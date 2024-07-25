module shift_hold_reg (
  input             Clk,Rst,
  input             stuff,
  input      [7:0]  DataIn,
  input             sync_enable,load_data_enable,
  input      [1:0]  edge_count,
  input             EOP_enable,
  output reg        TX_hold_empty, 
  output reg        data_out_s,
  output reg        sync_done,
  output reg        EOP_done,
  output reg        data_done
   );

reg [7:0] hold_reg;
reg [2:0] bit_cnt,bit_cnt1;
reg [1:0] count;
reg sync_enable1;

always @(posedge Clk or negedge Rst)
begin
	if(!Rst)	
		bit_cnt <= 3'b0;
	else if (sync_enable && !sync_enable1)	
		bit_cnt <= 4'b0;
	else if( !stuff && edge_count == 3 )
		bit_cnt <= bit_cnt + 1;
end

always @(posedge Clk or negedge Rst)
begin
  if(!Rst)
    data_out_s <= 1'b0;
  else
	  begin
	   case(bit_cnt)	
	      3'h0: data_out_s <= hold_reg[0];
	      3'h1: data_out_s <= hold_reg[1];
	      3'h2: data_out_s <= hold_reg[2];
	      3'h3: data_out_s <= hold_reg[3];
	      3'h4: data_out_s <= hold_reg[4];
	      3'h5: data_out_s <= hold_reg[5];
	      3'h6: data_out_s <= hold_reg[6];
	      3'h7: data_out_s <= hold_reg[7];
	   endcase
	  end
end

always @(posedge Clk or negedge Rst)
begin
  if(!Rst)
    bit_cnt1 <= 1'b0;
  else
    bit_cnt1 <= bit_cnt;
end

always @(posedge Clk or negedge Rst)
begin
  if (!Rst)
    TX_hold_empty <= 1'b0;
  else if ( !stuff && bit_cnt1 == 6 && bit_cnt ==7)
    TX_hold_empty <= 1'b1;
  else
    TX_hold_empty <= 1'b0;
end

always @(posedge Clk or negedge Rst)
begin
  if (!Rst)
    begin
     count <= 0;
     EOP_done <= 1'b0;
     hold_reg <= 8'b00000000;
     data_done <= 1'b0;
    end
  else if (sync_enable)
   begin
      EOP_done <= 1'b0;
      data_done <= 1'b0;
	    hold_reg <= 8'b10000000;
	   end
	else if(load_data_enable)	
	  begin
	    EOP_done <= 1'b0;
	    data_done <= 1'b0;
	    hold_reg <= DataIn;
	   end
	else if (EOP_enable && !EOP_done)
	  begin
	    data_done <= 1'b1;
	    hold_reg[0] <= 1'b0;
      hold_reg[1] <= 1'b0;
      hold_reg[2] <= 1'b1;
      hold_reg[3] <= 1'b1;
	    if (bit_cnt1 == 3 && bit_cnt ==4)
	       EOP_done <= 1'b1;
	    else
	       EOP_done <= 1'b0;
	  end
	else if(EOP_done)
	  begin
	    EOP_done <= 1'b0;
	    data_done <= 1'b0;
	    hold_reg <= 8'b11111111;
	  end
end

always @(posedge Clk or negedge Rst)
begin
  if (!Rst)
    sync_done <= 1'b0;
  else if ( sync_enable && bit_cnt1 == 6 && bit_cnt ==7 )
    sync_done <= 1'b1;
  else
    sync_done <= 1'b0;
end

always @(posedge Clk)
begin
  sync_enable1 <= sync_enable;
end

endmodule


