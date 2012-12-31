//include the datetime library, so our garduino can keep track of how long the lights are on
//#include <DateTime.h>
//changed to use Time.h library
#include <Time.h>
/*Water sensor values:
   0 - no reading
*/
#include <Streaming.h>

//define analog inputs to which we have connected our sensors
int waterSensor = 0;
int soilSensor1 = 2;
int soilSensor2 = 3;
int tempSensor = 4;
int lightSensor = 5;

//define digital outputs to which we have connecte our relays (water and light) and LED (temperature)
int watersensepower = 3;
int soilSensor1power = 4;
int soilSensor2power = 5;
int waterPump1 = 6;
int waterPump2 = 7;
int waterHot = 8;
int waterCold = 9;

//define variables to store values
int temp_val;
int temperature;
int water_val;
int soil_val1;
int soil_val2;
int light_val;

//setup a variable to store seconds since arduino switched on
float start_time;
float seconds_elapsed;
float seconds_elapsed_total;
float seconds_for_this_cycle;

void setup() {
//open serial port
Serial.begin(9600);
//set the water, light, and temperature pins as outputs that are turned off
pinMode (watersensepower, OUTPUT);
pinMode (soilSensor1power, OUTPUT);
pinMode (soilSensor2power, OUTPUT);
pinMode (waterPump1, OUTPUT);
pinMode (waterPump2, OUTPUT);
pinMode (waterHot, OUTPUT);
pinMode (waterCold, OUTPUT);
digitalWrite (watersensepower, LOW);
digitalWrite (soilSensor1power, LOW);
digitalWrite (soilSensor2power, LOW);
digitalWrite (waterPump1, LOW);
digitalWrite (waterPump2, LOW);
digitalWrite (waterHot, LOW);
digitalWrite (waterCold, LOW);

//establish start time
start_time = now();
seconds_elapsed_total = 0;
Serial.println ("delay 3 seconds");
delay(3000);

}
void loop() {
/*light_val = analogRead(lightSensor);
Serial.print("light sensor reads ");
Serial.println( light_val );
delay(1000);*/

temp_val = analogRead(tempSensor);
//temperature = (1.1*temp_val*100.0)/1024.0;
temperature = (5.0*temp_val*100.0)/1024.0;
Serial << "Raw: " << temp_val << " temperature: " << temperature << endl;

digitalWrite (watersensepower, HIGH);
water_val = analogRead(waterSensor);
digitalWrite (watersensepower, LOW);
digitalWrite (soilSensor1power, HIGH);
soil_val1 = analogRead(soilSensor1);
digitalWrite (soilSensor1power, LOW);
digitalWrite (soilSensor2power, HIGH);
soil_val2 = analogRead(soilSensor2);
digitalWrite (soilSensor2power, LOW);
light_val = analogRead(lightSensor);

Serial << "Vals: " << water_val << " - " << soil_val1 << " - " <<
    soil_val2 << " - " << light_val << " :" << endl;
delay(5000);

/*
// read the value from the moisture-sensing probes, print it to screen, and wait a second
moisture_val = analogRead(moistureSensor);
Serial.print("moisture sensor reads ");
Serial.println( moisture_val );
delay(1000);
// read the value from the photosensor, print it to screen, and wait a second
light_val = analogRead(lightSensor);
Serial.print("light sensor reads ");
Serial.println( light_val );
delay(1000);
// read the value from the temperature sensor, print it to screen, and wait a second
temp_val = analogRead(tempSensor);
Serial.print("temp sensor reads ");
Serial.println( temp_val );
delay(1000);
Serial.print("seconds total = ");
Serial.println( seconds_elapsed_total );
delay(1000);
Serial.print("seconds lit = ");
Serial.println( seconds_light);
delay(1000);
Serial.print("proportion desired = ");
Serial.println( proportion_to_light);
delay(1000);
Serial.print("proportion achieved = ");
Serial.println( proportion_lit);
delay(1000);
//Serial.print("proportion achieved = ");
//long(proportion_lit);
//Serial.println( proportion_lit );
//delay(1000);
//turn water on for 10 seconds if moisture_val is less than 800, turn it off, then wait a second
if (moisture_val < 850)
{
digitalWrite(waterPump, HIGH);
delay (10000);
digitalWrite(waterPump, LOW);
delay (1000);
}

//update time, and increment seconds_light if the lights are on
seconds_for_this_cycle = now() - seconds_elapsed_total;
seconds_elapsed_total = now() - start_time;
if (light_val > 600)
{
seconds_light = seconds_light + seconds_for_this_cycle;
}

//cloudy days that get sunny again: turn lights back off if light_val exceeds 900. this works b/c the supplemental lights aren't as bright as the sun:)
if (light_val > 900)
{
digitalWrite (lightSwitch, LOW);
}

//turn off lights if proportion_lit>proportion_to_light, and then wait 5 minutes
if (proportion_lit > proportion_to_light)
{
digitalWrite (lightSwitch, LOW);
delay (300000);
}

//figure out what proportion of time lights have been on
proportion_lit = seconds_light/seconds_elapsed_total;

//turn lights on if light_val is less than 600 and plants have light for less than desired proportion of time, then wait 10 seconds
if (light_val < 600 and proportion_lit < proportion_to_light)
{
digitalWrite(lightSwitch, HIGH);
delay(10000);
}

//turn on temp alarm light if temp_val is less than 850 (approximately 50 degrees Fahrenheit)
if (temp_val < 850)
{
digitalWrite(tempLed, HIGH);
}
*/
}

