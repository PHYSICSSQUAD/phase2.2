package instruction_coverage_pkg;
  import shared_pkg::*;

  // ============================================================
  // Instruction coverage
  // ============================================================
  covergroup instruction_covgp with function sample(
    input logic [31:0]       instr,
    input instr_e            op,
    input instr_group_e      group_op,
    input logic signed [31:0] imm,
    input logic [4:0]        shamt,
    input bit                rd_used,
    input bit                rs1_used,
    input bit                rs2_used,
    input bit                imm_used,
    input bit                shamt_used
  );

    option.per_instance = 1;

    cp_instruction : coverpoint op {
      illegal_bins decoded_illegal = {ILLEGAL};
      bins implemented_instruction[] = {[LUI:REMU]};
    }

    cp_group : coverpoint group_op iff (op != ILLEGAL) {
      bins alu_r  = {ALU_R};
      bins alu_i  = {ALU_I};
      bins shift  = {SHIFT};
      bins load   = {LOAD};
      bins store  = {STORE};
      bins branch = {BRANCH};
      bins jump   = {JUMP};
      bins muldiv = {MULDIV};
      bins upper  = {UPPER};
    }

    cp_format : coverpoint op {
      bins r_type[] = {
        ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
        MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
      };
      bins i_type[] = {
        JALR, LB, LH, LW, LBU, LHU,
        ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
      };
      bins s_type[] = {SB, SH, SW};
      bins b_type[] = {BEQ, BNE, BLT, BGE, BLTU, BGEU};
      bins u_type[] = {LUI, AUIPC};
      bins j_type   = {JAL};
      illegal_bins illegal = {ILLEGAL};
    }

    cp_opcode : coverpoint instr[6:0] {
      bins lui       = {get_opcode(LUI)};
      bins auipc     = {get_opcode(AUIPC)};
      bins jal       = {get_opcode(JAL)};
      bins jalr      = {get_opcode(JALR)};
      bins branch    = {get_opcode(BEQ)};
      bins load      = {get_opcode(LB)};
      bins store     = {get_opcode(SB)};
      bins op_imm    = {get_opcode(ADDI)};
      bins op_r_m    = {get_opcode(ADD)};
      bins other_opcode = default;
    }

    cp_load_funct3 : coverpoint instr[14:12]
      iff (instr[6:0] == get_opcode(LB)) {
      bins lb  = {get_funct3(LB)};
      bins lh  = {get_funct3(LH)};
      bins lw  = {get_funct3(LW)};
      bins lbu = {get_funct3(LBU)};
      bins lhu = {get_funct3(LHU)};
      bins reserved = default;
    }

    cp_store_funct3 : coverpoint instr[14:12]
      iff (instr[6:0] == get_opcode(SB)) {
      bins sb = {get_funct3(SB)};
      bins sh = {get_funct3(SH)};
      bins sw = {get_funct3(SW)};
      bins reserved = default;
    }

    cp_branch_op : coverpoint op iff (group_op == BRANCH) {
      bins beq  = {BEQ};
      bins bne  = {BNE};
      bins blt  = {BLT};
      bins bge  = {BGE};
      bins bltu = {BLTU};
      bins bgeu = {BGEU};
    }

    cp_branch_imm_sign : coverpoint (imm < 0)
      iff (group_op == BRANCH) {
      bins nonnegative = {0};
      bins negative    = {1};
    }

    x_branch_op_sign : cross cp_branch_op, cp_branch_imm_sign;

    cp_opimm_funct3 : coverpoint instr[14:12]
      iff (instr[6:0] == get_opcode(ADDI)) {
      bins addi  = {get_funct3(ADDI)};
      bins slli  = {get_funct3(SLLI)};
      bins slti  = {get_funct3(SLTI)};
      bins sltiu = {get_funct3(SLTIU)};
      bins xori  = {get_funct3(XORI)};
      bins ori   = {get_funct3(ORI)};
      bins andi  = {get_funct3(ANDI)};
      bins right_shift = {get_funct3(SRLI)};
    }

    cp_r_funct3 : coverpoint instr[14:12]
      iff (instr[6:0] == get_opcode(ADD)) {
      bins add_sub = {get_funct3(ADD)};
      bins sll     = {get_funct3(SLL)};
      bins slt     = {get_funct3(SLT)};
      bins sltu    = {get_funct3(SLTU)};
      bins xor_op  = {get_funct3(XOR)};
      bins right_shift = {get_funct3(SRL)};
      bins or_op   = {get_funct3(OR)};
      bins and_op  = {get_funct3(AND)};
    }

    cp_r_funct7 : coverpoint instr[31:25]
      iff (instr[6:0] == get_opcode(ADD)) {
      bins base_ops = {get_funct7(ADD)};
      bins sub_sra  = {get_funct7(SUB)};
      bins m_ext    = {get_funct7(MUL)};
      bins reserved = default;
    }

    cp_shift_imm_funct7 : coverpoint instr[31:25]
      iff ((instr[6:0] == get_opcode(SLLI)) &&
           (instr[14:12] inside {
             get_funct3(SLLI), get_funct3(SRLI), get_funct3(SRAI)
           })) {
      bins logical_shift    = {get_funct7(SLLI)};
      bins arithmetic_shift = {get_funct7(SRAI)};
      bins reserved         = default;
    }

    cp_jalr_funct3 : coverpoint instr[14:12]
      iff (instr[6:0] == get_opcode(JALR)) {
      bins legal    = {get_funct3(JALR)};
      bins reserved = default;
    }

    cp_rd : coverpoint instr[11:7] iff (rd_used) {
      bins x0 = {0};
      bins x1 = {1};
      bins x2 = {2};
      bins x31 = {31};
      bins other_registers[] = {[3:30]};
    }

    cp_rs1 : coverpoint instr[19:15] iff (rs1_used) {
      bins x0 = {0};
      bins x1 = {1};
      bins x2 = {2};
      bins x31 = {31};
      bins other_registers[] = {[3:30]};
    }

    cp_rs2 : coverpoint instr[24:20] iff (rs2_used) {
      bins x0  = {0};
      bins x1  = {1};
      bins x2  = {2};
      bins x31 = {31};
      bins other_registers[] = {[3:30]};
    }

    cp_imm_value : coverpoint imm iff (imm_used) {
      bins zero           = {0};
      bins positive_small = {[1:16]};
      bins negative_small = {[-16:-1]};
    }

    cp_shamt : coverpoint shamt iff (shamt_used) {
      bins zero       = {0};
      bins shamt_1_7  = {[1:7]};
      bins shamt_8_15 = {[8:15]};
      bins shamt_16_30 = {[16:30]};
      bins shamt_31   = {31};
    }

  endgroup : instruction_covgp


  // ============================================================
  // helper functions
  // ============================================================
  function automatic bit has_rd(input instr_e op);
    case (op)
      ILLEGAL,
      BEQ, BNE, BLT, BGE, BLTU, BGEU,
      SB, SH, SW: return 0;
      default:   return 1;
    endcase
  endfunction

  function automatic bit has_rs1(input instr_e op);
    case (op)
      ILLEGAL, LUI, AUIPC, JAL: return 0;
      default:                  return 1;
    endcase
  endfunction

  function automatic bit has_rs2(input instr_e op);
    case (op)
      BEQ, BNE, BLT, BGE, BLTU, BGEU,
      SB, SH, SW,
      ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
      MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU:
        return 1;
      default:
        return 0;
    endcase
  endfunction

  function automatic bit has_imm(input instr_e op);
    case (op)
      LUI, AUIPC, JAL, JALR,
      BEQ, BNE, BLT, BGE, BLTU, BGEU,
      LB, LH, LW, LBU, LHU,
      SB, SH, SW,
      ADDI, SLTI, SLTIU, XORI, ORI, ANDI:
        return 1;
      default:
        return 0;
    endcase
  endfunction

  function automatic bit has_shamt(input instr_e op);
    case (op)
      SLLI, SRLI, SRAI: return 1;
      default:          return 0;
    endcase
  endfunction

  function automatic logic signed [31:0] get_imm_value(
    input logic [31:0] inst,
    input instr_e op
  );
    case (op)
      LUI, AUIPC:
        return $signed({inst[31:12], 12'd0});

      LB, LH, LW, LBU, LHU,
      JALR,
      ADDI, SLTI, SLTIU, XORI, ORI, ANDI:
        return $signed({{20{inst[31]}}, inst[31:20]});

      SB, SH, SW:
        return $signed({{20{inst[31]}}, inst[31:25], inst[11:7]});

      BEQ, BNE, BLT, BGE, BLTU, BGEU:
        return $signed({{19{inst[31]}}, inst[31], inst[7],
                        inst[30:25], inst[11:8], 1'd0});

      JAL:
        return $signed({{11{inst[31]}}, inst[31], inst[19:12],
                        inst[20], inst[30:21], 1'd0});

      default:
        return 32'sd0;
    endcase
  endfunction

endpackage : instruction_coverage_pkg
