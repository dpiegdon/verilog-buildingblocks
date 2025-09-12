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

// input debouncer.
//
// on out_edge, a rising edge identifies a button press, and nothing when the button is released.
// the value will only be high for a single clock.
//
// on out_state, the current button state is output, active high when pressed.
//
// INPUT_WHEN_IDLE must be set to the value that the line has
// when no button is pressed. this avoids an initial button press
// when the FPGA is started, and makes sure the edge comes when the
// button is pressed, and not when it is released.
//
// DEBOUNCE_CYCLES is the number of clock cycles after which a
// signal is assumed to be stable, if no changes happened.
module debouncer(
	input wire clk,
	input wire in,
	output reg out_state = 0,
	output reg out_edge = 0);

	parameter INPUT_WHEN_IDLE = 1;
	parameter DEBOUNCE_CYCLES = 1000;

	reg old = INPUT_WHEN_IDLE;
	reg running = 0;
	reg [$clog2(DEBOUNCE_CYCLES+1)-1 : 0] bounce_timeout = 0;

	always @(posedge clk) begin
		if(old != in) begin
			running <= 1;
			bounce_timeout <= DEBOUNCE_CYCLES;
			out_edge <= 0;
		end else begin
			if(running) begin
				bounce_timeout <= bounce_timeout - 1;
				if(bounce_timeout == 0) begin
					running <= 0;
					out_edge <= (INPUT_WHEN_IDLE) ? ~in : in;
					out_state <= (INPUT_WHEN_IDLE) ? ~in : in;
				end else begin
					out_edge <= 0;
				end
			end else begin
				out_edge <= 0;
			end
		end

		old <= in;
	end

endmodule

