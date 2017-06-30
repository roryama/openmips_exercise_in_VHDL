--entity:  data_ram
--File:    data_ram.vhd
--Description: data ram
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY data_ram IS
	PORT( 
		clock:IN STD_LOGIC;
		ce:IN STD_LOGIC;
		we:IN STD_LOGIC;
		addr:IN STD_LOGIC_VECTOR(DataAddrBus-1 DOWNTO 0);
		sel:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		data_i:IN STD_LOGIC_VECTOR(DataBus-1 DOWNTO 0);
		data_o: OUT STD_LOGIC_VECTOR(DataBus-1 DOWNTO 0);
		--view data
		data_mem00:OUT STD_LOGIC_VECTOR(DataBus-1 DOWNTO 0)
	);
END data_ram;

ARCHITECTURE behavior OF data_ram IS
	type data_mem_type is array(0 to DataMemNum-1) of STD_LOGIC_VECTOR(ByteWidth-1 DOWNTO 0 );--Declare an array has 32 number(0 to DataMemNum-1),every number has 32bits( ByteWidth-1 DOWNTO 0 )
	SIGNAL data_mem0 : data_mem_type;
	SIGNAL data_mem1 : data_mem_type;
	SIGNAL data_mem2 : data_mem_type;
	SIGNAL data_mem3 : data_mem_type;
begin
	process
	begin
	WAIT UNTIL clock'EVENT AND clock = '1';
		if (ce = ChipDisable) then
			--data_o <= ZeroWord;
		elsif(we = WriteEnable) then
			if (sel(3) = '1') then
				data_mem3(CONV_INTEGER(addr(DataMemNumLog2+1 DOWNTO 2)))<= data_i( 31 DOWNTO 24 );
			end if;
			if (sel(2) = '1') then
				data_mem2(CONV_INTEGER(addr(DataMemNumLog2+1 DOWNTO 2))) <= data_i( 23 DOWNTO 16 );
			end if;
			if (sel(1)= '1') then
				data_mem1(CONV_INTEGER(addr(DataMemNumLog2+1 DOWNTO 2))) <= data_i( 15 DOWNTO 8 );
			end if;
			if (sel(0) = '1') then
				data_mem0(CONV_INTEGER(addr(DataMemNumLog2+1 DOWNTO 2))) <= data_i( 7 DOWNTO 0 );
			end if;		
		end if;
		data_mem00<=data_i;
	end process;


	process
	begin
	WAIT UNTIL clock'EVENT AND clock = '1';
		if (ce = ChipDisable) then
			data_o <= ZeroWord;
		elsif(we = WriteDisable) then
		    data_o <= data_mem3(CONV_INTEGER(addr(DataMemNumLog2+1 DOWNTO 2)))&
		               data_mem2(CONV_INTEGER(addr(DataMemNumLog2+1 DOWNTO 2)))&
		               data_mem1(CONV_INTEGER(addr(DataMemNumLog2+1 DOWNTO 2)))&
		               data_mem0(CONV_INTEGER(addr(DataMemNumLog2+1 DOWNTO 2)));
		else
			data_o <= ZeroWord;
		end if;
	end process;	
END behavior;