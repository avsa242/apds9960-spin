{
----------------------------------------------------------------------------------------------------
    Filename:       APDS9960-ProxDemo.spin
    Description:    Demo of the APDS9960 driver
        * Proximity sensing functionality
    Author:         Jesse Burt
    Started:        Aug 3, 2020
    Updated:        Jan 29, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}


CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    apds:   "sensor.light.apds9960" | SCL=28, SDA=29, I2C_FREQ=400_000
    time:   "time"


PUB main() | prox, proxint_lo, proxint_hi, proxint_dur

    setup()

    apds.preset_proximity_detect()              ' setup driver with proximity
                                                '   sensing features enabled
    apds.prox_int_clear()                       ' clear existing interrupt

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
    proxint_lo := apds.prox_int_lo_thresh()
    proxint_hi := apds.prox_int_hi_thresh()

    proxint_dur := apds.prox_int_duration()

    ser.printf(@"\n\rInterrupt thresholds (lo:hi): %d:%d\n\r", proxint_lo, proxint_hi)
    ser.printf(@"Proximity interrupt duration: %d cycles", proxint_dur)
    apds.prox_int_clear()
    repeat
        repeat until apds.prox_data_rdy()       ' wait for new dataset
        prox := apds.prox_data()
        ser.pos_xy(0, 7)
        ser.printf(@"Proximity data: %3.3d", prox)' show raw data (unsigned 8bit)
        if ( apds.prox_interrupt() )            ' show a message if threshold
            ser.str(@" (int)")                  '   is crossed
        else
            ser.clear_line()
        if ( ser.getchar_noblock() == "c" )     ' press c to clear the int
            apds.prox_int_clear()


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( apds.start() )
        ser.strln(@"APDS9960 driver started")
    else
        ser.strln(@"APDS9960 driver failed to start - halting")
        repeat


DAT
{
Copyright 2026 Jesse Burt

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

