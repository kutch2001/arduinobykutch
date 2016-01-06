# Introduction #

It was indeed an OK honeymoon..  Not great, not bad, but ok.  Did have some fun with the MakerBot, but it also proved to have headaches alot.  When the honeymoon was over everything went south from there, not even a peep.  Currently working to bring the bot back to life with new electronics.
Update: 10/10/2010 - Believe, after counseling, seems to be back on track for a good relationship, with different electronics.


# Details #

First and foremost, pictures of my makerbot are on [google photo](http://picasaweb.google.com/kutch2001/MakerBot#)

Know my experience may seem like an anomoly on the MakerBot radar, but at this stage the printer is truly in Beta mode.  It still has **alot** of kinks, and other things, in it that truly shouldn't happen.  This includes assembling, configuring, and maintaining.  Am glad that I do have the resources, and will, to find and fix my problems.

_Remember, only person you can truly trust is yourself........_  Everyone else have to figure them out for yourself.

History:
  * Bought Makerbot Cupcake CNC standard kit from [Makerbot](http://store.makerbot.com)
    * Added a power supply, extra bearings, and couple other things to the order
    * Makerbot # 1670 Batch XV
  * Ordered some good gear from [MakerGear](http://www.makergear.com) (Rick is super awesome)
    * An operator pack with an assembled Makergear heatercore (excellent choice!)
    * Some other nifty stuff to get started with, which forgot already.
  * Assembled bot following the MakerBot wiki.  Have some pics someplace of it, not uploaded.
  * Hooked up software and started tuning (the tuning is **NOT** _plug and play_)
  * Ordered plastic filament from [New Image Plastics](http://plasticweldingrod.com/)
  * Ordered some Acme threaded z-roids from fleabay (seller is truly excellent) as had severe binding issues and lubed with silicone spray stuff after cleaning oil off.  Did not know how to increase motor torque at this point (slow down speed of movement)
  * Ordered higher torque stepper motor as Acme z-roids did not fix z-axis problems (after upgrade needed to reduce speed of z-axis movement.  I cut it roughly in 1/2).  Went on the reprap site, under stepper motors, and chose ones with highest torque from the US.  Colors don't match up to Makerbot stepper colors either..  :(
    * Changing default speed settings is not exactly a straight-forward process.  It is hidden someplace (forget where) and took me some time to figure it out.
  * Finished tuning and a happy makerbot owner
  * H-bridge #1 fails.  Figure out the Makerbot code (not easy) and switch it to use the other H-bridge.  Couldn't get it to reverse after switching.
    * [Compiled code](http://code.google.com/p/arduinobykutch/source/browse?repo=makerbot#hg/Software/firmware)
    * EC-ecv22-v2.3r3-stepper.hex is my overridden version (to upload using ReplicatorG
    * EC-ecv22-v2.3r3-stepper\_old.hex is delivered Makerbot version from ReplicatorG v17
  * H-bridge #2 fails.......  **BAD MAKERBOT BAD BAD BAD**
  * Found no help on makerbot's google group or contacting MBI directly
  * Ordered shield and accessories from [Ultimachine](http://www.ultimachine.com/ramps)
    * Ordered 4 [stepper drivers](http://ultimachine.com/content/pololu-a4983-stepper-driver-heatsink-kit) and 1 [polulu motor driver](http://ultimachine.com/content/pololu-tb6612fng-dual-dc-motor-driver) with [heatsink](http://ultimachine.com/content/heat-sink-63mm-x-48mm)
    * Ordered 7 [endstops](http://ultimachine.com/content/opto-endstop-v21-kit), one for backup
    * While a little slow initially, they did answer most of my questions.
  * Not much info out there on Arduino Mega firmware for use with reprap.
    * Tonokip firmware - chose initially for ease of use and it's simple nature.  Lacked heated build platform support and DC motor driver capability, hacked those in plus other stuff
    * Joaz reprap firmware fork - was hoping to use this one as included alot of things, but couldn't get it to work initially (probably user error on my part).  Still might try to use eventually.
  * Assembled shield and started testing
  * Donated a MakerGear HBP, Extruder heatercore set, and a higher torque stepper motor, to AS220 labs in Providence, RI for their help with me on a different project.
  * Completed first build with new electronics (see pics)..  Didn't end too well...  http://picasaweb.google.com/lh/photo/F1Qr3J8F7vkrX7qGgwm1uA?feat=directlink
    * Used [RepSnapper](http://reprap.org/wiki/RepSnapper_Manual:Introduction) as client software..  Only one that worked.
    * Reprap client software gave lots of error messages that other people seemed to experience too.
  * On 10/10/2010 believe have finally fixed the firmware problems was having with the Tonokip Firmware for the Arduino Mega. Had firmware set to disable X/Y steppers while not in use.. Turns out that is not such a good move as was causing problems, am assuing because of delay in re-activating stepper.
    * Version should be good now! Will feed addiction for a little bit then might try the FiveD firmware code I downloaded.
    * Am guessing will have to convert to Gcode through ReplicatorG, then print using RepSnapper.
    * [Tonokip](http://code.google.com/p/arduinobykutch/source/browse/#hg/My_documents_arduino/Tonokip_firmware%3Fstate%3Dclosed) firmware being used
    * Not sure, but most of the firmware problems related to the Mega might have been case of PBCK (Problem Between Chair and Keyboard), i.e. me
  * Pictures to come of Extruder Board being pummeled into many tiny (hopefully) pieces with minimal injury to myself.
  * Sad news.. 10/10/2010 Makerbot extruder head bit the dust when trying to remove the nozzle.  broke right in 1/2, oh well.  Lost my preassembled MakerGear heatercore too as didn't remove it (thanks for backups!)
    * Put together MakerGear heatercore set (with 0.5 and 0.4 nozzles).
    * Mounted 0.5 nozzle and so far so good.  Retrying a print have tried for at least 10 times with failures on all but one due to snags...
  * 11/24/2012  In this time, have moved to the west coast and finally unpacked the Makerbot.  Almost done tuning it and updating the firmware to correct sizing problems, plus some other tweaks.
  * 12/04/2012  Updating Tonokip firmware to sprinter as it supports SD Card and some other things.  Sprinter is just a renamed Tonokip.

# Tips and Tricks for Arduino Mega #
  * Make sure no interference in wires before starting large prints
    * My initial prints seemed to work great, but when started first big print got some crazy behavior on the Y axis
    * Steps done in approximate order until got it solidly working
      * Twisted stepper wires
      * Re-routed stepper wires
      * Verified tightness of Molex connectors
      * More to come....
  * While had interference with wires, also had thermistor reading problems.  Got the heatercore to over 400 Celcius reported temp..  Hope didn't damage anything long term _shrugs_
    * Seperated thermistor wires from stepper wires (i.e. physical space between them)
      * Reduced times where it would read 3 (i.e. 0?) but not eliminated
    * Verified connections and which pins were for what sensor

Add your content here.  Format your content with:
  * Text in **bold** or _italic_
  * Headings, paragraphs, and lists
  * Automatic links to other wiki pages