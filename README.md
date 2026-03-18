# apds9960-spin 
---------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the APDS9960 Prox/Amb. light/RGB/Gesture sensor

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at ~30kHz (P1: SPIN I2C) up to 400kHz (P1: PASM I2C, P2)
* Ambient light/RGB sensing (read C, R, G, B channels independently or all channels simultaneously)
* Set ALS/RGB sensor gain
* Set ALS/RGB sensor integration time
* ALS/RGB interrupt source (with persistence filter, and configurable lo/hi thresholds)
* Optional inter-measurement (ALS, prox., gesture) low-power wait state with configurable time
* Proximity sensing
* Set Proximity sensor gain (prox., gesture)
* Set Proximity sensor integration time
* Proximity interrupt source (with persistence filter, and configurable lo/hi thresholds)
* Optional low-power sleep mode when an interrupt is asserted
* Set LED drive current (prox., gesture)
* Gesture sensing (read U, R, D, L channels independently or all channels simultaneously)
* Gesture interrupt source (with configurable threshold)


## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C engine (none if SPIN I2C engine is used)

P2/SPIN2:
* p2-spin-standard-library


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (7.6.4)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (7.6.4)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (7.6.4)       | NuCode       | OK                    |
| P2        | SPIN2    | FlexSpin (7.6.4)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Limitations

* ALS/Prox. wait timer doesn't support the wait long feature (multiply wait timer duration by x12)

