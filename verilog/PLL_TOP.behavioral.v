`timescale 1ns/1ps

module PLL_TOP (
    input           EN,
    input           BP,
    input   [7:0]   N,
    input           SELECT,
    input   [1:0]   OD,
    input           REFCLK,
    
    inout           AVDD,
    inout           AVSS,
    inout           DVDD,
    inout           DVSS,
    inout           DVDD_DRV,
    inout           DVSS_DRV,
    
    output reg      CKOUT1 = 0,
    output reg      CKOUT2 = 0,
    output reg      CKTST = 0
);

real refclk_freq_mhz = 0;
real vco_freq_mhz = 0;
real ckout_freq_mhz = 0;
real cktst_freq_mhz = 0;
real output_divider = 1;

reg power_ok = 0;
reg config_printed = 0;
reg prev_en = 0;

wire avdd_signal;
wire avss_signal;
wire dvdd_signal;
wire dvss_signal;
wire dvdd_drv_signal;
wire dvss_drv_signal;

assign avdd_signal = AVDD;
assign avss_signal = AVSS;
assign dvdd_signal = DVDD;
assign dvss_signal = DVSS;
assign dvdd_drv_signal = DVDD_DRV;
assign dvss_drv_signal = DVSS_DRV;

always @* begin
    if (avdd_signal === 1'b1 && avss_signal === 1'b0 && 
        dvdd_signal === 1'b1 && dvss_signal === 1'b0 &&
        dvdd_drv_signal === 1'b1 && dvss_drv_signal === 1'b0) begin
        power_ok = 1;
    end else begin
        power_ok = 0;
    end
end

task automatic measure_refclk_freq;
    realtime t1, t2;
    begin
        @(posedge REFCLK);
        t1 = $realtime;
        @(posedge REFCLK);
        t2 = $realtime;
        refclk_freq_mhz = 1000.0 / (t2 - t1);
        
        if (refclk_freq_mhz < 5.0 || refclk_freq_mhz > 40.0) begin
            $display("[WARNING] REFCLK %.3f MHz out of 5-40MHz range", refclk_freq_mhz);
        end
    end
endtask

always @(posedge EN) begin
    if (EN && power_ok && !prev_en) begin
        prev_en = 1;
        
        measure_refclk_freq;
        
        if (N <= 8'h10) begin
            $display("[WARNING] N=%d should be >16", N);
        end
        
        vco_freq_mhz = refclk_freq_mhz * N * (SELECT ? 2.0 : 1.0);
        
        if (vco_freq_mhz < 500.0 || vco_freq_mhz > 1200.0) begin
            $display("[WARNING] VCO %.3f MHz out of 500-1200MHz range", vco_freq_mhz);
        end
        
        case (OD)
            2'b00: output_divider = 1.0;
            2'b01: output_divider = 2.0;
            2'b10: output_divider = 4.0;
            2'b11: output_divider = 8.0;
        endcase
        
        cktst_freq_mhz = vco_freq_mhz / 64.0;
        
        if (BP) begin
            ckout_freq_mhz = refclk_freq_mhz;
        end else begin
            ckout_freq_mhz = vco_freq_mhz / output_divider;
        end
        
        if (!config_printed) begin
            if (BP) begin
                $display("[INFO] PLL Configured: Bypass Mode");
                $display("       CKOUT1=CKOUT2=REFCLK=%.3fMHz", refclk_freq_mhz);
                $display("       VCO=%.3fMHz, CKTST=%.3fMHz", vco_freq_mhz, cktst_freq_mhz);
            end else begin
                $display("[INFO] PLL Configured: PLL Mode");
                $display("       REFCLK=%.3fMHz, N=%d, SELECT=%d", refclk_freq_mhz, N, SELECT);
                $display("       VCO=%.3fMHz, OD=%b, CKOUT1=CKOUT2=%.3fMHz", vco_freq_mhz, OD, ckout_freq_mhz);
                $display("       CKTST=%.3fMHz", cktst_freq_mhz);
            end
            config_printed = 1;
        end
    end
end

always @(negedge EN) begin
    prev_en = 0;
    config_printed = 0;
    refclk_freq_mhz = 0;
    ckout_freq_mhz = 0;
    cktst_freq_mhz = 0;
    vco_freq_mhz = 0;
end

always begin
    if (!EN || !power_ok) begin
        CKOUT1 = 0;
        CKOUT2 = 0;
        wait(EN && power_ok && prev_en);
    end
    
    if (BP) begin
        while (EN && power_ok && BP) begin
            @(posedge REFCLK);
            CKOUT1 = 1;
            CKOUT2 = 1;
            #(500.0 / refclk_freq_mhz);
            CKOUT1 = 0;
            CKOUT2 = 0;
            #(500.0 / refclk_freq_mhz);
        end
    end 
    else begin
        while (EN && power_ok && !BP && ckout_freq_mhz > 0) begin
            CKOUT1 = 0;
            CKOUT2 = 0;
            #(500.0 / ckout_freq_mhz);
            CKOUT1 = 1;
            CKOUT2 = 1;
            #(500.0 / ckout_freq_mhz);
        end
        CKOUT1 = 0;
        CKOUT2 = 0;
        wait(EN && power_ok && !BP && ckout_freq_mhz > 0);
    end
end

always begin
    if (!EN || !power_ok) begin
        CKTST = 0;
        wait(EN && power_ok && prev_en);
    end
    
    while (EN && power_ok && cktst_freq_mhz > 0) begin
        CKTST = 0;
        #(500.0 / cktst_freq_mhz);
        CKTST = 1;
        #(500.0 / cktst_freq_mhz);
    end
    CKTST = 0;
    wait(EN && power_ok && cktst_freq_mhz > 0);
end

initial begin
    CKOUT1 = 0;
    CKOUT2 = 0;
    CKTST = 0;
    config_printed = 0;
    prev_en = 0;
    $display("[INFO] PLL_TOP Behavioral Model Initialized");
end

endmodule
