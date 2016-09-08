module brightness_control_top(
	clk, rst_n,
	
	din_data, din_ready, din_valid,
	din_startofpacket, din_endofpacket,
	
	dout_data, dout_ready, dout_valid,
	dout_startofpacket, dout_endofpacket,
	
	avs_address, avs_write, avs_writedata
);

/*	
 * register[2][0]			invert
 * register[3][15:0]		brightness
 */

parameter DATA_WIDTH = 10;

input clk, rst_n;

input [DATA_WIDTH-1:0]	din_data;
input 						din_valid;
output 						din_ready;
input 						din_startofpacket;
input 						din_endofpacket;

output [DATA_WIDTH-1:0]	dout_data;
output 						dout_valid;
input 						dout_ready;
output 						dout_startofpacket;
output 						dout_endofpacket;

input [1:0]					avs_address;
input 						avs_write;
input [31:0]				avs_writedata;

wire [DATA_WIDTH-1:0]	decode_data;
wire 							decode_ready, decode_valid;
wire 							decode_startofpacket;
wire 							decode_endofpacket;

wire [DATA_WIDTH-1:0]	encode_data;
wire 							encode_ready, encode_valid;
wire 							encode_startofpacket;
wire 							encode_endofpacket;

wire [15:0]					im_width, im_height;
wire [3:0]					im_interlaced;

wire [DATA_WIDTH:0]		add_data;
reg [DATA_WIDTH-1:0]		brightness_data;
reg [31:0]					register[4];

assign add_data = decode_data + register[3][DATA_WIDTH:0];
assign encode_data = register[2][0] ? ~brightness_data : brightness_data;

assign encode_startofpacket = decode_startofpacket;
assign encode_endofpacket = decode_endofpacket;
assign encode_valid = decode_valid;
assign decode_ready = encode_ready;

always @(add_data or register[3][DATA_WIDTH])
begin
	case ({add_data[DATA_WIDTH], register[3][DATA_WIDTH]})
	2'b00:brightness_data = add_data[DATA_WIDTH-1:0];
	2'b01:brightness_data = add_data[DATA_WIDTH-1:0];
	2'b10:brightness_data = {DATA_WIDTH{1'b1}};
	2'b11:brightness_data = {DATA_WIDTH{1'b0}};
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		register[0] <= 32'd0;
		register[1] <= 32'd0;
		register[2] <= 32'd0;
		register[3] <= 32'd0;
	end
	else if (avs_write)
		register[avs_address] <= avs_writedata;
end

brightness_control_decode #(
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

brightness_control_encode #(
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
