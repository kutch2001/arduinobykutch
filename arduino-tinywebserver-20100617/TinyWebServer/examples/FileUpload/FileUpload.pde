// -*- c++ -*-
//
// Copyright 2010 Ovidiu Predescu <ovidiu@gmail.com>
// Date: June 2010
//

extern "C" {
#include <ctype.h>
}

#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <Flash.h>
#include <Fat16.h>
#include <Fat16util.h>
#include <TinyWebServer.h>

boolean file_handler(TinyWebServer& web_server);
boolean index_handler(TinyWebServer& web_server);

TinyWebServer::PathHandler handlers[] = {
  // Work around Arduino's IDE preprocessor bug in handling /* inside
  // strings.
  //
  // `put_handler' is defined in TinyWebServer
  {"/", TinyWebServer::GET, &index_handler },
  {"/upload/" "*", TinyWebServer::PUT, &TinyWebPutHandler::put_handler },
  {"/" "*", TinyWebServer::GET, &file_handler },
  {NULL},
};

const char* headers[] = {
  "Content-Length",
  NULL
};

TinyWebServer web = TinyWebServer(handlers, headers);

boolean has_filesystem = true;
SdCard card;
Fat16 file = Fat16();

static uint8_t mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
boolean has_ip_address = false;

void send_file_name(TinyWebServer& web_server, const char* filename) {
  if (!filename) {
    web_server.send_error_code(404);
    web_server << F("Could not parse URL");
  } else {
    TinyWebServer::MimeType mime_type
      = TinyWebServer::get_mime_type_from_filename(filename);
    web_server.send_error_code(mime_type, 200);
    if (file.open(filename, O_READ)) {
      Serial << F("Read file "); Serial.println(filename);
      web_server.send_file(file);
      file.close();
    } else {
      web_server << F("Could not find file: ") << filename << "\n";
    }
  }
}

boolean file_handler(TinyWebServer& web_server) {
  char* filename = TinyWebServer::get_file_from_path(web_server.get_path());
  send_file_name(web_server, filename);
  free(filename);
}

boolean index_handler(TinyWebServer& web_server) {
  send_file_name(web_server, "INDEX.HTM");
}

void file_uploader_handler(TinyWebServer& web_server,
			   TinyWebPutHandler::PutAction action,
			   char* buffer, int size) {
  static uint32_t start_time;

  switch (action) {
  case TinyWebPutHandler::START:
    start_time = millis();
    if (!file.isOpen()) {
      // File is not opened, create it. First obtain the desired name
      // from the request path.
      char* fname = web_server.get_file_from_path(web_server.get_path());
      if (fname) {
	Serial << F("Creating ") << fname << "\n";
	file.open(fname, O_CREAT | O_WRITE | O_TRUNC);
	free(fname);
      }
    }
    break;

  case TinyWebPutHandler::WRITE:
    if (file.isOpen()) {
      file.write(buffer, size);
    }
    break;

  case TinyWebPutHandler::END:
    file.sync();
    Serial << F("Wrote ") << file.fileSize() << F(" bytes in ")
	   << millis() - start_time << F(" millis\n");
    file.close();
  }
}

void setup() {
  Serial.begin(115200);
  Serial << F("Free RAM: ") << FreeRam() << "\n";

  // initialize the SD card
  if (!card.init()) {
    Serial << F("card failed\n");
    has_filesystem = false;
  }
  if (!Fat16::init(card)) {
    // initialize a FAT16 volume
    Serial << F("Fat16 failed\n");
    has_filesystem = false;
  }

  if (has_filesystem) {
    // Assign our function to `upload_handler_fn'.
    TinyWebPutHandler::put_handler_fn = file_uploader_handler;
  }

  // Initiate a DHCP session.
  // Serial << F("Getting an IP address...");
  if (!EthernetDHCP.begin(mac)) {
    Serial << F("Could not get an IP address\n");
    return;
  }
  has_ip_address = true;

  // Start the web server.
  web.begin();

  Serial << F("Ready to accept HTTP requests.\n");
}

void loop() {
  if (has_ip_address && has_filesystem) {
    EthernetDHCP.maintain();
    web.process();
  }
}
