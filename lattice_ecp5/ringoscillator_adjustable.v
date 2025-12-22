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

`ifndef __vbb__lattice_ecp5__ringoscillator_adjustable_v__
`define __vbb__lattice_ecp5__ringoscillator_adjustable_v__

`default_nettype none

/* Adjustable ring oscillator.
 *
 * An on-the-fly adjustable version of above. The active delay can be chosen
 * from different taps. The higher the tap, the higher the delay.
 * When changing the tap:
 *  - take care to set @rst for at least one period,
 *     otherwise metastable states may be reached.
 *  - the output may glitch, i.e.:
 *    - no phase-correctness is guaranteed
 *    - no minimal period length is guaranteed
 *
 * Avoid using zero delay LUTs. Zero delay LUTs may be unstable
 * and also results in extremely high frequencies at very low amplitudes.
 */
module ringoscillator_adjustable(output wire chain_out, input [TAPWIDTH-1:0] tap, input rst);

	/* maximum number of selectable taps,
	 * i.e. the number of different delays that can be set.
	 * selectable will be 0 .. MAX_TAPS-1.
	 * must be >= 2 */
	parameter MAX_TAPS = 4;

	/* number of (untapped) delays before first tap. */
	parameter PREFIX_DELAYS = 5;

	/* number of (untapped) delays in-between each tap.
	 * must be >= 1. */
	parameter TAP_DELAYS = 4;

	/* the oscillator ring will look like this:
	 *
	 *                   /-------------------------------------------....
	 *  -----------------| tap-selector
	 *  |                \-------------------------------------------....
	 *  |                   |           |           |           |
	 *  |                   |           |           |           |
	 *  --!D-----D-D-D-D-D-----D-D-D-D-----D-D-D-D-----D-D-D-D-----D-....
	 *    ^ inverter        ^ tap0      ^ tap1      ^ tap2      ^ tap3
	 *                         ^ tap0-delay^ tap1-delay^ tap2-delay
	 *           ^ prefix-delay
	 */

	localparam TAPWIDTH = $clog2(MAX_TAPS-1)+1;

	localparam TOTAL_LUTS = 1 + PREFIX_DELAYS + (TAP_DELAYS) * (MAX_TAPS-1);

	generate
		if(MAX_TAPS < 2) begin : bad_max_taps
			$error("MAX_TAPS must be >= 2");
		end
		if(PREFIX_DELAYS < 0) begin : bad_prefix_delay
			$error("PREFIX_DELAYS must be >= 0");
		end
		if(TAP_DELAYS < 1) begin : bad_infix_delay
			$error("TAP_DELAYS must be >= 1");
		end
	endgenerate

	wire [TOTAL_LUTS+1:0] chain_wire;
	wire [MAX_TAPS-1:0] taps;
	assign chain_wire[0] = taps[tap];
	assign chain_out = chain_wire[0];

	generate /* luts */
		genvar i;
		for(i=0; i<TOTAL_LUTS; i=i+1) begin : create_delayline
			(* keep *) (* noglobal *)
			LUT4 #(.INIT((i==0)?16'd1:16'd2))
				chain_lut(.Z(chain_wire[i+1]),
					  .A(chain_wire[i]),
					  .B(rst),
					  .C(1'b0),
					  .D(1'b0));
		end
	endgenerate

	generate /* taps */
		genvar k;
		for(k = 0; k<MAX_TAPS; k=k+1) begin : create_taps
			assign taps[k] = chain_wire[1 + PREFIX_DELAYS + TAP_DELAYS * k];
		end
	endgenerate
endmodule

`endif // __vbb__lattice_ecp5__ringoscillator_adjustable_v__
