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

/* Simple SPI master implementation.
 *
 * SPI master that can transfer multiple words during a full SPI transfer,
 * but between each word the received/to-be-transmitted data has to be
 * handled.
 * 
 * E.g. if you want to xfer 2 words:
 *
 *  - Adjust cpol, cpha, msb_first, clk_div.
 *  - Set xfer_enable.
 *  - While there are words to be transceived:
 *     * Await xfer_idle
 *     * Set data_tx to the word to be transmitted next
 *     * Set xfer_word_trigger for one cycle
 *       (i.e. rising edge, clear after 1 cycle)
 *     * Await rising edge on xfer_word_trigger
 *     * Copy received data from data_rx
 *  - Clear xfer_enable.
 *
 * Output signals:
 *  - spi_cs:
 *    There is only one CS, and it is active high.
 *    If you want multiple chips, or the chips CS is active low, you will
 *    need a mux and a negation.
 *  - spi_clk, spi_mosi:
 *    Use as-is.
 *  - spi_miso:
 *    Optionally is routed through a synchronizer, see
 *    SYNCHRONIZE_MISO_FOR_CLKS.
 *
 */
module simple_spi_master(
	input  wire system_clk,				// system-clock

	input  wire [PRESCALER_WIDTH-1:0] clk_div,	// spi-clock prescaler
	input  wire cpol,				// clock polarity
	input  wire cpha,				// clock phase
	input  wire msb_first,				// send/receive MSB first

	input  wire xfer_enable,			// xfer-on flag (more or less chipselect)
	output wire xfer_idle,				// no xfer running, idle state
	input  wire xfer_word_trigger,			// rising edge triggers xfer of next word
	output reg  xfer_word_completed,		// rising edge indicates that word xfer is ready and received in data_rx

	input  wire [WORDWIDTH-1:0] data_tx,		// data to transmit in next xfer word (only change this before first trigger or when xfer_ready)
	output reg  [WORDWIDTH-1:0] data_rx,		// data received in last xfer word

	output reg  spi_cs,				// SPI chipselect
	output reg  spi_clk,				// SPI clock
	input  wire spi_miso,				// SPI MISO signal
	output reg  spi_mosi);				// SPI MOSI signal

	parameter WORDWIDTH = 8;			// # of bits per each word that is transfered on the bus
	parameter PRESCALER_WIDTH = 4; 			// bits the prescaler register should be wide
	parameter SYNCHRONIZE_MISO_FOR_CLKS = 0;	// number of clocks that MISO should be passed through a synchronizer for,
							// to avoid metastable states.
							// set to 0 to disable sync, or something >= 3 to enable.
							// if enabled, clk_div must be set such that synchronization is fast enough.

	localparam STATE_XFER_AWAIT = 0;		// xfer_enable, but awaiting TX word + trigger
	localparam STATE_XFER_LATCH = 1;		// xfer triggered and running: latch-half of current clock
	localparam STATE_XFER_SAMPLE = 2;		// xfer triggered and running: sample-half of current clock
	localparam STATE_XFER_READY = 3;		// xfer of word completed, await trigger-removal

	// synchronize MISO, if need be
	wire spi_miso_synced;
	generate
		if (SYNCHRONIZE_MISO_FOR_CLKS == 0) begin : miso_sync_off
			assign spi_miso_synced = spi_miso;
		end else if (SYNCHRONIZE_MISO_FOR_CLKS >= 3) begin : miso_sync_on
			/* verilator lint_off PINCONNECTEMPTY */
			synchronizer #(.EXTRA_DEPTH(SYNCHRONIZE_MISO_FOR_CLKS-3))
				miso_syncer(.clk(system_clk),
					    .in(spi_miso),
					    .out(spi_miso_synced),
					    .rising_edge(),
					    .falling_edge());
		end else begin : miso_sync_error
			/* raise an error for invalid values of SYNCHRONIZE_MISO_FOR_CLKS */
			INVALID_VALUE_FOR_PARAMETER_SYNCHRONIZE_MISO_FOR_CLKS not_a_real_instance();
		end
	endgenerate

	reg [1:0] state = STATE_XFER_AWAIT;
	reg [WORDWIDTH-1:0] current_mask = 0;							// mask with only current bit set
	reg [PRESCALER_WIDTH-1+1:0] clk_prescaler = 0;						// prescaler counter
	wire [PRESCALER_WIDTH-1+1:0] clk_last = {1'b0, clk_div} + 1;				// stop-condition for prescaler counter
	wire [WORDWIDTH-1:0] next_mask = msb_first ? (current_mask >> 1) : (current_mask << 1);	// mask for the next bit to be xfer'ed, or 0 when finished
	assign xfer_idle = xfer_enable && (state == STATE_XFER_AWAIT);

	always @(posedge system_clk) begin
		if (xfer_enable) begin
			case (state)
				STATE_XFER_AWAIT: begin
					spi_cs <= 1;
					spi_clk <= cpol;
					xfer_word_completed <= 0;
					spi_mosi <= 0;
					clk_prescaler <= 0;
					current_mask <= (msb_first) ? (1 << (WORDWIDTH-1)) : 1;
					if (xfer_word_trigger) begin
						data_rx <= 0;
						state <= STATE_XFER_LATCH;
					end
				end
				STATE_XFER_LATCH, STATE_XFER_SAMPLE: begin
					if (clk_prescaler != clk_last) begin
						if (clk_prescaler == 0) begin
							if (state == STATE_XFER_LATCH) begin
								// latch output data
								spi_mosi <= |(data_tx & current_mask);
								spi_clk <= cpol ^ cpha;
							end else begin
								// sample input data
								if (spi_miso_synced) begin
									data_rx <= data_rx | current_mask;
								end
								spi_clk <= !(cpol ^ cpha);
							end
						end
						clk_prescaler <= clk_prescaler + 1;
					end else begin
						clk_prescaler <= 0;
						if (state == STATE_XFER_SAMPLE) begin
							current_mask <= next_mask;
							state <= (|next_mask) ? STATE_XFER_LATCH : STATE_XFER_READY;
						end else begin
							state <= STATE_XFER_SAMPLE;
						end
					end
				end
				STATE_XFER_READY: begin
					// prevent immediate trigger of next word xfer
					if (!xfer_word_trigger) begin
						xfer_word_completed <= 1;
						state <= STATE_XFER_AWAIT;
					end
				end
			endcase
		end else begin
			state <= STATE_XFER_AWAIT;
			spi_clk <= cpol;
			spi_cs <= 0;
			xfer_word_completed <= 0;
			data_rx <= 0;
			spi_mosi <= 0;
		end
	end
endmodule
