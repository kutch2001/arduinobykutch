// kutch2001
// 07-04-2010

/*
    This sketch has several modes, each one changes by button.
    1.  Dispenses a specific amount of food at a constant 
    interval throughout the day.  Buzzer before dispensing to
    let recipients know food is on the way.  
    Status LED will blink once every two seconds.
    2.  Added logic for the CatGenie resetter module, by ScottSEA
      URL - http://www.instructables.com/id/CatGenie_Resetting_a_SaniSolution_Cartridge/
    Status LED will blink twice every two seconds.
    3.  Motion detector mode only - this activates relay.
    Status LED will blink three times every two seconds.
    4.  Food dispensing only (on same timers as #1).
    Status LED will blink four times every two seconds.
    5.  Dummy mode blinks status led
    NOTE1:  All times are in milliseconds
    NOTE2:  Expandable using a mode button (thanks ladyada for great tutorial
      URL - http://www.ladyada.net/learn/arduino/lesson5.html
    NOTE3:  Thanks to faludi for buzzer tutorial
      URL - http://www.faludi.com/2007/04/23/buzzer-arduino-example-code/
*/

#include <Wire.h>
#include <Servo.h> 
 
Servo myservo;  // create servo object to control a servo 
                // a maximum of eight servo objects can be created 

int switchPin = 2;  // button is connected to pin 2
int pirPin = 3;    //the digital pin connected to the PIR sensor's output
//buzzer @ pin 4
//servo @ pin 10
#define RELAY_PIN 11  //pin for food auger motor
int statusLed = 12;  //status led
int ledPin = 13;  //LED connect gives status on feeder since last dispensing (1 blink per hour)
byte buttonState = 0;  //initialize button to zero
byte val;  // variable for reading the pin status
byte val2;  // variable for reading the delayed/debounced status
byte switchMode = 0;  //defines what to do
//These are feeding controls
unsigned long timeLapse = 10800000;  //turn on motor every 3 hours
unsigned long runTime = 7250;  //turn on motor for 7.25 seconds
int relayState = LOW;  //relayState used to set the Relay
unsigned long nextrelayMillis = 0;  //will store next time to activate relay
byte relaySwitch=0;  //0 is off, 1 is on
//These are display controls
unsigned long blinkTime = 0;  //main counter to tell when to blink
byte blinks = 0;  //how many times to blink
unsigned long blinkdelayTime = 10000;  //defines how often to blink
byte blinksLeft = 0;  //Number of blinks left to do
unsigned long blinkaddTime = 3600000;  //every hour add a blink
unsigned long blinkchangeTime = 0;  //track when to increment time
int blinkLength = 250;  //length of time for blink
//These are for status light
unsigned long statusblinkTime = 0;  //main counter to tell when to blink
byte statusblinks = 0;  //how many times to blink
unsigned long statusblinkdelayTime = 3000;  //defines how often to blink
byte statusblinksLeft = 0;  //Number of blinks left to do
unsigned long statusblinkchangeTime = 0;  //track when to increment time
int statusblinkLength = 150;  //length of time for blink
//These are for error light
unsigned long errorblinkTime = 0;  //main counter to tell when to blink
byte errorblinks = 1;  //how many times to blink
unsigned long errorblinkdelayTime = 500;  //defines how often to blink
byte errorblinksLeft = 1;  //Number of blinks left to do
int errorblinkLength = 1000;  //length of time for blink
//general working variables
unsigned long tempTime = 0;  //used to store/calc durations
//the time we give the sensor to calibrate (10-60 secs according to the datasheet)
int calibrationTime = 30000;        
//the time when the sensor outputs a low impulse
long unsigned int lowIn;         
//the amount of milliseconds the sensor has to be low 
//before we assume all motion has stopped
long unsigned int pause = 5000; //delay for 5 minutes  
unsigned long genieRuntime = 2220000; //genie runs for 37 minutes 
boolean lockLow = true;
boolean takeLowTime;  
//activate genie 10 minutes after last motion detected
unsigned long genieDelaytime = 600000;
unsigned long genieActivatetime = 0;
unsigned long servoDelaytime = 2000;  //delay time between movements
boolean activateGenie = false;
byte genieStep = 0;  //used to identify which step of process it is in
int pos = 0;    // variable to store the servo position 
byte servoStandby = 135;  //servo position for nothing
byte servoActive = 45;  //servo position to push button


#define CG (B1010000)
boolean resetSuccess = false;
int byteArray []= {01, 01, 01, 60, 60, 60, 60, 60, 60, 8, 8, 8, 33, 33, 33, 255};

void setup()
{
  pinMode(4, OUTPUT); // set a pin for buzzer output
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(statusLed,OUTPUT);  //status led
  pinMode (ledPin, OUTPUT);
  pinMode(pirPin, INPUT);  //for motion sensor
  digitalWrite(pirPin, LOW);  //for motion sensor
  myservo.attach(10);  // attaches the servo on pin 10 to the servo object 
  myservo.write(servoStandby);  //move servo to standby position
  Wire.begin();        // join i2c bus (address optional for master)
  Serial.begin(9600); // open serial
  Serial.println("Leaving this open to print debug msgs"); //debug message
  digitalWrite(statusLed, HIGH);  //set the LED on
  delay (calibrationTime);  //delay to initialize PIR
  digitalWrite(statusLed, LOW);  //set the LED off
}

void loop()
{
read_button ();  //see what to do by button press
switch (switchMode)
  {
  case 0:  //normal routine
    //Serial.println ("case 0");
    reset_blinks (1);
    feed_cats (switchMode);  //run cat feeder
    digitalWrite(RELAY_PIN, LOW);  // sets the Relay off
    break;
  case 1:  //reset catgenie cartridges
    //Serial.println ("case 1");
    reset_blinks (2);
    resetCartridgeloop ();  //run cartridge reset logic
    break;
  case 2:  //PIR mode only
    //Serial.println ("case 2");
    reset_blinks (3);
    while (switchMode == 2)
      {
      check_litter ();
      read_button ();
      }
    break;
  case 3:  //dispenser only
    //Serial.println ("case 3");
    reset_blinks (4);
    feed_cats (switchMode);  //run cat feeder
    digitalWrite(RELAY_PIN, LOW);  // sets the Relay off
    break;
  default:  //nothing to do
    //Serial.println ("case default");
    digitalWrite(ledPin, LOW);  //sets to off
    blinkLight ();  //meaning nothing selected
  }
}

void reset_blinks (byte blink_amt)
{
  statusblinks = blink_amt;  //sets # blinks based on what is passed
  statusblinksLeft = statusblinks;
  statusblinkTime = millis();  //set to start blinking right away
  blinkTime = millis();  //reset blinkTime so doesn't "stack them up"
  errorblinkTime = millis();  //set to start blinking right away
}

void feed_cats (byte mode)
{
while (switchMode == mode)
  {
  if (millis() > nextrelayMillis) //is it time to dispense?
   {
      if (relaySwitch == 0) //if it is off
        {
        tempTime = millis ();  //capture time before starting buzzer
        feed_warning ();  //make buzzer sounds for cats to leave
        tempTime = millis() - tempTime;  //calculate time elapsed
        nextrelayMillis = millis() + runTime + tempTime;  //sets time to turn Relay off
        digitalWrite(RELAY_PIN, HIGH);  // turns the Relay on
        relaySwitch = 1;  // sets the Relay switch to on
        }
     else  //Relay is assumed to be on
        {
        nextrelayMillis = millis() + timeLapse - tempTime;  //sets time to turn Relay off
        digitalWrite(RELAY_PIN, LOW);  // sets the Relay off
        relaySwitch = 0;  // sets the Relay switch to off
        blinks = 0;  //reset blinks to indicate Relay was on
        blinkchangeTime = millis();  //reset blinkchangeTime to increment time as of now
        }
   };

  if (millis() > blinkchangeTime)  //check to see if time to increment blinks
   {
     blinkchangeTime = blinkchangeTime + blinkaddTime;  //increment time for next blink
     blinks = ++blinks;  //add one to blink counter
   };

  if (millis() > blinkTime)  //If time to blink go in here
   {
     if (blinksLeft > 100)  //turn blink on
       {
         digitalWrite(ledPin, HIGH);  //set the LED on
         blinksLeft = blinksLeft - 101;  //subtract 100 so know to switch next time
         blinkTime = blinkTime + blinkLength;  //set next time to enter blink logic
       }
     else  //turn blink off
       {
         digitalWrite(ledPin, LOW);  //set the LED off
         if (blinksLeft > 0)  //start process for blinking
           {
             blinkTime = blinkTime + blinkLength;  //set next time to enter blink logic
             blinksLeft = blinksLeft + 100; //subtract one blink as just completed
           }
         else  //initialize blinks for next time
           {
             blinksLeft = 0;  //initialize to zero
             blinksLeft = blinksLeft + blinks; //add # of times to blink
             blinkTime = blinkTime + blinkdelayTime;  //set next time to enter blink logic
           }
       }
   };
   if (mode == 0) 
     {
     check_litter ();
     };
   read_button ();
   statusBlink ();
  }
}

void check_litter ()
{
  if (digitalRead(pirPin) == HIGH && genieStep == 0)
    {
    //Serial.println("possible activation");
    //receiving erronous PIR activation after servo movement, not sure why
    //so make sure good enough pause has passed since last Activate time
    if (millis() - genieActivatetime > genieRuntime)
      {
      if(lockLow)
         {  
         //makes sure we wait for a transition to LOW before any further output is made:
         lockLow = false;            
         /*Serial.println("---");
         Serial.print("motion detected at ");
         Serial.print(millis()/1000);
         Serial.println(" sec");*/
         //if genie is already activated let it continue
         if (genieStep == 0)
           {
           //Serial.println ("genie activate false");
           activateGenie = false;
           };
         delay(50);
         }         
       takeLowTime = true;
      }
    };
  if (digitalRead(pirPin) == LOW)
    {
    if(takeLowTime)
      {
      lowIn = millis();          //save the time of the transition from high to LOW
      takeLowTime = false;       //make sure this is only done at the start of a LOW phase
      };
    //if the sensor is low for more than the given pause, 
    //we assume that no more motion is going to happen
    if(!lockLow && millis() - lowIn > pause)
      {  
      //makes sure this block of code is only executed again after 
      //a new motion sequence has been detected
      lockLow = true;                        
      /*Serial.print("motion ended at ");      //output
      Serial.print((millis() - pause)/1000);
      Serial.println(" sec");*/
      //set to turn genie on after use
      genieActivatetime = millis() + genieDelaytime;
      activateGenie = true;
      //Serial.println ("genie activate true");
      delay(50);
      }
    };
  //If time to activate flip servo
  if (activateGenie && millis() > genieActivatetime)
    {
    switch (genieStep)
      {
      case 0:  //press button
        //Serial.println ("genie activate 0");
        buzz(4, 1200, 300);
        myservo.write(servoActive);  //move servo to standby position
        //enter when time to move servo again
        genieActivatetime = genieActivatetime + servoDelaytime;
        genieStep = genieStep++;  //increment step counter
        break;
      case 1:  //let go of button
        //Serial.println ("genie activate 1");
        myservo.write(servoStandby);  //move servo to standby position
        //enter when time to move servo again
        genieActivatetime = genieActivatetime + servoDelaytime;
        genieStep = genieStep++;  //increment step counter
        break;
      default:  //de-activate Genie
        //Serial.println ("genie activate default");
        genieStep = 0;  //increment step counter
        //Serial.println ("genie activate false");
        activateGenie = false;
        break;
      }
    };
}

void feed_warning ()
{
   buzz(4, 600, 200);
   delay (500);
   buzz(4, 600, 200);
   delay (500);
   buzz(4, 600, 200);
   delay (500);
}

void resetCartridgeloop ()
{
while (switchMode == 1)
  {
  if (resetSuccess) 
    {
      delay (2000);      // our work is done - pause for a while 
      resetSuccess = false;
    } else {
      resetCartridge();
      resetSuccess = verifyCartridge();
      //digitalWrite(ledPin, resetSuccess);
    };
  read_button ();
  statusBlink ();
  }
}

void resetCartridge()
{
  for (int i=3; i < sizeof(byteArray)/2; i++)
  {
    Wire.beginTransmission(CG);
    Wire.send(i);
    Wire.send(byteArray[i]);
    Wire.endTransmission();
    delay(4);
  }
}

void movePointerTo(int deviceAddr, int memoryAddr)
{
  Wire.beginTransmission(deviceAddr);
  Wire.send(memoryAddr);
  Wire.endTransmission();
}

boolean verifyCartridge()
{
  boolean success = true;
  movePointerTo(CG, 3);
  Wire.requestFrom(CG, 3);
  //while (Wire.available())
  //{
    if (Wire.receive() == 60 && success == true)
    { 
      // looking good so far
    } else {
      error_blink();
      success = false;
    }
  //}
  return success;
}

void error_blink()                     // blink if error
  {
  if (millis() > errorblinkTime)  //If time to blink go in here
   {
     if (errorblinksLeft > 100)  //turn blink on
       {
         digitalWrite(ledPin, HIGH);  //set the LED on
         errorblinksLeft = errorblinksLeft - 101;  //subtract 100 so know to switch next time
         errorblinkTime = errorblinkTime + errorblinkLength;  //set next time to enter blink logic
       }
     else  //turn blink off
       {
         digitalWrite(ledPin, LOW);  //set the LED off
         if (errorblinksLeft > 0)  //start process for blinking
           {
             errorblinkTime = errorblinkTime + errorblinkLength;  //set next time to enter blink logic
             errorblinksLeft = errorblinksLeft + 100; //subtract one blink as just completed
           }
         else  //initialize blinks for next time
           {
             errorblinksLeft = 0;  //initialize to zero
             errorblinksLeft = errorblinksLeft + errorblinks; //add # of times to blink
             errorblinkTime = errorblinkTime + errorblinkdelayTime;  //set next time to enter blink logic
           }
       }
   };
  }

void blinkLight ()
{
  digitalWrite(statusLed, HIGH);  //set the LED on
  delay (500);
  digitalWrite(statusLed, LOW);  //set the LED off
  delay (500);
}

void read_button ()
{
  val = digitalRead(switchPin);      // read input value and store it in val
  delay(10);                         // 10 milliseconds is a good amount of time
  val2 = digitalRead(switchPin);     // read the input again to check for bounces
  if (val == val2) {                 // make sure we got 2 consistant readings!
    if (val != buttonState) {      // the button state has changed!
      if (val == LOW) {                // check if the button is pressed
        switchMode = switchMode++;
        if (switchMode > 4) {        //if greater than 3 reset to 0
          switchMode = 0;
        }
      }
    }
    buttonState = val;                 // save the new state in our variable
  }
}

void statusBlink ()
{
  if (millis() > statusblinkTime)  //If time to blink go in here
   {
     if (statusblinksLeft > 100)  //turn blink on
       {
         digitalWrite(statusLed, HIGH);  //set the LED on
         statusblinksLeft = statusblinksLeft - 101;  //subtract 100 so know to switch next time
         statusblinkTime = statusblinkTime + statusblinkLength;  //set next time to enter blink logic
       }
     else  //turn blink off
       {
         digitalWrite(statusLed, LOW);  //set the LED off
         if (statusblinksLeft > 0)  //start process for blinking
           {
             statusblinkTime = statusblinkTime + statusblinkLength;  //set next time to enter blink logic
             statusblinksLeft = statusblinksLeft + 100; //subtract one blink as just completed
           }
         else  //initialize blinks for next time
           {
             statusblinksLeft = 0;  //initialize to zero
             statusblinksLeft = statusblinksLeft + statusblinks; //add # of times to blink
             statusblinkTime = statusblinkTime + statusblinkdelayTime;  //set next time to enter blink logic
           }
       }
   };
  
}

void buzz(int targetPin, long frequency, long length) {
  long delayValue = 1000000/frequency/2; // calculate the delay value between transitions
  //// 1 second's worth of microseconds, divided by the frequency, then split in half since
  //// there are two phases to each cycle
  long numCycles = frequency * length/ 1000; // calculate the number of cycles for proper timing
  //// multiply frequency, which is really cycles per second, by the number of seconds to 
  //// get the total number of cycles to produce
  for (long i=0; i < numCycles; i++){ // for the calculated length of time...
    digitalWrite(targetPin,HIGH); // write the buzzer pin high to push out the diaphram
    delayMicroseconds(delayValue); // wait for the calculated delay value
    digitalWrite(targetPin,LOW); // write the buzzer pin low to pull back the diaphram
    delayMicroseconds(delayValue); // wait againf or the calculated delay value
  }
}

