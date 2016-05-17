module dis_pal_delay(
	clk,rst_n,
	datain,dataout
);

parameter	DATA_WIDTH = 16;
parameter	DELAY_CYCLE = 2;

input								clk,rst_n;
input		[DATA_WIDTH-1:0]	datain;
output	[DATA_WIDTH-1:0]	dataout;

reg		[DATA_WIDTH-1:0]	data_reg[DELAY_CYCLE-1:0];

assign dataout = data_reg[DELAY_CYCLE-1];

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		data_reg[0] <= 'd0;
	else
		data_reg[0] <= datain;
end

genvar i;
generate
	for(i=1 ; i<DELAY_CYCLE ; i=i+1)
	begin:delay
		always @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				data_reg[i] <= 'd0;
			else
				data_reg[i] <= data_reg[i-1];
		end
	end
endgenerate
endmodule

module dis_pal_mult (
	clock,
	aclr,
	dataa,
	result
);
parameter						PIPELINE		= 4;
parameter						DATA_WIDTH	= 10;
parameter [DATA_WIDTH-1:0]	MULT_NUM		= 716;

input							aclr;
input							clock;
input	[DATA_WIDTH-1:0]	dataa;
output [DATA_WIDTH-1:0]	result;

wire [DATA_WIDTH-1:0] sub_wire0;
wire [DATA_WIDTH-1:0] sub_wire1 = MULT_NUM;
wire [DATA_WIDTH-1:0] result = sub_wire0[DATA_WIDTH-1:0];

lpm_mult	lpm_mult_component (
			.aclr (aclr),
			.clock (clock),
			.datab (sub_wire1),
			.dataa (dataa),
			.result (sub_wire0),
			.clken (1'b1),
			.sum (1'b0));
defparam
	lpm_mult_component.lpm_hint				= "INPUT_B_IS_CONSTANT=YES,MAXIMIZE_SPEED=5",
	lpm_mult_component.lpm_pipeline			= PIPELINE,
	lpm_mult_component.lpm_representation	= "UNSIGNED",
	lpm_mult_component.lpm_type				= "LPM_MULT",
	lpm_mult_component.lpm_widtha				= DATA_WIDTH,
	lpm_mult_component.lpm_widthb				= DATA_WIDTH,
	lpm_mult_component.lpm_widthp				= DATA_WIDTH;
endmodule

module dis_pal_add (
	clock,
	aclr,
	dataa,
	datab,
	result
);
parameter						PIPELINE		= 2;
parameter						DATA_WIDTH	= 10;

input								clock;
input								aclr;
input	[DATA_WIDTH-1:0]		dataa;
input	[DATA_WIDTH-1:0]		datab;
output [DATA_WIDTH-1:0]		result;

wire [DATA_WIDTH-1:0] sub_wire0;
wire [DATA_WIDTH-1:0] result = sub_wire0[DATA_WIDTH-1:0];

lpm_add_sub	LPM_ADD_SUB_component (
			.aclr (aclr),
			.clock (clock),
			.datab (datab),
			.dataa (dataa),
			.result (sub_wire0)
			// synopsys translate_off
			,
			.add_sub (),
			.cin (),
			.clken (),
			.cout (),
			.overflow ()
			// synopsys translate_on
);
defparam
	LPM_ADD_SUB_component.lpm_direction			= "ADD",
	LPM_ADD_SUB_component.lpm_hint				= "ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO",
	LPM_ADD_SUB_component.lpm_pipeline			= PIPELINE,
	LPM_ADD_SUB_component.lpm_representation	= "UNSIGNED",
	LPM_ADD_SUB_component.lpm_type				= "LPM_ADD_SUB",
	LPM_ADD_SUB_component.lpm_width				= DATA_WIDTH;
endmodule

module dis_pal_embedded #(
	parameter						DATA_WIDTH	= 10,
	parameter						MULT_PIPE	= 4,
	parameter						ADD_PIPE		= 2,
	parameter [DATA_WIDTH-1:0]	MULT_NUM		= 716,
	parameter [DATA_WIDTH-1:0]	ADD_NUM		= 307
) (
	input 	clk,
	input 	rst_n,
	input 	din_sync_n,
	input 	din_blank_n,
	input [DATA_WIDTH-1:0]	din_data,
	output [DATA_WIDTH-1:0]	dout_data
);

wire [DATA_WIDTH-1:0]	mult_result;
wire							sync_n_delay;
wire							blank_n_delay;

dis_pal_mult #(
	.PIPELINE(MULT_PIPE),
	.DATA_WIDTH(DATA_WIDTH),
	.MULT_NUM(MULT_NUM))
mult (
	.clock(clk),
	.aclr(~rst_n),
	.dataa(din_data),
	.result(mult_result)
);

dis_pal_delay #(
	.DATA_WIDTH(2),
	.DELAY_CYCLE(MULT_PIPE)
)
delay (
	.clk(clk),
	.rst_n(rst_n),
	.datain({din_sync_n, din_blank_n}),
	.dataout({sync_n_delay, blank_n_delay})
);

dis_pal_add #(
	.PIPELINE(ADD_PIPE),
	.DATA_WIDTH(DATA_WIDTH)
)
add (
	.clock(clk),
	.aclr(~rst_n),
	.dataa(blank_n_delay ? mult_result : {DATA_WIDTH{1'b0}}),
	.datab(sync_n_delay ? ADD_NUM : {DATA_WIDTH{1'b0}}),
	.result(dout_data)
);

endmodule
