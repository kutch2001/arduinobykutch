#ifndef PARAMETERS_H
#define PARAMETERS_H

// NO RS485/EXTRUDER CONTROLLER SUPPORT
// PLEASE VERIFY PIN ASSIGNMENTS FOR YOUR CONFIGURATION!!!!!!!
#define MOTHERBOARD 3 // ATMEGA168 0, SANGUINO 1, MOTHERBOARD = 2, MEGA 3, ATMEGA328 4

//Use debugging or not..
#define DEBUGGING false

// MOTOR SUPPORT..
const bool USE_MOTOR = true; //Set to false if using thermocouple

// THERMOCOUPLE SUPPORT UNTESTED... USE WITH CAUTION!!!!
const bool USE_THERMISTOR = true; //Set to false if using thermocouple
const bool USE_HBP_THERMISTOR = false; //Set to false if using thermocouple for HBP

// Calibration formulas
// e_extruded_steps_per_mm = e_feedstock_steps_per_mm * (desired_extrusion_diameter^2 / feedstock_diameter^2)
// new_axis_steps_per_mm = previous_axis_steps_per_mm * (test_distance_instructed/test_distance_traveled)
// units are in millimeters or whatever length unit you prefer: inches,football-fields,parsecs etc

//Calibration variables
float x_steps_per_unit = 90.47;
float y_steps_per_unit = 90.47;
/*float x_steps_per_unit = 100.47;
float y_steps_per_unit = 100.47;  - commented out 11/24/2012 as sizes were off last time printed, by about 10%*/
//float x_steps_per_unit = 80.376;
//float y_steps_per_unit = 80.376;
//changed for axis z-roids - roughly calibrated
float z_steps_per_unit = 1210.37;
//float z_steps_per_unit = 1322.633;  - commented out 11/24/2012 as sizes were off last time printed, by about 10%*/
//float z_steps_per_unit = 6667.184;
float e_steps_per_unit = 16;
float max_feedrate = 18000;
float z_feedrate = 90;

//float x_steps_per_unit = 10.047;
//float y_steps_per_unit = 10.047;
//float z_steps_per_unit = 833.398;
//float e_steps_per_unit = 0.706;
//float max_feedrate = 3000;

//For Inverting Stepper Enable Pins (Active Low) use 0, Non Inverting (Active High) use 1
const bool X_ENABLE_ON = 0;
const bool Y_ENABLE_ON = 0;
const bool Z_ENABLE_ON = 0;
const bool E_ENABLE_ON = 0;

//Disables axis when it's not being used.
const bool DISABLE_X = false;
const bool DISABLE_Y = false;
const bool DISABLE_Z = true;
const bool DISABLE_E = true;

//invert direction
const bool INVERT_X_DIR = false;
const bool INVERT_Y_DIR = false;
const bool INVERT_Z_DIR = false;
const bool INVERT_E_DIR = false;

//Endstop Settings
const bool ENDSTOPS_INVERTING = true;
const bool min_software_endstops = false; //If true, axis won't move to coordinates less than zero.
const bool max_software_endstops = true;  //If true, axis won't move to coordinates greater than the defined lengths below.
const int X_MAX_LENGTH = 100;
const int Y_MAX_LENGTH = 100;
const int Z_MAX_LENGTH = 110;

#define BAUDRATE 115200
#define TEMP_VARIANCE 10

#endif
