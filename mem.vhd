--entity:  mem
--File:    mem.vhd
--Description:memory access
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY mem IS
	PORT( 
		rst:IN STD_LOGIC;

		--來自執行階段的資訊	
		wd_i:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		wreg_i:IN STD_LOGIC;
		wdata_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		hi_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		lo_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		whilo_i:IN STD_LOGIC;	

		aluop_i:IN STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		mem_addr_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		reg2_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		
		--來自memory的資訊
		mem_data_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

		--LLbit_i是LLbit暫存器的值
		LLbit_i:IN STD_LOGIC;
		--但不一定是最新值，回寫階段可能要寫入LLbit，所以還要進一步判斷
		wb_LLbit_we_i:IN STD_LOGIC;
		wb_LLbit_value_i:IN STD_LOGIC;
		
		--送到回寫階段的資訊
		wd_o:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		wreg_o:OUT STD_LOGIC;
		wdata_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		hi_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		lo_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		whilo_o:OUT STD_LOGIC;

		LLbit_we_o:OUT STD_LOGIC;
		LLbit_value_o:OUT STD_LOGIC;
		
		--送到memory的資訊
		mem_addr_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_we_o:OUT STD_LOGIC;
		mem_sel_o:OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		mem_data_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_ce_o:OUT STD_LOGIC			
	);
END mem;

ARCHITECTURE behavior OF mem IS

	SIGNAL LLbit : STD_LOGIC;
	SIGNAL zero32 : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
	SIGNAL mem_we : STD_LOGIC;
begin
	mem_we_o<= mem_we;
	zero32 <= ZeroWord;
	--獲取最新的LLbit的值
	process(rst,wb_LLbit_we_i,LLbit,wb_LLbit_value_i,LLbit_i)
	begin
		if(rst = RstEnable) then
			LLbit <= '0';
		else
			if(wb_LLbit_we_i = '1') then
				LLbit <= wb_LLbit_value_i;
			else
				LLbit <= LLbit_i;
			end if;
		end if;
	end process;
	
	process(rst,wd_i,wreg_i,wdata_i,hi_i,lo_i,whilo_i,aluop_i,mem_addr_i,mem_data_i,reg2_i,zero32,LLbit)
	begin
		if(rst = RstEnable) then
			wd_o <= NOPRegAddr;
			wreg_o <= WriteDisable;
			wdata_o <= ZeroWord;
			hi_o <= ZeroWord;
			lo_o <= ZeroWord;
			whilo_o <= WriteDisable;		
			mem_addr_o <= ZeroWord;
			mem_we <= WriteDisable;
			mem_sel_o <= "0000";
			mem_data_o <= ZeroWord;	
			mem_ce_o <= ChipDisable;	
			LLbit_we_o <= '0';
			LLbit_value_o <= '0';		      
		else
			wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			hi_o <= hi_i;
			lo_o <= lo_i;
			whilo_o <= whilo_i;		
			mem_we <= WriteDisable;
			mem_addr_o <= ZeroWord;
			mem_sel_o <= "1111";
			mem_ce_o <= ChipDisable;
			LLbit_we_o <= '0';
			LLbit_value_o <= '0';			
			case aluop_i is
				when EXE_LB_OP =>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteDisable;
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>
							wdata_o <= mem_data_i(31)& mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31)&mem_data_i(31) & mem_data_i(31 DOWNTO 24);
							mem_sel_o <= "1000";
						when "01"=>
							wdata_o <= mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) &mem_data_i(23) & mem_data_i(23 DOWNTO 16);
							mem_sel_o <= "0100";
						when "10"=>
							wdata_o <= mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15 DOWNTO 8);
							mem_sel_o <= "0010";
						when "11"=>
							wdata_o <= mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7) & mem_data_i(7 DOWNTO 0);
							mem_sel_o <= "0001";
						WHEN OTHERS =>
							wdata_o <= ZeroWord;
						end case;
				when EXE_LBU_OP=>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteDisable;
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>
							wdata_o <= X"000000" & mem_data_i(31 DOWNTO 24);
							mem_sel_o <= "1000";
						when "01"=>
							wdata_o <= X"000000" & mem_data_i(23 DOWNTO 16);
							mem_sel_o <= "0100";
						when "10"=>
							wdata_o <= X"000000" & mem_data_i(15 DOWNTO 8);
							mem_sel_o <= "0010";
						when "11"=>
							wdata_o <= X"000000" & mem_data_i(7 DOWNTO 0);
							mem_sel_o <= "0001";
						WHEN OTHERS =>
							wdata_o <= ZeroWord;
						end case;
				when EXE_LH_OP=>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteDisable;
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>
							wdata_o <= mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31) & mem_data_i(31 DOWNTO 16);
							mem_sel_o <= "1100";
						when "10"=>
							wdata_o <= mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15) & mem_data_i(15 DOWNTO 0);
							mem_sel_o <= "0011";
						WHEN OTHERS =>
							wdata_o <= ZeroWord;
					end case;
				when EXE_LHU_OP=>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteDisable;
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>
							wdata_o <= X"0000" & mem_data_i(31 DOWNTO 16);
							mem_sel_o <= "1100";
						when "10"=>
							wdata_o <= X"0000" & mem_data_i(15 DOWNTO 0);
							mem_sel_o <= "0011";
						WHEN OTHERS =>
							wdata_o <= ZeroWord;
					end case;
				when EXE_LW_OP=>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteDisable;
					wdata_o <= mem_data_i;
					mem_sel_o <= "1111";		
					mem_ce_o <= ChipEnable;
				when EXE_LWL_OP=>
					mem_addr_o <= mem_addr_i(31 DOWNTO 2) & "00";
					mem_we <= WriteDisable;
					mem_sel_o <= "1111";
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>
							wdata_o <= mem_data_i(31 DOWNTO 0);
						when "01"=>
							wdata_o <= mem_data_i(23 DOWNTO 0) & reg2_i(7 DOWNTO 0);
						when "10"=>
							wdata_o <= mem_data_i(15 DOWNTO 0) & reg2_i(15 DOWNTO 0);
						when "11"=>
							wdata_o <= mem_data_i(7 DOWNTO 0) & reg2_i(23 DOWNTO 0);	
						WHEN OTHERS =>
							wdata_o <= ZeroWord;
					end case;
				when EXE_LWR_OP=>
					mem_addr_o <= mem_addr_i(31 DOWNTO 2)& "00";
					mem_we <= WriteDisable;
					mem_sel_o <= "1111";
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>
							wdata_o <= reg2_i(31 DOWNTO 8) & mem_data_i(31 DOWNTO 24);
						when "01"=>
							wdata_o <= reg2_i(31 DOWNTO 16) & mem_data_i(31 DOWNTO 16);
						when "10"=>
							wdata_o <= reg2_i(31 DOWNTO 24) & mem_data_i(31 DOWNTO 8);
						when "11"=>
							wdata_o <= mem_data_i;	
						WHEN OTHERS =>
							wdata_o <= ZeroWord;
					end case;
				when EXE_LL_OP=>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteDisable;
					wdata_o <= mem_data_i;	
					LLbit_we_o <= '1';
					LLbit_value_o <= '1';
					mem_sel_o <= "1111";			
					mem_ce_o <= ChipEnable;										
				when EXE_SB_OP=>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteEnable;
					mem_data_o <= reg2_i(7 DOWNTO 0)&reg2_i(7 DOWNTO 0)&reg2_i(7 DOWNTO 0)&reg2_i(7 DOWNTO 0);
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>
							mem_sel_o <= "1000";
						when "01"=>
							mem_sel_o <= "0100";
						when "10"=>
							mem_sel_o <= "0010";
						when "11"=>
							mem_sel_o <= "0001";	
						WHEN OTHERS =>
							mem_sel_o <= "0000";
					end case;
				when EXE_SH_OP=>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteEnable;
					mem_data_o <= reg2_i(15 DOWNTO 0)& reg2_i(15 DOWNTO 0);
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>
							mem_sel_o <= "1100";
						when "10"=>
							mem_sel_o <= "0011";
						WHEN OTHERS =>
							mem_sel_o <= "0000";
					end case;
				when EXE_SW_OP=>
					mem_addr_o <= mem_addr_i;
					mem_we <= WriteEnable;
					mem_data_o <= reg2_i;
					mem_sel_o <= "1111";	
					mem_ce_o <= ChipEnable;		
				when EXE_SWL_OP=>
					mem_addr_o <= mem_addr_i(31 DOWNTO 2)&"00";
					mem_we <= WriteEnable;
					mem_data_o <= reg2_i;
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>						  
							mem_sel_o <= "1111";
						when "01"=>
							mem_sel_o <= "0111";
						when "10"=>
							mem_sel_o <= "0011";
						when "11"=>
							mem_sel_o <= "0001";	
						WHEN OTHERS =>
							mem_sel_o <= "0000";
					end case;
				when EXE_SWR_OP=>
					mem_addr_o <= mem_addr_i(31 DOWNTO 2) & "00";
					mem_we <= WriteEnable;
					mem_ce_o <= ChipEnable;
					case mem_addr_i(1 DOWNTO 0) is
						when "00"=>					  
							mem_sel_o <= "1000";
							mem_data_o <= reg2_i(7 DOWNTO 0) & zero32(23 DOWNTO 0);
						when "01"=>
							mem_sel_o <= "1100";
							mem_data_o <= reg2_i(15 DOWNTO 0) & zero32(15 DOWNTO 0);
						when "10"=>
							mem_sel_o <= "1110";
							mem_data_o <= reg2_i(23 DOWNTO 0) & zero32(7 DOWNTO 0);
						when "11"=>
							mem_sel_o <= "1111";	
							mem_data_o <= reg2_i(31 DOWNTO 0);
						WHEN OTHERS =>
							mem_sel_o <= "0000";
					end case;
				when EXE_SC_OP=>
					if(LLbit ='1') then
						LLbit_we_o <= '1';
						LLbit_value_o <= '0';
						mem_addr_o <= mem_addr_i;
						mem_we <= WriteEnable;
						mem_data_o <= reg2_i;
						wdata_o <= X"11111111";
						mem_sel_o <= "1111";		
						mem_ce_o <= ChipEnable;				
					else
						wdata_o <= X"00000000";
					end if;			
				WHEN OTHERS =>
			end case;							
		end if;
	end process;	
	
END behavior;