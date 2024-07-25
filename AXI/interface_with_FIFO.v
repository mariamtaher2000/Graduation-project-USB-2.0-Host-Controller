module interface_with_FIFO(
  input               	  Clk ,Rst,
  input      [31:0]  	   address_interface_i,
  input      [31:0]      data_interface_i,
  input               	  empty,
  output reg		           read_en_data, read_en_address,
  output reg 	[31:0]	    address_interface_o,
  output reg  [31:0]     data_interface_o,
  output reg             mem_wr,
  output reg  	      	  wr_en_reg
  );

localparam  	IDLE = 1'b0;
localparam  	POP = 1'b1;

reg C_S,N_S;

always@(posedge Clk or negedge Rst) begin
if(!Rst) begin
	C_S <= IDLE;
end
else begin	
	C_S <= N_S;
end 
end

//next state logic
always@(*) begin
case(C_S)
IDLE:		begin
		if(!empty) begin
			N_S <= POP;
			
		end
		else begin
			N_S <= IDLE;
		end
		end

POP:		begin
  if(!empty) 
			N_S <= POP;
	else
			N_S <= IDLE;
		end
endcase
end

always @(*) begin
    mem_wr = 1'b0;
		read_en_address = 1'b0;
 		read_en_data = 1'b0;
		address_interface_o = 'b0; //w_address to decoder
		data_interface_o =  'b0;
		 wr_en_reg       = 1'b0;
case (C_S)
IDLE :		begin
    mem_wr = 1'b0;
		read_en_address = 1'b0;
 		read_en_data = 1'b0;
		address_interface_o = 'b0; //w_address to decoder
		data_interface_o =  'b0;
		wr_en_reg        = 1'b0; 
		end

POP:		begin
  
 		  address_interface_o = address_interface_i; //w_address to decoder
		  if (N_S == IDLE) begin
		  	wr_en_reg = 1'b0;
		  	mem_wr = 1'b0;
		  	read_en_address = 1'b0;
 		  	read_en_data = 1'b0;
 		  	address_interface_o = 'b0; //w_address to decoder
		  	data_interface_o = 'b0;
		  end
		  else if (address_interface_o[17] != 1) begin
		    mem_wr = 1'b0;
		    wr_en_reg = 1'b0;
		    read_en_address = 1'b0;
 		    read_en_data = 1'b0;
 		    data_interface_o = 0;
		    end
		  else if ((address_interface_o[8] == 1)) begin
		    wr_en_reg = 1'b1;
		    mem_wr    = 1'b0;
		    read_en_address = 1'b1;
 		    read_en_data = 1'b1;
		    data_interface_o = data_interface_i;
		  end
		  else if (address_interface_o[8] != 1) begin
		    mem_wr = 1'b1;
		    wr_en_reg = 1'b0;
		    read_en_address = 1'b1;
 		    read_en_data = 1'b1;
 		    data_interface_o = data_interface_i;
		    end
		end
		
default: begin
    mem_wr = 1'b0;
    read_en_address = 1'b0;
 		read_en_data = 1'b0;
		address_interface_o = 'b0; //w_address to decoder
		data_interface_o =  'b0;
  end
endcase
end

endmodule
