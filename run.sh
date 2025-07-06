avra main.s && avrdude -c arduino -p m328p -P /dev/ttyUSB0 -b 115200 -U flash:w:main.s.hex -v

