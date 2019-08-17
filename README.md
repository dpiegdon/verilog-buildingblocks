
Various verilog modules that I use or develop
=============================================

Contains
--------

* `binary_debias.v`
  Module to XOR two bits in a bistream into one. Used to remove a binary debias in a random stream.

* `charlieplexer.v`
  Generic charlieplexing module for N pins to control N*(N-1) LEDs.

* `debouncer.v`
  Button debouncer.

* `demux.v`
  Generic demultiplexer.

* `lfsr.v`
  Generic linear feedback shift register (LFSR).

* `random.v`
  Modules to generate metastable output and random numbers.

* `synchronous_reset_timer.v`
  Module to synchronize an sync reset signal to a clock domain and hold it for a defined number of clock cycles.

* `uart.v`
  UART module by Timothy Goddard that can be found in various places on the internet, with some changes by me to add high speed capability.

* Lattice iCE40 specific implementations (in `lattice_ice40/`)

 - `lattice_ice40/debounced_button.v`
  Debounced button from an input pin.

 - `lattice_ice40/pullup_input.v`
  Input with pullup.

 - `lattice_ice40/random.v`
  Modules for random number generation.
  
 - `lattice_ice40/ringoscillator.v`
  Ring oscillator implementation.

 - `lattice_ice40/tristate_output.v`
  A tristateable output.


Contains also testbenches (`*_tb.v`) for some of the modules, see below.

Note: most of the implementation-specific modules should be easily adaptable to other platforms.


Testbenches
-----------

Some of the modules have a testbench (`*_tb.v`). Testbenches are
optimizes for use with the Icarus Verilog compiler. To run all tests,
just run `make`. The build is successfull if and only if all testbenches
were able to build and succeeded.


Authors
-------

All files except `uart.v`:

* David R. Piegdon <dgit@piegdon.de>

`uart.v`:

* Timothy Goddard <tim@goddard.net.nz>

* David R. Piegdon <dgit@piegdon.de>


Licensing
---------

License exceptions:

`uart.v` -- MIT license, see header of file.

All OTHER contained files are licensed under the LGPL v3.0, see LICENSE.txt .
That means that you may use the provided verilog modules in a proprietary
software without publishing your proprietary code.
But you must publish any changes that you did to the provided verilog modules.

I suggest that you include this repository as a submodule.
That way you can easily publish any changes separately from your own code.

