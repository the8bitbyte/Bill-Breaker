# Bill-Breaker
Bill Breaker is an anti-Rubber Ducky tool, similar to [Duck Hunt](https://github.com/pmsosa/duckhunt) but made for Linux.

BBill Breaker is a shell script written to detect external keyboards as they are plugged in and monitor them for keystrokes. If they exceed a defined typing speed, they are unbound, and ```ondetect.sh``` is ran.

This script requires evtest, which is installed by default when ```setup.sh``` is ran.

> [!WARNING]  
> This was developed on EndeavourOS and tested with the Rubber Ducky built into the Flipper Zero.
