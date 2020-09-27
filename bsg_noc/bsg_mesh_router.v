/**
 *    bsg_mesh_router.v
 *
 */  


module bsg_mesh_router
  import bsg_noc_pkg::*;
  import bsg_mesh_router_pkg::*;
  #(parameter width_p = -1
    , parameter x_cord_width_p = -1
    , parameter y_cord_width_p = -1
    , parameter ruche_factor_X_p = 0
    , parameter ruche_factor_Y_p = 0
    , parameter broadcast_1d_p = 0
    , parameter dims_p = 2
    , parameter dirs_lp = (2*dims_p)+1
    , parameter XY_order_p = 1
    , parameter bit [dirs_lp-1:0][dirs_lp-1:0]  routing_matrix_p = 
      (dims_p == 2) ? (broadcast_1d_p ? Broadcast_1D : (XY_order_p ? StrictXY : StrictYX)) : (
      (dims_p == 3) ? (XY_order_p ? HalfRucheX_StrictXY : HalfRucheX_StrictYX) : "inv")

    , parameter debug_p = 0
  )
  (
    input clk_i
    , input reset_i

    , input [dirs_lp-1:0][width_p-1:0] data_i
    , input [dirs_lp-1:0]              v_i
    , output logic [dirs_lp-1:0]       yumi_o

    , input   [dirs_lp-1:0]               ready_i
    , output  [dirs_lp-1:0] [width_p-1:0] data_o
    , output logic [dirs_lp-1:0]          v_o

    // node's x and y coord
    , input   [x_cord_width_p-1:0] my_x_i           
    , input   [y_cord_width_p-1:0] my_y_i
  );


  // input x,y coords
  logic [dirs_lp-1:0][x_cord_width_p-1:0] x_dirs;
  logic [dirs_lp-1:0][y_cord_width_p-1:0] y_dirs;

  for (genvar i = 0; i < dirs_lp; i++) begin
    assign x_dirs[i] = data_i[i][0+:x_cord_width_p];
    assign y_dirs[i] = data_i[i][x_cord_width_p+:y_cord_width_p];
  end


  // dimension-ordered routing logic
  logic [dirs_lp-1:0][dirs_lp-1:0] req, req_t;

  for (genvar i = 0; i < dirs_lp; i++) begin: dor
    bsg_mesh_router_decoder_dor #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.ruche_factor_X_p(ruche_factor_X_p)
      ,.ruche_factor_Y_p(ruche_factor_Y_p)
      ,.broadcast_1d_p(broadcast_1d_p)
      ,.dims_p(dims_p)
      ,.XY_order_p(XY_order_p)
      ,.from_p((dirs_lp)'(1 << i))
      ,.debug_p(debug_p)
    ) dor_decoder (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.v_i(v_i[i])
      ,.x_dirs_i(x_dirs[i])
      ,.y_dirs_i(y_dirs[i])
      ,.my_x_i(my_x_i)
      ,.my_y_i(my_y_i)

      ,.req_o(req[i])
    );
  end

  bsg_transpose #(
    .width_p(dirs_lp)
    ,.els_p(dirs_lp) 
  ) req_tp (
    .i(req)
    ,.o(req_t)
  );



  // Instantiate crossbars for each output direction
  logic [dirs_lp-1:0][dirs_lp-1:0] yumi_lo, yumi_lo_t;

  for (genvar i = 0; i < dirs_lp; i++) begin: xbar

    localparam input_els_lp = `BSG_COUNTONES_SYNTH(routing_matrix_p[i]);

    logic [input_els_lp-1:0][width_p-1:0] conc_data;
    logic [input_els_lp-1:0] conc_req;
    logic [input_els_lp-1:0] grants;
    logic [input_els_lp-1:0] conc_yumi;
    
    bsg_array_concentrate_static #(
      .pattern_els_p(routing_matrix_p[i])
      ,.width_p(width_p)
    ) conc0 (
      .i(data_i)
      ,.o(conc_data)
    );

    bsg_concentrate_static #(
      .pattern_els_p(routing_matrix_p[i])
    ) conc1 (
      .i(req_t[i])
      ,.o(conc_req)
    );

    if (broadcast_1d_p == 0)
        assign v_o[i] = |conc_req;
    else
        assign v_o[i] = |(grants & conc_yumi);

    bsg_arb_round_robin #(
      .width_p(input_els_lp)
    ) rr (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.reqs_i(conc_req)
      ,.grants_o(grants)
      ,.yumi_i((|conc_req) & ready_i[i])
    );

    bsg_mux_one_hot #(
      .els_p(input_els_lp)
      ,.width_p(width_p)
    ) data_mux (
      .data_i(conc_data)
      ,.sel_one_hot_i(grants)
      ,.data_o(data_o[i])
    );

    bsg_unconcentrate_static #(
      .pattern_els_p(routing_matrix_p[i])
      ,.unconnected_val_p(1'b0)
    ) unconc0 (
      .i(grants & {input_els_lp{ready_i[i]}})
      ,.o(yumi_lo[i])
    );

    bsg_concentrate_static #(
      .pattern_els_p(routing_matrix_p[i])
    ) conc2 (
      .i(yumi_o)
      ,.o(conc_yumi)
    );

  end


  bsg_transpose #(
    .width_p(dirs_lp)
    ,.els_p(dirs_lp) 
  ) yumi_tp (
    .i(yumi_lo)
    ,.o(yumi_lo_t)
  );


  for (genvar i = 0; i < dirs_lp; i++) begin
    if (broadcast_1d_p == 0)
        assign yumi_o[i] = |yumi_lo_t[i];
    else
        assign yumi_o[i] = (req[i] == yumi_lo_t[i]);
  end



  // synopsys translate_off
  if (debug_p) begin
    always_ff @ (negedge clk_i) begin

      if (~reset_i) begin
        for (integer i = 0; i < dirs_lp; i++) begin
          if (broadcast_1d_p == 0)
            assert($countones(yumi_lo_t[i]) < 2)
              else $fatal("multiple yumi detected. i=%d, %b", i, yumi_lo_t[i]);
        end
      end
 
    end
  end
  // synopsys translate_on







endmodule
