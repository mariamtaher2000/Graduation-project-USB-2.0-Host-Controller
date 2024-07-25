module Error_logic (
	input	wire	clk,rst_n,
	input	wire	HCR_err,		//Host Controller error from fsm
	output 	reg 	RS,
	output  reg     en,
	output	reg 	HCR_halt_err,
	output	reg		HCPR_reg		//Host Controller Process Error bit in register file
	);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
	//Default values
		RS <= 0;
		HCR_halt_err <= 1;
		HCPR_reg <= 0;
		en <= 0;
	end
	else if (HCR_err) begin
		RS <= 0;
		HCR_halt_err <= 1;
		HCPR_reg <= 1;
		en <= 1;
	end
	else begin
		RS <= 0;
		HCR_halt_err <= 1;
		HCPR_reg <= 1;
		en <= 0;
	end
end

endmodule
