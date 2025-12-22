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

`ifndef __vbb__lattice_ice40__metastable_oscillator_depth2_v__
`define __vbb__lattice_ice40__metastable_oscillator_depth2_v__

`default_nettype none

`include "metastable_oscillator.v"

// Circuit generating an even more metastable output than
// metastable_oscillator.
module metastable_oscillator_depth2(output wire metastable);
	wire s0, s1, s2, s3;

	metastable_oscillator r0(s0);
	metastable_oscillator r1(s1);
	metastable_oscillator r2(s2);
	metastable_oscillator r3(s3);

	(* keep *)
	SB_LUT4 #(.LUT_INIT(16'b0101_0011_0001_1110))
		destabilizer (.O(metastable), .I0(s0), .I1(s1), .I2(s2), .I3(s3));
endmodule

`endif // __vbb__lattice_ice40__metastable_oscillator_depth2_v__
