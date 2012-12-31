// Copyright 2009 by Steve Conklin http://www.antitronics.com
// released to the public domain
//
// derived from some code and ideas by Maurice Ribble:
// http://www.glacialwanderer.com/hobbyrobotics
// http://www.glacialwanderer.com/hobbyrobotics/?cat=5&paged=2

// This sketch sends the values from the first three analog inputs to a web server
// for logging. It uses the adafruit ethernet shield with an XPort module installed.
// The XPORT connections and configuration are *almost* the same as documented on the adafruit
// web site: http://www.ladyada.net/make/eshield/index.html
//
// You must install the AF_XPort and NewSoftSerial libraries - see ladyada's site for links to them
//
// XPort connections on the eshield:
//
// XPort RX pin -> Arduino digital pin 2
// XPort TX pin -> Arduino digital pin 3
// XPort Reset pin -> Arduino digital pin 4
// XPort DTR pin -> Arduino digital pin 5 (not used)
// XPort CTS pin -> Arduino digital pin 6
// XPort RTS pin -> Arduino digital pin 7 (not used)
//
// XPort configuration:
//
// *** Channel 1
// Baudrate 57600, I/F Mode 4C, Flow 02
// Port 10001
// Connect Mode : D4
// Send '+++' in Modem Mode enabled
// Show IP addr after 'RING' enabled
// Auto increment source port disabled
// Remote IP Adr: --- none ---, Port 00000
// Disconn Mode : 80  Disconn Time: 00:03 <=== Different than adafruit example, she uses Disconn Mode = 0
// Flush   Mode : 77

// These are web server specific values
/*#define PHP_PAGE_LOCATION "/monitor/power.php"
#define WEB_HOST "HOST: mydomainname.com\n\n"
#define CONN_IP "172.130.0.003"
#define CONN_PORT 80
*/
#define IPADDR "209.40.205.190"  // pachube.com
#define PORT 80
#define HTTPPATH "/api/6726.csv"      // The feed - nnnn is your feed number
#define APIKEY "255d6abafa754c1bc9e792ff14754ce69bdab1b67b6fdeccbde3a05f624777b0"          // my API key
#define HOSTNAME "pachube.com"

#include "AF_XPort.h"
#include "NewSoftSerial.h"

// the xport!
#define XPORT_RX        2
#define XPORT_TX        3
#define XPORT_RESET     4
#define XPORT_CTS       6
#define XPORT_RTS       7
#define XPORT_DTR       5
AF_XPort xport = AF_XPort(XPORT_RX, XPORT_TX, XPORT_RESET, XPORT_DTR, XPORT_RTS, XPORT_CTS);

#define vers "1.4"      // version - output to Pachube
#define MAXBUFLEN 255
char linebuffer[MAXBUFLEN+1]; // our large buffer for data - this gets reused so be careful not to overwrite data we are reading
int retstat;
int buflength;
uint8_t success;
int ret;

void printstatus(int)
{
  // no output for success
  if (retstat == ERROR_TIMEDOUT)
    Serial.println("ERROR: Timeout");
  else if (retstat == ERROR_BADRESP)
    Serial.println("ERROR: Bad Response");
  else if (retstat == ERROR_DISCONN)
    Serial.println("ERROR: Disconnect");

  return;
}

void setup()
{
  Serial.begin(9600);
  Serial.println ("waiting 15 seconds");
  delay(15000);
  xport.begin(9600);
  //retstat = xport.reset();
  printstatus(retstat);
  Serial.println("XPort ready");
}

void loop()
{
  success = 0;
  Serial.println ("success");
  int value0, value1, value2;
  uint8_t read;
  //Serial.println("Connecting");
  retstat = xport.connect(IPADDR, PORT);
  Serial.println ("connected");
  printstatus(retstat);
  //Serial.println("Sending GET");

  Serial.println("analog read");
  value0 = analogRead(0);
  value1 = analogRead(1);
  value2 = analogRead(2);
    // sprintf does not handles floats so help it out
  sprintf(linebuffer,"%s,%s,%0d.%d,%0d.%d,%d,%d",vers,(int)value0,(int)value1,(int)value2);
  Serial.println("linebuffer");

  // send the HTTP command, ie "PUT /api/nnnn"
  xport.print("PUT "); 
  xport.print(HTTPPATH);
  xport.println(" HTTP/1.1");
  xport.print("Host: ");   
  xport.println(HOSTNAME);
  xport.print("X-PachubeApiKey: ");  
  xport.println(APIKEY);
  xport.print("User-Agent: ");  
  xport.println("Arduino (JGC Pachube V1.0");
  xport.println("Content-Type: text/csv");
  xport.print("Content-Length:"); 
  xport.println(buflength);
  xport.println("Connection: close" );
  xport.println();
  xport.println(linebuffer);
  xport.println();

    ret = xport.readline_timeout(linebuffer, 255, 3000); // 3s timeout
    if (strstr(linebuffer, "HTTP/1.1 200 OK")) success=1;  // set success
    Serial.print ("return success");
    Serial.println (success,DEC);
  Serial.println("sent - sleeping");
  // Delay for 1 minute
  delay(60000);
  // The disconnect notification 'D' character probably arrived during this interval
  // so flush it so we don't read it after our next connect attempt
  xport.flush(255);
}
