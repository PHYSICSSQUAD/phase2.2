package shared_pkg;

	localparam T      = 10;
	localparam no_txn = 10;

    // R-type:  funct7 | rs2 | rs1 | funct3 | rd | opcode
    typedef struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        logic [6:0] opcode;
    } r_type_t;

    // I-type:  imm[11:0] | rs1 | funct3 | rd | opcode
    typedef struct packed {
        logic [11:0] imm_11_0;
        logic [4:0]  rs1;
        logic [2:0]  funct3;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } i_type_t;

    // S-type:  imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
    typedef struct packed {
        logic [6:0] imm_11_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] imm_4_0;
        logic [6:0] opcode;
    } s_type_t;

    // B-type:  imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode
    typedef struct packed {
        logic       imm_12;
        logic [5:0] imm_10_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [3:0] imm_4_1;
        logic       imm_11;
        logic [6:0] opcode;
    } b_type_t;

    // U-type:  imm[31:12] | rd | opcode
    typedef struct packed {
        logic [19:0] imm_31_12;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } u_type_t;

    // J-type:  imm[20] | imm[10:1] | imm[11] | imm[19:12] | rd | opcode
    typedef struct packed {
        logic        imm_20;
        logic [9:0]  imm_10_1;
        logic        imm_11;
        logic [7:0]  imm_19_12;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } j_type_t;

    // Common union same 32-bit instruction
    typedef union packed {
        logic [31:0]    raw;
        r_type_t  r_type;
        i_type_t  i_type;
        s_type_t  s_type;
        b_type_t  b_type;
        u_type_t  u_type;
        j_type_t  j_type;
    } instr_t;

    // enum for targeted instructions
    typedef enum logic [5:0] {
        ILLEGAL,
        LUI, AUIPC, JAL, JALR,
        BEQ, BNE, BLT, BGE, BLTU, BGEU,
        LB, LH, LW, LBU, LHU, SB, SH, SW,
        ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI,
        ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
        MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
    } instr_e;

    // enum for instruciton groups
    typedef enum{
        ALU_R, ALU_I, SHIFT, LOAD, STORE, BRANCH, JUMP, MULDIV, UPPER
    } instr_group_e;


    //----------------------------- functions used ------------------------\\
    function bit [6:0] get_opcode(instr_e op);
        case (op)
            LUI:                                           return 7'b0110111;
            AUIPC:                                         return 7'b0010111;
            JAL:                                           return 7'b1101111;
            JALR:                                          return 7'b1100111;
            BEQ, BNE, BLT, BGE, BLTU, BGEU:                return 7'b1100011;
            LB, LH, LW, LBU, LHU:                          return 7'b0000011;
            SB, SH, SW:                                    return 7'b0100011;
            ADDI, SLTI, SLTIU, XORI, ORI, ANDI,
            SLLI, SRLI, SRAI:                              return 7'b0010011;
            default:                                       return 7'b0110011; // R-type + M
        endcase
    endfunction

    function bit [2:0] get_funct3(instr_e o);
        case (o)
            BEQ, LB, SB, ADDI, ADD, SUB, MUL, JALR:        return 3'b000;
            BNE, LH, SH, SLLI, SLL, MULH:                  return 3'b001;
            LW, SW, SLTI, SLT, MULHSU:                     return 3'b010;
            SLTIU, SLTU, MULHU:                            return 3'b011;
            BLT, LBU, XORI, XOR, DIV:                      return 3'b100;
            BGE, LHU, SRLI, SRAI, SRL, SRA, DIVU:          return 3'b101;
            BLTU, ORI, OR, REM:                            return 3'b110;
            BGEU, ANDI, AND, REMU:                         return 3'b111;
            default:                                       return 3'b000; // LUI/AUIPC/JAL (unused)
        endcase
    endfunction

    function bit [6:0] get_funct7(instr_e o);
        case (o)
            SUB, SRA, SRAI:                                 return 7'b0100000;
            MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU: return 7'b0000001;
            default:                                        return 7'b0000000;
        endcase
    endfunction

    function automatic instr_e decode_instr(input logic [31:0] instr);
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;

        opcode = instr[6:0];
        funct3 = instr[14:12];
        funct7 = instr[31:25];

        case(opcode)
            7'b0110111: return LUI;
            7'b0010111: return AUIPC;
            7'b1101111: return JAL;

            7'b1100111: return (funct3 == 3'b000) ? JALR : ILLEGAL;

            // Branch
            7'b1100011: begin
                case (funct3)
                    3'b000: return BEQ;
                    3'b001: return BNE;
                    3'b100: return BLT;
                    3'b101: return BGE;
                    3'b110: return BLTU;
                    3'b111: return BGEU;
                    default: return ILLEGAL;
                endcase
            end

            // Load
            7'b0000011: begin
                case (funct3)
                    3'b000: return LB;
                    3'b001: return LH;
                    3'b010: return LW;
                    3'b100: return LBU;
                    3'b101: return LHU;
                    default: return ILLEGAL;
                endcase
            end

            // Store
            7'b0100011: begin
                case (funct3)
                    3'b000: return SB;
                    3'b001: return SH;
                    3'b010: return SW;
                    default: return ILLEGAL;
                endcase
            end

            // OP-IMM
            7'b0010011: begin
                case (funct3)
                    3'b000: return ADDI;
                    3'b010: return SLTI;
                    3'b011: return SLTIU;
                    3'b100: return XORI;
                    3'b110: return ORI;
                    3'b111: return ANDI;
                    3'b001: return (funct7 == 7'b0000000) ? SLLI : ILLEGAL;
                    3'b101: begin
                        if      (funct7 == 7'b0000000) return SRLI;
                        else if (funct7 == 7'b0100000) return SRAI;
                        else                           return ILLEGAL;
                    end
                    default: return ILLEGAL;
                endcase
            end

            // OP (base R-type + M extension)
            7'b0110011: begin
                case (funct7)
                    7'b0000000: begin
                        case (funct3)
                            3'b000: return ADD;
                            3'b001: return SLL;
                            3'b010: return SLT;
                            3'b011: return SLTU;
                            3'b100: return XOR;
                            3'b101: return SRL;
                            3'b110: return OR;
                            3'b111: return AND;
                            default: return ILLEGAL;
                        endcase
                    end
                    7'b0100000: begin
                        case (funct3)
                            3'b000: return SUB;
                            3'b101: return SRA;
                            default: return ILLEGAL;
                        endcase
                    end
                    7'b0000001: begin
                        case (funct3)
                            3'b000: return MUL;
                            3'b001: return MULH;
                            3'b010: return MULHSU;
                            3'b011: return MULHU;
                            3'b100: return DIV;
                            3'b101: return DIVU;
                            3'b110: return REM;
                            3'b111: return REMU;
                            default: return ILLEGAL;
                        endcase
                    end
                    default: return ILLEGAL;
                endcase
            end

            default: return ILLEGAL;
        endcase
    endfunction

    // Instruction group classifier
    function automatic instr_group_e classify_group(instr_e op);
        case (op)
            ADD, SUB, SLT, SLTU, XOR, OR, AND:                  return ALU_R;
            ADDI, SLTI, SLTIU, XORI, ORI, ANDI:                 return ALU_I;
            SLLI, SRLI, SRAI, SLL, SRL, SRA:                    return SHIFT;
            LB, LH, LW, LBU, LHU:                               return LOAD;
            SB, SH, SW:                                         return STORE;
            BEQ, BNE, BLT, BGE, BLTU, BGEU:                     return BRANCH;
            JAL, JALR:                                          return JUMP;
            MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU:     return MULDIV;
            LUI, AUIPC:                                         return UPPER;
            default:                                            return ALU_R;
        endcase
    endfunction

    // apply be mask or data
    function automatic logic [31:0] apply_be_mask(logic [31:0] old_val, new_val, logic [3:0] be);
        logic [31:0] res = old_val;
        if (be[0]) res[ 7: 0] = new_val[ 7: 0];
        if (be[1]) res[15: 8] = new_val[15: 8];
        if (be[2]) res[23:16] = new_val[23:16];
        if (be[3]) res[31:24] = new_val[31:24];
        return res;
    endfunction

    // Compute Byte Enable mask based on operation and address offset
    function automatic logic [3:0] get_byte_enable(instr_e op, logic [1:0] offset);
        case (op)
            LB, LBU, SB: return (4'b0001 << offset);
            LH, LHU, SH: return (4'b0011 << offset);
            LW, SW:      return  4'b1111;
            default:     return  4'b0000;
        endcase
    endfunction

endpackage : shared_pkg
