module fifo_memory #(parameter DATASIZE = 8, ADDRSIZE = 5) (
	input wire [DATASIZE-1:0] write_data,
 	input wire [ADDRSIZE-1:0] read_addr, 
	input wire [ADDRSIZE-1:0] write_addr,
 	input wire 		  full,empty, 
	input wire		  write_rst,
	input wire		  write_clk,
	input wire		  read_clk,
	input wire		  write_enable,read_enable,
	output wire [DATASIZE-1:0] read_data
);
 	
 // RTL Verilog memory model
 localparam DEPTH = ((1<<ADDRSIZE));// size of fifo is 25 bytes
 reg [DATASIZE-1:0] mem [0:DEPTH-1];
integer i;

always @(posedge write_clk or negedge write_rst )
begin
	if (!write_rst)
		begin
		for(i=0; i<DEPTH; i=i+1)
		begin
			mem[i] <= 'b0;
		end
		end

	else if (write_enable && !full)
		begin
		mem[write_addr] <= write_data;
		end

end


	assign	read_data = mem[read_addr];
		


endmodule
