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

/* Clock Prescaler.
 *
 * Has the input clock at @out[0].
 * @out[n] toggles half as often as @out[n-1].
 * I.e. @clkout behaves like a counter counting up at the speed of @clkin.
 */
module clock_prescaler(input wire clkin, output wire [WIDTH-1:0] clkout, input wire reset);
	parameter WIDTH=8;

	reg [WIDTH-2:0] prescaler = 0;

	always @(negedge clkin) begin
		if(reset) begin
			prescaler <= 0;
		end else begin
			prescaler <= prescaler + 1;
		end
	end

	assign clkout = { prescaler, clkin };
endmodule

