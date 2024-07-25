module fifo #(parameter DSIZE = 8,parameter ASIZE = 5)(
	input wire [DSIZE-1:0] write_data,
 	input wire             write_enable, write_clk, write_rst,
 	input wire 	       read_enable, read_clk, read_rst,
	input wire		clear,
	output wire [DSIZE-1:0] read_data,
 	output wire 		full,
 	output wire		empty
 );
 wire [ASIZE-1:0] write_addr, read_addr;
 wire [ASIZE:0] write_ptr, read_ptr, write_ptr_sync, read_ptr_sync;

 sync_pointer #(ASIZE) sync_read_to_write (
	.ptr(read_ptr),
 	.clk(write_clk), 
	.rst(write_rst),
	.clear(clear),
	.ptr_sync(read_ptr_sync)
);

sync_pointer #(ASIZE) sync_write_to_read (
	.ptr(write_ptr),
 	.clk(read_clk), 
	.rst(read_rst),
	.clear(clear),
	.ptr_sync(write_ptr_sync)
);

fifo_memory #(DSIZE, ASIZE) fifo_mem (
	.write_data(write_data),
 	.read_addr (read_addr), 
	.write_addr(write_addr),
 	.full(full),
	.empty(empty), 
	.write_rst(write_rst),
	.write_clk(write_clk),
	.read_clk(read_clk),
	.write_enable(write_enable),
	.read_enable(read_enable),
	.read_data (read_data)
);
 
empty_and_readpointer #(ASIZE) empt_readptr(
	.write_pointer_sync(write_ptr_sync),
 	.read_enable(read_enable), 
	.read_clk(read_clk), 
	.read_rst(read_rst),
	.clear(clear),
	.empty(empty),
 	.read_addr(read_addr),
 	.read_ptr(read_ptr)

);


full_and_writepointer #(ASIZE) full_writeptr (
	.read_ptr_sync (read_ptr_sync),
 	.write_enable(write_enable), 
	.write_clk(write_clk), 
	.write_rst(write_rst),
	.clear(clear),
	.full(full),
 	.write_addr(write_addr),
 	.write_ptr(write_ptr)
 );

endmodule
