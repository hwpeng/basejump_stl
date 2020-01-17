module testbench();


  bit clk;
  bit reset;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(100)
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


  // trace replay
  localparam payload_width_p = 10;
  localparam rom_addr_width_p = 16;

  logic tr_v_lo;
  logic [payload_width_p-1:0] tr_data_lo;
  logic tr_yumi_li;

  logic [rom_addr_width_p-1:0] rom_addr;
  logic [payload_width_p+4-1:0] rom_data; 

  logic tr_done_lo;

  bsg_trace_replay #(
    .payload_width_p()
    ,.rom_addr_width_p()
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
    ,.els_p(16)
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

  // requester
  //
  bsg_test_master #(
  ) tm0 (
    .clk_i(clk)
    ,.reset_i(reset)

  );

  // dramsim3
  //
  bsg_nonsynth_dramsim3 #(
    .channel_addr_width_p()
    ,.data_width_p()
    ,.num_channels_p()
    ,.num_columns_p()
    ,.address_mapping_p()
    ,.size_in_bits_p()
    ,.config_p()
  ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i()
    ,.write_not_read_i()
    ,.ch_addr_i()
    ,.yumi_o()

    ,.data_v_i()
    ,.data_i()
    ,.data_yumi_o()

    ,.data_v_o()
    ,.data_o()
  ); 




endmodule
