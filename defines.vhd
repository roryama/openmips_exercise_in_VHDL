LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
PACKAGE defines IS
--Global
CONSTANT RstEnable : STD_LOGIC:='1';
CONSTANT RstDisable : STD_LOGIC:='0';
CONSTANT ZeroWord : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"00000000";
CONSTANT WriteEnable : STD_LOGIC:='1';
CONSTANT WriteDisable : STD_LOGIC:='0';
CONSTANT ReadEnable : STD_LOGIC:='1';
CONSTANT ReadDisable : STD_LOGIC:='0';
CONSTANT AluOpBus :INTEGER:=8;
CONSTANT AluSelBus :INTEGER:=3;
CONSTANT InstValid : STD_LOGIC:='0';
CONSTANT InstInvalid : STD_LOGIC:='1';
CONSTANT Stop : STD_LOGIC:='1';
CONSTANT NoStop : STD_LOGIC:='0';
CONSTANT InDelaySlot : STD_LOGIC:='1';
CONSTANT NotInDelaySlot : STD_LOGIC:='0';
CONSTANT Branch : STD_LOGIC:='1';
CONSTANT NotBranch : STD_LOGIC:='0';
CONSTANT InterruptAssert : STD_LOGIC:='1';
CONSTANT InterruptNotAssert : STD_LOGIC:='0';
CONSTANT TrapAssert : STD_LOGIC:='1';
CONSTANT TrapNotAssert : STD_LOGIC:='0';
CONSTANT True_v : STD_LOGIC:='1';
CONSTANT False_v : STD_LOGIC:='0';
CONSTANT ChipEnable : STD_LOGIC:='1';
CONSTANT ChipDisable : STD_LOGIC:='0';

--Instructions
CONSTANT EXE_AND  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100100";
CONSTANT EXE_OR   : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100101";
CONSTANT EXE_XOR : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100110";
CONSTANT EXE_NOR : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100111";
CONSTANT EXE_ANDI : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001100";
CONSTANT EXE_ORI  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001101";
CONSTANT EXE_XORI : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001110";
CONSTANT EXE_LUI : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001111";

CONSTANT EXE_SLL  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
CONSTANT EXE_SLLV  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000100";
CONSTANT EXE_SRL  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000010";
CONSTANT EXE_SRLV  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000110";
CONSTANT EXE_SRA  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000011";
CONSTANT EXE_SRAV  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000111";
CONSTANT EXE_SYNC  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001111";
CONSTANT EXE_PREF  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "110011";

CONSTANT EXE_MOVZ  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001010";
CONSTANT EXE_MOVN  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001011";
CONSTANT EXE_MFHI  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "010000";
CONSTANT EXE_MTHI  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "010001";
CONSTANT EXE_MFLO  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "010010";
CONSTANT EXE_MTLO  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "010011";

CONSTANT EXE_SLT  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101010";
CONSTANT EXE_SLTU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101011";
CONSTANT EXE_SLTI  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001010";
CONSTANT EXE_SLTIU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001011";  
CONSTANT EXE_ADD  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100000";
CONSTANT EXE_ADDU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100001";
CONSTANT EXE_SUB  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100010";
CONSTANT EXE_SUBU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100011";
CONSTANT EXE_ADDI  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001000";
CONSTANT EXE_ADDIU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001001";
CONSTANT EXE_CLZ  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100000";
CONSTANT EXE_CLO  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100001";

CONSTANT EXE_MULT  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "011000";
CONSTANT EXE_MULTU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "011001";
CONSTANT EXE_MUL  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000010";
CONSTANT EXE_MADD  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
CONSTANT EXE_MADDU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000001";
CONSTANT EXE_MSUB  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000100";
CONSTANT EXE_MSUBU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000101";

CONSTANT EXE_DIV  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "011010";
CONSTANT EXE_DIVU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "011011";

CONSTANT EXE_J  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000010";
CONSTANT EXE_JAL  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000011";
CONSTANT EXE_JALR  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001001";
CONSTANT EXE_JR  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "001000";
CONSTANT EXE_BEQ  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000100";
CONSTANT EXE_BGEZ  : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001";
CONSTANT EXE_BGEZAL  : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10001";
CONSTANT EXE_BGTZ  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000111";
CONSTANT EXE_BLEZ  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000110";
CONSTANT EXE_BLTZ  : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
CONSTANT EXE_BLTZAL  : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10000";
CONSTANT EXE_BNE  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000101";

CONSTANT EXE_LB  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100000";
CONSTANT EXE_LBU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100100";
CONSTANT EXE_LH  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100001";
CONSTANT EXE_LHU  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100101";
CONSTANT EXE_LL  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "110000";
CONSTANT EXE_LW  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100011";
CONSTANT EXE_LWL  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100010";
CONSTANT EXE_LWR  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100110";
CONSTANT EXE_SB  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101000";
CONSTANT EXE_SC  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "111000";
CONSTANT EXE_SH  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101001";
CONSTANT EXE_SW  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101011";
CONSTANT EXE_SWL  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101010";
CONSTANT EXE_SWR  : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101110";


CONSTANT EXE_NOP : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
CONSTANT SSNOP : STD_LOGIC_VECTOR(31 DOWNTO 0) :="00000000000000000000000001000000";

CONSTANT EXE_SPECIAL_INST : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
CONSTANT EXE_REGIMM_INST : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000001";
CONSTANT EXE_SPECIAL2_INST : STD_LOGIC_VECTOR(5 DOWNTO 0) := "011100";
--Aluop
CONSTANT EXE_AND_OP   : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100100";
CONSTANT EXE_OR_OP    : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100101";
CONSTANT EXE_XOR_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100110";
CONSTANT EXE_NOR_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100111";
CONSTANT EXE_ANDI_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01011001";
CONSTANT EXE_ORI_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01011010";
CONSTANT EXE_XORI_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01011011";
CONSTANT EXE_LUI_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01011100"; 

CONSTANT EXE_SLL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01111100";
CONSTANT EXE_SLLV_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000100";
CONSTANT EXE_SRL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000010";
CONSTANT EXE_SRLV_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000110";
CONSTANT EXE_SRA_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000011";
CONSTANT EXE_SRAV_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000111";

CONSTANT EXE_MOVZ_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001010";
CONSTANT EXE_MOVN_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001011";
CONSTANT EXE_MFHI_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00010000";
CONSTANT EXE_MTHI_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00010001";
CONSTANT EXE_MFLO_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00010010";
CONSTANT EXE_MTLO_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00010011";

CONSTANT EXE_SLT_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00101010";
CONSTANT EXE_SLTU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00101011";
CONSTANT EXE_SLTI_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01010111";
CONSTANT EXE_SLTIU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01011000";  
CONSTANT EXE_ADD_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100000";
CONSTANT EXE_ADDU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100001";
CONSTANT EXE_SUB_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100010";
CONSTANT EXE_SUBU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100011";
CONSTANT EXE_ADDI_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01010101";
CONSTANT EXE_ADDIU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01010110";
CONSTANT EXE_CLZ_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10110000";
CONSTANT EXE_CLO_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10110001";

CONSTANT EXE_MULT_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00011000";
CONSTANT EXE_MULTU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00011001";
CONSTANT EXE_MUL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10101001";
CONSTANT EXE_MADD_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10100110";
CONSTANT EXE_MADDU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10101000";
CONSTANT EXE_MSUB_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10101010";
CONSTANT EXE_MSUBU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10101011";

CONSTANT EXE_DIV_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00011010";
CONSTANT EXE_DIVU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00011011";

CONSTANT EXE_J_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01001111";
CONSTANT EXE_JAL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01010000";
CONSTANT EXE_JALR_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001001";
CONSTANT EXE_JR_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001000";
CONSTANT EXE_BEQ_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01010001";
CONSTANT EXE_BGEZ_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01000001";
CONSTANT EXE_BGEZAL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01001011";
CONSTANT EXE_BGTZ_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01010100";
CONSTANT EXE_BLEZ_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01010011";
CONSTANT EXE_BLTZ_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01000000";
CONSTANT EXE_BLTZAL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01001010";
CONSTANT EXE_BNE_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01010010";

CONSTANT EXE_LB_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11100000";
CONSTANT EXE_LBU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11100100";
CONSTANT EXE_LH_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11100001";
CONSTANT EXE_LHU_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11100101";
CONSTANT EXE_LL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11110000";
CONSTANT EXE_LW_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11100011";
CONSTANT EXE_LWL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11100010";
CONSTANT EXE_LWR_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11100110";
CONSTANT EXE_PREF_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11110011";
CONSTANT EXE_SB_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11101000";
CONSTANT EXE_SC_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111000";
CONSTANT EXE_SH_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11101001";
CONSTANT EXE_SW_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11101011";
CONSTANT EXE_SWL_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11101010";
CONSTANT EXE_SWR_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11101110";
CONSTANT EXE_SYNC_OP  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001111";

CONSTANT EXE_NOP_OP    : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";


--AluSel
CONSTANT EXE_RES_LOGIC : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
CONSTANT EXE_RES_SHIFT : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
CONSTANT EXE_RES_MOVE : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
CONSTANT EXE_RES_ARITHMETIC : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";	
CONSTANT EXE_RES_MUL : STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";
CONSTANT EXE_RES_JUMP_BRANCH : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
CONSTANT EXE_RES_LOAD_STORE : STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";	

CONSTANT EXE_RES_NOP : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
--inst_rom
CONSTANT InstAddrBus :INTEGER:=32;
CONSTANT InstBus :INTEGER:=32;
CONSTANT InstMemNum:INTEGER:=131071;
CONSTANT InstMemNumLog2:INTEGER:=17;
--data_ram
CONSTANT DataAddrBus :INTEGER:=32;
CONSTANT DataBus :INTEGER:=32;
CONSTANT DataMemNum:INTEGER:=131071;
CONSTANT DataMemNumLog2:INTEGER:=17;
CONSTANT ByteWidth:INTEGER:=8;
--regfile
CONSTANT RegAddrBus :INTEGER:=5;
CONSTANT RegBus :INTEGER:=32;
CONSTANT RegWidth :INTEGER:=32;
CONSTANT DoubleRegWidth :INTEGER:=64;
CONSTANT DoubleRegBus :INTEGER:=64;
CONSTANT RegNum :INTEGER:=32;
CONSTANT RegNumLog2 :INTEGER:=5;
CONSTANT NOPRegAddr : STD_LOGIC_VECTOR(4 DOWNTO 0):="00000";
--div
CONSTANT DivFree : STD_LOGIC_VECTOR(1 DOWNTO 0):= "00";
CONSTANT DivByZero : STD_LOGIC_VECTOR(1 DOWNTO 0):= "01";
CONSTANT DivOn : STD_LOGIC_VECTOR(1 DOWNTO 0):= "10";
CONSTANT DivEnd : STD_LOGIC_VECTOR(1 DOWNTO 0):= "11";
CONSTANT DivResultReady : STD_LOGIC:='1';
CONSTANT DivResultNotReady : STD_LOGIC:='0';
CONSTANT DivStart : STD_LOGIC:='1';
CONSTANT DivStop : STD_LOGIC:='0';



END defines;