# apds9960-spin 
---------------

This is a P8X32A/Propeller, ~~P2X8C4M64P/Propeller 2~~ driver object for the APDS9960 Prox/Amb. light/RGB/Gesture sensor

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or ~~[p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P)~~. Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz
* Ambient light/RGB sensing (read C, R, G, B channels independently or all channels simultaneously)
* Set ALS/RGB sensor gain
* Set ALS/RGB sensor integration time
* ALS/RGB interrupt source (with persistence filter, and configurable lo/hi thresholds)
* Optional inter-measurement (ALS, prox.) low-power wait state with configurable time
* Proximity sensing
* Set Proximity sensor gain
* Set Proximity sensor integration time
* Proximity interrupt source (with persistence filter, and configurable lo/hi thresholds)
* Optional low-power sleep mode when an interrupt is asserted
* Set LED drive current (prox., gesture)

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C driver

~~P2/SPIN2:~~
* ~~p2-spin-standard-library~~

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* ~~P2/SPIN2: FastSpin (tested with 4.2.6-beta)~~ _(not currently implemented)_
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* No gesture sensing support (planned)
* ALS/Prox. wait timer doesn't support the wait long feature (multiply wait timer duration by x12)

## TODO

- [x] ALS/RGB sensing
- [ ] Long wait timer multiplier
- [x] Proximity sensing
- [ ] Gesture sensing
- [ ] Port to P2/SPIN2
