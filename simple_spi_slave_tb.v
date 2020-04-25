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

// testbench for simple_spi_slave

module simple_spi_slave_tb();
	parameter WIDTH=4;

	reg [20:0] system_clock;
	always #1 system_clock = system_clock+1;

	reg pin_clk = 0;
	reg pin_ncs = 1;
	reg pin_mosi = 0;
	wire pin_miso;
	wire pin_miso_en;

	reg [WIDTH-1:0] dut_miso_out;
	wire [WIDTH-1:0] dut_mosi_in;
	wire dut_cs_stop;
	wire dut_cs_start;
	wire dut_value_valid;

	reg [WIDTH-1:0] slave_mosi_buffer;
	reg [WIDTH-1:0] master_miso_buffer;

	simple_spi_slave #(.WIDTH(WIDTH)) dut(
		.system_clk(system_clock[0]),
		.pin_ncs(pin_ncs),
		.pin_clk(pin_clk),
		.pin_mosi(pin_mosi),
		.pin_miso(pin_miso),
		.pin_miso_en(pin_miso_en),
		.value_miso(dut_miso_out),
		.value_mosi(dut_mosi_in),
		.cs_stop(dut_cs_stop),
		.cs_start(dut_cs_start),
		.value_valid(dut_value_valid));
	
	always @(negedge system_clock) begin
		if(dut_value_valid) begin
			slave_mosi_buffer <= dut_mosi_in;
		end
	end

	integer errors;

	task automatic clock_single;
		input bit;
		begin
			pin_mosi = bit;
			#100;
			pin_clk = 1;
			master_miso_buffer = { master_miso_buffer[WIDTH-2:0], pin_miso };
			#100;
			pin_clk = 0;
		end
	endtask

	task automatic clock_word;
		input [WIDTH-1:0] word;
		integer i;
		begin
			#100;
			pin_ncs=0;

			for(i = 0; i < WIDTH; i=i+1) begin
				clock_single(word[WIDTH-1-i]);
			end
			#10;

			pin_ncs=1;
			#100;
		end
	endtask

	task automatic check_full_transfert;
		input [WIDTH-1:0] miso_value;
		input [WIDTH-1:0] mosi_value;

		begin
			slave_mosi_buffer = 4'bxxxx;
			master_miso_buffer = 4'bxxxx;
			dut_miso_out = miso_value;
			clock_word(mosi_value);
			if(slave_mosi_buffer != mosi_value) begin
				$error("MOSI sent %d but received %d", mosi_value, slave_mosi_buffer);
				errors += 1;
			end
			if(master_miso_buffer != miso_value) begin
				$error("MISO sent %d but received %d", miso_value, master_miso_buffer);
				errors += 1;
			end
			#100;
		end
	endtask

	initial begin
		//$dumpfile("simple_spi_slave_tb.vcd");
		//$dumpvars;
		errors = 0;
		system_clock = 0;
		pin_clk = 0;
		pin_ncs = 1;
		pin_mosi = 0;

		check_full_transfert(4'b1010, 4'b0110);
		check_full_transfert(4'b0000, 4'b1111);
		check_full_transfert(4'b0101, 4'b1010);
		check_full_transfert(4'b1111, 4'b0000);
		check_full_transfert(4'b0001, 4'b1000);
		check_full_transfert(4'b0010, 4'b0100);
		check_full_transfert(4'b0100, 4'b0010);
		check_full_transfert(4'b1000, 4'b0001);
		check_full_transfert(4'b1110, 4'b0111);
		check_full_transfert(4'b1101, 4'b1011);
		check_full_transfert(4'b1011, 4'b1101);
		check_full_transfert(4'b0111, 4'b1110);

		if(errors) begin
			$error("FAIL: collected %d errors", errors);
			$fatal();
		end else begin
			$finish;
		end
	end

endmodule
