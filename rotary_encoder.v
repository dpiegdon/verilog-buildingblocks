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
 * Expects inputs A and B of digital rotary encoder (with external pullups)
 * and yields a clk-long flag on out_ccw (counter-clockwise)
 * or out_cw (clockwise) to indicate a single rotation step.
 */
module rotary_encoder(input wire clk, input wire in_a, input wire in_b, output wire out_ccw, output wire out_cw);
	parameter DEBOUNCE_CYCLES = 0;

	wire debounced_a;
	wire debounced_b;

	generate
		if(DEBOUNCE_CYCLES == 0) begin
			assign debounced_a = in_a;
			assign debounced_b = in_b;
		end else begin
			debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES))
				input_a_debouncer(.clk(clk), .in(in_a), .out_state(debounced_a), .out_edge());
			debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES))
				input_b_debouncer(.clk(clk), .in(in_b), .out_state(debounced_b), .out_edge());
		end
	endgenerate

	wire marker = !(debounced_a || debounced_b);
	reg previous_marker = 0;

	always @(posedge clk) begin
		previous_marker <= marker;
	end

	assign out_ccw = previous_marker && debounced_b;
	assign out_cw = previous_marker && debounced_a;
endmodule

