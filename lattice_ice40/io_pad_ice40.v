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

`ifndef __vbb__lattice_ice40__io_pad_ice40_v__
`define __vbb__lattice_ice40__io_pad_ice40_v__

`default_nettype none

`include "../console.v"
`include "../io_mux.v"

/* Lattice iCE40 specific IO PAD implemenation.
 *
 * Full implementation of iCE40 specific muxable IO pad.
 * See ../io_pad.v for details on muxing and function selection. */
module io_pad_ice40(	output wire pin,				// actual IO-pin
			input  wire [MUXWIDTH-1:0] func_select,		// function selection
			input  wire [TXCOUNT-1:0]  func_transmit,	// func'wise demuxed value to transmit
			output wire [RXCOUNT-1:0]  func_receive);	// func'wise demuxed value received

	parameter TXCOUNT = 2;						// number of transmit functions to implement (higher bits); must be > 0
	parameter RXCOUNT = 2;						// number of receive  functions to implement (lower  bits); must be > 0

	generate
		if (TXCOUNT <= 0) begin : bad_tx_count
			`ERROR("Bad TXCOUNT");
		end
		if (RXCOUNT <= 0) begin : bad_rx_count
			`ERROR("Bad RXCOUNT");
		end
	endgenerate

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
		mux(pin_enable, pin_output, pin_input, func_select, func_transmit, func_receive);
endmodule

`endif // __vbb__lattice_ice40__io_pad_ice40_v__
