// Tonokip RepRap firmware rewrite based off of Hydra-mmm firmware.
// Licence: GPL

#include "configuration.h"
#include "pins.h"
#include "ThermistorTable.h"

// look here for descriptions of gcodes: http://linuxcnc.org/handbook/gcode/g-code.html
// http://objects.reprap.org/wiki/Mendel_User_Manual:_RepRapGCodes

//Implemented Codes
//-------------------
// G0 -> G1
// G1  - Coordinated Movement X Y Z E
// G4  - Dwell S<seconds> or P<milliseconds>
// G90 - Use Absolute Coordinates
// G91 - Use Relative Coordinates
// G92 - Set current position to cordinates given

//RepRap M Codes
// M101 - Turn Extruder on - forward
// M102 - Turn Extruder on - reverse
// M103 - Turn Extruder off
// M104 - Set target temp
// M105 - Read current temp
// M106 - Fan on
// M107 - Fan off
// M108 - Set extruder speed
// M109 - Platform temp.
// M118 - Set platform temp
// M140 - Set platform temp

//Custom M Codes
// M18  - disable steppers (same as M84)
// M80  - Turn on Power Supply
// M81  - Turn off Power Supply
// M82  - Set E codes absolute (default)
// M83  - Set E codes relative while in Absolute Coordinates (G90) mode
// M84  - Disable steppers until next move
// M85  - Set inactivity shutdown timer with parameter S<seconds>. To disable set zero (default)
// M86  - If Endstop is Not Activated then Abort Print. Specify X and/or Y
// M92  - Set axis_steps_per_unit - same syntax as G92

//Stepper Movement Variables
bool direction_x, direction_y, direction_z, direction_e;
unsigned long previous_micros=0, previous_micros_x=0, previous_micros_y=0, previous_micros_z=0, previous_micros_e=0, previous_millis_heater;
unsigned long x_steps_to_take, y_steps_to_take, z_steps_to_take, e_steps_to_take;
float destination_x =0.0, destination_y = 0.0, destination_z = 0.0, destination_e = 0.0;
float current_x = 0.0, current_y = 0.0, current_z = 0.0, current_e = 0.0;
float x_interval, y_interval, z_interval, e_interval; // for speed delay
float feedrate = 1500, next_feedrate;
float time_for_move;
long gcode_N, gcode_LastN;
bool relative_mode = false;  //Determines Absolute or Relative Coordinates
bool relative_mode_e = false;  //Determines Absolute or Relative E Codes while in Absolute Coordinates mode. E is always relative in Relative Coordinates mode.

//extruder variables
float extruder_speed = 0;
bool extruder_wait = false;  //If command is sent to start extruder, it must be upto temp first.  This lets the loop 

// comm variables
#define MAX_CMD_SIZE 256
char cmdbuffer[MAX_CMD_SIZE];
char serial_char;
int serial_count = 0;
boolean comment_mode = false;
char *strchr_pointer; // just a pointer to find chars in the cmd string like X, Y, Z, E, etc

//manage heater variables
int target_raw = 0;
int target_var = 0;
int target_platform = 0;
int current_raw;
int current_platform;
int oldT;
int newT;
unsigned long platformrelayTime = 0;  //last time platform relay was activated
unsigned long extruderheaterTime = 0;  //last time extruder heater was activated

//Inactivity shutdown variables
unsigned long previous_millis_cmd=0;
unsigned long max_inactive_time = 0;

void setup()
{ 
  //Initialize Step Pins
  if(X_STEP_PIN > -1) pinMode(X_STEP_PIN,OUTPUT);
  if(Y_STEP_PIN > -1) pinMode(Y_STEP_PIN,OUTPUT);
  if(Z_STEP_PIN > -1) pinMode(Z_STEP_PIN,OUTPUT);
  if(E_STEP_PIN > -1) pinMode(E_STEP_PIN,OUTPUT);
  
  //Initialize Dir Pins
  if(X_DIR_PIN > -1) pinMode(X_DIR_PIN,OUTPUT);
  if(Y_DIR_PIN > -1) pinMode(Y_DIR_PIN,OUTPUT);
  if(Z_DIR_PIN > -1) pinMode(Z_DIR_PIN,OUTPUT);
  if(E_DIR_PIN > -1) pinMode(E_DIR_PIN,OUTPUT);

  //Steppers default to disabled.
  if(X_ENABLE_PIN > -1) if(!X_ENABLE_ON) digitalWrite(X_ENABLE_PIN,HIGH);
  if(Y_ENABLE_PIN > -1) if(!Y_ENABLE_ON) digitalWrite(Y_ENABLE_PIN,HIGH);
  if(Z_ENABLE_PIN > -1) if(!Z_ENABLE_ON) digitalWrite(Z_ENABLE_PIN,HIGH);
  if(E_ENABLE_PIN > -1) if(!E_ENABLE_ON) digitalWrite(E_ENABLE_PIN,HIGH);
  
  //Initialize Enable Pins
  if(X_ENABLE_PIN > -1) pinMode(X_ENABLE_PIN,OUTPUT);
  if(Y_ENABLE_PIN > -1) pinMode(Y_ENABLE_PIN,OUTPUT);
  if(Z_ENABLE_PIN > -1) pinMode(Z_ENABLE_PIN,OUTPUT);
  if(E_ENABLE_PIN > -1) pinMode(E_ENABLE_PIN,OUTPUT);

  if(HEATER_0_PIN > -1) pinMode(HEATER_0_PIN,OUTPUT);
  Serial.begin(BAUDRATE);
  Serial.println("start");
}


void loop()
{
  get_command();
  manage_heater();
  manage_platform (); //add heated build base/platform support
  
  manage_inactivity(1); //shutdown if not receiving any new commands
}

inline void get_command() 
{ 

  if( Serial.available() > 0 ) {
    serial_char = Serial.read();
    if(serial_char == '\n' || serial_char == '\r' || serial_char == ':' || serial_count >= (MAX_CMD_SIZE - 1) ) 
    {
      if(!serial_count) return; //if empty line
      cmdbuffer[serial_count] = 0; //terminate string
      Serial.print("Echo:");
      Serial.println(&cmdbuffer[0]);
      
      process_commands();
      
      comment_mode = false; //for new command
      serial_count = 0; //clear buffer
      //Serial.println("ok"); 
    }
    else
    {
      if(serial_char == ';') comment_mode = true;
      if(!comment_mode) cmdbuffer[serial_count++] = serial_char; 
    }
  }  
}


//#define code_num (strtod(&cmdbuffer[strchr_pointer - cmdbuffer + 1], NULL))
//inline void code_search(char code) { strchr_pointer = strchr(cmdbuffer, code); }
inline float code_value() { return (strtod(&cmdbuffer[strchr_pointer - cmdbuffer + 1], NULL)); }
inline long code_value_long() { return (strtol(&cmdbuffer[strchr_pointer - cmdbuffer + 1], NULL, 10)); }
inline bool code_seen(char code_string[]) { return (strstr(cmdbuffer, code_string) != NULL); }  //Return True if the string was found

inline bool code_seen(char code)
{
  strchr_pointer = strchr(cmdbuffer, code);
  return (strchr_pointer != NULL);  //Return True if a character was found
}



inline void process_commands()
{
  unsigned long codenum; //throw away variable
  
  if(code_seen('N'))
  {
    gcode_N = code_value_long();
    if(gcode_N != gcode_LastN+1 && (strstr(cmdbuffer, "M110") == NULL) ) {
    //if(gcode_N != gcode_LastN+1 && !code_seen("M110") ) {   //Hmm, compile size is different between using this vs the line above even though it should be the same thing. Keeping old method.
      Serial.print("Serial Error: Line Number is not Last Line Number+1, Last Line:");
      Serial.println(gcode_LastN);
      FlushSerialRequestResend();
      return;
    }
    
    if(code_seen('*'))
    {
      byte checksum = 0;
      byte count=0;
      while(cmdbuffer[count] != '*') checksum = checksum^cmdbuffer[count++];
     
      if( (int)code_value() != checksum) {
        Serial.print("Error: checksum mismatch, Last Line:");
        Serial.println(gcode_LastN);
        FlushSerialRequestResend();
        return;
      }
      //if no errors, continue parsing
    }
    else 
    {
      Serial.print("Error: No Checksum with line number, Last Line:");
      Serial.println(gcode_LastN);
      FlushSerialRequestResend();
      return;
    }
    
    gcode_LastN = gcode_N;
    //if no errors, continue parsing
  }
  else  // if we don't receive 'N' but still see '*'
  {
    if(code_seen('*'))
    {
      Serial.print("Error: No Line Number with checksum, Last Line:");
      Serial.println(gcode_LastN);
      return;
    }
  }

  //continues parsing only if we don't receive any 'N' or '*' or no errors if we do. :)
  
  if(code_seen('G'))
  {
    switch((int)code_value())
    {
      case 0: // G0 -> G1
      case 1: // G1
        get_coordinates(); // For X Y Z E F
        x_steps_to_take = abs(destination_x - current_x)*x_steps_per_unit;
        y_steps_to_take = abs(destination_y - current_y)*y_steps_per_unit;
        z_steps_to_take = abs(destination_z - current_z)*z_steps_per_unit;
        e_steps_to_take = abs(destination_e - current_e)*e_steps_per_unit;

        #define X_TIME_FOR_MOVE ((float)x_steps_to_take / (x_steps_per_unit*feedrate/60000000))
        #define Y_TIME_FOR_MOVE ((float)y_steps_to_take / (y_steps_per_unit*feedrate/60000000))
        #define Z_TIME_FOR_MOVE ((float)z_steps_to_take / (z_steps_per_unit*z_feedrate/60000000))
        //#define Z_TIME_FOR_MOVE ((float)z_steps_to_take / (z_steps_per_unit*feedrate/60000000))
        #define E_TIME_FOR_MOVE ((float)e_steps_to_take / (e_steps_per_unit*feedrate/60000000))
        
        time_for_move = max(X_TIME_FOR_MOVE,Y_TIME_FOR_MOVE);
        time_for_move = max(time_for_move,Z_TIME_FOR_MOVE);
        time_for_move = max(time_for_move,E_TIME_FOR_MOVE);

        if(x_steps_to_take) x_interval = time_for_move/x_steps_to_take;
        if(y_steps_to_take) y_interval = time_for_move/y_steps_to_take;
        if(z_steps_to_take) z_interval = time_for_move/z_steps_to_take;
        if(e_steps_to_take) e_interval = time_for_move/e_steps_to_take;
        
        if(DEBUGGING) {
          Serial.print("destination_x: "); Serial.println(destination_x); 
          Serial.print("current_x: "); Serial.println(current_x); 
          Serial.print("x_steps_to_take: "); Serial.println(x_steps_to_take); 
          Serial.print("X_TIME_FOR_MVE: "); Serial.println(X_TIME_FOR_MOVE); 
          Serial.print("x_interval: "); Serial.println(x_interval); 
          Serial.println("");
          Serial.print("destination_y: "); Serial.println(destination_y); 
          Serial.print("current_y: "); Serial.println(current_y); 
          Serial.print("y_steps_to_take: "); Serial.println(y_steps_to_take); 
          Serial.print("Y_TIME_FOR_MVE: "); Serial.println(Y_TIME_FOR_MOVE); 
          Serial.print("y_interval: "); Serial.println(y_interval); 
          Serial.println("");
          Serial.print("destination_z: "); Serial.println(destination_z); 
          Serial.print("current_z: "); Serial.println(current_z); 
          Serial.print("z_steps_to_take: "); Serial.println(z_steps_to_take); 
          Serial.print("Z_TIME_FOR_MVE: "); Serial.println(Z_TIME_FOR_MOVE); 
          Serial.print("z_interval: "); Serial.println(z_interval); 
          Serial.println("");
          Serial.print("destination_e: "); Serial.println(destination_e); 
          Serial.print("current_e: "); Serial.println(current_e); 
          Serial.print("e_steps_to_take: "); Serial.println(e_steps_to_take); 
          Serial.print("E_TIME_FOR_MVE: "); Serial.println(E_TIME_FOR_MOVE); 
          Serial.print("e_interval: "); Serial.println(e_interval); 
          Serial.println("");
        }
        
        linear_move(x_steps_to_take, y_steps_to_take, z_steps_to_take, e_steps_to_take); // make the move
        ClearToSend();
        return;
      case 4: // G4 dwell
        codenum = 0;
        if(code_seen('P')) codenum = code_value(); // milliseconds to wait
        if(code_seen('S')) codenum = code_value()*1000; // seconds to wait
        previous_millis_heater = millis();  // keep track of when we started waiting
        while((millis() - previous_millis_heater) < codenum ) manage_heater(); //manage heater until time is up
        break;
      case 90: // G90
        relative_mode = false;
        break;
      case 91: // G91
        relative_mode = true;
        break;
      case 92: // G92
        if(code_seen('X')) current_x = code_value();
        if(code_seen('Y')) current_y = code_value();
        if(code_seen('Z')) current_z = code_value();
        if(code_seen('E')) current_e = code_value();
        break;
        
    }
  }

  if(code_seen('M'))
  {
    
    switch( (int)code_value() ) 
    {
      case 101: // M101  forward
        set_direction(1);
        set_speed (extruder_speed);
        break;
      case 102: // M102  reverse
        set_direction(0);
        set_speed (extruder_speed);
        break;
      case 103: // M103  stop
        set_speed (0);
        break;
      case 104: // M104
        if (code_seen('S')) target_raw = temp2analog(code_value());
        set_variance ();
        break;
      case 105: // M105
        Serial.print("T:");
        Serial.println( analog2temp(analogRead(TEMP_0_PIN)) ); 
        if(!code_seen('N')) return;  // If M105 is sent from generated gcode, then it needs a response.
        break;
      case 106: // M106
        control_fan (1);
        break;
      case 107: // M107
        control_fan (0);
        break;
      case 108: // M108  set max extruder speed (0 - 255)
        if (code_seen('S')) extruder_speed = code_value();
        break;
      case 109: // M109 - Wait for heater to reach target.
        /*  This will be used to set temperature for bed/platform to conform to makerbot (will also use 140 for reprap)
        if (code_seen('S')) target_raw = temp2analog(code_value());
        previous_millis_heater = millis(); 
        while(current_raw < target_raw) {
          if( (millis()-previous_millis_heater) > 1000 ) //Print Temp Reading every 1 second while heating up.
          {
            Serial.print("T:");
            Serial.println( analog2temp(analogRead(TEMP_0_PIN)) ); 
            previous_millis_heater = millis(); 
          }
          manage_heater();
        } */
        if (code_seen('S')) target_platform = temp2analog(code_value());
        manage_platform ();
        break;
      case 118:  // M118 - return temperature of base/platform - is there makerbot/reprap equivalent?
        Serial.print("T:");
        Serial.println( analog2temp(analogRead(TEMP_B_PIN)) ); 
        if(!code_seen('N')) return;  // If M105 is sent from generated gcode, then it needs a response.
        break;
      case 140: // M140 - Wait for heater to reach target.
        if (code_seen('S')) target_platform = temp2analog(code_value());
        manage_platform ();
        break;
      case 18: // M18
        disable_x();
        disable_y();
        disable_z();
        disable_e();
        break;
      case 80: // M81 - ATX Power On
        if(PS_ON_PIN > -1) pinMode(PS_ON_PIN,OUTPUT); //GND
        break;
      case 81: // M81 - ATX Power Off
        if(PS_ON_PIN > -1) pinMode(PS_ON_PIN,INPUT); //Floating
        break;
      case 82:
        relative_mode_e = false;
        break;
      case 83:
        relative_mode_e = true;
        break;
      case 84:
        disable_x();
        disable_y();
        disable_z();
        disable_e();
        break;
      case 85: // M85
        code_seen('S');
        max_inactive_time = code_value()*1000; 
        break;
      case 86: // M86 If Endstop is Not Activated then Abort Print
        if(code_seen('X')) if( digitalRead(X_MIN_PIN) == ENDSTOPS_INVERTING ) kill(3);
        if(code_seen('Y')) if( digitalRead(Y_MIN_PIN) == ENDSTOPS_INVERTING ) kill(4);
        break;
      case 92: // M92
        if(code_seen('X')) x_steps_per_unit = code_value();
        if(code_seen('Y')) y_steps_per_unit = code_value();
        if(code_seen('Z')) z_steps_per_unit = code_value();
        if(code_seen('E')) e_steps_per_unit = code_value();
        break;
    }
    
  }
  
  ClearToSend();
}

inline void FlushSerialRequestResend()
{
  char cmdbuffer[100]="Resend:";
  ltoa(gcode_LastN+1, cmdbuffer+7, 10);
  Serial.flush();
  Serial.println(cmdbuffer);
  ClearToSend();
}

inline void ClearToSend()
{
  previous_millis_cmd = millis();
  Serial.println("ok"); 
}

inline void get_coordinates()
{
  if(code_seen('X')) destination_x = (float)code_value() + relative_mode*current_x;
  else destination_x = current_x;                                                       //Are these else lines really needed?
  if(code_seen('Y')) destination_y = (float)code_value() + relative_mode*current_y;
  else destination_y = current_y;
  if(code_seen('Z')) destination_z = (float)code_value() + relative_mode*current_z;
  else destination_z = current_z;
  if(code_seen('E')) destination_e = (float)code_value() + (relative_mode_e || relative_mode)*current_e;
  else destination_e = current_e;
  if(code_seen('F')) {
    next_feedrate = code_value();
    if(next_feedrate > 0.0) feedrate = next_feedrate;
  }
  
  //Find direction
  if(destination_x >= current_x) direction_x=1;
  else direction_x=0;
  if(destination_y >= current_y) direction_y=1;
  else direction_y=0;
  if(destination_z >= current_z) direction_z=1;
  else direction_z=0;
  if(destination_e >= current_e) direction_e=1;
  else direction_e=0;
  
  
  if (min_software_endstops) {
    if (destination_x < 0) destination_x = 0.0;
    if (destination_y < 0) destination_y = 0.0;
    if (destination_z < 0) destination_z = 0.0;
  }

  if (max_software_endstops) {
    if (destination_x > X_MAX_LENGTH) destination_x = X_MAX_LENGTH;
    if (destination_y > Y_MAX_LENGTH) destination_y = Y_MAX_LENGTH;
    if (destination_z > Z_MAX_LENGTH) destination_z = Z_MAX_LENGTH;
  }
  
  if(feedrate > max_feedrate) feedrate = max_feedrate;
}

void linear_move(unsigned long x_steps_remaining, unsigned long y_steps_remaining, unsigned long z_steps_remaining, unsigned long e_steps_remaining) // make linear move with preset speeds and destinations, see G0 and G1
{
  //Determine direction of movement
  if (destination_x > current_x) digitalWrite(X_DIR_PIN,!INVERT_X_DIR);
  else digitalWrite(X_DIR_PIN,INVERT_X_DIR);
  if (destination_y > current_y) digitalWrite(Y_DIR_PIN,!INVERT_Y_DIR);
  else digitalWrite(Y_DIR_PIN,INVERT_Y_DIR);
  if (destination_z > current_z) digitalWrite(Z_DIR_PIN,!INVERT_Z_DIR);
  else digitalWrite(Z_DIR_PIN,INVERT_Z_DIR);
  if (destination_e > current_e) digitalWrite(E_DIR_PIN,!INVERT_E_DIR);
  else digitalWrite(E_DIR_PIN,INVERT_E_DIR);
        if(DEBUGGING) {
           if (destination_x > current_x) 
             {
               Serial.print ("X_DIR_PIN"); Serial.print (X_DIR_PIN);
               Serial.print (" !INVERT_X_DIR"); Serial.print (!INVERT_X_DIR);
               Serial.println("");
             }
            else
             {
               Serial.print ("X_DIR_PIN"); Serial.print (X_DIR_PIN);
               Serial.print (" INVERT_X_DIR"); Serial.print (INVERT_X_DIR);
               Serial.println("");
             };
           if (destination_y > current_y)
             {
               Serial.print ("Y_DIR_PIN"); Serial.print (Y_DIR_PIN);
               Serial.print (" !INVERT_Y_DIR"); Serial.print (!INVERT_Y_DIR);
               Serial.println("");
             }
           else
             {
               Serial.print ("Y_DIR_PIN"); Serial.print (Y_DIR_PIN);
               Serial.print (" INVERT_Y_DIR"); Serial.print (INVERT_Y_DIR);
               Serial.println("");
             };
           if (destination_z > current_z)
             {
               Serial.print ("Z_DIR_PIN"); Serial.print (Z_DIR_PIN);
               Serial.print (" !INVERT_Z_DIR"); Serial.print (!INVERT_Z_DIR);
               Serial.println("");
             }
           else
             {
               Serial.print ("Z_DIR_PIN"); Serial.print (Z_DIR_PIN);
               Serial.print (" INVERT_Z_DIR"); Serial.print (INVERT_Z_DIR);
               Serial.println("");
             };
           if (destination_e > current_e)
             {
               Serial.print ("E_DIR_PIN"); Serial.print (E_DIR_PIN);
               Serial.print (" !INVERT_E_DIR"); Serial.print (!INVERT_E_DIR);
               Serial.println("");
             }
           else
             {
               Serial.print ("E_DIR_PIN"); Serial.print (E_DIR_PIN);
               Serial.print (" INVERT_E_DIR"); Serial.print (INVERT_E_DIR);
               Serial.println("");
             };
        }
  
  //Only enable axis that are moving. If the axis doesn't need to move then it can stay disabled depending on configuration.
  if(x_steps_remaining) enable_x();
  if(y_steps_remaining) enable_y();
  if(z_steps_remaining) enable_z();
  if(e_steps_remaining) enable_e();

  if(DEBUGGING) {
                Serial.println ("before possible zero step");
                Serial.print ("X_MIN_PIN "); Serial.print (X_MIN_PIN); 
                Serial.print (" direction_x "); Serial.print (direction_x); 
                Serial.print (" X_MIN_PIN "); Serial.print (X_MIN_PIN); 
                Serial.print (" ENDSTOPS_INVERTING "); Serial.print (ENDSTOPS_INVERTING); 
                Serial.println ("");
                Serial.print ("Y_MIN_PIN "); Serial.print (Y_MIN_PIN); 
                Serial.print (" direction_y "); Serial.print (direction_y); 
                Serial.print (" Y_MIN_PIN "); Serial.print (Y_MIN_PIN); 
                Serial.print (" ENDSTOPS_INVERTING "); Serial.print (ENDSTOPS_INVERTING); 
                Serial.println ("");
                Serial.print ("Z_MIN_PIN "); Serial.print (Z_MIN_PIN); 
                Serial.print (" direction_z "); Serial.print (direction_z); 
                Serial.print (" Z_MIN_PIN "); Serial.print (Z_MIN_PIN); 
                Serial.print (" ENDSTOPS_INVERTING "); Serial.print (ENDSTOPS_INVERTING); 
                Serial.println ("");
                };
  if(X_MIN_PIN > -1) if(!direction_x) if(digitalRead(X_MIN_PIN) != ENDSTOPS_INVERTING) x_steps_remaining=0;
  if(Y_MIN_PIN > -1) if(!direction_y) if(digitalRead(Y_MIN_PIN) != ENDSTOPS_INVERTING) y_steps_remaining=0;
  if(Z_MIN_PIN > -1) if(!direction_z) if(digitalRead(Z_MIN_PIN) != ENDSTOPS_INVERTING) z_steps_remaining=0;
  
  previous_millis_heater = millis();

  if(DEBUGGING) {
                Serial.println ("before while loop steps remaining");
                Serial.print ("x_steps_remaining "); Serial.print (x_steps_remaining); Serial.println ("");
                Serial.print ("y_steps_remaining "); Serial.print (y_steps_remaining); Serial.println ("");
                Serial.print ("z_steps_remaining "); Serial.print (z_steps_remaining); Serial.println ("");
                Serial.print ("e_steps_remaining "); Serial.print (e_steps_remaining); Serial.println ("");
                };
  //while(x_steps_remaining > 0 || y_steps_remaining > 0 || z_steps_remaining > 0 || e_steps_remaining > 0) // move until no more steps remain
  while(x_steps_remaining + y_steps_remaining + z_steps_remaining + e_steps_remaining > 0) // move until no more steps remain
  { 
    if(x_steps_remaining) {
      if ((micros()-previous_micros_x) >= x_interval) { do_x_step(); x_steps_remaining--; }
      if(X_MIN_PIN > -1) if(!direction_x) if(digitalRead(X_MIN_PIN) != ENDSTOPS_INVERTING) x_steps_remaining=0;
    }
    
    if(y_steps_remaining) {
      if ((micros()-previous_micros_y) >= y_interval) { do_y_step(); y_steps_remaining--; }
      if(Y_MIN_PIN > -1) if(!direction_y) if(digitalRead(Y_MIN_PIN) != ENDSTOPS_INVERTING) y_steps_remaining=0;
    }
    
    if(z_steps_remaining) {
      if ((micros()-previous_micros_z) >= z_interval) { do_z_step(); z_steps_remaining--; }
      if(Z_MIN_PIN > -1) if(!direction_z) if(digitalRead(Z_MIN_PIN) != ENDSTOPS_INVERTING) z_steps_remaining=0;
    }    
    
    if(e_steps_remaining) if ((micros()-previous_micros_e) >= e_interval) { do_e_step(); e_steps_remaining--; }
    
    if( (millis() - previous_millis_heater) >= 500 ) {
      manage_heater();
      previous_millis_heater = millis();
      manage_platform();
      manage_inactivity(2);
    }
  }
  
  if(DEBUGGING) {
                Serial.println ("after while loop steps remaining");
                Serial.print ("x_steps_remaining "); Serial.print (x_steps_remaining); Serial.println ("");
                Serial.print ("y_steps_remaining "); Serial.print (y_steps_remaining); Serial.println ("");
                Serial.print ("z_steps_remaining "); Serial.print (z_steps_remaining); Serial.println ("");
                Serial.print ("e_steps_remaining "); Serial.print (e_steps_remaining); Serial.println ("");
                };
  if(DISABLE_X) disable_x();
  if(DISABLE_Y) disable_y();
  if(DISABLE_Z) disable_z();
  if(DISABLE_E) disable_e();
  
  // Update current position partly based on direction, we probably can combine this with the direction code above...
  if (destination_x > current_x) current_x = current_x + x_steps_to_take/x_steps_per_unit;
  else current_x = current_x - x_steps_to_take/x_steps_per_unit;
  if (destination_y > current_y) current_y = current_y + y_steps_to_take/y_steps_per_unit;
  else current_y = current_y - y_steps_to_take/y_steps_per_unit;
  if (destination_z > current_z) current_z = current_z + z_steps_to_take/z_steps_per_unit;
  else current_z = current_z - z_steps_to_take/z_steps_per_unit;
  if (destination_e > current_e) current_e = current_e + e_steps_to_take/e_steps_per_unit;
  else current_e = current_e - e_steps_to_take/e_steps_per_unit;
}


inline void do_x_step()
{
  digitalWrite(X_STEP_PIN, HIGH);
  previous_micros_x = micros();
  //delayMicroseconds(3);
  digitalWrite(X_STEP_PIN, LOW);
}

inline void do_y_step()
{
  digitalWrite(Y_STEP_PIN, HIGH);
  previous_micros_y = micros();
  //delayMicroseconds(3);
  digitalWrite(Y_STEP_PIN, LOW);
}

inline void do_z_step()
{
  digitalWrite(Z_STEP_PIN, HIGH);
  previous_micros_z = micros();
  //delayMicroseconds(3);
  digitalWrite(Z_STEP_PIN, LOW);
}

inline void do_e_step()
{
  if (USE_MOTOR == false)
    {
    digitalWrite(E_STEP_PIN, HIGH);
    //delayMicroseconds(3);
    digitalWrite(E_STEP_PIN, LOW);
    }
  previous_micros_e = micros();
}

inline void disable_x() { if(X_ENABLE_PIN > -1) digitalWrite(X_ENABLE_PIN,!X_ENABLE_ON); }
inline void disable_y() { if(Y_ENABLE_PIN > -1) digitalWrite(Y_ENABLE_PIN,!Y_ENABLE_ON); }
inline void disable_z() { if(Z_ENABLE_PIN > -1) digitalWrite(Z_ENABLE_PIN,!Z_ENABLE_ON); }
inline void disable_e() { if(E_ENABLE_PIN > -1) { if (USE_MOTOR == false) { digitalWrite(E_ENABLE_PIN,!E_ENABLE_ON); } }; }
inline void  enable_x() { if(X_ENABLE_PIN > -1) digitalWrite(X_ENABLE_PIN, X_ENABLE_ON); }
inline void  enable_y() { if(Y_ENABLE_PIN > -1) digitalWrite(Y_ENABLE_PIN, Y_ENABLE_ON); }
inline void  enable_z() { if(Z_ENABLE_PIN > -1) digitalWrite(Z_ENABLE_PIN, Z_ENABLE_ON); }
inline void  enable_e() { if(E_ENABLE_PIN > -1) { if (USE_MOTOR == false) { digitalWrite(E_ENABLE_PIN, E_ENABLE_ON); } }; }

inline void manage_heater()
{
  current_raw = get_extruder_temperature ();
  if (millis() > extruderheaterTime) //only activate/deactivate after 1/2 second to prevent rapid on/off
    {
    if(current_raw >= target_raw)
      {
      digitalWrite(HEATER_0_PIN,LOW);
      extruderheaterTime = millis() + 500;
      }
    else
      {
      digitalWrite(HEATER_0_PIN,HIGH);
      extruderheaterTime = millis() + 500;
      }
    }
  //if(current_raw >= target_raw) Serial.println ("heater low");
  //else Serial.println ("heater high");
}

inline void manage_platform()  //copy/paste of manage_heater (almost)
{
  current_platform = get_platform_temperature ();
  //limit switching to once every so often to prevent over activating relay (annoying sound)
  if (millis() > platformrelayTime) //if time to activate relay check temperature
     {
     if(current_platform >= target_platform)
       {
        digitalWrite(BASE_HEATER_PIN,LOW);
        platformrelayTime = millis() + 1000; //wait 1 second to see if need to turn platform on
       }
     else
       {
        digitalWrite(BASE_HEATER_PIN,HIGH);
        platformrelayTime = millis() + 2000;  //wait 2 seconds before seeing if temp is lower
       }
    }
  //if(current_raw >= target_raw) Serial.println ("heater low");
  //else Serial.println ("heater high");
}

// Takes temperature value as input and returns corresponding analog value from RepRap thermistor temp table.
// This is needed because PID in hydra firmware hovers around a given analog value, not a temp value.
// This function is derived from inversing the logic from a portion of getTemperature() in FiveD RepRap firmware.
float temp2analog(int celsius) {
  if(USE_THERMISTOR) {
    int raw = 0;
    byte i;
    
    for (i=1; i<NUMTEMPS; i++)
    {
      if (temptable[i][1] < celsius)
      {
        raw = temptable[i-1][0] + 
          (celsius - temptable[i-1][1]) * 
          (temptable[i][0] - temptable[i-1][0]) /
          (temptable[i][1] - temptable[i-1][1]);
      
        break;
      }
    }

    // Overflow: Set to last value in the table
    if (i == NUMTEMPS) raw = temptable[i-1][0];

    return 1023 - raw;
  } else {
    return celsius * (1024.0/(5.0*100.0));
  }
}

//returns extruder temperature from one place with how it was used..  :(
int get_extruder_temperature () {
  current_raw = analogRead(TEMP_0_PIN);                  // If using thermistor, when the heater is colder than targer temp, we get a higher analog reading than target, 
  if(USE_THERMISTOR) current_raw = 1023 - current_raw;   // this switches it up so that the reading appears lower than target for the control logic.
  return current_raw;
}

//returns platform temperature from one place with how it was used..  :(
int get_platform_temperature () {
  current_platform = analogRead(TEMP_B_PIN);                  // If using thermistor, when the platform is colder than targer temp, we get a higher analog reading than target, 
  if(USE_THERMISTOR) current_platform = 1023 - current_platform;   // this switches it up so that the reading appears lower than target for the control logic.
  return current_platform;
}

// Derived from RepRap FiveD extruder::getTemperature()
float analog2temp(int raw) {
  if(USE_THERMISTOR) {
    int celsius = 0;
    byte i;

    for (i=1; i<NUMTEMPS; i++)
    {
      if (temptable[i][0] > raw)
      {
        celsius  = temptable[i-1][1] + 
          (raw - temptable[i-1][0]) * 
          (temptable[i][1] - temptable[i-1][1]) /
          (temptable[i][0] - temptable[i-1][0]);

        break;
      }
    }

    // Overflow: Set to last value in the table
    if (i == NUMTEMPS) celsius = temptable[i-1][1];

    return celsius;
    
  } else {
    return raw * ((5.0*100.0)/1024.0);
  }
}

inline void set_direction(byte dir)
{
//changed this around due to two pins on polulu motor controller that drive the voltage
        switch (dir) {
        case 0: //reverse
          {
          if(DEBUGGING) { Serial.println ("reverse"); };
  	  digitalWrite(E_DIR_PIN, HIGH);
	  digitalWrite(E_ENABLE_PIN, LOW);
          digitalWrite (MOTOR_ENABLE_PIN, HIGH);
          break;
          }
        case 1: //forward
          {
          if(DEBUGGING) { Serial.println ("forward"); };
  	  digitalWrite(E_DIR_PIN, LOW);
	  digitalWrite(E_ENABLE_PIN, HIGH);
          digitalWrite (MOTOR_ENABLE_PIN, HIGH);
          break;
          }
        case 2: //stop
          {
          if(DEBUGGING) { Serial.println ("stop"); };
          digitalWrite (MOTOR_ENABLE_PIN, LOW);
          digitalWrite (E_DIR_PIN, LOW);
          digitalWrite (E_ENABLE_PIN, LOW);
          break;
          }
        default:
          {
          if(DEBUGGING) { Serial.println ("default"); };
          digitalWrite (MOTOR_ENABLE_PIN, LOW);
          digitalWrite (E_DIR_PIN, LOW);
          digitalWrite (E_ENABLE_PIN, LOW);
          }
        }
}

inline void set_speed(byte sp)
{
      if(sp > 0)
          wait_till_hot();
      if(DEBUGGING) { Serial.println ("speed set"); };
      analogWrite(E_STEP_PIN, sp);
      return;
}

inline void set_variance ()
{
  //only figure out when real value is set
  if (target_raw > 50)
    {
    target_var = target_raw - temp2analog(TEMP_VARIANCE);
    }
  else
    {
    target_var = target_raw;
    };
  if(DEBUGGING)
    {
    Serial.print ("target_var :");
    Serial.println (target_var);
    Serial.print ("target_raw :");
    Serial.println (target_raw);
    Serial.print ("temp_variance :");
    Serial.println (temp2analog(TEMP_VARIANCE));
    }
}

inline void control_fan(byte dir)
{
//changed this around due to two pins on polulu motor controller that drive the voltage
        switch (dir) {
        case 0: //off
          {
          if(DEBUGGING) { Serial.println ("fan off"); };
  	  digitalWrite(FAN_PIN, LOW);
          break;
          }
        case 1: //on
          {
          if(DEBUGGING) { Serial.println ("fan on"); };
  	  digitalWrite(FAN_PIN, HIGH);
          break;
          }
        default: //default off
          {
          if(DEBUGGING) { Serial.println ("fan default"); };
          digitalWrite (FAN_PIN, LOW);
          }
        }
}

byte wait_till_hot()
{ 
  oldT = get_extruder_temperature ();
  //to prevent excessive stops obey variance instead as temp will always fluctuate a little above and below
  //while (oldT < target_raw)
  while (oldT < target_var)
  {
	manage_heater();
        newT = get_extruder_temperature();
        if(newT > oldT)
           oldT = newT;
        Serial.print("T:");
        Serial.println( analog2temp(analogRead(TEMP_0_PIN)) ); 
        previous_millis_heater = millis(); 
	delay(1000);
  }
}

inline void kill(byte debug)
{
  if(HEATER_0_PIN > -1) digitalWrite(HEATER_0_PIN,LOW);
  
  disable_x;
  disable_y;
  disable_z;
  disable_e;
  
  if(PS_ON_PIN > -1) pinMode(PS_ON_PIN,INPUT);
  
  while(1)
  {
    switch(debug)
    {
      case 1: Serial.print("Inactivity Shutdown, Last Line: "); break;
      case 2: Serial.print("Linear Move Abort, Last Line: "); break;
      case 3: Serial.print("Homing X Min Stop Fail, Last Line: "); break;
      case 4: Serial.print("Homing Y Min Stop Fail, Last Line: "); break;
    } 
    Serial.println(gcode_LastN);
    delay(5000); // 5 Second delay
  }
}

inline void manage_inactivity(byte debug) { if( (millis()-previous_millis_cmd) >  max_inactive_time ) if(max_inactive_time) kill(debug); }
