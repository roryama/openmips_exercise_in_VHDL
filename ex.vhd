--entity:  ex
--File:    ex.vhd
--Description:ex
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY ex IS
	PORT( 
		rst:IN STD_LOGIC;
		
		--送到執行階段的資訊
		aluop_i:IN STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		alusel_i:IN STD_LOGIC_VECTOR(AluSelBus-1 DOWNTO 0);
		reg1_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		reg2_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wd_i:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		wreg_i:IN STD_LOGIC;
		inst_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		
		--HI、LO暫存器的值
		hi_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		lo_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

		--回寫階段的指令是否要寫入HI、LO，用於檢測HI、LO的資料相依
		wb_hi_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wb_lo_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wb_whilo_i:IN STD_LOGIC;
		
		--存取記憶體階段的指令是否要寫入HI、LO，用於檢測HI、LO的資料相依
		mem_hi_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_lo_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_whilo_i:IN STD_LOGIC;

		hilo_temp_i:IN STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);
		cnt_i:IN STD_LOGIC_VECTOR(1 DOWNTO 0);

		--與除法模組相連
		div_result_i:IN STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);
		div_ready_i:IN STD_LOGIC;

		--是否轉移、以及link address
		link_address_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		is_in_delayslot_i:IN STD_LOGIC;	
		
		wd_o:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		wreg_o:OUT STD_LOGIC;
		wdata_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

		hi_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		lo_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		whilo_o:OUT STD_LOGIC;
		
		hilo_temp_o:OUT STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);
		cnt_o:OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

		div_opdata1_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		div_opdata2_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		div_start_o:OUT STD_LOGIC;
		signed_div_o:OUT STD_LOGIC;

		--下面新增的幾個輸出是為載入、儲存指令準備的
		aluop_o:OUT STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		mem_addr_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		reg2_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

		stallreq   :OUT STD_LOGIC	
	);
END ex;

ARCHITECTURE behavior OF ex IS
	SIGNAL logicout : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );--save logic operation result
	SIGNAL shiftres : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );--save shift operation result
	SIGNAL moveres : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );--save move operation result
	SIGNAL arithmeticres : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );--save arithmetic operation result
	SIGNAL mulres : STD_LOGIC_VECTOR( DoubleRegBus-1 DOWNTO 0 );--save multiplication operation result
	
	SIGNAL HI : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
	SIGNAL LO : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
	
	SIGNAL reg2_i_mux : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );-- complement reg2	
	SIGNAL reg1_i_not : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );-- ~reg1
	SIGNAL result_sum : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );--save sum
	
	SIGNAL ov_sum : STD_LOGIC;--save overflow or not
	SIGNAL reg1_eq_reg2 : STD_LOGIC;--save if reg1 = reg2
	SIGNAL reg1_lt_reg2 : STD_LOGIC;--save if reg1 < reg2

	SIGNAL opdata1_mult : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );--save multiplicand result in multiplication operation 
	SIGNAL opdata2_mult : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );--save multiplier result in multiplication operation 
	SIGNAL hilo_temp : STD_LOGIC_VECTOR( DoubleRegBus-1 DOWNTO 0 );--save multiplication operation result temporary
	SIGNAL hilo_temp1 : STD_LOGIC_VECTOR( DoubleRegBus-1 DOWNTO 0 );--save multiplication operation result temporary	
	SIGNAL stallreq_for_madd_msub : STD_LOGIC;
	SIGNAL stallreq_for_div : STD_LOGIC;
	begin
	--aluop_o傳遞到存取記憶體階段，用於載入、儲存指令
	aluop_o <= aluop_i;
  
	--mem_addr傳遞到存取記憶體階段，是載入、儲存指令對應的記憶體位址
	mem_addr_o <= reg1_i + (inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i( 15 DOWNTO 0 ));

	--將兩個運算元也傳遞到存取記憶體階段，也是為載入、儲存指令準備的
	reg2_o <= reg2_i;
	--#############################################################
	--               Logic operation(Calculate by aluop_in)
	--#############################################################
	process(rst,aluop_i,logicout,reg1_i,reg2_i)
	begin
		if(rst = RstEnable) then
			logicout <= ZeroWord;
		else
			case aluop_i is 
				when EXE_OR_OP=>
					logicout <= reg1_i or reg2_i;
				when EXE_AND_OP=>
					logicout <= reg1_i and reg2_i;
				when EXE_NOR_OP=>
					logicout <= reg1_i nor reg2_i;
				when EXE_XOR_OP=>
					logicout <= reg1_i xor reg2_i;
				WHEN OTHERS => 
					logicout <= ZeroWord;
			end case;
		end if;   
	end process;
	--#############################################################
	--               Shift operation(Calculate by aluop_i)
	--#############################################################
	process(rst,aluop_i,reg1_i,reg2_i,shiftres)
	begin
		if (rst = RstEnable) then
			shiftres<=ZeroWord;
		else
			case aluop_i is
				when EXE_SLL_OP=>
					shiftres(31 DOWNTO CONV_INTEGER(reg1_i( 4 DOWNTO 0 )))<=reg2_i( (31-CONV_INTEGER(reg1_i( 4 DOWNTO 0 ))) DOWNTO 0 );					
				when EXE_SRL_OP=>
					shiftres( (31-CONV_INTEGER(reg1_i( 4 DOWNTO 0 ))) DOWNTO 0 )<=reg2_i(31 DOWNTO CONV_INTEGER(reg1_i( 4 DOWNTO 0 )));--CONV_INTEGER(reg2_i( 4 DOWNTO 0 ))要移幾位						
				when EXE_SRA_OP=>
					shiftres(31 DOWNTO (31-CONV_INTEGER(reg1_i( 4 DOWNTO 0 ))+1))<=reg2_i(CONV_INTEGER(reg1_i( 4 DOWNTO 0 ))-1 DOWNTO 0 );
					shiftres( (31-CONV_INTEGER(reg1_i( 4 DOWNTO 0 ))) DOWNTO 0 )<=reg2_i(31 DOWNTO CONV_INTEGER(reg1_i( 4 DOWNTO 0 )));--Logical Shift Right
				WHEN OTHERS => 
					shiftres<=ZeroWord;
			end case;	
		end if;
	end process;
	--#############################################################
	--        Aarithmetic operation(Calculate by aluop_i)
	--#############################################################
	process(rst,aluop_i,reg1_i,reg2_i,reg2_i_mux,result_sum,reg1_lt_reg2,reg1_i_not)
		variable i:integer;
	begin
		if ((aluop_i = EXE_SUB_OP) or (aluop_i = EXE_SUBU_OP) or(aluop_i = EXE_SLT_OP) ) then
			reg2_i_mux<=NOT reg2_i+1;
		else
			reg2_i_mux<=reg2_i;
		end if;
		
		result_sum<=reg1_i+reg2_i_mux;
		
		if (aluop_i = EXE_SLT_OP) then
			reg1_lt_reg2<=((reg1_i(31) and (NOT reg2_i(31))) or ((NOT reg1_i(31)) and (NOT reg2_i(31)) and result_sum(31)) or (reg1_i(31) and reg2_i(31) and result_sum(31)));
		else
			if (reg1_i < reg2_i) then
				reg1_lt_reg2<='1';
			else
				reg1_lt_reg2<='0';
			end if;
		end if;
		
		reg1_i_not <= NOT (reg1_i);
		if (rst = RstEnable) then
			arithmeticres<=ZeroWord;
		else		
			--Calculate overflowornot,reg1_lt_reg2,result_sum,reg1_i_not,compreg2	
			case aluop_i is
				when EXE_SLT_OP=>
					arithmeticres <= X"0000000" &"000"& reg1_lt_reg2;
				when EXE_SLTU_OP=>
					arithmeticres <= X"0000000" &"000"& reg1_lt_reg2;
				when EXE_ADD_OP=> 
					arithmeticres <= result_sum;
				when EXE_ADDU_OP=>
					arithmeticres <= result_sum;
				when EXE_ADDI_OP=> 
					arithmeticres <= result_sum;
				when EXE_ADDIU_OP=>
					arithmeticres <= result_sum; 
				when EXE_SUB_OP=>
					arithmeticres <= result_sum;
				when EXE_SUBU_OP=>
					arithmeticres <= result_sum; 		
				when EXE_CLZ_OP=>
					if (reg1_i(31)='1') then
						arithmeticres<=X"000000" &"00"&"000000";--0
					elsif (reg1_i(30)='1') then
						arithmeticres<=X"000000" &"00"&"000001";--1
					elsif (reg1_i(29)='1') then
						arithmeticres<=X"000000" &"00"&"000010";--2
					elsif (reg1_i(28)='1') then
						arithmeticres<=X"000000" &"00"&"000011";--3
					elsif (reg1_i(27)='1') then
						arithmeticres<=X"000000" &"00"&"000100";--4
					elsif (reg1_i(26)='1') then
						arithmeticres<=X"000000" &"00"&"000101";--5
					elsif (reg1_i(25)='1') then
						arithmeticres<=X"000000" &"00"&"000110";--6
					elsif (reg1_i(24)='1') then
						arithmeticres<=X"000000" &"00"&"000111";--7
					elsif (reg1_i(23)='1') then
						arithmeticres<=X"000000" &"00"&"001000";--8
					elsif (reg1_i(22)='1') then
						arithmeticres<=X"000000" &"00"&"001001";--9
					elsif (reg1_i(21)='1') then
						arithmeticres<=X"000000" &"00"&"001010";--10
					elsif (reg1_i(20)='1') then
						arithmeticres<=X"000000" &"00"&"001011";--11
					elsif (reg1_i(19)='1') then
						arithmeticres<=X"000000" &"00"&"001100";--12
					elsif (reg1_i(18)='1') then
						arithmeticres<=X"000000" &"00"&"001101";--13
					elsif (reg1_i(17)='1') then
						arithmeticres<=X"000000" &"00"&"001110";--14
					elsif (reg1_i(16)='1') then
						arithmeticres<=X"000000" &"00"&"001111";--15
					elsif (reg1_i(15)='1') then
						arithmeticres<=X"000000" &"00"&"010000";--16
					elsif (reg1_i(14)='1') then
						arithmeticres<=X"000000" &"00"&"010001";--17
					elsif (reg1_i(13)='1') then
						arithmeticres<=X"000000" &"00"&"010010";--18
					elsif (reg1_i(12)='1') then
						arithmeticres<=X"000000" &"00"&"010011";--19
					elsif (reg1_i(11)='1') then
						arithmeticres<=X"000000" &"00"&"010100";--20
					elsif (reg1_i(10)='1') then
						arithmeticres<=X"000000" &"00"&"010101";--21
					elsif (reg1_i(9)='1') then
						arithmeticres<=X"000000" &"00"&"010110";--22
					elsif (reg1_i(8)='1') then
						arithmeticres<=X"000000" &"00"&"010111";--23
					elsif (reg1_i(7)='1') then
						arithmeticres<=X"000000" &"00"&"011000";--24
					elsif (reg1_i(6)='1') then
						arithmeticres<=X"000000" &"00"&"011001";--25
					elsif (reg1_i(5)='1') then
						arithmeticres<=X"000000" &"00"&"011010";--26
					elsif (reg1_i(4)='1') then
						arithmeticres<=X"000000" &"00"&"011011";--27
					elsif (reg1_i(3)='1') then
						arithmeticres<=X"000000" &"00"&"011100";--28
					elsif (reg1_i(2)='1') then
						arithmeticres<=X"000000" &"00"&"011101";--29	
					elsif (reg1_i(1)='1') then
						arithmeticres<=X"000000" &"00"&"011110";--30
					elsif (reg1_i(0)='1') then
						arithmeticres<=X"000000" &"00"&"011111";--31						
					else
						arithmeticres<=X"000000" &"00"&"100000";--32
					end if;

				when EXE_CLO_OP=>
					if (reg1_i_not(31)='1') then
						arithmeticres<=X"000000" &"00"&"000000";--0
					elsif (reg1_i_not(30)='1') then
						arithmeticres<=X"000000" &"00"&"000001";--1
					elsif (reg1_i_not(29)='1') then
						arithmeticres<=X"000000" &"00"&"000010";--2
					elsif (reg1_i_not(28)='1') then
						arithmeticres<=X"000000" &"00"&"000011";--3
					elsif (reg1_i_not(27)='1') then
						arithmeticres<=X"000000" &"00"&"000100";--4
					elsif (reg1_i_not(26)='1') then
						arithmeticres<=X"000000" &"00"&"000101";--5
					elsif (reg1_i_not(25)='1') then
						arithmeticres<=X"000000" &"00"&"000110";--6
					elsif (reg1_i_not(24)='1') then
						arithmeticres<=X"000000" &"00"&"000111";--7
					elsif (reg1_i_not(23)='1') then
						arithmeticres<=X"000000" &"00"&"001000";--8
					elsif (reg1_i_not(22)='1') then
						arithmeticres<=X"000000" &"00"&"001001";--9
					elsif (reg1_i_not(21)='1') then
						arithmeticres<=X"000000" &"00"&"001010";--10
					elsif (reg1_i_not(20)='1') then
						arithmeticres<=X"000000" &"00"&"001011";--11
					elsif (reg1_i_not(19)='1') then
						arithmeticres<=X"000000" &"00"&"001100";--12
					elsif (reg1_i_not(18)='1') then
						arithmeticres<=X"000000" &"00"&"001101";--13
					elsif (reg1_i_not(17)='1') then
						arithmeticres<=X"000000" &"00"&"001110";--14
					elsif (reg1_i_not(16)='1') then
						arithmeticres<=X"000000" &"00"&"001111";--15
					elsif (reg1_i_not(15)='1') then
						arithmeticres<=X"000000" &"00"&"010000";--16
					elsif (reg1_i_not(14)='1') then
						arithmeticres<=X"000000" &"00"&"010001";--17
					elsif (reg1_i_not(13)='1') then
						arithmeticres<=X"000000" &"00"&"010010";--18
					elsif (reg1_i_not(12)='1') then
						arithmeticres<=X"000000" &"00"&"010011";--19
					elsif (reg1_i_not(11)='1') then
						arithmeticres<=X"000000" &"00"&"010100";--20
					elsif (reg1_i_not(10)='1') then
						arithmeticres<=X"000000" &"00"&"010101";--21
					elsif (reg1_i_not(9)='1') then
						arithmeticres<=X"000000" &"00"&"010110";--22
					elsif (reg1_i_not(8)='1') then
						arithmeticres<=X"000000" &"00"&"010111";--23
					elsif (reg1_i_not(7)='1') then
						arithmeticres<=X"000000" &"00"&"011000";--24
					elsif (reg1_i_not(6)='1') then
						arithmeticres<=X"000000" &"00"&"011001";--25
					elsif (reg1_i_not(5)='1') then
						arithmeticres<=X"000000" &"00"&"011010";--26
					elsif (reg1_i_not(4)='1') then
						arithmeticres<=X"000000" &"00"&"011011";--27
					elsif (reg1_i_not(3)='1') then
						arithmeticres<=X"000000" &"00"&"011100";--28
					elsif (reg1_i_not(2)='1') then
						arithmeticres<=X"000000" &"00"&"011101";--29	
					elsif (reg1_i_not(1)='1') then
						arithmeticres<=X"000000" &"00"&"011110";--30
					elsif (reg1_i_not(0)='1') then
						arithmeticres<=X"000000" &"00"&"011111";--31						
					else
						arithmeticres<=X"000000" &"00"&"100000";--32
					end if;
				WHEN OTHERS =>
					arithmeticres <= ZeroWord;
			end case;
		end if;
	end process;
	--#############################################################
	--       Multiplication operation(Calculate by aluop_i)
	--#############################################################
	process(rst,aluop_i,reg1_i,reg2_i,opdata2_mult,opdata1_mult,hilo_temp)
	begin
		--取得乘法運算的運算元，如果是有號除法且運算元是負數，那麼取反加一
		if(((aluop_i=EXE_MUL_OP) OR (aluop_i=EXE_MULT_OP)) AND (reg1_i(31)='1'))then
			opdata1_mult<=(NOT reg1_i)+1;
		else
			opdata1_mult<=reg1_i;
		end if;
			
		if(((aluop_i=EXE_MUL_OP) OR (aluop_i=EXE_MULT_OP)) AND (reg2_i(31)='1'))then
			opdata2_mult<=(NOT reg2_i)+1;
		else
			opdata2_mult<=reg2_i;
		end if;			
		hilo_temp<=opdata1_mult*opdata2_mult;	
		
		if (rst = RstEnable) then
			mulres<=ZeroWord & ZeroWord;
		elsif( (aluop_i=EXE_MULT_OP) OR (aluop_i=EXE_MUL_OP) OR (aluop_i = EXE_MADD_OP) OR (aluop_i = EXE_MSUB_OP)) then
			if((reg1_i(31) XOR reg2_i(31))='1')then
				mulres<=(NOT hilo_temp)+1;
			else
				mulres<=hilo_temp;
			end if;
		else
			mulres<=hilo_temp;
		end if;
	end process;
	--#############################################################
	--        Get new data from HILO(solve Data dependency)
	--#############################################################
	process(rst,mem_hi_i,mem_lo_i,wb_hi_i,wb_lo_i,hi_i,lo_i,mem_whilo_i,wb_whilo_i)
	begin
	  --得到最新的HI、LO暫存器的值，此處要解決指令資料相依問題
		if (rst = RstEnable) then
			HI<=ZeroWord;
			LO<=ZeroWord;
		elsif (mem_whilo_i = WriteEnable) then
			HI<=mem_hi_i;
			LO<=mem_lo_i;
		elsif (wb_whilo_i = WriteEnable) then
			HI<=wb_hi_i;
			LO<=wb_lo_i;
		else		
			HI<=hi_i;
			LO<=lo_i;
		end if;
	end process;	
	--#############################################################
	--        						stallreq
	--#############################################################
	process(stallreq_for_madd_msub,stallreq_for_div)
	begin
		stallreq <= stallreq_for_madd_msub or stallreq_for_div;
	end process;	
	--#############################################################
	--        				MADD、MADDU、MSUB、MSUBU
	--#############################################################
	process(rst,aluop_i,cnt_i,mulres,hilo_temp1,HI,LO,hilo_temp_i)
	begin
		if(rst = RstEnable) then
			hilo_temp_o <= ZeroWord & ZeroWord;
			cnt_o <= "00";
			stallreq_for_madd_msub <= NoStop;
		else
			case aluop_i is 
				when EXE_MADD_OP=>
					if(cnt_i = "00") then
						hilo_temp_o <= mulres;
						cnt_o <= "01";
						stallreq_for_madd_msub <= Stop;
						hilo_temp1 <= ZeroWord & ZeroWord;
					elsif(cnt_i = "01") then
						hilo_temp_o <= ZeroWord & ZeroWord;						
						cnt_o <= "10";
						hilo_temp1 <= hilo_temp_i + (HI&LO);
						stallreq_for_madd_msub <= NoStop;
					end if;
				when EXE_MADDU_OP=>	
					if(cnt_i = "00") then
						hilo_temp_o <= mulres;
						cnt_o <= "01";
						stallreq_for_madd_msub <= Stop;
						hilo_temp1 <= ZeroWord & ZeroWord;
					elsif(cnt_i = "01") then
						hilo_temp_o <= ZeroWord & ZeroWord;						
						cnt_o <= "10";
						hilo_temp1 <= hilo_temp_i + (HI&LO);
						stallreq_for_madd_msub <= NoStop;
					end if;
				when EXE_MSUB_OP=>
					if(cnt_i = "00") then
						hilo_temp_o <=  NOT(mulres) + 1 ;
						cnt_o <= "01";
						stallreq_for_madd_msub <= Stop;
					elsif(cnt_i = "01")then
						hilo_temp_o <= ZeroWord & ZeroWord;						
						cnt_o <= "10";
						hilo_temp1 <= hilo_temp_i + (HI & LO);
						stallreq_for_madd_msub <= NoStop;
					end if;	
				when EXE_MSUBU_OP=>		
					if(cnt_i = "00") then
						hilo_temp_o <=  NOT(mulres) + 1 ;
						cnt_o <= "01";
						stallreq_for_madd_msub <= Stop;
					elsif(cnt_i = "01")then
						hilo_temp_o <= ZeroWord & ZeroWord;						
						cnt_o <= "10";
						hilo_temp1 <= hilo_temp_i + (HI & LO);
						stallreq_for_madd_msub <= NoStop;
					end if;				
				WHEN OTHERS => 	
					hilo_temp_o <= ZeroWord & ZeroWord;
					cnt_o <= "00";
					stallreq_for_madd_msub <= NoStop;				
			end case;
		end if;
	end process;		
	--#############################################################
	--        						DIV、DIVU
	--#############################################################
	process(rst,aluop_i,div_ready_i,reg1_i,reg2_i)
	begin
		if(rst = RstEnable) then
			stallreq_for_div <= NoStop;
			div_opdata1_o <= ZeroWord;
			div_opdata2_o <= ZeroWord;
			div_start_o <= DivStop;
			signed_div_o <= '0';
		else
			stallreq_for_div <= NoStop;
			div_opdata1_o <= ZeroWord;
			div_opdata2_o <= ZeroWord;
			div_start_o <= DivStop;
			signed_div_o <= '0';	
			case aluop_i is
				WHEN EXE_DIV_OP=>
					if(div_ready_i = DivResultNotReady)then
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= DivStart;
						signed_div_o <= '1';
						stallreq_for_div <= Stop;
					elsif(div_ready_i =DivResultReady) then
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= DivStop;
						signed_div_o <= '1';
						stallreq_for_div <= NoStop;
					else						
						div_opdata1_o <= ZeroWord;
						div_opdata2_o <= ZeroWord;
						div_start_o <= DivStop;
						signed_div_o <= '0';
						stallreq_for_div <= NoStop;
					end if;				
				WHEN EXE_DIVU_OP =>
					if(div_ready_i = DivResultNotReady) then
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= DivStart;
						signed_div_o <= '0';
						stallreq_for_div <= Stop;
					elsif(div_ready_i = DivResultReady) then
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= DivStop;
						signed_div_o <= '0';
						stallreq_for_div <= NoStop;
					else						
						div_opdata1_o <= ZeroWord;
						div_opdata2_o <= ZeroWord;
						div_start_o <= DivStop;
						signed_div_o <= '0';
						stallreq_for_div <= NoStop;
					end if;					
				WHEN OTHERS => 
			end case;
		end if;
	end process;	
	--#############################################################
	--        				MFHI,MFLO,MOVN,MOVZ
	--#############################################################
	process(rst,aluop_i,HI,LO,reg1_i)
	begin
		if(rst =RstEnable) then
			moveres <= ZeroWord;
		else
			moveres <= ZeroWord;
			case aluop_i is
				WHEN EXE_MFHI_OP=>
					moveres <= HI;
				WHEN EXE_MFLO_OP=>
					moveres <= LO;
				WHEN EXE_MOVZ_OP=>
					moveres <= reg1_i;
				WHEN EXE_MOVN_OP=>
					moveres <= reg1_i;
				WHEN OTHERS =>
			end case;
		end if;
	end process;	
	--#############################################################
	--       Choose a result of the operation by alutype_in
	--#############################################################
	process(alusel_i,wd_i,reg2_i_mux,reg1_i,result_sum,aluop_i,ov_sum,wreg_i,logicout,shiftres,moveres,arithmeticres,mulres,link_address_i)
		
	begin
		--if ((aluop_i = EXE_SUB_OP) or (aluop_i = EXE_SUBU_OP) or(aluop_i = EXE_SLT_OP) ) then
		--	reg2_i_mux<=(NOT reg2_i)+1;
		--else
		--	reg2_i_mux<=reg2_i;
		--end if;
		--result_sum<=reg1_i+reg2_i_mux;							 

		ov_sum <= (((NOT reg1_i(31)) and (NOT reg2_i_mux(31))) and result_sum(31)) or ((reg1_i(31) and reg2_i_mux(31)) and (NOT result_sum(31))); 
		wd_o <= wd_i;
	 	 	 	
	 if(((aluop_i = EXE_ADD_OP) or (aluop_i = EXE_ADDI_OP) or (aluop_i = EXE_SUB_OP)) and (ov_sum = '1')) then
	 	wreg_o <= WriteDisable;
	 else
		wreg_o <= wreg_i;
	 end if;
	 
	 case alusel_i IS 
	 	WHEN EXE_RES_LOGIC=>		
	 		wdata_o <= logicout;
	 	WHEN EXE_RES_SHIFT=>		
	 		wdata_o <= shiftres;
	 	WHEN EXE_RES_MOVE=>		
	 		wdata_o <= moveres;
	 	WHEN EXE_RES_ARITHMETIC=>	
	 		wdata_o <= arithmeticres;
	 	WHEN EXE_RES_MUL=>		
	 		wdata_o <= mulres(31 DOWNTO 0);
	 	WHEN EXE_RES_JUMP_BRANCH=>	
	 		wdata_o <= link_address_i;	 	
	 	WHEN OTHERS =>
	 		wdata_o <= ZeroWord;
	 end case;
	end process;
	--#############################################################
	--        	MTHI,MTLO(need whilo_out,hi_out,lo_out)
	--#############################################################
	process(rst,div_result_i,aluop_i,reg1_i,LO,mulres,hilo_temp1,HI)
		
	begin
		if(rst = RstEnable) then
			whilo_o <= WriteDisable;
			hi_o <= ZeroWord;
			lo_o <= ZeroWord;		
		elsif((aluop_i = EXE_MULT_OP) or (aluop_i = EXE_MULTU_OP)) then
			whilo_o <= WriteEnable;
			hi_o <= mulres(63 DOWNTO 32);
			lo_o <= mulres(31 DOWNTO 0);			
		elsif((aluop_i = EXE_MADD_OP) or (aluop_i = EXE_MADDU_OP)) then
			whilo_o <= WriteEnable;
			hi_o <= hilo_temp1(63 DOWNTO 32);
			lo_o <= hilo_temp1(31 DOWNTO 0);
		elsif((aluop_i = EXE_MSUB_OP) or (aluop_i = EXE_MSUBU_OP)) then
			whilo_o <= WriteEnable;
			hi_o <= hilo_temp1(63 DOWNTO 32);
			lo_o <= hilo_temp1(31 DOWNTO 0);		
		elsif((aluop_i = EXE_DIV_OP) or (aluop_i = EXE_DIVU_OP)) then
			whilo_o <= WriteEnable;
			hi_o <= div_result_i(63 DOWNTO 32);
			lo_o <= div_result_i(31 DOWNTO 0);							
		elsif(aluop_i =EXE_MTHI_OP) then
			whilo_o <= WriteEnable;
			hi_o <= reg1_i;
			lo_o <= LO;
		elsif(aluop_i = EXE_MTLO_OP) then
			whilo_o <= WriteEnable;
			hi_o <= HI;
			lo_o <= reg1_i;
		else
			whilo_o <= WriteDisable;
			hi_o <= ZeroWord;
			lo_o <= ZeroWord;
		end if;				
	
	end process;	

	

	
END behavior;