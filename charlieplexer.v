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
		// This is a stupid solution, but I am not very versatile with
		// verilog so far, so I did not really come up with a better
		// solution.
		integer ix, iy, stop;
		begin
			LedIndex = 0;
			stop = 0;
			for(ix = 0; ix < pinCount; ix++) begin
				for(iy = 0; iy < pinCount; iy++) begin
					if((ix != iy) && (stop == 0)) begin
						if((x == ix) && (y == iy)) begin
							stop = 1;
						end else begin
							LedIndex = LedIndex+1;
						end
					end
				end
			end
		end
	endfunction

	// @grid corresponds to the matrix of LEDs and resistors as seen above
	wire grid [PINCOUNT-1:0] [PINCOUNT-1:0];
	wor [PINCOUNT-1:0] out_gnd; // OR over each row
	wor [PINCOUNT-1:0] out_vcc; // OR over each column

	generate
		genvar x, y;
		for(y = 0; y < PINCOUNT; y++) begin
			for(x = 0; x < PINCOUNT; x++) begin
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

