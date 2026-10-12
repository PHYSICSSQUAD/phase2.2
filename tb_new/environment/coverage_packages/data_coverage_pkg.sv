package data_coverage_pkg;
  import shared_pkg::*;

    // ============================================================
    // LSU data coverage
    // ============================================================
    covergroup data_covgp with function sample(
        input logic [31:0] addr,
        input logic        we,
        input logic [3:0]  be,
        input logic [31:0] wdata,
        input logic [31:0] rdata
    );

        option.per_instance = 1;

        cp_direction : coverpoint we {
            bins read  = {0};
            bins write = {1};
        }

        cp_addr_offset : coverpoint addr[1:0] {
            bins offset_0 = {2'd0};
            bins offset_1 = {2'd1};
            bins offset_2 = {2'd2};
            bins offset_3 = {2'd3};
        }

        cp_byte_enable : coverpoint be {
            bins byte_lane_0 = {get_byte_enable(LB, 2'd0)};
            bins byte_lane_1 = {get_byte_enable(LB, 2'd1)};
            bins byte_lane_2 = {get_byte_enable(LB, 2'd2)};
            bins byte_lane_3 = {get_byte_enable(LB, 2'd3)};

            bins halfword_lanes_01 = {get_byte_enable(LH, 2'd0)};
            bins halfword_lanes_12 = {get_byte_enable(LH, 2'd1)};
            bins halfword_lanes_23 = {get_byte_enable(LH, 2'd2)};

            bins full_word = {get_byte_enable(LW, 2'd0)};

            bins other_mask = default;
        }

        cp_enabled_lane_count : coverpoint $countones(be) {
            bins one_lane    = {1};
            bins two_lanes   = {2};
            bins three_lanes = {3};
            bins four_lanes  = {4};
        }

        cp_wdata_pattern : coverpoint wdata iff (we == 1) {
            bins zero             = {32'h0000_0000};
            bins all_ones         = {32'hFFFF_FFFF};
            bins lsb_only         = {32'h0000_0001};
            bins msb_only         = {32'h8000_0000};
            bins alternating_a    = {32'hAAAA_AAAA};
            bins alternating_5    = {32'h5555_5555};
            bins other_data       = default;
        }

        cp_wdata_msb : coverpoint wdata[31] iff (we == 1) {
            bins msb_zero = {0};
            bins msb_one  = {1};
        }

        cp_wdata_lsb : coverpoint wdata[0] iff (we == 1) {
            bins lsb_zero = {0};
            bins lsb_one  = {1};
        }

        cp_wdata_low_byte : coverpoint wdata[7:0] iff (we == 1) {
            bins zero        = {8'h00};
            bins low_nibble  = {8'h0F};
            bins high_nibble = {8'hF0};
            bins all_ones    = {8'hFF};
            bins other = default;
        }

        cp_rdata_pattern : coverpoint rdata iff (we == 0) {
            bins zero             = {32'h0000_0000};
            bins all_ones         = {32'hFFFF_FFFF};
            bins lsb_only         = {32'h0000_0001};
            bins msb_only         = {32'h8000_0000};
            bins alternating_a    = {32'hAAAA_AAAA};
            bins alternating_5    = {32'h5555_5555};
            bins other_data       = default;
        }

        cp_rdata_msb : coverpoint rdata[31] iff (we == 0) {
            bins msb_zero = {0};
            bins msb_one  = {1};
        }

        cp_rdata_lsb : coverpoint rdata[0] iff (we == 0) {
            bins lsb_zero = {0};
            bins lsb_one  = {1};
        }

        cp_rdata_low_byte : coverpoint rdata[7:0] iff (we == 0) {
            bins zero        = {8'h00};
            bins low_nibble  = {8'h0F};
            bins high_nibble = {8'hF0};
            bins all_ones    = {8'hFF};
            bins other       = default;
        }

        x_direction_be          : cross cp_direction,   cp_byte_enable;
        x_offset_be             : cross cp_addr_offset, cp_byte_enable;
        x_write_be_data_pattern : cross cp_byte_enable, cp_wdata_pattern iff (we == 1);
        x_read_be_data_pattern  : cross cp_byte_enable, cp_rdata_pattern iff (we == 0);

    endgroup : data_covgp

endpackage : data_coverage_pkg
