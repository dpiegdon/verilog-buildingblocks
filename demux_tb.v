/*
This file is part of verilog-buildingblocks,
by David R. Piegdon <dgit@piegdon.de>

verilog-buildingblocks is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

verilog-buildingblocks is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with verilog-buildingblocks.  If not, see <https://www.gnu.org/licenses/>.
*/

`default_nettype none
`timescale 1ns / 1ps

// testbench for demultiplexer.
module demux_tb();
	localparam OUTPUT_WIDTH = 2**10+1;
	localparam SELECTOR_WIDTH = $clog2(OUTPUT_WIDTH);

	reg dut_enable;
	reg [SELECTOR_WIDTH-1:0] dut_selector;
	wire [OUTPUT_WIDTH-1:0] dut_out;

	demux #(.OUTPUT_WIDTH(OUTPUT_WIDTH))
		dut(.enable(dut_enable), .selector(dut_selector), .out(dut_out));


	initial begin: test_inputs
		integer errors;
		integer i;

		errors = 0;

		for(i=0; i<OUTPUT_WIDTH; i=i+1) begin
			dut_enable = 1;
			dut_selector = i;
			
			#1

			if(dut_out != (1 << i)) begin
				$error("enabled selector=%0d selected wrong pin: out=0x%0x", i, dut_out);
				errors = errors + 1;
			end

			#1;

			dut_enable = 0;

			#1;

			if(dut_out != 0) begin
				$error("DISABLED selector=%0d selected pins: out=0x%0x", i, dut_out);
				errors = errors + 1;
			end
		end

		if(errors == 0)
			$finish;
		else
			$fatal();
	end
endmodule

