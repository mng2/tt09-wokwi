/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_wokwi_414120248222232577 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // control signals
    reg         filter_on;
    reg [6:0]   phase_incr_A;
    reg         bypass_B;
    reg         lowamp_B;
    reg [5:0]   phase_incr_B;
    always @(posedge clk) begin
        filter_on       <= ui_in[7];
        phase_incr_A    <= ui_in[6:0];
        bypass_B        <= uio_in[7];
        lowamp_B     <= uio_in[6];
        phase_incr_B    <= uio_in[5:0];
    end

    // NCO A
    reg [7:0] phase_A;
    always @(posedge clk) begin
        if (~rst_n) begin
            phase_A <= 0;
        end else begin
            phase_A <= phase_A + phase_incr_A;
        end
    end
    wire signed [7:0] sine_A;
    reg  signed [7:0] sine_Areg;
    sine_lookup inst_sine_A(
        .phase  (phase_A),
        .sample (sine_A)
    );

    // NCO B
    reg [7:0] phase_B;
    always @(posedge clk) begin
        if (~rst_n) begin
            phase_B <= 0;
        end else begin
            phase_B <= phase_B + phase_incr_B;
        end
    end
    wire signed [7:0] sine_B;
    reg  signed [7:0] sine_Breg;
    sine_lookup inst_sine_B(
        .phase  (phase_B),
        .sample (sine_B)
    );

    reg signed [15:0] product;
    reg signed [8:0] mixer_out;
    always @(posedge clk) begin
        sine_Areg <= sine_A;
        if (bypass_B) begin
            if (lowamp_B) begin
                sine_Breg <= 8'sd64;
            end else begin
                sine_Breg <= 8'sd127;
            end
        end else begin
            if (lowamp_B) begin
                sine_Breg <= sine_B >> 1;
            end else begin
                sine_Breg <= sine_B;
            end
        end
        
        product <= sine_Areg * sine_Breg;
        // output is planned to be R2R DAC
        mixer_out <= product[14:7] + 8'sd127;
    end

    // boxcar filter
    reg [7:0] boxcar_storage [1:4];
    reg [7+2:0] boxcar_filter;
    always @(posedge clk) begin
        if (~rst_n) begin
            boxcar_filter <= 0;
            for (int ii = 1; ii <= 4; ii = ii + 1)  begin
                boxcar_storage[ii] <= 0;
            end
        end else begin
            boxcar_filter <= boxcar_filter + mixer_out[7:0] - boxcar_storage[4];
            boxcar_storage[1] <= mixer_out[7:0];
            boxcar_storage[2] <= boxcar_storage[1];
            boxcar_storage[3] <= boxcar_storage[2];
            boxcar_storage[4] <= boxcar_storage[3];
        end
    end

    reg [7:0] final_out;
    always @(posedge clk) begin
        final_out <= filter_on ? boxcar_filter[7+2:2]: mixer_out[7:0];
    end

    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out = final_out;
    assign uio_out = 0;
    assign uio_oe  = 0;

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, rst_n, 1'b0};

endmodule
