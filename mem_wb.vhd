--entity:  mem_wb
--File:    mem_wb.vhd
--Description:MEM / WB stage of the register
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY mem_wb IS
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--來自控制模組的資訊
		stall:IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		--來自存取記憶體階段的資訊
		mem_wd: IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		mem_wreg: IN STD_LOGIC;
		mem_wdata: IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_hi: IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_lo: IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_whilo: IN STD_LOGIC;
		
		mem_LLbit_we: IN STD_LOGIC;
		mem_LLbit_value: IN STD_LOGIC;
		--送到回寫階段的資訊
		wb_wd: OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		wb_wreg: OUT STD_LOGIC;
		wb_wdata: OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wb_hi: OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wb_lo: OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wb_whilo: OUT STD_LOGIC;
		
		wb_LLbit_we: OUT STD_LOGIC;
		wb_LLbit_value: OUT STD_LOGIC
	);
END mem_wb;

ARCHITECTURE behavior OF mem_wb IS
begin
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if(rst = RstEnable) then
			wb_wd <= NOPRegAddr;
			wb_wreg <= WriteDisable;
			wb_wdata <= ZeroWord;	
			wb_hi <= ZeroWord;
			wb_lo <= ZeroWord;
			wb_whilo <= WriteDisable;
			wb_LLbit_we <= '0';
			wb_LLbit_value <= '0';			  	
		elsif(stall(4) = Stop AND stall(5) = NoStop) then
			wb_wd <= NOPRegAddr;
			wb_wreg <= WriteDisable;
			wb_wdata <= ZeroWord;
			wb_hi <= ZeroWord;
			wb_lo <= ZeroWord;
			wb_whilo <= WriteDisable;	
			wb_LLbit_we <= '0';
			wb_LLbit_value <= '0';			  	  	  
		elsif(stall(4) = NoStop) then
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;
			wb_whilo <= mem_whilo;		
			wb_LLbit_we <= mem_LLbit_we;
			wb_LLbit_value <= mem_LLbit_value;				
		end if;
	end process;
	
END behavior;