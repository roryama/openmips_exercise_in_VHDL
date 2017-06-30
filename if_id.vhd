--entity:  if_id
--File:    if_id.vhd
--Description:IF / ID stage of the register
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY if_id IS
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		if_pc:IN STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
		if_inst:IN STD_LOGIC_VECTOR( InstBus-1 DOWNTO 0 );
		id_pc:OUT STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );		
		id_inst:OUT STD_LOGIC_VECTOR( InstBus-1 DOWNTO 0 );
		
		stall:IN STD_LOGIC_VECTOR( 5 DOWNTO 0 )--Pause line control signal 
	);
END if_id;

ARCHITECTURE behavior OF if_id IS
begin
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if (rst = RstEnable) then
			id_pc <= ZeroWord;
			id_inst <= ZeroWord;
		elsif ((stall(1)=STOP) AND (stall(2)=NOSTOP)) then
			id_pc <= ZeroWord;
			id_inst <= ZeroWord;
		elsif((stall(1)=NOSTOP)) then
			id_pc <= if_pc;
			id_inst <= if_inst;
		end if;
	end process;
	
END behavior;
