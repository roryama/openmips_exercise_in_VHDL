--entity:  LLbit_reg
--File:    LLbit_reg.vhd
--Description:Save LLbit, used in the SC, LL instructions
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY LLbit_reg IS
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		flush:IN STD_LOGIC;
		--寫入連接埠
		LLbit_i:IN STD_LOGIC;
		we:IN STD_LOGIC;
		--讀取連接埠1
		LLbit_o:OUT STD_LOGIC
	);
END LLbit_reg;

ARCHITECTURE behavior OF LLbit_reg IS
begin
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if (rst = RstEnable) then
			LLbit_o <= '0';
		elsif(flush = '1') then
			LLbit_o <= '0';
		elsif(we = WriteEnable) then
			LLbit_o <= LLbit_i;
		end if;
	end process;
	
END behavior;