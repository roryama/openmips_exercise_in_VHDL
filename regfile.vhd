--entity:  regfile
--File:    regfile.vhd
--Description:General registers, has 32 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY regfile IS
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--Write port
		we:IN STD_LOGIC;
		waddr:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		wdata:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		--read port1
		re1:IN STD_LOGIC;
		raddr1:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		rdata1:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		--read port2
		re2:IN STD_LOGIC;
		raddr2:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		rdata2:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0)
	);
END regfile;

ARCHITECTURE behavior OF regfile IS
	type registerfile is array(0 to RegNum-1) of STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0 );--Declare an array has 32 number(0 to 31),every number has 32bits( RegBus-1 DOWNTO 0 )
	SIGNAL regs : registerfile;
begin
	--#############################################################
	--                        write register
	--#############################################################
	process
	begin
	WAIT UNTIL clk'EVENT AND clk = '1';
		if (rst = RstDisable) then
			if((we =WriteEnable) AND (waddr/="00000")) then
				regs(CONV_INTEGER(waddr))<=wdata;
			end if;
		end if;
	end process;
	--#############################################################
	--                        read from register 1
	--#############################################################
	process(rst,raddr1,re1,waddr,we,wdata,regs)
	begin
		if (rst = RstEnable) then
			rdata1<=ZeroWord;
		elsif(raddr1="00000")then
			rdata1<=ZeroWord;
		elsif((raddr1=waddr) and (we=WriteEnable) and (re1=ReadEnable)) then
			rdata1<=wdata;
		elsif (re1=ReadEnable) then
			rdata1<=regs(CONV_INTEGER(raddr1));
		else
			rdata1<=ZeroWord;
		end if;
	end process;
	--#############################################################
	--                        read from register 2
	--#############################################################
	process(rst,raddr2,re2,waddr,we,wdata,regs)
	begin
		if (rst = RstEnable) then
			rdata2<=ZeroWord;
		elsif(raddr2="00000") then
			rdata2<=ZeroWord;
		elsif((raddr2=waddr) and (we=WriteEnable) and (re2=ReadEnable)) then
			rdata2<=wdata;
		elsif (re2=ReadEnable) then
			rdata2<=regs(CONV_INTEGER(raddr2));
		else
			rdata2<=ZeroWord;
		end if;
	end process;
	
END behavior;

