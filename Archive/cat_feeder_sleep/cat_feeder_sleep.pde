// Richard Kutscher
// 2-28-2010

/*
    This sketch allows a dispenser to dispense a specific amount of food at
    a constant interval throughout the day.  In the comments next to each
    item describes the behavior it controls.
    All times are in milliseconds
*/

#include <avr/sleep.h>
#include <avr/wdt.h>

#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif
volatile boolean f_wdt=1;

#define RELAY_PIN 11
int ledPin = 13;  //LED connect gives status on feeder since last dispensing (1 blink per hour)
//These are feeding controls
unsigned long timeLapse = 30000;  //turn on motor every 3 hours
unsigned long runTime = 10000;  //turn on motor for 10 seconds
int relayState = LOW;  //relayState used to set the Relay
unsigned long nextrelayMillis = 0;  //will store next time to activate relay
byte relaySwitch=0;  //0 is off, 1 is on
//These are display controls
unsigned long blinkTime = 0;  //main counter to tell when to blink
byte blinks = 0;  //how many times to blink
unsigned long blinkdelayTime = 8000;  //defines how often to blink
byte blinksLeft = 0;  //Number of blinks left to do
unsigned long blinkaddTime = 3600000;  //every hour add a blink
unsigned long blinkchangeTime = 0;  //track when to increment time
int blinkLength = 250;  //length of time for blink
byte blinkDone = 0;  //to identify if blinking is done

void setup()
{
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(9600); // open serial
  Serial.println("Leaving this open to print status msgs"); //debug message
  Serial.println("Setup watchdog");

  // CPU Sleep Modes
  // SM2 SM1 SM0 Sleep Mode
  // 0    0  0 Idle
  // 0    0  1 ADC Noise Reduction
  // 0    1  0 Power-down
  // 0    1  1 Power-save
  // 1    0  0 Reserved
  // 1    0  1 Reserved
  // 1    1  0 Standby(1)

  cbi( SMCR,SE );	// sleep enable, power down mode
  cbi( SMCR,SM0 );     // power down mode
  sbi( SMCR,SM1 );     // power down mode
  cbi( SMCR,SM2 );     // power down mode

  setup_watchdog(9);
}

void loop()
{
  if (f_wdt==1) {  // wait for timed out watchdog / flag is set when a watchdog timeout occurs
    {
  if (millis() > nextrelayMillis) //is it time to dispense?
   {
      if (relaySwitch == 0) //if it is off
        {
        nextrelayMillis = millis() + runTime;  //sets time to turn Relay off
        digitalWrite(RELAY_PIN, HIGH);  // turns the Relay on
        relaySwitch = 1;  // sets the Relay switch to on
       Serial.println("High");  //debug message
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
       Serial.println("Low");  //debug message
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
     blinkDone = 1;
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
             blinkTime = millis() + blinkdelayTime;  //set next time to enter blink logic
             blinkDone = 0;
           }
       }
   };
   if (relaySwitch == 0 && blinkDone == 0)
      {
            Serial.println("Reset flag");
            f_wdt=0;	 // reset flag
            system_sleep();
            blinkTime = millis() - 1;  //set next time to enter blink logic
      };
    }
}
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

//****************************************************************
// set system into the sleep state
// system wakes up when wtchdog is timed out
void system_sleep() {

            Serial.println("Sleep");
  cbi(ADCSRA,ADEN);			  // switch Analog to Digitalconverter OFF

  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
  sleep_enable();

  sleep_mode();				// System sleeps here

    sleep_disable();			   // System continues execution here when watchdog timed out
  sbi(ADCSRA,ADEN);			  // switch Analog to Digitalconverter ON
            delay (10);
            Serial.println("Wake up");

}

//****************************************************************
// 0=16ms, 1=32ms,2=64ms,3=128ms,4=250ms,5=500ms
// 6=1 sec,7=2 sec, 8=4 sec, 9= 8sec
void setup_watchdog(int ii) {

  byte bb;
  int ww;
  if (ii > 9 ) ii=9;
  bb=ii & 7;
  if (ii > 7) bb|= (1<<5);
  bb|= (1<<WDCE);
  ww=bb;
  Serial.println(ww);


  MCUSR &= ~(1<<WDRF);
  // start timed sequence
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  // set new watchdog timeout value
  WDTCSR = bb;
  WDTCSR |= _BV(WDIE);

}
//****************************************************************
// Watchdog Interrupt Service / is executed when  watchdog timed out
ISR(WDT_vect) {
  f_wdt=1;  // set global flag
}

