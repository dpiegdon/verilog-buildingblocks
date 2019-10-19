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

// Implements a generic linear feedback shift register that allows to shift
// additional random bits into the front to improve its randomness.
// The default parameters match to a fibonacci LFSR.
module lfsr(input wire clk, input wire random, output reg [WIDTH-1:0] shiftreg, input wire rst);

	parameter WIDTH = 'd16;
	parameter INIT_VALUE = 16'b1010_1100_1110_0001;
	parameter FEEDBACK = 16'b0000_0000_0010_1101;

	wire feedback;
	reg init_done = 0;

	assign feedback = random ^ (^(shiftreg & FEEDBACK));

	always @(posedge clk) begin
		if(rst || !init_done) begin
			shiftreg <= INIT_VALUE;
			init_done <= 1;
		end else begin
			shiftreg <= {feedback, shiftreg[WIDTH-1:1]};
		end
	end

endmodule

