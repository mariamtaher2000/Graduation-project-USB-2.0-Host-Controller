module decoder(
  input                 Clk,Rst,
  input 	       [31:0]  address_decoder_i,
  input         [1:0] 	 Read_en,
  output reg    [3:0]  	wr_en_mem , rd_en_mem,
  output reg  	      	  rd_en_reg, 
  output reg    [5:0]   addr_b,addr_reg,
  output                mem_reg
  );
 

always @(posedge Clk)
begin
  if(!Rst) begin
    rd_en_reg = 1'b0;
    wr_en_mem = 4'b0;
    rd_en_mem = 4'b0;
    addr_b = 'b0;
    addr_reg = 'b0;
  end
else
  begin
  rd_en_reg = 1'b0;
  wr_en_mem = 4'b0;
  rd_en_mem = 4'b0;
  if(Read_en == 2'b10) // busses to usb "write"
    begin
      if(!mem_reg) // write in memory
        begin
	        addr_b = address_decoder_i[7:2];
          case(address_decoder_i[1:0])
            2'b00: wr_en_mem = 4'b0001;
            2'b01: wr_en_mem = 4'b0010;
            2'b10: wr_en_mem = 4'b0100;
            2'b11: wr_en_mem = 4'b1000;
          endcase
       end
      else //write in registers
        begin
          wr_en_mem = 4'b0000;
	        addr_reg = address_decoder_i[5:0];
        end
     end
  else if (Read_en == 2'b01)// usb to busses
    begin
      if(!mem_reg) // read from memory
        begin
	      addr_b = address_decoder_i[7:2];
	      rd_en_reg = 1'b0;
          case(address_decoder_i[1:0])
            2'b00: rd_en_mem = 4'b0001;
            2'b01: rd_en_mem = 4'b0010;
            2'b10: rd_en_mem = 4'b0100;
            2'b11: rd_en_mem = 4'b1000;
          endcase
       end
      else // read from registers
        begin
          rd_en_reg = 1'b1 ;
          rd_en_mem = 4'b0000;
	        addr_reg = address_decoder_i[5:0];
        end
     end
     end
end

assign mem_reg = address_decoder_i[8];


endmodule 