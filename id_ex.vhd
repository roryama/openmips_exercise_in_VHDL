--entity:  id_ex
--File:    id_ex.vhd
--Description:ID / EX stage of the register
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY id_ex IS
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--來自控制模組的資訊
		stall:IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		--從解碼階段傳遞的資訊
		id_aluop:IN STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		id_alusel:IN STD_LOGIC_VECTOR(AluSelBus-1 DOWNTO 0);
		id_reg1:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		id_reg2:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		id_wd:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		id_wreg:IN STD_LOGIC;
		id_link_address:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		id_is_in_delayslot:IN STD_LOGIC;
		next_inst_in_delayslot_i:IN STD_LOGIC;
		id_inst:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		--傳遞到執行階段的資訊
		ex_aluop:OUT STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		ex_alusel:OUT STD_LOGIC_VECTOR(AluSelBus-1 DOWNTO 0);
		ex_reg1:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_reg2:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_wd:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		ex_wreg:OUT STD_LOGIC;
		ex_link_address:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_is_in_delayslot:OUT STD_LOGIC;
		is_in_delayslot_o:OUT STD_LOGIC;
		ex_inst:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0)	
	);
END id_ex;

ARCHITECTURE behavior OF id_ex IS
begin
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if (rst = RstEnable) then
			ex_aluop <= EXE_NOP_OP;
			ex_alusel <= EXE_RES_NOP;
			ex_reg1 <= ZeroWord;
			ex_reg2 <= ZeroWord;
			ex_wd <= NOPRegAddr;
			ex_wreg <= WriteDisable;
			ex_link_address <= ZeroWord;
			ex_is_in_delayslot <= NotInDelaySlot;
			is_in_delayslot_o <= NotInDelaySlot;		
			ex_inst <= ZeroWord;	
		elsif(stall(2) = Stop AND stall(3) = NoStop) then
			ex_aluop <= EXE_NOP_OP;
			ex_alusel <= EXE_RES_NOP;
			ex_reg1 <= ZeroWord;
			ex_reg2 <= ZeroWord;
			ex_wd <= NOPRegAddr;
			ex_wreg <= WriteDisable;	
			ex_link_address <= ZeroWord;
			ex_is_in_delayslot <= NotInDelaySlot;	
			ex_inst <= ZeroWord;			
		elsif(stall(2) = NoStop) then		
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;		
			ex_link_address <= id_link_address;
			ex_is_in_delayslot <= id_is_in_delayslot;
			is_in_delayslot_o <= next_inst_in_delayslot_i;
			ex_inst <= id_inst;				
		end if;
	end process;
	
END behavior;