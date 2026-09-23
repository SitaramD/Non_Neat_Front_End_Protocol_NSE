// NSE NNF 9.49 — ORDER_CONFIRMATION_OUT (2073) field extractor
// Byte-serial, big-endian. off = 0 at MESSAGE_HEADER
// (after the 22-byte Length/Seq/Checksum wrapper).
module nnf_2073_parser (
  input  logic        clk, rst_n,
  input  logic        s_valid,
  input  logic [7:0]  s_data,
  input  logic        s_last,
  output logic        conf_valid,
  output logic [63:0] order_num,    // raw DOUBLE bits — match, don't convert
  output logic [31:0] price,        // paise
  output logic [31:0] volume,
  output logic [15:0] reason_code,  // 0 = normal, 17/18 = freeze approve/reject
  output logic        closeout,     // CloseoutFlag == 'C'
  output logic        is_sell       // Buy/Sell: 1 = buy, 2 = sell
);
  logic [8:0]  off;                 // 316-byte structure
  logic [15:0] tcode, errcode, bs;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      off <= '0;  conf_valid <= 1'b0;
    end else begin
      conf_valid <= 1'b0;
      if (s_valid) begin
        if (off inside {[0:1]})     tcode       <= {tcode[7:0],       s_data};
        if (off inside {[12:13]})   errcode     <= {errcode[7:0],     s_data};
        if (off inside {[48:49]})   reason_code <= {reason_code[7:0], s_data};
        if (off == 9'd94)           closeout    <= (s_data == "C");
        if (off inside {[98:105]})  order_num   <= {order_num[55:0],  s_data};
        if (off inside {[118:119]}) bs          <= {bs[7:0],          s_data};
        if (off inside {[132:135]}) volume      <= {volume[23:0],     s_data};
        if (off inside {[140:143]}) price       <= {price[23:0],      s_data};

        off <= s_last ? '0 : off + 9'd1;
        if (s_last) conf_valid <= (tcode == 16'd2073) && (errcode == 16'd0);
      end
    end
  end

  assign is_sell = (bs == 16'd2);
endmodule
