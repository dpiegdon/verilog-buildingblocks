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

// testbench for charlieplexer.
module charlieplexer_tb();
	localparam PINCOUNT=33;
	localparam INDEXBITS=$clog2(PINCOUNT * (PINCOUNT-1));


	reg [INDEXBITS-1:0] dut_in;
	reg dut_enable;
	wire [PINCOUNT-1:0] dut_out_en;
	wire [PINCOUNT-1:0] dut_out_value;

	charlieplexer #(.PINCOUNT(PINCOUNT)) dut(
		.in(dut_in),
		.enable(dut_enable),
		.out_en(dut_out_en),
		.out_value(dut_out_value));


	reg [PINCOUNT-1:0] highmask;
	reg [PINCOUNT-1:0] lowmask;

	function integer count_bits(input [PINCOUNT-1:0] in);
		integer i;
		begin
			count_bits = 0;
			for(i = 0; i < PINCOUNT; i=i+1) begin
				if(in[i]) begin
					count_bits = count_bits + 1;
				end
			end;
		end
	endfunction

	initial begin: test_inputs
		integer errors;
		integer i;
		integer count;
		integer grid [PINCOUNT-1:0] [PINCOUNT-1:0];
		integer vcc, gnd;

		errors = 0;

		for(vcc=0; vcc<PINCOUNT; vcc=vcc+1)
			for(gnd=0; gnd<PINCOUNT; gnd=gnd+1)
				grid[vcc][gnd] = 0;

		// the following loop does a few simple checks:
		// for any (valid) input:
		// 	- exactly one pin must be set to high,
		// 	- exactly one pin must be set to low,
		// 	- all others must be in tristate.
		for(i=0; i<PINCOUNT*(PINCOUNT-1); i=i+1) begin
			#1;
			dut_in = i;
			dut_enable = 1;

			#1;
			highmask = dut_out_en & dut_out_value;
			lowmask = dut_out_en & ~dut_out_value;

			/* // NOTE XXX for debugging enable this
			$display("");
			$display("in=%0d enable=%0d out_en=0x%x out_value=0x%x", dut_in, dut_enable, dut_out_en, dut_out_value);
			$display("in=%0d highmask=0x%x lowmask=0x%x", dut_in, highmask, lowmask);
			*/ // NOTE XXX end

			if(highmask != dut_out_value) begin
				$error("enabling pin that is in tristate?");
				errors = errors+1;
			end

			count = count_bits(highmask);
			if(count != 1) begin
				$error("not exactly 1 pin is HIGH, but %0d.", count);
				errors = errors+1;
			end

			count = count_bits(lowmask);
			if(count != 1) begin
				$error("not exactly 1 pin is LOW, but %0d.", count);
				errors = errors+1;
			end

			count = count_bits(~dut_out_en);
			if(count != PINCOUNT-2) begin
				$error("not exactly %0d pins are tristated, but %0d.", PINCOUNT-2, count);
				errors = errors+1;
			end

			// remember which combinations were hit
			vcc = $clog2(highmask);
			gnd = $clog2(lowmask);
			grid[vcc][gnd] = grid[vcc][gnd] + 1;

			#1;

			dut_enable = 0;

			#1;

			if(dut_enable != 0) begin
				$error("device disabled but pin enabled.");
				errors = errors+1;
			end
		end

		/*
		 * check that:
		 *   - all correct combinations (vcc!=gnd) were hit exactly once
		 *   - all invalid (vcc==gnd) were not hit.
		 */
		for(vcc=0; vcc<PINCOUNT; vcc=vcc+1) begin
			for(gnd=0; gnd<PINCOUNT; gnd=gnd+1) begin
				if(vcc == gnd) begin
					if(grid[vcc][gnd] != 0) begin
						$error("invalid combination hit: (vcc %0d, gnd %0d)", vcc, gnd);
						errors = errors + 1;
					end
				end else begin
					if(grid[vcc][gnd] != 1) begin
						$error("combination hit %0d times, should have been once: (vcc %0d, gnd %0d)", vcc, gnd);
						errors = errors + 1;
					end
				end
			end
		end

		if(errors == 0)
			$finish;
		else
			$fatal();
	end
endmodule

