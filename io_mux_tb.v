/*
This file is part of verilog-buildingblocks,
by David R. Piegdon <dgit@piegdon.de>

verilog-buildingblocks is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

verilog-buildingblocks is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with verilog-buildingblocks.  If not, see <https://www.gnu.org/licenses/>.
*/

`default_nettype none
`timescale 1ns / 1ps

module io_mux_tb();
	localparam RXCOUNT = 2;
	localparam TXCOUNT = 3;
	localparam FCOUNT = RXCOUNT+TXCOUNT;
	localparam FWIDTH = $clog2(FCOUNT+1);

	integer errors = 0;
	reg [FWIDTH-1+1:0] func_select;
	reg [TXCOUNT-1+1:0] func_transmit;
	reg [1:0] pin_in = 0;
	wire [RXCOUNT-1:0] func_receive;
	wire pin_ena, pin_out;

	io_mux #(.RXCOUNT(RXCOUNT), .TXCOUNT(TXCOUNT))
		mux(pin_ena, pin_out, pin_in[0],
		    func_select[FWIDTH-1:0], func_receive[RXCOUNT-1:0], func_transmit[TXCOUNT-1:0]);

	integer value;
	integer func;

	initial begin
		/*
		$dumpfile("io_mux_tb.vcd");
		$dumpvars;
		*/

		// test input functions
		for (func_select = 0; func_select < RXCOUNT; func_select=func_select+1) begin
			for (func_transmit = 0; func_transmit <= 2**TXCOUNT; func_transmit = func_transmit+1) begin
				for (pin_in = 0; pin_in <= 1; pin_in = pin_in+1) begin
					#1;
					if (pin_ena != 0) begin
						$error("pin_ena for input function %d", func_select);
						errors = errors + 1;
					end
					if (pin_out != 0) begin
						$error("pin_out for input function %d", func_select);
						errors = errors + 1;
					end
					if (pin_in != |(func_receive & (1 << func_select))) begin
						$error("bad func_receive 0x%x for input function %d input %d", func_receive, func_select, pin_in);
						errors = errors + 1;
					end
				end
			end
		end

		// test output functions
		for(func_select = RXCOUNT; func_select < FCOUNT; func_select=func_select+1) begin
			for (func_transmit = 0; func_transmit <= 2**TXCOUNT; func_transmit = func_transmit+1) begin
				for(pin_in = 0; pin_in <= 1; pin_in = pin_in+1) begin
					#1;
					if (pin_ena != 1) begin
						$error("pin_ena NOT for output function %d", func_select);
						errors = errors + 1;
					end
					if (pin_out != |(func_transmit & (1 << func_select-2))) begin
						$error("bad pin_out %d for output function %d func_transmit 0x%x", pin_out, func_select, func_transmit);
						errors = errors + 1;
					end
					if (func_receive != 0) begin
						$error("bad func_receive 0x%x for output function %d input %d", func_receive, func_select, pin_in);
						errors = errors + 1;
					end
				end
			end
		end

		if(errors != 0) begin
			$error("FAIL: collected %d errors", errors);
			$fatal();
		end else begin
			$finish();
		end
	end
endmodule
