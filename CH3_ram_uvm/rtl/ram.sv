module ram(
  input   logic       i_clk,
  input   logic       i_we,
  input   logic [7:0] i_addr,
  input   logic [7:0] i_wdata,
  output  logic [7:0] o_rdata
);

  // ram_file
  logic [7:0] ram_file[0:255];

  // CL
  assign o_rdata = ram_file[i_addr];

  // SL
  always_ff @(posedge i_clk) begin
    if(i_we) begin
      ram_file[i_addr] <=  i_wdata;
    end
  end
endmodule
