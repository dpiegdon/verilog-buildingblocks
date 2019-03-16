`default_nettype none
`timescale 1ns / 1ps

// testbench for synchronous_reset_timer
module synchronous_reset_timer_tb();

	parameter LENGTH=7;

	reg [20:0] clk;
	reg reset_in;
	integer errors;
	integer i;

	wire reset_out;

	synchronous_reset_timer #(.LENGTH(LENGTH)) dut(clk[0], reset_out, reset_in);

	always #1 clk = clk+1;
	
	initial begin
		clk = 0;
		reset_in = 0;
		errors = 0;

		for(i=0; i<LENGTH; i=i+1) begin
			if(!reset_out) begin
				$error("should reset but does not.");
				errors = errors + 1;
			end
			@(negedge clk);
		end
		if(reset_out) begin
			$error("should no longer reset but does.");
			errors = errors + 1;
		end

		reset_in = 1;
		@(negedge clk);
		reset_in = 0;

		for(i=0; i<LENGTH; i=i+1) begin
			if(!reset_out) begin
				$error("should reset but does not.");
				errors = errors + 1;
			end
			@(negedge clk);
		end
		if(reset_out) begin
			$error("should no longer reset but does.");
			errors = errors + 1;
		end

		if(errors == 0)
			$finish;
		else
			$fatal();
	end

endmodule

