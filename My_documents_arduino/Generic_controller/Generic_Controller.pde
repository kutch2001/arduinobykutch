#define thisDev 'T'        //  0 is local serial, 1 is Bridge router and a to z are controllers.

/*
 2009-01-30
 S George Matthews
 gmatthews at mmcs.com
 
 Controller using...
 TempLM335
 and
 Wire 11 network 2-wire protocol
 and
 EEPROM Recorder
 and
 Microcontroller Remote Management Protocol (MRMP) (Controller authentication) with routing to Wire
 A simple printable ASCII packet protocol for communicating with Atmel AVR
 */

#include <stdlib.h>          // ASCII to Dec and Dec to ASCII
#include <NewSoftSerial.h>   // ability to use more than one serial device
#include <Streaming.h>       // ability to string commands to print
byte fromDev = '0' ;         // The 'control' device by default 0 to 9 valid
byte tagrmp = '?' ;          // Serial Com. Protocol tag for packet ASCII 33 to 127
byte packetType = '0';       // I K R B G P 0
byte command = '0';          // Byte 4 These following by parameters and values
char group = '\0';           // group and user for authenticated access
byte  user = 0;
char delimiter = ',';          // Delimiter to use between each field
char terminator = '#';         // Used to define end of message

byte commandParameters = 0;  //Byte 5 
//Byte 6 is ','
byte commandOK = 0;          //at this point command is executable

// Bytes 7 to 9. See field array notes. [1]
int field = 0;               // 00 to 99  bytes 8 aand 9
int fieldType = 0;           // 100, 200, 300 to 900 byte 7 + 00

// Followed by up to 3 comma seperated data elements
#define maxParameters '3'   //  1 2 3 = number of the following string Data arrays.

#define dataFieldArray 64   // The size of the entire inbound data array
#define dataFieldsize 20    // The size of each element terminated with '\0' = +1 to size

byte parameterCount = 0;       // Current parameter being prcessed
byte pByteCount = 0;           // current byte count for the current Parameter
char stData[dataFieldArray];  // The temp inbound data array poked one char at a time by nextData()

// stData format using the above #define where n is a '\0' a Null.
// 0123456789123456789n01234567890123456789n01234567890123456789nn
// Field number        | Data               | Data optional

long parm1; // First MRMP Data Parameter converted long
long parm2; // Second MRMP Data Parameter converted long
long parm3; // Third MRMP optional Data Parameter converted long

byte inByte = '0';    // Byte count read from serial port

byte  toDev = '?';         // Device code any printable ASCII valid

char packetByte = 0;       // Packet byte to interpret next
byte packetDiscard = 0;    // Packet byte discard this one
byte newInvite = 0;        // New Invite flag

// Reserved fields... Bridge will update *absolute_time_t501
long *time_t500 = 0;  // Seconds since startup
long *absolute_time_t501 = 0;  // Updated periodically

// Simple ascii to dec sting conversion function

byte ASCIItoDEC1 (byte u)  // 0 to 9
{
  return constrain(u-48,0,9);
}

// ============== MRMP functions ==========================
// =======================================================

void okay()
{
  //Serial.print(" Okay to: ");             // debug
  //Serial.print(toDev);             // debug
  packetHeader('#','K');

}

// &&&&&&&&&&&&&&&&&  Voltage on Pin  &&&&&&&&&&&&&&&&&&&&&&&&&
// Battery is connected via two 5.1v Zener diodes, and therefore 0 = 10.2V or 102
// In practice 9.6 volts = 97
// We have 10 bits (1024) to reprsent 5v range of A/D = 1024/5 = 204.8 0r 205 bits per volt
// Returns 10x the voltage on pin +- the offset.
int getVoltsOnPin(byte pin, int offset)
{
  int volts; 
  volts = analogRead(pin) * 10;  // 00 to 50 = 0 to 5.0 volts
  volts = ( volts / 205 ) + offset; // Add/Subtract the volts offset from zero.
  return (volts);

}

void routeWirePacket(char add, char data)   // Packet is not for this device so route it to othe wire device.
{
  if (add == '0')  // Local serial port
  {
    Serial.print(data);          // send it out the serial port for this device
    if (data == '#')
    {
      Serial.println();
    }
  }
}


void RTPError(byte b)
{

  packetHeader('E', 'R');
  routeWirePacket(fromDev,'1');
  routeWirePacket(fromDev,','); 
  routeWirePacket(fromDev,b);  
  routeWirePacket(fromDev,'#');

}


void RTPdataERROR(byte e)
{
  packetHeader('E', 'R');
  routeWirePacket(fromDev,'1');
  routeWirePacket(fromDev,','); 
  routeWirePacket(fromDev,e);
  routeWirePacket(fromDev,','); 
  routeWirePacket(fromDev,command);
  routeWirePacket(fromDev,',');
//    routeWirePacket(fromDev,stData);
  //for (int i=0; *(stData + i) != 0 ; i++) // Send byte by byte until null
  //{
  //  routeWirePacket(fromDev, *(stData + i));
  //}

  routeWirePacket(fromDev,'#');
}

void nextData( char p )
{
  //Serial.print("NextData:"); // Debug
  if((pByteCount + ( parameterCount * dataFieldsize)) >= dataFieldArray )
  {
    RTPError('4');   // Outside the bounds of the array

    parameterCount = 0;           // Current parameter being prcessed
    commandOK = 0;                // command is executable or has been done
    commandParameters = 0;        // 6th packetByte
    packetDiscard = 0;            // Discarded. Try next packet
  }
  else
  {
    if(parameterCount >= (commandParameters -1))
    {
      commandOK = 1; 
    }
    *(stData + (pByteCount + parameterCount + (parameterCount * dataFieldsize))) = p;  //poke p into the stData array
    pByteCount++ ;
  }
}


void processCommand(char c, char p) // Current command and next paramenter character
{
  if( c == 'A' || c == 'G' || c == 'P' || c == 'T' || c == 'R'|| c == 'V' || c == 'S' || c == 'B')
  {
    // Have 
    // Then to finish R10vG1,502# or R10vP2,502,7654# or R10vT2,902,7654#
    // parmeters for either Get, Put or Temperature
    //Realtime count followed by 
    // 
    if (p != ',')  // a delimeter between data elements
    {
      nextData( p ); 
    }
    else
    {
      // Move ahead  to ensure n \0 is at the end of the data element.
      pByteCount = 0;
      parameterCount++;
    }
  }
}

void nullData()   // Wipe stData buffer with nulls
{
  for (int i=0; i <= dataFieldArray  ; i++)   // Be sure dataFieldArray is less that 255 or use an int loop
  {
    *(stData + i ) = '\0';
  }   
}


long getData()
{
  return 0; // Not implemented
}


void putData()   // fieldType = FieldBase, field = element in the array
{
}

/*
 
 long getTemp()   // fieldType = FieldBase, field = sensor or channel
 {
 switch (fieldType) 
 {
 case (otherBase):   // Currently ony 900 range
 //
 
 // pin  = field // 0 to 5 else error
 // offset= atoi(stData + (dataFieldsize + 1 ) )  // each temp channel has a custom offset
 //
 // 1 = 5574 air
 // 0 = 5670 water
 
 // slope = BitsPerDegree
 // tempOnPin = 10x the degrees c, which peovides a single decimal point resolution.
 // roundTemp = last digit rounded down to 0, 5 or rounded up to next.
 
 if ((field >= 0) && (field <= 4))  // Valid analog pins for temperature 4 and 5 used for Wire.h
 {
 return (tempOnPin(field,atoi(stData + (dataFieldsize + 1 )),BitsPerDegree)) ;
 }
 else
 {
 // RTPdataERROR('t');
 return TempError;
 
 }
 
 break;
 
 
 default: 
 // RTPdataERROR('t');
 return TempError;
 }
 }
 */

void RpacketData(long data)   // Sends ,1234   where 1234 is data
{
  routeWirePacket(fromDev,',');
  nullData();                        // Wipe stData inbound buffer so we can use it for data conversion
  // routeWirePacket(fromDev,data);         // The actual data passed

  ltoa(data,stData,10);

  for (int i=0; *(stData + i) != 0 ; i++) // Send byte by byte until null
  {
    routeWirePacket(fromDev, *(stData + i));
  }
  nullData();                        // Wipe stData inbound buffer so we can use it for data conversion



}

// c == command, t == type
void packetHeader(char c, char t)
{
  Serial << "in packetHeader " << c << "-" << t << endl;
  routeWirePacket(fromDev,t);
  routeWirePacket(fromDev,fromDev);
  routeWirePacket(fromDev,thisDev);
  routeWirePacket(fromDev,tagrmp);

  routeWirePacket(fromDev,c);

}


void RpacketReply(long data)
{
  Serial.println ("in RpacketReply");
  packetHeader(command, 'R');
  routeWirePacket(fromDev,'2');
  routeWirePacket(fromDev,',');

  for (int i=0; *(stData + i) != 0 ; i++) // Send byte by byte until null
  {
    routeWirePacket(fromDev, *(stData + i));
  }
  RpacketData(data);
  routeWirePacket(fromDev,'#');

}

// p = parameters
// stData must already be formated with comma separated data strings to send ending with a null


// stData format using the above #define where n is a '\0' a Null.
// 0123456789123456789n01234567890123456789n01234567890123456789nn
// Field number        | Data               | Data optional
// 0                   21                   42                  




void executeCommand()  // Commands built by processCommand will be executed
{
  Serial.println ("in executecommand");
  // These parameters sit in the stData array
  parm1 = strtol(stData,'\0',10);
  parm2 = strtol(stData + (dataFieldsize + 1 ),'\0',10);
  parm3 = strtol(stData + ((2 * dataFieldsize) + 2),'\0',10);
  Serial.println (stData);
  Serial << "parm1:" << parm1 << endl;
  Serial << "parm2:" << parm2 << endl;
  Serial << "parm3:" << parm3 << endl;
  Serial << "stData:" << stData << endl;
  fieldType = 100 * (ASCIItoDEC1(*stData));  // First byte
  field =  parm1 - fieldType;
  if(command != 'A')
  {
    if(group == 'a' || group == 'm')  // Must be authenticated
    {
      // Now process the command type
      // Determine the field type and which field
      // okay(); // Send a packet that it's OKAY and reply packet to follow
      switch (command) 
      {
      case 'G':
        long d;
        d = getData();
        RpacketReply(d); 
        break;

      case 'P':
        putData();
        break;

      case 'T':
        //Temperature data from sensors
        // The replay packet 
        // pin and offset passed in 900 series packet bytes.  
        // R10vT2,901,5562#
        // pin 1
        // offset 5562
        //RpacketReply(getTemp(field, parm2));
        break;

      case 'V': 
        RpacketReply(getVoltsOnPin(field - 50, parm2));
        break;


      case 'B':
        /*  Rp1vB1,962,0#
         Returns 0 to 1023.
         962 represents analog channel 2.
         960-969 are accepted, but 960 to 963  representing 0 - 3 are typical limts and therefore other values will be nonsense.  4 and 5 are dedicated to the Wire bus.
         */
        RpacketReply(analogRead(field - 60));
        break;

      case 'S':

        /*  Rp1vS1,944#
         Returns True or False. 1 or 0.
         944 represents digital pin 4.
         940-999 are accepted, but 940-956  are typical limits representing pins 0 to 16 and therefore other values will be nonsense.
         */
        RpacketReply(digitalRead(field - 40));
        break;

      case 'R':  

        // See MMRP documentation
          int p;
          RpacketReply(p);
          break;
      }

      nullData();          // Wipe stData inbound buffer
      parameterCount = 0;    // Current parameter being prcessed
      commandOK = 0;         // command has been done
      commandParameters = 0; // 6th packetByte
      packetDiscard = 0;     // Discard. Try next packet

    }
    else
    {
      RTPdataERROR('a');
    }
  }
  else
  {
    // 'A'  // Try to authenticate
      // Serial.println(" Authenticating... ");  // Dbug
    // User = ASCIItoDEC1(*stData)
    // PassCodeAdd  *stData + 1

    // group returned by  SecurityValidatePass();

    // printstData(); // Debug


    group = *(stData +  dataFieldsize + 1);  

    if(group)  // If no group passed on second parameter it will be null.
    {
      Serial.println ("authenticated OK");
      user = ASCIItoDEC1(*stData);
      RTPError('0'); // Send a packet that authentication is OKAY
    }
    else
    {
      Serial.println ("authentication failure");
      user = 0;
      RTPdataERROR('q');
    }
  }
}

// +++++++++++++++++ SCP main +++++++++++++++++++++
//       Serial Communication Protocol
// ++++++++++++++++++++++++++++++++++++++++++++++++
//
//                  Routing
// If this device is '1' it is the Bridge for routing to/from Wire devices
// If toDev !=0 or !=1 then it is sent out the Wire
// If the toDev is = '0' then the date is sent out the local serial port
// 
// If this device is a Controller, no data is routed.
// Data not destined for the Controller is simply ignored (eaten)
void getAvailableSerial()   // Check if any bytes are arriving on the serial port
{
  delay(10); // Or you will overun the buffer
  if (Serial.available() > 0) 
  {
    //    fromSerialPort = 1; // So we can wipe the Packet Buffer.
    // read the incoming byte:
    inByte = Serial.read();
    if ((inByte <= 128 ) && (inByte >= 32 ))  // Only printable ASCII
    {
      processPackets();
    }
  }
}

void processPackets()   // Process byes from either Serial port or Wire bus.
{
  //   blinkLED();
  packetByte++;
  if (inByte == '#' ) 
  {        // End of packet byte, so reset for next packet.
    Serial.println();  // To allow end of line detection in Telnet sessions
    if(commandOK == 1)
    {
      executeCommand();          // The complete packet was received so execute!
    }

    // Get ready for the next packet
    parameterCount = 0;         // Current parameter being prcessed
    commandOK = 0;              // command is ot executable or has been done
    packetByte = 0;             // contains the next packet byte
    command = '0';              // 5th packetByte
    commandParameters = 0;      // 6th packetByte
    packetDiscard = 0;          // Discard. Try next packet
  }

  if (packetDiscard == 0) 
  {
    //
    switch (packetByte) {
    case 1:
      // Packet type first byte
      switch (inByte) {

      case 'I':
        // Invite
        packetDiscard = 0;         
        newInvite = 1;
        packetType = 'I'; 
        break;

      case 'K':
        // OK
        packetDiscard = 0;
        packetType = 'K';
        break;

      case 'R':
        // RTP
        packetDiscard = 0;
        packetType = 'R';
        pByteCount = 0;
        break;

      case 'B':
        // BYE
        packetDiscard = 0;
        packetType = 'B';
        break;

      default:
        // Not any know type
        // packetDiscard = 1;
        packetType = '0';
        packetByte = 0; // Keep parsing the inbound characters until a know packet type is encountered.
      }
      break;

    case 2:
      // To: second byte
      toDev = inByte;
      if (toDev != thisDev)  // Is it for us?
      {
        commandOK = 0;
        packetDiscard = 1;  // Eat the packet if you are a Controller and it is not for you
      }
      break;

    case 3:
      // From: third byte, device sending
      {
        fromDev = inByte;  // Who is it from?  Save that for replies.
      }
      break;

    case 4:
      // Tag for the SCP. Subsequent tag for other packets must have same tag.
      if (newInvite == 1) // If a new invite, save the tag for other packet processing
      {
        tagrmp = inByte;
        newInvite = 0;
        okay();
      }
      if (packetType == 'R')    // Are we in a Realtime packet exchange?
      {
        if (tagrmp != inByte) {  // Is it the same tag as recorded previously?
          tagrmp = '?';          // No the null it, discard and toss an error.
          RTPError('1');
          packetDiscard = 1;
        }
      }
      if (packetType == 'B')  // Bye? Then lets forget about this tag
      {
        // Then be polite and acknowledge with a Bye
        packetHeader('#','B');
        packetDiscard = 1;
        tagrmp = '?';
        group = '\0';
        user = 0;
      }
      break;

    case 5:
      // command
      if (packetDiscard != 1) 
      {
        command = inByte;    // 5th packetByte
      }
      break;

    case 6:
      // Parameter count
      if (packetDiscard != 1) 
      {   
        // Check that the count is 1 to 3 ASCII
        if ((inByte >= '1') && (inByte <= maxParameters))
        {
          commandParameters = ASCIItoDEC1(inByte);    // convert to decimal 6th packetByte
        }
        else
        {
          packetDiscard = 1;  // not between 0 and 9 so discard
          RTPError('3'); 
        }
      }      
      break;

    case 7:
      // Data or command
      if (packetDiscard != 1) 
      {
        if(inByte = ',')  // command followed by a comma
        {
          parameterCount = 0;  // Reset the loop to process parameters
          pByteCount = 0;  
        }
        else
        {
          packetDiscard = 1;
          RTPError('5'); 
        }
      }
      break;

    default:
      // Data parameter
      if (packetDiscard != 1) 
      {  // There will be a variable amount of data to follow starting at th 7th byte
        processCommand(command,inByte);
      } 
    }
  }
}

// *************** Setup ***************************
// *************************************************
void setup() {

  // begin the serial communication
  Serial.begin(9600);
  Serial.print("W:");
  Serial.println(thisDev);
}

// %%%%%%%%%%%%%%%%%%%  Loop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
void loop() 
{
  getAvailableSerial();    // Serial Communication Protocol
  //tickTock();              // Counts seconds and quarter seconds since startup
}

