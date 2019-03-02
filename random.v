`default_nettype none

// Circuit generating a metastable output.
// Lattice ICE40 specific.
// May also work for ECP5 when `defining SB_LUT4 to LUT4.
module metastable_oscillator(output wire metastable);

	wire s0, s1, s2, s3;

	ringoscillator r0(s0);
	ringoscillator r1(s1);
	ringoscillator r2(s2);
	ringoscillator r3(s3);

	SB_LUT4 #(.LUT_INIT(16'b1010_1100_1110_0001))
		destabilizer (.O(metastable), .I0(s0), .I1(s1), .I2(s2), .I3(s3));

endmodule

// Circuit generating an even more metastable output.
// Lattice ICE40 specific.
// May also work for ECP5 when `defining SB_LUT4 to LUT4.
module metastable_oscillator_depth2(output wire metastable);

	wire s0, s1, s2, s3;

	metastable_oscillator r0(s0);
	metastable_oscillator r1(s1);
	metastable_oscillator r2(s2);
	metastable_oscillator r3(s3);

	SB_LUT4 #(.LUT_INIT(16'b0101_0011_0001_1110))
		destabilizer (.O(metastable), .I0(s0), .I1(s1), .I2(s2), .I3(s3));
	
endmodule

// Remove a simple statistical bias in a random stream,
// by XORing the stream with itself offset by one bit.
module metastable_binary_debias(input wire clk, input wire metastable, output reg output_clk, output reg random);

	reg last_random;

	always @ (posedge clk) begin
		output_clk <= output_clk+1;
		if(output_clk) begin
			random <= !metastable ^ last_random;
		end else begin
			last_random <= metastable;
		end
	end

endmodule

// LFSR for random number generation that is seeded from a metastable
// source. Yields bits at output_clk, or fully independent words at
// output_word_clk.
// Output data usually passes tests of rngtest [1] and
// NIST Entropy Assessment [2].
// But don't hold me accountable. Entropy quality may heavily depend on FPGA
// fabric, routing and other effects.
//
// [1] rngtest https://linux.die.net/man/1/rngtest
// [2] NIST Entropy Assessment https://github.com/usnistgov/SP800-90B_EntropyAssessment
//
// Lattice ICE40 specific.
// May also work for ECP5 when `defining SB_LUT4 to LUT4.
module randomized_lfsr(input wire clk, input wire rst, output wire output_clk, output wire output_word_clk, output wire [WIDTH-1:0] out, output wire metastable);

	parameter WIDTH = 'd16;
	parameter INIT_VALUE = 16'b1010_1100_1110_0001;
	parameter FEEDBACK = 16'b0000_0000_0010_1101;

	reg [$clog2(WIDTH)-1:0] word_clk = 0;

	always @ (posedge output_clk) begin
		if(rst) begin
			word_clk = 0;
		end else begin
			word_clk = word_clk + 1;
		end
	end

	assign output_word_clk = !(|word_clk);

	wire random;
	metastable_oscillator_depth2 osci(metastable);
	metastable_binary_debias debias(clk, metastable, output_clk, random);
	lfsr #(.WIDTH(WIDTH), .INIT_VALUE(INIT_VALUE), .FEEDBACK(FEEDBACK)) shiftreg(output_clk, random, out, rst);

endmodule

// Like the randomized_lfsr, this generates random numbers.
// But where randomized_lfsr tries to maximize entropy of
// produced random numbers, the randomized_lfsr_weak tries to be very
// small while still producing an acceptable amount of entropy
// for jobs that don't depend on too much entropy.
// Lattice ICE40 specific.
// May also work for ECP5 when `defining SB_LUT4 to LUT4.
module randomized_lfsr_weak(input wire clk, input wire rst, output wire [WIDTH-1:0] out, output wire metastable);

	parameter WIDTH = 'd8;
	parameter INIT_VALUE = 8'b1100_1010;
	parameter FEEDBACK = 8'b0001_1101;

	wire random;
	metastable_oscillator osci(metastable);
	lfsr #(.WIDTH(WIDTH), .INIT_VALUE(INIT_VALUE), .FEEDBACK(FEEDBACK)) shiftreg(clk, metastable, out, rst);

endmodule

