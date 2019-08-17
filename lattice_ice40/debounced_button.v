/*
This file is part of verilog-buildingblocks,
by David R. Piegdon <dgit@piegdon.de>

verilog-buildingblocks is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

verilog-buildingblocks is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with verilog-buildingblocks.  If not, see <https://www.gnu.org/licenses/>.
*/

`default_nettype none

// Fully debounced button with an internal pull-up.
// Connect a switch to the pin that pulls it to GND when pressed.
module debounced_button(input wire clk, input wire in, output wire out);
	parameter DEBOUNCE_CYCLES = 100;
	parameter CLOCKED_EDGE_OUT = 0;

	wire pin_value;

	pullup_input input_pin(.pin(in), .value(pin_value));

	debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES),
		.CLOCKED_EDGE_OUT(CLOCKED_EDGE_OUT))
		input_debouncer(.clk(clk), .in(pin_value), .out(out));
endmodule

