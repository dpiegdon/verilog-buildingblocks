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

// LFSR for random number generation that is seeded from a metastable
// source. Yields bits at bit_ready, or fully independent words at
// word_ready.
// Output data usually passes tests of rngtest [1] and
// NIST Entropy Assessment [2].
// But don't hold me accountable. Entropy quality may heavily depend on FPGA
// fabric, routing and other effects.
//
// [1] rngtest https://linux.die.net/man/1/rngtest
// [2] NIST Entropy Assessment https://github.com/usnistgov/SP800-90B_EntropyAssessment
module randomized_lfsr(input wire clk, input wire rst, output wire bit_ready, output wire word_ready, output wire [WIDTH-1:0] out, output wire metastable);

	parameter WIDTH = 'd16;
	parameter INIT_VALUE = 16'b1010_1100_1110_0001;
	parameter FEEDBACK = 16'b0000_0000_0010_1101;

	reg [$clog2(WIDTH)-1:0] bits_remaining = WIDTH-1;
	reg previous_bit_ready = 0;

	always @ (posedge clk) begin
		if(rst || word_ready) begin
			bits_remaining <= WIDTH-1;
		end else begin
			if(!previous_bit_ready && bit_ready) begin
				bits_remaining <= bits_remaining - 1;
			end
		end
		previous_bit_ready <= bit_ready;
	end

	assign word_ready = (bits_remaining == 0);

	wire random;
	metastable_oscillator_depth2 osci(metastable);
	binary_debias debias(clk, metastable, bit_ready, random);
	lfsr #(.WIDTH(WIDTH), .INIT_VALUE(INIT_VALUE), .FEEDBACK(FEEDBACK)) shiftreg(bit_ready, random, out, rst);

endmodule

// Like the randomized_lfsr, this generates random numbers.
// But where randomized_lfsr tries to maximize entropy of
// produced random numbers, the randomized_lfsr_weak tries to be very
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

