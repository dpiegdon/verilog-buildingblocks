/*
This file is part of verilog-buildingblocks,
by David R. Piegdon <dgit@piegdon.de>

verilog-buildingblocks is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

verilog-buildingblocks is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with verilog-buildingblocks.  If not, see <https://www.gnu.org/licenses/>.
*/

`default_nettype none

/* Debounced digital rotary encoder. (e.g. EC11)
 *
 * Expects inputs A and B of digital rotary encoder
 * and applies a pullup to these pins,
 * yields a clk-long flag on out_ccw (counter-clockwise)
 * or out_cw (clockwise) to indicate a single rotation step.
 */
module rotary_encoder_pullup(input wire clk, input wire in_a, input wire in_b, output wire out_ccw, output wire out_cw);
	parameter DEBOUNCE_CYCLES = 0;

	wire pin_value_a;
	wire pin_value_b;

	pullup_input input_pin_a(.pin(in_a), .value(pin_value_a));
	pullup_input input_pin_b(.pin(in_b), .value(pin_value_b));

	rotary_encoder #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES))
		encoder(clk, pin_value_a, pin_value_b, out_ccw, out_cw);

endmodule

