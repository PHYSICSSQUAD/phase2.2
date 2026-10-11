package instruction_coverage_pkg;

  // ------------------------------------------------------------
  // Sampled instruction and decoded information
  // ------------------------------------------------------------

  logic [31:0]  instr_sample;
  instr_e       op_sample;
  instr_group_e group_sample;

  logic signed [31:0] imm_sample;
  logic [4:0] shamt_sample;

  bit rd_used;
  bit rs1_used;
  bit rs2_used;
  bit imm_used;
  bit shamt_used;


  // ============================================================
  // FUNCTIONAL COVERAGE
  // ============================================================

  covergroup instr_cg;

    option.per_instance = 1;

    // ----------------------------------------------------------
    // 1. Individual instruction coverage
    // ----------------------------------------------------------

    cp_instruction : coverpoint op_sample {
      bins illegal = {ILLEGAL};
      bins implemented_instr[] = {[LUI:REMU]};
    }


    // ----------------------------------------------------------
    // 2. Instruction group coverage
    // Uses instr_group_e and classify_group() from shared_pkg.
    // ----------------------------------------------------------

    cp_group : coverpoint group_sample
      iff (op_sample != ILLEGAL) {
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


    // ----------------------------------------------------------
    // 3. Instruction format coverage
    // Uses the instruction definitions already in instr_e.
    // ----------------------------------------------------------

    cp_format : coverpoint op_sample {

      bins r_type = {
        ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
        MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
      };

      bins i_type = {
        JALR, LB, LH, LW, LBU, LHU,
        ADDI, SLTI, SLTIU, XORI, ORI, ANDI,
        SLLI, SRLI, SRAI
      };

      bins s_type = {SB, SH, SW};

      bins b_type = {
        BEQ, BNE, BLT, BGE, BLTU, BGEU
      };

      bins u_type = {LUI, AUIPC};

      bins j_type = {JAL};

      bins illegal = {ILLEGAL};
    }


    // ----------------------------------------------------------
    // 4. Raw opcode coverage
    // ----------------------------------------------------------

    cp_opcode : coverpoint instr_sample[6:0] {

      bins load     = {7'b0000011};
      bins misc_mem = {7'b0001111};
      bins op_imm   = {7'b0010011};
      bins auipc    = {7'b0010111};
      bins store    = {7'b0100011};
      bins op       = {7'b0110011};
      bins lui      = {7'b0110111};
      bins branch   = {7'b1100011};
      bins jalr     = {7'b1100111};
      bins jal      = {7'b1101111};
      bins system   = {7'b1110011};

      bins other_opcode = default;
    }


    // ----------------------------------------------------------
    // 5. LOAD operations
    // ----------------------------------------------------------

    cp_load_funct3 : coverpoint instr_sample[14:12]
      iff (instr_sample[6:0] == 7'b0000011) {

      bins lb  = {3'b000};
      bins lh  = {3'b001};
      bins lw  = {3'b010};
      bins lbu = {3'b100};
      bins lhu = {3'b101};

      bins reserved = {3'b011, 3'b110, 3'b111};
    }


    // ----------------------------------------------------------
    // 6. STORE operations
    // ----------------------------------------------------------

    cp_store_funct3 : coverpoint instr_sample[14:12]
      iff (instr_sample[6:0] == 7'b0100011) {

      bins sb = {3'b000};
      bins sh = {3'b001};
      bins sw = {3'b010};

      bins reserved = {
        3'b011, 3'b100, 3'b101, 3'b110, 3'b111
      };
    }


    // ----------------------------------------------------------
    // 7. BRANCH operations
    // ----------------------------------------------------------

    cp_branch_funct3 : coverpoint instr_sample[14:12]
      iff (instr_sample[6:0] == 7'b1100011) {

      bins beq  = {3'b000};
      bins bne  = {3'b001};
      bins blt  = {3'b100};
      bins bge  = {3'b101};
      bins bltu = {3'b110};
      bins bgeu = {3'b111};

      bins reserved = {3'b010, 3'b011};
    }

    // Branch displacement sign in the encoded B-type immediate.
    cp_branch_imm_sign : coverpoint instr_sample[31]
      iff (instr_sample[6:0] == 7'b1100011) {

      bins nonnegative = {1'b0};
      bins negative    = {1'b1};
    }

    // Exercise each branch encoding with both displacement signs.
    x_branch_op_sign :
      cross cp_branch_funct3, cp_branch_imm_sign;


    // ----------------------------------------------------------
    // 8. OP-IMM operations
    // ----------------------------------------------------------

    cp_opimm_funct3 : coverpoint instr_sample[14:12]
      iff (instr_sample[6:0] == 7'b0010011) {

      bins addi  = {3'b000};
      bins slli  = {3'b001};
      bins slti  = {3'b010};
      bins sltiu = {3'b011};
      bins xori  = {3'b100};
      bins right_shift = {3'b101};
      bins ori   = {3'b110};
      bins andi  = {3'b111};
    }


    // ----------------------------------------------------------
    // 9. R-type and M-extension operations
    // ----------------------------------------------------------

    cp_r_funct3 : coverpoint instr_sample[14:12]
      iff (instr_sample[6:0] == 7'b0110011) {

      bins add_sub = {3'b000};
      bins sll     = {3'b001};
      bins slt     = {3'b010};
      bins sltu    = {3'b011};
      bins xor_op  = {3'b100};
      bins right_shift = {3'b101};
      bins or_op   = {3'b110};
      bins and_op  = {3'b111};
    }

    cp_r_funct7 : coverpoint instr_sample[31:25]
      iff (instr_sample[6:0] == 7'b0110011) {

      bins base      = {7'b0000000};
      bins sub_sra   = {7'b0100000};
      bins m_ext     = {7'b0000001};

      bins reserved = default;
    }


    // ----------------------------------------------------------
    // 10. Shift-immediate encoding
    // ----------------------------------------------------------

    cp_shift_imm_funct7 : coverpoint instr_sample[31:25]
      iff (
        instr_sample[6:0] == 7'b0010011 &&
        instr_sample[14:12] inside {3'b001, 3'b101}
      ) {

      bins logical_shift = {7'b0000000};
      bins arithmetic_shift = {7'b0100000};

      bins reserved = default;
    }


    // ----------------------------------------------------------
    // 11. JALR encoding
    // ----------------------------------------------------------

    cp_jalr_funct3 : coverpoint instr_sample[14:12]
      iff (instr_sample[6:0] == 7'b1100111) {

      bins legal = {3'b000};
      bins reserved = default;
    }


    // ----------------------------------------------------------
    // 12. Destination register coverage
    // Only sample instructions that use rd.
    // ----------------------------------------------------------

    cp_rd : coverpoint instr_sample[11:7]
      iff (rd_used) {

      bins x0 = {5'd0};
      bins x1 = {5'd1};
      bins x2 = {5'd2};
      bins x31 = {5'd31};

      bins other_registers[] = {[5'd3:5'd30]};
    }


    // ----------------------------------------------------------
    // 13. Source register 1 coverage
    // ----------------------------------------------------------

    cp_rs1 : coverpoint instr_sample[19:15]
      iff (rs1_used) {

      bins x0 = {5'd0};
      bins x1 = {5'd1};
      bins x2 = {5'd2};
      bins x31 = {5'd31};

      bins other_registers[] = {[5'd3:5'd30]};
    }


    // ----------------------------------------------------------
    // 14. Source register 2 coverage
    // ----------------------------------------------------------

    cp_rs2 : coverpoint instr_sample[24:20]
      iff (rs2_used) {

      bins x0 = {5'd0};
      bins x1 = {5'd1};
      bins x2 = {5'd2};
      bins x31 = {5'd31};

      bins other_registers[] = {[5'd3:5'd30]};
    }


    // ----------------------------------------------------------
    // 15. Immediate value coverage
    // imm_sample is reconstructed from the actual instruction.
    // ----------------------------------------------------------

    cp_imm_value : coverpoint imm_sample
      iff (imm_used) {

      bins zero = {32'sd0};

      bins positive_small = {
        [32'sd1:32'sd16]
      };

      bins positive_large = {
        [32'sd17:32'sd2147483647]
      };

      bins negative_small = {
        [-32'sd16:-32'sd1]
      };

      bins negative_large = {
        [32'sh80000000:-32'sd17]
      };
    }


    // ----------------------------------------------------------
    // 16. Shift-amount coverage
    // ----------------------------------------------------------

    cp_shamt : coverpoint shamt_sample
      iff (shamt_used) {

      bins zero = {5'd0};
      bins shamt_1_7 = {[5'd1:5'd7]};
      bins shamt_8_15 = {[5'd8:5'd15]};
      bins shamt_16_30 = {[5'd16:5'd30]};
      bins shamt_31 = {5'd31};
    }

  endgroup : instr_cg


  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  function new(
    string name = "instr_coverage",
    uvm_component parent = null
  );

    super.new(name, parent);
    instr_cg = new();

  endfunction : new


  // ============================================================
  // FIELD-USE HELPERS
  // These use only instr_e values from shared_pkg.
  // ============================================================

  function automatic bit has_rd(instr_e op);

    case (op)
      ILLEGAL,
      BEQ, BNE, BLT, BGE, BLTU, BGEU,
      SB, SH, SW:
        return 0;

      default:
        return 1;
    endcase

  endfunction


  function automatic bit has_rs1(instr_e op);

    case (op)
      ILLEGAL, LUI, AUIPC, JAL:
        return 0;

      default:
        return 1;
    endcase

  endfunction


  function automatic bit has_rs2(instr_e op);

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


  function automatic bit has_imm(instr_e op);

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


  function automatic bit has_shamt(instr_e op);

    case (op)
      SLLI, SRLI, SRAI:
        return 1;

      default:
        return 0;
    endcase

  endfunction


  // ============================================================
  // IMMEDIATE RECONSTRUCTION
  // Uses the existing instruction layouts in shared_pkg.
  // ============================================================

  function automatic logic signed [31:0] get_imm_value(
    input logic [31:0] inst,
    input instr_e op
  );

    case (op)

      // U-type
      LUI, AUIPC:
        return {inst[31:12], 12'b0};

      // I-type, excluding shift-immediate instructions
      LB, LH, LW, LBU, LHU,
      JALR,
      ADDI, SLTI, SLTIU, XORI, ORI, ANDI:
        return {{20{inst[31]}}, inst[31:20]};

      // S-type
      SB, SH, SW:
        return {{20{inst[31]}}, inst[31:25], inst[11:7]};

      // B-type
      BEQ, BNE, BLT, BGE, BLTU, BGEU:
        return {
          {19{inst[31]}},
          inst[31],
          inst[7],
          inst[30:25],
          inst[11:8],
          1'b0
        };

      // J-type
      JAL:
        return {
          {11{inst[31]}},
          inst[31],
          inst[19:12],
          inst[20],
          inst[30:21],
          1'b0
        };

      default:
        return 32'sd0;

    endcase

  endfunction : get_imm_value


  // ============================================================
  // MONITOR CALLBACK
  // ============================================================

  virtual function void write(instr_item t);

    if (t == null)
      `uvm_fatal(
        "INSTR_COV",
        "Received null instruction transaction"
      )

    // Assumes the transaction has a valid flag.
    // Remove this condition if the monitor already filters invalid
    // transactions and the item does not contain a valid field.
    if (!t.valid)
      return;

    // Assumes t.instr uses the instr_t union from shared_pkg.
    instr_sample = t.instr.raw;

    if ($isunknown(instr_sample)) begin
      `uvm_error(
        "INSTR_COV",
        "Instruction contains unknown bits; sample skipped"
      )
      return;
    end

    // Use the package's existing decoder and group classifier.
    op_sample    = decode_instr(instr_sample);
    group_sample = classify_group(op_sample);

    // Determine which instruction fields are meaningful.
    rd_used   = has_rd(op_sample);
    rs1_used  = has_rs1(op_sample);
    rs2_used  = has_rs2(op_sample);
    imm_used  = has_imm(op_sample);
    shamt_used = has_shamt(op_sample);

    // Reconstruct immediate values and shift amounts.
    imm_sample   = get_imm_value(instr_sample, op_sample);
    shamt_sample = instr_sample[24:20];

    // Sample the functional coverage model.
    instr_cg.sample();

  endfunction : write
	
endpackage : instruction_coverage_pkg