module UTMI_TX_top 
(
 input         Clk,Rst,
 input         TX_Valid,
 input [7:0]   DataIn,
 output        TX_Ready,
 output        TX_DP,
 output        TX_DM,
 output        TX_en
);

//hold reg wire
wire sync_enable,load_data_enable,EOP_enable;
wire TX_hold_empty;
wire data_out_s;
wire sync_done,EOP_done,data_done;


//counter wires
wire [1:0] edge_count;
wire edge_cnt_enable;
//bit stuff wires
wire stuff;

//bit stuff wires
wire [1:0] bit_stuff_en;
wire data_out_stuff;

//NRZI encoding wires
wire [1:0] NRZI_en;

UTMI_TX_FSM u0(
  .Clk(Clk),
  .Rst(Rst),
  .TX_Valid(TX_Valid),
  .sync_done(sync_done),
  .TX_hold_empty(TX_hold_empty),
  .EOP_done(EOP_done),
  .TX_Ready(TX_Ready),
  .sync_enable(sync_enable),
  .load_data_enable(load_data_enable),
  .bit_stuff_en(bit_stuff_en),
  .edge_cnt_enable(edge_cnt_enable),
  .EOP_enable(EOP_enable)
  );
  
shift_hold_reg u1(
  .Clk(Clk),
  .Rst(Rst),
  .stuff(stuff),
  .DataIn(DataIn),
  .sync_enable(sync_enable),
  .load_data_enable(load_data_enable),
  .edge_count(edge_count),
  .EOP_enable(EOP_enable),
  .TX_hold_empty(TX_hold_empty), 
  .data_out_s(data_out_s),
  .sync_done(sync_done),
  .EOP_done(EOP_done),
  .data_done(data_done)
   );
   
 edge_counter u2(
 .CLK(Clk),
 .RST(Rst),
 .Enable(edge_cnt_enable),
 .sync_enable(sync_enable),
 .edge_count(edge_count)
 );
 
 bit_stuff u3(
  .Clk(Clk),
  .Rst(Rst),
  .bit_stuff_en(bit_stuff_en), 
  .data_in(data_out_s),
  .edge_count(edge_count),
  .data_done(data_done),
  .stuff(stuff),
  .data_out(data_out_stuff),
  .NRZI_en(NRZI_en)
  );
  
 NRZI_encoding u4(
  .Clk(Clk),
  .Rst(Rst),
  .data_in(data_out_stuff),
  .NRZI_en(NRZI_en),
  .edge_count(edge_count),
  .TX_DP(TX_DP),
  .TX_DM(TX_DM),
  .TX_en(TX_en)
  );
  
endmodule
