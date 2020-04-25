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

// Fully debounced digital rotary encoder (e.g. EC11)
module debounced_encoder(input wire clk, input wire in_a, input wire in_b, output wire out_ccw, output wire out_cw);
	parameter DEBOUNCE_CYCLES = 100;

	wire pin_value_a;
	wire pin_value_b;

	pullup_input input_pin_a(.pin(in_a), .value(pin_value_a));
	pullup_input input_pin_b(.pin(in_b), .value(pin_value_b));

	wire debounced_a;
	wire debounced_b;

	debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES))
		input_a_debouncer(.clk(clk), .in(pin_value_a), .out(debounced_a));

	debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES))
		input_b_debouncer(.clk(clk), .in(pin_value_b), .out(debounced_b));

	wire marker = !(debounced_a || debounced_b);
	reg previously_marker = 0;

	always @(negedge clk) begin
		previously_marker <= marker;
	end

	assign out_ccw = previously_marker && !marker && debounced_a;
	assign out_cw = previously_marker && !marker && debounced_b;
endmodule

