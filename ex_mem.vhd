--entity:  ex_mem
--File:    ex_mem.vhd
--Description:ex/mem stage of the register
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY ex_mem IS
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--來自控制模組的資訊
		stall:IN STD_LOGIC_VECTOR(5 DOWNTO 0);	
		
		--來自執行階段的資訊	
		ex_wd:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		ex_wreg:IN STD_LOGIC;
		ex_wdata:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0); 	
		ex_hi:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_lo:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_whilo:IN STD_LOGIC; 	

		--為實現載入、存取記憶體指令而添加
		ex_aluop:IN STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		ex_mem_addr:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_reg2:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

		hilo_i:IN STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);	
		cnt_i:IN STD_LOGIC_VECTOR(1 DOWNTO 0);	
		
		--送到存取記憶體階段的資訊
		mem_wd:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		mem_wreg:OUT STD_LOGIC;
		mem_wdata:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_hi:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_lo:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_whilo:OUT STD_LOGIC;

		--為實現載入、存取記憶體指令而添加
		mem_aluop:OUT STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		mem_mem_addr:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_reg2:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
			
		hilo_o:OUT STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);
		cnt_o	:OUT STD_LOGIC_VECTOR(1 DOWNTO 0)		
		
	);
END ex_mem;

ARCHITECTURE behavior OF ex_mem IS
begin
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if(rst = RstEnable) then
			mem_wd <= NOPRegAddr;
			mem_wreg <= WriteDisable;
			mem_wdata <= ZeroWord;	
			mem_hi <= ZeroWord;
			mem_lo <= ZeroWord;
			mem_whilo <= WriteDisable;		
			hilo_o <= ZeroWord & ZeroWord;
			cnt_o <= "00";	
			mem_aluop <= EXE_NOP_OP;
			mem_mem_addr <= ZeroWord;
			mem_reg2 <= ZeroWord;			
		elsif(stall(3) = Stop AND stall(4) = NoStop) then
			mem_wd <= NOPRegAddr;
			mem_wreg <= WriteDisable;
			mem_wdata <= ZeroWord;
			mem_hi <= ZeroWord;
			mem_lo <= ZeroWord;
			mem_whilo <= WriteDisable;
			hilo_o <= hilo_i;
			cnt_o <= cnt_i;	
			mem_aluop <= EXE_NOP_OP;
			mem_mem_addr <= ZeroWord;
			mem_reg2 <= ZeroWord;						  				    
		elsif(stall(3) = NoStop) then
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;	
			mem_hi <= ex_hi;
			mem_lo <= ex_lo;
			mem_whilo <= ex_whilo;	
			hilo_o <= ZeroWord & ZeroWord;
			cnt_o <= "00";	
			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;			
		else 
			hilo_o <= hilo_i;
			cnt_o <= cnt_i;											
		end if;
	end process;
	
END behavior;