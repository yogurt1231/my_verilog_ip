module image_store_avalon_master(
	clk, rst_n,
	
	din_data, din_ready, din_valid,
	din_startofpacket, din_endofpacket,
	
	avm_address, avm_write,
	avm_writedata, avm_waitrequest,
	
	sig_en, sig_address, sig_image_cnt
);

parameter DIN_WIDTH		= 10;
parameter AVM_WIDTH_LOG	= 4;
parameter STORE_WIDTH	= 4;

localparam AVM_ADDR_ADD = 1<<(AVM_WIDTH_LOG-3);

input clk, rst_n;

input [DIN_WIDTH-1:0]	din_data;
input 						din_valid;
output 						din_ready;
input 						din_startofpacket;
input 						din_endofpacket;

output [31:0]							avm_address;
output 									avm_write;
output [(1<<AVM_WIDTH_LOG)-1:0]	avm_writedata;
input 									avm_waitrequest;

input 						sig_en;
input [31:0]				sig_address;
input [STORE_WIDTH-1:0]	sig_image_cnt;

reg [STORE_WIDTH-1:0]	image_cnt;

reg 			avm_write_reg;
reg [31:0]	avm_address_reg;
reg [31:0]	avm_address_cnt;
wire [31:0]	avm_address_add;
reg [DIN_WIDTH-1:0]	din_data_reg;

reg [1:0]	state, n_state;

localparam IDLE	= 2'd0;
localparam WAIT	= 2'd1;
localparam WRITE	= 2'd2;
localparam MIN		= 2'd3;

assign avm_address_add = avm_address_cnt + AVM_ADDR_ADD;

assign din_ready = ~avm_waitrequest;
assign avm_address = avm_address_reg + avm_address_cnt;
assign avm_write = state==WRITE ? din_valid | avm_write_reg : n_state==WRITE;
assign avm_writedata = avm_write_reg ? din_data_reg : din_data;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or image_cnt or din_startofpacket or din_endofpacket or din_valid)
begin
	case (state)
	IDLE: n_state = image_cnt=={STORE_WIDTH{1'b0}} ? IDLE : WAIT;
	WAIT: n_state = (din_startofpacket & din_valid) ? WRITE : WAIT;
	WRITE: n_state = (din_endofpacket & din_valid) ? MIN : WRITE;
	MIN: n_state = IDLE;
	default: n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		avm_address_cnt <= 32'd0;
	else if (state==IDLE && image_cnt=={STORE_WIDTH{1'b0}})
		avm_address_cnt <= 32'd0;
	else if (avm_write & ~avm_waitrequest)
		avm_address_cnt <= avm_address_add;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		avm_write_reg <= 1'b0;
	else if (avm_write_reg)
		avm_write_reg <= avm_waitrequest;
	else
		avm_write_reg <= din_valid & avm_waitrequest;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		din_data_reg <= {DIN_WIDTH{1'b0}};
	else if (din_valid & avm_waitrequest)
		din_data_reg <= din_data;
	else
		din_data_reg <= avm_write_reg ? din_data_reg : din_data;
end
		
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		image_cnt <= {STORE_WIDTH{1'b0}};
	else if (state == IDLE)
		image_cnt <= sig_en ? sig_image_cnt : image_cnt;
	else if (state == MIN)
		image_cnt <= image_cnt - 1'b1;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		avm_address_reg <= 32'd0;
	else if (sig_en)
		avm_address_reg <= sig_address;
end

endmodule
