module bsg_test_master
  #(parameter channel_addr_width_p="inv"
    , parameter num_request_p="inv"
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [channel_addr_width_p-1:0] ch_addr_i
    , output logic yumi_o

    , output logic dram_v_o
    , output logic [channel_addr_width_p-1:0] dram_ch_addr_o
    , input dram_yumi_i

    , input dram_data_v_i
  );




  // credit counter
  logic credit_up;
  logic credit_down;
  logic [`BSG_WIDTH(num_request_p)-1:0] credit_lo;

  bsg_counter_up_down #(
    .max_val_p(num_request_p)
    ,.init_val_p(num_request_p)
    ,.max_step_p(1)
  ) cc0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.up_i(credit_up)
    ,.down_i(credit_down)
    ,.count_o(credit_lo)
  );


  assign dram_ch_addr_o = ch_addr_i;


  assign yumi_o = v_i & (credit_lo != '0) & dram_yumi_i;

  assign dram_v_o = v_i & (credit_lo != '0);

  assign credit_up = dram_data_v_i;
  assign credit_down = dram_v_o & dram_yumi_i;


endmodule 
