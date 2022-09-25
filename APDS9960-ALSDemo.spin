{
    --------------------------------------------
    Filename: APDS9960-ALSDemo.spin
    Author: Jesse Burt
    Description: Demo of the APDS9960 driver
        (ALS functionality)
    Copyright (c) 2021
    Started Aug 02, 2020
    Updated Aug 15, 2021
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one of the below lines to choose the SPIN or PASM-based I2C engine
#define APDS9960_SPIN
'#define APDS9960_PASM

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    apds    : "sensor.light.apds9960"

PUB Main{} | c, r, g, b

    setup{}

    apds.powered(true)
    apds.alsenabled(true)

    repeat
        repeat until apds.alsdataready{}
        apds.alsdata(@c, @r, @g, @b)

' Alternatively, read individual channels:
'        c := apds.cleardata{}
'        r := apds.reddata{}
'        g := apds.greendata{}
'        b := apds.bluedata{}
        ser.position(0, 3)
        ser.printf4(string("Clear: %x\nRed:   %x\nGreen: %x\nBlue:  %x\n"), c, r, g, b)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if apds.startx(I2C_SCL, I2C_SDA, I2C_HZ)
#ifdef APDS9960_SPIN
        ser.strln(string("APDS9960 driver started (I2C-SPIN)"))
#elseifdef APDS9960_PASM
        ser.strln(string("APDS9960 driver started (I2C-PASM)"))
#endif
    else
        ser.strln(string("APDS9960 driver failed to start - halting"))
        repeat

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
