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

// Ring oscillator.
// Lattice ice40 specific.
// May also work for ecp5 when `defining sb_lut4 to lut4.
module ringoscillator(output wire out);

	wire chain_in, chain_out;

	assign out = chain_out;

	// Single inverter of oscillator.
	assign chain_in = !chain_out;

	// Single LUT delay line. This also takes care that the compiler
	// (yosys) is not removing this logic path.
	(* keep *)
	SB_LUT4 #(
		.LUT_INIT(16'd2)
	) buffers (
		.O(chain_out),
		.I0(chain_in),
		.I1(1'b0),
		.I2(1'b0),
		.I3(1'b0)
	);

endmodule

// Ring oscillator with minimal delay.
// Lattice ice40 specific.
// May also work for ecp5 when `defining sb_lut4 to lut4.
//
// In contrast to the above ringoscillator, this uses a single LUT
// for inversion, without any extra delay.
// This results in the output signal is running at roughly 625MHz,
// but so weak that other logic might not properly pick it up.
// E.g. when connecting it to an output pin, the signal has -25dBmu (~36mVpp).
// So if in doubt use the above ringoscillator.
module ringoscillator_minimal_delay(output wire out);

	// Single LUT delay line. This also takes care that the compiler
	// (yosys) is not removing this logic path.
	(* keep *)
	SB_LUT4 #(
		.LUT_INIT(16'd1)
	) buffers (
		.O(out),
		.I0(out),
		.I1(0),
		.I2(0),
		.I3(0)
	);

endmodule

