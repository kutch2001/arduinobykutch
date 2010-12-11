The directories here are Arduino libraries. Copy them to the directory
the Arduino IDE application looks into for libraries. This is usually
a directory named 'libraries' (no quotes) inside the sketchbook'
directory location.

On a Mac to find out where the sketchbook directory is located, open
up Arduino.app and look in Arduino -> Preferences -> Sketchbook
location.

The default sketchbook directory on Mac is ~/Documents/Arduino. Thus
the libraries location would be ~/Documents/Arduino/libraries. If you
don't have a library directory already, create one now. Then copy the
directories found in this package inside 'libraries'.

After you copy them, restart the Arduino IDE.

To play with the examples, make sure you have the hardware
modifications made to your Ethernet and Data Logging shields, as
described here:

http://www.webweavertech.com/ovidiu/weblog/archives/000476.html

The examples are located in TinyWebServer/examples/

Documentation on how to write your own Web server is located here:

http://www.webweavertech.com/ovidiu/weblog/archives/000477.html

Look at the TinyWebServer/examples/FileUpload for a good starting
point for your application.
