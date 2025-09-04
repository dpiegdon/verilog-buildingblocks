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

// testbench for simple_spi_master

module simple_spi_master_tb();

	parameter WORDWIDTH=4;

	integer errors;
	integer phase;
	integer polarity;
	integer msb;


	reg [19:0] system_clk = 0;
	always #1 system_clk = system_clk+1;

	reg [19:0] clk_div = 20'd4;

	reg  cpol = 0;
	reg  cpha = 0;
	reg  msb_first = 0;

	reg  xfer_enable = 0;
	reg  xfer_word_trigger = 0;
	wire xfer_word_completed;
	reg  [WORDWIDTH-1:0] data_tx;
	wire [WORDWIDTH-1:0] data_rx;

	wire spi_cs;
	wire spi_clk;
	reg  spi_miso = 0;
	wire spi_mosi;


	simple_spi_master #(.WORDWIDTH(WORDWIDTH), .PRESCALER_WIDTH(4), .SYNCHRONIZE_MISO_FOR_CLKS(3))
		master(
			.system_clk(system_clk[0]),
			.clk_div(clk_div[3:0]),
			.cpol(cpol),
			.cpha(cpha),
			.msb_first(msb_first),
			.xfer_enable(xfer_enable),
			.xfer_word_trigger(xfer_word_trigger),
			.xfer_word_completed(xfer_word_completed),
			.data_tx(data_tx),
			.data_rx(data_rx),
			.spi_cs(spi_cs),
			.spi_clk(spi_clk),
			.spi_miso(spi_miso),
			.spi_mosi(spi_mosi));


	wire normalized_clk = spi_clk ^ cpol;  /* normalize to cpol=0 */
	reg [WORDWIDTH-1:0] current_mask;
	reg [WORDWIDTH-1:0] slave_buf_rx;
	reg [WORDWIDTH-1:0] slave_buf_tx;

	task automatic check_single_word_xfer;
		input test_cpol;
		input test_msb_first;
		input [WORDWIDTH-1:0] test_miso_value;
		input [WORDWIDTH-1:0] test_mosi_value;

		begin
			// assumes master already enabled, in ready mode,
			// waiting for trigger.

			data_tx = test_mosi_value;
			#2;
			xfer_word_trigger = 1;
			#2
			xfer_word_trigger = 0;

			if (!spi_cs) begin
				$error("CS not set during xfer");
				errors += 1;
			end

			if (normalized_clk) begin
				$error("CLK inverted during start of xfer");
			end

			slave_buf_rx = 0;
			slave_buf_tx = test_miso_value;
			current_mask = (test_msb_first) ? (1 << (WORDWIDTH-1)) : 1;

			if (!cpha) begin
				// latch on CS
				spi_miso = |(slave_buf_tx & current_mask);

				while (current_mask) begin
					@(posedge normalized_clk)
					if (spi_mosi) begin
						slave_buf_rx |= current_mask;
					end
					current_mask = (test_msb_first) ? (current_mask >> 1) : (current_mask << 1);
					if(|current_mask) begin
						@(negedge normalized_clk)
						spi_miso = |(slave_buf_tx & current_mask);
					end
				end

			end else begin
				// latch on first CLK edge
				while (current_mask) begin
					@(posedge normalized_clk)
					spi_miso = |(slave_buf_tx & current_mask);
					@(negedge normalized_clk)
					if (spi_mosi) begin
						slave_buf_rx |= current_mask;
					end
					current_mask = (test_msb_first) ? (current_mask >> 1) : (current_mask << 1);
				end
			end

			// check buffer values
			@(posedge xfer_word_completed);
			#1;
			if (slave_buf_rx != test_mosi_value) begin
				$error("MOSI sent %d but received %d", test_mosi_value, slave_buf_rx);
				errors += 1;
			end
			if (data_rx != slave_buf_tx) begin
				$error("MISO sent %d but received %d", slave_buf_tx, data_rx);
				errors += 1;
			end

			#2;
			if (xfer_word_completed) begin
				$error("xfer_word_completed held for longer than one clock!");
				errors += 1;
			end

			// regression:
			// should still show the same output after xfer_word_completed was released
			if (data_rx != slave_buf_tx) begin
				$error("received data latched in data_rx invalid after xfer_word_completed was released! MISO sent %d but received %d", slave_buf_tx, data_rx);
				errors += 1;
			end

			#1;
		end
	endtask

	task automatic check_full_xfer_simple;
		input integer test_clk_div;
		input test_cpol;
		input test_cpha;
		input test_msb_first;
		input [WORDWIDTH-1:0] test_miso_value;
		input [WORDWIDTH-1:0] test_mosi_value;

		begin
			system_clk = 0;
			#1;

			if (spi_cs) begin
				$error("CS set but no xfer");
				errors += 1;
			end

			clk_div = test_clk_div;
			cpol = test_cpol;
			cpha = test_cpha;
			msb_first = test_msb_first;
			#2;
			xfer_enable = 1;
			#2;

			if (!spi_cs) begin
				$error("CS not set during xfer");
				errors += 1;
			end

			check_single_word_xfer(test_cpol, test_msb_first, test_miso_value, test_mosi_value);

			xfer_enable = 0;
			#2;
			if (spi_cs) begin
				$error("CS set after xfer completed");
				errors += 1;
			end

			#10;
		end
	endtask

	task automatic check_full_xfer_long;
		input integer test_clk_div;
		input test_cpol;
		input test_cpha;
		input test_msb_first;
		input [WORDWIDTH-1:0] test_miso_value1;
		input [WORDWIDTH-1:0] test_miso_value2;
		input [WORDWIDTH-1:0] test_miso_value3;
		input [WORDWIDTH-1:0] test_mosi_value1;
		input [WORDWIDTH-1:0] test_mosi_value2;
		input [WORDWIDTH-1:0] test_mosi_value3;

		begin
			system_clk = 0;
			#1;

			if (spi_cs) begin
				$error("CS set but no xfer");
				errors += 1;
			end

			clk_div = test_clk_div;
			cpol = test_cpol;
			cpha = test_cpha;
			msb_first = test_msb_first;
			#2;
			xfer_enable = 1;
			#2;

			if (!spi_cs) begin
				$error("CS not set during xfer");
				errors += 1;
			end

			check_single_word_xfer(test_cpol, test_msb_first, test_miso_value1, test_mosi_value1);
			check_single_word_xfer(test_cpol, test_msb_first, test_miso_value2, test_mosi_value2);
			check_single_word_xfer(test_cpol, test_msb_first, test_miso_value3, test_mosi_value3);

			xfer_enable = 0;
			#2;
			if (spi_cs) begin
				$error("CS set after xfer completed");
				errors += 1;
			end

			#10;
		end
	endtask


	initial begin
		$dumpfile("simple_spi_master_tb.vcd");
		$dumpvars;

		errors = 0;

		/* single-word xfers for all combinations of CPOL/CPHA/bitorder */
		for(polarity = 0; polarity <= 1; polarity++) begin: check_all_polaritytypes
			for(phase = 0; phase <= 1; phase++) begin: check_all_phasetypes
				for(msb = 0; msb <= 1; msb++) begin: check_all_msbtypes
					check_full_xfer_simple(4, polarity, phase, msb, 4'b1010, 4'b0110);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b0000, 4'b1111);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b0101, 4'b1010);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b1111, 4'b0000);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b0001, 4'b1000);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b0010, 4'b0100);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b0100, 4'b0010);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b1000, 4'b0001);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b1110, 4'b0111);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b1101, 4'b1011);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b1011, 4'b1101);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b0111, 4'b1110);
					check_full_xfer_simple(4, polarity, phase, msb, 4'b1110, 4'b1110);

					check_full_xfer_long(4, polarity, phase, msb, 4'b0000, 4'b1111, 4'b0000,  4'b1010, 4'b0101, 4'b1100);
					check_full_xfer_long(4, polarity, phase, msb, 4'b1010, 4'b0101, 4'b1100,  4'b0000, 4'b1111, 4'b0000);
					check_full_xfer_long(4, polarity, phase, msb, 4'b1010, 4'b0000, 4'b0101,  4'b0110, 4'b1111, 4'b1010);

				end
			end
		end

		/* multi-word xfer */

		if (errors) begin
			$error("FAIL: collected %d errors", errors);
			$fatal();
		end else begin
			$finish();
		end
	end

endmodule
