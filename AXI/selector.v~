module selector # ( parameter OUT1 = 32 , parameter OUT2 = 32  ) 
(
  input                  reg_mem,
  input      [31:0]      A,
  output reg [OUT1-1:0]  OUT_1,
  output reg [OUT2-1:0]  OUT_2
  );
  
always @(*)
begin
    case( reg_mem)
        1'b0: begin 
		OUT_1 = A[OUT1-1:0]; // memory
		OUT_2 = 0; //
	end
        1'b1: begin
		OUT_2 = A[OUT2-1:0]; // reg_file
		OUT_1 = 0; //
	end
    endcase
end
      
endmodule
