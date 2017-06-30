--entity:  div
--File:    div.vhd
--Description:Division module
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY div IS
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		
		signed_div_i:IN STD_LOGIC;
		opdata1_i:IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		opdata2_i:IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		start_i:IN STD_LOGIC;
		annul_i:IN STD_LOGIC;
		
		result_o:OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
		ready_o:OUT STD_LOGIC
	);
END div;

ARCHITECTURE behavior OF div IS
	SIGNAL div_temp : STD_LOGIC_VECTOR( 32 DOWNTO 0 );
	SIGNAL cnt : STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	SIGNAL dividend : STD_LOGIC_VECTOR( 64 DOWNTO 0 );
	SIGNAL state : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL divisor : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL temp_op1 : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL temp_op2 : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
begin
	div_temp <= ('0' & dividend(63 DOWNTO 32)) - ('0' & divisor);
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if (rst = RstEnable) then
			state <= DivFree;
			ready_o <= DivResultNotReady;
			result_o <= ZeroWord & ZeroWord;
		else
			case state IS
				when DivFree=>               --DivFree狀態
					if(start_i = DivStart AND annul_i = '0') then
						if(opdata2_i = ZeroWord) then
							state <= DivByZero;
						else
							state <= DivOn;
							cnt <= "000000";
							if(signed_div_i = '1' AND opdata1_i(31) = '1' ) then
								temp_op1 <= NOT(opdata1_i) + 1;
							else
								temp_op1 <= opdata1_i;
							end if;
							if(signed_div_i = '1' AND opdata2_i(31) = '1' ) then
								temp_op2 <= NOT(opdata2_i) + 1;
							else
								temp_op2 <= opdata2_i;
							end if;
							dividend <= ZeroWord & ZeroWord & '0';
							dividend(32 DOWNTO 1) <= temp_op1;
							divisor <= temp_op2;
						end if;
					else
						ready_o <= DivResultNotReady;
						result_o <= ZeroWord & ZeroWord;
					end if;       	
				when DivByZero=>               --DivByZero狀態
					dividend <= ZeroWord & ZeroWord &'0';
					state <= DivEnd;		 		
				when DivOn=>              --DivOn狀態
					if(annul_i = '0') then
						if(cnt /= "100000") then
							if(div_temp(32) = '1') then
								dividend <= dividend(63 DOWNTO 0)&'0';
							else
								dividend <= div_temp(31 DOWNTO 0) & dividend(31 DOWNTO 0) & '1';
							end if;
							cnt <= cnt + 1;
						else
							if((signed_div_i = '1') AND ((opdata1_i(31) XOR opdata2_i(31)) = '1')) then
								dividend(31 DOWNTO 0) <= (NOT(dividend(31 DOWNTO 0)) + 1);
							end if;
							if((signed_div_i = '1') AND ((opdata1_i(31) XOR dividend(64)) = '1')) then              
								dividend(64 DOWNTO 33) <= (NOT(dividend(64 DOWNTO 33)) + 1);
							end if;
							state <= DivEnd;
							cnt <= "000000";            	
						end if;
					else
						state <= DivFree;
					end if;	
				when DivEnd=>               --DivEnd狀態
					result_o <= dividend(64 DOWNTO 33)& dividend(31 DOWNTO 0);  
					ready_o <= DivResultReady;
					if(start_i = DivStop) then
						state <= DivFree;
						ready_o <= DivResultNotReady;
						result_o <= ZeroWord & ZeroWord;       	
					end if;	
				WHEN OTHERS =>
			end case;
		end if;

	end process;
	
END behavior;