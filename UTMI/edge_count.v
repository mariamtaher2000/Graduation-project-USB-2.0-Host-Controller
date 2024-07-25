module edge_counter 
(
 input   wire                  CLK,
 input   wire                  RST,
 input   wire                  Enable,sync_enable,
 output  reg   [1:0]           edge_count 
);



wire                           edge_count_done;
reg sync_enable1;
  
//edge counter 
always @ (posedge CLK or negedge RST)
 begin
  if(!RST)
   begin
    edge_count <= 'b0 ;
   end
  else if(Enable)
   begin
    if (sync_enable && !sync_enable1)
	 begin
      edge_count <= 'b0 ;
	 end
	else
	 begin
      edge_count <= edge_count + 'b1 ;
	 end	
   end 
  else
   begin
    edge_count <= 'b0 ;
   end   
 end
 
assign edge_count_done = (edge_count == 'b011) ? 1'b1 : 1'b0 ; 

always @(posedge CLK)
sync_enable1<= sync_enable;

endmodule


