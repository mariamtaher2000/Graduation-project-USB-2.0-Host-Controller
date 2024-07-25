module sync_pointer #(parameter ADDRSIZE = 5)(
	input wire [ADDRSIZE:0] ptr,
 	input wire		clk, rst,clear,
	output reg [ADDRSIZE:0] ptr_sync//
);

 
reg [ADDRSIZE:0] ptr_sync1;

always @(posedge clk or negedge rst)
begin
	if (!rst) 
		begin
		{ptr_sync,ptr_sync1} <= 0;
		end
	else if (clear) 
		begin
		{ptr_sync,ptr_sync1} <= 0;
		end
	else 
		begin
		{ptr_sync,ptr_sync1} <= {ptr_sync1,ptr};
		end

end
endmodule 
