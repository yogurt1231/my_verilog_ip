module detector_delay(
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
