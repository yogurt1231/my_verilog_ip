module image_store_splite(
	clk, rst_n,
	
	din_data, din_ready, din_valid,
	din_startofpacket, din_endofpacket,
	
	dout_0_data, dout_0_ready, dout_0_valid,
	dout_0_startofpacket, dout_0_endofpacket,
	
	dout_1_data, dout_1_ready, dout_1_valid,
	dout_1_startofpacket, dout_1_endofpacket
);

parameter DATA_WIDTH = 10;

input clk, rst_n;

input [DATA_WIDTH-1:0]	din_data;
input 						din_valid;
output 						din_ready;
input 						din_startofpacket;
input 						din_endofpacket;

output [DATA_WIDTH-1:0]	dout_0_data;
output 						dout_0_valid;
input 						dout_0_ready;
output 						dout_0_startofpacket;
output 						dout_0_endofpacket;

output [DATA_WIDTH-1:0]	dout_1_data;
output 						dout_1_valid;
input 						dout_1_ready;
output 						dout_1_startofpacket;
output 						dout_1_endofpacket;

assign dout_0_data = din_data;
assign dout_0_valid = din_valid;
assign dout_0_startofpacket = din_startofpacket;
assign dout_0_endofpacket = din_endofpacket;

assign dout_1_data = din_data;
assign dout_1_valid = din_valid;
assign dout_1_startofpacket = din_startofpacket;
assign dout_1_endofpacket = din_endofpacket;

assign din_ready = dout_0_ready & dout_1_ready;

endmodule
