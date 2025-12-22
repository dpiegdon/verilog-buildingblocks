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

`ifndef __vbb__randomized_spongent_v__
`define __vbb__randomized_spongent_v__

`default_nettype none

`include "spongent_hash.v"

/* Randomness source from a metastable data stream fed through the spongent hashing algorithm to whiten the entropy.
 *
 * This should be a comparably secure source of randomness, especially since a lot
 * of randomness is merged into each input bit due to the slowness of spongent.
 */
module randomized_spongent(input wire clk, input wire rst, output wire [RATE-1:0] out, output wire out_valid, input wire out_received, output wire metastable);
	parameter HASHSIZE = 88; 			// `n` in paper
	parameter CAPACITY = 80; 			// `c` in paper
	parameter RATE = 8; 				// `r` in paper
	parameter ROUNDS = 45; 				// `R` in paper
	parameter LCOUNTER_FEEDBACK = 'b110000;		// Feedback definition of the lCounter LFSR.
	parameter LCOUNTER_INIT = 'h5;			// Initial value of the lCounter LFSR.
	parameter SBOX_DOUBLETIME = 0;			// use two sbox (8-bit serial) instead of one (4-bit serial)?
	parameter NOISE_DOUBLETIME = 0;			// use two noise-sources and XOR them together?

	localparam SQUEEZE_AFTER = CAPACITY + RATE + 2;	// we can safely squeeze after inputting a single full state,
							// since our input already has plenty of entropy merged into each bit.
							// but since the first byte we absorb is always 8'h0, we add two more.

	reg [3:0] rng_input = 0;	// shift through a few FFs to get rid of metastable state before actually using it

`ifdef TESTBENCH
	// for testbench we need to avoid using platform-specific metastable_oscillator_depth2()
	reg fake_entropy = 0;
	always @(posedge clk) begin
		fake_entropy <= !fake_entropy;
	end
	assign metastable = fake_entropy ^ NOISE_DOUBLETIME;  // only using NOISE_DOUBLETIME here so compiler doesn't complain about unused param.
`else
	generate
		if (NOISE_DOUBLETIME) begin : double_noise
			wire metastable1;
			wire metastable2;
			metastable_oscillator_depth2 osci1(metastable1);
			metastable_oscillator_depth2 osci2(metastable2);
			assign metastable = metastable1 ^ metastable2;
		end else begin : single_noise
			metastable_oscillator_depth2 osci(metastable);
		end
	endgenerate
`endif

	reg [RATE-1:0] in = 0;		// input for the hash and scratchpad for entropy
	reg in_valid = 0;
	wire in_completed;
	wire in_received;
	wire out_completed;
	reg reset_hash = 1;
	reg [$clog2(SQUEEZE_AFTER)-1:0] needed_input = SQUEEZE_AFTER;
	
	wire merged_reset = rst | reset_hash;

	wire state_reset  = reset_hash;
	wire state_squeeze= !reset_hash && (needed_input == 0);

	spongent_hash #(	.HASHSIZE(HASHSIZE),
				.CAPACITY(CAPACITY),
				.RATE(RATE),
				.ROUNDS(ROUNDS),
				.LCOUNTER_FEEDBACK(LCOUNTER_FEEDBACK),
				.LCOUNTER_INIT(LCOUNTER_INIT),
				.SBOX_DOUBLETIME(SBOX_DOUBLETIME))
			hash(	clk, merged_reset,
				in, in_valid, in_completed, in_received,
				out, out_valid, out_completed, out_received);
	assign in_completed = state_squeeze;

	always @(posedge clk) begin
		if (rst) begin
			rng_input <= 0;
			in <= 0;
			in_valid <= 0;
			reset_hash <= 1;
		end else begin
			// shift metastable input through a few FFs to get rid of metastable state before actually using it
			rng_input <= {rng_input[2:0], metastable};
			// then shuffle it into the accumulator to be fed into the sponge, or reset it after it was fed into the sponge.
			in <= (in_received 	? {7'b0,    rng_input[3]}
						: {in[6:0], in[7] ^ rng_input[3]});

			/* reset phase */
			if (state_reset) begin
				reset_hash <= 0;
				needed_input <= SQUEEZE_AFTER;
			end

			/* absorb phase -- statemachine is driven via state_squeeze. */
			if (in_received) begin
				in_valid <= 0;
				needed_input <= needed_input - 1;
			end else begin
				in_valid <= (needed_input != 0);
			end

			/* squeeze phase -- statemachine is driven from the outside via out_completed and out_received. */
			if (out_completed) begin
				reset_hash <= 1;
			end
		end
	end
endmodule

`endif // __vbb__randomized_spongent_v__
