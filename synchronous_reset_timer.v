
module synchronous_reset_timer(input wire clk, output wire reset_out, input wire reset_in);

	reg [2:0] timer = 3'b111;
	assign reset_out = |timer;

	always @(posedge clk) begin
		if(reset_in) begin
			timer = 3'b111;
		end else if(reset_out) begin
			timer = timer - 1;
		end
	end

endmodule

