module GB_state(
	clk,rst_n,
	din_valid,
	din_startofpacket,din_endofpacket,
	state_idle,state_gray_stat,
	state_map_comp,state_cnt
);

parameter	DIN_WIDTH = 14;

input		clk,rst_n;
input		din_valid;
input		din_startofpacket,din_endofpacket;

output	state_idle,state_gray_stat,state_map_comp;
output	[DIN_WIDTH-1:0]	state_cnt;

reg		[DIN_WIDTH-1:0]	cnt;
wire		[DIN_WIDTH-1:0]	cnt_add;

reg		[2:0]	state,n_state;

localparam	IDLE = 3'b001;
localparam	GRAY_STAT = 3'b010;
localparam	MAP_COMP = 3'b100;

assign cnt_add = cnt + 'd1;

assign state_idle = state==IDLE;
assign state_gray_stat = state==GRAY_STAT;
assign state_map_comp = state==MAP_COMP;
assign state_cnt = cnt;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(din_valid or din_startofpacket or din_endofpacket or cnt_add)
begin
	case(state)
	IDLE:			n_state = (din_startofpacket & din_valid) ? GRAY_STAT : IDLE;
	GRAY_STAT:	n_state = (din_endofpacket & din_valid) ? MAP_COMP : GRAY_STAT;
	MAP_COMP:	n_state = (cnt_add=='d0) ? IDLE : MAP_COMP;
	default:		n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt <= 'd0;
	else if(state==MAP_COMP)
		cnt <= cnt_add;
end

endmodule
