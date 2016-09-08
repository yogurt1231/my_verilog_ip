module rvbridge_read_fifo(
	clk,
	rst_n,
	
	fifo_aclr,
	fifo_rdreq,
	fifo_empty,
	fifo_usedw,
	
	vst_ready,
	vst_valid
);

parameter FIFO_USED_WIDTH = 10;
parameter FIFO_BUFFER_NUM = 512;

input 								clk;
input 								rst_n;
	
output 								fifo_aclr;
output 								fifo_rdreq;
input 								fifo_empty;
input [FIFO_USED_WIDTH-1:0]	fifo_usedw;
	
input 								vst_ready;
output reg 							vst_valid;

reg		vst_valid_reg;

reg [1:0] state, n_state;

assign fifo_aclr = ~rst_n;
assign fifo_rdreq = vst_ready && ~fifo_empty && state==VOUT;

localparam BUFFER = 2'd0;
localparam VOUT = 2'd1;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		vst_valid <= 1'b0;
	else
		vst_valid <= fifo_rdreq;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		state <= BUFFER;
	else
		state <= n_state;
end

always @(state or fifo_usedw)
begin
	case (state)
	BUFFER: n_state = fifo_usedw < FIFO_BUFFER_NUM ? BUFFER : VOUT;
	VOUT:	n_state = VOUT;
	default: n_state = BUFFER;
	endcase
end

endmodule
