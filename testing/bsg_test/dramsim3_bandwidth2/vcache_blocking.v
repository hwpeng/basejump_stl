module vcache_blocking
  import bsg_cache_pkg::*;
  #(parameter id_p="inv"
    , parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter sets_p="inv"
    , parameter ways_p="inv"


    , parameter dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
  )
  (
    input clk_i
    , input reset_i

    , output logic data_v_o // cache request processed

    , output logic [dma_pkt_width_lp-1:0] dma_pkt_o
    , output logic dma_pkt_v_o
    , input dma_pkt_yumi_i

    , input [data_width_p-1:0] dma_data_i
    , input dma_data_v_i
    , output logic dma_data_ready_o
  
    , output logic [data_width_p-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_yumi_i 

    , output logic done_o
  );

  localparam rom_filename_lp=$sformatf("trace_%0d.tr",id_p);

  // trace replay
  typedef struct packed {
    logic write_not_read;
    logic [addr_width_p-1:0] addr;
  } payload_s;
  

  localparam payload_width_lp = $bits(payload_s);
  localparam rom_addr_width_lp = 20;

  logic tr_v_lo;
  payload_s tr_data_lo;
  logic tr_yumi_li;

  logic [rom_addr_width_lp-1:0] rom_addr;
  logic [payload_width_lp+4-1:0] rom_data; 

  logic tr_done_lo;

  bsg_trace_replay #(
    .payload_width_p(payload_width_lp)
    ,.rom_addr_width_p(rom_addr_width_lp)
  ) tr0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.en_i(1'b1)

    ,.v_i(1'b0)
    ,.data_i('0)
    ,.ready_o()
    
    ,.v_o(tr_v_lo)
    ,.data_o(tr_data_lo)
    ,.yumi_i(tr_yumi_li)

    ,.rom_addr_o(rom_addr)
    ,.rom_data_i(rom_data)
 
    ,.done_o(tr_done_lo)
    ,.error_o()
  ); 

  // test rom
  bsg_nonsynth_test_rom #(
    .filename_p(rom_filename_lp)
    ,.data_width_p(payload_width_lp+4)
    ,.addr_width_p(rom_addr_width_lp)
  ) trom0 (
    .addr_i(rom_addr)
    ,.data_o(rom_data)
  );


  // the vcache
  `declare_bsg_cache_pkt(addr_width_p,data_width_p);
  bsg_cache_pkt_s cache_pkt;
  logic cache_pkt_v_li;
  logic cache_pkt_ready_lo;

  bsg_cache #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
  ) vcache (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.cache_pkt_i(cache_pkt)
    ,.v_i(cache_pkt_v_li)
    ,.ready_o(cache_pkt_ready_lo)
    
    ,.data_o()
    ,.v_o(data_v_o)
    ,.yumi_i(data_v_o) // accept right away

    ,.dma_pkt_o(dma_pkt_o)
    ,.dma_pkt_v_o(dma_pkt_v_o)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_i)

    ,.dma_data_i(dma_data_i)
    ,.dma_data_v_i(dma_data_v_i)
    ,.dma_data_ready_o(dma_data_ready_o)

    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_yumi_i(dma_data_yumi_i)

    ,.v_we_o()
  );

  assign cache_pkt_v_li = tr_v_lo;
  assign tr_yumi_li = cache_pkt_ready_lo & tr_v_lo;

  assign cache_pkt.opcode = tr_data_lo.write_not_read
    ? SW
    : LW;

  assign cache_pkt.mask = 4'b1111;
  assign cache_pkt.data = '0;
  assign cache_pkt.addr = tr_data_lo.addr;

  // tracker
  integer sent_r;
  integer recv_r;

  always_ff @ (negedge clk_i) begin
    if (reset_i) begin
      sent_r <= 0;
      recv_r <= 0;
    end
    else begin
      if (tr_yumi_li) sent_r++;
      if (data_v_o) recv_r++; 
    end
  end

  assign done_o = (sent_r == recv_r) & tr_done_lo;

endmodule
