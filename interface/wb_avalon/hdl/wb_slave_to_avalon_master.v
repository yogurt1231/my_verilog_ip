module wb_slave_to_avalon_master(
	clk, rst_n,
	
	wb_cyc_i, wb_stb_i, wb_we_i,
	wb_adr_i, wb_dat_i, wb_dat_o,
	wb_sel_i, wb_ack_o,
	
	av_chipselect, av_byteenable,
	av_address, 
	av_read, av_write,
	av_readdata, av_readdatavalid,
	av_writedata, av_waitrequest
);

parameter	ADDR_WIDTH = 32;
parameter	DATA_WIDTH = 32;
parameter	DATA_BYTES = 4;

input		clk, rst_n;

input								wb_cyc_i, wb_stb_i, wb_we_i;
input 	[ADDR_WIDTH-1:0]	wb_adr_i;
input 	[DATA_WIDTH-1:0]	wb_dat_i;
output 	[DATA_WIDTH-1:0]	wb_dat_o;
input 	[DATA_BYTES-1:0]	wb_sel_i;
output 							wb_ack_o;

output 							av_chipselect;
output 	[DATA_BYTES-1:0]	av_byteenable;
output 	[ADDR_WIDTH-1:0]	av_address;
output 							av_read, av_write;
input 	[DATA_WIDTH-1:0]	av_readdata;
input 							av_readdatavalid;
output 	[DATA_WIDTH-1:0]	av_writedata;
input 							av_waitrequest;

assign av_chipselect = wb_cyc_i;
assign av_byteenable = wb_sel_i;
assign av_address = wb_adr_i;
assign av_writedata = wb_dat_i;
assign wb_dat_o = av_readdata;
assign av_read = state==IDLE && (wb_cyc_i & wb_stb_i & ~wb_we_i);
assign av_write = state==IDLE && (wb_cyc_i & wb_stb_i & wb_we_i);
assign wb_ack_o = state==WRITE_WAIT | av_readdatavalid;

reg [1:0]	state, next_state;

localparam	IDLE = 2'b00;
localparam	READ_WAIT = 2'b01;
localparam	WRITE_WAIT = 2'b10;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end

always @(state or wb_cyc_i or wb_stb_i or wb_we_i or av_waitrequest or av_readdatavalid)
begin
	case (state)
	IDLE: next_state = (wb_cyc_i & wb_stb_i &  ~av_waitrequest) ? (wb_we_i ? WRITE_WAIT : READ_WAIT) : IDLE;
	READ_WAIT: next_state = av_readdatavalid ? IDLE : READ_WAIT;
	WRITE_WAIT: next_state = IDLE;
	default: next_state = IDLE;
	endcase
end

endmodule
