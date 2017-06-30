--entity:  pc_reg
--File:    pc_reg.vhd
--Description:program counter register
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY pc_reg IS
	PORT( 
		rst:IN STD_LOGIC;
		clk:IN STD_LOGIC;
		--from ctrl
		stall:IN STD_LOGIC_VECTOR( 5 DOWNTO 0 );--Pause line control signal
		--clock cycle counter
		cccoun : OUT STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
		--from id
		branch_flag_i: IN STD_LOGIC;
		branch_target_address_i :IN STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
		pc:OUT STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
		ce:OUT STD_LOGIC
	);
END pc_reg;

ARCHITECTURE behavior OF pc_reg IS
	SIGNAL pc_buff : STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
	SIGNAL cccoun_buff : STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
	SIGNAL ce_buff : STD_LOGIC;
begin
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if (ce_buff = ChipDisable) then
			pc_buff <= X"00000000";
			cccoun_buff<= X"00000000";
		elsif (stall(0)=NOSTOP) then
			cccoun_buff<= cccoun_buff+X"0001";--count time
			if (branch_flag_i = Branch) then
				pc_buff<= branch_target_address_i;
			else
				pc_buff <= pc_buff+X"0004";
			end if;
		end if;
		pc<=pc_buff;
		cccoun<=cccoun_buff;
	end process;
	
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if (rst = RstEnable) then
			ce_buff <= ChipDisable;
		else
			ce_buff <= ChipEnable;
		end if;
		ce<=ce_buff;
	end process;
END behavior;

