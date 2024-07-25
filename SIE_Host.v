module SIE_Host (
  input wire               clk,
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
  input wire		   data_recieved,
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
  //UTMI
  input wire               tx_ready,
  input wire    [1:0]      line_state,
  input wire               Rx_Valid,
  input wire               Rx_active,
  input wire               Rx_error,
  input wire    [7:0]      UTMI_Rx_Data,
  input wire                eop_detection, 
  output wire               tx_valid,
  output wire    [7:0]      tx_data_utmi,
  output wire               bus_enable
  );
  
  wire      Ack;
  wire      in_transfer;
  wire      HS_transfer;
  wire      enable;
  
//////////////Packet Encode//////////////////////////
PacketEncode_USB U0_PacketEncode_USB (
.clk(clk),
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
.fifo_empty(fifo_empty),
.Tx_data_HC(Tx_data_HC),
.read_enable(read_enable),
.tx_ready(tx_ready),
.line_state(line_state),
.tx_valid(tx_valid),
.tx_data_utmi(tx_data_utmi),
.Ack(Ack),
.in_transfer(in_transfer),
.bus_enable(bus_enable),
.IDLE_ready(IDLE_ready),
.HS_transfer(HS_transfer),
.enable(enable)
);


//////////////Packet Decode//////////////////////////

packetdecode U1_packetdecode (

.CLK(clk),
.RST(reset),
.in_transfer(in_transfer),
.Data_toggle(data_toggle),
.info_Ready(info_valid),
.Rx_Valid(Rx_Valid),
.Rx_active(Rx_active),
.Rx_error(Rx_error),
.UTMI_Rx_Data(UTMI_Rx_Data),
.Rx_Data_HC(Rx_Data_HC),
.HC_Data_count(HC_Data_count),
.write_enable(write_enable),
.HS_Ready(HS_Ready),
.Error_Ready(Error_Ready),
.crc_error(crc_error),
.ack_in(Ack),
.Time_out(Time_out),
.nak_o(nak_o),
.stall_o(stall_o),
.data_toggle_error(data_toggle_error),
.maxpacket_length(maxpacket_length),
.HC_Rx_error(HC_Rx_error),
.eop_detection( eop_detection),
.HS_transfer(HS_transfer),
.enable_pid(enable),
.HS_corrupted(HS_corrupted),
.data_recieved(data_recieved),
.data_corrupted(data_corrupted)
);



endmodule
