// Sweep
// by BARRAGAN <http://barraganstudio.com> 

#include <Servo.h> 
 
Servo myservo;  // create servo object to control a servo 
                // a maximum of eight servo objects can be created 
 
int pos = 0;    // variable to store the servo position 
 
void setup() 
{ 
  myservo.attach(9);  // attaches the servo on pin 9 to the servo object 
} 
 
 
void loop() 
{ 
  myservo.write(55);              // far left of mp90
  delay (2000);
  myservo.write(105);              // far left of mp90
  delay (2000) ; 
} 
