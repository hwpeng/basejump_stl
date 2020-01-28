`include "bsg_nonsynth_dramsim3.svh"


`define dram_pkg bsg_dramsim3_hbm2_8gb_x128_pkg

module testbench();
  import bsg_cache_pkg::*;
  import `dram_pkg::*;

  parameter num_cache_p = 1;


  bit hbm_clk;
  bit core_clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg0 (
    .o(hbm_clk)
  );

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg1 (
    .o(core_clk)
  );


  bsg_nonsynth_reset_gen #(
    .num_clocks_p(2)
    ,.reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(10)
  ) rg0 (
    .clk_i({core_clk, hbm_clk})
    ,.async_reset_o(reset)
  );



  // driver
  localparam cache_addr_width_lp = `dram_pkg::channel_addr_width_p-$clog2(num_cache_p);
  localparam data_width_p = 32;
  localparam block_size_in_words_p = 8;
  localparam sets_p = 128;
  localparam ways_p = 8;
  
  
  logic [num_cache_p-1:0] data_v_lo;

  `declare_bsg_cache_dma_pkt_s(cache_addr_width_lp);
  bsg_cache_dma_pkt_s [num_cache_p-1:0] dma_pkt_lo;
  logic [num_cache_p-1:0] dma_pkt_v_lo;
  logic [num_cache_p-1:0] dma_pkt_yumi_li;

  logic [num_cache_p-1:0][data_width_p-1:0] dma_data_li;
  logic [num_cache_p-1:0] dma_data_v_li;
  logic [num_cache_p-1:0] dma_data_ready_lo;

  logic [num_cache_p-1:0][data_width_p-1:0] dma_data_lo;
  logic [num_cache_p-1:0] dma_data_v_lo;
  logic [num_cache_p-1:0] dma_data_yumi_li;
  
  logic [num_cache_p-1:0] cache_done_lo;


  for (genvar i = 0; i < num_cache_p; i++) begin

    if (1) begin
      // blocking
      vcache_blocking #(
        .id_p(i)
        ,.addr_width_p(cache_addr_width_lp)
        ,.data_width_p(data_width_p)
        ,.block_size_in_words_p(block_size_in_words_p)
        ,.sets_p(sets_p)
        ,.ways_p(ways_p)
      ) vb (
        .clk_i(core_clk)
        ,.reset_i(reset)

        ,.data_v_o(data_v_lo[i])

        ,.dma_pkt_o(dma_pkt_lo[i])
        ,.dma_pkt_v_o(dma_pkt_v_lo[i])
        ,.dma_pkt_yumi_i(dma_pkt_yumi_li[i])

        ,.dma_data_i(dma_data_li[i])
        ,.dma_data_v_i(dma_data_v_li[i])
        ,.dma_data_ready_o(dma_data_ready_lo[i])

        ,.dma_data_o(dma_data_lo[i])
        ,.dma_data_v_o(dma_data_v_lo[i])
        ,.dma_data_yumi_i(dma_data_yumi_li[i])

        ,.done_o(cache_done_lo[i])
      );

    end
    else begin
      // TODO: non-blocking
    end
  end

  logic hbm_req_v_lo;
  logic hbm_write_not_read_lo;
  logic [`dram_pkg::channel_addr_width_p-1:0] hbm_ch_addr_lo;
  logic hbm_req_yumi_li;
  
  logic hbm_data_v_lo;
  logic [`dram_pkg::data_width_p-1:0] hbm_data_lo;
  logic hbm_data_yumi_li;

  logic hbm_data_v_li;
  logic [`dram_pkg::data_width_p-1:0] hbm_data_li;

  
  bsg_cache_to_ramulator_hbm #(
    .num_cache_p(num_cache_p)
    ,.addr_width_p(cache_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.cache_bank_addr_width_p(cache_addr_width_lp)

    ,.hbm_channel_addr_width_p(`dram_pkg::channel_addr_width_p)
    ,.hbm_data_width_p(`dram_pkg::data_width_p)
  ) c2r (
    .core_clk_i(core_clk)
    ,.core_reset_i(reset)

    ,.dma_pkt_i(dma_pkt_lo)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_i(dma_data_ready_lo)

    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)

    ,.hbm_clk_i(hbm_clk)
    ,.hbm_reset_i(reset)

    ,.hbm_req_v_o(hbm_req_v_lo)
    ,.hbm_write_not_read_o(hbm_write_not_read_lo)
    ,.hbm_ch_addr_o(hbm_ch_addr_lo)
    ,.hbm_req_yumi_i(hbm_req_yumi_li)

    ,.hbm_data_v_o(hbm_data_v_lo)
    ,.hbm_data_o(hbm_data_lo)
    ,.hbm_data_yumi_i(hbm_data_yumi_li)

    ,.hbm_data_v_i(hbm_data_v_li)
    ,.hbm_data_i(hbm_data_li)
  );


  // dramsim3
  //
  logic [`dram_pkg::num_channels_p-1:0] dramsim3_v_li;
  logic [`dram_pkg::num_channels_p-1:0] dramsim3_write_not_read_li;
  logic [`dram_pkg::num_channels_p-1:0][`dram_pkg::channel_addr_width_p-1:0] dramsim3_ch_addr_li;
  logic [`dram_pkg::num_channels_p-1:0] dramsim3_yumi_lo;

  logic [`dram_pkg::num_channels_p-1:0][`dram_pkg::data_width_p-1:0] dramsim3_data_li;
  logic [`dram_pkg::num_channels_p-1:0] dramsim3_data_v_li;
  logic [`dram_pkg::num_channels_p-1:0] dramsim3_data_yumi_lo;

  logic [`dram_pkg::num_channels_p-1:0][`dram_pkg::data_width_p-1:0] dramsim3_data_lo;
  logic [`dram_pkg::num_channels_p-1:0] dramsim3_data_v_lo;

  bsg_nonsynth_dramsim3 #(
    .channel_addr_width_p(`dram_pkg::channel_addr_width_p)
    ,.data_width_p(`dram_pkg::data_width_p)
    ,.num_channels_p(`dram_pkg::num_channels_p)
    ,.num_columns_p(`dram_pkg::num_columns_p)
    ,.size_in_bits_p(`dram_pkg::size_in_bits_p)
    ,.address_mapping_p(`dram_pkg::address_mapping_p)
    ,.config_p(`dram_pkg::config_p)
    ,.debug_p(1)
  ) DUT (
    .clk_i(hbm_clk)
    ,.reset_i(reset)

    ,.v_i(dramsim3_v_li)
    ,.write_not_read_i(dramsim3_write_not_read_li)
    ,.ch_addr_i(dramsim3_ch_addr_li)
    ,.yumi_o(dramsim3_yumi_lo)

    ,.data_v_i(dramsim3_data_v_li)
    ,.data_i(dramsim3_data_li)
    ,.data_yumi_o(dramsim3_data_yumi_lo)

    ,.data_v_o(dramsim3_data_v_lo)
    ,.data_o(dramsim3_data_lo)
  ); 

  assign dramsim3_v_li[0] = hbm_req_v_lo;
  assign dramsim3_write_not_read_li[0] = hbm_write_not_read_lo;
  assign dramsim3_ch_addr_li[0] = hbm_ch_addr_lo;
  assign hbm_req_yumi_li = dramsim3_yumi_lo[0];

  assign dramsim3_data_v_li[0] = hbm_data_v_lo;
  assign dramsim3_data_li[0] = hbm_data_lo;
  assign hbm_data_yumi_li = dramsim3_data_yumi_lo[0];
  
  assign hbm_data_v_li = dramsim3_data_v_lo[0];
  assign hbm_data_li = dramsim3_data_lo[0];

  for (genvar i = 1; i < `dram_pkg::num_channels_p; i++) begin
    assign dramsim3_v_li[i] = 1'b0;
    assign dramsim3_write_not_read_li[i] = 1'b0;
    assign dramsim3_ch_addr_li[i] = '0;

    assign dramsim3_data_v_li[i] = 1'b0;
    assign dramsim3_data_li[i] = '0;
  end


  initial begin
    wait(&cache_done_lo);
    $finish;
  end


endmodule
