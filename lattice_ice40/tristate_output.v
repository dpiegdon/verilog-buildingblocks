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

// Implementation of tristateable output.
module tristate_output(input pin, input wire enable, input wire value);
	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b0),
	) sb_io (
		.PACKAGE_PIN(pin),
		.OUTPUT_ENABLE(enable),
		.D_OUT_0(value),
	);
endmodule

