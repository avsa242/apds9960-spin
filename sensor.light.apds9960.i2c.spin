{
    --------------------------------------------
    Filename: sensor.light.apds9960.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Allegro APDS9960 Proximity,
        Ambient Light, RGB and Gesture sensor
    Copyright (c) 2020
    Started Aug 02, 2020
    Updated Aug 02, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

    i2c : "com.i2c"                                             'PASM I2C Driver
    core: "core.con.apds9960.spin"                       'File containing your device's register set
    time: "time"                                                'Basic timing functions

PUB Null{}
''This is not a top-level object

PUB Start{}: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.msleep(core#TPOR)
                if i2c.present(SLAVE_WR)                        'Response from device?
                    if deviceid{} == core#DEVID_RESP
                        return

    return FALSE                                                'If we got here, something went wrong

PUB Stop{}
' Put any other housekeeping code here required/recommended by your device before shutting down
    i2c.terminate

PUB Defaults{}
' Set factory defaults
    powered(false)

PUB DefaultsALS{}

    powered(true)

PUB DefaultsProx{}

    powered(true)

PUB DefaultsGest{}

    powered(true)

PUB ALSDataReady{}: flag
' STATUS: AVALID

PUB ALSEnabled(state): curr_state
' ENABLE: AEN

PUB ALSGain(factor): curr_gain
' CONTROL: AGAIN: 1, 4, 16, 64

PUB ALSIntPersistence(cycles): curr_setting
' PERS: APERS: 0: every, 1: any outside, 2, 3=1:1 cycles, 4..15=(n-3)*5 cycles

PUB ALSIntsEnabled(state): curr_state
' ENABLE: AIEN

PUB ALSIntThreshold(low, high, rw): curr_setting
' [AILTL, AILTH], [AIHTL, AIHTH]: 8b ea

PUB DeviceID{}: id
' Read device identification
    readreg(core#DEVICEID, 1, @id)

PUB GesturesEnabled(state): curr_state
' ENABLE: GEN

PUB IntegrationTime(usecs): curr_setting
' ATIME: 8b, 2.78ms per LSB = 2780us per LSB, 256-TIME/2.78ms. ADC max := 1025*cycles

PUB LEDDriveCurrent(mA): curr_setting
' CONTROL: LDRIVE: 100, 50, 25, 12.5

PUB OpMode(mode): curr_mode
' GCONF4?

PUB Powered(state): curr_state
' Enable device power
'   Valid values: TRUE (-1 or 1), FALSE (0)
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

PUB ProxDataReady{}: flag
' STATUS: PVALID

PUB ProxDetEnabled(state): curr_state
' ENABLE: PEN

PUB ProxGain(factor): curr_gain
' CONTROL: PGAIN: 1, 2, 4, 8

PUB ProxIntPersistence(cycles): curr_setting
' PERS: PPERS, 0: every, 1: any outside, 2..15=1:1 cycles

PUB ProxIntsEnabled(state): curr_state
' ENABLE: PEN

PUB ProxIntThresh(low, high, rw): curr_thr
' PILT, PIHT: 8b ea

PUB Reset{}
' Reset the device

PUB WaitTime(usecs): curr_setting
' WTIME: 8b, 2.78ms per LSB = 2780us per LSB (if WLONG==1, time*=12) 256-TIME/2.78ms

PUB WaitTimerEnabled(state): curr_state
' ENABLE: WEN

PRI readReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
' Read nr_bytes from the slave device
    case reg_nr                                             ' Basic register validation
        core#CDATAL, core#RDATAL, core#GDATAL, core#BDATAL, core#PDATA:

        core#RAM..core#ATIME, core#WTIME..core#AIHTH, core#PILT, core#PIHT..core#CONFIG2, core#DEVICEID..core#STATUS, core#POFFSET_UR..core#GOFFSET_L, core#GOFFSET_R..core#GCONF4, core#GFLVL, core#GSTATUS, core#GFIFO_U..core#GFIFO_R:

        OTHER:
            return

    cmd_packet.byte[0] := SLAVE_WR
    cmd_packet.byte[1] := reg_nr
    i2c.start{}
    i2c.wr_block (@cmd_packet, 2)
    i2c.start{}
    i2c.write (SLAVE_RD)
    i2c.rd_block (buff_addr, nr_bytes, TRUE)
    i2c.stop{}

PRI writeReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
' Write nr_bytes to the slave device
    case reg_nr                                             ' Basic register validation
        core#RAM..core#ATIME, core#WTIME..core#AIHTH, core#PILT, core#PIHT, core#PERS..core#CONTROL, core#POFFSET_UR..core#GOFFSET_L, core#GOFFSET_R..core#GCONF4:
        core#CONFIG2:
            byte[buff_addr][0] |= 1                         ' APDS9960: Reserved bit that must always be set

        core#IFORCE..core#AICLEAR:

        OTHER:
            return

    cmd_packet.byte[0] := SLAVE_WR
    cmd_packet.byte[1] := reg_nr
    i2c.start{}
    i2c.wr_block (@cmd_packet, 2)
    repeat tmp from 0 to nr_bytes-1
        i2c.write (byte[buff_addr][tmp])
    i2c.stop{}

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
