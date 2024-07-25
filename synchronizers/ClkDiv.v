module ClkDiv#(parameter N=4 )(
	input i_ref_clk,i_rst_n,i_clk_en,
	input [N-1 : 0] i_div_ratio,
	output reg o_div_clk
	);

reg [N-1 : 0] cnt;
reg toggle_flag;
reg toggle;

//Counter
always @(posedge i_ref_clk or negedge i_rst_n) begin 
	if (!i_rst_n) begin
		cnt<=0;
		o_div_clk<=0;
		toggle_flag <=0;
	end
	else if(i_clk_en) begin
		if (!i_div_ratio[0]) begin
				if(cnt != (i_div_ratio>>1)-1)
					cnt<=cnt+1;
				else begin
					cnt<=0;
					o_div_clk <= ~(o_div_clk);
				end	
		end
		else begin
			 	if(!toggle_flag)
					if(cnt!= (i_div_ratio>>1)-1) begin
						cnt<=cnt+1;
						toggle<=0;
					end
					else begin
						cnt<=0;
						toggle_flag<=1;
						toggle<=1;
					end
				else begin
					if(cnt!= (i_div_ratio>>1)) begin
						cnt<=cnt+1;
						toggle<=0;
					end
					else begin
						cnt<=0;
						toggle_flag<=0;
						toggle<=1;
					end
				end
			if (toggle)
				o_div_clk <= ~(o_div_clk);
		end
	end
	else begin
		o_div_clk <= !o_div_clk;
	end
end

endmodule