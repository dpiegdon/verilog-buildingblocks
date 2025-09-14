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

/* Nibble-serial Spongent hash implementation.
 *
 * Spongent is a family of lightweight cryptographic hash functions designed for
 * constrained hardware.
 * 
 * It combines a simple sponge construction with a PRESENT-style permutation:
 * each round 
 * - XORs in a round constant (lCounter)
 * - applies a fixed 4-bit S-box to every nibble of the state (sBoxLayer)
 * - and permutes the bits with a deterministic shuffle (pLayer)
 * 
 * Different variants (e.g. Spongent-88, Spongent-128) trade off state size,
 * security margin, and number of rounds, but all share the same structure. The
 * design is compact enough to fit into very small FPGAs or ASICs, yet provides
 * cryptographic-grade diffusion and nonlinearity suitable for tasks like
 * entropy whitening, lightweight authentication, or low-end integrity checks.
 *
 * Reference documentation:
 * - Spongent: The Design Space of Lightweight Cryptographic Hashing.
 *   By A. Bogdanov, M. Knežević, G. Leander, D. Toz, K. Varıcı, I. Verbauwhede.
 *   In CHES 2011: Cryptographic Hardware and Embedded Systems – CHES 2011, LNCS 6917, pp. 145–162.
 *   Springer, 2011.
 *
 * - Spongent: The Design Space of Lightweight Cryptographic Hashing.
 *   By A. Bogdanov, M. Knežević, G. Leander, D. Toz, K. Varıcı, I. Verbauwhede.
 *
 * Reference implementations:
 * - https://github.com/joostrijneveld/readable-crypto/blob/master/hashfunctions/SPONGENT.py
 * - https://github.com/ehsanaerabi/HashFunctions/blob/master/Spongent/SourceCode/Spongent.h
 * - https://github.com/ehsanaerabi/HashFunctions/blob/master/Spongent/SourceCode/Spongent.cpp
 */
module spongent_hash(
			input  wire clk,		// system clock
			input  wire rst,		// reset full state
			input  wire [RATE-1:0] in,	// chunk of input data
			input  wire in_valid,		// input chunk is valid?
			input  wire in_completed,	// all input data was completely absorbed? I.e. transition to output mode?
			output reg  in_received = 0,	// input chunk was received?
			output wire [RATE-1:0] out,	// chunk of output data
			output reg  out_valid = 0,	// output chunk is valid?
			output reg  out_completed = 0,  // output hash fully received?
			input  wire out_received        // output chunk was received?
		);
	parameter HASHSIZE = 88; 			// `n` in paper
	parameter CAPACITY = 80; 			// `c` in paper
	parameter RATE = 8; 				// `r` in paper
	parameter ROUNDS = 45; 				// `R` in paper
	parameter LCOUNTER_FEEDBACK = 'b110000;		// Feedback definition of the lCounter LFSR.
	parameter LCOUNTER_INIT = 'b000101;		// Initial value of the lCounter LFSR.
	parameter FIX_BYTE_ORDER = 1;			// inverse byteorder of input and output, so that the verilog-expected way of passing bits matches the software implementation.

	localparam STATESIZE = CAPACITY + RATE;		// `b`
	localparam STATEMIDDLE = (((STATESIZE/2)/4)*4); // nibble-aligned middle of state
	localparam NIBBLES = STATESIZE / 4;		// statesize in nibbles (half bytes)
	localparam OUTPUT_CHUNKS = HASHSIZE / RATE;	// number of rate-sized chunks the total hash consists off

	generate
		if (       (HASHSIZE == 0) 
			|| (CAPACITY <= 1)
			|| (RATE <= 1)
			|| (ROUNDS == 0)
			|| (LCOUNTER_FEEDBACK == 0)
			|| (LCOUNTER_INIT == 0)) begin : invalid_parameters
			/* raise an error for invalid/uninitialized parameters */
			INVALID_OR_UNINITIALIZED_PARAMETERS not_a_real_instance();
		end
	endgenerate

	reg [STATESIZE-1:0] state = 0;			// internal state
	wire [STATESIZE-1:0] state_nibbleshifted = { state[STATESIZE-1-4 : 0], state[STATESIZE-1 : STATESIZE-1-3] };

	/* i/o with more than 1 byte is expected in reverse byte order */
	wire [RATE-1:0] in_byteorder_fixed;
	wire [RATE-1:0] out_byteorder_fixed;
	generate
		genvar cbyte;
		for (cbyte = 0; cbyte < RATE/8; cbyte = cbyte+1) begin
			if (FIX_BYTE_ORDER) begin : use_inverse_byteorder
				assign in_byteorder_fixed[cbyte*8 + 7 : cbyte*8 + 0] = in[RATE-1 - cbyte*8 : RATE-1 - cbyte*8 - 7];
				assign out[cbyte*8 + 7 : cbyte*8 + 0] = out_byteorder_fixed[RATE-1 - cbyte*8 : RATE-1 - cbyte*8 - 7];
			end else begin : use_naive_byteorder
				assign in_byteorder_fixed = in;
				assign out = out_byteorder_fixed;
			end
		end
	endgenerate

	/* injection: lCounter definitions */
	localparam LCOUNTER_SIZE = $clog2(ROUNDS);	// size of the lCounter LFSR
	wire [LCOUNTER_SIZE-1:0] lCounter;
	wire [LCOUNTER_SIZE-1:0] retnuoCl;
	generate
		genvar lcbit;
		for (lcbit = 0; lcbit < LCOUNTER_SIZE; lcbit=lcbit+1) begin
			assign retnuoCl[lcbit] = lCounter[LCOUNTER_SIZE-1-lcbit];
		end
	endgenerate
	wire [STATESIZE-1:0] lCounter_outstate;		// output of the lCounter step
	reg lCounter_clk = 0;				// clock for the LFSR
	reg lCounter_rst = 0;				// reset for the LFSR
	lfsr  #(.WIDTH(LCOUNTER_SIZE),
		.INIT_VALUE(LCOUNTER_INIT),
		.FEEDBACK(LCOUNTER_FEEDBACK),
		.INVERSE(1))
		lCounter_lfsr(  .clk(lCounter_clk),
				.random(1'b0),
				.shiftreg(lCounter),
				.rst(lCounter_rst));
	assign lCounter_outstate = {
					/* verilator lint_off SELRANGE */
					state[STATESIZE-1               : STATESIZE-LCOUNTER_SIZE]   	^ retnuoCl, // <-- inverse order is per spec.
					/* verilator lint_on SELRANGE */
					state[STATESIZE-LCOUNTER_SIZE-1 : LCOUNTER_SIZE],
					state[LCOUNTER_SIZE-1           : 0]                       	^ lCounter
				};

	/* substitution: sBox definitions */
	reg [$clog2(NIBBLES)-1:0] sBoxNibblesLeft = 0;
	function [3:0] sBoxLayer;
		input [3:0] sBoxIn;
		begin
			case (sBoxIn)
				4'h0: sBoxLayer = 4'he;
				4'h1: sBoxLayer = 4'hd;
				4'h2: sBoxLayer = 4'hb;
				4'h3: sBoxLayer = 4'h0;
				4'h4: sBoxLayer = 4'h2;
				4'h5: sBoxLayer = 4'h1;
				4'h6: sBoxLayer = 4'h4;
				4'h7: sBoxLayer = 4'hf;
				4'h8: sBoxLayer = 4'h7;
				4'h9: sBoxLayer = 4'ha;
				4'ha: sBoxLayer = 4'h8;
				4'hb: sBoxLayer = 4'h5;
				4'hc: sBoxLayer = 4'h9;
				4'hd: sBoxLayer = 4'hc;
				4'he: sBoxLayer = 4'h3;
				4'hf: sBoxLayer = 4'h6;
			endcase
		end
	endfunction

	/* permutation: pLayer definitions */
	wire [STATESIZE-1:0] pLayer;
	assign pLayer[STATESIZE-1] = state[STATESIZE-1];
	generate
		genvar plbit;
		for(plbit = 0; plbit < STATESIZE-1; plbit=plbit+1) begin
			assign pLayer[(plbit * (STATESIZE/4)) % (STATESIZE-1)] = state[plbit];
		end
	endgenerate

	/* main logic */
	reg [$clog2(ROUNDS)-1:0] rounds_left;		// # of rounds to be done
	localparam MODE_INPUT            = 0;
	localparam MODE_RELEASE_LFSR     = 1;
	localparam MODE_PREPARE_ROUNDS = 2;
	localparam MODE_INJECTION        = 3;
	localparam MODE_SUBSTITUTE       = 4;
	localparam MODE_PERMUTE          = 5;
	localparam MODE_OUTPUT           = 6;
	reg [2:0] mode = MODE_INPUT;			// current mode
	reg squeezing = 0;				// are we in the absorbing- or squeezing-phase?

	assign out_byteorder_fixed = state[RATE-1:0];

	reg [$clog2(OUTPUT_CHUNKS-1)-1:0] out_remaining = 0;

	always @(posedge clk) begin
		if (rst) begin
			in_received     <= 0;
			out_valid       <= 0;
			out_completed   <= 0;
			state           <= 0;
			sBoxNibblesLeft <= 0;
			lCounter_rst    <= 0;
			lCounter_clk    <= 0;
			rounds_left     <= 0;
			mode            <= MODE_INPUT;
			squeezing       <= 0;
			out_remaining   <= 0;
		end else case (mode)
			MODE_INPUT: begin
				lCounter_rst <= 1;
				if (in_valid) begin
					state[RATE-1:0] <= state[RATE-1:0] ^ in_byteorder_fixed;
					in_received <= 1;
					mode <= MODE_RELEASE_LFSR;
				end
			end

			MODE_RELEASE_LFSR: begin
				lCounter_clk <= 1;
				in_received <= 0;
				mode <= MODE_PREPARE_ROUNDS;
			end

			MODE_PREPARE_ROUNDS: begin
				lCounter_rst <= 0;
				lCounter_clk <= 0;
				mode <= MODE_INJECTION;
				rounds_left <= ROUNDS-1;
			end

			MODE_INJECTION: begin
				state <= lCounter_outstate;
				lCounter_clk <= 1;
				mode <= MODE_SUBSTITUTE;
				sBoxNibblesLeft <= NIBBLES[$clog2(NIBBLES)-1:0] - 1;
			end

			MODE_SUBSTITUTE: begin
				lCounter_clk <= 0;
				// applying the sBox to the middle nibble
				// because the LUTs at start/end of state
				// already have extra logic due to lCounter.
				state <= {
								state_nibbleshifted[STATESIZE-1 : STATEMIDDLE+4],
						sBoxLayer(	state_nibbleshifted[STATEMIDDLE+3 : STATEMIDDLE]	),
								state_nibbleshifted[STATEMIDDLE-1 : 0]
					};
				if (sBoxNibblesLeft != 0) begin
					sBoxNibblesLeft <= sBoxNibblesLeft - 1;
				end else begin
					mode <= MODE_PERMUTE;
				end
			end

			MODE_PERMUTE: begin
				state <= pLayer;
				if (rounds_left != 0) begin
					rounds_left <= rounds_left-1;
					mode <= MODE_INJECTION;
				end else begin
					if (squeezing || in_completed) begin
						if (!squeezing) begin
							out_remaining <= OUTPUT_CHUNKS[$clog2(OUTPUT_CHUNKS-1)-1:0] - 1;
						end else begin
							out_remaining <= out_remaining - 1;
						end
						squeezing <= 1;
						mode <= MODE_OUTPUT;
						out_valid <= 1;
					end else begin
						mode <= MODE_INPUT;
					end
				end
			end

			MODE_OUTPUT: begin
				lCounter_rst <= 1;
				lCounter_clk <= 1;
				if (out_received) begin
					out_valid <= 0;
					if (out_remaining != 0) begin
						mode <= MODE_RELEASE_LFSR;
					end else begin
						out_completed <= 1;
					end
				end
			end
		endcase
	end
endmodule
