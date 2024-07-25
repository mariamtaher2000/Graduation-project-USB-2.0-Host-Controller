module RegFile #(parameter WIDTH = 8, DEPTH = 6, ADDR = 6)

(
input                         clk,
input                         rst_n,
//From AXI interface
input                         WrEn,
input            [ADDR-1:0]   Address,
input            [WIDTH-1:0]  WrData,
input                         RdEn,
output    reg    [WIDTH-1:0]  RdData,
//error logic
input                         RS_in,
input                         HCR_halt_err,
input                         HCPR_reg,
input                         en,
//fsm
input                         Terminate_reg,
//sof gen input
input             [3:0]       F_no,       //Frame Number from SOF Generator
input                         HCR_halt_sof,
//ouputs
output   wire                 RS,         //Run/Stop
output   wire    [3:0]        FRNUM,      //Frame Number
output   wire    [1:0]        FLBASEADD,   //Frame List Base Address
output   reg                  Data_toggle_RF
);

integer I ;
  
// register file of 7 registers each of 32 bits width
reg [WIDTH-1:0] Mem [DEPTH-1:0] ;    

reg        [ADDR-1:0]   Address_reg;

always @(posedge clk or negedge rst_n)
 begin
   if(!rst_n)  // Asynchronous active low reset 
    begin
    Data_toggle_RF <= 1;	///////////////////////////////////////////////////////////////////////////
    Address_reg <= 0;
    for (I=0 ; I < DEPTH ; I = I +1)
        begin
            if (I==1) begin
                //Mem[I] <= 'd64;
                Mem[I] <= 'b01000000;   //SOF modify registers
            end
            else if(I==4) begin
            // HCR_halt register = 1 as the host will be halted till the driver finishes editing the memory
            // and then sets that register to 0 and RS to 1
                Mem[I] <= 'b00000010;       
            end
            else begin
                Mem[I] <= 'b0;                
            end
        end
   end
   // AXI
   else if (WrEn) begin
       Mem[Address] <= WrData;
   end
   else begin
	if (RdEn) begin
        Data_toggle_RF <= !Data_toggle_RF;
        RdData <= Mem[Address];
   end 
   //
      if (en) begin
          Mem[5][0] <= RS_in;
          Mem[4][1] <= HCR_halt_err || HCR_halt_sof;
          Mem[4][0] <= HCPR_reg;
      end 
      else begin
          Mem[4][1] <= HCR_halt_sof;
      end
      Mem[3][3:0] <= F_no;      //Frame Number
      Mem[4][2]   <= Terminate_reg;
  end
end


assign RS         = Mem[5][0];
assign FRNUM      = Mem[3][3:0];
assign FLBASEADD  = Mem[2][5:4];

endmodule
