// -*- c++ -*-
//
// Copyright 2010 Ovidiu Predescu <ovidiu@gmail.com>
// Date: June 2010
//

#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <Flash.h>
#include <Fat16util.h> // for FreeRam()
#include <TinyWebServer.h>

boolean index_handler(TinyWebServer& web_server);

static uint8_t mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

TinyWebServer::PathHandler handlers[] = {
  {"/", TinyWebServer::GET, &index_handler },
  {NULL},
};

boolean index_handler(TinyWebServer& web_server) {
  web_server.send_error_code(200);
  web_server << F("<html><body><h1>Hello World!</h1></body></html>\n");
  return true;
}

boolean has_ip_address = false;
TinyWebServer web = TinyWebServer(handlers, NULL);

const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}

void setup() {
  Serial.begin(115200);
  Serial << F("Free RAM: ") << FreeRam() << "\n";

  // Initiate a DHCP session.
  Serial << F("Getting an IP address...");
  if (!EthernetDHCP.begin(mac)) {
    Serial << F("\nCould not get an IP address");
    return;
  }
  has_ip_address = true;

  const byte* ip_addr = EthernetDHCP.ipAddress();
  const byte* gateway_addr = EthernetDHCP.gatewayIpAddress();
  const byte* dns_addr = EthernetDHCP.dnsIpAddress();

  Serial << F("\nMy IP address: ");
  Serial.println(ip_to_str(ip_addr));

  Serial << F("Gateway IP address: ");
  Serial.println(ip_to_str(gateway_addr));

  Serial<< F("DNS IP address: ");
  Serial.println(ip_to_str(dns_addr));

  Serial<< F("Hostname: ");
  Serial.println(EthernetDHCP.hostName());

  // Start the web server.
  web.begin();

  Serial << F("Ready to accept HTTP requests.\n\n");
}

void loop() {
  if (has_ip_address) {
    EthernetDHCP.maintain();
    web.process();
  }
}
