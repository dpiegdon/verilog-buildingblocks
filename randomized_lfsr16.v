`default_nettype none

// Random number generator based on a 16 bit LFSR that is seeded
// from a metastable source.
// Lattice ICE40 specific.
// May also work for ECP5 when `defining SB_LUT4 to LUT4.
module randomized_lfsr16(input wire clk, output wire [0:15] out, output wire metastable, input wire rst);

	metastable_oscillator osci(metastable);
	lfsr shiftreg(clk, metastable, out, rst);

endmodule

