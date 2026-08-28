
module PLL_TOP (
   AVDD,
   AVSS,
   DVDD,
   DVSS,
   DVDD_DRV,
   DVSS_DRV,
   EN,
   N,
   REFCLK,
   BP,
   OD,
   SELECT,
   CKOUT1,
   CKOUT2,
   CKTST
   );

   inout   AVDD;
   inout   AVSS;
   inout   DVDD;
   inout   DVSS;
   inout   DVDD_DRV;
   inout   DVSS_DRV;
   input   EN;
   input   [7:0]   N;
   input   REFCLK;
   input   BP;
   input   [1:0]   OD;
   input   SELECT;
   output  CKOUT1;
   output  CKOUT2;
   output  CKTST;

endmodule
