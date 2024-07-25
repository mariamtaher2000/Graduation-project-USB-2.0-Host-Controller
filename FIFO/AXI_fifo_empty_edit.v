module AXI_fifo_empty #(parameter ADDRSIZE = 5)(
	input wire [ADDRSIZE :0] write_pointer,
	input wire [ADDRSIZE :0] read_pointer_sync,
 	input wire		 write_clk,write_rst,
	input wire		 clear,
	output reg 		 empty
);

 
 wire empty_val;
 
 assign empty_val = (write_pointer == read_pointer_sync);

always @(posedge write_clk or negedge write_rst)
begin
 	if (!write_rst )
		begin
		empty <= 1'b1;
		end
	else if (clear )
		begin
		empty <= 1'b1;
		end
 	else 
		begin
		empty <= empty_val;
		end
end
endmodule
