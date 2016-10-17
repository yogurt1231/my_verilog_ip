module blind_pixel_proc(
	clk,
	rst_n,
	
	ram_read,
	ram_address,
	ram_readdata,
	
	reg_mode,
	reg_background,
	
	din_data,
	din_valid,
	din_startofpacket,
	din_endofpacket,
	din_ready,
	
	dout_data,
	dout_valid,
	dout_startofpacket,
	dout_endofpacket,
	dout_ready
);

parameter	DATA_WIDTH = 14;

parameter	MODE_VIDEO = 2'b00;
parameter	MODE_BLIND = 2'b01;
parameter	MODE_BACK = 2'b10;
parameter	MODE_TEST = 2'b11;

input 						clk;
input 						rst_n;

input [31:0]				ram_readdata;
output 						ram_read;
output reg [7:0]			ram_address;

input [1:0]					reg_mode;
input [DATA_WIDTH-1:0]	reg_background;

input [DATA_WIDTH-1:0]	din_data;
input 						din_startofpacket;
input 						din_endofpacket;
input 						din_valid;
output 						din_ready;

output [DATA_WIDTH-1:0]	dout_data;
output 						dout_startofpacket;
output 						dout_endofpacket;
output 						dout_valid;
input 						dout_ready;

reg [2:0]	state, n_state;
reg [31:0]	data_cnt;
reg [7:0]	blind_pixel_number;
wire [7:0]	read_location_cnt;

wire [31:0]	ram_use_data;
reg [31:0]	ram_readdata_reg;
reg 			ram_datavalid;

reg [DATA_WIDTH-1:0]	data_pre_buffer;
reg [DATA_WIDTH-1:0]	dout_data_reg;
wire data_in_location;

localparam	IDLE = 3'd0;
localparam	RDNU = 3'd1;	/* addr = num */
localparam	DANU = 3'd2;	/* addr = l[0], data = num */
localparam	PROC = 3'd3;

assign data_in_location = data_cnt==ram_use_data && din_valid;
assign ram_read = state==RDNU || state==DANU || state==PROC && data_in_location;
assign ram_use_data = ram_datavalid ? ram_readdata : ram_readdata_reg;

assign dout_startofpacket = din_startofpacket;
assign dout_endofpacket = din_endofpacket;
assign dout_valid = din_valid;
assign din_ready = (state==IDLE || state==PROC) && dout_ready;
assign dout_data = dout_data_reg;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or din_endofpacket or din_valid or ram_address or blind_pixel_number or data_in_location or ram_use_data[7:0])
begin
	case (state)
	IDLE: n_state = din_endofpacket & din_valid ? RDNU : IDLE;
	RDNU: n_state = DANU;
	DANU: n_state = ram_use_data[7:0]==8'd0 ? IDLE : PROC;
	PROC: n_state = ram_address==(blind_pixel_number+8'd1) && data_in_location ? IDLE : PROC;
	default: n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		data_cnt <= 32'd0;
	else if (din_valid) begin
		if (din_endofpacket)
			data_cnt <= 32'd0;
		else
			data_cnt <= data_cnt + 32'd1;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		blind_pixel_number <= 8'd0;
	else if (state == DANU)
		blind_pixel_number <= ram_use_data[7:0];
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		ram_address <= 8'd0;
	else if (state == IDLE)
		ram_address <= 8'd0;
	else if (ram_read)
		ram_address <= ram_address + 8'd1;
end

always @(state or reg_mode or reg_background or din_data or data_in_location or data_pre_buffer)
begin
	case (reg_mode)
	MODE_VIDEO: dout_data_reg = din_data;
	MODE_BACK: dout_data_reg = reg_background;
	MODE_BLIND: dout_data_reg = state==PROC && data_in_location ? data_pre_buffer : din_data;
	MODE_TEST: dout_data_reg = state==PROC && data_in_location ? reg_background : din_data;
	default: dout_data_reg = din_data;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		data_pre_buffer <= {DATA_WIDTH{1'b0}};
	else if (din_valid && data_cnt!=ram_use_data)
		data_pre_buffer <= din_data;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		ram_datavalid <= 1'b0;
	else
		ram_datavalid <= ram_read;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		ram_readdata_reg <= 32'd0;
	else if (ram_datavalid)
		ram_readdata_reg <= ram_readdata;
end

endmodule
