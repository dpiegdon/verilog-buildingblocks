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

/* Lattice iCE40 specific IO PAD implemenation.
 *
 * Full implementation of iCE40 specific muxable IO pad.
 * See ../io_pad.v for details. */
module io_pad_ice40(	output wire pin,				// actual IO-pin
			input  wire [MUXWIDTH-1:0] func_select,		// function selection
			input  wire [TXCOUNT-1:0]  func_transmit,	// func'wise demuxed value to transmit
			output wire [RXCOUNT-1:0]  func_receive);	// func'wise demuxed value received

	parameter TXCOUNT = 2;						// number of transmit functions to implement (higher bits)
	parameter RXCOUNT = 2;						// number of receive functions to implement (lower bits)

	localparam MUXWIDTH = $clog2(TXCOUNT + RXCOUNT);

	wire pin_enable;
	wire pin_output;
	wire pin_input;

	SB_IO #(
		.PIN_TYPE(6'b1010_01),	// unregistered output with enable pin, unregistered input
		.PULLUP(1'b0)
	) sb_io (
		.PACKAGE_PIN(pin),
		.OUTPUT_ENABLE(pin_enable),
		.D_OUT_0(pin_output),
		.D_IN_0(pin_input)
	);

	io_mux	#(.RXCOUNT(RXCOUNT), .TXCOUNT(TXCOUNT))
		mux(pin_enable, pin_output, pin_input, func_select, func_receive, func_transmit);
endmodule
