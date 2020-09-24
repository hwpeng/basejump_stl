/**
 *    bsg_mesh_router_decoder_dor.v
 *
 *    Dimension ordered routing decoder
 *    
 *    depopulated ruche router.
 */

module bsg_mesh_router_decoder_dor
  import bsg_noc_pkg::*;
  import bsg_mesh_router_pkg::*;
  #(parameter x_cord_width_p = -1
    , parameter y_cord_width_p = -1
    , parameter dims_p = 2
    , parameter dirs_lp = (2*dims_p)+1
    , parameter ruche_factor_X_p=0
    , parameter ruche_factor_Y_p=0
    // broadcast_1d_p = 0: nomral
    // broadcast_1d_p = 1: broadcast to all nodes at X or Y, 
    //                     dirs become source node coords
    , parameter broadcast_1d_p=0
    // XY_order_p = 1 :  X then Y
    // XY_order_p = 0 :  Y then X
    , parameter XY_order_p = 1
    , parameter from_p = {dirs_lp{1'b0}}  // one-hot, indicates which direction is the input coming from.

    , parameter debug_p = 0
  )
  (
    input clk_i         // debug only
    , input reset_i     // debug only

    , input v_i

    , input [x_cord_width_p-1:0] x_dirs_i
    , input [y_cord_width_p-1:0] y_dirs_i
      
    , input broadcast_dirs_i

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i

    , output [dirs_lp-1:0] req_o
  );


  // check parameters

  // synopsys translate_off
  initial begin
    if (ruche_factor_X_p > 0) begin
      assert(dims_p > 2) else $fatal("ruche in X direction requires dims_p greater than 2.");
    end
    
    if (ruche_factor_Y_p > 0) begin
      assert(dims_p > 3) else $fatal("ruche in Y direction requires dims_p greater than 3.");
    end

    assert($countones(from_p) == 1) else $fatal("Must define from_p as one-hot value.");
  end
  // synopsys translate_on




  // compare coordinates
  wire x_eq = (x_dirs_i == my_x_i);
  wire y_eq = (y_dirs_i == my_y_i);
  wire x_gt = x_dirs_i > my_x_i;
  wire y_gt = y_dirs_i > my_y_i;
  wire x_lt = ~x_gt & ~x_eq;
  wire y_lt = ~y_gt & ~y_eq;

  // valid signal
  logic [dirs_lp-1:0] req;
  assign req_o = {dirs_lp{v_i}} & req;


  // P-port
  assign req[P] = (broadcast_1d_p == 0)? x_eq & y_eq
                                       : 1'b1;


  if (ruche_factor_X_p > 0) begin

    if (XY_order_p) begin
      // make sure there is no under/overflow.
      wire [x_cord_width_p:0] re_cord = (x_cord_width_p+1)'(my_x_i + ruche_factor_X_p);
      wire send_rw = (my_x_i > ruche_factor_X_p) & (x_dirs_i < (my_x_i - ruche_factor_X_p));
      wire send_re = ~re_cord[x_cord_width_p] & (x_dirs_i > re_cord[0+:x_cord_width_p]);

      assign req[W]  = x_lt & ~send_rw;
      assign req[RW] = send_rw;
      assign req[E]  = x_gt & ~send_re;
      assign req[RE] = send_re;
    end
    else begin
      if (from_p[S] | from_p[N] | from_p[P]) begin
        assign req[W]  = y_eq & x_lt;
        assign req[RW] = 1'b0;
        assign req[E]  = y_eq & x_gt;
        assign req[RE] = 1'b0;
      end
      else if(from_p[W]) begin
        wire [x_cord_width_p-1:0] dx = (x_dirs_i - my_x_i) % ruche_factor_X_p;
        assign req[RE] = y_eq & x_gt & (dx == 'd0);
        assign req[E]  = y_eq & x_gt & (dx != 'd0);
        assign req[RW] = 1'b0;
        assign req[W]  = 1'b0;
      end
      else if (from_p[E]) begin
        wire [x_cord_width_p-1:0] dx = (my_x_i - x_dirs_i) % ruche_factor_X_p;
        assign req[RE] = 1'b0;
        assign req[E]  = 1'b0;
        assign req[RW] = y_eq & x_lt & (dx == 'd0);
        assign req[W]  = y_eq & x_lt & (dx != 'd0);
      end
      else if (from_p[RW]) begin
        assign req[RE] = y_eq & x_gt;
        assign req[E]  = 1'b0;
        assign req[RW] = 1'b0;
        assign req[W]  = 1'b0;
      end
      else if (from_p[RE]) begin
        assign req[RE] = 1'b0;
        assign req[E]  = 1'b0;
        assign req[RW] = y_eq & x_lt;
        assign req[W]  = 1'b0;
      end
    end

  end
  else if (broadcast_1d_p == 0) begin
    if (XY_order_p) begin
      assign req[W] = x_lt;
      assign req[E] = x_gt;
    end
    else begin
      assign req[W] = y_eq & x_lt;
      assign req[E] = y_eq & x_gt;
    end
  end
  else begin
      assign req[W] = ~broadcast_dirs_i & (~x_lt);
      assign req[E] = ~broadcast_dirs_i & (~x_gt);
  end


  
  if (ruche_factor_Y_p > 0) begin
    if (XY_order_p) begin
      // make sure there is no under/overflow.
      wire [y_cord_width_p:0] rs_cord = (y_cord_width_p+1)' (my_y_i + ruche_factor_Y_p);
      wire send_rn = (my_y_i > ruche_factor_Y_p) & (y_dirs_i < (my_y_i - ruche_factor_Y_p));
      wire send_rs = ~rs_cord[y_cord_width_p] & (y_dirs_i > rs_cord[0+:y_cord_width_p]);

      assign req[N]  = x_eq & y_lt & ~send_rn;
      assign req[RN] = x_eq & send_rn;
      assign req[S]  = x_eq & y_gt & ~send_rs;
      assign req[RS] = x_eq & send_rs;
    end
    else begin
      if (from_p[E] | from_p[W] | from_p[P]) begin
        assign req[N]  = y_lt;
        assign req[RN] = 1'b0;
        assign req[S]  = y_gt;
        assign req[RS] = 1'b0;
      end
      else if (from_p[N]) begin
        wire [y_cord_width_p-1:0] dy = (y_dirs_i - my_y_i) % ruche_factor_Y_p;
        assign req[RS] = y_gt & (dy == 'd0);
        assign req[S]  = y_gt & (dy != 'd0);
        assign req[RN] = 1'b0;
        assign req[N]  = 1'b0;
      end
      else if (from_p[S]) begin
        wire [x_cord_width_p-1:0] dy = (my_y_i - y_dirs_i) % ruche_factor_Y_p;
        assign req[RS] = 1'b0;
        assign req[S]  = 1'b0;
        assign req[RN] = y_lt & (dy == 'd0);
        assign req[N]  = y_lt & (dy != 'd0);
      end
      else if (from_p[RN]) begin
        assign req[RS] = y_gt;
        assign req[S]  = 1'b0;
        assign req[RN] = 1'b0;
        assign req[N]  = 1'b0;
      end
      else if (from_p[RS]) begin
        assign req[RS] = 1'b0;
        assign req[S]  = 1'b0;
        assign req[RN] = y_lt;
        assign req[N]  = 1'b0;
      end
    end

  end
  else if (broadcast_1d_p == 0) begin
    if (XY_order_p) begin
      assign req[N] = x_eq & y_lt;
      assign req[S] = x_eq & y_gt;
    end
    else begin
      assign req[N] = y_lt;
      assign req[S] = y_gt;
    end
  end
  else begin
      assign req[N] = broadcast_dirs_i & (~y_lt);
      assign req[S] = broadcast_dirs_i & (~y_gt);
  end


  // synopsys translate_off
  if (debug_p) begin
    always_ff @ (negedge clk_i) begin
      if (~reset_i) begin
        if (broadcast_1d_p == 0)
            assert($countones(req_o) < 2)
              else $fatal("multiple req_o detected. i=%d, %b", req_o);
      end
    end
  end
  else begin
    wire unused0 = clk_i;
    wire unused1 = reset_i;
  end
  // synopsys translate_on




endmodule

