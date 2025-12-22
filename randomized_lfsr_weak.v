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

`ifndef __vbb__randomized_lfsr_weak_v__
`define __vbb__randomized_lfsr_weak_v__

`default_nettype none

`include "lfsr.v"
// NOTE: you need to pick/provide metastable_oscillator and
// metastable_oscillator_depth2 matching your FPGA architecture.

// Like the randomized_lfsr, this generates random numbers.
// But where randomized_lfsr tries to maximize entropy of
// produced random numbers for the given input data and constraints,
// the randomized_lfsr_weak tries to be very
// small while still producing an acceptable amount of entropy
// for jobs that don't depend on too much entropy.
module randomized_lfsr_weak(input wire clk, input wire rst, output wire [WIDTH-1:0] out, output wire metastable);
	parameter WIDTH = 'd8;
	parameter INIT_VALUE = 8'b1100_1010;
	parameter FEEDBACK = 8'b0001_1101;

	wire random;
	metastable_oscillator osci(metastable);
	lfsr #(.WIDTH(WIDTH), .INIT_VALUE(INIT_VALUE), .FEEDBACK(FEEDBACK)) shiftreg(clk, metastable, out, rst);
endmodule

`endif // __vbb__randomized_lfsr_weak_v__
