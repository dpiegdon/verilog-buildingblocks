`default_nettype none

// Random number generator based on a 16 bit LFSR that is seeded
// from a metastable source. Yields bits at clk/2.
// Lattice ICE40 specific.
// May also work for ECP5 when `defining SB_LUT4 to LUT4.
module randomized_lfsr16(input wire clk, output wire [0:15] out, output wire metastable, input wire rst);

	// the oscillator may be biased toward one side.
	// splitting the random stream into two and inverting one of them
	// before recombination should take out any statistical bias.

	reg half_clk = 0;
	reg random = 0;

	metastable_oscillator_depth2 osci(metastable);
	lfsr shiftreg(half_clk, random, out, rst);

	always @ (posedge clk) begin
		if(half_clk) begin
			random <= metastable;
		end else begin
			random <= random ^ !metastable;
		end
		half_clk <= half_clk + 1;
	end

endmodule

