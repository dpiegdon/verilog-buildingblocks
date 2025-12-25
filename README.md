
Various verilog modules that I use or develop
=============================================

Contains
--------


| File                                           | Description                                                                                             |
|------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `binary_debias.v`                              | Module to XOR two bits in a bistream into one. Used to remove a binary debias in a random stream.       |
| `charlieplexer.v`                              | Generic charlieplexing module for N pins to control `N*(N-1)` LEDs.                                     |
| `charlieplex_display.v`                        | A generic addressable display that uses a charlieplexer.                                                |
| `clock_prescaler.v`                            | Simple clock prescaler implementation that also exposes the full prescaler counter.                     |
| `debouncer.v`                                  | Button debouncer.                                                                                       |
| `demux.v`                                      | Generic demultiplexer.                                                                                  |
| `lfsr.v`                                       | Generic linear feedback shift register (LFSR).                                                          |
| `randomized_spongent.v`                        | High quality entropy source using metastability fed into the spongent hash algorithm to whiten it.      |
| `randomized_lfsr.v`                            | Module to generate metastable output and random numbers.                                                |
| `randomized_lfsr_weak.v`                       | Module to generate weak metastable output and weak random numbers.                                      |
| `rotary_encoder.v`                             | Input decoder for debounced digital rotary encoders like the EC11.                                      |
| `simple_spi_master.v`                          | Simple SPI master implementation.                                                                       |
| `simple_spi_slave.v`                           | Simple SPI slave implementation.                                                                        |
| `spongent_hash.v`                              | Nibble-serial implementation of the Spongent hash algorithm.                                            |
| `synchronizer.v`                               | Cross-clockdomain signal synchronizer.                                                                  |
| `synchronous_reset_timer.v`                    | Module to synchronize a sync reset signal to a clock domain and hold it for a defined number of cycles. |
| `uart.v`                                       | UART module by Timothy Goddard with some changes by me to add high speed capability.                    |
| `lattice_ice40/`                               | Lattice iCE40 specific implementations                                                                  |
| `lattice_ice40/debounced_button.v`             | Debounced button from an input pin.                                                                     |
| `lattice_ice40/pullup_input.v`                 | Input with pullup.                                                                                      |
| `lattice_ice40/rotary_encoder_pullup.v`        | Pull-up implementation for rotary encoder input controller.                                             |
| `lattice_ice40/tristate_output.v`              | A tristateable output.                                                                                  |
| `lattice_ice40/metastable_oscillator.v`        | Circuit generating a metastable output.                                                                 |
| `lattice_ice40/metastable_oscillator_depth2.v` | Circuit generating an even more metastable output than `metastable_oscillator`.                         |
| `lattice_ice40/ringoscillator.v`               | Ring oscillator implementation.                                                                         |
| `lattice_ice40/ringoscillator_adjustable.v`    | Adjustable ring oscillator implementation.                                                              |
| `lattice_ecp5/`                                | Lattice ECP5 specific implementations                                                                   |
| `lattice_ecp5/metastable_oscillator.v`         | Circuit generating a metastable output.                                                                 |
| `lattice_ecp5/metastable_oscillator_depth2.v`  | Circuit generating an even more metastable output than `metastable_oscillator`.                         |
| `lattice_ecp5/ringoscillator.v`                | Ring oscillator implementation.                                                                         |
| `lattice_ecp5/ringoscillator_adjustable.v`     | Adjustable ring oscillator implementation.                                                              |

Contains also testbenches (`*_tb.v`) for many of the modules, see below.

Note: most of the implementation-specific modules should be easily adaptable to other platforms.


Testbenches
-----------

Many of the modules have a testbench (`*_tb.v`). Testbenches are
optimizes for use with the Icarus Verilog compiler. To run all tests,
just run `make`. The build is successfull if and only if all testbenches
were able to build and succeeded.


Authors/Contributors
--------------------

* David R. Piegdon <dgit@piegdon.de> -> https://github.com/dpiegdon

* Timothy Goddard <tim@goddard.net.nz> (Author `uart.v`)

* Arnaud Durand <arnaud.durand@unifr.ch> (Contributor `ringoscillator.v`) -> https://github.com/DurandA

* David A. Roberts <d@vidr.cc> (Contributor `lattice_ecp5/random.v`, `lattice_ecp5/ringoscillator.v`) -> https://github.com/davidar


Licensing
---------

License exceptions:

* `uart.v` -- MIT license, see header of file.

All OTHER contained files are licensed under the LGPL v3.0, see LICENSE.txt .
That means that you may use the provided verilog modules in a proprietary
software without publishing your proprietary code.
But you must publish any changes that you did to the provided verilog modules.

I suggest that you include this repository as a submodule.
That way you can easily publish any changes separately from your own code.
