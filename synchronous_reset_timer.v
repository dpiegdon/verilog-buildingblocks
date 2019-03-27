`default_nettype none

// synchronize a reset signal to a clock, also stretch it to LENGTH clocks.
module synchronous_reset_timer(input wire clk, output wire reset_out, input wire reset_in);
	parameter LENGTH=7;

	reg [$clog2(LENGTH)-1:0] timer = LENGTH;
	assign reset_out = |timer;

	always @(posedge clk, posedge reset_in) begin
		if(reset_in) begin
			timer <= LENGTH;
		end else if(reset_out) begin
			timer <= timer - 1;
		end
	end

endmodule

