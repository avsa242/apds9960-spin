{
    --------------------------------------------
    Filename: core.con.apds9960.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Aug 02, 2020
    Updated Aug 05, 2020
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
    ENABLE_MASK         = $7F
        GEN             = 6
        PIEN            = 5
        AIEN            = 4
        WEN             = 3
        PEN             = 2
        AEN             = 1
        PON             = 0
        GEN_MASK        = ENABLE_MASK ^ (1 << GEN)
        PIEN_MASK       = ENABLE_MASK ^ (1 << PIEN)
        AIEN_MASK       = ENABLE_MASK ^ (1 << AIEN)
        WEN_MASK        = ENABLE_MASK ^ (1 << WEN)
        PEN_MASK        = ENABLE_MASK ^ (1 << PEN)
        AEN_MASK        = ENABLE_MASK ^ (1 << AEN)
        PON_MASK        = ENABLE_MASK ^ (1 << PON)

    ATIME               = $81
    WTIME               = $83

    AILTL               = $84
    AILTH               = $85
    AIHTL               = $86
    AIHTH               = $87

    PILT                = $89
    PIHT                = $8B

    PERS                = $8C
    PERS_MASK           = $FF
        PPERS           = 4
        APERS           = 0
        PPERS_BITS      = %1111
        APERS_BITS      = %1111
        PPERS_MASK      = PERS_MASK ^ (PPERS_BITS << PPERS)
        APERS_MASK      = PERS_MASK ^ (APERS_BITS << APERS)

    CONFIG1             = $8D
    CONFIG1_MASK        = $02
        WLONG           = 1

    PPULSECNT           = $8E
    PPULSECNT_MASK      = $FF
        PPLEN           = 6
        PPULSE          = 0
        PPLEN_BITS      = %11
        PPULSE_BITS     = %111111
        PPLEN_MASK      = PPULSECNT_MASK ^ (PPLEN_BITS << PPLEN)
        PPULSE_MASK     = PPULSECNT_MASK ^ (PPULSE_BITS << PPULSE)

    CONTROL             = $8F
    CONTROL_MASK        = $CF
        LDRIVE          = 6
        PGAIN           = 2
        AGAIN           = 0
        LDRIVE_BITS     = %11
        PGAIN_BITS      = %11
        AGAIN_BITS      = %11
        LDRIVE_MASK     = CONTROL_MASK ^ (LDRIVE_BITS << LDRIVE)
        PGAIN_MASK      = CONTROL_MASK ^ (PGAIN_BITS << PGAIN)
        AGAIN_MASK      = CONTROL_MASK ^ (AGAIN_BITS << AGAIN)

    CONFIG2             = $90
    CONFIG2_MASK        = $F1                               ' *Always Write LSB (Reserved) as 1
        PSIEN           = 7
        CPSIEN          = 6
        LED_BOOST       = 4
        LED_BOOST_BITS  = %11
        PSIEN_MASK      = CONFIG2_MASK ^ (1 << PSIEN)
        CPSIEN_MASK     = CONFIG2_MASK ^ (1 << CPSIEN)
        LEDBOOST_MASK   = CONFIG2_MASK ^ (LED_BOOST_BITS << LED_BOOST)

    DEVICEID            = $92
        DEVID_RESP      = $AB

    STATUS              = $93
        CPSAT           = 7
        PGSAT           = 6
        PINT            = 5
        AINT            = 4
        GINT            = 2
        PVALID          = 1
        AVALID          = 0

    CDATAL              = $94                               ' Reading this reg first latches both
    CDATAH              = $95                               '   the upper byte of this reg,
    RDATAL              = $96                               '   as well as ALL of the remaining data
    RDATAH              = $97                               '   output regs
    GDATAL              = $98                               ' Similarly, reading any L reg latches the
    GDATAH              = $99                               '   corresponding H reg
    BDATAL              = $9A                               ' This guarantees the data being read is
    BDATAH              = $9B                               '   all from the same "frame"

    PDATA               = $9C
    POFFSET_UR          = $9D
    POFFSET_DL          = $9E

    CONFIG3             = $9F
    CONFIG3_MASK        = $3F
        PCMP            = 5
        SAI             = 4
        PMASK_U         = 3
        PMASK_D         = 2
        PMASK_L         = 1
        PMASK_R         = 0
        PCMP_MASK       = CONFIG3_MASK ^ (1 << PCMP)
        SAI_MASK        = CONFIG3_MASK ^ (1 << SAI)
        PMASK_U_MASK    = CONFIG3_MASK ^ (1 << PMASK_U)
        PMASK_D_MASK    = CONFIG3_MASK ^ (1 << PMASK_D)
        PMASK_L_MASK    = CONFIG3_MASK ^ (1 << PMASK_L)
        PMASK_R_MASK    = CONFIG3_MASK ^ (1 << PMASK_R)

    GPENTH              = $A0
    GEXTH               = $A1

    GCONF1              = $A2
    GCONF1_MASK         = $FF
        GFIFOTH         = 6
        GEXMSK          = 2
        GEXPERS         = 0
        GFIFOTH_BITS    = %11
        GEXMSK_BITS     = %1111
        GEXPERS_BITS    = %11
        GFIFOTH_MASK    = GCONF1_MASK ^ (GFIFOTH_BITS << GFIFOTH)
        GEXMSK_MASK     = GCONF1_MASK ^ (GEXMSK_BITS << GEXMSK)
        GEXPERS_MASK    = GCONF1_MASK ^ (GEXPERS_BITS << GEXPERS)

    GCONF2              = $A3
    GCONF2_MASK         = $7F
        GGAIN           = 5
        GLDRIVE         = 3
        GWTIME          = 0
        GGAIN_BITS      = %11
        GLDRIVE_BITS    = %11
        GWTIME_BITS     = %111
        GGAIN_MASK      = GCONF2_MASK ^ (GGAIN_BITS << GGAIN)
        GLDRIVE_MASK    = GCONF2_MASK ^ (GLDRIVE_BITS << GLDRIVE)
        GWTIME_MASK     = GCONF2_MASK ^ (GWTIME_BITS << GWTIME)

    GOFFSET_U           = $A4
    GOFFSET_D           = $A5

    GOFFSET_L           = $A7
    GOFFSET_R           = $A9

    GPULSECNT           = $A6
    GPULSECNT_MASK      = $FF
        GPLEN           = 6
        GPULSE          = 0
        GPLEN_BITS      = %11
        GPULSE_BITS     = %111111
        GPLEN_MASK      = GPULSECNT_MASK ^ (GPLEN_BITS << GPLEN)
        GPULSE_MASK     = GPULSECNT_MASK ^ (GPULSE_BITS << GPULSE)

    GCONF3              = $AA
    GCONF3_MASK         = $03
        GDIMS           = 0
        GDIMS_BITS      = %11

    GCONF4              = $AB
    GCONF4_MASK         = $07
        GFIFO_CLR       = 2
        GIEN            = 1
        GMODE           = 0
        GFIFO_CLR_MASK  = GCONF4_MASK ^ (1 << GFIFO_CLR)
        GIEN_MASK       = GCONF4_MASK ^ (1 << GIEN)
        GMODE_MASK      = GCONF4_MASK ^ (1 << GMODE)

    GFLVL               = $AE

    GSTATUS             = $AF
        GFOV            = 1
        GVALID          = 0

    IFORCE              = $E4                               ' Write any value
    PICLEAR             = $E5                               '
    CICLEAR             = $E6                               '
    AICLEAR             = $E7                               '

    GFIFO_U             = $FC
    GFIFO_D             = $FD
    GFIFO_L             = $FE
    GFIFO_R             = $FF


#ifndef __propeller2__
PUB Null
'' This is not a top-level object
#endif
