--entity:  id
--File:    id.vhd
--Description:decode
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

ENTITY id IS
	PORT( 
	rst:IN STD_LOGIC;
	pc_i:IN STD_LOGIC_VECTOR(InstAddrBus-1 DOWNTO 0);
	inst_i:IN STD_LOGIC_VECTOR(InstBus-1 DOWNTO 0);

  	--處於執行階段的指令的一些資訊，用於解決load相依
	ex_aluop_i:IN STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);

	--處於執行階段的指令要寫入的目的暫存器資訊
	ex_wreg_i:IN STD_LOGIC;
	ex_wdata_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	ex_wd_i:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	
	--處於存取記憶體階段的指令要寫入的目的暫存器資訊
	mem_wreg_i:IN STD_LOGIC;
	mem_wdata_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	mem_wd_i:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	
	reg1_data_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	reg2_data_i:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

	--如果上一條指令是轉移指令，那麼下一條指令在解碼的時候is_in_delayslot為true
	is_in_delayslot_i:IN STD_LOGIC;

	--送到regfile的資訊
	reg1_read_o:OUT STD_LOGIC;
	reg2_read_o:OUT STD_LOGIC;     
	reg1_addr_o:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	reg2_addr_o:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0); 	      
	
	--送到執行階段的資訊
	aluop_o:OUT STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
	alusel_o:OUT STD_LOGIC_VECTOR(AluSelBus-1 DOWNTO 0);
	reg1_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	reg2_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	wd_o:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	wreg_o:OUT STD_LOGIC;
	inst_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

	next_inst_in_delayslot_o:OUT STD_LOGIC;
	
	branch_flag_o:OUT STD_LOGIC;
	branch_target_address_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);       
	link_addr_o:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	is_in_delayslot_o:OUT STD_LOGIC;
	
	stallreq:OUT STD_LOGIC
	);
END id;

ARCHITECTURE behavior OF id IS
	SIGNAL op1 : STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	SIGNAL op2 : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL op3 : STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	SIGNAL op4 : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL imm : STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
	SIGNAL instvalid : STD_LOGIC;
	
	SIGNAL pc_plus_8: STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
	SIGNAL pc_plus_4: STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
	SIGNAL imm_sll2_signedext: STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
	
	SIGNAL stallreq_for_reg1_loadrelate : STD_LOGIC;
	SIGNAL stallreq_for_reg2_loadrelate : STD_LOGIC;
	SIGNAL pre_inst_is_load : STD_LOGIC;
	
	--To solve Data dependency
	SIGNAL reg1_addr_buff:STD_LOGIC_VECTOR( 4 DOWNTO 0 );--reg1_addr_o
	SIGNAL reg2_addr_buff:STD_LOGIC_VECTOR( 4 DOWNTO 0 );--reg2_addr_o
	SIGNAL reg1_read_buf:STD_LOGIC;--reg1_read_o
	SIGNAL reg2_read_buf:STD_LOGIC;--reg2_read_o
	--MOVZ.MOVN
	SIGNAL reg1_out_buff:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL reg2_out_buff:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
begin
	op1<=inst_i( 31 DOWNTO 26 );
	op2<=inst_i( 10 DOWNTO 6 );
	op3<=inst_i( 5 DOWNTO 0 );
	op4<=inst_i( 20 DOWNTO 16 );
	pc_plus_8 <=pc_i + 8;
	pc_plus_4 <= pc_i +4;
	imm_sll2_signedext <=inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)
								&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)
								&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i( 15 DOWNTO 0 )
								&"00";--{{14{inst_i[15]}}, inst_i[15:0], 2'b00 } 
	stallreq <= stallreq_for_reg1_loadrelate or stallreq_for_reg2_loadrelate;--|

	inst_o <= inst_i;
	--#############################################################
	--                        Instruction decode
	--#############################################################
	process(rst,inst_i,op1,op2,op3,op4,instvalid,reg2_out_buff,reg1_out_buff,pc_plus_8,pc_plus_4,imm_sll2_signedext)
	begin
		if (rst = RstEnable) then
			aluop_o <= EXE_NOP_OP;
			alusel_o <= EXE_RES_NOP;
			wd_o <= NOPRegAddr;
			wreg_o <= WriteDisable;
			instvalid <= InstValid;
			reg1_read_o <= '0';
			reg1_read_buf<= '0';
			reg2_read_o <= '0';
			reg2_read_buf<='0';
			reg1_addr_o <= NOPRegAddr;
			reg1_addr_buff<= NOPRegAddr;
			reg2_addr_o <= NOPRegAddr;
			reg2_addr_buff<=NOPRegAddr;
			imm <= X"00000000";	
			link_addr_o <= ZeroWord;
			branch_target_address_o <= ZeroWord;
			branch_flag_o <= NotBranch;
			next_inst_in_delayslot_o <= NotInDelaySlot;					
		else
			aluop_o <= EXE_NOP_OP;
			alusel_o <= EXE_RES_NOP;
			wd_o <= inst_i( 15 DOWNTO 11 );
			wreg_o <= WriteDisable;
			instvalid <= InstInvalid;	   
			reg1_read_o <= '0';
			reg1_read_buf<= '0';
			reg2_read_o <= '0';
			reg2_read_buf<='0';
			reg1_addr_o <= inst_i(25 DOWNTO 21);
			reg1_addr_buff<= inst_i(25 DOWNTO 21);
			reg2_addr_o <= inst_i(20 DOWNTO 16);
			reg2_addr_buff<= inst_i(20 DOWNTO 16);
			imm <= ZeroWord;
			link_addr_o <= ZeroWord;
			branch_target_address_o <= ZeroWord;
			branch_flag_o <= NotBranch;	
			next_inst_in_delayslot_o <= NotInDelaySlot; 			
		  case op1 is
		    when EXE_SPECIAL_INST=>
		    	case op2 is
		    		when "00000"=>
		    			case op3 is
		    				when EXE_OR=>
		    					wreg_o <= WriteEnable;		
								aluop_o <= EXE_OR_OP;
		  						alusel_o <= EXE_RES_LOGIC; 	
								reg1_read_o <= '1';
								reg1_read_buf<= '1';	
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	  
		    				when EXE_AND=>
		    					wreg_o <= WriteEnable;		
								aluop_o <= EXE_AND_OP;
		  						alusel_o <= EXE_RES_LOGIC;	  
								reg1_read_o <= '1';
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	  	
		    				when EXE_XOR=>
		    					wreg_o <= WriteEnable;		
								aluop_o <= EXE_XOR_OP;
		  						alusel_o <= EXE_RES_LOGIC;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';	
								reg2_read_buf<='1';
		  						instvalid <= InstValid;				
		    				when EXE_NOR=>
		    					wreg_o <= WriteEnable;		
								aluop_o <= EXE_NOR_OP;
		  						alusel_o <= EXE_RES_LOGIC;		
								reg1_read_o <= '1';
								reg1_read_buf<='1';
								reg2_read_o <= '1';	
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	
							when EXE_SLLV=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_SLL_OP;
		  						alusel_o <= EXE_RES_SHIFT;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	
							when EXE_SRLV=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_SRL_OP;
		  						alusel_o <= EXE_RES_SHIFT;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;						
							when EXE_SRAV=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_SRA_OP;
		  						alusel_o <= EXE_RES_SHIFT;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;			
							when EXE_MFHI=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_MFHI_OP;
		  						alusel_o <= EXE_RES_MOVE;   
								reg1_read_o <= '0';
								reg1_read_buf<='0';	
								reg2_read_o <= '0';
								reg2_read_buf<='0';
		  						instvalid <= InstValid;	
							when EXE_MFLO=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_MFLO_OP;
		  						alusel_o <= EXE_RES_MOVE;   
								reg1_read_o <= '0';	
								reg1_read_buf<='0';
								reg2_read_o <= '0';
								reg2_read_buf<='0';
		  						instvalid <= InstValid;	
							when EXE_MTHI=>
								wreg_o <= WriteDisable;		
								aluop_o <= EXE_MTHI_OP;
		  						reg1_read_o <= '1';
								reg1_read_buf<='1';	
								reg2_read_o <= '0';
								reg2_read_buf<='0';
								instvalid <= InstValid;	
							when EXE_MTLO=>
								wreg_o <= WriteDisable;		
								aluop_o <= EXE_MTLO_OP;
		  						reg1_read_o <= '1';
								reg1_read_buf<='1';	
								reg2_read_o <= '0'; 
								reg2_read_buf<='0';
								instvalid <= InstValid;	
							when EXE_MOVN=>
								aluop_o <= EXE_MOVN_OP;
		  						alusel_o <= EXE_RES_MOVE;   
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;
								if(reg2_out_buff /= ZeroWord) then
	 								wreg_o <= WriteEnable;
	 							else
	 								wreg_o <= WriteDisable;
	 							end if;
							when EXE_MOVZ=>
								aluop_o <= EXE_MOVZ_OP;
		  						alusel_o <= EXE_RES_MOVE;   
								reg1_read_o <= '1';
								reg1_read_buf<='1';	
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;
								if(reg2_out_buff = ZeroWord) then
	 								wreg_o <= WriteEnable;
	 							else
	 								wreg_o <= WriteDisable;
	 							end if;		  							
							when EXE_SLT=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_SLT_OP;
		  						alusel_o <= EXE_RES_ARITHMETIC;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	
							when EXE_SLTU=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_SLTU_OP;
		  						alusel_o <= EXE_RES_ARITHMETIC;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	
							when EXE_SYNC=>
								wreg_o <= WriteDisable;		
								aluop_o <= EXE_NOP_OP;
		  						alusel_o <= EXE_RES_NOP;		
								reg1_read_o <= '0';
								reg1_read_buf<='0';	
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;								
							when EXE_ADD=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_ADD_OP;
		  						alusel_o <= EXE_RES_ARITHMETIC;		
								reg1_read_o <= '1';
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	
							when EXE_ADDU=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_ADDU_OP;
		  						alusel_o <= EXE_RES_ARITHMETIC;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	
							when EXE_SUB=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_SUB_OP;
		  						alusel_o <= EXE_RES_ARITHMETIC;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	
							when EXE_SUBU=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_SUBU_OP;
		  						alusel_o <= EXE_RES_ARITHMETIC;		
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';
		  						instvalid <= InstValid;	
							when EXE_MULT=>
								wreg_o <= WriteDisable;		
								aluop_o <= EXE_MULT_OP;
		  						reg1_read_o <= '1';
								reg1_read_buf<='1';	
								reg2_read_o <= '1'; 
								reg2_read_buf<='1';
								instvalid <= InstValid;	
							when EXE_MULTU=>
								wreg_o <= WriteDisable;		
								aluop_o <= EXE_MULTU_OP;
		  						reg1_read_o <= '1';
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';	
								instvalid <= InstValid;	
							when EXE_DIV=>
								wreg_o <= WriteDisable;		
								aluop_o <= EXE_DIV_OP;
		  						reg1_read_o <= '1';
								reg1_read_buf<='1';
								reg2_read_o <= '1';
								reg2_read_buf<='1';	
								instvalid <= InstValid;	
							when EXE_DIVU=>
								wreg_o <= WriteDisable;		
								aluop_o <= EXE_DIVU_OP;
		  						reg1_read_o <= '1';
								reg1_read_buf<='1';
								reg2_read_o <= '1'; 
								reg2_read_buf<='1';
								instvalid <= InstValid;			
							when EXE_JR=>
								wreg_o <= WriteDisable;		
								aluop_o <= EXE_JR_OP;
		  						alusel_o <= EXE_RES_JUMP_BRANCH;   
								reg1_read_o <= '1';	
								reg1_read_buf<='1';
								reg2_read_o <= '0';
								reg2_read_buf<='0';
		  						link_addr_o <= ZeroWord;
		  						
			            	branch_target_address_o <= reg1_out_buff;
			            	branch_flag_o <= Branch;
			           
								next_inst_in_delayslot_o <= InDelaySlot;
								instvalid <= InstValid;	
							when EXE_JALR=>
								wreg_o <= WriteEnable;		
								aluop_o <= EXE_JALR_OP;
		  						alusel_o <= EXE_RES_JUMP_BRANCH;   
								reg1_read_o <= '1';
								reg1_read_buf<='1';	
								reg2_read_o <= '0';
								reg2_read_buf<='0';
		  						wd_o <= inst_i(15 DOWNTO 11);
		  						link_addr_o <= pc_plus_8;
		  						
			            	branch_target_address_o <= reg1_out_buff;
			            	branch_flag_o <= Branch;
			           
								next_inst_in_delayslot_o <= InDelaySlot;
								instvalid <= InstValid;														 											  											
							WHEN OTHERS =>
						end case;
					WHEN OTHERS =>
				end case;								  
		  	when EXE_ORI=>                        --ORI指令
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_OR_OP;
		  		alusel_o <= EXE_RES_LOGIC; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';				
				imm <= X"0000"& inst_i(15 DOWNTO 0);		
				wd_o <= inst_i(20 DOWNTO 16);
				instvalid <= InstValid;	
		  	when EXE_ANDI=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_AND_OP;
		  		alusel_o <= EXE_RES_LOGIC;	
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';				
				imm <= X"0000"& inst_i(15 DOWNTO 0);		
				wd_o <= inst_i(20 DOWNTO 16);		  	
				instvalid <= InstValid;		 	
		  	when EXE_XORI=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_XOR_OP;
		  		alusel_o <= EXE_RES_LOGIC;	
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '0';	
				reg2_read_buf<='0';
				imm <= X"0000"& inst_i(15 DOWNTO 0);		
				wd_o <= inst_i(20 DOWNTO 16);		  	
				instvalid <= InstValid;	 		
		  	when EXE_LUI=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_OR_OP;
		  		alusel_o <= EXE_RES_LOGIC; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
				imm <= inst_i(15 DOWNTO 0)& X"0000";		
				wd_o <= inst_i(20 DOWNTO 16);		  	
				instvalid <= InstValid;			
			when EXE_SLTI=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_SLT_OP;
		  		alusel_o <= EXE_RES_ARITHMETIC; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '0';	
				reg2_read_buf<='0';
				imm <= inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i( 15 DOWNTO 0 );	
				wd_o <= inst_i(20 DOWNTO 16);		  	
				instvalid <= InstValid;	
			when EXE_SLTIU=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_SLTU_OP;
		  		alusel_o <= EXE_RES_ARITHMETIC; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '0';	 
				reg2_read_buf<='0';
				imm <=inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i( 15 DOWNTO 0 );--signed extension->copy first bit to Expanded into 32 bits	
				wd_o <= inst_i(20 DOWNTO 16);		  	
				instvalid <= InstValid;	
			when EXE_PREF=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_NOP_OP;
		  		alusel_o <= EXE_RES_NOP; 
				reg1_read_o <= '0';
				reg1_read_buf<='0';
				reg2_read_o <= '0';	
				reg2_read_buf<='0';
				instvalid <= InstValid;							
			when EXE_ADDI=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_ADDI_OP;
		  		alusel_o <= EXE_RES_ARITHMETIC; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '0';	
				reg2_read_buf<='0';
				imm <=inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i( 15 DOWNTO 0 );--signed extension->copy first bit to Expanded into 32 bits		
				wd_o <= inst_i(20 DOWNTO 16);		  	
				instvalid <= InstValid;	
			when EXE_ADDIU=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_ADDIU_OP;
		  		alusel_o <= EXE_RES_ARITHMETIC; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '0';	
				reg2_read_buf<='0';
				imm <= inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i(15)&inst_i( 15 DOWNTO 0 );--signed extension->copy first bit to Expanded into 32 bits		
				wd_o <= inst_i(20 DOWNTO 16);		  	
				instvalid <= InstValid;	
			when EXE_J=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_J_OP;
		  		alusel_o <= EXE_RES_JUMP_BRANCH; 
				reg1_read_o <= '0';	
				reg1_read_buf<='0';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
		  		link_addr_o <= ZeroWord;
			   branch_target_address_o <= pc_plus_4(31 DOWNTO 28)& inst_i(25 DOWNTO 0)& "00";
			   branch_flag_o <= Branch;
			   next_inst_in_delayslot_o <= InDelaySlot;		  	
			   instvalid <= InstValid;	
			when EXE_JAL=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_JAL_OP;
		  		alusel_o <= EXE_RES_JUMP_BRANCH; 
				reg1_read_o <= '0';	
				reg1_read_buf<='0';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
		  		wd_o <= "11111";	
		  		link_addr_o <= pc_plus_8 ;
			   branch_target_address_o <= pc_plus_4(31 DOWNTO 28)& inst_i(25 DOWNTO 0)& "00";
			   branch_flag_o <= Branch;
			   next_inst_in_delayslot_o <= InDelaySlot;		  	
			   instvalid <= InstValid;	
			when EXE_BEQ=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_BEQ_OP;
		  		alusel_o <= EXE_RES_JUMP_BRANCH; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '1';
				reg2_read_buf<='1';
		  		instvalid <= InstValid;	
		  		if(reg1_out_buff = reg2_out_buff) then
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= Branch;
			    	next_inst_in_delayslot_o <= InDelaySlot;		  	
			   end if;
			when EXE_BGTZ=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_BGTZ_OP;
		  		alusel_o <= EXE_RES_JUMP_BRANCH; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
		  		instvalid <= InstValid;	
		  		if((reg1_out_buff(31) = '0') and (reg1_out_buff /= ZeroWord)) then
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= Branch;
			    	next_inst_in_delayslot_o <= InDelaySlot;		  	
			   end if;
			when EXE_BLEZ=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_BLEZ_OP;
		  		alusel_o <= EXE_RES_JUMP_BRANCH; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
		  		instvalid <= InstValid;	
		  		if((reg1_out_buff(31) = '1') or (reg1_out_buff = ZeroWord)) then
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= Branch;
			    	next_inst_in_delayslot_o <= InDelaySlot;		  	
			    end if;
			when EXE_BNE=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_BLEZ_OP;
		  		alusel_o <= EXE_RES_JUMP_BRANCH; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '1';
				reg2_read_buf<='1';
		  		instvalid <= InstValid;	
		  		if(reg1_out_buff /= reg2_out_buff) then
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= Branch;
			    	next_inst_in_delayslot_o <= InDelaySlot;		  	
			   end if;
			when EXE_LB=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_LB_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
			when EXE_LBU=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_LBU_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
			when EXE_LH=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_LH_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
			when EXE_LHU=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_LHU_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '0';	
				reg2_read_buf<='0';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
			when EXE_LW=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_LW_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '0';	
				reg2_read_buf<='0';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
			when EXE_LL=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_LL_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '0';
				reg2_read_buf<='0';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
			when EXE_LWL=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_LWL_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '1';
				reg2_read_buf<='1';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
			when EXE_LWR=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_LWR_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';
				reg1_read_buf<='1';	
				reg2_read_o <= '1';	
				reg2_read_buf<='1';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
			when EXE_SB=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_SB_OP;
		  		reg1_read_o <= '1';
				reg1_read_buf<='1';	
				reg2_read_o <= '1';
				reg2_read_buf<='1';	
				instvalid <= InstValid;	
		  		alusel_o <= EXE_RES_LOAD_STORE; 
			when EXE_SH=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_SH_OP;
		  		reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '1'; 
				reg2_read_buf<='1';
				instvalid <= InstValid;	
		  		alusel_o <= EXE_RES_LOAD_STORE; 
			when EXE_SW=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_SW_OP;
		  		reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '1'; 
				reg2_read_buf<='1';
				instvalid <= InstValid;	
		  		alusel_o <= EXE_RES_LOAD_STORE; 
			when EXE_SWL=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_SWL_OP;
		  		reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '1'; 
				reg2_read_buf<='1';
				instvalid <= InstValid;	
		  		alusel_o <= EXE_RES_LOAD_STORE; 
			when EXE_SWR=>
		  		wreg_o <= WriteDisable;		
				aluop_o <= EXE_SWR_OP;
		  		reg1_read_o <= '1';
				reg1_read_buf<='1';
				reg2_read_o <= '1'; 
				reg2_read_buf<='1';
				instvalid <= InstValid;	
		  		alusel_o <= EXE_RES_LOAD_STORE; 
			when EXE_SC=>
		  		wreg_o <= WriteEnable;		
				aluop_o <= EXE_SC_OP;
		  		alusel_o <= EXE_RES_LOAD_STORE; 
				reg1_read_o <= '1';	
				reg1_read_buf<='1';
				reg2_read_o <= '1';	
				reg2_read_buf<='1';
				wd_o <= inst_i(20 DOWNTO 16); 
				instvalid <= InstValid;	
				alusel_o <= EXE_RES_LOAD_STORE; 			
			when EXE_REGIMM_INST=>
				case op4 is
					when EXE_BGEZ=>
						wreg_o <= WriteDisable;		
						aluop_o <= EXE_BGEZ_OP;
		  				alusel_o <= EXE_RES_JUMP_BRANCH; 
						reg1_read_o <= '1';	
						reg1_read_buf<='1';
						reg2_read_o <= '0';
						reg2_read_buf<='0';
		  				instvalid <= InstValid;	
		  				if(reg1_out_buff(31) = '0') then
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= Branch;
			    			next_inst_in_delayslot_o <= InDelaySlot;		  	
			   		end if;
					when EXE_BGEZAL=>
						wreg_o <= WriteEnable;		
						aluop_o <= EXE_BGEZAL_OP;
		  				alusel_o <= EXE_RES_JUMP_BRANCH; 
						reg1_read_o <= '1';
						reg1_read_buf<='1';
						reg2_read_o <= '0';
						reg2_read_buf<='0';
		  				link_addr_o <= pc_plus_8; 
		  				wd_o <= "11111";  	
						instvalid <= InstValid;
		  				if(reg1_out_buff(31) = '0') then
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= Branch;
			    			next_inst_in_delayslot_o <= InDelaySlot;
			   		end if;
					when EXE_BLTZ=>
						wreg_o <= WriteDisable;		
						aluop_o <= EXE_BGEZAL_OP;
		  				alusel_o <= EXE_RES_JUMP_BRANCH; 
						reg1_read_o <= '1';	
						reg1_read_buf<='1';
						reg2_read_o <= '0';
						reg2_read_buf<='0';
		  				instvalid <= InstValid;	
		  				if(reg1_out_buff(31) = '1') then
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= Branch;
			    			next_inst_in_delayslot_o <= InDelaySlot;		  	
			   		end if;
					when EXE_BLTZAL=>
						wreg_o <= WriteEnable;		
						aluop_o <= EXE_BGEZAL_OP;
						alusel_o <= EXE_RES_JUMP_BRANCH; 
						reg1_read_o <= '1';	
						reg1_read_buf<='1';
						reg2_read_o <= '0';
						reg2_read_buf<='0';
						link_addr_o <= pc_plus_8;	
						wd_o <= "11111"; 
						instvalid <= InstValid;
						if(reg1_out_buff(31) = '1') then
							branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
							branch_flag_o <= Branch;
							next_inst_in_delayslot_o <= InDelaySlot;
						end if;
					WHEN OTHERS =>
				end case;--end op2						
			when EXE_SPECIAL2_INST=>
					case  op3  is
						when EXE_CLZ=>
							wreg_o <= WriteEnable;		
							aluop_o <= EXE_CLZ_OP;
							alusel_o <= EXE_RES_ARITHMETIC; 
							reg1_read_o <= '1';	
							reg1_read_buf<='1';
							reg2_read_o <= '0';	
							reg2_read_buf<='0';
							instvalid <= InstValid;	
						when EXE_CLO=>
							wreg_o <= WriteEnable;		
							aluop_o <= EXE_CLO_OP;
							alusel_o <= EXE_RES_ARITHMETIC; 
							reg1_read_o <= '1';	
							reg1_read_buf<='1';
							reg2_read_o <= '0';
							reg2_read_buf<='0';
							instvalid <= InstValid;	
						when EXE_MUL=>
							wreg_o <= WriteEnable;		
							aluop_o <= EXE_MUL_OP;
							alusel_o <= EXE_RES_MUL; 
							reg1_read_o <= '1';	
							reg1_read_buf<='1';
							reg2_read_o <= '1';
							reg2_read_buf<='1';
							instvalid <= InstValid;	  			
						when EXE_MADD=>
							wreg_o <= WriteDisable;		
							aluop_o <= EXE_MADD_OP;
							alusel_o <= EXE_RES_MUL; 
							reg1_read_o <= '1';	
							reg1_read_buf<='1';
							reg2_read_o <= '1';	
							reg2_read_buf<='1';
							instvalid <= InstValid;	
						when EXE_MADDU=>
							wreg_o <= WriteDisable;		
							aluop_o <= EXE_MADDU_OP;
							alusel_o <= EXE_RES_MUL; 
							reg1_read_o <= '1';	
							reg1_read_buf<='1';
							reg2_read_o <= '1';
							reg2_read_buf<='1';
							instvalid <= InstValid;	
						when EXE_MSUB=>
							wreg_o <= WriteDisable;		
							aluop_o <= EXE_MSUB_OP;
							alusel_o <= EXE_RES_MUL; 
							reg1_read_o <= '1';	
							reg1_read_buf<='1';
							reg2_read_o <= '1';
							reg2_read_buf<='1';
							instvalid <= InstValid;	
						when EXE_MSUBU=>
							wreg_o <= WriteDisable;		
							aluop_o <= EXE_MSUBU_OP;
							alusel_o <= EXE_RES_MUL; 
							reg1_read_o <= '1';	
							reg1_read_buf<='1';
							reg2_read_o <= '1';	
							reg2_read_buf<='1';
							instvalid <= InstValid;						
						WHEN OTHERS => 
					end case;     --EXE_SPECIAL_INST2 case																		  	
			WHEN OTHERS => 
		end case;		  --case op
		  
			if (inst_i(31 DOWNTO 21) = "00000000000") then
				if (op3 = EXE_SLL) then
					wreg_o <= WriteEnable;		
					aluop_o <= EXE_SLL_OP;
					alusel_o <= EXE_RES_SHIFT; 
					reg1_read_o <= '0';	
					reg1_read_buf<='0';
					reg2_read_o <= '1';
					reg2_read_buf<='1';
					imm(4 DOWNTO 0) <= inst_i(10 DOWNTO 6);		
					wd_o <= inst_i(15 DOWNTO 11);
					instvalid <= InstValid;	
				elsif ( op3 = EXE_SRL ) then
					wreg_o <= WriteEnable;		
					aluop_o <= EXE_SRL_OP;
					alusel_o <= EXE_RES_SHIFT; 
					reg1_read_o <= '0';	
					reg1_read_buf<='0';
					reg2_read_o <= '1';	
					reg2_read_buf<='1';
					imm(4 DOWNTO 0) <= inst_i(10 DOWNTO 6);		
					wd_o <= inst_i(15 DOWNTO 11);
					instvalid <= InstValid;	
				elsif ( op3 = EXE_SRA ) then
					wreg_o <= WriteEnable;		
					aluop_o <= EXE_SRA_OP;
					alusel_o <= EXE_RES_SHIFT; 
					reg1_read_o <= '0';	
					reg1_read_buf<='0';
					reg2_read_o <= '1';
					reg2_read_buf<='1';
					imm(4 DOWNTO 0) <= inst_i(10 DOWNTO 6);		
					wd_o <= inst_i(15 DOWNTO 11);
					instvalid <= InstValid;	
				else
				end if;
			else
			end if;		  
		end if;	
	end process;	
	--#############################################################
	--                        take Source operand 1(reg1_out)
	--#############################################################	
	process(rst,reg1_data_i,ex_wdata_i,mem_wdata_i,reg1_read_buf,ex_wreg_i,ex_wd_i,reg1_addr_buff,mem_wreg_i,mem_wd_i,imm,pre_inst_is_load,ex_aluop_i)
	begin
		if ((ex_aluop_i = EXE_LB_OP) or (ex_aluop_i = EXE_LBU_OP)or(ex_aluop_i = EXE_LH_OP) or(ex_aluop_i = EXE_LHU_OP)or(ex_aluop_i = EXE_LW_OP) or(ex_aluop_i = EXE_LWR_OP)or(ex_aluop_i = EXE_LWL_OP)or(ex_aluop_i = EXE_LL_OP)or(ex_aluop_i = EXE_SC_OP))then
			pre_inst_is_load<='1';
		else
			pre_inst_is_load<='0';
		end if;
		stallreq_for_reg1_loadrelate <= NoStop;
		if (rst = RstEnable) then
			reg1_out_buff<=ZeroWord;
			reg1_o<=ZeroWord;
		elsif((pre_inst_is_load = '1') AND (ex_wd_i = reg1_addr_buff) AND (reg1_read_buf = '1') ) then
			stallreq_for_reg1_loadrelate <= Stop;		
		elsif ((reg1_read_buf='1') AND (ex_wreg_i='1') AND (ex_wd_i=reg1_addr_buff)) then--To solve Data dependency
			reg1_out_buff<=ex_wdata_i;
			reg1_o<=ex_wdata_i;
		elsif ((reg1_read_buf='1') AND (mem_wreg_i='1') AND (mem_wd_i=reg1_addr_buff)) then--To solve Data dependency
			reg1_out_buff<=mem_wdata_i;
			reg1_o<=mem_wdata_i;
		elsif (reg1_read_buf='1') then --reg1read_out=1,Source operand 1的值是從register讀入的
			reg1_out_buff<=reg1_data_i;
			reg1_o<=reg1_data_i;
		elsif (reg1_read_buf='0') then--Source operand 1的值不是從register讀入的=>是imm
			reg1_out_buff<=imm;
			reg1_o<=imm;
		else
			reg1_out_buff<=ZeroWord;
			reg1_o<=ZeroWord;
		end if;
	end process;	
	--#############################################################
	--                        take Source operand 2(reg2_out)
	--#############################################################	
	process(rst,reg2_data_i,ex_wdata_i,mem_wdata_i,reg2_read_buf,ex_wreg_i,ex_wd_i,reg2_addr_buff,mem_wreg_i,mem_wd_i,imm,pre_inst_is_load,reg1_addr_buff)
	begin
		--if ((ex_aluop_i = EXE_LB_OP) or (ex_aluop_i = EXE_LBU_OP)or(ex_aluop_i = EXE_LH_OP) or(ex_aluop_i = EXE_LHU_OP)or(ex_aluop_i = EXE_LW_OP) or(ex_aluop_i = EXE_LWR_OP)or(ex_aluop_i = EXE_LWL_OP)or(ex_aluop_i = EXE_LL_OP)or(ex_aluop_i = EXE_SC_OP))then
		--	pre_inst_is_load<='1';
		--else
		--	pre_inst_is_load<='0';
		--end if;
		stallreq_for_reg2_loadrelate <= NoStop;
		if (rst = RstEnable) then
			reg2_out_buff<=ZeroWord;
			reg2_o<=ZeroWord;
		elsif((pre_inst_is_load = '1') AND (ex_wd_i = reg1_addr_buff) AND (reg2_read_buf = '1') ) then
			stallreq_for_reg2_loadrelate <= Stop;		
		elsif ((reg2_read_buf='1') AND (ex_wreg_i='1') AND (ex_wd_i=reg2_addr_buff)) then--To solve Data dependency
			reg2_out_buff<=ex_wdata_i;
			reg2_o<=ex_wdata_i;
		elsif ((reg2_read_buf='1') AND (mem_wreg_i='1') AND (mem_wd_i=reg2_addr_buff)) then--To solve Data dependency
			reg2_out_buff<=mem_wdata_i;
			reg2_o<=mem_wdata_i;
		elsif (reg2_read_buf='1') then --reg1read_out=1,Source operand 1的值是從register讀入的
			reg2_out_buff<=reg2_data_i;
			reg2_o<=reg2_data_i;
		elsif (reg2_read_buf='0') then--Source operand 1的值不是從register讀入的=>是imm
			reg2_out_buff<=imm;
			reg2_o<=imm;
		else
			reg2_out_buff<=ZeroWord;
			reg2_o<=ZeroWord;
		end if;
	end process;
	--如果上一條指令是轉移指令，那麼下一條指令在解碼的時候is_in_delayslot為true
	process(rst,is_in_delayslot_i)
	begin
		if(rst = RstEnable) then
			is_in_delayslot_o <= NotInDelaySlot;
		else
			is_in_delayslot_o <= is_in_delayslot_i;		
		end if;
	end process;
	
END behavior;
