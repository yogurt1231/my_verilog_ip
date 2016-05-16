module i2c_interface(
	clk,rst_n,
	i2c_pclk,
	
	av_address,av_write,av_read,
	av_writedata,av_readdata,
	av_readdatavalid,av_waitrequest,
	
	i2c_scl,i2c_sda
);

input					clk,rst_n,i2c_pclk;

input		[1:0]		av_address;
input					av_write,av_read;
input		[31:0]	av_writedata;
output	[31:0]	av_readdata;
output				av_readdatavalid,av_waitrequest;

output				i2c_scl;
inout					i2c_sda;

reg					av_readdatavalid;
reg					i2c_scl_reg;
reg					i2c_sda_out,i2c_sda_reg;

reg		[3:0]		state,n_state;
reg		[4:0]		cnt;

reg					ack_reg;
reg		[7:0]		tx_data,rx_data;

wire		[3:0]		av_write_read_address;

localparam			IDLE						= 4'd0;
localparam			I2C_START				= 4'd1;
localparam			I2C_STOP					= 4'd2;
localparam			I2C_WRITE				= 4'd3;
localparam			I2C_GETACK				= 4'd4;
localparam			I2C_READ_WITH_ACK 	= 4'd5;
localparam			I2C_READ_WITH_NACK	= 4'd6;
localparam			I2C_ACK_NACK			= 4'd7;
localparam			AVALON_READ_ACK		= 4'd8;

assign av_write_read_address = {av_write,av_read,av_address};

assign i2c_scl = i2c_scl_reg;
assign i2c_sda = i2c_sda_out ? i2c_sda_reg : 1'bz;

assign av_waitrequest = ~((state==IDLE)||(state==AVALON_READ_ACK));
assign av_readdata = state==AVALON_READ_ACK ? {30'd0,ack_reg,1'b0} : {24'd0,rx_data};

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or av_write_read_address or cnt or i2c_pclk or av_writedata[0])
begin
	case(state)
	IDLE,
	AVALON_READ_ACK:begin
		case(av_write_read_address)
		4'b0100:n_state = AVALON_READ_ACK;
		4'b0101:n_state = AVALON_READ_ACK;
		4'b0110:n_state = I2C_READ_WITH_ACK;
		4'b0111:n_state = I2C_READ_WITH_NACK;
		4'b1000:n_state = av_writedata[0] ? I2C_START : I2C_STOP;
		4'b1001:n_state = I2C_WRITE;
		default:n_state = IDLE;
		endcase
	end
	I2C_START,
	I2C_STOP,
	I2C_GETACK,
	I2C_ACK_NACK:			n_state = (cnt==5'd0 && i2c_pclk) ? IDLE : state;
	I2C_WRITE:				n_state = (cnt==5'd0 && i2c_pclk) ? I2C_GETACK : state;
	I2C_READ_WITH_ACK,
	I2C_READ_WITH_NACK:	n_state = (cnt==5'd0 && i2c_pclk) ? I2C_ACK_NACK : state;
	default:					n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt <= 5'd0;
	else
	begin
		case(state)
		IDLE,
		AVALON_READ_ACK:begin
			case(n_state)
			I2C_START:begin
				case({i2c_scl_reg,i2c_sda_reg})
				2'b00,
				2'b01:cnt <= 5'd7;
				2'b10:cnt <= 5'd8;
				2'b11:cnt <= 5'd5;
				default:cnt <= 5'd0;
				endcase
			end
			I2C_STOP:begin
				case({i2c_scl_reg,i2c_sda_reg})
				2'b00,
				2'b01:cnt <= 5'd5;
				2'b10:cnt <= 5'd3;
				2'b11:cnt <= 5'd6;
				default:cnt <= 5'd0;
				endcase
			end
			I2C_WRITE,
			I2C_READ_WITH_ACK,
			I2C_READ_WITH_NACK:cnt <= 5'd31;
			default:cnt <= 5'd0;
			endcase
		end
		I2C_START,
		I2C_STOP,
		I2C_GETACK,
		I2C_ACK_NACK:			cnt <= i2c_pclk ? cnt-5'd1 : cnt;
		I2C_WRITE,
		I2C_READ_WITH_ACK,
		I2C_READ_WITH_NACK:	cnt <= i2c_pclk ? (cnt==5'd0 ? 5'd3 : cnt-5'd1) : cnt;
		default:					cnt <= 5'd0;
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		i2c_scl_reg <= 1'b1;
	else if(i2c_pclk)
	begin
		case(state)
		I2C_START:begin
			case(cnt[3:0])
			4'd8:i2c_scl_reg <= 1'b0;
			4'd6:i2c_scl_reg <= 1'b1;
			4'd0:i2c_scl_reg <= 1'b0;
			endcase
		end
		I2C_STOP:begin
			case(cnt[3:0])
			4'd6:i2c_scl_reg <= 1'b0;
			4'd4:i2c_scl_reg <= 1'b1;
			endcase
		end
		I2C_GETACK,
		I2C_ACK_NACK,
		I2C_WRITE,
		I2C_READ_WITH_ACK,
		I2C_READ_WITH_NACK:i2c_scl_reg <= cnt[0] ? i2c_scl_reg : cnt[1];
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		i2c_sda_reg <= 1'b1;
	else if(i2c_pclk)
	begin
		case(state)
		I2C_START:begin
			case(cnt[2:0])
			3'd7:i2c_sda_reg <= 1'b1;
			3'd3:i2c_sda_reg <= 1'b0;
			endcase
		end
		I2C_STOP:begin
			case(cnt[2:0])
			3'd5:i2c_sda_reg <= 1'b0;
			3'd1:i2c_sda_reg <= 1'b1;
			endcase
		end
		I2C_GETACK:begin
			case(cnt[1:0])
			2'd1:i2c_sda_reg <= i2c_sda;
			endcase
		end
		I2C_WRITE:				i2c_sda_reg <= tx_data[cnt[4:2]];
		I2C_READ_WITH_ACK:	i2c_sda_reg <= 1'b0;
		I2C_READ_WITH_NACK:	i2c_sda_reg <= 1'b1;
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		i2c_sda_out <= 1'b0;
	else if(i2c_pclk)
	begin
		case(state)
		I2C_START,
		I2C_STOP,
		I2C_WRITE,
		I2C_ACK_NACK:i2c_sda_out <= 1'b1;
		I2C_GETACK,
		I2C_READ_WITH_ACK,
		I2C_READ_WITH_NACK:i2c_sda_out <= 1'b0;
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		rx_data <= 8'd0;
	else if(i2c_pclk)
	begin
		case(state)
		I2C_READ_WITH_ACK,
		I2C_READ_WITH_NACK:rx_data <= cnt[1:0]==2'd1 ? {rx_data[6:0],i2c_sda} : rx_data;
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		tx_data <= 8'd0;
	else
	begin
		case(state)
		IDLE,
		AVALON_READ_ACK:tx_data <= n_state==I2C_WRITE ? av_writedata[7:0] : tx_data;
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		ack_reg <= 1'b1;
	else
	begin
		case(state)
		I2C_GETACK:ack_reg <= (cnt==5'd1 && i2c_pclk) ? i2c_sda : ack_reg;
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		av_readdatavalid <= 1'b0;
	else
	begin
		case(state)
		IDLE,
		AVALON_READ_ACK:		av_readdatavalid <= n_state==AVALON_READ_ACK;
		I2C_READ_WITH_ACK,
		I2C_READ_WITH_NACK:	av_readdatavalid <= (cnt==5'd1 && i2c_pclk);
		default:					av_readdatavalid <= 1'b0;
		endcase
	end
end

endmodule
