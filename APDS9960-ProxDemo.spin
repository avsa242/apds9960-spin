{
    --------------------------------------------
    Filename: APDS9960-ProxDemo.spin
    Author: Jesse Burt
    Description: Demo of the APDS9960 driver
        (Proximity sensing functionality)
    Copyright (c) 2022
    Started Aug 03, 2020
    Updated Sep 27, 2022
    See end of file for terms of use.
    --------------------------------------------
}

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
    apds    : "sensor.light.apds9960"

PUB Main{} | prox, proxint_lo, proxint_hi, proxintpers

    setup{}

    apds.preset_prox{}                         ' setup driver with proximity
                                                '   sensing features enabled
    apds.prox_int_clr{}                         ' clear existing interrupt

    ' prox_int_duration(): 0..15
    '   0: triggers an interrupt on every reading, _regardless_ of whether it's
    '       outside the threshold or not)
    '   1..15: triggers an interrupt when the threshold has been crossed for
    '       this many cycles
    '   See method definition in driver for details
    apds.prox_int_duration(2)

    ' prox_int_set_lo_thresh(), prox_int_set_hi_thresh: 0..255 threshold
    apds.prox_int_set_lo_thresh(0)
    apds.prox_int_set_hi_thresh(64)

    ' read back settings, for verification below
    proxint_lo := apds.prox_int_lo_thresh{}
    proxint_hi := apds.prox_int_hi_thresh{}

    proxintpers := apds.prox_int_duration(-2)

    ser.printf2(string("\nInterrupt thresholds (lo:hi): %d:%d\n"), proxint_lo, proxint_hi)
    ser.printf1(string("Proximity interrupt duration: %d cycles"), proxintpers)
    apds.prox_int_clr{}
    repeat
        repeat until apds.prox_data_rdy{}       ' wait for new dataset
        prox := apds.prox_data{}
        ser.position(0, 7)
        ser.str(string("Proximity data: "))     ' show raw data (unsigned 8bit)
        ser.dec(prox)
        if (apds.prox_interrupt{})              ' show a message if threshold
            ser.str(string(" (int)"))           '   is crossed
        else
            ser.clearline{}
        if ser.rxcheck{} == "c"                 ' press c to clear the int
            apds.prox_int_clr{}

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if apds.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.strln(string("APDS9960 driver started"))
    else
        ser.strln(string("APDS9960 driver failed to start - halting"))
        repeat

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

