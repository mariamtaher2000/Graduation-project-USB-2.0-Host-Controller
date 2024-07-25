
// Dual-Port BRAM with Byte Write/read EnaBle
// 1kB
//_____________________________Size Calculation Details_____________________________________// 
// Assumption 16 TD, 16 Frame , 32Byte Max. packet size
// 16 TD each one is 16Byte >> 16*16B
// 16 Frame each one is 32Bits >> 16 memory location
// two memory location for each TD data >>32
// Total size = 64*16Bytes = 1KByte
//_______________________________________Port A_____________________________________________// 

// connected to UHCI with clock 12MHz
// double word write enable using 4 bits write enable 
// w_A  0000 read all DWords
// w_A  0001 write first DWord
// w_A  0010 write seconed DWord
// w_A  0100 write third DWord
// w_A  1000 write fourth DWord
// w_A  1111 write all DWords
//_______________________________________Port B_____________________________________________// 

// connected to AXI slave 
// double word write enable using 4 bits write enable 
// w_B  0001 write first DWord
// w_B  0010 write seconed DWord
// w_B  0100 write third DWord
// w_B  1000 write fourth DWord
// double word read enable using 4 bits read enable 
// r_B  0001 read first DWord
// r_B  0010 read second DWord
// r_B  0100 read third DWord
// r_B  1000 read fourth DWord


module dual_memory #(
parameter   NUM_COL      =  4,      // to devide each location into 4 Dwords
parameter   COL_WIDTH    =  32,     // width of eash Dword
parameter   ADDR_WIDTH   =  6,      // Addr  Width in bits : 2**ADDR_WIDTH = RAM Depth
parameter   DATA_WIDTH   =  NUM_COL*COL_WIDTH  // Data  Width in bits
)
(
input clk,rst_n,
input En_A,                         //to enable port A
input [NUM_COL-1:0] w_A,            // write enable
input [ADDR_WIDTH-1:0] addrA,
input [DATA_WIDTH-1:0] dinA,
output reg [DATA_WIDTH-1:0] doutA,

input En_B,                         //to enable port B
input [NUM_COL-1:0] w_B,r_B,        // write/read enable
input [ADDR_WIDTH-1:0] addrB,
input [COL_WIDTH-1:0] dinB,
output reg Data_toggle,
output reg [COL_WIDTH-1:0] doutB
);

//_______________________________________Core Memory___________________________________________// 

reg [DATA_WIDTH-1:0] memory [(2**ADDR_WIDTH)-1:0];

//________________________________________Operation____________________________________________// 

reg [ADDR_WIDTH-1:0] addrB_reg;
reg [NUM_COL-1:0] r_B_reg;
integer j;

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		doutA <= 'b0;
		doutB <= 'b0;
		Data_toggle <= 'b1;
		addrB_reg <= 'b0;
		r_B_reg   <= 'b0;
		for (j=0 ; j < 2**ADDR_WIDTH ; j = j +1)
        begin
             memory [j] <= 'b0;                
        end
	end
	else if(En_B) begin
		//
		case (r_B)
		4'b0001: begin 
			if((addrB_reg != addrB) || (r_B_reg != r_B) ) begin
				Data_toggle <= !Data_toggle;
				addrB_reg <= addrB;
				r_B_reg <= r_B;
			end
			else begin
				Data_toggle <= Data_toggle;
			end
			doutB <= memory[addrB][31 : 0];
			end
		4'b0010: begin 
			if((addrB_reg != addrB) || (r_B_reg != r_B) ) begin
				Data_toggle <= !Data_toggle;
				addrB_reg <= addrB;
				r_B_reg <= r_B;
			end
			else begin
				Data_toggle <= Data_toggle;
			end
			doutB <= memory[addrB][63 : 32];
			end
		4'b0100: begin 
			if((addrB_reg != addrB) || (r_B_reg != r_B) ) begin
				Data_toggle <= !Data_toggle;
				addrB_reg <= addrB;
				r_B_reg <= r_B;
			end
			else begin
				Data_toggle <= Data_toggle;
			end
			doutB <= memory[addrB][95 : 64];
			end
		4'b1000: begin 
			if((addrB_reg != addrB) || (r_B_reg != r_B) ) begin
				Data_toggle <= !Data_toggle;
				addrB_reg <= addrB;
				r_B_reg <= r_B;
			end
			else begin
				Data_toggle <= Data_toggle;
			end
			doutB <= memory[addrB][127 : 96];
			end
		default: begin 
			Data_toggle <= Data_toggle;
			doutB <= 0;
			end
		endcase
		//
		//
		case(w_B)
		4'b0001:memory[addrB][31:0]   <= dinB;
		4'b0010:memory[addrB][63:32]  <= dinB;
		4'b0100:memory[addrB][95:64]  <= dinB;
		4'b1000:memory[addrB][127:96] <= dinB;
		default:memory[addrB] <= memory[addrB];
		endcase
	end
	else if(En_A) begin
		if (~|w_A)
		doutA <= memory[addrA];
		else begin
			case(w_A)
			4'b0001:memory[addrA][31:0]   <= dinA[31:0];
			4'b0010:memory[addrA][63:32]  <= dinA[63:32];
			4'b0100:memory[addrA][95:64]  <= dinA[95:64];
			4'b1000:memory[addrA][127:96] <= dinA[127:96];
			4'b1111:memory[addrA] <= dinA;
			default:memory[addrA] <= memory[addrA];
			endcase
		end
	end

end

endmodule

