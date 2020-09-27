/**
 *      bsg_mesh_router_pkg.v
 *
 */



package bsg_mesh_router_pkg;


  
  //  ruche directions
  typedef enum logic [3:0] {
    RW = 4'd5
    ,RE = 4'd6
    ,RN = 4'd7
    ,RS = 4'd8
  } ruche_dirs_e;



  //                        //
  //    routing matrices    //
  //                        //


  // vanilla 2D mesh
 

 
  // dims_p = 2
  // XY_order_p = 1
  localparam bit [4:0][4:0] StrictXY = {
    //  SNEWP (input)
     5'b01111  // S
    ,5'b10111  // N
    ,5'b00011  // E
    ,5'b00101  // W
    ,5'b11111  // P (output)
  };

  // dims_p = 2
  // XY_order_p = 0
  localparam bit [4:0][4:0] StrictYX = {
    //  SNEWP (input)
     5'b01001  // S
    ,5'b10001  // N
    ,5'b11011  // E
    ,5'b11101  // W
    ,5'b11111  // P (output)
  };




  // Half Ruche (ruche network in X-direction)
  // depopulated router
  // YX retraces XY.


  // dims_p = 3
  // XY_order_p = 1
  localparam bit [6:0][6:0] HalfRucheX_StrictXY = {
    //  RE,RW,SNEWP (input)
     7'b0100001  // RE
    ,7'b1000001  // RW
    ,7'b0001111  // S
    ,7'b0010111  // N
    ,7'b0100011  // E
    ,7'b1000101  // W
    ,7'b0011111  // P (output)
   };


  // dims_p = 3
  // XY_order_p = 0
  localparam bit [6:0][6:0] HalfRucheX_StrictYX = {
    //  RE,RW,SNEWP (input)
     7'b0100010  // RE
    ,7'b1000100  // RW
    ,7'b0001001  // S
    ,7'b0010001  // N
    ,7'b0011011  // E
    ,7'b0011101  // W
    ,7'b1111111  // P (output)
  };


  // broadcast_1d_p = 1
  // dims_p = 2
  localparam bit [4:0][4:0] Broadcast_1D = {
    //  SNEWP (input)
     5'b01001  // S
    ,5'b10001  // N
    ,5'b00011  // E
    ,5'b00101  // W
    ,5'b11111  // P (output)
  };

endpackage