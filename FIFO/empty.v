module empty(
	input wire write_enable,read_enable,
	input wire w_clk,r_clk,rst,
	output reg empty
);



always @(posedge r_clk or negedge rst)
begin
	if (!rst ) 
		begin
		empty <= 1;
		end
 	else  if(write_enable)
		begin
		empty <= 0;
		end
	else  if(read_enable)
		begin
		empty <= 1;
		end
end

endmodule

