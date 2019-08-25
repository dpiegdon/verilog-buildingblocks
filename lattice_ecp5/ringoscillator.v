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
//
// Avoid using zero delay LUTs. Zero delay LUTs may be unstable
// and also results in extremely high frequencies at very low amplitudes.
// E.g. on the ice40hx1k, this results in a ~650MHz signal,
// but so weak that other logic will not properly pick it up.
// When connecting it to an output pin, the signal has -25dBm.
module ringoscillator(output wire chain_out);
	parameter DELAY_LUTS = 1;

	wire chain_wire[DELAY_LUTS+1:0];
	assign chain_wire[0] = chain_wire[DELAY_LUTS+1];
	assign chain_out = chain_wire[1];
	// inverter is at [0], so [1] comes freshly from the inverter.
	// if that matters.

	generate
		genvar i;
		for(i=0; i<=DELAY_LUTS; i=i+1) begin: delayline
			(* keep *) (* noglobal *)
			TRELLIS_SLICE #(.LUT0_INITVAL((i==0)?16'd1:16'd2))
				chain_lut(.F0(chain_wire[i+1]), .A0(chain_wire[i]), .B0(0), .C0(0), .D0(0));
		end
	endgenerate
	
endmodule

