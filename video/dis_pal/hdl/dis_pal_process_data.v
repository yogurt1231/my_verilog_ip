module dis_pal_process_data(
	vst_clk, vst_rst_n,
	
	vst_data, vst_valid, vst_ready,
	vst_startofpacket, vst_endofpacket,
	
	fifo_data, fifo_wrreq,
	fifo_usedw, fifo_aclr,
	
	dis_rst_n
);

parameter			DATA_WIDTH	= 10;
parameter [9:0]	PAL_WIDTH	= 720;
parameter [23:0]	FRAME_NUM	= 2_000_000;

parameter [23:0]	THRESHOLD_A	= 1_929_600;
parameter [23:0]	THRESHOLD_B	= 0_003_200;
parameter [23:0]	THRESHOLD_C	= 0_928_000;
parameter [23:0]	THRESHOLD_D	= 1_004_800;

input 						vst_clk;
input 						vst_rst_n;

input [DATA_WIDTH-1:0]	vst_data;
input 						vst_valid;
output 						vst_ready;
input 						vst_startofpacket;
input 						vst_endofpacket;

output [DATA_WIDTH-1:0]	fifo_data;
output 						fifo_wrreq;
input [9:0]					fifo_usedw;
output 						fifo_aclr;

output 						dis_rst_n;

reg [3:0]	rst_state_cnt;
reg [9:0]	dis_x, dis_y;
reg [23:0]	frame_cnt;

wire [23:0]	frame_add;
wire [3:0]	frame_th;
wire [9:0]	dis_x_add, dis_y_add;

assign frame_th[0] = frame_cnt>THRESHOLD_A || frame_cnt<=THRESHOLD_B;	/* pre F0 */
assign frame_th[1] = frame_cnt>THRESHOLD_B && frame_cnt<=THRESHOLD_C;	/* F0 */
assign frame_th[2] = frame_cnt>THRESHOLD_C && frame_cnt<=THRESHOLD_D;	/* pre F1 */
assign frame_th[3] = frame_cnt>THRESHOLD_D && frame_cnt<=THRESHOLD_A;	/* F1 */

assign frame_add = frame_cnt + 24'd1;
assign dis_x_add = dis_x + 10'd1;
assign dis_y_add = dis_y + 10'd1;

assign fifo_data = vst_data;
assign fifo_aclr = ~vst_rst_n;
assign dis_rst_n = rst_state_cnt == 4'h0;
assign fifo_wrreq = vst_valid & ((frame_th[0] | frame_th[1]) ^ dis_y[0]);
assign vst_ready = fifo_usedw<=PAL_WIDTH && (frame_th[0] || frame_th[2] || dis_y<10'd576);

always @(posedge vst_clk or negedge vst_rst_n)
begin
	if (!vst_rst_n)
		rst_state_cnt <= 4'h0;
	else if (rst_state_cnt != 4'h0)
		rst_state_cnt <= rst_state_cnt - 4'h1;
	else if (vst_valid & vst_startofpacket & (frame_th[1] | frame_th[3])) 
		rst_state_cnt <= 4'hF;
end

always @(posedge vst_clk or negedge vst_rst_n)
begin
	if (!vst_rst_n)
		frame_cnt <= 24'd0;
	else if (rst_state_cnt!=4'h0 || frame_add==FRAME_NUM)
		frame_cnt <= 24'd0;
	else
		frame_cnt <= frame_add;
end

always @(posedge vst_clk or negedge vst_rst_n)
begin
	if (!vst_rst_n) begin
		dis_x <= 10'd0;
		dis_y <= 10'd0;
	end
	else if (vst_valid) begin
		if (vst_startofpacket) begin
			dis_x <= 10'd1;
			dis_y <= 10'd0;
		end
		else if (dis_x_add == PAL_WIDTH) begin
			dis_x <= 10'd0;
			dis_y <= dis_y_add;
		end
		else begin
			dis_x <= dis_x_add;
			dis_y <= dis_y;
		end
	end
end

endmodule
