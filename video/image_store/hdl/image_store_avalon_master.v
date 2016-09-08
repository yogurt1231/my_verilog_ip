module image_store_avalon_master(
	clk, rst_n,
	
	din_data, din_ready, din_valid,
	din_startofpacket, din_endofpacket,
	
	avm_address, avm_write,
	avm_writedata, avm_waitrequest,
	
	sig_en, sig_address, sig_image_cnt
);

parameter DATA_WIDTH		= 10;
parameter DIN_WIDTH_LOG	= 16;
parameter AVM_WIDTH_LOG	= 4;
parameter USEDW_MIN		= 2;
parameter STORE_WIDTH	= 4;

localparam AVM_ADDR_ADD = 1<<(AVM_WIDTH_LOG-3);

input clk, rst_n;

input [DATA_WIDTH-1:0]	din_data;
input 						din_valid;
output 						din_ready;
input 						din_startofpacket;
input 						din_endofpacket;

output [31:0]							avm_address;
output reg								avm_write;
output [(1<<AVM_WIDTH_LOG)-1:0]	avm_writedata;
input 									avm_waitrequest;

input 						sig_en;
input [31:0]				sig_address;
input [STORE_WIDTH-1:0]	sig_image_cnt;

reg [2:0]					state, n_state;

reg [STORE_WIDTH-1:0]	image_cnt;
reg [31:0]					avm_address_reg;
reg [31:0]					avm_address_cnt;
wire [31:0]					avm_address_add;

wire 			fifo_wrreq;
wire 			fifo_rdreq;
wire 			fifo_rdempty;
wire [7:0]	fifo_wrusedw;

localparam	IDLE = 3'd0;
localparam	WAIT = 3'd1;
localparam	WRITE = 3'd2;
localparam	MIN = 3'd3;

assign din_ready = ~(&fifo_wrusedw[7:6]);
assign fifo_wrreq = (state==WRITE || n_state==WRITE) && din_valid;
assign fifo_rdreq = ~((avm_waitrequest & avm_write) | fifo_rdempty);

assign avm_address = avm_address_reg + avm_address_cnt;
assign avm_address_add = avm_address_cnt + AVM_ADDR_ADD;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		avm_write <= 1'b0;
	else if (~(avm_waitrequest & avm_write))
		avm_write <= fifo_rdreq;
end

image_store_fifo #(
	.DIN_WIDTH(1<<DIN_WIDTH_LOG),
	.DOUT_WIDTH(1<<AVM_WIDTH_LOG),
	.USEDW_MIN(USEDW_MIN))
u_fifo (
	.wrclk(clk),
	.wrreq(fifo_wrreq),
	.data(din_data),
	.wrusedw(fifo_wrusedw),
	
	.rdclk(clk),
	.rdreq(fifo_rdreq),
	.q(avm_writedata),
	.rdempty(fifo_rdempty),
	
	.aclr(~rst_n)
);

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or image_cnt or din_valid or din_startofpacket or din_endofpacket)
begin
	case (state)
	IDLE: n_state = image_cnt=={STORE_WIDTH{1'b0}} ? IDLE : WAIT;
	WAIT: n_state = din_valid & din_startofpacket ? WRITE : WAIT;
	WRITE: n_state = din_valid & din_endofpacket ? MIN : WRITE;
	MIN: n_state = IDLE;
	default: n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		image_cnt <= {STORE_WIDTH{1'b0}};
	else if (state==IDLE && sig_en)
		image_cnt <= sig_image_cnt;
	else if (state==MIN)
		image_cnt <= image_cnt - 1'b1;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		avm_address_cnt <= 32'd0;
	else if (sig_en)
		avm_address_cnt <= 32'd0;
	else if (avm_write & ~avm_waitrequest)
		avm_address_cnt <= avm_address_add;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		avm_address_reg <= 32'd0;
	else if (sig_en)
		avm_address_reg <= sig_address;
end

endmodule
