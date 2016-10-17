module blind_pixel_top (
	clk, rst_n,
	
	av_address, av_write, av_writedata,
	
	ram_address, ram_write, ram_writedata,
	ram_read, ram_readdata, ram_byteenable,
	
	din_data, din_ready, din_valid,
	din_startofpacket, din_endofpacket,
	
	dout_data, dout_ready, dout_valid,
	dout_startofpacket, dout_endofpacket
);

parameter DATA_WIDTH = 10;

input				clk, rst_n;

input [1:0]		av_address;
input 			av_write;
input [31:0]	av_writedata;

input [7:0]		ram_address;
input 			ram_write;
input [31:0]	ram_writedata;
input 			ram_read;
input [3:0]		ram_byteenable;
output [31:0]	ram_readdata;

input [DATA_WIDTH-1:0]	din_data;
output 						din_ready;
input 						din_valid;
input 						din_startofpacket;
input 						din_endofpacket;

output [DATA_WIDTH-1:0]	dout_data;
input 						dout_ready;
output 						dout_valid;
output 						dout_startofpacket;
output 						dout_endofpacket;

wire [DATA_WIDTH-1:0]	decode_data;
wire 							decode_ready, decode_valid;
wire 							decode_startofpacket;
wire 							decode_endofpacket;

wire [DATA_WIDTH-1:0]	encode_data;
wire 							encode_ready, encode_valid;
wire 							encode_startofpacket;
wire 							encode_endofpacket;

wire [15:0]					im_height, im_width;
wire [3:0]					im_interlaced;

localparam	MODE_VIDEO = 2'b00;
localparam	MODE_BLIND = 2'b01;
localparam	MODE_BACK = 2'b10;
localparam	MODE_TEST = 2'b11;

wire 			proc_read;
wire [7:0]	proc_address;
wire [31:0]	proc_readdata;

reg [1:0]				reg_mode;
reg [DATA_WIDTH-1:0]	reg_background;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		reg_mode <= MODE_BLIND;
		reg_background <= {DATA_WIDTH{1'b1}};
	end
	else if (av_write) begin
		case (av_address)
		2'd0: reg_mode <= av_writedata[1:0];
		2'd2: reg_background <= av_writedata[DATA_WIDTH-1:0];
		endcase
	end
end

blind_pixel_ram  u_ram(
	.clk(clk),
	.address(ram_address),
	.byteenable(ram_byteenable),
	.write(ram_write),
	.writedata(ram_writedata),
	.readdata(ram_readdata),
  
	.clk2(clk),
	.address2(proc_address),
	.byteenable2(4'hF),
	.write2(1'b0),
	.writedata2(32'd0),
	.readdata2(proc_readdata)
);

blind_pixel_proc #(
	.DATA_WIDTH(DATA_WIDTH),
	.MODE_VIDEO(MODE_VIDEO),
	.MODE_BLIND(MODE_BLIND),
	.MODE_BACK(MODE_BACK),
	.MODE_TEST(MODE_TEST))
u_proc (
	.clk(clk),
	.rst_n(rst_n),
	
	.ram_read(),
	.ram_address(proc_address),
	.ram_readdata(proc_readdata),
	
	.reg_mode(reg_mode),
	.reg_background(reg_background),
	
	.din_data(decode_data),
	.din_valid(decode_valid),
	.din_startofpacket(decode_startofpacket),
	.din_endofpacket(decode_endofpacket),
	.din_ready(decode_ready),
	
	.dout_data(encode_data),
	.dout_valid(encode_valid),
	.dout_startofpacket(encode_startofpacket),
	.dout_endofpacket(encode_endofpacket),
	.dout_ready(encode_ready)
);

blind_pixel_decode #(
	.DATA_WIDTH(DATA_WIDTH),
	.COLOR_BITS(DATA_WIDTH),
	.COLOR_PLANES(1))
u_decode (
	.clk(clk),
	.rst_n(rst_n),
	
	.din_data(din_data),
	.din_valid(din_valid),
	.din_ready(din_ready),
	.din_startofpacket(din_startofpacket),
	.din_endofpacket(din_endofpacket),
	
	.im_width(im_width),
	.im_height(im_height),
	.im_interlaced(im_interlaced),
	
	.dout_data(decode_data),
	.dout_valid(decode_valid),
	.dout_ready(decode_ready),
	.dout_startofpacket(decode_startofpacket),
	.dout_endofpacket(decode_endofpacket)
);

blind_pixel_encode #(
	.DATA_WIDTH(DATA_WIDTH),
	.DATA_BITS(DATA_WIDTH),
	.DATA_PLANES(1))
u_encode (
	.clk(clk),
	.rst_n(rst_n),
	
	.video_width(im_width),
	.video_height(im_height),
	.video_interlaced(im_interlaced),
	
	.din_data(encode_data),
	.din_valid(encode_valid),
	.din_ready(encode_ready),
	.din_startofpacket(encode_startofpacket),
	.din_endofpacket(encode_endofpacket),
	
	.dout_data(dout_data),
	.dout_valid(dout_valid),
	.dout_ready(dout_ready),
	.dout_startofpacket(dout_startofpacket),
	.dout_endofpacket(dout_endofpacket)
);

endmodule
