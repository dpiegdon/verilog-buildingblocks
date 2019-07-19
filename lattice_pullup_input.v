`default_nettype none

// Lattice ice40 specific.
// Simplification of input with pullup on Lattice ice40 parts.
module lattice_pullup_input(
	input pin,
	output wire value);

	SB_IO #(
		.PIN_TYPE(6'b0000_01),
		.PULLUP(1'b1),
	) sb_io (
		.PACKAGE_PIN(pin),
		.D_IN_0(value),
	);
endmodule

