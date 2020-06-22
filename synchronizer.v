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

/* Synchronizes a signal to a clockdomain using a shift register.
 * Also provides signals @rising_edge and @falling_edge exactly timed to @out.
 * @out was at least shifted through one FF (if EXTRA_DEPTH=0), but the
 * amount can be increased by increasing EXTRA_DEPTH. */
module synchronizer(input wire clk, input wire in, output wire out, output wire rising_edge, output wire falling_edge);

	parameter EXTRA_DEPTH = 1;
	parameter START_HISTORY = 0;

	reg [2 + EXTRA_DEPTH : 0] history = START_HISTORY;
	// NOTE that [max] is input, [1] is present and [0] lies in the past.

	assign out = history[1];
	assign rising_edge  = (history[1:0] == 2'b10);
	assign falling_edge = (history[1:0] == 2'b01);

	always @(posedge clk) begin
		history <= { in, history[2+EXTRA_DEPTH : 1] };
	end
endmodule

