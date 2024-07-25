module SIE_UTMI(
  input wire               clk_utmi,
  input wire               clk_sie,
  input wire               reset,
  //UHCI interface
  input wire    [6:0]      Address,
  input wire    [3:0]      Endpoint_address,
  input wire    [7:0]      PID,
  input wire    [10:0]     frame_no,
  input wire               sof,
  input wire               data_toggle,
  input wire               maxpacket_length,
  input wire               info_valid,
  input wire               Token_valid,
  input wire	           data_recieved,
  output wire               sof_done,
  output wire    [7:0]      Rx_Data_HC,   
  output wire    [5:0]      HC_Data_count,
  output wire               HS_Ready,
  output wire               Error_Ready,
  output wire               crc_error,
  output wire               Time_out,
  output wire               nak_o,
  output wire               stall_o,
  output wire               data_toggle_error, 
  output wire               HC_Rx_error, 
  output wire               IDLE_ready, 
  output wire               HS_corrupted,
  output wire               data_corrupted, 
  //FIFO
  input wire               fifo_empty,
  input wire    [7:0]      Tx_data_HC,
  output wire               read_enable,
  output wire               write_enable,

  input		DP, DM,
  //TX outputs
  output        	TX_DP,
  output        	TX_DM,
  output       	TX_en
  
  );
  
 wire                 tx_ready;
 wire                 tx_ready_sync;
 wire    [1:0]        line_state;
 wire                 Rx_Valid;
 wire                 Rx_active_sync;
 wire                 Rx_active;
 wire                 Rx_error_sync;
 wire                 Rx_error;
 wire    [7:0]        UTMI_Rx_Data; 
 wire                 tx_valid;
 wire                 sync_tx_valid;
 wire    [7:0]        tx_data_utmi;
 wire     [7:0]       unsync_bus;
 wire                 bus_enable;
 wire                 bus_enable_rx;
 wire    [7:0]        sync_bus;
 wire    [7:0]        sync_bus_rx;
 wire                 enable_pulse_d;
 wire    [1:0]        line_state_sync;
 wire                 eop_detection;
 wire                 eop_detection_sync;
 
 DATA_SYNC # ( 
   .NUM_STAGES(2) ,
	 .BUS_WIDTH (8) 
) U0_DATA_SYNC_tx (
.CLK(clk_utmi),
.RST(reset),
.unsync_bus(tx_data_utmi),
.bus_enable(bus_enable),
.sync_bus(sync_bus),
.enable_pulse_d(enable_pulse_d)
 );
 
  DATA_SYNC # ( 
   .NUM_STAGES(2) ,
	 .BUS_WIDTH (8) 
) U0_DATA_SYNC_rx (
.CLK(clk_sie),
.RST(reset),
.unsync_bus(UTMI_Rx_Data),
.bus_enable(bus_enable_rx),
.sync_bus(sync_bus_rx),
.enable_pulse_d(Rx_Valid)
 );
 
 BIT_SYNC U0_BIT_SYNC_linestate0(
.CLK(clk_sie),
.RST(reset),
.ASYNC(line_state[0]),
.SYNC(line_state_sync[0])
 );
 
   BIT_SYNC U0_BIT_SYNC_linestate1(
.CLK(clk_sie),
.RST(reset),
.ASYNC(line_state[1]),
.SYNC(line_state_sync[1])
 );
 
 BIT_SYNC U0_BIT_SYNC_txvalid(
.CLK(clk_utmi),
.RST(reset),
.ASYNC(tx_valid),
.SYNC(sync_tx_valid)
 );

 BIT_SYNC U0_BIT_SYNC_txready(
.CLK(clk_sie),
.RST(reset),
.ASYNC(tx_ready),
.SYNC(tx_ready_sync)
 ); 
 
  BIT_SYNC U0_BIT_SYNC_rxactive(
.CLK(clk_sie),
.RST(reset),
.ASYNC(Rx_active),
.SYNC(Rx_active_sync)
 );
 
  BIT_SYNC U0_BIT_SYNC_rxerror(
.CLK(clk_sie),
.RST(reset),
.ASYNC(Rx_error),
.SYNC(Rx_error_sync)
 );
 
  BIT_SYNC U0_eopdetect(
.CLK(clk_sie),
.RST(reset),
.ASYNC(eop_detection),
.SYNC(eop_detection_sync)
 );

 SIE_Host u1_SIE_Host(
.clk(clk_sie),
.reset(reset),
  //UHCI interface
.Address(Address),
.Endpoint_address(Endpoint_address),
.PID(PID),
.frame_no(frame_no),
.sof(sof),
.data_toggle(data_toggle),
.maxpacket_length(maxpacket_length),
.info_valid(info_valid),
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
.IDLE_ready(IDLE_ready), 
.HS_corrupted(HS_corrupted), 
.data_corrupted(data_corrupted),  
  //FIFO
.fifo_empty(fifo_empty),
.Tx_data_HC(Tx_data_HC),
.read_enable(read_enable),
.write_enable(write_enable),
.data_recieved(data_recieved),
  //UTMI
.tx_ready(tx_ready_sync),
.line_state(line_state_sync),
.Token_valid(Token_valid),
.Rx_Valid(Rx_Valid),
.Rx_active(Rx_active_sync),
.Rx_error(Rx_error_sync),
.UTMI_Rx_Data(sync_bus_rx), 
.tx_valid(tx_valid),
.tx_data_utmi(tx_data_utmi),
.bus_enable(bus_enable),
.eop_detection(eop_detection_sync)
 );
 
 UTMI_TOP u1_UTMI_TOP(
 //RX inputs
.CLK(clk_utmi),
.RST(reset),
.DP(DP),
.DM(DM),
//TX inputs
.TX_Valid(sync_tx_valid),
.DataIn(sync_bus),
//RX outputs
.Data_o(UTMI_Rx_Data),
.RX_valid(bus_enable_rx), 
.RX_active(Rx_active), 
.RX_error(Rx_error),
.LineState(line_state),
.eop_detection(eop_detection),
//TX outputs
.TX_Ready(tx_ready),
.TX_DP(TX_DP),
.TX_DM(TX_DM),
.TX_en(TX_en)
 );
 endmodule
