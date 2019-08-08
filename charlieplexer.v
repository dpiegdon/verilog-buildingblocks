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

/* Generic charlieplexer module to control (PINCOUNT * (PINCOUNT-1)) LEDs
 * via PINCOUNT outputs that may be tristated or pulled to VCC or GND.
 *
 * in:         LED to enable (index number from 0 .. PINCOUNT*(PINCOUNT-1)-1)
 * enable:     global enable switch for tristateable outputs
 * out_en:     flags indicating that an output shall be driven instead of tristated
 * out_value:  values for non-tristated outputs (0=GND, 1=VCC)
 *
 * The charlieplex hardware is expected to look like a generalized version
 * of the following 4-pin example. I.e. it is a NxN matrix for N outputs.
 *
 *          X=0      X=1      X=2      X=3
 *
 *       OUT0     OUT1     OUT2     OUT3
 *       |        |        |        |
 *       x---x    x---x    x---x    x---x
 *       |   |    |   |    |   |    |   |
 *  Y=0  |   ▓    |   ▼3   |   ▼6   |   ▼9
 *       |   |    |   |    |   |    |   |
 *       |   x----|---x----|---x----|---x
 *       |        |        |        |
 *       x---x    x---x    x---x    x---x
 *       |   |    |   |    |   |    |   |
 *  Y=1  |   ▼0   |   ▓    |   ▼7   |   ▼10
 *       |   |    |   |    |   |    |   |
 *       |   x----|---x----|---x----|---x
 *       |        |        |        |
 *       x---x    x---x    x---x    x---x
 *       |   |    |   |    |   |    |   |
 *  Y=2  |   ▼1   |   ▼4   |   ▓    |   ▼11
 *       |   |    |   |    |   |    |   |
 *       |   x----|---x----|---x----|---x
 *       |        |        |        |
 *       x---x    x---x    x---x    x---x
 *           |        |        |        |
 *  Y=3      ▼2       ▼5       ▼8       ▓
 *           |        |        |        |
 *           x--------x--------x--------x
 *
 *   Where
 *      ▓   is a current-limiting resistor as needed to drive
 *          a single LED from a single output line. These resistors
 *          are all on the diagonal (x==y) of the matrix and each
 *          is the current-limiter for the LEDs right and left of it.
 *      ▼n  is the LED with index n, with its anode (+) at the top
 *          and cathode (-) at the bottom. Each LED is driven by
 *          setting its column to VCC and its row-resistor to GND.
 *
 */
module charlieplexer(
	input  wire [INDEXBITS-1:0] in,
	input  wire enable,
	output wire [PINCOUNT-1:0] out_en,
	output wor [PINCOUNT-1:0] out_value);

	parameter PINCOUNT = 4;
	localparam INDEXBITS = $clog2(PINCOUNT * (PINCOUNT-1));

	function [INDEXBITS-1:0] LedIndex(input integer x, input integer y, input integer pinCount);
		// Returns the index of the LED at grid-position x/y.
		if(x > y) begin
			LedIndex = (pinCount-1)*x + y;
		end else begin
			LedIndex = (pinCount-1)*x + y-1;
		end
	endfunction

	// @grid corresponds to the matrix of LEDs and resistors as seen above
	wire grid [PINCOUNT-1:0] [PINCOUNT-1:0];
	wor [PINCOUNT-1:0] out_gnd; // OR over each row
	wor [PINCOUNT-1:0] out_vcc; // OR over each column

	generate
		genvar x, y;
		for(y = 0; y < PINCOUNT; y=y+1) begin
			for(x = 0; x < PINCOUNT; x=x+1) begin
				if(x != y) begin
					assign grid[x][y] = (in == LedIndex(x, y, PINCOUNT));
					assign out_vcc[x] = grid[x][y];
					assign out_gnd[y] = grid[x][y];
				end
			end

			// gate output with enable-signal
			assign out_en[y] = enable && (out_gnd[y] || out_vcc[y]);
		end
	endgenerate

	assign out_value = out_vcc;
endmodule

