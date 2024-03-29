{
    --------------------------------------------
    Filename: APDS9960-ALSDemo.spin
    Author: Jesse Burt
    Description: Demo of the APDS9960 driver
        (ALS functionality)
    Copyright (c) 2022
    Started Aug 02, 2020
    Updated Nov 17, 2022
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

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    apds    : "sensor.light.apds9960"

PUB main{} | w, r, g, b

    setup{}

    apds.powered(true)
    apds.als_ena(true)

    repeat
        repeat until apds.als_data_rdy{}
        apds.als_data(@w, @r, @g, @b)           ' read all four channels indirectly

' Alternatively, read individual channels:
'        w := apds.white_data{}
'        r := apds.red_data{}
'        g := apds.green_data{}
'        b := apds.blue_data{}
        ser.position(0, 3)
        ser.printf1(string("White: %04.4x\n\r"), w)
        ser.printf1(string("Red:   %04.4x\n\r"), r)
        ser.printf1(string("Green: %04.4x\n\r"), g)
        ser.printf1(string("Blue:  %04.4x\n\r"), b)

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

