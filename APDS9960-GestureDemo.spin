{
    --------------------------------------------
    Filename: APDS9960-GestureDemo.spin
    Author: Jesse Burt
    Description: Demo of the APDS9960 driver
        (Gesture sensing functionality)
    Copyright (c) 2022
    Started Aug 04, 2020
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

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    apds    : "sensor.light.apds9960"
    str     : "string"

VAR

    long _ud_delta, _lr_delta, _ud_count, _lr_count, _near_count, _far_count, _gesture_motion
    long _gcnt
    byte _ser_cog
    byte _gest_u[32], _gest_d[32], _gest_l[32], _gest_r[32]
    byte _total
    byte _gesture_state

PUB main{} | fifo_level, i

    setup{}
    apds.preset_gest{}
    apds.gest_int_ena(true)
    apds.gest_fifo_thresh(1)
    apds.gest_set_start_thresh(40)
    apds.gest_set_end_thresh(35)
    apds.gest_gain(4)
    apds.gest_wait_time(0)
    apds.gest_pulse_cnt(10)
    apds.gest_pulse_len(16)
    apds.gest_led_current(300)
    apds.prox_int_set_lo_thresh(0)
    apds.prox_int_set_hi_thresh(200)
    apds.gest_int_clear{}
    _gcnt := 0
    _total := 0

    repeat
        apds.opmode(apds#GEST)
        time.msleep(30)
        repeat until apds.gest_data_rdy{}
        fifo_level := apds.gest_fifo_nr_unread{}
        if (fifo_level > 0)
            repeat
                apds.gest_data(@_gest_u[_total], @_gest_d[_total], @_gest_l[_total], @_gest_r[_total])
                _total += 1
            while apds.gest_fifo_nr_unread{} > 0
            ser.position(0, 12)
            ser.dec(_total)
            ser.chars(32, 5)
{
            mdn(_gest_u[_total])
            mdn(_gest_d[_total])
            mdn(_gest_l[_total])
            mdn(_gest_r[_total])
}
            if processgesturedata{}
                _gcnt++
                if decodegesture{}
                    ser.position(0, 4)
                    ser.str(lookup(_gesture_motion: string("LEFT "), string("RIGHT"), string("UP   "), string("DOWN "), string("NEAR "), string("FAR  "), string("ALL  ")))
            else
                ser.position(0, 4)
                ser.chars(" ", 5)
            _total := 0
        ser.position(0, 13)
        ser.dec(_gcnt)

pub msg(pstr, val, row)

    ser.position(0, row)
    ser.str(pstr)
    ser.dec(val)
    ser.clearline{}

pub md(val)

    ser.printf1(string("%03.3d"), val)

pub mdn(val)

    ser.printf1(string("%03.3d "), val)

pub fl

    repeat 10
        dira[26]:=1
        !outa[26]
        time.msleep(50)

con

    GESTURE_THRESHOLD_OUT   = 20
    GESTURE_SENSITIVITY_1   = 50
    GESTURE_SENSITIVITY_2   = 20

    #0, STATE_NA, STATE_NEAR, STATE_FAR, STATE_ALL

    NONE = 0
    LEFT = 1
    RIGHT = 2
    UP = 3
    DOWN = 4
    NEAR = 5
    FAR = 6
    ALL = 7

pub dd(pstr, n, row)

    ser.position(0, row)
    ser.str(pstr)
    mdn(_gest_u[n])
    mdn(_gest_d[n])
    mdn(_gest_l[n])
    mdn(_gest_r[n])

pub processgesturedata | u_first, d_first, l_first, r_first, u_last, d_last, l_last, r_last, i, ud_ratio_first, lr_ratio_first, ud_ratio_last, lr_ratio_last, ud_delta, lr_delta

    if _total =< 4
        return false

    if _total =< 32 and _total > 0
        repeat i from 0 to _total
            if _gest_u[i] > GESTURE_THRESHOLD_OUT and _gest_d[i] > GESTURE_THRESHOLD_OUT and _gest_l[i] > GESTURE_THRESHOLD_OUT and _gest_r[i] > GESTURE_THRESHOLD_OUT
                u_first := _gest_u[i]
                d_first := _gest_d[i]
                l_first := _gest_l[i]
                r_first := _gest_r[i]
'                msg(string("firstidx: "), i, 12)
'                dd(string("first: "), i, 13)
                quit

        if u_first == 0 or d_first == 0 or l_first == 0 or r_first == 0
            return false

        repeat i from _total to 0
            if _gest_u[i] > GESTURE_THRESHOLD_OUT and _gest_d[i] > GESTURE_THRESHOLD_OUT and _gest_l[i] > GESTURE_THRESHOLD_OUT and _gest_r[i] > GESTURE_THRESHOLD_OUT
                u_last := _gest_u[i]
                d_last := _gest_d[i]
                l_last := _gest_l[i]
                r_last := _gest_r[i]
'                msg(string("lastidx: "), i, 15)
'                dd(string("last: "), i, 16)
                quit

        ud_ratio_first := ((u_first - d_first) * 100) / (u_first + d_first)
        lr_ratio_first := ((l_first - r_first) * 100) / (l_first + r_first)
        ud_ratio_last := ((u_last - d_last) * 100) / (u_last + d_last)
        lr_ratio_last := ((l_last - r_last) * 100) / (l_last + r_last)
{
        msg(string("udr_f: "), ud_ratio_first, 18)
        msg(string("lrr_f: "), lr_ratio_first, 19)
        msg(string("udr_l: "), ud_ratio_last, 20)
        msg(string("lrr_l: "), lr_ratio_last, 21)
}
        ud_delta := ud_ratio_last - ud_ratio_first
        lr_delta := lr_ratio_last - lr_ratio_first

        _ud_delta := ud_delta
        _lr_delta := lr_delta

        if _ud_delta => GESTURE_SENSITIVITY_1
            _ud_count := 1
        elseif _ud_delta =< -GESTURE_SENSITIVITY_1
            _ud_count := -1
        else
            _ud_count := 0

        if _lr_delta => GESTURE_SENSITIVITY_1
            _lr_count := 1
        elseif _lr_delta =< -GESTURE_SENSITIVITY_1
            _lr_count := -1
        else
            _lr_count := 0

        if _ud_count == 0 and _lr_count == 0
            if ||(ud_delta) < GESTURE_SENSITIVITY_2 and ||(lr_delta) < GESTURE_SENSITIVITY_2
                if ud_delta == 0 and lr_delta == 0
                    _near_count += 1
                elseif ud_delta <> 0 or lr_delta <> 0
                    _far_count += 1

                if _near_count => 10 and _far_count => 2
                    if ud_delta == 0 and lr_delta == 0
                        _gesture_state := STATE_NEAR
                    elseif ud_delta <> 0 and lr_delta <> 0
                        _gesture_state := STATE_FAR
                    return true
        else
            if ||(ud_delta) < GESTURE_SENSITIVITY_2 and ||(lr_delta) < GESTURE_SENSITIVITY_2
                if ud_delta == 0 and lr_delta == 0
                    _near_count += 1

                if _near_count => 10
                    _ud_count := 0
                    _lr_count := 0
                    _ud_delta := 0
                    _lr_delta := 0

    return false

pub decodegesture

    if _gesture_state == STATE_NEAR
        _gesture_motion := NEAR
        return true

    if _gesture_state == FAR
        _gesture_motion := FAR
        return true

    ' determine swipe direction
    if _ud_count == -1 and _lr_count == 0
        _gesture_motion := UP
    elseif _ud_count == 1 and _lr_count == 0
        _gesture_motion := DOWN
    elseif _ud_count == 0 and _lr_count == 1
        _gesture_motion := RIGHT
    elseif _ud_count == 0 and _lr_count == -1
        _gesture_motion := LEFT
    elseif _ud_count == -1 and _lr_count == 1
        if ||(_ud_delta) > ||(_lr_delta)
                _gesture_motion := UP
        else
            _gesture_motion := DOWN
    elseif _ud_count == 1 and _lr_count == -1
        if ||(_ud_delta) > ||(_lr_delta)
                _gesture_motion := DOWN
        else
            _gesture_motion := LEFT
    elseif _ud_count == -1 and _lr_count == -1
        if ||(_ud_delta) > ||(_lr_delta)
            _gesture_motion := UP
        else
            _gesture_motion := LEFT
    elseif _ud_count == 1 and _lr_count == 1
        if ||(_ud_delta) > ||(_lr_delta)
            _gesture_motion := DOWN
        else
            _gesture_motion := RIGHT
    else
        return false

    return true


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
