//Initial sketch for temperature reading courtesy of Lady Ada.  Tutorial here:
//http://www.ladyada.net/learn/sensors/temp36.html

int sensorPin = 4;
int relayPin = 2; //pin to activate relay
int relayPower = 4; //provide 5V to relay

/*
 * setup() - this function runs once when you turn your Arduino on
 * We initialize the serial connection with the computer
 */
void setup()
{
  Serial.begin(9600);  //Start the serial connection with the computer
                       //to view the result open the serial monitor 
  //Set relay to off
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, LOW);
  pinMode(relayPower, OUTPUT);
  digitalWrite(relayPower, HIGH);
}
 
void loop()                     // run over and over again
{
 //getting the voltage reading from the temperature sensor
 int reading = analogRead(sensorPin);  

 // converting that reading to voltage, for 3.3v arduino use 3.3, for 5.0v arduino use 5.0
 float voltage = reading * 5.0 / 1024; 
 
 // print out the voltage
 Serial.print(voltage); Serial.println(" volts");
 
 // now print out the temperature
 float temperatureC = (voltage - 0.5) * 100 ;  //converting from 10 mv per degree wit 500 mV offset
                                               //to degrees ((volatge - 500mV) times 100)
 Serial.print(temperatureC); Serial.println(" degress C");
 
 // now convert to Fahrenheight
 float temperatureF = (temperatureC * 9 / 5) + 32;
 Serial.print(temperatureF); Serial.println(" degress F");

 //For now, due to valtage drop when relay is switched on, trick it to think unchanged
 if (temperatureF < 70.0)
   {
    digitalWrite(relayPin, HIGH);
    Serial.println("Relay high");
   }
 if (temperatureF > 83.0)
   {
    digitalWrite(relayPin, LOW);
    Serial.println("Relay low");
   }
 
 delay(5000);                                     //waiting 5 seconds
}

