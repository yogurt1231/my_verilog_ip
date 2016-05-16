module pll_avalon_module(
	clk,rst_n,
	
	av_address,av_read,av_write,
	av_readdata,av_writedata,
	av_readdatavalid,av_waitrequest,
	
	pll_phasedone,pll_locked,
	pll_pfdena,pll_areset,
	pll_phasecounterselect,
	pll_phaseupdown,pll_phasestep
);

input clk,rst_n;

input 			[1:0] 	av_address;
input 						av_read,av_write;
input 			[31:0] 	av_writedata;
output	reg	[31:0] 	av_readdata;
output	reg				av_readdatavalid;
output						av_waitrequest;

input 						pll_phasedone,pll_locked;
output	reg 				pll_pfdena,pll_areset;
output						pll_phasestep,pll_phaseupdown;
output			[2:0] 	pll_phasecounterselect;

reg 				[3:0]		n_state;
reg				[1:0]		phase;
reg				[8:0]		counter_number;
reg				[1:0]		stepcnt;

localparam	IDLE				= 4'b0001;
localparam	READ				= 4'b0010;
localparam	WRITE_CONTROL	= 4'b0100;
localparam	WRITE_PHASE		= 4'b1000;

assign pll_phasestep				= stepcnt ? 1'b1 : 1'b0;
assign pll_phaseupdown			= phase[0];
assign pll_phasecounterselect	= counter_number[2:0]+{counter_number[8],1'b0};
assign av_waitrequest			= pll_phasestep;

always @(av_read or av_write or av_address or pll_phasedone)
begin
	if(av_read)
		n_state = READ;
	else if(av_write)
	begin
		case(av_address)
		2'd1:n_state = WRITE_CONTROL;
		2'd2:n_state = WRITE_PHASE;
		default:n_state = IDLE;
		endcase
	end
	else
		n_state = IDLE;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		av_readdata <= 32'd0;
	else if(n_state==READ)
	begin
		case(av_address)
		2'd0:av_readdata <= {30'd0,pll_phasedone,pll_locked};
		2'd1:av_readdata <= {30'd0,pll_pfdena,pll_areset};
		2'd2:av_readdata <= {phase,21'd0,counter_number};
		default:av_readdata <= 32'd0;
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		{pll_pfdena,pll_areset} <= 2'b10;
	else if(n_state==WRITE_CONTROL)
		{pll_pfdena,pll_areset} <= av_writedata[1:0];
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		{phase,counter_number} <= 11'd0;
	else if(n_state==WRITE_PHASE)
		{phase,counter_number} <= {av_writedata[31:30],av_writedata[8:0]};
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		stepcnt <= 2'd0;
	else if((n_state==WRITE_PHASE) && (av_writedata[31]^av_writedata[30]))
		stepcnt <= 2'd1;
	else if(stepcnt)
		stepcnt <= stepcnt + 2'd1;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		av_readdatavalid <= 1'b0;
	else
		av_readdatavalid <= n_state==READ;
end

endmodule
