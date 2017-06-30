--entity:  ctrl
--File:    ctrl.vhd
--Description:Control module, control pipeline update, pause and so on
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY ctrl IS
	PORT( 
		rst:IN STD_LOGIC;
		stallreq_from_id:IN STD_LOGIC;
		--來自執行階段的暫停請求
		stallreq_from_ex:IN STD_LOGIC;
		stall:OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
	);
END ctrl;

ARCHITECTURE behavior OF ctrl IS
begin
	process(rst,stallreq_from_id,stallreq_from_ex)
	begin
		if(rst = RstEnable) then
			stall <= "000000";
		elsif(stallreq_from_ex = Stop) then
			stall <= "001111";
		elsif(stallreq_from_id = Stop) then
			stall <= "000111";			
		else 
			stall <= "000000";
		end if;

	end process;
	
END behavior;

