{
    --------------------------------------------
    Filename: sensor.light.apds9960.spin
    Author: Jesse Burt
    Description: Driver for the Allegro APDS9960 Proximity,
        Ambient Light, RGB and Gesture sensor
    Copyright (c) 2022
    Started Aug 2, 2020
    Updated Sep 27, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

    R               = 0
    W               = 1

' Gesture sensor modes
    ALS             = 0
    GEST            = 1

' Gesture sensor dimension select
    BOTH            = 0
    UPDOWN          = 1
    LEFTRIGHT       = 2

OBJ

#ifdef APDS9960_SPIN
    i2c : "com.i2c.nocog"                       ' SPIN I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.apds9960"
    time: "time"                                ' timekeepng methods

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom I/O settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate I/O pins and freq
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.msleep(core#TPOR)
            if (i2c.present(SLAVE_WR))          ' test device bus presence
                if (dev_id{} == core#DEVID_RESP)
                    return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}

PUB defaults{}
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

PUB preset_als{}
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

PUB preset_prox{}
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

PUB preset_gest{}
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
    readreg(core#CDATAL, 8, @tmp)
    long[ptr_c] := tmp.word[0]
    long[ptr_r] := tmp.word[1]
    long[ptr_g] := tmp.word[2]
    long[ptr_b] := tmp.word[3]

PUB als_data_rdy{}: flag
' Flag indicating ambient light source data is ready
'   Returns: TRUE (-1) or FALSE (0)
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return ((flag >> core#AVALID) & 1) == 1

PUB als_ena(state): curr_state
' Enable ambient light source sensor/ADC
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#AEN
        other:
            return ((curr_state >> core#AEN) & %1) == 1

    state := (curr_state & core#AEN_MASK) | state
    writereg(core#ENABLE, 1, @state)

PUB als_gain(factor): curr_gain
' Set ambient light sensor gain multiplier
'   Valid values: *1, 4, 16, 64
'   Any other value polls the device and returns the current setting
    curr_gain := 0
    readreg(core#CONTROL, 1, @curr_gain)
    case factor
        1, 4, 16, 64:
            factor := lookdownz(factor: 1, 4, 16, 64)
        other:
            curr_gain &= core#AGAIN_BITS
            return lookupz(curr_gain: 1, 4, 16, 64)

    factor := (curr_gain & core#AGAIN_MASK) | factor
    writereg(core#CONTROL, 1, @factor)

PUB als_int_duration(cycles): curr_setting
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
    curr_setting := 0
    readreg(core#PERS, 1, @curr_setting)
    case cycles
        0..3:
        5..60:
            cycles := (cycles / 5) + 3
        other:
            if (curr_setting &= core#APERS_BITS) =< 3
                return curr_setting
            else
                return ((curr_setting & core#APERS_BITS) - 3) * 5

    cycles := (curr_setting & core#APERS_MASK) | cycles
    writereg(core#PERS, 1, @cycles)

PUB als_int_ena(state): curr_state
' Enable ALS interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#AIEN
        other:
            return ((curr_state >> core#AIEN) & %1) == 1

    state := (curr_state & core#AIEN_MASK) | state
    writereg(core#ENABLE, 1, @state)

PUB als_int_hi_thresh{}: thresh
' Get ALS interrupt high threshold
    thresh := 0
    readreg(core#AIHTL, 2, thresh)

PUB als_int_lo_thresh{}: thresh
' Get ALS interrupt low threshold
    thresh := 0
    readreg(core#AILTL, 2, thresh)

PUB als_int_set_hi_thresh(thresh)
' Set ALS interrupt high threshold
'   Valid values
'       low, high: 0..65535
    thresh := 0 #> thresh <# 65535
    writereg(core#AIHTL, 2, @thresh)

PUB als_int_set_lo_thresh(thresh)
' Set ALS interrupt low threshold
'   Valid values
'       low, high: 0..65535
    thresh := 0 #> thresh <# 65535
    writereg(core#AILTL, 2, @thresh)

PUB als_integr_time(usecs): curr_setting
' Set ALS integration time, in microseconds
'   Valid values: *2_780..712_000, in multiples of 2_780 (rounded to nearest result)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the ALS/RGB engine. The proximity and gesture engines are not affected.
    case usecs
        2_780..712_000:
            usecs := 256-(usecs / 2_780)
            writereg(core#ATIME, 1, @usecs)
        other:
            curr_setting := 0
            readreg(core#ATIME, 1, @curr_setting)
            return (256-curr_setting) * 2_780

PUB blue_data{}: bdata
' Blue-channel sensor data
'   Returns: 16-bit unsigned
    bdata := 0
    readreg(core#CDATAL, 2, @bdata)

PUB dev_id{}: id
' Read device identification
    id := 0
    readreg(core#DEVICEID, 1, @id)

PUB green_data{}: gdata
' Green-channel sensor data
'   Returns: 16-bit unsigned
    gdata := 0
    readreg(core#GDATAL, 2, @gdata)

PUB gest_fifo_nr_unread{}: nr_samples
' Number of samples available in FIFO
'   Returns: 8-bit unsigned
'   NOTE: One sample is a complete set of U, D, L, R data. To reduce the level reported here, a complete dataset must be read
    readreg(core#GFLVL, 1, @nr_samples)

PUB gest_fifo_overflow{}: flag
' Flag indicating gesture FIFO has overflowed
'   Returns: TRUE (-1) if FIFO overflowed (data has been lost), FALSE (0) otherwise
    readreg(core#GSTATUS, 1, @flag)
    flag := ((flag >> core#GFOV) & 1) == 1

PUB gest_led_current(mA): curr_setting | ledboost
' Set LED drive current in gesture mode, in milliamperes
'   Valid values: 300, 200, 150, *100, 50, 25, 12_5 (12.5)
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#GCONF2, 1, @curr_setting.byte[0])
    readreg(core#CONFIG2, 1, @curr_setting.byte[1])
    case mA
        100, 50, 25, 12_5:
            mA := lookdownz(mA: 100, 50, 25, 12_5) << core#GLDRIVE
        150, 200, 300:
            mA := 0
            ledboost := lookdown(mA: 150, 200, 300)
        other:
            curr_setting.byte[0] := (curr_setting.byte[0] >> core#GLDRIVE) & core#GLDRIVE_BITS
            curr_setting.byte[1] := (curr_setting.byte[1] >> core#LED_BOOST) & core#LED_BOOST_BITS
            if curr_setting.byte[1]
                return lookdown(curr_setting.byte[1]: 150, 200, 300)
            else
                return lookupz(curr_setting.byte[0]: 100, 50, 25, 12_5)

    mA := (curr_setting.byte[0] & core#GLDRIVE_MASK) | mA
    ledboost := (curr_setting.byte[1] & core#LEDBOOST_MASK) | ledboost
    writereg(core#GCONF2, 1, @mA)
    writereg(core#CONFIG2, 1, @ledboost)

PUB gest_pulse_cnt(nr_pulses): curr_setting     'XXX tentatively named
' Set gesture LED pulse count, generated on LDR 'XXX tentative summary
'   Valid values: 1..64
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#GPULSECNT, 1, @curr_setting)
    case nr_pulses
        1..64:
            nr_pulses -= 1
        other:
            return (curr_setting & core#GPULSE_BITS) + 1

    nr_pulses := (curr_setting & core#GPULSE_MASK) | nr_pulses
    writereg(core#GPULSECNT, 1, @nr_pulses)

PUB gest_pulse_len(usec): curr_setting
' Set gesture LED pulse length, generated on LDR, in microseconds 'XXX tentative summary
'   Valid values: 4, *8, 16, 32
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#GPULSECNT, 1, @curr_setting)
    case usec
        4, 8, 16, 32:
            usec := lookdownz(usec: 4, 8, 16, 32) << core#GPLEN
        other:
            curr_setting := (curr_setting >> core#GPLEN) & core#GPLEN_BITS
            return lookupz(curr_setting: 4, 8, 16, 32)

    usec := (curr_setting & core#GPLEN_MASK) | usec
    writereg(core#GPULSECNT, 1, @usec)

PUB gest_data(ptr_u, ptr_d, ptr_l, ptr_r) | tmp
' All gesture sensor source data
'   ptr_u, ptr_d, ptr_l, ptr_r: pointers at least 1 byte in size, each
    readreg(core#GFIFO_U, 4, @tmp)
    byte[ptr_u] := tmp.byte[0]
    byte[ptr_d] := tmp.byte[1]
    byte[ptr_l] := tmp.byte[2]
    byte[ptr_r] := tmp.byte[3]

PUB gest_data_down{}: data
' Gesture sensor down direction data
'   Returns: 8-bit unsigned
    readreg(core#GFIFO_D, 1, @data)

PUB gest_data_left{}: data
' Gesture sensor left direction data
'   Returns: 8-bit unsigned
    readreg(core#GFIFO_L, 1, @data)

PUB gest_data_rdy{}: flag
' Flag indicating gesture FIFO contains valid data
'   NOTE: Flag will be set when FIFO level exceeds threshold set with GestureFIFOThresh()
    readreg(core#GSTATUS, 1, @flag)
    return (flag & 1) == 1

PUB gest_data_right{}: data
' Gesture sensor right direction data
'   Returns: 8-bit unsigned
    readreg(core#GFIFO_R, 1, @data)

PUB gest_data_up{}: data
' Gesture sensor up direction data
'   Returns: 8-bit unsigned
    readreg(core#GFIFO_U, 1, @data)

PUB gest_dims(dim_select): curr_setting
' Select which sensor pairs are used to detect gestures
'   Valid values:
'       BOTH (0): Both Up/Down and Left/Right sensors active
'       UPDOWN (1): Only the Up/Down sensor is active (Right/Left FIFO data always 0)
'       LEFTRIGHT (2): Only the Left/Right sensor is active (Up/Down FIFO data always 0)
'   Any other value polls the device and returns the current setting
    case (dim_select &= core#GCONF3_MASK)
        BOTH, UPDOWN, LEFTRIGHT:
            writereg(core#GCONF3, 1, @dim_select)
        other:
            curr_setting := 0
            readreg(core#GCONF3, 1, @curr_setting)
            return (curr_setting & core#GDIMS_BITS)

PUB gest_ena(state): curr_state
' Enable gesture sensing
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#GEN
        other:
            return ((curr_state >> core#GEN) & 1) == 1

    state := (curr_state & core#GEN_MASK) | state
    writereg(core#ENABLE, 1, @state)

PUB gest_end_duration(cycles): curr_setting
' Set gesture exit persistence filter (number of gesture end occurences before gesture state machine is exited) 'XXX tentative summary
'   Valid values: 1, 2, 4, 7
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#GCONF1, 1, @curr_setting)
    case cycles
        1, 2, 4, 7:
            cycles := lookdownz(cycles: 1, 2, 4, 7)
        other:
            return lookupz(curr_setting: 1, 2, 4, 7)

    cycles := (curr_setting & core#GEXPERS_MASK) | cycles
    writereg(core#GCONF1, 1, @cycles)

PUB gest_end_thresh{}: thresh
' Get threshold used to determine if a gesture has ended
    thresh := 0
    readreg(core#GEXTH, 1, @thresh)

PUB gest_set_end_thresh(thresh)
' Set threshold used to determine if a gesture has ended
'   Valid values: 0..255
'   NOTE: This value is compared with output from ProxData(), to determine if a gesture has started
    thresh := 0 #> thresh <# 255
    writereg(core#GEXTH, 1, @thresh)

PUB gest_fifo_thresh(level): curr_thr
' Set gesture FIFO threshold for asserting an interrupt
'   Valid values: *1, 4, 8, 16
'   Any other value polls the device and returns the current setting
'   NOTE: Gesture data is only added to the FIFO if it reaches or exceeds the threshold set with GestureStartThresh()
    curr_thr := 0
    readreg(core#GCONF1, 1, @curr_thr)
    case level
        1, 4, 8, 16:
            level := lookdownz(level: 1, 4, 8, 16) << core#GFIFOTH
        other:
            curr_thr := (curr_thr >> core#GFIFOTH) & core#GFIFOTH_BITS
            return lookupz(curr_thr: 1, 4, 8, 16)

    level := (curr_thr & core#GFIFOTH_MASK) | level
    writereg(core#GCONF1, 1, @level)

PUB gest_gain(factor): curr_setting
' Set proximity sensor gain in gesture mode
'   Valid values: *1, 2, 4, 8
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#GCONF2, 1, @curr_setting)
    case factor
        1, 2, 4, 8:
            factor := lookdownz(factor: 1, 2, 4, 8) << core#GGAIN
        other:
            curr_setting := (curr_setting >> core#GGAIN) & core#GGAIN_BITS
            return lookupz(curr_setting: 1, 2, 4, 8)

    factor := (curr_setting & core#GGAIN_MASK) | factor
    writereg(core#GCONF2, 1, @factor)

PUB gest_int_clr{} | tmp
' Clear gesture-sourced interrupts
    readreg(core#GCONF4, 1, @tmp)
    tmp |= (1 << core#GFIFO_CLR)
    writereg(core#GCONF4, 1, @tmp)

PUB gest_interrupt{}: flag
' Flag indicating gesture interrupt asserted
'   Returns: TRUE (-1) if interrupt asserted, FALSE (0) otherwise
    readreg(core#STATUS, 1, @flag)
    return ((flag >> core#GINT) & 1) == 1

PUB gest_int_ena(state): curr_state
' Enable gesture sensor interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and rturns the current setting
    curr_state := 0
    readreg(core#GCONF4, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#GIEN
        other:
            return ((curr_state >> core#GIEN) & 1) == 1

    state := (curr_state & core#GIEN_MASK) | state
    writereg(core#GCONF4, 1, @state)

PUB gest_start_thresh{}: thresh
' Get threshold used to determine if a gesture has started
    thresh := 0
    readreg(core#GPENTH, 1, @thresh)

PUB gest_set_start_thresh(thresh)
' Set threshold used to determine if a gesture has started
'   Valid values: 0..255
'   NOTE: This value is compared with output from ProxData(), to determine if a gesture has started
    thresh := 0 #> thresh <# 255
    writereg(core#GPENTH, 1, @thresh)

PUB gest_wait_time(msecs): curr_setting
' Set inter-measurement wait timer (low-power mode between measurements), in milliseconds
'   Valid values: *0, 2_8 (2.8), 5_6 (5.6), 8_4 (8.4), 14_0 (14.0), 22_4 (22.4), 30_8 (30.8), 39_2 (39.2)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the Gesture engine. The proximity and ALS engines are not affected.
    curr_setting := 0
    readreg(core#GCONF2, 1, @curr_setting)
    case msecs
        0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2:
            msecs := lookdownz(msecs: 0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2)
        other:
            curr_setting := curr_setting & core#GWTIME_BITS
            return lookupz(curr_setting: 0, 2_8, 5_6, 8_4, 14_0, 22_4, 30_8, 39_2)

    msecs := (curr_setting & core#GWTIME_MASK) | msecs
    writereg(core#GCONF2, 1, @msecs)

PUB led_current(mA): curr_setting
' Set LED drive current, used in Proximity and Gesture sensing modes, in milliamperes
'   Valid values: *100, 50, 25, 12_5 (12.5)
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#CONTROL, 1, @curr_setting)
    case mA
        100, 50, 25, 12_5:
            mA := lookdownz(mA: 100, 50, 25, 12_5) << core#LDRIVE
        other:
            curr_setting := (curr_setting >> core#LDRIVE) & core#LDRIVE_BITS
            return lookupz(curr_setting: 100, 50, 25, 12_5)

    mA := (curr_setting & core#LDRIVE_MASK) | mA
    writereg(core#CONTROL, 1, @mA)

PUB opmode(mode): curr_mode
' Set sensor operating mode
'   Valid values:
'       ALS (0): ALS/Proximity/RGB mode
'       GEST (1): Gesture mode
'   Any other value polls the device and rturns the current setting
    curr_mode := 0
    readreg(core#GCONF4, 1, @curr_mode)
    case mode
        ALS, GEST:
        other:
            return curr_mode & 1

    mode := (curr_mode & core#GMODE_MASK) | mode
    writereg(core#GCONF4, 1, @mode)

PUB powered(state): curr_state
' Enable device power
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state)
        other:
            return (curr_state & %1) == 1

    state := (curr_state & core#PON_MASK) | state
    writereg(core#ENABLE, 1, @state)

PUB prox_data{}: pdata
' Read proximity sensor data
'   Returns: 8bit unsigned
    readreg(core#PDATA, 1, @pdata)

PUB prox_data_rdy{}: flag
' Flag indicating proximity sensor data is ready
'   Returns: TRUE (-1) or FALSE (0)
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return ((flag >> core#PVALID) & 1) == 1

PUB prox_det_ena(state): curr_state
' Enable proximity sensing/detection
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#PEN
        other:
            return ((curr_state >> core#PEN) & 1) == 1

    state := (curr_state & core#PEN_MASK) | state
    writereg(core#ENABLE, 1, @state)

PUB prox_gain(factor): curr_gain
' Set proximity sensor gain multiplier
'   Valid values: *1, 2, 4, 8
'   Any other value polls the device and returns the current setting
    curr_gain := 0
    readreg(core#CONTROL, 1, @curr_gain)
    case factor
        1, 2, 4, 8:
            factor := lookdownz(factor: 1, 2, 4, 8) << core#PGAIN
        other:
            curr_gain := (curr_gain >> core#PGAIN) & core#PGAIN_BITS
            return lookupz(curr_gain: 1, 2, 4, 8)

    factor := (curr_gain & core#PGAIN_MASK) | factor
    writereg(core#CONTROL, 1, @factor)

PUB prox_int_clr{}
' Clear proximity sensor interrupt
    writereg(core#PICLEAR, 0, 0)

PUB prox_integr_time(usecs): curr_setting
' Set proximity sensor integration time, in microseconds
'   Valid values: 4, *8, 16, 32
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#PPULSECNT, 1, @curr_setting)
    case usecs
        4, 8, 16, 32:
            usecs := lookdownz(usecs: 4, 8, 16, 32) << core#PPLEN
        other:
            curr_setting := (curr_setting >> core#PPLEN) & core#PPLEN_BITS
            return lookupz(curr_setting: 4, 8, 16, 32)

    usecs := (curr_setting & core#PPLEN_MASK) | usecs
    writereg(core#PPULSECNT, 1, @usecs)

PUB prox_interrupt{}: flag
' Flag indicating proximity sensor interrupt
'   Returns: TRUE (-1) if interrupt asserted, FALSE (0) otherwise
    readreg(core#STATUS, 1, @flag)
    return ((flag >> core#PINT) & 1) == 1

PUB prox_int_duration(cycles): curr_setting
' Set interrupt duration, in cycles
'   Defines how many consecutive measurements must be outside the interrupt threshold
'   before an interrupt is actually triggered (e.g., to reduce false positives)
'   Valid values:
'      *0 - _Every measurement_ triggers an interrupt, _regardless_
'       1 - Every measurement _outside your set threshold_ triggers an interrupt
'       2..15 - Must be 'n' consecutive measurements outside the set threshold to trigger an interrupt
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#PERS, 1, @curr_setting)
    case cycles
        0..15:
            cycles <<= core#PPERS
        other:
            return (curr_setting >> core#PPERS) & core#PPERS_BITS

    cycles := (curr_setting & core#PPERS_MASK) | cycles
    writereg(core#PERS, 1, @cycles)

PUB prox_int_ena(state): curr_state
' Enable Proximity sensor interrupt source
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#PIEN
        other:
            return ((curr_state >> core#PIEN) & %1) == 1

    state := (curr_state & core#PIEN_MASK) | state
    writereg(core#ENABLE, 1, @state)

PUB prox_int_hi_thresh{}: thresh
' Get proximity sensor interrupt high threshold
    thresh := 0
    readreg(core#PIHT, 1, thresh)

PUB prox_int_lo_thresh{}: thresh
' Get proximity sensor interrupt low threshold
    thresh := 0
    readreg(core#PILT, 1, thresh)

PUB prox_int_set_hi_thresh(thresh)
' Set proximity sensor interrupt high threshold
'   Valid values
'       0..255
    thresh := 0 #> thresh <# 255
    writereg(core#PIHT, 1, @thresh)

PUB prox_int_set_lo_thresh(thresh)
' Set proximity sensor interrupt low threshold
'   Valid values
'       0..255
    thresh := 0 #> thresh <# 255
    writereg(core#PILT, 1, @thresh)

PUB prox_pulse_cnt(nr_pulses): curr_setting     'XXX tentatively named
' Set proximity pulse count, generated on LDR   'XXX tentative summary
'   Valid values: 1..64
'   Any other value polls the device and returns the current setting
    curr_setting := 0
    readreg(core#PPULSECNT, 1, @curr_setting)
    case nr_pulses
        1..64:
            nr_pulses -= 1
        other:
            return (curr_setting & core#PPULSE_BITS) + 1

    nr_pulses := (curr_setting & core#PPULSE_MASK) | nr_pulses
    writereg(core#PPULSECNT, 1, @nr_pulses)

PUB red_data{}: rdata
' Red-channel sensor data
'   Returns: 16-bit unsigned
    rdata := 0
    readreg(core#RDATAL, 2, @rdata)

PUB reset{}
' Reset the device

PUB sleep_after_ints(enable): curr_setting
' Enter low power mode when an interrupt is asserted
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
'   NOTE: To return to normal operating mode, clear the interrupt
    curr_setting := 0
    readreg(core#CONFIG3, 1, @curr_setting)
    case ||(enable)
        0, 1:
            enable := ||(enable) << core#SAI
        other:
            curr_setting := ((curr_setting >> core#SAI) & 1) == 1

    enable := (curr_setting & core#SAI_MASK) | enable
    writereg(core#CONFIG3, 1, @enable)

PUB wait_time(usecs): curr_setting
' Set inter-measurement wait timer (low-power mode between measurements), in microseconds
'   Valid values: *2_780..712_000, in multiples of 2_780 (rounded to nearest result)
'   Any other value polls the device and returns the current setting
'   NOTE: This setting only applies to the ALS/RGB engine. The proximity and gesture engines are not affected.
    case usecs
        2_780..712_000:
            usecs := 256-(usecs / 2_780)
            writereg(core#ATIME, 1, @usecs)
        other:
            curr_setting := 0
            readreg(core#WTIME, 1, @curr_setting)
            return (256-curr_setting) * 2_780

PUB wait_timer_ena(state): curr_state
' Enable inter-measurement wait timer
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the device and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#WEN
        other:
            return ((curr_state >> core#WEN) & 1) == 1

    state := (curr_state & core#WEN_MASK) | state
    writereg(core#ENABLE, 1, @state)

PUB white_data{}: cdata
' White/clear-channel sensor data
'   Returns: 16-bit unsigned
    cdata := 0
    readreg(core#CDATAL, 2, @cdata)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from the slave device
    case reg_nr                                             ' Basic register validation
        core#CDATAL, core#RDATAL, core#GDATAL, core#BDATAL, core#PDATA:
        core#RAM..core#ATIME, core#WTIME..core#AIHTH, core#PILT, core#PIHT..core#CONFIG2, core#DEVICEID..core#STATUS, core#POFFSET_UR..core#GOFFSET_L, core#GOFFSET_R..core#GCONF4, core#GFLVL, core#GSTATUS, core#GFIFO_U..core#GFIFO_R:
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start{}
    i2c.write (SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes to the slave device
    case reg_nr                                             ' Basic register validation
        core#RAM..core#ATIME, core#WTIME..core#AIHTH, core#PILT, core#PIHT, core#PERS..core#CONTROL, core#POFFSET_UR..core#GOFFSET_L, core#GOFFSET_R..core#GCONF4:
        core#CONFIG2:
            byte[ptr_buff][0] |= 1                         ' APDS9960: Reserved bit that must always be set
        core#IFORCE..core#AICLEAR:                          ' Commands with no parameters
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.stop{}
            return
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_lsbf(ptr_buff, nr_bytes)
    i2c.stop{}

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

