module osd_avalon_slave(
	clk, rst_n,
	
	av_address, av_read, av_write,
	av_readdata, av_writedata,
	
	conduit_signal
);

parameter	ADDR_WIDTH	= 3;
localparam	ADDR_NUM		= 1<<ADDR_WIDTH;

input 						clk, rst_n;
input [ADDR_WIDTH-1:0]	av_address;
input 						av_read, av_write;
output reg [31:0]			av_readdata;
input [31:0]				av_writedata;

output [(1<<(ADDR_WIDTH+5))-1:0]	conduit_signal;

reg [31:0]	registers [ADDR_NUM-1:0];

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		av_readdata <= 32'd0;
	else if (av_read)
		av_readdata <= registers[av_address];
end

genvar i;
generate
   for(i=0; i<ADDR_NUM; i=i+1)
	begin: register
		always @(posedge clk or negedge rst_n)
		begin
			if (!rst_n)
				registers[i] <= 32'd0;
			else if (av_write && av_address==i)
				registers[i] <= av_writedata;
		end
		assign conduit_signal[(32*i+31):(32*i)] = registers[i];
	end
endgenerate

endmodule
