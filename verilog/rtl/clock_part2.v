/*
    A simple user's project example - Part 2
     - Minutes and Seconds clock. The design drives 4 multiplexed 7-Segment display digits.
     - It uses Caravel system clock and reset and 11 I/O pads. 
     - The 11 I/O pads are divided between 4 digit enables and 7 segment drivers.
     - The WB bus is used to set the ALARM and to adjust the time
     - The clock interrupts the management SoC when the time matches the set alarm
    
    RTL Parameters:
     - Common Anode (CC=0) or Common Cathode (CC=1) multiplexed display
     - Different clock frequencies (FREQ in Hertz)
     - Different scans by sec (SCAN_PER_SEC)

*/
`timescale          1ns/1ns
`default_nettype    none

`define     WB_REG(name, init_value)    always @(posedge clk_i or posedge rst_i) if(rst_i) name <= init_value; else if(wb_we & (adr_i[15:0]==``name``_ADDR)) name <= dat_i;

module Clock_part2 #(parameter  CC = 1,
                                FREQ = 2_000,
                                SCAN_PER_SEC = 25,
                                WB_ADDR_WIDTH = 4
                                ) 
(
    // Clock and Reset
    input   wire                        clk,
    input   wire                        rst,
    // I/O pads interface
    output  wire [7:0]                  seven_seg,
    output  wire [3:0]                  digit_en,
    // Wishbone Bus Interface
    input   wire [WB_ADDR_WIDTH-1:0]    wb_adr_i,
    input   wire [31:0]                 wb_dat_i,
    output  wire [31:0]                 wb_dat_o,
    input   wire [3:0]                  wb_sel_i,
    input   wire                        wb_cyc_i,
    input   wire                        wb_stb_i,
    output  reg                         wb_ack_o,
    input   wire                        wb_we_i,
    // IRQ
    output  reg                         irq
);
    localparam DIG_DURATION = (FREQ)/(4 * SCAN_PER_SEC);
    localparam [WB_ADDR_WIDTH-1:0] ALARM_REG_OFF    = 'h0;
    localparam [WB_ADDR_WIDTH-1:0] TIME_REG_OFF     = 'h4;
    localparam [WB_ADDR_WIDTH-1:0] IRQCLR_REG_OFF   = 'h8;
    
    // WB Control Signals
    wire        wb_valid            =   wb_cyc_i & wb_stb_i;
    wire        wb_we               =   wb_we_i & wb_valid;
    wire        wb_re               =   ~wb_we_i & wb_valid;
    wire[3:0]   wb_byte_sel         =   wb_sel_i & {4{wb_we}};
    wire        wb_time_reg_sel     =   (wb_adr_i == TIME_REG_OFF);  
    wire        wb_alarm_reg_sel    =   (wb_adr_i == ALARM_REG_OFF);  
    wire        wb_irqclr_reg_sel   =   (wb_adr_i == IRQCLR_REG_OFF);  
     

    always @ (posedge clk or posedge rst)
        if(rst)
            wb_ack_o <= 1'b0;
        else 
            if(wb_valid & ~wb_ack_o)
                wb_ack_o <= 1'b1;
            else
                wb_ack_o <= 1'b0;

    // The Alaram Register
    reg [15:0] alarm_reg;
    always @(posedge clk or posedge rst) 
        if(rst) 
            alarm_reg <= 16'h0; 
        else if(wb_we & (wb_alarm_reg_sel)) 
            alarm_reg <= wb_dat_i[15:0];

    // The Time Register
    wire [15:0] time_reg = {min_tens, min_ones, sec_tens, sec_ones};

    // The IRQ
    always @(posedge clk)
        if(rst) irq <= 0;
        else if(wb_irqclr_reg_sel & wb_we)
            irq <= 0;
        else if((alarm_reg != 16'h0) && (alarm_reg == time_reg))
            irq <= 1;
    
    // WB Registers Read
    assign  wb_dat_o =  (wb_alarm_reg_sel)  ? {16'h0, alarm_reg}:
                        (wb_time_reg_sel)   ? {16'h0, time_reg} :
                        32'h0BADBAD0;

    // the counter
    reg [3:0]   sec_ones, sec_tens;
    reg [3:0]   min_ones, min_tens;
    wire        nine_sec        = (sec_ones == 4'd9);
    wire        fifty_nine_sec  = (sec_tens == 4'd5) & nine_sec;
    wire        nine_min        = (min_ones == 4'd9);
    wire        fifty_nine_min  = (min_tens == 4'd5) & nine_min;
    
    // Time Base Generators
    reg         sec;
    reg         scan;

    reg [31:0]  sec_div;
    reg [31:0]  scan_div;
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            sec_div <= 32'b0;
        else if(sec_div == FREQ)
            sec_div <= 32'b0;
        else
            sec_div <= sec_div + 32'b1;
    end

    always @(posedge clk or posedge rst) begin
        if(rst)
            scan_div <= 32'b0;
        else if(scan_div == DIG_DURATION)
            scan_div <= 32'b0;
        else
            scan_div <= scan_div + 32'b1;
    end

    always @(posedge clk or posedge rst) begin
        if(rst)
            sec <= 1'b0;
        else if(sec_div == FREQ)
            sec <= 1'b1;
        else 
            sec <= 1'b0;
    end

    always @(posedge clk or posedge rst) begin
        if(rst)
            scan <= 1'b0;
        else if(scan_div == DIG_DURATION)
            scan <= 1'b1;
        else 
            scan <= 1'b0;
    end


    // Seconds Counters
    always @(posedge clk or posedge rst)
        if(rst) 
            sec_ones <=  4'b0;
        else if(wb_time_reg_sel & wb_we)
            sec_ones <= wb_dat_i[3:0];
        else if(sec) begin
            if(!nine_sec) 
                sec_ones <= sec_ones + 4'd1;
            else 
                sec_ones <= 0;
        end

    always @(posedge clk or posedge rst)
        if(rst) 
            sec_tens <=  4'b0;
        else if(wb_time_reg_sel & wb_we)
            sec_tens <= wb_dat_i[7:4];
        else if(sec) begin 
            if(fifty_nine_sec) 
                sec_tens <= 0;
            else if(nine_sec) 
                sec_tens <= sec_tens + 4'd1;
        end

    // Minutes Counters
    always @(posedge clk or posedge rst)
        if(rst) 
            min_ones <=  4'b0;
        else if(wb_time_reg_sel & wb_we)
            min_ones <= wb_dat_i[11:8];
        else if(fifty_nine_sec & sec) begin
            if(!nine_min)
                min_ones <= min_ones + 4'd1;
            else
                min_ones <= 0;
        end

    always @(posedge clk or posedge rst)
        if(rst) 
            min_tens <=  4'b0;
        else if(wb_time_reg_sel & wb_we)
            min_tens <= wb_dat_i[15:12];
        else if(fifty_nine_sec & sec) begin
            if(fifty_nine_min) 
                min_tens <= 0;
            else if(nine_min) 
                min_tens <= min_tens + 4'd1;
        end
    
    
        // Display TDM
        reg [1:0] dig_cnt;
        always @(posedge clk or posedge rst) begin
            if(rst)
                dig_cnt <= 2'b0;
            else
                if(scan) dig_cnt <= dig_cnt + 1'b1;
        end

        wire [3:0]  bcd_mux =   (dig_cnt == 2'b00) ? sec_ones :
                                (dig_cnt == 2'b01) ? sec_tens :
                                (dig_cnt == 2'b10) ? min_ones : min_tens;

        // BCD to 7SEG Decoder
        reg [7:0]   ca_7seg;
        wire[7:0]   cc_7seg = ~ ca_7seg;
        always @* begin
            ca_7seg = 7'b0000000;
            case(bcd_mux)
                4'd0 : ca_7seg = 7'b0000001;
                4'd1 : ca_7seg = 7'b1001111;
                4'd2 : ca_7seg = 7'b0010010;
                4'd3 : ca_7seg = 7'b0000110;
                4'd4 : ca_7seg = 7'b1001100;
                4'd5 : ca_7seg = 7'b0100100;
                4'd6 : ca_7seg = 7'b0100000;
                4'd7 : ca_7seg = 7'b0001111;
                4'd8 : ca_7seg = 7'b0000000;
                4'd9 : ca_7seg = 7'b0000100;
            endcase
        end

        generate
            if(CC==0) begin
                assign seven_seg    =   ca_7seg;
                assign digit_en     =   (4'b1 << dig_cnt);
            end else begin
                assign seven_seg    =   cc_7seg;
                assign digit_en     =   ~(4'b1 << dig_cnt);
            end
        endgenerate

endmodule