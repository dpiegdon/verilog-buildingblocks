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

/* Generic IO function multiplexer.
 *
 * Implementation of an IO mux for multiple different inputs and outputs.
 * This the mux for an IO pad that can be used for different functions.
 * Actual I/O is hardware dependent and needs to be wrapped around this
 * with the signals pin_*. See lattice_ice40/io_pad_ice40.v for an example.
 *
 * - A configurable number of outputs and inputs (TXCOUNT, RXCOUNT -- at least one of each) is selectable.
 * - Functions are counted from the right.
 * - Receive-functions are right-most, output functions are left-most.
 * - To select a function, write its index (from the right) into func_select.
 * - Writing an invalid index (i.e. too large) into the func_select register results in undefined behaviour.
 */
module io_mux(	output wire pin_enable,				// IO-pin connection: enable output setting
		output wire pin_output,				// IO-pin connection: output value to send
		input  wire pin_input,				// IO-pin connection: input value received
		input  wire [MUXWIDTH-1:0] func_select,		// function selection
		input  wire [TXCOUNT-1:0]  func_transmit,	// func'wise demuxed value to transmit
		output wire [RXCOUNT-1:0]  func_receive);	// func'wise demuxed value received

	parameter TXCOUNT = 2;					// number of transmit functions to implement (higher bits)
	parameter RXCOUNT = 2;					// number of receive functions to implement (lower bits)

	localparam MUXWIDTH = $clog2(TXCOUNT + RXCOUNT);

	wire [RXCOUNT-1:0] select_rx;
	wire [TXCOUNT-1:0] select_tx;
	assign {select_tx, select_rx} = (1 << func_select);

	assign pin_enable = |select_tx;
	assign pin_output = |(func_transmit & select_tx);
	assign func_receive = pin_input ? select_rx : 0;
endmodule
