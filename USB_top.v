module USB_top #(parameter DSIZE = 8,parameter ASIZE = 5,b_a_w = 2, f_n_w = 4, 
    MEM_ADDR_WIDTH = 6, MEM_NUM_COL=4, MEM_COL_WIDTH=32, MEM_DATA_WIDTH =MEM_COL_WIDTH*MEM_NUM_COL)
(
  input wire        SIE_clk,
  input wire        UTMI_clk,
  input wire        reset,
  input		    DP, DM,
  input             Reg_WrEn,
  input             [MEM_ADDR_WIDTH-1:0]   Reg_Address,
  input             [7:0]  Reg_WrData,
  input             Reg_RdEn,
  output            [7:0]  Reg_RdData,
  output            TX_DP,
  output            TX_DM,
  output       	    TX_en,
  input wire        En_B,
  input wire        [MEM_NUM_COL-1:0] w_B,r_B,
  input wire        [MEM_ADDR_WIDTH-1:0] addrB,
  input wire        [MEM_COL_WIDTH-1:0] dinB,
  output wire       Data_toggle_Mem,
  output wire       [MEM_COL_WIDTH-1:0] doutB,
  output wire                           Data_toggle_RF,
  output            UHCI_clk
  );

// internal connections
wire    [6:0]       Address;
wire    [3:0]       Endpoint_address;
wire    [7:0]       PID;
wire    [10:0]      frame_no;
wire                sof;
wire                data_toggle;
wire                maxpacket_length;
wire                info_valid;
wire                Token_valid;
wire                sof_done;
wire    [7:0]       Rx_Data_HC;  
wire    [5:0]       HC_Data_count;
wire                HS_Ready;
wire                Error_Ready;
wire                crc_error;
wire                Time_out;
wire                nak_o;
wire                stall_o;
wire                data_toggle_error; 
wire                HC_Rx_error;  
 wire               fifo_empty;
wire    [7:0]       Tx_data_HC;
wire                read_enable;
wire                write_enable;
wire                Idle_ready;
wire                Idle_ready_sync;
wire                HS_corrupted;
wire                data_corrupted;
wire		    data_recieved;

ClkDiv   U0_ClkDiv(
.i_ref_clk(SIE_clk),
.i_rst_n(reset),
.i_clk_en(1'b1),
.i_div_ratio(4'd4),
.o_div_clk(UHCI_clk)
  );

BIT_SYNC U0_BIT_SYNC_HC(
.CLK(UHCI_clk),
.RST(reset),
.ASYNC(Idle_ready),
.SYNC(Idle_ready_sync)
 );

SIE_UTMI U0_SIE_UTMI (
.clk_sie(SIE_clk),
.clk_utmi(UTMI_clk),
.reset(reset),
.Address(Address),
.Endpoint_address(Endpoint_address),
.PID(PID),
.frame_no(frame_no),
.sof(sof),
.data_toggle(data_toggle),
.maxpacket_length(maxpacket_length),
.info_valid(info_valid),
.Token_valid(Token_valid),
.sof_done(sof_done),
.Rx_Data_HC(Rx_Data_HC),   
.HC_Data_count(HC_Data_count),
.HS_Ready(HS_Ready),
.Error_Ready(Error_Ready),
.crc_error(crc_error),
.Time_out(Time_out),
.nak_o(nak_o),
.stall_o(stall_o),
.data_toggle_error(data_toggle_error), 
.HC_Rx_error(HC_Rx_error),   
.fifo_empty(fifo_empty),
.Tx_data_HC(Tx_data_HC),
.read_enable(read_enable),
.write_enable(write_enable),
.DP(DP), 
.DM(DM),
.TX_DP(TX_DP),
.TX_DM(TX_DM),
.TX_en(TX_en),
.IDLE_ready(Idle_ready),
.data_corrupted(data_corrupted),
.HS_corrupted(HS_corrupted),
.data_recieved(data_recieved)
);

UHCI_ctrl_top #(DSIZE,ASIZE,b_a_w,f_n_w,MEM_ADDR_WIDTH,MEM_NUM_COL,MEM_COL_WIDTH,MEM_DATA_WIDTH) U0_UHCI_ctrl_top(
.UHCI_clk(UHCI_clk),
.SIE_clk(SIE_clk),
.rst_n(reset),
.Reg_WrEn(Reg_WrEn),
.Reg_Address(Reg_Address),
.Reg_WrData(Reg_WrData),
.Reg_RdEn(Reg_RdEn),
.Reg_RdData(Reg_RdData),
.Data_toggle_RF(Data_toggle_RF),
.rx_sie_data(Rx_Data_HC),
.SIE_data_w_en(write_enable),
.tx_fifo_r_en(read_enable),
.tx_sie_data(Tx_data_HC),
.tx_fifo_empty(fifo_empty),
.En_B(En_B),
.w_B(w_B),
.r_B(r_B),
.addrB(addrB),
.dinB(dinB),
.Data_toggle(Data_toggle_Mem),
.doutB(doutB),
.SOF_done(sof_done),
.Idle_ready(Idle_ready_sync),
.CRC_error(crc_error),
.timeout_error(Time_out),
.NAK_received(nak_o),
.stall_recieved(stall_o),
.UTMI_error(HC_Rx_error),
.data_toggle_error(data_toggle_error),
.act_length(HC_Data_count),
.errs_ready(Error_Ready),   
.handshake_ready(HS_Ready),  
.PID(PID),
.device_address(Address),
.endpoint_address(Endpoint_address),
.data_toggle(data_toggle),
.max_length_flag(maxpacket_length),  
.PID_ready(Token_valid), 
.send_SOF_packet(sof),
.information_ready(info_valid),
.frame_num_SIE(frame_no),
.handshake_error(HS_corrupted),
.PID_error(data_corrupted),
.SIE_r_en(data_recieved)
);

endmodule
