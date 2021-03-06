{
    --------------------------------------------
    Filename: APDS9960-GestureDemo.spin
    Author: Jesse Burt
    Description: Demo of the APDS9960 driver
        (Gesture sensing functionality)
    Copyright (c) 2020
    Started Aug 04, 2020
    Updated Aug 07, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000
' --

    R           = 0
    W           = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    apds    : "sensor.light.apds9960.i2c"

VAR

    byte _ser_cog

PUB Main{} | gest_u, gest_d, gest_l, gest_r

    setup{}
    apds.defaultsgest{}
    apds.gesturefifothresh(8)

    repeat
        apds.gesturedata(@gest_u, @gest_d, @gest_l, @gest_r)
        ser.position(0, 5)
        ser.printf(string("Gesture data: Up: %x  Down: %x  Left: %x  Right: %x"), gest_u, gest_d, gest_l, gest_r, 0, 0)

    flashled(LED, 100)

PUB Setup{}

    repeat until ser.startrxtx (SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if apds.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("APDS9960 driver started", ser#CR, ser#LF))
    else
        ser.str(string("APDS9960 driver failed to start - halting", ser#CR, ser#LF))
        apds.stop{}
        time.msleep(50)
        ser.stop{}
        flashled(LED, 500)

#include "lib.utility.spin"

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
