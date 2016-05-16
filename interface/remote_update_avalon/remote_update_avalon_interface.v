module remote_update_avalon_interface(
	clk,rst_n,
	
	av_address,av_waitrequest,
	av_write,av_writedata,
	av_read,av_readdata,av_readdatavalid,
	
	ru_read_param,ru_write_param,ru_param,
	ru_datain,ru_source,ru_reset,ru_busy,ru_dataout
);

input					clk,rst_n;

input		[5:0]		av_address;
input					av_read,av_write;
input		[31:0]	av_writedata;
output	[31:0]	av_readdata;
output				av_readdatavalid,av_waitrequest;

output				ru_read_param,ru_write_param;
output	[2:0]		ru_param;
output	[21:0]	ru_datain;
output	[1:0]		ru_source;
output				ru_reset;
input					ru_busy;
input		[28:0]	ru_dataout;

reg					state,n_state;

assign ru_reset = ~rst_n;
assign {ru_source,ru_param} = {av_address[5:4],av_address[2:0]};
assign {ru_read_param,ru_write_param} = {av_read,av_write};
assign ru_datain = av_writedata[21:0];
assign av_readdata = {3'd0,ru_dataout};
assign av_waitrequest = ru_busy;
assign av_readdatavalid = (state==1'b1) && (~ru_busy);

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		state <= 1'b0;
	else
		state <= n_state;
end

always @(state or av_read or ru_busy)
begin
	case(state)
	1'b0:n_state = av_read ? 1'b1 : 1'b0;
	1'b1:n_state = ru_busy ? 1'b1 : 1'b0;
	default:n_state = 1'b0;
	endcase
end

endmodule
