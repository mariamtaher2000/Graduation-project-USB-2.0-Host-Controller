module full_and_writepointer  #(parameter ADDRSIZE = 5) (
	input wire [ADDRSIZE :0] read_ptr_sync,
 	input wire		 write_enable, write_clk, write_rst,
	input wire		 clear,
	output reg 		 full,
 	output wire [ADDRSIZE-1:0]write_addr,
 	output reg [ADDRSIZE :0] write_ptr
 );
 reg [ADDRSIZE:0] write_bin;
 wire [ADDRSIZE:0] write_gray_next, write_bin_next;
 wire full_val;

 // GRAYSTYLE2 pointer
always @(posedge write_clk or negedge write_rst)
begin
 	if (!write_rst) 
		begin
		{write_bin, write_ptr} <= 0;
		end
	else  	if (clear) 
		begin
		{write_bin, write_ptr} <= 0;
		end
 	else 
		begin
		{write_bin, write_ptr} <= {write_bin_next, write_gray_next};
		end
end

// Memory write-address pointer ( use binary to address memory)

 assign write_addr = write_bin[ADDRSIZE-1:0];
 assign write_bin_next = write_bin + (write_enable & ~full);
 assign write_gray_next = (write_bin_next>>1) ^ write_bin_next;
 //------------------------------------------------------------------
 //  full-tests:
 assign full_val=((write_gray_next[ADDRSIZE] !=read_ptr_sync[ADDRSIZE] ) &&(write_gray_next[ADDRSIZE-1] !=read_ptr_sync[ADDRSIZE-1]) && (write_gray_next[ADDRSIZE-2:0]==read_ptr_sync[ADDRSIZE-2:0]));
 //------------------------------------------------------------------

always @(posedge write_clk or negedge write_rst)
begin
 	if (!write_rst) 
		begin	
		full <= 1'b0;
		end
	else if (!write_rst) 
		begin	
		full <= 1'b0;
		end
 	else 
		begin
		full <= full_val;
		end
end
endmodule



