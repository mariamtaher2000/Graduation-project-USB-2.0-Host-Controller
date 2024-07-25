module USB_crc16(
  input wire       clk,
  input wire      reset,
  input wire      crc_done,
  input wire [7:0] data_in,
  input wire      crc_enable,
  output wire [15:0] crc_out
);
reg [15:0] crc_q;
reg [15:0] crc_qo;

assign crc_out = crc_qo;

always @(*)
begin

crc_qo[0] = crc_q[8] ^ crc_q[9] ^ crc_q[10] ^ crc_q[11] ^ crc_q[12] ^ crc_q[13] ^ crc_q[14] ^ crc_q[15] 
            ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
            
crc_qo[1] = crc_q[9] ^ crc_q[10] ^ crc_q[11] ^ crc_q[12] ^ crc_q[13] ^ crc_q[14] ^ crc_q[15]
            ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
            
crc_qo[2] = crc_q[8] ^ crc_q[9] ^ data_in[0] ^ data_in[1];

crc_qo[3] = crc_q[9] ^ crc_q[10] ^ data_in[1] ^ data_in[2];

crc_qo[4] = crc_q[10] ^ crc_q[11] ^ data_in[2] ^ data_in[3];

crc_qo[5] = crc_q[11] ^ crc_q[12] ^ data_in[3] ^ data_in[4];

crc_qo[6] = crc_q[12] ^ crc_q[13] ^ data_in[4] ^ data_in[5];

crc_qo[7] = crc_q[13] ^ crc_q[14] ^ data_in[5] ^ data_in[6];

crc_qo[8] = crc_q[0] ^ crc_q[14] ^ crc_q[15] ^ data_in[6] ^ data_in[7];

crc_qo[9] = crc_q[1] ^ crc_q[15] ^ data_in[7];

crc_qo[10] = crc_q[2];

crc_qo[11] = crc_q[3];

crc_qo[12] = crc_q[4];

crc_qo[13] = crc_q[5];

crc_qo[14] = crc_q[6];

crc_qo[15] = crc_q[7] ^ crc_q[8] ^ crc_q[9] ^ crc_q[10] ^ crc_q[11] ^ crc_q[12] ^ crc_q[13] ^ crc_q[14] ^ crc_q[15]
              ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
            
end
			

always@(posedge clk or negedge reset)
begin
  if (!reset)
    begin
      crc_q <= 16'hffff;
    end
    else if (crc_done)
      crc_q <= 16'hffff;
    else if(crc_enable)
      begin
       crc_q <= crc_qo ; 
        end
        else
          begin
            crc_q <= crc_q;
            end
end
endmodule



