 module dis_pal_buff2pal(
	dis_clk,dis_rst_n,
	dis_data,dis_sync_n,dis_blank_n,
	if_cnt_x,if_cnt_y,
	fifo_rdreq,fifo_q
);

parameter 			DATA_WIDTH		= 10;

parameter [9:0]	CNT_X				= 10'd864;
parameter [9:0]	BLANK_H_BEFORE	= 10'd126;
parameter [9:0]	DIS_X				= 10'd720;
parameter [9:0]	SYNC_SLOT		= 10'd64;

input									dis_clk,dis_rst_n;
output		[DATA_WIDTH-1:0]	dis_data;
output								dis_sync_n,dis_blank_n;

output		[9:0]					if_cnt_x,if_cnt_y;

output								fifo_rdreq;
input			[DATA_WIDTH-1:0]	fifo_q;

reg									dis_sync_n_reg,dis_blank_n_reg;
reg			[9:0]					dis_cnt_x,dis_cnt_y;

wire									f0_rdreq,f1_rdreq;
wire			[9:0]					dis_cnt_x_add;

assign dis_data		= fifo_q;
assign dis_sync_n		= dis_sync_n_reg;
assign dis_blank_n	= dis_blank_n_reg;
assign fifo_rdreq		= f0_rdreq | f1_rdreq;

assign dis_cnt_x_add	= dis_cnt_x + 10'd1;
assign f0_rdreq		= dis_cnt_y>=10'd022 && dis_cnt_y<=10'd309 && dis_cnt_x_add>=BLANK_H_BEFORE && dis_cnt_x_add<BLANK_H_BEFORE+DIS_X;
assign f1_rdreq		= dis_cnt_y>=10'd335 && dis_cnt_y<=10'd622 && dis_cnt_x_add>=BLANK_H_BEFORE && dis_cnt_x_add<BLANK_H_BEFORE+DIS_X;

assign if_cnt_x		= dis_cnt_x;
assign if_cnt_y		= dis_cnt_y;

always @(posedge dis_clk or negedge dis_rst_n)
begin
	if(!dis_rst_n)
	begin
		dis_cnt_x <= 10'd0;
		dis_cnt_y <= 10'd20;
	end
	else if(dis_cnt_x_add>=CNT_X)
	begin
		dis_cnt_x <= 10'd0;
		dis_cnt_y <= dis_cnt_y>=10'd624 ? 10'd0 : dis_cnt_y+10'd1;
	end
	else
	begin
		dis_cnt_x <= dis_cnt_x_add;
		dis_cnt_y <= dis_cnt_y;
	end
end

always @(dis_cnt_x or dis_cnt_y)
begin
	if(dis_cnt_y<=10'd21)
		dis_blank_n_reg = 1'b0;
	else if(dis_cnt_y==10'd22)
		dis_blank_n_reg = (dis_cnt_x<(BLANK_H_BEFORE+CNT_X[9:1]) || dis_cnt_x>=(BLANK_H_BEFORE+DIS_X)) ? 1'b0 : 1'b1;
	else if(dis_cnt_y>=10'd310 && dis_cnt_y<=10'd334)
		dis_blank_n_reg = 1'b0;
	else if(dis_cnt_y==10'd622)
		dis_blank_n_reg = (dis_cnt_x<BLANK_H_BEFORE || dis_cnt_x>=(DIS_X+BLANK_H_BEFORE-CNT_X[9:1])) ? 1'b0 : 1'b1;
	else if(dis_cnt_y >= 10'd623)
		dis_blank_n_reg = 1'b0;
	else if(dis_cnt_x<BLANK_H_BEFORE || dis_cnt_x>=(BLANK_H_BEFORE+DIS_X))
		dis_blank_n_reg = 1'b0;
	else
		dis_blank_n_reg = 1'b1;
end

always @(dis_cnt_x or dis_cnt_y)
begin
	case(dis_cnt_y)
	10'd000,
	10'd001,
	10'd313,
	10'd314:begin
		if(dis_cnt_x<(CNT_X[9:1]-SYNC_SLOT))
			dis_sync_n_reg = 1'b0;
		else if(dis_cnt_x<CNT_X[9:1])
			dis_sync_n_reg = 1'b1;
		else if(dis_cnt_x<(CNT_X-SYNC_SLOT))
			dis_sync_n_reg = 1'b0;
		else
			dis_sync_n_reg = 1'b1;
	end
	
	10'd003,
	10'd004,
	10'd310,
	10'd311,
	10'd315,
	10'd316,
	10'd623,
	10'd624:begin
		if(dis_cnt_x<SYNC_SLOT[9:1])
			dis_sync_n_reg = 1'b0;
		else if(dis_cnt_x<CNT_X[9:1])
			dis_sync_n_reg = 1'b1;
		else if(dis_cnt_x<(CNT_X[9:1]+SYNC_SLOT[9:1]))
			dis_sync_n_reg = 1'b0;
		else
			dis_sync_n_reg = 1'b1;	
	end
	
	10'd002:begin
		if(dis_cnt_x<(CNT_X[9:1]-SYNC_SLOT))
			dis_sync_n_reg = 1'b0;
		else if(dis_cnt_x<CNT_X[9:1])
			dis_sync_n_reg = 1'b1;
		else if(dis_cnt_x<(CNT_X[9:1]+SYNC_SLOT[9:1]))
			dis_sync_n_reg = 1'b0;
		else
			dis_sync_n_reg = 1'b1;	
	end
	10'd312:begin
		if(dis_cnt_x<SYNC_SLOT[9:1])
			dis_sync_n_reg = 1'b0;
		else if(dis_cnt_x<CNT_X[9:1])
			dis_sync_n_reg = 1'b1;
		else if(dis_cnt_x<(CNT_X-SYNC_SLOT))
			dis_sync_n_reg = 1'b0;
		else
			dis_sync_n_reg = 1'b1;	
	end
	10'd317:begin
		if(dis_cnt_x<SYNC_SLOT[9:1])
			dis_sync_n_reg = 1'b0;
		else
			dis_sync_n_reg = 1'b1;
	end
	10'd622:begin
		if(dis_cnt_x<SYNC_SLOT)
			dis_sync_n_reg = 1'b0;
		else if(dis_cnt_x<CNT_X[9:1])
			dis_sync_n_reg = 1'b1;
		else if(dis_cnt_x<(CNT_X[9:1]+SYNC_SLOT[9:1]))
			dis_sync_n_reg = 1'b0;
		else
			dis_sync_n_reg = 1'b1;	
	end
	
	default:begin
		if(dis_cnt_x<SYNC_SLOT)
			dis_sync_n_reg = 1'b0;
		else
			dis_sync_n_reg = 1'b1;
	end
	endcase
end

endmodule
