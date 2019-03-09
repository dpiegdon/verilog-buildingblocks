`default_nettype none
`timescale 1ns / 1ps

// testbench for lfsr.
module lfsr_tb();
	localparam ITERATIONS=16'h1000;

	reg [20:0] clk;
	reg random;
	wire [15:0] shiftreg;
	reg rst;

	reg [15:0] whitelist [0:ITERATIONS-1];

	integer errors;
	integer i;
	reg [15:0] known_good;
	reg [15:0] old;
	reg feedback;

	lfsr dut(clk[0], random, shiftreg, rst);

	always #1 clk = clk+1;

	initial begin
		clk = 0;
		random = 0;
		rst = 0;
		errors = 0;
		whitelist[0] = 16'hACE1;
		for(i=1; i<ITERATIONS; i=i+1) begin
			old = whitelist[i-1];
			feedback = old[0] ^ old[2] ^ old[3] ^ old[5];
			whitelist[i] = { feedback, old[15:1] };
		end

		while((clk[20:1]) < ITERATIONS) begin
			known_good = whitelist[{1'h0, clk[15:1]}];
			if (known_good != shiftreg) begin
				$error("iteration %d: output 0x%04x != 0x%04x expected",
					clk[16:1],
					whitelist[{1'h0, clk[15:1]}],
					shiftreg);
				errors = errors+1;
			end
			#2;
		end

		if(errors == 0)
			$finish;
		else
			$fatal();
	end

endmodule

