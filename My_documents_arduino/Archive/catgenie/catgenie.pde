#include <Wire.h>

#define CG (B1010000)
boolean resetSuccess = false;
int isReset = 13;

int byteArray []= {01, 01, 01, 60, 60, 60, 60, 60, 60, 8, 8, 8, 33, 33, 33, 255};

void setup()
{ 
  pinMode(isReset, OUTPUT);
  digitalWrite(isReset, LOW);

  Wire.begin();        // join i2c bus (address optional for master)
}

void loop()
{
  if (resetSuccess) 
  {
    delay (2000);      // our work is done - pause for a while 
    resetSuccess = false;
  } else {
    resetCartridge();
    resetSuccess = verifyCartridge();
    digitalWrite(isReset, resetSuccess);
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
    digitalWrite(isReset, HIGH);   // sets the LED on
    delay(1000);                  // waits for a second
    digitalWrite(isReset, LOW);    // sets the LED off
    delay(1000);                  // waits for a second
  }
