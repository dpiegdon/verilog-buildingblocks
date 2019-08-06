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

// Demultiplexer.
module demux(input wire enable, input wire [SELECTOR_WIDTH-1:0] selector, output wire [OUTPUT_WIDTH-1:0] out);
	parameter OUTPUT_WIDTH = 'd3;

	localparam SELECTOR_WIDTH = $clog2(OUTPUT_WIDTH);

	genvar i;
	generate
		for(i = 0; i < OUTPUT_WIDTH; i=i+1) begin
			assign out[i] = enable && (selector == i);
		end
	endgenerate
endmodule

