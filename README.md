
Various verilog modules that I use or develop
=============================================

Contains
--------

* `charlieplexer.v`
  Generic charlieplexing module for N pins to control N*(N-1) LEDs.

* `debouncer.v`
  Button debouncer.

* `demux.v`
  Generic demultiplexer.

* `lattice_debounced_button.v`
  Lattice-specific implementation of a proper debounced button from an input pin.

* `lattice_pullup_input.v`
  Lattice-specific implementation of an input with pullup.

* `lattice_tristate_output.v`
  Lattice-specific implementation of a tristateable output.

* `lfsr.v`
  Generic linear feedback shift register (LFSR).

* `random.v`
  Mostly lattice-specific code to generate random numbers from metastability.

* `ringoscillator.v`
  Lattice-specific ring oscillator implementation.
  
* `synchronous_reset_timer.v`
  Module to synchronize an sync reset signal to a clock domain and hold it for a defined number of clock cycles.

* `uart.v`
  UART module by Timothy Goddard that can be found in various places on the internet, with some changes by me to add high speed capability.

Contains also testbenches (`*_tb.v`) for some of these modules.

Note: most of the implementation-specific modules should be easily adaptable to other platforms.


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

