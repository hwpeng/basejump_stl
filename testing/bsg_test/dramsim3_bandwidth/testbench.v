`include "bsg_nonsynth_dramsim3.svh"


`define dram_pkg bsg_dramsim3_hbm2_8gb_x128_pkg

module testbench();

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
  localparam payload_width_p = `dram_pkg::channel_addr_width_p + 1;
  localparam rom_addr_width_p = 20;

  typedef struct packed {
    logic write_not_read;
    logic [`dram_pkg::channel_addr_width_p-1:0] ch_addr;
  } trace_s;

  trace_s tr_data_lo;
  logic tr_v_lo;
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


  // dramsim3
  //
  logic [num_channels_p-1:0] dramsim3_v_li;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] dramsim3_ch_addr_li;
  logic [num_channels_p-1:0] dramsim3_yumi_lo;
  logic [num_channels_p-1:0] dramsim3_write_not_read_li;

  logic [num_channels_p-1:0] dramsim3_data_v_lo;
  logic [num_channels_p-1:0] dramsim3_write_done_lo;

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
    ,.write_not_read_i(dramsim3_write_not_read_li)
    ,.ch_addr_i(dramsim3_ch_addr_li)
    ,.yumi_o(dramsim3_yumi_lo)

    ,.data_v_i('0)
    ,.data_i('0)
    ,.data_yumi_o()

    ,.data_v_o(dramsim3_data_v_lo)
    ,.data_o()

    ,.write_done_o(dramsim3_write_done_lo)
    ,.write_done_ch_addr_o()
  ); 

  assign dramsim3_v_li[0] = tr_v_lo;
  assign dramsim3_write_not_read_li[0] = tr_data_lo.write_not_read;
  assign dramsim3_ch_addr_li[0] = tr_data_lo.ch_addr;
  assign tr_yumi_li = dramsim3_yumi_lo[0];

  for (genvar i = 1; i < `dram_pkg::num_channels_p; i++) begin
    assign dramsim3_v_li[i] = 1'b0;
    assign dramsim3_ch_addr_li[i] = '0;
    assign dramsim3_write_not_read_li[i] = 1'b0;
  end

  // request tracker
  integer sent_r;
  integer recv_r;

  always_ff @ (negedge clk) begin
    if (reset) begin
      sent_r <= 0;
      recv_r <= 0;
    end
    else begin
      if (tr_v_lo & tr_yumi_li) sent_r <= sent_r + 1;
      recv_r <= recv_r + dramsim3_data_v_lo[0] + dramsim3_write_done_lo[0];
    end
  end

  initial begin
    wait(tr_done_lo & (sent_r == recv_r));
    $finish();
  end


endmodule
