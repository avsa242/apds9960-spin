{
    --------------------------------------------
    Filename: core.con.apds9960.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Aug 02, 2020
    Updated Aug 02, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ        = 400_000
    SLAVE_ADDR          = $39 << 1

    TPOR                = 6

' Register definitions
    RAM                 = $00
    RAM_END             = $7F
    ENABLE              = $80
    ATIME               = $81
    WTIME               = $83
    AILTL               = $84
    AILTH               = $85
    AIHTL               = $86
    AIHTH               = $87
    PILT                = $89
    PIHT                = $8B
    PERS                = $8C
    CONFIG1             = $8D
    PPULSE              = $8E
    CONTROL             = $8F
    CONFIG2             = $90
    DEVICEID            = $92
        DEVID_RESP      = $AB
    STATUS              = $93
    CDATAL              = $94
    CDATAH              = $95
    RDATAL              = $96
    RDATAH              = $97
    GDATAL              = $98
    GDATAH              = $99
    BDATAL              = $9A
    BDATAH              = $9B
    PDATA               = $9C
    POFFSET_UR          = $9D
    POFFSET_DL          = $9E
    CONFIG3             = $9F
    GPENTH              = $A0
    GEXTH               = $A1
    GCONF1              = $A2
    GCONF2              = $A3
    GOFFSET_U           = $A4
    GOFFSET_D           = $A5
    GOFFSET_L           = $A7
    GOFFSET_R           = $A9
    GPULSE              = $A6
    GCONF3              = $AA
    GCONF4              = $AB
    GFLVL               = $AE
    GSTATUS             = $AF
    IFORCE              = $E4
    PICLEAR             = $E5
    CICLEAR             = $E6
    AICLEAR             = $E7
    GFIFO_U             = $FC
    GFIFO_D             = $FD
    GFIFO_L             = $FE
    GFIFO_R             = $FF


#ifndef __propeller2__
PUB Null
'' This is not a top-level object
#endif
