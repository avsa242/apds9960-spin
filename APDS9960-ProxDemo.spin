{
    --------------------------------------------
    Filename: APDS9960-ProxDemo.spin
    Author: Jesse Burt
    Description: Demo of the APDS9960 driver
        (Proximity sensing functionality)
    Copyright (c) 2020
    Started Aug 03, 2020
    Updated Aug 04, 2020
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

PUB Main{} | prox, proxint_lo, proxint_hi, proxintpers

    setup{}

    apds.defaultsprox{}                                     ' Setup driver with proximity sensing features enabled
    apds.proxintclear{}                                     ' Clear out existing interrupt
    apds.proxintpersistence(2)                              ' 0..15; If you actually intend to use the interrupt functionality, 0 is probably not what you want (triggers an interrupt on every reading, regardless of whether it's outside the threshold or not). See ProxIntPersistence() definition for details.
    apds.proxintthresh(0, 64, W)                           ' (lo, hi): 0..255 threshold. W(1) writes new thresholds
    apds.proxintthresh(@proxint_lo, @proxint_hi, R)         '   R(0) reads existing settings (pointers to variables)

    proxintpers := apds.proxintpersistence(-2)              ' Read back persistence setting

    ser.printf(string("\nInterrupt thresholds (lo:hi): %d:%d\n"), proxint_lo, proxint_hi, 0, 0, 0, 0)
    ser.printf(string("Proximity interrupt persistence filter: %d cycles"), proxintpers, 0, 0, 0, 0, 0)
    apds.proxintclear{}
    repeat
        repeat until apds.proxdataready{}
        prox := apds.proxdata{}
        ser.position(0, 7)
        ser.str(string("Proximity data: "))
        ser.hex(prox, 2)
        if apds.proxinterrupt{}
            ser.str(string(" (int)"))
        else
            ser.clearline(ser#CLR_CUR_TO_END)
        if ser.rxcheck{} == "c"
            apds.proxintclear{}
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
