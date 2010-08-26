// Richard Kutscher
// 2-28-2010

/*
    This sketch allows a dispenser to dispense a specific amount of food at
    a constant interval throughout the day.  In the comments next to each
    item describes the behavior it controls.
    All times are in milliseconds
*/

#define RELAY_PIN 11
int ledPin = 13;  //LED connect gives status on feeder since last dispensing (1 blink per hour)
//These are feeding controls
unsigned long timeLapse = 14400000;  //turn on motor every 4 hours
unsigned long runTime = 22000;  //turn on motor for 22 seconds
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

void setup()
{
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(9600); // open serial
  Serial.println("Leaving this open to print status msgs"); //debug message
}

void loop()
{
  if (millis() > nextrelayMillis) //is it time to dispense?
   {
      if (relaySwitch == 0) //if it is off
        {
        nextrelayMillis = millis() + runTime;  //sets time to turn Relay off
        digitalWrite(RELAY_PIN, HIGH);  // turns the Relay on
        relaySwitch = 1;  // sets the Relay switch to on
       //Serial.println("High");  //debug message
        }
     else  //Relay is assumed to be on
        {
        nextrelayMillis = millis() + timeLapse;  //sets time to turn Relay off
        digitalWrite(RELAY_PIN, LOW);  // sets the Relay on
        relaySwitch = 0;  // sets the Relay switch to off
        blinks = 0;  //reset blinks to indicate Relay was on
        blinkchangeTime = millis();  //reset blinkchangeTime to increment time as of now
        if (blinksLeft > 0);  //add one if currently blinking
          blinksLeft = ++blinksLeft;
       //Serial.println("Low");  //debug message
        }
   };

  if (millis() > blinkchangeTime)  //check to see if time to increment blinks
   {
     blinkchangeTime = blinkchangeTime + blinkaddTime;  //increment time for next blink
     blinks = ++blinks;  //add one to blink counter
    //Serial.println("Blinks ");  //debug message
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


  // original code works so commented it out as a starting point
  /*while (Serial.available() > 0)
  {
    cmd = Serial.read();

    switch (cmd)
    {
    case ' ':
      {
        relayVal ^= 1; // xor current value with 1 (causes value to toggle)
        if (relayVal)
          {
           Serial.println("Relay on");
           digitalWrite(ledPin, HIGH);   // sets the LED on
          }
        else
          {
           Serial.println("Relay off");
           digitalWrite(ledPin, LOW);    // sets the LED off
          }
        break;
      }
    default:
      {
        Serial.println("Press the spacebar to toggle relay on/off");
      }
    }

    if (relayVal)
      digitalWrite(RELAY_PIN, HIGH);
    else
      digitalWrite(RELAY_PIN, LOW);
   }*/
  
}
