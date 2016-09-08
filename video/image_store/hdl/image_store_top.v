module image_store_top(
	clk, rst_n,
	
	din_data, din_ready, din_valid,
	din_startofpacket, din_endofpacket,
	
	dout_data,dout_valid,dout_ready,
	dout_startofpacket,dout_endofpacket,
	
	avm_address, avm_write,
	avm_writedata, avm_waitrequest,
	
	avs_address, avs_read, avs_readdata,
	avs_write, avs_writedata
);

/*
 * register[0][0]	store enable
 * register[1]		reserve
 * register[2]		write address
 * register[3]		write frames count
 */

parameter DATA_WIDTH		= 10;
parameter DIN_WIDTH_LOG	= 4;
parameter AVM_WIDTH_LOG	= 6;
parameter USEDW_MIN		= 2;
parameter STORE_WIDTH	= 3;

input clk, rst_n;

input [DATA_WIDTH-1:0]	din_data;
input 						din_valid;
output 						din_ready;
input 						din_startofpacket;
input 						din_endofpacket;

output [DATA_WIDTH-1:0]	dout_data;
output						dout_valid;
output						dout_startofpacket,dout_endofpacket;
input							dout_ready;

output [31:0]							avm_address;
output 									avm_write;
output [(1<<AVM_WIDTH_LOG)-1:0]	avm_writedata;
input 									avm_waitrequest;

input [1:0]		avs_address;
input 			avs_read;
output [31:0]	avs_readdata;
input 			avs_write;
input [31:0]	avs_writedata;

reg 				sig_en_reg;
wire [31:0]		register[3:0];

wire [DATA_WIDTH-1:0]	wire_data;
wire							wire_valid;
wire							wire_startofpacket;
wire							wire_endofpacket;
wire							wire_ready;

wire [DATA_WIDTH-1:0]	raw_data;
wire							raw_valid;
wire							raw_startofpacket;
wire							raw_endofpacket;
wire							raw_ready;

image_store_avalon_slave #(
	.ADDR_WIDTH(2),
	.REGS_STATE(4'b0011),
	.REGS_NUM(4),
	.REGS_INIT({32'h0, 32'h400000, 32'h0, 32'd0}))
u_slave(
	.clk(clk),
	.rst_n(rst_n),
	
	.av_address(avs_address),
	.av_read(avs_read),
	.av_write(avs_write),
	.av_readdata(avs_readdata),
	.av_writedata(avs_writedata),
	
	.register_signal_in({32'd0, 32'd0, 32'd0, 32'd0}),
	.register_signal_out({register[3], register[2], register[1], register[0]})
);

image_store_splite #(
	.DATA_WIDTH(DATA_WIDTH))
u_splite(
	.clk(clk),
	.rst_n(rst_n),
	
	.din_data(din_data),
	.din_ready(din_ready),
	.din_valid(din_valid),
	.din_startofpacket(din_startofpacket),
	.din_endofpacket(din_endofpacket),
	
	.dout_0_data(dout_data),
	.dout_0_ready(dout_ready),
	.dout_0_valid(dout_valid),
	.dout_0_startofpacket(dout_startofpacket),
	.dout_0_endofpacket(dout_endofpacket),
	
	.dout_1_data(wire_data),
	.dout_1_ready(wire_ready),
	.dout_1_valid(wire_valid),
	.dout_1_startofpacket(wire_startofpacket),
	.dout_1_endofpacket(wire_endofpacket)
);

image_store_decode #(
	.DATA_WIDTH(DATA_WIDTH),
	.COLOR_BITS(DATA_WIDTH),
	.COLOR_PLANES(1))
u_decode(
	.clk(clk),
	.rst_n(rst_n),
	
	.din_data(wire_data),
	.din_valid(wire_valid),
	.din_ready(wire_ready),
	.din_startofpacket(wire_startofpacket),
	.din_endofpacket(wire_endofpacket),
	
	.dout_data(raw_data),
	.dout_valid(raw_valid),
	.dout_ready(raw_ready),
	.dout_startofpacket(raw_startofpacket),
	.dout_endofpacket(raw_endofpacket)
);

image_store_avalon_master #(
	.DATA_WIDTH(DATA_WIDTH),
	.DIN_WIDTH_LOG(DIN_WIDTH_LOG),
	.AVM_WIDTH_LOG(AVM_WIDTH_LOG),
	.USEDW_MIN(USEDW_MIN),
	.STORE_WIDTH(STORE_WIDTH))
u_master(
	.clk(clk),
	.rst_n(rst_n),
	
	.din_data(raw_data),
	.din_ready(raw_ready),
	.din_valid(raw_valid),
	.din_startofpacket(raw_startofpacket),
	.din_endofpacket(raw_endofpacket),
	
	.avm_address(avm_address),
	.avm_write(avm_write),
	.avm_writedata(avm_writedata),
	.avm_waitrequest(avm_waitrequest),
	
	.sig_en(sig_en_reg),
	.sig_address(register[2]),
	.sig_image_cnt(register[3])
);

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		sig_en_reg <= 1'b0;
	else if (avs_write && avs_address==2'd0)
		sig_en_reg <= 1'b1;
	else
		sig_en_reg <= 1'b0;
end

endmodule
