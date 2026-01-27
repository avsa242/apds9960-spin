{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.light.apds9960.spin
    Description:    Driver for the APDS9960 Proximity, Ambient Light, RGB and Gesture sensor
    Author:         Jesse Burt
    Started:        Aug 2, 2020
    Updated:        Jan 27, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O configuration - these can be overridden by the parent object }
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 100_000

    { Gesture sensor modes }
    ALS             = 0
    GEST            = 1

    { Gesture sensor dimension select }
    BOTH            = 0
    UPDOWN          = 1
    LEFTRIGHT       = 2


    SLAVE_WR        = core.SLAVE_ADDR
    SLAVE_RD        = core.SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core.I2C_MAX_FREQ

    R               = 0
    W               = 1


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
' Start using custom I/O settings
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
    powered(true)
    gest_end_duration(1)
    gest_led_current(100)
    gest_pulse_cnt(1)
    gest_dims(BOTH)
    gest_fifo_thresh(1)
    gest_gain(1)
    gest_int_ena(true)
    opmode(GEST)
    gest_ena(true)
    gest_wait_time(0)
    gest_set_start_thresh(0)
    gest_set_end_thresh(0)


PUB als_data(ptr_c, ptr_r, ptr_g, ptr_b) | tmp[2]
' All ambient light source data
'   ptr_c, ptr_r, ptr_g, ptr_b: pointers at least 1 word in size, each
    readreg(core.CDATAL, 8, @tmp)
    long[ptr_c] := tmp.word[0]
    long[ptr_r] := tmp.word[1]
    long[ptr_g] := tmp.word[2]
    long[ptr_b] := tmp.word[3]


PUB als_data_rdy(): flag
' Flag indicating ambient light source data is ready
'   Returns: TRUE (-1) or FALSE (0)
    flag := readreg(core.STATUS)
    return ( ((flag >> core.AVALID) & 1) == 1 )


PUB als_ena(state=-2): curr_state
' Enable ambient light source sensor/ADC
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := readreg(core.ENABLE)
    case ||(state)
        0, 1:
            state := ||(state) << core.AEN
            state := (curr_state & core.AEN_MASK) | state
            writereg(core.ENABLE, state)
        other:
            return ( ((curr_state >> core.AEN) & 1) == 1 )


PUB als_gain(factor=-2): curr_gain
' Set ambient light sensor gain multiplier
'   Valid values: *1, 4, 16, 64
'   Any other value polls the device and returns the current setting
    curr_gain := readreg(core.CONTROL)
    case factor
        1, 4, 16, 64:
            factor := lookdownz(factor: 1, 4, 16, 64)
            factor := (curr_gain & core.AGAIN_MASK) | factor
            writereg(core.CONTROL, factor)
        other:
            curr_gain &= core.AGAIN_BITS
            return lookupz(curr_gain: 1, 4, 16, 64)


PUB als_int_duration(cycles=-2): curr_setting
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
    curr_setting := readreg(core.PERS)
    case cycles
        0..3, 5..60:
            if ( cycles > 3 )
                cycles := (cycles / 5) + 3
            cycles := (curr_setting & core.APERS_MASK) | cycles
            writereg(core.PERS, cycles)
        other:
            if ( (curr_setting &= core.APERS_BITS) =< 3 )
                return curr_setting
            else
                return ( ((curr_setting & core.APERS_BITS) - 3) * 5 )


PUB als_int_ena(state=-2): curr_state
' Enable ALS interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := readreg(core.ENABLE)
    case ||(state)
        0, 1:
            state := ||(state) << core.AIEN
            state := (curr_state & core.AIEN_MASK) | state
            writereg(core.ENABLE, state)
        other:
            return ( ((curr_state >> core.AIEN) & 1) == 1 )


PUB als_int_hi_thresh(): thresh
' Get ALS interrupt high threshold
    thresh := readreg(core.AIHTL, 2)


PUB als_int_lo_thresh(): thresh
' Get ALS interrupt low threshold
    thresh := readreg(core.AILTL, 2)


PUB als_int_set_hi_thresh(thresh)
' Set ALS interrupt high threshold
'   Valid values
'       low, high: 0..65535
    thresh := 0 #> thresh <# 65535
    writereg(core.AIHTL, thresh, 2)


PUB als_int_set_lo_thresh(thresh)
' Set ALS interrupt low threshold
'   Valid values
'       low, high: 0..65535
    thresh := 0 #> thresh <# 65535
    writereg(core.AILTL, thresh, 2)


PUB als_integr_time(usecs=-2): curr_setting
' Set ALS integration time, in microseconds
'   Valid values: *2_780..712_000, in multiples of 2_780 (rounded to nearest result)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the ALS/RGB engine. The proximity and gesture engines
'       are not affected.
    case usecs
        2_780..712_000:
            usecs := 256-(usecs / 2_780)
            writereg(core.ATIME, usecs)
        other:
            curr_setting := readreg(core.ATIME)
            return ( (256-curr_setting) * 2_780 )


PUB blue_data(): bdata
' Blue-channel sensor data
'   Returns: 16-bit unsigned
    bdata := readreg(core.CDATAL, 2)


PUB dev_id(): id
' Read device identification
    return readreg(core.DEVICEID)


PUB green_data(): gdata
' Green-channel sensor data
'   Returns: 16-bit unsigned
    gdata := readreg(core.GDATAL, 2)


PUB gest_fifo_nr_unread(): nr_samples
' Number of samples available in FIFO
'   Returns: 8-bit unsigned
'   NOTE: One sample is a complete set of U, D, L, R data. To reduce the level reported here,
'       a complete dataset must be read.
    return readreg(core.GFLVL)


PUB gest_fifo_overflow(): flag
' Flag indicating gesture FIFO has overflowed
'   Returns: TRUE (-1) if FIFO overflowed (data has been lost), FALSE (0) otherwise
    flag := readreg(core.GSTATUS)
    flag := ( ((flag >> core.GFOV) & 1) == 1 )


PUB gest_led_current(mA=-2): curr_setting | ledboost
' Set LED drive current in gesture mode, in milliamperes
'   Valid values: 300, 200, 150, *100, 50, 25, 12_5 (12.5)
'   Any other value polls the device and returns the current setting
    curr_setting.byte[0] := readreg(core.GCONF2)
    curr_setting.byte[1] := readreg(core.CONFIG2)
    case mA
        100, 50, 25, 12_5:
            mA := lookdownz(mA: 100, 50, 25, 12_5) << core.GLDRIVE
        150, 200, 300:
            mA := 0
            ledboost := lookdown(mA: 150, 200, 300)
        other:
            curr_setting.byte[0] := (curr_setting.byte[0] >> core.GLDRIVE) & core.GLDRIVE_BITS
            curr_setting.byte[1] := (curr_setting.byte[1] >> core.LED_BOOST) & core.LED_BOOST_BITS
            if ( curr_setting.byte[1] )
                return lookdown(curr_setting.byte[1]: 150, 200, 300)
            else
                return lookupz(curr_setting.byte[0]: 100, 50, 25, 12_5)

    mA := (curr_setting.byte[0] & core.GLDRIVE_MASK) | mA
    ledboost := (curr_setting.byte[1] & core.LEDBOOST_MASK) | ledboost
    writereg(core.GCONF2, mA)
    writereg(core.CONFIG2, ledboost)


PUB gest_pulse_cnt(nr_pulses=-2): curr_setting     'XXX tentatively named
' Set gesture LED pulse count, generated on LDR 'XXX tentative summary
'   Valid values: 1..64
'   Any other value polls the device and returns the current setting
    curr_setting := readreg(core.GPULSECNT)
    case nr_pulses
        1..64:
            nr_pulses -= 1
            nr_pulses := (curr_setting & core.GPULSE_MASK) | nr_pulses
            writereg(core.GPULSECNT, nr_pulses)
        other:
            return ( (curr_setting & core.GPULSE_BITS) + 1 )

PUB gest_pulse_len(usec=-2): curr_setting
' Set gesture LED pulse length, generated on LDR, in microseconds 'XXX tentative summary
'   Valid values: 4, *8, 16, 32
'   Any other value polls the device and returns the current setting
    curr_setting := readreg(core.GPULSECNT)
    case usec
        4, 8, 16, 32:
            usec := lookdownz(usec: 4, 8, 16, 32) << core.GPLEN
            usec := (curr_setting & core.GPLEN_MASK) | usec
            writereg(core.GPULSECNT, usec)
        other:
            curr_setting := ( (curr_setting >> core.GPLEN) & core.GPLEN_BITS )
            return lookupz(curr_setting: 4, 8, 16, 32)


PUB gest_data(ptr_u, ptr_d, ptr_l, ptr_r) | tmp
' All gesture sensor source data
'   ptr_u, ptr_d, ptr_l, ptr_r: pointers to variables at least 1 byte in size, each
    tmp := readreg(core.GFIFO_U, 4)
    byte[ptr_u] := tmp.byte[0]
    byte[ptr_d] := tmp.byte[1]
    byte[ptr_l] := tmp.byte[2]
    byte[ptr_r] := tmp.byte[3]


PUB gest_data_down(): data
' Gesture sensor down direction data
'   Returns: 8-bit unsigned
    return readreg(core.GFIFO_D)


PUB gest_data_left(): data
' Gesture sensor left direction data
'   Returns: 8-bit unsigned
    return readreg(core.GFIFO_L)


PUB gest_data_rdy(): flag
' Flag indicating gesture FIFO contains valid data
'   NOTE: Flag will be set when FIFO level exceeds threshold set with gest_fifo_thresh()
    flag := readreg(core.GSTATUS)
    return ( (flag & 1) == 1 )


PUB gest_data_right(): data
' Gesture sensor right direction data
'   Returns: 8-bit unsigned
    return readreg(core.GFIFO_R)


PUB gest_data_up(): data
' Gesture sensor up direction data
'   Returns: 8-bit unsigned
    return readreg(core.GFIFO_U)


PUB gest_dims(dim_select=-2): curr_setting
' Select which sensor pairs are used to detect gestures
'   Valid values:
'       BOTH (0): Both Up/Down and Left/Right sensors active
'       UPDOWN (1): Only the Up/Down sensor is active (Right/Left FIFO data always 0)
'       LEFTRIGHT (2): Only the Left/Right sensor is active (Up/Down FIFO data always 0)
'   Any other value polls the device and returns the current setting
    case (dim_select &= core.GCONF3_MASK)
        BOTH, UPDOWN, LEFTRIGHT:
            writereg(core.GCONF3, dim_select)
        other:
            curr_setting := readreg(core.GCONF3)
            return (curr_setting & core.GDIMS_BITS)


PUB gest_ena(state=-2): curr_state
' Enable gesture sensing
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := readreg(core.ENABLE)
    case ||(state)
        0, 1:
            state := ||(state) << core.GEN
            state := (curr_state & core.GEN_MASK) | state
            writereg(core.ENABLE, state)
        other:
            return ( ((curr_state >> core.GEN) & 1) == 1 )


PUB gest_end_duration(cycles=-2): curr_setting
' Set gesture exit persistence filter (number of gesture end occurences before gesture
'   state machine is exited) 'XXX tentative summary
'   Valid values: 1, 2, 4, 7
'   Any other value polls the device and returns the current setting
    curr_setting := readreg(core.GCONF1)
    case cycles
        1, 2, 4, 7:
            cycles := lookdownz(cycles: 1, 2, 4, 7)
            cycles := (curr_setting & core.GEXPERS_MASK) | cycles
            writereg(core.GCONF1, cycles)
        other:
            return lookupz(curr_setting: 1, 2, 4, 7)


PUB gest_end_thresh(): thresh
' Get threshold used to determine if a gesture has ended
    return readreg(core.GEXTH)


PUB gest_set_end_thresh(thresh)
' Set threshold used to determine if a gesture has ended
'   Valid values: 0..255
'   NOTE: This value is compared with output from ProxData(), to determine if a gesture has started
    thresh := 0 #> thresh <# 255
    writereg(core.GEXTH, thresh)


PUB gest_fifo_thresh(level=-2): curr_thr
' Set gesture FIFO threshold for asserting an interrupt
'   Valid values: *1, 4, 8, 16
'   Any other value polls the device and returns the current setting
'   NOTE: Gesture data is only added to the FIFO if it reaches or exceeds the threshold set with GestureStartThresh()
    curr_thr := readreg(core.GCONF1)
    case level
        1, 4, 8, 16:
            level := lookdownz(level: 1, 4, 8, 16) << core.GFIFOTH
            level := (curr_thr & core.GFIFOTH_MASK) | level
            writereg(core.GCONF1, level)
        other:
            curr_thr := (curr_thr >> core.GFIFOTH) & core.GFIFOTH_BITS
            return lookupz(curr_thr: 1, 4, 8, 16)

PUB gest_gain(factor=-2): curr_setting
' Set proximity sensor gain in gesture mode
'   Valid values: *1, 2, 4, 8
'   Any other value polls the device and returns the current setting
    curr_setting := readreg(core.GCONF2)
    case factor
        1, 2, 4, 8:
            factor := lookdownz(factor: 1, 2, 4, 8) << core.GGAIN
            factor := (curr_setting & core.GGAIN_MASK) | factor
            writereg(core.GCONF2, factor)
        other:
            curr_setting := (curr_setting >> core.GGAIN) & core.GGAIN_BITS
            return lookupz(curr_setting: 1, 2, 4, 8)


PUB gest_int_clear() | tmp
' Clear gesture-sourced interrupts
    tmp := readreg(core.GCONF4)
    tmp |= (1 << core.GFIFO_CLR)
    writereg(core.GCONF4, tmp)


PUB gest_interrupt(): flag
' Flag indicating gesture interrupt asserted
'   Returns: TRUE (-1) if interrupt asserted, FALSE (0) otherwise
    flag := readreg(core.STATUS)
    return ( ((flag >> core.GINT) & 1) == 1 )


PUB gest_int_ena(state=-2): curr_state
' Enable gesture sensor interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and rturns the current setting
    curr_state := readreg(core.GCONF4)
    case ||(state)
        0, 1:
            state := ||(state) << core.GIEN
            state := (curr_state & core.GIEN_MASK) | state
            writereg(core.GCONF4, state)
        other:
            return ( ((curr_state >> core.GIEN) & 1) == 1 )


PUB gest_start_thresh(): thresh
' Get threshold used to determine if a gesture has started
    thresh := readreg(core.GPENTH)


PUB gest_set_start_thresh(thresh)
' Set threshold used to determine if a gesture has started
'   Valid values: 0..255
'   NOTE: This value is compared with output from prox_data(), to determine if a gesture has started
    thresh := 0 #> thresh <# 255
    writereg(core.GPENTH, thresh)


PUB gest_wait_time(msecs=-2): curr_setting
' Set inter-measurement wait timer (low-power mode between measurements), in milliseconds
'   Valid values: *0, 2_8 (2.8), 5_6 (5.6), 8_4 (8.4), 14_0 (14.0), 22_4 (22.4), 30_8 (30.8),
'       39_2 (39.2)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the Gesture engine. The proximity and ALS engines
'       are not affected.
    curr_setting := readreg(core.GCONF2)
    case msecs
        0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2:
            msecs := lookdownz(msecs: 0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2)
            msecs := (curr_setting & core.GWTIME_MASK) | msecs
            writereg(core.GCONF2, msecs)
        other:
            curr_setting := curr_setting & core.GWTIME_BITS
            return lookupz(curr_setting: 0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2)


PUB led_current(mA=-2): curr_setting
' Set LED drive current, used in Proximity and Gesture sensing modes, in milliamperes
'   Valid values: *100, 50, 25, 12_5 (12.5)
'   Any other value polls the device and returns the current setting
    curr_setting := readreg(core.CONTROL)
    case mA
        100, 50, 25, 12_5:
            mA := lookdownz(mA: 100, 50, 25, 12_5) << core.LDRIVE
            mA := (curr_setting & core.LDRIVE_MASK) | mA
            writereg(core.CONTROL, mA)
        other:
            curr_setting := (curr_setting >> core.LDRIVE) & core.LDRIVE_BITS
            return lookupz(curr_setting: 100, 50, 25, 12_5)


PUB opmode(mode=-2): curr_mode
' Set sensor operating mode
'   Valid values:
'       ALS (0): ALS/Proximity/RGB mode
'       GEST (1): Gesture mode
'   Any other value polls the device and rturns the current setting
    curr_mode := readreg(core.GCONF4)
    case mode
        ALS, GEST:
            mode := (curr_mode & core.GMODE_MASK) | mode
            writereg(core.GCONF4, mode)
        other:
            return ( curr_mode & 1 )


PUB powered(state=-2): curr_state
' Enable device power
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := readreg(core.ENABLE)
    case ||(state)
        0, 1:
            state := ||(state)
            state := (curr_state & core.PON_MASK) | state
            writereg(core.ENABLE, state)
        other:
            return ( (curr_state & 1) == 1 )


PUB prox_data(): pdata
' Read proximity sensor data
'   Returns: 8bit unsigned
    return readreg(core.PDATA)


PUB prox_data_rdy(): flag
' Flag indicating proximity sensor data is ready
'   Returns: TRUE (-1) or FALSE (0)
    flag := readreg(core.STATUS)
    return ( ((flag >> core.PVALID) & 1) == 1 )


PUB prox_det_ena(state=-2): curr_state
' Enable proximity sensing/detection
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := readreg(core.ENABLE)
    case ||(state)
        0, 1:
            state := ||(state) << core.PEN
            state := (curr_state & core.PEN_MASK) | state
            writereg(core.ENABLE, state)
        other:
            return ( ((curr_state >> core.PEN) & 1) == 1 )



PUB prox_gain(factor=-2): curr_gain
' Set proximity sensor gain multiplier
'   Valid values: *1, 2, 4, 8
'   Any other value polls the device and returns the current setting
    curr_gain := readreg(core.CONTROL)
    case factor
        1, 2, 4, 8:
            factor := lookdownz(factor: 1, 2, 4, 8) << core.PGAIN
            factor := (curr_gain & core.PGAIN_MASK) | factor
            writereg(core.CONTROL, factor)
        other:
            curr_gain := (curr_gain >> core.PGAIN) & core.PGAIN_BITS
            return lookupz(curr_gain: 1, 2, 4, 8)


PUB prox_int_clear()
' Clear proximity sensor interrupt
    writereg(core.PICLEAR)


PUB prox_integr_time(usecs=-2): curr_setting
' Set proximity sensor integration time, in microseconds
'   Valid values: 4, *8, 16, 32
'   Any other value polls the device and returns the current setting
    curr_setting := readreg(core.PPULSECNT)
    case usecs
        4, 8, 16, 32:
            usecs := lookdownz(usecs: 4, 8, 16, 32) << core.PPLEN
            usecs := (curr_setting & core.PPLEN_MASK) | usecs
            writereg(core.PPULSECNT, usecs)
        other:
            curr_setting := (curr_setting >> core.PPLEN) & core.PPLEN_BITS
            return lookupz(curr_setting: 4, 8, 16, 32)



PUB prox_interrupt(): flag
' Flag indicating proximity sensor interrupt
'   Returns: TRUE (-1) if interrupt asserted, FALSE (0) otherwise
    flag := readreg(core.STATUS)
    return ( ((flag >> core.PROXINT) & 1) == 1 )


PUB prox_int_duration(cycles=-2): curr_setting
' Set interrupt duration, in cycles
'   Defines how many consecutive measurements must be outside the interrupt threshold
'   before an interrupt is actually triggered (e.g., to reduce false positives)
'   Valid values:
'      *0 - _Every measurement_ triggers an interrupt, _regardless_
'       1 - Every measurement _outside the set threshold_ triggers an interrupt
'       2..15 - Must be 'n' consecutive measurements outside the set threshold to trigger
'           an interrupt
'   Any other value polls the device and returns the current setting
    curr_setting := readreg(core.PERS)
    case cycles
        0..15:
            cycles <<= core.PPERS
            cycles := (curr_setting & core.PPERS_MASK) | cycles
            writereg(core.PERS, cycles)
        other:
            return (curr_setting >> core.PPERS) & core.PPERS_BITS


PUB prox_int_ena(state=-2): curr_state
' Enable Proximity sensor interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := readreg(core.ENABLE)
    case ||(state)
        0, 1:
            state := ||(state) << core.PIEN
            state := (curr_state & core.PIEN_MASK) | state
            writereg(core.ENABLE, state)
        other:
            return ( ((curr_state >> core.PIEN) & 1) == 1 )



PUB prox_int_hi_thresh(): thresh
' Get proximity sensor interrupt high threshold
    return readreg(core.PIHT)


PUB prox_int_lo_thresh(): thresh
' Get proximity sensor interrupt low threshold
    return readreg(core.PILT)


PUB prox_int_set_hi_thresh(thresh)
' Set proximity sensor interrupt high threshold
'   Valid values
'       0..255
    thresh := 0 #> thresh <# 255
    writereg(core.PIHT, thresh)


PUB prox_int_set_lo_thresh(thresh)
' Set proximity sensor interrupt low threshold
'   Valid values
'       0..255
    thresh := 0 #> thresh <# 255
    writereg(core.PILT, thresh)


PUB prox_pulse_cnt(nr_pulses=-2): curr_setting     'XXX tentatively named
' Set proximity pulse count, generated on LDR   'XXX tentative summary
'   Valid values: 1..64
'   Any other value polls the device and returns the current setting
    curr_setting := readreg(core.PPULSECNT)
    case nr_pulses
        1..64:
            nr_pulses -= 1
            nr_pulses := (curr_setting & core.PPULSE_MASK) | nr_pulses
            writereg(core.PPULSECNT, nr_pulses)
        other:
            return ( (curr_setting & core.PPULSE_BITS) + 1 )


PUB red_data(): rdata
' Red-channel sensor data
'   Returns: 16-bit unsigned
    return readreg(core.RDATAL, 2)


PUB reset()
' Reset the device


PUB sleep_after_ints(enable=-2): curr_setting
' Enter low power mode when an interrupt is asserted
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
'   NOTE: To return to normal operating mode, clear the interrupt
    curr_setting := readreg(core.CONFIG3)
    case ||(enable)
        0, 1:
            enable := ||(enable) << core.SAI
            enable := (curr_setting & core.SAI_MASK) | enable
            writereg(core.CONFIG3, enable)
        other:
            return ( ((curr_setting >> core.SAI) & 1) == 1 )


PUB wait_time(usecs=-2): curr_setting
' Set inter-measurement wait timer (low-power mode between measurements), in microseconds
'   Valid values: *2_780..712_000, in multiples of 2_780 (rounded to nearest result)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the ALS/RGB engine. The proximity and gesture engines are not affected.
    case usecs
        2_780..712_000:
            usecs := 256-(usecs / 2_780)
            writereg(core.ATIME, usecs)
        other:
            curr_setting := readreg(core.WTIME)
            return ( (256-curr_setting) * 2_780 )


PUB wait_timer_ena(state=-2): curr_state
' Enable inter-measurement wait timer
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := readreg(core.ENABLE)
    case ||(state)
        0, 1:
            state := ||(state) << core.WEN
            state := (curr_state & core.WEN_MASK) | state
            writereg(core.ENABLE, state)
        other:
            return ( ((curr_state >> core.WEN) & 1) == 1 )


PUB white_data(): cdata
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

