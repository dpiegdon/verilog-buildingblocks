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

module randomized_spongent_tb();
	integer errors = 0;

	reg [20:0] clk = 0;
	reg rst = 1;
	wire [7:0] out;
	wire out_valid;
	reg out_received = 0;
	wire metastable;

	integer received_count = 0;
	reg [399:0] received_data = 0;

	integer expected_count = 3*11 + 1;
	reg [399:0] expected_data = 400'h00000000000000000000000000000000_7c700ee6d3489520eb261c_087b2de20369daeea85c50_087b2de20369daeea85c50_08;
	/*                 first iteration has a differentstarting state--^^
	 *                              second and thirt iterations have inverse state to first--^^---------------------^^
	 *                                iteration stops immediately after start of fourth iteratation result (will be same as second/third)--^^
	 */



	randomized_spongent sponge(clk[0], rst, out, out_valid, out_received, metastable);

	always #1 clk = clk + 1;

	initial begin
		/*
		$dumpfile("randomized_spongent_tb.vcd");
		$dumpvars;
		*/

		#1;
		rst = 0;
		#1;

		while (clk < 'h0a0604) begin
			@(posedge out_valid);
//			$warning("out: 0x%x", out);
			received_data = {received_data[399-8:0], out};
			received_count = received_count + 1;
			out_received = 1;
			#4;
			out_received = 0;
			#4;
		end

		if ((received_data != expected_data)
			|| (received_count != expected_count)) begin
			$error("received     %d: 0x%x", received_count, received_data);
			$error("but expected %d: 0x%x", expected_count, expected_data);
		end


		if(errors != 0) begin
			$error("FAIL: collected %d errors", errors);
			$fatal();
		end else begin
			$finish();
		end
	end
endmodule
