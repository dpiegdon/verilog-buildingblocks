`default_nettype none

// Simplification of tristate output module on Lattice HX/LP parts.
module tristate_output(
	input pin,
	input wire enable,
	input wire value);

	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b0),
	) sb_io (
		.PACKAGE_PIN(pin),
		.OUTPUT_ENABLE(enable),
		.D_OUT_0(value),
	);
endmodule

