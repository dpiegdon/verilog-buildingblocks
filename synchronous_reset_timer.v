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

// synchronize a reset signal to a clock, also stretch it to LENGTH clocks.
module synchronous_reset_timer(input wire clk, output wire reset_out, input wire reset_in);
	parameter LENGTH=7;

	reg [$clog2(LENGTH+1)-1:0] timer = LENGTH;
	assign reset_out = |timer;

	always @(posedge clk, posedge reset_in) begin
		if(reset_in) begin
			timer <= LENGTH;
		end else if(reset_out) begin
			timer <= timer - 1;
		end
	end

endmodule

