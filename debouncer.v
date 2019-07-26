`default_nettype none

// input debouncer.
// if CLOCKED_EDGE_OUT, it yields a rising edge on the output
// indicate a button press and nothing when the button is released.
// the value will be high for only a single clock cycle.
// if not CLOCKED_EDGE_OUT, it yields the debounced value of the input.
// INPUT_WHEN_IDLE should be set to the value that the line has
// when no button is pressed. this avoids an initial button press
// when the FPGA is started.
module debouncer(
	input wire clk,
	input wire in,
	output reg out = 0);

	parameter INPUT_WHEN_IDLE = 1;
	parameter DEBOUNCE_CYCLES = 1000;
	parameter CLOCKED_EDGE_OUT = 0;

	reg old = INPUT_WHEN_IDLE;
	reg running = 0;
	reg [$clog2(DEBOUNCE_CYCLES+1)-1 : 0] decay = 0;

	always @(posedge clk) begin
		if(old != in) begin
			running <= 1;
			decay <= DEBOUNCE_CYCLES;
		end else begin
			if(running) begin
				decay <= decay - 1;
				if(decay == 0) begin
					running <= 0;
					if(CLOCKED_EDGE_OUT) begin
						out <= (INPUT_WHEN_IDLE) ? ~in : in;
					end else begin
						out <= in;
					end
				end else begin
					if(CLOCKED_EDGE_OUT) begin
						out <= 0;
					end
				end
			end else begin
				if(CLOCKED_EDGE_OUT) begin
					out <= 0;
				end
			end
		end

		old <= in;
	end

endmodule

