//ya gma3a m7adesh ya5od files 2adema y3ml beha 7aga 
module AXI_FSM #(parameter ADDR_W = 32, parameter Data_W = 32, parameter usb_mem_W = 6)(
//INPUTS
//Slave_inputs
input				                Clk, Rst,
input			           	    	R_Valid_Address, 
input                 	 			Read_Ready, 
input [ADDR_W-1:0]	     			Read_Address_axi, 
input [2:0]			          	R_Prot, 

input [ADDR_W-1:0]		    		Write_Address_axi, 
input [2:0]			         	W_Prot, 
input 				                Write_Valid, 
input [Data_W-1:0]		    		Write_Data_axi, 
input [3:0]		     	       		Write_Strobe, 

//UHCI inputs
input [Data_W-1:0]		    		r_data_mem,
input [7:0]			          	r_data_reg,
input                   			data_reg_toggle,data_mem_toggle,
output reg              			rd_en,

//OUTPUTS
//Slave_outputs
output reg        			   	R_Ready_Address, Valid_Data_R, 
output reg			           	R_Error, Write_Ready, W_Error, 
output reg [Data_W-1:0]				Read_Data_axi, 

//FIFO signals
output reg 			          	wr_en_fifo_data,wr_en_fifo_address,
output reg [ADDR_W-1:0]				w_address_FIFO,
output reg [Data_W-1:0]				w_data_FIFO,
input			                	empty,full,

//MUX signals 
output reg [Data_W-1:0]				R_address_mux,
output reg [1:0]	     			Read_en//mux selector
);

//states
localparam IDLE		            		= 2'b00;
localparam READ_DATA_ADDR_0			= 2'b01;
localparam READ_DATA_ADDR_1	 		= 2'b11;
localparam WRITE_DATA_ADDR  			= 2'b10;


reg [1:0]       				C_S, N_S;
reg [ADDR_W-1:0]				address;

reg data_reg_toggle1, data_mem_toggle1;

//state transition
always@(posedge Clk or negedge Rst) begin
if(!Rst) begin
	C_S 					<= IDLE;
end
else begin
	C_S 					<= N_S;
end
end 

//next state logic
always@(*) begin
case(C_S)
IDLE: 		begin
			if (Write_Valid && !full && (Write_Strobe == 4'b1111)) begin 
				N_S 	= WRITE_DATA_ADDR;
			end
			else if (R_Valid_Address && empty) begin
				N_S 	= READ_DATA_ADDR_0;
			end
			else begin
				N_S 	= IDLE;
			end 
		end

READ_DATA_ADDR_0: 	begin
    if ( ((data_reg_toggle1 != data_reg_toggle) || (data_mem_toggle1 != data_mem_toggle))  && Read_Ready)
			  N_S = IDLE;
		else if  ( ((data_reg_toggle1 != data_reg_toggle) || (data_mem_toggle1 != data_mem_toggle))  && !Read_Ready )
			  N_S = READ_DATA_ADDR_1;
		else 
			  N_S = READ_DATA_ADDR_0;
		end
		
READ_DATA_ADDR_1: 	begin
    if (Read_Ready)
			  N_S = IDLE;
			else 
			  N_S = READ_DATA_ADDR_1;
		end

WRITE_DATA_ADDR: 	begin
			N_S = IDLE;
		end
		
default:
		 N_S = IDLE;
endcase
end
 
//output logic
always@(*) begin
      rd_en = 1'b0;
			R_Ready_Address  = 1'b0;//initiate read op
			Valid_Data_R	= 1'b0;//
			R_Error 	= 1'b0;//
			Write_Ready 	= 1'b0;//initiate write op
			W_Error 	= 1'b0;//
			Read_Data_axi 	= 'b0;//
			R_address_mux	= 1'b0;//
			wr_en_fifo_address = 1'b0;//
			wr_en_fifo_data    = 1'b0;
			w_address_FIFO   = 'b0;//
			Read_en		   = 2'b00;//
			w_data_FIFO = 'b0;
case (C_S)
IDLE: 		begin
      rd_en = 1'b0;
			Valid_Data_R	= 1'b0;//
			R_Error 	= 1'b0;//
			W_Error 	= 1'b0;//
			Read_Data_axi 	= 'b0;//
			R_address_mux	= 1'b0;//
			wr_en_fifo_address = 1'b0;
			wr_en_fifo_data	= 1'b0;//
			w_address_FIFO	= 'b0;//
			if(empty) begin
			  Read_en		= 2'b00;//
				R_Ready_Address = 1'b1;
				Write_Ready 	= 1'b1;
			end
			else if (!full && !empty) begin
			  Read_en		= 2'b10;
				R_Ready_Address = 1'b0;
				Write_Ready 	= 1'b1;
			end
			else begin
			  Read_en		= 2'b10;
				R_Ready_Address = 1'b0;
				Write_Ready 	= 1'b0;
			end
		end

READ_DATA_ADDR_0: 	begin
      //rd_en = 1'b1;
      Read_en		= 2'b01;
      Valid_Data_R = 1'b0;
			R_address_mux = Read_Address_axi;
			if(Read_Address_axi[8]) begin
			  rd_en = 1'b0;
				if (data_reg_toggle1 != data_reg_toggle) begin // flag abdullah ali
					Read_Data_axi 	= { 24'b0,r_data_reg};
					Valid_Data_R = 1'b1;
				end
			end
			else begin
			  rd_en = 1'b1;
				if(data_mem_toggle1 != data_mem_toggle) begin
				  Read_Data_axi 	= r_data_mem;
				  Valid_Data_R = 1'b1;
				 end
			  end		
		end

READ_DATA_ADDR_1: 	begin
  Valid_Data_R = 1'b1;
  if(Read_Address_axi[8]) begin
    Read_Data_axi 	= { 24'b0,r_data_reg};
  end
  else begin
    Read_Data_axi 	= r_data_mem;
  end
end

WRITE_DATA_ADDR: 	begin
      Read_en		= 2'b10;
			Write_Ready = 1'b0;
			R_Ready_Address = 1'b0;
			w_data_FIFO = Write_Data_axi;
			wr_en_fifo_data = 1'b1;
			wr_en_fifo_address = 1'b1;
			w_address_FIFO = Write_Address_axi;
		end
		
default: begin
      rd_en = 1'b0;
			R_Ready_Address  = 1'b0;//initiate read op
			Valid_Data_R	= 1'b0;//
			R_Error 	= 1'b0;//
			Write_Ready 	= 1'b0;//initiate write op
			W_Error 	= 1'b0;//
			Read_Data_axi 	= 'b0;//
			R_address_mux	= 1'b0;//
			wr_en_fifo_address = 1'b0;//
			wr_en_fifo_data    = 1'b0;
			w_address_FIFO   = 'b0;//
			Read_en		   = 2'b00;//
			w_data_FIFO = 'b0;
end

endcase
end

always @(posedge Clk or negedge Rst)
begin
  if (!Rst) begin
    data_reg_toggle1 = 1'b0;
		data_mem_toggle1 = 1'b0;
	end
	else begin
	  data_reg_toggle1 = data_reg_toggle;
		data_mem_toggle1 = data_mem_toggle;
	end
end
endmodule 
