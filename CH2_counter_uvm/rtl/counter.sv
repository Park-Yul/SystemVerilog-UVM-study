module counter (
  input   logic         i_clk,
  input   logic         i_rst_n,
  input   logic         i_en,
  output  logic [2:0]   o_counter,
  output  logic         o_tick
);

always_ff @(posedge i_clk) begin
  if(!i_rst_n) begin
    o_counter <=  3'b0;
    o_tick    <=  1'b0;
  end
  else begin
    if(i_en) begin
        if(o_counter >= 7) begin
          o_counter <= 3'b0;
          o_tick    <= 1'b1;
        end
        else begin
          o_counter <=  o_counter + 1;
          o_tick    <=  1'b0;
        end
    end
    else begin
        o_tick    <=  1'b0;
    end
  end
end

endmodule
