`default_nettype none

// Lattice ice40 specific.
// Fully debounced button with an internal pull-up.
// Just connect a switch to the pin that would pull it to GND.
module lattice_debounced_button(
	input wire clk,
	input wire in,
	output wire out);

	parameter DEBOUNCE_CYCLES = 100;
	parameter CLOCKED_EDGE_OUT = 0;

	wire pin_value;

	lattice_pullup_input input_pin(in, pin_value);

	debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES),
		.CLOCKED_EDGE_OUT(CLOCKED_EDGE_OUT))
		input_debouncer(clk, pin_value, out);

endmodule

