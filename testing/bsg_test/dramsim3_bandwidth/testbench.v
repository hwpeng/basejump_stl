`include "bsg_nonsynth_dramsim3.svh"


`define dram_pkg bsg_dramsim3_hbm2_8gb_x128_pkg

module testbench();

  parameter num_request_p = 2;


  bit clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg0 (
    .o(clk)
  );


  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(10)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );


  import `dram_pkg::*;

  // trace replay
  localparam payload_width_p = `dram_pkg::channel_addr_width_p;
  localparam rom_addr_width_p = 20;

  logic tr_v_lo;
  logic [payload_width_p-1:0] tr_data_lo;
  logic tr_yumi_li;

  logic [rom_addr_width_p-1:0] rom_addr;
  logic [payload_width_p+4-1:0] rom_data; 

  logic tr_done_lo;

  bsg_trace_replay #(
    .payload_width_p(payload_width_p)
    ,.rom_addr_width_p(rom_addr_width_p)
  ) tr0 (
    .clk_i(clk)
    ,.reset_i(reset)
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


  bsg_nonsynth_test_rom #(
    .filename_p("trace.tr")
    ,.data_width_p(payload_width_p+4)
    ,.addr_width_p(rom_addr_width_p)
  ) trom0 (
    .addr_i(rom_addr)
    ,.data_o(rom_data)
  );


  // request fifo
  //
  logic fifo_ready_lo;
  logic fifo_v_lo;
  logic [payload_width_p-1:0] fifo_data_lo;
  logic fifo_yumi_li;

  bsg_fifo_1r1w_small #(
    .width_p(payload_width_p)
    ,.els_p(1024)
  ) req_fifo0 (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i(tr_v_lo)
    ,.ready_o(fifo_ready_lo)
    ,.data_i(tr_data_lo)

    ,.v_o(fifo_v_lo)
    ,.data_o(fifo_data_lo)
    ,.yumi_i(fifo_yumi_li)
  );

  assign tr_yumi_li = tr_v_lo & fifo_ready_lo;


  // requester
  //
  logic dram_v_lo;
  logic [channel_addr_width_p-1:0] dram_ch_addr_lo;
  logic dram_yumi_li;
  logic dram_data_v_li;

  bsg_test_master #(
    .channel_addr_width_p(`dram_pkg::channel_addr_width_p)
    ,.num_request_p(num_request_p) // the max number of request that this thing can send out.
  ) tm0 (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i(fifo_v_lo)
    ,.ch_addr_i(fifo_data_lo)
    ,.yumi_o(fifo_yumi_li)

    ,.dram_v_o(dram_v_lo)
    ,.dram_ch_addr_o(dram_ch_addr_lo)
    ,.dram_yumi_i(dram_yumi_li)

    ,.dram_data_v_i(dram_data_v_li)
  );


  // dramsim3
  //
  logic [num_channels_p-1:0] dramsim3_v_li;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] dramsim3_ch_addr_li;
  logic [num_channels_p-1:0] dramsim3_yumi_lo;

  logic [num_channels_p-1:0] dramsim3_data_v_lo;

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
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i(dramsim3_v_li)
    ,.write_not_read_i('0) // you can only read in this test.
    ,.ch_addr_i(dramsim3_ch_addr_li)
    ,.yumi_o(dramsim3_yumi_lo)

    ,.data_v_i('0)
    ,.data_i('0)
    ,.data_yumi_o()

    ,.data_v_o(dramsim3_data_v_lo)
    ,.data_o()
  ); 

  assign dramsim3_v_li[0] = dram_v_lo;
  assign dramsim3_ch_addr_li[0] = dram_ch_addr_lo;
  assign dram_yumi_li = dramsim3_yumi_lo[0];
  assign dram_data_v_li = dramsim3_data_v_lo[0];

  for (genvar i = 1; i < `dram_pkg::num_channels_p; i++) begin
    assign dramsim3_v_li[i] = 1'b0;
    assign dramsim3_ch_addr_li[i] = '0;
  end



  // request tracker
  integer sent_r;
  integer dram_req_sent_r;
  integer recv_r;

  always_ff @ (negedge clk) begin
    if (reset) begin
      sent_r <= 0;
      recv_r <= 0;
      dram_req_sent_r <= 0;
    end
    else begin
      if (tr_v_lo & tr_yumi_li) sent_r++;
      if (dramsim3_data_v_lo) recv_r++;
      if (dram_v_lo & dram_yumi_li) dram_req_sent_r++;
    end
  end

  initial begin
    wait(tr_done_lo & (sent_r == recv_r));
    $finish();
  end


endmodule
