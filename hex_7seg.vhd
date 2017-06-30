--entity:  hex_7seg
--File:    hex_7seg.vhd
--Description: 4-bit conversion 7-segment display
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY hex_7seg IS
	PORT( 
		hex_digit:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		seg:OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END hex_7seg;

ARCHITECTURE behavior OF hex_7seg IS
begin
	process(hex_digit)
	begin
		case hex_digit is
			when "0000"=>
				seg <= "0111111";
			when "0001"=>
				seg <= "0000110";--  ---a----
			when "0010"=>
				seg <= "1011011";-- |        |
			when "0011"=>
				seg <= "1001111";-- f        b
			when "0100"=>
				seg <= "1100110";-- |        |
			when "0101"=>
				seg <= "1101101";--  ---g----
			when "0110"=>
				seg <= "1111101";-- |        |
			when "0111"=>
				seg <= "0000111";-- e        c
			when "1000"=>
				seg <= "1111111";-- |        |
			when "1001"=>
				seg <= "1101111";--  ---d----
			when others=>
				seg <= "0111110";
		end case;
	end process;

	
END behavior;