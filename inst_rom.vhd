--entity:  inst_rom
--File:    inst_rom.vhd
--Description: instruction rom
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use STD.TEXTIO.all;
library work;
use work.defines.all;

ENTITY inst_rom IS
	PORT( 
		ce:IN STD_LOGIC;
		addr:IN STD_LOGIC_VECTOR(InstAddrBus-1 DOWNTO 0);
		inst:OUT STD_LOGIC_VECTOR(InstBus-1 DOWNTO 0)
	);
END inst_rom;

ARCHITECTURE behavior OF inst_rom IS
	--1KB=1024B,so 128KB=131072B
	type inst_memory is array(0 to InstMemNum-1) of STD_LOGIC_VECTOR(InstBus-1 DOWNTO 0 );--Declare an array has 131072 number(0 to 131071),every number has 32bits( 31 DOWNTO 0 )
	SIGNAL inst_mem : inst_memory;
	--:=(X"3c020404",X"34420404",X"34070007",X"34070007",X"34050005",X"34080008",X"0000000f",X"00021200",X"00e21004",X"00021202",X"00a21006",X"00000000",X"000214c0",X"00000040",X"00021403",X"01021007",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000");
begin
	process(ce)
	file memfile: TEXT;
	variable L: line;
	variable ch:character;
	variable result : integer;
	--variable i : integer;
	begin
	if (ce=ChipEnable) then
		-- initialize memory from file
		for i in 0 to 127 loop -- set all contents low
			inst_mem(i) <= CONV_STD_LOGIC_VECTOR(0, 32);
		end loop;
		--i:=0;
		FILE_OPEN(memfile, "inst_rom.data", READ_MODE);
		--while not endfile(memfile) loop --if file not end do this
		for i in 0 to 127 loop  --use it or quartus ii can not compile 
			exit when endfile(memfile); --use it or quartus ii can not compile	
			readline(memfile, L);--Read the whole line from the file
			result := 0;
			for j in 1 to 8 loop
				read(L, ch);--read each character from line
				--report "Reading line " & integer'image(i) & " j = " & integer'image(j) & "character = " &character'image(ch) severity error;--debug print each character
				if '0' <= ch and ch <= '9' then 
					result := result*16 + character'pos(ch) - character'pos('0');
				elsif 'a' <= ch and ch <= 'f' then
					result := result*16 + character'pos(ch) - character'pos('a')+10;
				else 
					report "Format error on line " & integer'image(i) severity error;
				end if;
			end loop;
			
			inst_mem(i)<=CONV_STD_LOGIC_VECTOR(result, 32);
			
			--i := i + 1;
		end loop;
	end if;
	end process;
	
	process(ce,addr,inst_mem)
	begin
		if (ce = ChipDisable) then
			inst <= ZeroWord;
		else
		  inst <= inst_mem(CONV_INTEGER(addr( InstMemNumLog2+1 DOWNTO 2)));
		end if;

	end process;
	
END behavior;