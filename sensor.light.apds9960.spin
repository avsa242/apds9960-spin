{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.light.apds9960.spin
    Description:    Driver for the APDS9960 Proximity, Ambient Light, RGB and Gesture sensor
    Author:         Jesse Burt
    Started:        Aug 2, 2020
    Updated:        Mar 18, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------

    NOTE: The gesture detection code is based on that found in Adafruit's Adafruit_APDS9960 driver
    (https://github.com/adafruit/Adafruit_APDS9960)
}

CON

    { default I/O configuration - these can be overridden by the parent object }
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 100_000

    ' Recognized gesture enums
    #1, GESTURE_UP, GESTURE_DOWN, GESTURE_LEFT, GESTURE_RIGHT

    { Gesture sensor modes }
    ALS             = 0
    GEST            = 1

    { Gesture sensor dimension select }
    BOTH            = 0
    UPDOWN          = 1
    LEFTRIGHT       = 2


    SLAVE_WR        = core.SLAVE_ADDR
    SLAVE_RD        = core.SLAVE_ADDR|1


    SMP_U           = 0
    SMP_D           = 1
    SMP_L           = 2
    SMP_R           = 3


var

    byte gest_buff[256]                         ' gesture FIFO data
    byte movecnt[4]                             ' movement/transition tracking


OBJ

#ifdef APDS9960_SPIN
    i2c:    "com.i2c.nocog"                     ' BC I2C engine
#else
    i2c:    "com.i2c"                           ' PASM I2C engine
#endif
    core:   "core.con.apds9960"                 ' APDS9960-specific constants
    time:   "time"                              ' timekeeping methods


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start the driver using custom I/O settings
'   SCL_PIN:    I2C SCL pin
'   SDA_PIN:    I2C SDA pin
'   I2C_HZ:     I2C bus speed (Hz; 400_000 max)
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.msleep(core.TPOR)
            if ( dev_id() == core.DEVID_RESP )
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()
' Stop the driver
    i2c.deinit()


PUB defaults()
' Set factory/POR defaults
    powered(false)
    als_ena(false)
    als_gain(1)
    als_int_ena(false)
    als_int_duration(0)
    als_int_set_lo_thresh(0)
    als_int_set_hi_thresh(0)
    opmode(ALS)
    als_integr_time(2_780)
    prox_det_ena(false)
    prox_integr_time(8)
    prox_int_duration(0)
    prox_int_ena(false)
    prox_int_set_lo_thresh(0)
    prox_int_set_hi_thresh(0)
    wait_timer_ena(false)


PUB preset_als()
' Set defaults for using the sensor in ALS/RGB mode
    powered(true)
    als_ena(true)
    als_gain(1)
    als_int_ena(true)
    als_int_duration(0)
    als_int_set_lo_thresh(0)
    als_int_set_hi_thresh(0)
    opmode(ALS)
    als_integr_time(2_780)
    prox_det_ena(false)
    prox_int_ena(false)
    wait_timer_ena(false)


PUB preset_proximity_detect()
' Set defaults for using the sensor in proximity sensor mode
    powered(true)
    als_ena(false)
    opmode(ALS)
    prox_det_ena(true)
    prox_gain(4)
    prox_integr_time(8)
    prox_int_duration(0)
    prox_int_ena(true)
    prox_int_set_lo_thresh(0)
    prox_int_set_hi_thresh(0)
    prox_pulse_cnt(8)
    wait_timer_ena(false)


PUB preset_gesture_detect()
' Set defaults for using the sensor in gesture sensor mode
    powered(false)
    gest_led_current(300)
    gest_pulse_cnt(10)
    gest_pulse_len(32)
    gest_dims(BOTH)
    gest_fifo_thresh(4)
    gest_gain(4)
    gest_int_ena(false)
    gest_wait_time(0)
    gest_set_start_thresh(30)
    gest_set_end_thresh(20)
    gest_end_duration(4)
    powered(true)
    opmode(GEST)
    gest_ena(true)


PUB als_data(ptr_c, ptr_r, ptr_g, ptr_b) | tmp[2]
' All ambient light source data
'   ptr_c, ptr_r, ptr_g, ptr_b: pointers at least 1 word in size, each
    readreg(core.CDATAL, 8, @tmp)
    long[ptr_c] := tmp.word[0]
    long[ptr_r] := tmp.word[1]
    long[ptr_g] := tmp.word[2]
    long[ptr_b] := tmp.word[3]


PUB als_data_rdy(): f
' Flag indicating ambient light source data is ready
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS)
    return ( ( (f >> core.AVALID) & 1) == 1 )


PUB als_ena(e=-2): c
' Enable ambient light source sensor/ADC
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    c := readreg(core.ENABLE)
    case abs(e)
        0, 1:
            e := abs(e) << core.AEN
            e := (c & core.AEN_MASK) | e
            writereg(core.ENABLE, e)
        other:
            return ( ((c >> core.AEN) & 1) == 1 )


PUB als_gain(g=-2): c
' Set ambient light sensor gain multiplier
'   Valid values: *1, 4, 16, 64
'   Any other value polls the device and returns the current setting
    c := readreg(core.CONTROL)
    case g
        1, 4, 16, 64:
            g := lookdownz(g: 1, 4, 16, 64)
            g := (c & core.AGAIN_MASK) | g
            writereg(core.CONTROL, g)
        other:
            c &= core.AGAIN_BITS
            return lookupz(c: 1, 4, 16, 64)


PUB als_int_duration(d=-2): c
' Set interrupt duration, in cycles
'   Defines how many consecutive measurements must be outside the interrupt threshold
'   before an interrupt is actually triggered (e.g., to reduce false positives)
'   Valid values:
'      *0 - _Every measurement_ triggers an interrupt, _regardless_
'       1 - Every measurement _outside your set threshold_ triggers an interrupt
'       2 - Must be 2 consecutive measurements outside the set threshold to trigger an interrupt
'       3 - Must be 3 consecutive measurements outside the set threshold to trigger an interrupt
'       5..60 - _n_ consecutive measurements, in multiples of 5
'   Any other value polls the device and returns the current setting
    c := readreg(core.PERS)
    case d
        0..3, 5..60:
            if ( d > 3 )
                d := (d / 5) + 3
            d := (c & core.APERS_MASK) | d
            writereg(core.PERS, d)
        other:
            if ( (c &= core.APERS_BITS) =< 3 )
                return c
            else
                return ( ((c & core.APERS_BITS) - 3) * 5 )


PUB als_int_ena(e=-2): c
' Enable ALS interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    c := readreg(core.ENABLE)
    case abs(e)
        0, 1:
            e := abs(e) << core.AIEN
            e := (c & core.AIEN_MASK) | e
            writereg(core.ENABLE, e)
        other:
            return ( ((c >> core.AIEN) & 1) == 1 )


PUB als_int_hi_thresh(): t
' Get ALS interrupt high threshold
    return readreg(core.AIHTL, 2)


PUB als_int_lo_thresh(): t
' Get ALS interrupt low threshold
    return readreg(core.AILTL, 2)


PUB als_int_set_hi_thresh(t)
' Set ALS interrupt high threshold
'   Valid values
'       low, high: 0..65535
    t := 0 #> t <# 65535
    writereg(core.AIHTL, t, 2)


PUB als_int_set_lo_thresh(t)
' Set ALS interrupt low threshold
'   Valid values
'       low, high: 0..65535
    t := 0 #> t <# 65535
    writereg(core.AILTL, t, 2)


PUB als_integr_time(t=-2): c
' Set ALS integration time, in microseconds
'   Valid values: *2_780..712_000, in multiples of 2_780 (rounded to nearest result)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the ALS/RGB engine. The proximity and gesture engines
'       are not affected.
    case t
        2_780..712_000:
            t := 256-(t / 2_780)
            writereg(core.ATIME, t)
        other:
            c := readreg(core.ATIME)
            return ( (256-c) * 2_780 )


PUB blue_data(): b
' Blue-channel sensor data
'   Returns: 16-bit unsigned
    return readreg(core.CDATAL, 2)


PUB dev_id(): id
' Read device identification
    return readreg(core.DEVICEID)


PUB green_data(): g
' Green-channel sensor data
'   Returns: 16-bit unsigned
    return readreg(core.GDATAL, 2)


PUB gest_fifo_nr_unread(): n
' Number of samples available in FIFO
'   Returns: 8-bit unsigned
'   NOTE: One sample is a complete set of U, D, L, R data. To reduce the level reported here,
'       a complete dataset must be read.
    return readreg(core.GFLVL)


PUB gest_fifo_overflow(): f
' Flag indicating gesture FIFO has overflowed
'   Returns: TRUE (-1) if FIFO overflowed (data has been lost), FALSE (0) otherwise
    f := readreg(core.GSTATUS)
    f := ( ((f >> core.GFOV) & 1) == 1 )


PUB gest_led_current(i=-2): c | ledboost
' Set LED drive current in gesture mode, in milliamperes
'   Valid values: 300, 200, 150, *100, 50, 25, 12_5 (12.5)
'   Any other value polls the device and returns the current setting
    c.byte[0] := readreg(core.GCONF2)
    c.byte[1] := readreg(core.CONFIG2)
    case i
        100, 50, 25, 12_5:
            i := lookdownz(i: 100, 50, 25, 12_5) << core.GLDRIVE
        150, 200, 300:
            i := 0
            ledboost := lookdown(i: 150, 200, 300)
        other:
            c.byte[0] := (c.byte[0] >> core.GLDRIVE) & core.GLDRIVE_BITS
            c.byte[1] := (c.byte[1] >> core.LED_BOOST) & core.LED_BOOST_BITS
            if ( c.byte[1] )
                return lookdown(c.byte[1]: 150, 200, 300)
            else
                return lookupz(c.byte[0]: 100, 50, 25, 12_5)

    i := (c.byte[0] & core.GLDRIVE_MASK) | i
    ledboost := (c.byte[1] & core.LEDBOOST_MASK) | ledboost
    writereg(core.GCONF2, i)
    writereg(core.CONFIG2, ledboost)


PUB gest_pulse_cnt(n=-2): c     'XXX tentatively named
' Set gesture LED pulse count, generated on LDR 'XXX tentative summary
'   Valid values: 1..64
'   Any other value polls the device and returns the current setting
    c := readreg(core.GPULSECNT)
    case n
        1..64:
            n -= 1
            n := (c & core.GPULSE_MASK) | n
            writereg(core.GPULSECNT, n)
        other:
            return ( (c & core.GPULSE_BITS) + 1 )


PUB gest_pulse_len(l=-2): c
' Set gesture LED pulse length, generated on LDR, in microseconds 'XXX tentative summary
'   Valid values: 4, *8, 16, 32
'   Any other value polls the device and returns the current setting
    c := readreg(core.GPULSECNT)
    case l
        4, 8, 16, 32:
            l := lookdownz(l: 4, 8, 16, 32) << core.GPLEN
            l := (c & core.GPLEN_MASK) | l
            writereg(core.GPULSECNT, l)
        other:
            c := ( (c >> core.GPLEN) & core.GPLEN_BITS )
            return lookupz(c: 4, 8, 16, 32)


PUB gest_data(p_dest, len=4): r
' All gesture sensor source data
    if ( len =< 4 )
        long[p_dest] := readreg(core.GFIFO_U, len)
    else
        readreg(core.GFIFO_U, len, p_dest)


PUB gest_data_down(): d
' Gesture sensor down direction data
'   Returns: 8-bit unsigned
    return readreg(core.GFIFO_D)


PUB gest_data_left(): d
' Gesture sensor left direction data
'   Returns: 8-bit unsigned
    return readreg(core.GFIFO_L)


PUB gest_data_rdy(): f
' Flag indicating gesture FIFO contains valid data
'   NOTE: Flag will be set when FIFO level exceeds threshold set with gest_fifo_thresh()
    f := readreg(core.GSTATUS)
    return ( (f & 1) == 1 )


PUB gest_data_right(): d
' Gesture sensor right direction data
'   Returns: 8-bit unsigned
    return readreg(core.GFIFO_R)


PUB gest_data_up(): d
' Gesture sensor up direction data
'   Returns: 8-bit unsigned
    return readreg(core.GFIFO_U)


PUB gest_dims(d=-2): c
' Select which sensor pairs are used to detect gestures
'   Valid values:
'       BOTH (0): Both Up/Down and Left/Right sensors active
'       UPDOWN (1): Only the Up/Down sensor is active (Right/Left FIFO data always 0)
'       LEFTRIGHT (2): Only the Left/Right sensor is active (Up/Down FIFO data always 0)
'   Any other value polls the device and returns the current setting
    case (d &= core.GCONF3_MASK)
        BOTH, UPDOWN, LEFTRIGHT:
            writereg(core.GCONF3, d)
        other:
            c := readreg(core.GCONF3)
            return (c & core.GDIMS_BITS)


PUB gest_ena(e=-2): c
' Enable gesture sensing
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    c := readreg(core.ENABLE)
    case abs(e)
        0, 1:
            e := abs(e) << core.GEN
            e := (c & core.GEN_MASK) | e
            writereg(core.ENABLE, e)
        other:
            return ( ((c >> core.GEN) & 1) == 1 )


PUB gest_end_duration(d=-2): c
' Set gesture exit persistence filter (number of gesture end occurences before gesture
'   state machine is exited) 'XXX tentative summary
'   Valid values: 1, 2, 4, 7
'   Any other value polls the device and returns the current setting
    c := readreg(core.GCONF1)
    case d
        1, 2, 4, 7:
            d := lookdownz(d: 1, 2, 4, 7)
            d := (c & core.GEXPERS_MASK) | d
            writereg(core.GCONF1, d)
        other:
            return lookupz(c: 1, 2, 4, 7)


PUB gest_end_thresh(): t
' Get threshold used to determine if a gesture has ended
    return readreg(core.GEXTH)


PUB gest_set_end_thresh(t)
' Set threshold used to determine if a gesture has ended
'   Valid values: 0..255
'   NOTE: This value is compared with output from ProxData(), to determine if a gesture has started
    t := 0 #> t <# 255
    writereg(core.GEXTH, t)


PUB gest_fifo_thresh(t=-2): c
' Set gesture FIFO threshold for asserting an interrupt
'   Valid values: *1, 4, 8, 16
'   Any other value polls the device and returns the current setting
'   NOTE: Gesture data is only added to the FIFO if it reaches or exceeds the threshold set with GestureStartThresh()
    c := readreg(core.GCONF1)
    case t
        1, 4, 8, 16:
            t := lookdownz(t: 1, 4, 8, 16) << core.GFIFOTH
            t := (c & core.GFIFOTH_MASK) | t
            writereg(core.GCONF1, t)
        other:
            c := (c >> core.GFIFOTH) & core.GFIFOTH_BITS
            return lookupz(c: 1, 4, 8, 16)


PUB gest_gain(g=-2): c
' Set proximity sensor gain in gesture mode
'   Valid values: *1, 2, 4, 8
'   Any other value polls the device and returns the current setting
    c := readreg(core.GCONF2)
    case g
        1, 2, 4, 8:
            g := lookdownz(g: 1, 2, 4, 8) << core.GGAIN
            g := (c & core.GGAIN_MASK) | g
            writereg(core.GCONF2, g)
        other:
            c := (c >> core.GGAIN) & core.GGAIN_BITS
            return lookupz(c: 1, 2, 4, 8)


PUB gest_int_clear() | tmp
' Clear gesture-sourced interrupts
    tmp := readreg(core.GCONF4)
    tmp |= (1 << core.GFIFO_CLR)
    writereg(core.GCONF4, tmp)


PUB gest_interrupt(): f
' Flag indicating gesture interrupt asserted
'   Returns: TRUE (-1) if interrupt asserted, FALSE (0) otherwise
    f := readreg(core.STATUS)
    return ( ((f >> core.GINT) & 1) == 1 )


PUB gest_int_ena(e=-2): c
' Enable gesture sensor interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and rturns the current setting
    c := readreg(core.GCONF4)
    case abs(e)
        0, 1:
            e := abs(e) << core.GIEN
            e := (c & core.GIEN_MASK) | e
            writereg(core.GCONF4, e)
        other:
            return ( ((c >> core.GIEN) & 1) == 1 )


PUB gest_start_thresh(): t
' Get threshold used to determine if a gesture has started
    return readreg(core.GPENTH)


PUB gest_set_start_thresh(t)
' Set threshold used to determine if a gesture has started
'   Valid values: 0..255
'   NOTE: This value is compared with output from prox_data(), to determine if a gesture has started
    t := 0 #> t <# 255
    writereg(core.GPENTH, t)


PUB gest_wait_time(t=-2): c
' Set inter-measurement wait timer (low-power mode between measurements), in milliseconds
'   Valid values: *0, 2_8 (2.8), 5_6 (5.6), 8_4 (8.4), 14_0 (14.0), 22_4 (22.4), 30_8 (30.8),
'       39_2 (39.2)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the Gesture engine. The proximity and ALS engines
'       are not affected.
    c := readreg(core.GCONF2)
    case t
        0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2:
            t := lookdownz(t: 0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2)
            t := (c & core.GWTIME_MASK) | t
            writereg(core.GCONF2, t)
        other:
            c := c & core.GWTIME_BITS
            return lookupz(c: 0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2)


pub last_gesture(tmo=300): g | tms, smp_cnt, t, delta_v, delta_h
' Get last gesture recognized by sensor
'   tmo:        gesture detection period/timeout (optional; default is 300ms)
'   Returns:    GESTURE_UP, GESTURE_DOWN, GESTURE_LEFT, GESTURE_RIGHT on success
'               0 if no gesture detected

'   NOTE: This method blocks for up to (tmo + 30) milliseconds

    t := 0
    tms := (clkfreq/1000)                       ' system ticks in 1ms
    repeat
        delta_v := 0
        delta_h := 0
        g := 0

        ifnot ( gest_data_rdy() )               ' no gesture data within set threshold
            return

        time.msleep(30)                         ' give the FIFO time to fill up
        smp_cnt := gest_fifo_nr_unread()

        gest_data(@gest_buff, smp_cnt)

        if ( abs(gest_buff[SMP_U] - gest_buff[SMP_D]) > 13 )
            delta_v += (gest_buff[SMP_U] - gest_buff[SMP_D])

        if ( abs(gest_buff[SMP_L] - gest_buff[SMP_R]) > 13)
            delta_h += (gest_buff[SMP_L] - gest_buff[SMP_R])

        if ( delta_v < 0 )                      ' D > U
            if ( movecnt[SMP_D] > 0 )
                g := GESTURE_UP
            else
                movecnt[SMP_U]++
        elseif ( delta_v > 0 )                  ' U > D
            if ( movecnt[SMP_U] > 0 )
                g := GESTURE_DOWN
            else
                movecnt[SMP_D]++

        if ( delta_h < 0 )                      ' R > L
            if ( movecnt[SMP_R] > 0 )
                g := GESTURE_LEFT
            else
                movecnt[SMP_L]++
        elseif ( delta_h > 0 )                  ' L > R
            if ( movecnt[SMP_L] > 0 )
                g := GESTURE_RIGHT
            else
                movecnt[SMP_R]++

        if ( (delta_v <> 0) or (delta_h <> 0) )
            t := cnt/tms

        if ( g or ( ( (cnt/tms) - t) > tmo) )   ' gesture recognized or timeout
            movecnt[SMP_U] := 0                 ' reset
            movecnt[SMP_D] := 0
            movecnt[SMP_L] := 0
            movecnt[SMP_R] := 0
            return g


PUB led_current(i=-2): c
' Set LED drive current, used in Proximity and Gesture sensing modes, in milliamperes
'   Valid values: *100, 50, 25, 12_5 (12.5)
'   Any other value polls the device and returns the current setting
    c := readreg(core.CONTROL)
    case i
        100, 50, 25, 12_5:
            i := lookdownz(i: 100, 50, 25, 12_5) << core.LDRIVE
            i := (c & core.LDRIVE_MASK) | i
            writereg(core.CONTROL, i)
        other:
            c := (c >> core.LDRIVE) & core.LDRIVE_BITS
            return lookupz(c: 100, 50, 25, 12_5)


PUB opmode(md=-2): c
' Set sensor operating mode
'   Valid values:
'       ALS (0): ALS/Proximity/RGB mode
'       GEST (1): Gesture mode
'   Any other value polls the device and rturns the current setting
    c := readreg(core.GCONF4)
    case md
        ALS, GEST:
            md := (c & core.GMODE_MASK) | md
            writereg(core.GCONF4, md)
        other:
            return ( c & 1 )


PUB powered(p=-2): c
' Enable device power
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    c := readreg(core.ENABLE)
    case abs(p)
        0, 1:
            p := abs(p)
            p := (c & core.PON_MASK) | p
            writereg(core.ENABLE, p)
        other:
            return ( (c & 1) == 1 )


PUB prox_data(): p
' Read proximity sensor data
'   Returns: 8bit unsigned
    return readreg(core.PDATA)


PUB prox_data_rdy(): f
' Flag indicating proximity sensor data is ready
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS)
    return ( ( (f >> core.PVALID) & 1) == 1 )


PUB prox_det_ena(e=-2): c
' Enable proximity sensing/detection
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    c := readreg(core.ENABLE)
    case abs(e)
        0, 1:
            e := abs(e) << core.PEN
            e := (c & core.PEN_MASK) | e
            writereg(core.ENABLE, e)
        other:
            return ( ( (c >> core.PEN) & 1) == 1 )


PUB prox_gain(g=-2): c
' Set proximity sensor gain multiplier
'   Valid values: *1, 2, 4, 8
'   Any other value polls the device and returns the current setting
    c := readreg(core.CONTROL)
    case g
        1, 2, 4, 8:
            g := lookdownz(g: 1, 2, 4, 8) << core.PGAIN
            g := (c & core.PGAIN_MASK) | g
            writereg(core.CONTROL, g)
        other:
            c := (c >> core.PGAIN) & core.PGAIN_BITS
            return lookupz(c: 1, 2, 4, 8)


PUB prox_int_clear()
' Clear proximity sensor interrupt
    writereg(core.PICLEAR)


PUB prox_integr_time(t=-2): c
' Set proximity sensor integration time, in microseconds
'   Valid values: 4, *8, 16, 32
'   Any other value polls the device and returns the current setting
    c := readreg(core.PPULSECNT)
    case t
        4, 8, 16, 32:
            t := lookdownz(t: 4, 8, 16, 32) << core.PPLEN
            t := (c & core.PPLEN_MASK) | t
            writereg(core.PPULSECNT, t)
        other:
            c := (c >> core.PPLEN) & core.PPLEN_BITS
            return lookupz(c: 4, 8, 16, 32)


PUB prox_interrupt(): f
' Flag indicating proximity sensor interrupt
'   Returns: TRUE (-1) if interrupt asserted, FALSE (0) otherwise
    f := readreg(core.STATUS)
    return ( ( (f >> core.PROXINT) & 1) == 1 )


PUB prox_int_duration(d=-2): c
' Set interrupt duration, in cycles
'   Defines how many consecutive measurements must be outside the interrupt threshold
'   before an interrupt is actually triggered (e.g., to reduce false positives)
'   Valid values:
'      *0 - _Every measurement_ triggers an interrupt, _regardless_
'       1 - Every measurement _outside the set threshold_ triggers an interrupt
'       2..15 - Must be 'n' consecutive measurements outside the set threshold to trigger
'           an interrupt
'   Any other value polls the device and returns the current setting
    c := readreg(core.PERS)
    case d
        0..15:
            d <<= core.PPERS
            d := (c & core.PPERS_MASK) | d
            writereg(core.PERS, d)
        other:
            return (c >> core.PPERS) & core.PPERS_BITS


PUB prox_int_ena(e=-2): c
' Enable Proximity sensor interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    c := readreg(core.ENABLE)
    case abs(e)
        0, 1:
            e := abs(e) << core.PIEN
            e := (c & core.PIEN_MASK) | e
            writereg(core.ENABLE, e)
        other:
            return ( ((c >> core.PIEN) & 1) == 1 )


PUB prox_int_hi_thresh(): t
' Get proximity sensor interrupt high threshold
    return readreg(core.PIHT)


PUB prox_int_lo_thresh(): t
' Get proximity sensor interrupt low threshold
    return readreg(core.PILT)


PUB prox_int_set_hi_thresh(t)
' Set proximity sensor interrupt high threshold
'   Valid values
'       0..255
    t := 0 #> t <# 255
    writereg(core.PIHT, t)


PUB prox_int_set_lo_thresh(t)
' Set proximity sensor interrupt low threshold
'   Valid values
'       0..255
    t := 0 #> t <# 255
    writereg(core.PILT, t)


PUB prox_pulse_cnt(n=-2): c     'XXX tentatively named
' Set proximity pulse count, generated on LDR   'XXX tentative summary
'   Valid values: 1..64
'   Any other value polls the device and returns the current setting
    c := readreg(core.PPULSECNT)
    case n
        1..64:
            n -= 1
            n := (c & core.PPULSE_MASK) | n
            writereg(core.PPULSECNT, n)
        other:
            return ( (c & core.PPULSE_BITS) + 1 )


PUB red_data(): r
' Red-channel sensor data
'   Returns: 16-bit unsigned
    return readreg(core.RDATAL, 2)


PUB reset()
' Reset the device


PUB sleep_after_ints(s=-2): c
' Enter low power mode when an interrupt is asserted
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
'   NOTE: To return to normal operating mode, clear the interrupt
    c := readreg(core.CONFIG3)
    case abs(s)
        0, 1:
            s := abs(s) << core.SAI
            s := (c & core.SAI_MASK) | s
            writereg(core.CONFIG3, s)
        other:
            return ( ((c >> core.SAI) & 1) == 1 )


PUB wait_time(t=-2): c
' Set inter-measurement wait timer (low-power mode between measurements), in microseconds
'   Valid values: *2_780..712_000, in multiples of 2_780 (rounded to nearest result)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the ALS/RGB engine. The proximity and gesture engines are not affected.
    case t
        2_780..712_000:
            t := 256-(t / 2_780)
            writereg(core.ATIME, t)
        other:
            c := readreg(core.WTIME)
            return ( (256-c) * 2_780 )


PUB wait_timer_ena(e=-2): c
' Enable inter-measurement wait timer
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    c := readreg(core.ENABLE)
    case abs(e)
        0, 1:
            e := abs(e) << core.WEN
            e := (c & core.WEN_MASK) | e
            writereg(core.ENABLE, e)
        other:
            return ( ((c >> core.WEN) & 1) == 1 )


PUB white_data(): c
' White/clear-channel sensor data
'   Returns: 16-bit unsigned
    return readreg(core.CDATAL, 2)


PRI readreg(reg_nr, len=1, p_dest=0): v | cmd_pkt, tmp
' Read nr_bytes from the slave device
    case reg_nr                                             ' Basic register validation
        core.CDATAL, core.RDATAL, core.GDATAL, core.BDATAL, core.PDATA:
        core.RAM..core.ATIME, core.WTIME..core.AIHTH, core.PILT, core.PIHT..core.CONFIG2, ...
        core.DEVICEID..core.STATUS, core.POFFSET_UR..core.GOFFSET_L, ...
        core.GOFFSET_R..core.GCONF4, core.GFLVL, core.GSTATUS, core.GFIFO_U..core.GFIFO_R:
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    if ( len =< 4 )                             ' for small enough reads, just return the value
        v := 0
        p_dest := @v

    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start()
    i2c.write(SLAVE_RD)
    i2c.rdblock_lsbf(p_dest, len, i2c.NAK)
    i2c.stop()


PRI writereg(reg_nr, val=0, len=1) | cmd_pkt, tmp
' Write nr_bytes to the slave device
    case reg_nr                                 ' Basic register validation
        core.RAM..core.ATIME, core.WTIME..core.AIHTH, core.PILT, core.PIHT, ...
        core.PERS..core.CONTROL, core.POFFSET_UR..core.GOFFSET_L, core.GOFFSET_R..core.GCONF4:
        core.CONFIG2:
            val |= 1                            ' Reserved bit that must always be set
        core.IFORCE..core.AICLEAR:              ' Commands with no parameters
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.stop()
            return
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_lsbf(@val, len)
    i2c.stop()


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

