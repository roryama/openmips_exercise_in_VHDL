--entity:  hilo_reg
--File:    hilo_reg.vhd
--Description:The HI and LO registers that hold the multiplication result
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY hilo_reg IS
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--寫入連接埠
		we:IN STD_LOGIC;
		hi_i: IN STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
		lo_i: IN STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
		--讀取連接埠1
		hi_o: OUT STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
		lo_o: OUT STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 )
	);
END hilo_reg;

ARCHITECTURE behavior OF hilo_reg IS
begin
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if (rst = RstEnable) then
			hi_o <= ZeroWord;
			lo_o <= ZeroWord;
		elsif(we = WriteEnable) then
			hi_o <= hi_i;
			lo_o <= lo_i;
		end if;
	end process;
	
END behavior;