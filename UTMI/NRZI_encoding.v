module NRZI_encoding (
  input              Clk,Rst,
  input              data_in,
  input       [1:0]  NRZI_en,
  input       [1:0]  edge_count,
  output wire        TX_DP,TX_DM,
  output reg         TX_en
  );
  
  reg NRZI_out;
  reg [1:0] flag;
  
  parameter NO_OP = 2'b00;
            
  parameter NRZI_normal = 2'b10,
            NRZI_EOP = 2'b01;
            
always @(posedge Clk or negedge Rst ) 
begin
  if (!Rst)
    begin
     TX_en<=1'b0;
     NRZI_out <= 1'b1;
     flag <=  0;
   end
 else if( NRZI_en == NO_OP)
   begin
     TX_en <= 1'b0;
     NRZI_out <= 1'b1;
     flag <=  0;
   end
  else if ( NRZI_en == NRZI_normal && edge_count == 3 )
     begin  
       TX_en <= 1'b1;
       flag <=0;
       NRZI_out <= data_in ? NRZI_out: ~NRZI_out;
     end
  else if (NRZI_en== NRZI_EOP && edge_count == 3)
    begin
       TX_en <= 1'b1;
       flag <= flag +1;
       NRZI_out <= data_in ;
       if(flag ==2)
         flag <=0;
     end
  end
  
  assign TX_DM = (flag ==2)? 1'b0 : (flag ==1)? 1'b0 : ~NRZI_out;
  assign TX_DP = NRZI_out;
  
endmodule

