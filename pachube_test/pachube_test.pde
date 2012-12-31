#include <NewSoftSerial.h>
#include <AF_XPort.h>
#include <stdio.h>

//#define IPADDR "192.168.0.101"
//#define HTTPPATH "/bit.txt"

#define IPADDR "70.40.207.211"  //cnn.com
#define HTTPPATH "/arduino/bit.txt"

#define PORT 80

#define XPORT_RESETPIN 2  //reset xport
#define XPORT_TXPIN  3    //serial tx
#define XPORT_RXPIN  4    //serial rx
#define XPORT_DTRPIN 5    //internet connection ended signal from xport
#define XPORT_CTSPIN 6    //used by arduino to stop xport overwhelming it with data
#define XPORT_RTSPIN 7    //signal for more data available... not used

char linebuffer[256]; // large buffer for storing data

AF_XPort xport = AF_XPort(XPORT_RXPIN, XPORT_TXPIN, XPORT_RESETPIN, XPORT_DTRPIN, XPORT_RTSPIN, XPORT_CTSPIN);

void setup()
  {
    Serial.begin(9600);
    xport.begin(9600);
    uint8_t ret;
    ret = xport.reset();
  Serial.print("Ret: "); Serial.println(ret, HEX);
    delay(1000);
    Serial.println("QueueBot 5000");
    Serial.println("Finished Setup...");
  }

void loop()
{
fetchStuff();
}


char * fetchStuff() {

  uint8_t ret;
  ret = xport.reset();
  Serial.print("Ret: "); Serial.println(ret, HEX);
  switch (ret) {
   case  ERROR_TIMEDOUT: {
	Serial.println("Timed out on reset!");
	return 0;
   }
   case ERROR_BADRESP:  {
	Serial.println("Bad response on reset!");
	return 0;
   }
   case ERROR_NONE: {
    Serial.println("Reset OK!");
    break;
   }
   default:
     Serial.println("Unknown error");
     return 0;
  }

  // time to connect...

  ret = xport.connect(IPADDR, PORT);
    switch (ret) {
   case  ERROR_TIMEDOUT: {
	Serial.println("Timed out on connect");
	return 0;
   }
   case ERROR_BADRESP:  {
	Serial.println("Failed to connect");
	return 0;
   }
   case ERROR_NONE: {
     Serial.println("Connected..."); break;
   }
   default:
     Serial.println("Unknown error");
     return 0;
  }

  // send the HTTP command

    xport.print("GET "); xport.println(HTTPPATH);

    ret = xport.readline_timeout(linebuffer, 255, 3000); // 3s timeout
    // if we're using flow control, we can actually dump the line at the same time!
    // Serial.print(linebuffer);
 while(ret!=0)
  {
   Serial.println(linebuffer);
   ret=xport.readline_timeout(linebuffer,255,1000);
  }
 //Serial.print("Readline returned: ");Serial.println(ret,HEX);
  xport.flush(1000);
}
 

