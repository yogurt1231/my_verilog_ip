module avalon_slave_to_wb_master(
	clk, rst_n,
	
	av_address, av_chipselect,
	av_byteenable,
	av_read, av_write,
	av_readdata, av_readdatavalid,
	av_writedata, av_waitrequest,
	
	wb_cyc_o, wb_stb_o, wb_we_o,
	wb_adr_o, wb_dat_o, wb_dat_i,
	wb_sel_o, wb_ack_i
);

parameter	ADDR_WIDTH = 32;
parameter	DATA_WIDTH = 32;
parameter	DATA_BYTES = 4;

input 						clk, rst_n;

input [ADDR_WIDTH-1:0]	av_address;
input 						av_chipselect;
input [DATA_BYTES-1:0]	av_byteenable;
input 						av_read, av_write;
output [DATA_WIDTH-1:0]	av_readdata;
output 						av_readdatavalid;
input [DATA_WIDTH-1:0]	av_writedata;
output 						av_waitrequest;

output 						wb_cyc_o, wb_stb_o, wb_we_o;
output [ADDR_WIDTH-1:0]	wb_adr_o;
output [DATA_WIDTH-1:0]	wb_dat_o;
input [DATA_WIDTH-1:0]	wb_dat_i;
output [DATA_BYTES-1:0]	wb_sel_o;
input 						wb_ack_i;

reg [ADDR_WIDTH-1:0]	wb_adr_o_reg;
reg [DATA_WIDTH-1:0]	wb_dat_o_reg;
reg [DATA_BYTES-1:0]	wb_sel_o_reg;

reg [1:0]	state, next_state;

localparam IDLE = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

assign wb_cyc_o = state == IDLE ? av_chipselect : 1'b1;
assign wb_stb_o = state == IDLE ? (av_chipselect & (av_read | av_write)) : 1'b1;
assign wb_we_o = state == IDLE ? (av_chipselect & av_write) : state == WRITE;
assign wb_adr_o = state == IDLE ? av_address : wb_adr_o_reg;
assign wb_dat_o = state == IDLE ? av_writedata : wb_dat_o_reg;
assign wb_sel_o = state == IDLE ? av_byteenable : wb_sel_o_reg;
assign av_readdata = wb_dat_i;
assign av_readdatavalid = state==READ && wb_ack_i;
assign av_waitrequest = state != IDLE;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end

always @(state or av_chipselect or av_read or av_write or wb_ack_i)
begin
	case (state)
	IDLE: begin
		if (av_chipselect & av_write)
			next_state = wb_ack_i ? IDLE : WRITE;
		else if (av_chipselect & av_read)
			next_state = READ;
		else
			next_state = IDLE;
	end
	READ: next_state = wb_ack_i ? IDLE : READ;
	WRITE: next_state = wb_ack_i ? IDLE : WRITE;
	default: next_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		wb_adr_o_reg <= 'd0;
		wb_dat_o_reg <= 'd0;
		wb_sel_o_reg <= 'd0;
	end
	else if (state==IDLE) begin
		wb_adr_o_reg <= av_address;
		wb_dat_o_reg <= av_writedata;
		wb_sel_o_reg <= av_byteenable;
	end
end

endmodule
