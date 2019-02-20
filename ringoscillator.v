`default_nettype none

// Ring-Oscillator.
// Lattice ICE40 specific.
// May also work for ECP5 when `defining SB_LUT4 to LUT4.
module ringoscillator(output wire out);

	wire chain_in, chain_out;

	assign out = chain_out;

	// Single inverter of oscillator.
	assign chain_in = !chain_out;

	// Single LUT delay line. This also takes care that the compiler
	// (yosys) is not removing this logic path.
	SB_LUT4 #(
		.LUT_INIT(16'd2)
	) buffers (
		.O(chain_out),
		.I0(chain_in),
		.I1(1'b0),
		.I2(1'b0),
		.I3(1'b0)
	);

	// One could also use a single LUT for inversion, without the
	// extra delay. But then the oscillator is running at roughly
	// 625MHz and the output signal is so weak that other logic
	// might not properly pick it up. E.g. when connecting an output
	// pin to the signal, the pin has 625MHz with -25dBm, which is
	// 35.56mVpp! So having a single LUT delay line here seems a good
	// choice!

endmodule

