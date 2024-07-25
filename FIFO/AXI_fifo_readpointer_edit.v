module AXI_fifo_readpointer #(parameter ADDRSIZE = 5)(
	input wire [ADDRSIZE :0] write_pointer_sync,
 	input wire		 read_enable, read_clk, read_rst,
	input wire		 clear,
 	output wire[ADDRSIZE-1:0]read_addr,
 	output reg [ADDRSIZE :0] read_ptr,
 	output reg empty_read

);

 reg [ADDRSIZE:0] read_bin;
 wire [ADDRSIZE:0] read_gray_next, read_bin_next;
 wire empty_val;
 //-------------------
 // GRAYSTYLE2 pointer
 //-------------------
always @(posedge read_clk or negedge read_rst)
begin
	if (!read_rst)
		begin
		{read_bin, read_ptr} <= 0;
		end
	else if (clear)
		begin
		{read_bin, read_ptr} <= 0;
		end
 	else 
		begin
		{read_bin, read_ptr} <= {read_bin_next, read_gray_next};
		end
end
 // Memory read-address pointer (o use binary to address memory)
 assign read_addr = read_bin[ADDRSIZE-1:0];
 assign read_bin_next = read_bin + (read_enable & ~empty_read);
 assign read_gray_next = (read_bin_next>>1) ^ read_bin_next;
 //---------------------------------------------------------------
 // FIFO empty when the next read_ptr == synchronized write_ptr or on reset
 //---------------------------------------------------------------
 assign empty_val = (read_gray_next == write_pointer_sync);

always @(posedge read_clk or negedge read_rst)
begin
 	if (!read_rst )
		begin
		empty_read <= 1'b1;
		end
	else if (clear )
		begin
		empty_read <= 1'b1;
		end
 	else 
		begin
		empty_read <= empty_val;
		end
end
endmodule
