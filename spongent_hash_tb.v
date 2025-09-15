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
`timescale 1ns / 1ps

module spongent_hash_specific_tb(output reg finished,
				 output reg [15:0] errors,
				 input wire [HASHSIZE-1:0] expected_result);
	parameter HASHSIZE = 88; 			// `n` in paper
	parameter CAPACITY = 80; 			// `c` in paper
	parameter RATE = 8; 				// `r` in paper
	parameter ROUNDS = 45; 				// `R` in paper
	parameter LCOUNTER_FEEDBACK = 'b110000;		// Feedback definition of the lCounter LFSR.
	parameter LCOUNTER_INIT = 'h5;			// Initial value of the lCounter LFSR.

	localparam input_length = 27*8;
	localparam input_message = "Sponge + Present = Spongent";

	reg [input_length-1 : 0] hash_input;

	integer input_index = 0;
	reg [HASHSIZE-1:0] hash_result = 23;
	integer result_index = 0;

	reg clk;
	reg rst;
	reg [RATE-1:0] in;
	reg in_valid;
	reg in_completed;
	wire in_received;
	wire [RATE-1:0] out;
	wire out_valid;
	wire out_completed;
	reg out_received;
	reg [RATE-1:0] padding;

	integer cyclecount;

	spongent_hash #(.HASHSIZE(HASHSIZE),
			.CAPACITY(CAPACITY),
			.RATE(RATE),
			.ROUNDS(ROUNDS),
			.LCOUNTER_FEEDBACK(LCOUNTER_FEEDBACK),
			.LCOUNTER_INIT(LCOUNTER_INIT))
		hash(	.clk(clk),
			.rst(rst),
			.in(in),
			.in_valid(in_valid),
			.in_completed(in_completed),
			.in_received(in_received),
			.out(out),
			.out_valid(out_valid),
			.out_completed(out_completed),
			.out_received(out_received));

	task automatic cycle;
		begin
			clk = 1;
			#1;
			clk = 0;
			#1;
		end
	endtask

	integer reset_count;
	integer test_for_resets;

	task automatic identify;
		begin
			$error("for HASHSIZE %d, CAPACITY %d, RATE %d, ROUNDS %d, LCOUNTER_FEEDBACK %d, LCOUNTER_INIT %d, reset_count %d:",
				HASHSIZE, CAPACITY, RATE, ROUNDS, LCOUNTER_FEEDBACK, LCOUNTER_INIT, reset_count);
		end
	endtask

	initial begin
		if (HASHSIZE==88) begin
			// test that reset also works (just for a smaller hash,
			// so that the test doesn't take forever)
			test_for_resets = 2;
		end else begin
			test_for_resets = 1;
		end

		for (reset_count = 0; reset_count < test_for_resets; reset_count = reset_count+1) begin
			rst = 1;

			hash_input = input_message;
			hash_result = 23 + reset_count;
			result_index = 0;
			in = 0;
			in_valid = 0;
			in_completed = 0;
			out_received = 0;
			padding = 1 << (RATE-1);

			cycle;
			rst = 0;
			cycle;

			if (in_received || out_valid || out_completed) begin
				identify;
				$error("unexpected state in_received %b out_valid %b", in_received, out_valid);
				errors = errors + 1;
			end

			/* absorbing phase */
			for (input_index = input_length-1+8; input_index > 0; input_index = input_index-RATE) begin
				//                       ^^ +8 to send a single padding structure at the end
				in = hash_input[input_length-1:input_length-RATE];
				hash_input = { hash_input[input_length-RATE-1:0], padding };  // NOTE: this appends padding-structure
				padding = 0;
				in_valid = 1;
				cyclecount = 0;
				while (!in_received && (cyclecount <= 1000000)) begin
					cycle;
					cyclecount = cyclecount + 1;
					if (cyclecount > 1000000) begin
						identify;
						$error("single absorbe cycle took to long");
						errors = errors + 1;
					end
				end
				in_valid = 0;
				cycle;
			end
			in_completed = 1;
			cycle;

			/* squeeze phase */
			for (result_index = HASHSIZE; (result_index > 0) && !out_completed; result_index = result_index - RATE) begin
				cyclecount = 0;
				while (!out_valid && (cyclecount <= 1000000)) begin
					cycle;
					cyclecount = cyclecount + 1;
					if (cyclecount > 1000000) begin
						identify;
						$error("single squeeze cycle took to long");
						errors = errors + 1;
					end
				end
				if (out_valid) begin
					hash_result = {hash_result[HASHSIZE-1-RATE:0], out};
					out_received = 1;
					cycle;
					out_received = 0;
				end
			end

			cycle;
			cycle;
			cycle;
			cycle;

			if (!out_completed) begin
				identify;
				$error("result is too long for hash!");
				errors = errors + 1;
			end
			if (result_index != 0) begin
				identify;
				$error("result is too short for hash!");
				errors = errors + 1;
			end

			/* check result */
			if (^hash_result === 1'bx) begin
				identify;
				$error("X-value 0x%h instead of 0x%h", hash_result, expected_result);
				errors = errors + 1;
			end
			if (^hash_result === 1'bz) begin
				identify;
				$error("Z-value 0x%h instead of 0x%h", hash_result, expected_result);
				errors = errors + 1;
			end
			if (expected_result === hash_result) begin
				/* fine */
			end else begin
				identify;
				$error("received hash 0x%h instead of expected 0x%h", hash_result, expected_result);
				errors = errors + 1;
			end
			finished = 1;
		end
	end
endmodule

module spongent_hash_tb();
	integer errors = 0;

	localparam SUBTESTS = 5;
	wire [SUBTESTS-1:0] subtest_finished;
	wire [15:0] subtest_errors[SUBTESTS-1:0];

	spongent_hash_specific_tb #(	.HASHSIZE(88),
					.CAPACITY(80),
					.RATE(8),
					.ROUNDS(45),
					.LCOUNTER_FEEDBACK('b110000),
					.LCOUNTER_INIT('h5))
			spongent_088_080_008(				// version: 88808 / SPONGENT-088-080-008
					subtest_finished[0],
					subtest_errors[0],
					88'h69971bf96def95bfc46822);

	spongent_hash_specific_tb #(	.HASHSIZE(128),
					.CAPACITY(128),
					.RATE(8),
					.ROUNDS(70),
					.LCOUNTER_FEEDBACK('b1100000),
					.LCOUNTER_INIT('h7a))
			spongent_128_128_008(				// version: 1281288 / SPONGENT-128-128-008
					subtest_finished[1],
					subtest_errors[1],
					128'h6b7ba35eb09de0f8def06ae555694c53
					);

	spongent_hash_specific_tb #(	.HASHSIZE(160),
					.CAPACITY(160),
					.RATE(16),
					.ROUNDS(90),
					.LCOUNTER_FEEDBACK('b1100000),
					.LCOUNTER_INIT('h45))
			spongent_160_160_016(				// version: 16016016 / SPONGENT-160-160-016
					subtest_finished[2],
					subtest_errors[2],
					160'h13188a4917ea29e258362c047b9bf00c22b5fe91
					);

	spongent_hash_specific_tb #(	.HASHSIZE(224),
					.CAPACITY(224),
					.RATE(16),
					.ROUNDS(120),
					.LCOUNTER_FEEDBACK('b1100000),
					.LCOUNTER_INIT('h01))
			spongent_224_224_016(				// version: 22422416 / SPONGENT-224-224-016
					subtest_finished[3],
					subtest_errors[3],
					224'h8443b12d2eee4e09969a183205f5f7f684a711a5be079a15f4ccdc30
					);

	spongent_hash_specific_tb #(	.HASHSIZE(256),
					.CAPACITY(256),
					.RATE(16),
					.ROUNDS(140),
					.LCOUNTER_FEEDBACK('b10001110),
					.LCOUNTER_INIT('h9e))
			spongent_256_256_016(				// version: 25625616 / SPONGENT-256-256-016
					subtest_finished[4],
					subtest_errors[4],
					256'h67dc8fc8b2edba6e55f4e68ec4f2b2196fe38df9b1a760f4d43b4669160bf5a8
					);

	wire finished = &(subtest_finished);
	integer i;

	initial begin
		/*
		$dumpfile("spongent_hash_tb.vcd");
		$dumpvars;
		*/

		#1;

		wait(finished);

		#10;

		for (i = 0; i < SUBTESTS; ++i) begin
			errors = errors + int'(subtest_errors[i]);
		end

		if(errors != 0) begin
			$error("FAIL: collected %d errors", errors);
			$fatal();
		end else begin
			$finish();
		end
	end
endmodule
