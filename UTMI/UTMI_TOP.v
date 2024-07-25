module UTMI_TOP (
//RX inputs
input		CLK,RST,
input		DP, DM,
//TX inputs
input         	TX_Valid,
input [7:0]   	DataIn,

//RX outputs
output [7:0]	Data_o,
output		RX_valid, RX_active, RX_error,eop_detection,
output [1:0]	LineState,
//TX outputs
output        	TX_Ready,
output        	TX_DP,
output        	TX_DM,
output       	TX_en

);

UTMI_TX_top T0  (.Clk(CLK),
 		 .Rst(RST),
 		 .TX_Valid(TX_Valid),
 		 .DataIn(DataIn),
 		 .TX_Ready(TX_Ready),
		 .TX_DP(TX_DP),
		 .TX_DM(TX_DM),
 		 .TX_en(TX_en));

RX_TOP R0 (.CLK(CLK),
 	   .RST(RST),
 	   .TX_en(TX_en),
 	   .TX_DP(TX_DP),
	   .TX_DM(TX_DM),
 	   .DP(DP),
	   .DM(DM),
	   .Data_o(Data_o),
	   .RX_valid(RX_valid),
	   .RX_active(RX_active),
 	   .RX_error(RX_error),
 	   .eop_detection(eop_detection),
	   .LineState(LineState));

endmodule 
