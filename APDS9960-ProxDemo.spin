{
    --------------------------------------------
    Filename: APDS9960-ProxDemo.spin
    Author: Jesse Burt
    Description: Demo of the APDS9960 driver
        (Proximity sensing functionality)
    Copyright (c) 2021
    Started Aug 03, 2020
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

    R           = 0
    W           = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    apds    : "sensor.light.apds9960.i2c"

PUB Main{} | prox, proxint_lo, proxint_hi, proxintpers

    setup{}

    apds.defaultsprox{}                         ' setup driver with proximity
                                                '   sensing features enabled
    apds.proxintclear{}                         ' clear existing interrupt

    ' ProxIntPersistence(): 0..15
    '   0: triggers an interrupt on every reading, _regardless_ of whether it's
    '       outside the threshold or not)
    '   1..15: triggers an interrupt when the threshold has been crossed for
    '       this many cycles
    '   See method definition in driver for details
    apds.proxintpersistence(2)

    ' ProxIntThresh(lo, hi, RW): 0..255 threshold. W (1) writes new thresholds
    apds.proxintthresh(0, 64, W)

    ' R: read back settings, for verification below
    apds.proxintthresh(@proxint_lo, @proxint_hi, R)
    proxintpers := apds.proxintpersistence(-2)

    ser.printf2(string("\nInterrupt thresholds (lo:hi): %d:%d\n"), proxint_lo, proxint_hi)
    ser.printf1(string("Proximity interrupt persistence filter: %d cycles"), proxintpers)
    apds.proxintclear{}
    repeat
        repeat until apds.proxdataready{}       ' wait for new dataset
        prox := apds.proxdata{}
        ser.position(0, 7)
        ser.str(string("Proximity data: "))     ' show raw data (unsigned 8bit)
        ser.dec(prox)
        if apds.proxinterrupt{}                 ' show a message if threshold
            ser.str(string(" (int)"))           '   is crossed
        else
            ser.clearline{}
        if ser.rxcheck{} == "c"                 ' press c to clear the int
            apds.proxintclear{}

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
