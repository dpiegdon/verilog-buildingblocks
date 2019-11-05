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

// Reduce a simple statistical bias in a random stream,
// by XORing two consecutive bits into one, with one of them negated.
// This is not fully removing the bias, only reducing it.
// Given a probability of `p` that an input bit (`metastable`) is 1,
// the probability will be `2p-2p^2` that the resulting bit is 1.
// This converges toward 0.5, but is not a perfect solution.
// See [1] for a better solution, which in turn needs a variable
// amount of input bits for perfect debiasing.
//
// [1] von Neumann method for debiasing random data
//     https://mcnp.lanl.gov/pdf_files/nbs_vonneumann.pdf
module binary_debias(input wire clk, input wire metastable, output reg bit_ready, output reg random);

	reg last_random;

	always @ (posedge clk) begin
		bit_ready <= bit_ready+1;
		if(bit_ready) begin
			random <= !metastable ^ last_random;
		end else begin
			last_random <= metastable;
		end
	end

endmodule

