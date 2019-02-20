`default_nettype none

// Implements a generic linear feedback shift register that allows to shift
// additional random bits into the front to improve its randomness.
// The default parameters match to a fibonacci LFSR.
module lfsr(input wire clk, input wire random, output reg [WIDTH-1:0] shiftreg);

	parameter WIDTH = 'd16;
	parameter INIT_VALUE = 16'b1010_1100_1110_0001;
	parameter FEEDBACK = 16'b0000_0000_0010_1101;

	wire feedback;
	reg init_done = 0;

	assign feedback = random ^ (^(shiftreg & FEEDBACK));

	always @ (posedge clk) begin
		if(init_done) begin
			shiftreg <= {feedback, shiftreg[WIDTH-1:1]};
		end else begin
			shiftreg <= INIT_VALUE;
			init_done <= 1;
		end
	end

endmodule

