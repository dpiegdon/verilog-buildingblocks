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

// Circuit generating a metastable output.
module metastable_oscillator(output wire metastable);
	wire s0, s1, s2, s3;

	ringoscillator r0(s0);
	ringoscillator r1(s1);
	ringoscillator r2(s2);
	ringoscillator r3(s3);

	(* keep *)
	LUT4 #(.INIT(16'b1010_1100_1110_0001))
		destabilizer (.Z(metastable), .A(s0), .B(s1), .C(s2), .D(s3));
endmodule

// Circuit generating an even more metastable output.
module metastable_oscillator_depth2(output wire metastable);
	wire s0, s1, s2, s3;

	metastable_oscillator r0(s0);
	metastable_oscillator r1(s1);
	metastable_oscillator r2(s2);
	metastable_oscillator r3(s3);

	(* keep *)
	LUT4 #(.INIT(16'b0101_0011_0001_1110))
		destabilizer (.Z(metastable), .A(s0), .B(s1), .C(s2), .D(s3));
endmodule

