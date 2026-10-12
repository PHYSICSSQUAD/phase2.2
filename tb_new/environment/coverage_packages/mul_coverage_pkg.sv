// 🔥 NEW (MUL/DIV integration) - RV32M functional coverage, same style as
// 🔥 instruction_coverage_pkg / data_coverage_pkg. Sampled by coverage_collector.
// 🔥 The covergroup is excluded when MUL_NO_COVERGROUP is defined, because the
// 🔥 free Questa/ModelSim edition has no license for covergroups.
package mul_coverage_pkg;
  import shared_pkg::*;

`ifndef MUL_NO_COVERGROUP
    // 🔥 bins copied from mul_env/mul_coverage.sv
    covergroup mul_covgp with function sample(
        input instr_e      op,
        input logic [31:0] rs1_val,
        input logic [31:0] rs2_val,
        input logic [31:0] result
    );

        option.per_instance = 1;

        cp_op : coverpoint op {
            bins mul    = {MUL};
            bins mulh   = {MULH};
            bins mulhsu = {MULHSU};
            bins mulhu  = {MULHU};
            bins div    = {DIV};
            bins divu   = {DIVU};
            bins rem    = {REM};
            bins remu   = {REMU};
        }

        cp_rs1_class : coverpoint rs1_val {
            bins zero      = {32'h0000_0000};
            bins one       = {32'h0000_0001};
            bins pos_other = {[32'h0000_0002 : 32'h7FFF_FFFE]};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins neg_other = {[32'h8000_0001 : 32'hFFFF_FFFE]};
            bins minus_one = {32'hFFFF_FFFF};
        }
        cp_rs2_class : coverpoint rs2_val {
            bins zero      = {32'h0000_0000};
            bins one       = {32'h0000_0001};
            bins pos_other = {[32'h0000_0002 : 32'h7FFF_FFFE]};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins neg_other = {[32'h8000_0001 : 32'hFFFF_FFFE]};
            bins minus_one = {32'hFFFF_FFFF};
        }

        cp_rs1_sign : coverpoint rs1_val {
            bins zero      = {32'h0000_0000};
            bins msb_clear = {[32'h0000_0001 : 32'h7FFF_FFFF]};
            bins msb_set   = {[32'h8000_0000 : 32'hFFFF_FFFF]};
        }
        cp_rs2_sign : coverpoint rs2_val {
            bins zero      = {32'h0000_0000};
            bins msb_clear = {[32'h0000_0001 : 32'h7FFF_FFFF]};
            bins msb_set   = {[32'h8000_0000 : 32'hFFFF_FFFF]};
        }

        cp_rs1_extreme : coverpoint rs1_val {
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins minus_one = {32'hFFFF_FFFF};
        }
        cp_rs2_extreme : coverpoint rs2_val {
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins minus_one = {32'hFFFF_FFFF};
        }

        cp_result : coverpoint result {
            bins zero     = {32'h0000_0000};
            bins all_ones = {32'hFFFF_FFFF};
            bins other    = {[32'h0000_0001 : 32'hFFFF_FFFE]};
        }

        cx_op_sign      : cross cp_op, cp_rs1_sign, cp_rs2_sign;
        cx_op_rs1_class : cross cp_op, cp_rs1_class;
        cx_op_rs2_class : cross cp_op, cp_rs2_class;
        cx_op_extremes  : cross cp_op, cp_rs1_extreme, cp_rs2_extreme;

        cx_op_result    : cross cp_op, cp_result {
            ignore_bins mulhu_all_ones = binsof(cp_op.mulhu) && binsof(cp_result.all_ones);
        }

    endgroup : mul_covgp
`endif

endpackage : mul_coverage_pkg
