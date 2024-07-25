module USB_crc5(
input wire	[10:0]	data_in,
input wire	[4:0]	crc_in,
output reg	[4:0]	crc_out
);
always @(*)
begin
 crc_out[0] = crc_in[0] ^ crc_in[3] ^ crc_in[4] ^	data_in[0] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[9] ^ data_in[10];

 crc_out[1] =	crc_in[0] ^ crc_in[1] ^ crc_in[4] ^ data_in[1] ^ data_in[4] ^ data_in[6] ^ data_in[7] ^ data_in[10];

 crc_out[2] =	crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[4] ^
              data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ;

 crc_out[3] =	 crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[4] ^  
                data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10];

 crc_out[4] =	crc_in[2] ^ crc_in[3] ^ crc_in[4] ^
              data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[8] ^ data_in[9] ^ data_in[10];
end
endmodule
