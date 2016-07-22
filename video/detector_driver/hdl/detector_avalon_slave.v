module detector_avalon_slave(
	clk, rst_n,
	
	av_address, av_read, av_write,
	av_readdata, av_writedata,
	
	register_signal_in,
	register_signal_out
);

parameter	ADDR_WIDTH	= 4;
parameter	REGS_STATE	= 0;
parameter	REGS_NUM		= 10;

input 						clk, rst_n;
input [ADDR_WIDTH-1:0]	av_address;
input 						av_read, av_write;
output reg [31:0]			av_readdata;
input [31:0]				av_writedata;

input [(REGS_NUM<<5)-1:0]	register_signal_in;
output [(REGS_NUM<<5)-1:0]	register_signal_out;

wire [31:0]	read_regs [REGS_NUM-1:0];
reg [31:0]	registers [REGS_NUM-1:0];

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		av_readdata <= 32'd0;
	else if (av_read)
		av_readdata <= av_address<REGS_NUM[ADDR_WIDTH-1:0] ? read_regs[av_address] : 32'd0;
end

genvar i;
generate
   for(i=0; i<REGS_NUM; i=i+1)
	begin: register
		if (REGS_STATE[i])
		begin: register_in
			assign read_regs[i] = register_signal_in[(32*i+31):(32*i)];
		end
		else
		begin: register_out
			always @(posedge clk or negedge rst_n)
			begin
				if (!rst_n)
					registers[i] <= 32'd0;
				else if (av_write && av_address==i)
					registers[i] <= av_writedata;
			end
			assign register_signal_out[(32*i+31):(32*i)] = registers[i];
			assign read_regs[i] = registers[i];
		end
	end
endgenerate

endmodule
