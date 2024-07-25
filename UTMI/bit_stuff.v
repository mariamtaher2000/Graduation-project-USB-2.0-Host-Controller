module bit_stuff(
  input               Clk,Rst,
  input        [1:0]  bit_stuff_en, 
  input               data_in,
  input        [1:0]  edge_count,
  input               data_done,
  output wire         stuff,
  output reg          data_out,
  output reg   [1:0]  NRZI_en
  );
  
  reg [3:0] count;
  reg data_done1;
  
  parameter NO_OP = 2'b00;
  
  parameter STUFF_OFF = 2'b01,
            STUFF_ON = 2'b10;
            
  parameter NRZI_normal = 2'b10,
            NRZI_EOP = 2'b01;
             
   always @(posedge Clk or negedge Rst)
   begin
     if (!Rst)
       begin
         NRZI_en <= NO_OP; 
         data_out <= 1'b1;
         count <= 0;
      end
    else if ( bit_stuff_en == NO_OP)
      begin
        NRZI_en <= NO_OP;
        data_out <= 1'b1;
        count <= 0;
      end
    else if ( bit_stuff_en == STUFF_OFF && edge_count == 3 && !data_done1 )
      begin
        data_out <= data_in;
        NRZI_en <= NRZI_normal;
        count <= 0;
      end
         
    else if (bit_stuff_en == STUFF_ON && edge_count == 3 && !data_done1)
         begin 
           NRZI_en <= NRZI_normal;
           
           if (stuff)
             begin
              count <= 0;
              data_out <= 1'b0;
             end
         
           else if ( data_in )
             begin
              count <= count + 1;
              data_out <= data_in;
             end
         
           else 
            begin
              count <= 0;
              data_out <= data_in;
           end
         end
         
     else if (data_done1 && stuff && edge_count == 3)
       begin
         NRZI_en <= NRZI_normal;
         data_out <= 1'b0;
         count <= 0;
       end
     else if (data_done1 && edge_count == 3)
       begin
         NRZI_en <= NRZI_EOP;
         data_out <= data_in;
     end
  end
  
  always @(posedge Clk or negedge Rst)
  begin
    if (!Rst)
      data_done1 <= 1'b0;
    else
      data_done1 <= data_done;
     end
     
   
    
  assign stuff = (count == 3'b110) ? 1'b1 : 1'b0 ;
  
  endmodule


