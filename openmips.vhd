--entity:  openmips
--File:    openmips.vhd
--Description:Top of openmips
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;

entity openmips is
	PORT(
		clock: in std_logic;
		reset: in std_logic;
	
 
		rom_data_i: in STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		rom_addr_o: out STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		rom_ce_o: out std_logic;
		--view data
		cccounmips: OUT STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
		--connect data_ram
		ram_data_i: in STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ram_addr_o: out STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ram_data_o: out STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ram_we_o: out std_logic;
		ram_sel_o: out STD_LOGIC_VECTOR(3 DOWNTO 0);
		ram_ce_o: out std_logic      --diff
	);
end openmips;

architecture struct of openmips is
	COMPONENT pc_reg
	PORT( 
		rst:IN STD_LOGIC;
		clk:IN STD_LOGIC;
		
		stall:IN STD_LOGIC_VECTOR( 5 DOWNTO 0 );--Pause line control signal
		--clock cycle counter
		cccoun : OUT STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
		--from id
		branch_flag_i: IN STD_LOGIC;
		branch_target_address_i :IN STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
		pc:OUT STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
		ce:OUT STD_LOGIC
	);
	END COMPONENT;
	COMPONENT if_id
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		if_pc:IN STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
		if_inst:IN STD_LOGIC_VECTOR( InstBus-1 DOWNTO 0 );
		id_pc:OUT STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );		
		id_inst:OUT STD_LOGIC_VECTOR( InstBus-1 DOWNTO 0 );
		
		stall:IN STD_LOGIC_VECTOR( 5 DOWNTO 0 )--Pause line control signal 
	);
	END COMPONENT;
	COMPONENT id
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
	END COMPONENT;
	COMPONENT regfile
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		
		we:IN STD_LOGIC;
		waddr:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		wdata:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		
		re1:IN STD_LOGIC;
		raddr1:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		rdata1:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		
		re2:IN STD_LOGIC;
		raddr2:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		rdata2:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0)
	);
	END COMPONENT;
	COMPONENT id_ex
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--來自控制模組的資訊
		stall:IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		--從解碼階段傳遞的資訊
		id_aluop:IN STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		id_alusel:IN STD_LOGIC_VECTOR(AluSelBus-1 DOWNTO 0);
		id_reg1:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		id_reg2:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		id_wd:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		id_wreg:IN STD_LOGIC;
		id_link_address:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		id_is_in_delayslot:IN STD_LOGIC;
		next_inst_in_delayslot_i:IN STD_LOGIC;
		
		id_inst:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		--傳遞到執行階段的資訊
		ex_aluop:OUT STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		ex_alusel:OUT STD_LOGIC_VECTOR(AluSelBus-1 DOWNTO 0);
		ex_reg1:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_reg2:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_wd:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		ex_wreg:OUT STD_LOGIC;
		ex_link_address:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_is_in_delayslot:OUT STD_LOGIC;
		is_in_delayslot_o:OUT STD_LOGIC;
		ex_inst:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0)	
	);
	END COMPONENT;
	COMPONENT ex
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
	END COMPONENT;
	COMPONENT ex_mem
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--來自控制模組的資訊
		stall:IN STD_LOGIC_VECTOR(5 DOWNTO 0);	
		
		--來自執行階段的資訊	
		ex_wd:IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		ex_wreg:IN STD_LOGIC;
		ex_wdata:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0); 	
		ex_hi:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_lo:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_whilo:IN STD_LOGIC; 	

		--為實現載入、存取記憶體指令而添加
		ex_aluop:IN STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		ex_mem_addr:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		ex_reg2:IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

		hilo_i:IN STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);	
		cnt_i:IN STD_LOGIC_VECTOR(1 DOWNTO 0);	
		
		--送到存取記憶體階段的資訊
		mem_wd:OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		mem_wreg:OUT STD_LOGIC;
		mem_wdata:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_hi:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_lo:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_whilo:OUT STD_LOGIC;

		--為實現載入、存取記憶體指令而添加
		mem_aluop:OUT STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
		mem_mem_addr:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_reg2:OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
			
		hilo_o:OUT STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);
		cnt_o	:OUT STD_LOGIC_VECTOR(1 DOWNTO 0)		
		
	);
	END COMPONENT;
	COMPONENT mem
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
	END COMPONENT;
	COMPONENT mem_wb
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--來自控制模組的資訊
		stall:IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		--來自存取記憶體階段的資訊
		mem_wd: IN STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		mem_wreg: IN STD_LOGIC;
		mem_wdata: IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_hi: IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_lo: IN STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		mem_whilo: IN STD_LOGIC;
		
		mem_LLbit_we: IN STD_LOGIC;
		mem_LLbit_value: IN STD_LOGIC;
		--送到回寫階段的資訊
		wb_wd: OUT STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
		wb_wreg: OUT STD_LOGIC;
		wb_wdata: OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wb_hi: OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wb_lo: OUT STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
		wb_whilo: OUT STD_LOGIC;
		
		wb_LLbit_we: OUT STD_LOGIC;
		wb_LLbit_value: OUT STD_LOGIC
	);
	END COMPONENT;
	COMPONENT hilo_reg
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		--寫入連接埠
		we:IN STD_LOGIC;
		hi_i: IN STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
		lo_i: IN STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
		--讀取連接埠1
		hi_o: OUT STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 );
		lo_o: OUT STD_LOGIC_VECTOR( RegBus-1 DOWNTO 0 )
	);
	END COMPONENT;
	COMPONENT ctrl
	PORT( 
		rst:IN STD_LOGIC;
		stallreq_from_id:IN STD_LOGIC;
		--來自執行階段的暫停請求
		stallreq_from_ex:IN STD_LOGIC;
		stall:OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
	);
	END COMPONENT;
	COMPONENT div
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
	END COMPONENT;
	COMPONENT LLbit_reg
	PORT( 
		clk:IN STD_LOGIC;
		rst:IN STD_LOGIC;
		flush:IN STD_LOGIC;
		--寫入連接埠
		LLbit_i:IN STD_LOGIC;
		we:IN STD_LOGIC;
		--讀取連接埠1
		LLbit_o:OUT STD_LOGIC
	);
	END COMPONENT;
	SIGNAL pc: STD_LOGIC_VECTOR(InstAddrBus-1 DOWNTO 0);
	SIGNAL id_pc_i: STD_LOGIC_VECTOR(InstAddrBus-1 DOWNTO 0);
	SIGNAL id_inst_i: STD_LOGIC_VECTOR(InstBus-1 DOWNTO 0);
	--連接解碼階段ID模組的輸出與ID/EX模組的輸入
	SIGNAL id_aluop_o: STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
	SIGNAL id_alusel_o: STD_LOGIC_VECTOR(AluSelBus-1 DOWNTO 0);
	SIGNAL id_reg1_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL id_reg2_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL id_wreg_o: STD_LOGIC;
	SIGNAL id_wd_o: STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	SIGNAL id_is_in_delayslot_o: STD_LOGIC;
	SIGNAL id_link_address_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);	
	SIGNAL id_inst_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	
	--連接ID/EX模組的輸出與執行階段EX模組的輸入
	SIGNAL ex_aluop_i: STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
	SIGNAL ex_alusel_i: STD_LOGIC_VECTOR(AluSelBus-1 DOWNTO 0);
	SIGNAL ex_reg1_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL ex_reg2_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL ex_wreg_i: STD_LOGIC;
	SIGNAL ex_wd_i: STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	SIGNAL ex_is_in_delayslot_i: STD_LOGIC;	
	SIGNAL ex_link_address_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);	
	SIGNAL ex_inst_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	
	--連接執行階段EX模組的輸出與EX/MEM模組的輸入
	SIGNAL ex_wreg_o: STD_LOGIC;
	SIGNAL ex_wd_o: STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	SIGNAL ex_wdata_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL ex_hi_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL ex_lo_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL ex_whilo_o: STD_LOGIC;
	SIGNAL ex_aluop_o: STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
	SIGNAL ex_mem_addr_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL ex_reg1_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL ex_reg2_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);	

	--連接EX/MEM模組的輸出與存取記憶體階段MEM模組的輸入
	SIGNAL mem_wreg_i: STD_LOGIC;
	SIGNAL mem_wd_i: STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	SIGNAL mem_wdata_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_hi_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_lo_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_whilo_i: STD_LOGIC;		
	SIGNAL mem_aluop_i: STD_LOGIC_VECTOR(AluOpBus-1 DOWNTO 0);
	SIGNAL mem_mem_addr_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_reg1_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_reg2_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);		

	--連接存取記憶體階段MEM模組的輸出與MEM/WB模組的輸入
	SIGNAL mem_wreg_o: STD_LOGIC;
	SIGNAL mem_wd_o: STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	SIGNAL mem_wdata_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_hi_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_lo_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_whilo_o: STD_LOGIC;	
	SIGNAL mem_LLbit_value_o: STD_LOGIC;
	SIGNAL mem_LLbit_we_o: STD_LOGIC;		
	
	--連接MEM/WB模組的輸出與回寫階段的輸入	
	SIGNAL wb_wreg_i: STD_LOGIC;
	SIGNAL wb_wd_i: STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	SIGNAL wb_wdata_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL wb_hi_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL wb_lo_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL wb_whilo_i: STD_LOGIC;	
	SIGNAL wb_LLbit_value_i: STD_LOGIC;
	SIGNAL wb_LLbit_we_i: STD_LOGIC;	
	
	--連接解碼階段ID模組與通用暫存器Regfile模組
	SIGNAL reg1_read: STD_LOGIC;
	SIGNAL reg2_read: STD_LOGIC;
	SIGNAL reg1_data: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL reg2_data: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL reg1_addr: STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);
	SIGNAL reg2_addr: STD_LOGIC_VECTOR(RegAddrBus-1 DOWNTO 0);

	--連接執行階段與hilo模組的輸出，讀取HI、LO暫存器
	SIGNAL hi: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL lo: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

	--連接執行階段與ex_reg模組，用於多週期的MADD、MADDU、MSUB、MSUBU指令
	SIGNAL hilo_temp_o: STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);
	SIGNAL cnt_o: STD_LOGIC_VECTOR(1 DOWNTO 0);
	
	SIGNAL hilo_temp_i: STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);
	SIGNAL cnt_i: STD_LOGIC_VECTOR(1 DOWNTO 0);

	SIGNAL div_result: STD_LOGIC_VECTOR(DoubleRegBus-1 DOWNTO 0);
	SIGNAL div_ready: STD_LOGIC;
	SIGNAL div_opdata1: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL div_opdata2: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL div_start: STD_LOGIC;
	SIGNAL div_annul: STD_LOGIC;
	SIGNAL signed_div: STD_LOGIC;

	SIGNAL is_in_delayslot_i: STD_LOGIC;
	SIGNAL is_in_delayslot_o: STD_LOGIC;
	SIGNAL next_inst_in_delayslot_o: STD_LOGIC;
	SIGNAL id_branch_flag_o: STD_LOGIC;
	SIGNAL branch_target_address: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);

	SIGNAL stall: STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL stallreq_from_id: STD_LOGIC;	
	SIGNAL stallreq_from_ex: STD_LOGIC;

	SIGNAL LLbit_o: STD_LOGIC;	

begin
	--pc_reg實體化
	pc_reg0:pc_reg 
	PORT MAP(
		clk=>clock,
		rst=>reset,
		stall=>stall,
		cccoun=>cccounmips,
		branch_flag_i=>id_branch_flag_o,
		branch_target_address_i=>branch_target_address,		
		pc=>pc,
		ce=>rom_ce_o	
			
	);
	
  rom_addr_o <= pc;

  --IF/ID模組實體化
	if_id0:if_id 
	PORT MAP(
		clk=>clock,
		rst=>reset,
		stall=>stall,
		if_pc=>pc,
		if_inst=>rom_data_i,
		id_pc=>id_pc_i,
		id_inst=>id_inst_i      	
	);
	
	--解碼階段ID模組
	id0:id
	PORT MAP(
		rst=>reset,
		pc_i=>id_pc_i,
		inst_i=>id_inst_i,

  		ex_aluop_i=>ex_aluop_o,

		reg1_data_i=>reg1_data,
		reg2_data_i=>reg2_data,

	  --處於執行階段的指令要寫入的目的暫存器資訊
		ex_wreg_i=>ex_wreg_o,
		ex_wdata_i=>ex_wdata_o,
		ex_wd_i=>ex_wd_o,

	  --處於存取記憶體階段的指令要寫入的目的暫存器資訊
		mem_wreg_i=>mem_wreg_o,
		mem_wdata_i=>mem_wdata_o,
		mem_wd_i=>mem_wd_o,

	  	is_in_delayslot_i=>is_in_delayslot_i,

		--送到regfile的資訊
		reg1_read_o=>reg1_read,
		reg2_read_o=>reg2_read, 	  

		reg1_addr_o=>reg1_addr,
		reg2_addr_o=>reg2_addr, 
	  
		--送到ID/EX模組的資訊
		aluop_o=>id_aluop_o,
		alusel_o=>id_alusel_o,
		reg1_o=>id_reg1_o,
		reg2_o=>id_reg2_o,
		wd_o=>id_wd_o,
		wreg_o=>id_wreg_o,
		inst_o=>id_inst_o,

	 	next_inst_in_delayslot_o=>next_inst_in_delayslot_o,	
		branch_flag_o=>id_branch_flag_o,
		branch_target_address_o=>branch_target_address,       
		link_addr_o=>id_link_address_o,
		
		is_in_delayslot_o=>id_is_in_delayslot_o,
		
		stallreq=>stallreq_from_id		
	);

  --通用暫存器Regfile實體化
	regfile1:regfile
	PORT MAP(
		clk =>clock,
		rst =>reset,
		we	=>wb_wreg_i,
		waddr =>wb_wd_i,
		wdata =>wb_wdata_i,
		re1 =>reg1_read,
		raddr1 =>reg1_addr,
		rdata1 =>reg1_data,
		re2 =>reg2_read,
		raddr2 =>reg2_addr,
		rdata2 =>reg2_data
	);

	--ID/EX模組
	id_ex0:id_ex
	PORT MAP(
		clk=>clock,
		rst=>reset,
		
		stall=>stall,
		
		--從解碼階段ID模組傳遞的資訊
		id_aluop=>id_aluop_o,
		id_alusel=>id_alusel_o,
		id_reg1=>id_reg1_o,
		id_reg2=>id_reg2_o,
		id_wd=>id_wd_o,
		id_wreg=>id_wreg_o,
		id_link_address=>id_link_address_o,
		id_is_in_delayslot=>id_is_in_delayslot_o,
		next_inst_in_delayslot_i=>next_inst_in_delayslot_o,		
		id_inst=>id_inst_o,		
	
		--傳遞到執行階段EX模組的資訊
		ex_aluop=>ex_aluop_i,
		ex_alusel=>ex_alusel_i,
		ex_reg1=>ex_reg1_i,
		ex_reg2=>ex_reg2_i,
		ex_wd=>ex_wd_i,
		ex_wreg=>ex_wreg_i,
		ex_link_address=>ex_link_address_i,
  		ex_is_in_delayslot=>ex_is_in_delayslot_i,
		is_in_delayslot_o=>is_in_delayslot_i,
		ex_inst=>ex_inst_i		
	);		
	
	--EX模組
	ex0:ex
	PORT MAP(
		rst=>reset,
	
		--送到執行階段EX模組的資訊
		aluop_i=>ex_aluop_i,
		alusel_i=>ex_alusel_i,
		reg1_i=>ex_reg1_i,
		reg2_i=>ex_reg2_i,
		wd_i=>ex_wd_i,
		wreg_i=>ex_wreg_i,
		hi_i=>hi,
		lo_i=>lo,
		inst_i=>ex_inst_i,

	  	wb_hi_i=>wb_hi_i,
	  	wb_lo_i=>wb_lo_i,
	  	wb_whilo_i=>wb_whilo_i,
	  	mem_hi_i=>mem_hi_o,
	  	mem_lo_i=>mem_lo_o,
	  	mem_whilo_i=>mem_whilo_o,

	  	hilo_temp_i=>hilo_temp_i,
	  	cnt_i=>cnt_i,

		div_result_i=>div_result,
		div_ready_i=>div_ready, 

	  	link_address_i=>ex_link_address_i,
		is_in_delayslot_i=>ex_is_in_delayslot_i,	  
			  
	  --EX模組的輸出到EX/MEM模組資訊
		wd_o=>ex_wd_o,
		wreg_o=>ex_wreg_o,
		wdata_o=>ex_wdata_o,

		hi_o=>ex_hi_o,
		lo_o=>ex_lo_o,
		whilo_o=>ex_whilo_o,

		hilo_temp_o=>hilo_temp_o,
		cnt_o=>cnt_o,

		div_opdata1_o=>div_opdata1,
		div_opdata2_o=>div_opdata2,
		div_start_o=>div_start,
		signed_div_o=>signed_div,	

		aluop_o=>ex_aluop_o,
		mem_addr_o=>ex_mem_addr_o,
		reg2_o=>ex_reg2_o,
		
		stallreq=>stallreq_from_ex     				
		
	);

  --EX/MEM模組
  ex_mem0:ex_mem
  PORT MAP(
		clk=>clock,
		rst=>reset,
	  
	  	stall=>stall,
	  
		--來自執行階段EX模組的資訊	
		ex_wd=>ex_wd_o,
		ex_wreg=>ex_wreg_o,
		ex_wdata=>ex_wdata_o,
		ex_hi=>ex_hi_o,
		ex_lo=>ex_lo_o,
		ex_whilo=>ex_whilo_o,		

  		ex_aluop=>ex_aluop_o,
		ex_mem_addr=>ex_mem_addr_o,
		ex_reg2=>ex_reg2_o,			

		hilo_i=>hilo_temp_o,
		cnt_i=>cnt_o,	

		--送到存取記憶體階段MEM模組的資訊
		mem_wd=>mem_wd_i,
		mem_wreg=>mem_wreg_i,
		mem_wdata=>mem_wdata_i,
		mem_hi=>mem_hi_i,
		mem_lo=>mem_lo_i,
		mem_whilo=>mem_whilo_i,

  		mem_aluop=>mem_aluop_i,
		mem_mem_addr=>mem_mem_addr_i,
		mem_reg2=>mem_reg2_i,
				
		hilo_o=>hilo_temp_i,
		cnt_o=>cnt_i
						       	
	);
	
  --MEM模組實體化
	mem0:mem
	PORT MAP(
		rst=>reset,
	
		--來自EX/MEM模組的資訊	
		wd_i=>mem_wd_i,
		wreg_i=>mem_wreg_i,
		wdata_i=>mem_wdata_i,
		hi_i=>mem_hi_i,
		lo_i=>mem_lo_i,
		whilo_i=>mem_whilo_i,		

  		aluop_i=>mem_aluop_i,
		mem_addr_i=>mem_mem_addr_i,
		reg2_i=>mem_reg2_i,
	
		--來自memory的資訊
		mem_data_i=>ram_data_i,

		--LLbit_i是LLbit暫存器的值
		LLbit_i=>LLbit_o,
		--但不一定是最新值，回寫階段可能要寫入LLbit，所以還要進一步判斷
		wb_LLbit_we_i=>wb_LLbit_we_i,
		wb_LLbit_value_i=>wb_LLbit_value_i,

		LLbit_we_o=>mem_LLbit_we_o,
		LLbit_value_o=>mem_LLbit_value_o,
	  
		--送到MEM/WB模組的資訊
		wd_o=>mem_wd_o,
		wreg_o=>mem_wreg_o,
		wdata_o=>mem_wdata_o,
		hi_o=>mem_hi_o,
		lo_o=>mem_lo_o,
		whilo_o=>mem_whilo_o,
		
		--送到memory的資訊
		mem_addr_o=>ram_addr_o,
		mem_we_o=>ram_we_o,
		mem_sel_o=>ram_sel_o,
		mem_data_o=>ram_data_o,
		mem_ce_o=>ram_ce_o		
	);

  --MEM/WB模組
	mem_wb0:mem_wb
	PORT MAP(
		clk=>clock,
		rst=>reset,

    	stall=>stall,

		--來自存取記憶體階段MEM模組的資訊	
		mem_wd=>mem_wd_o,
		mem_wreg=>mem_wreg_o,
		mem_wdata=>mem_wdata_o,
		mem_hi=>mem_hi_o,
		mem_lo=>mem_lo_o,
		mem_whilo=>mem_whilo_o,		

		mem_LLbit_we=>mem_LLbit_we_o,
		mem_LLbit_value=>mem_LLbit_value_o,						
	
		--送到回寫階段的資訊
		wb_wd=>wb_wd_i,
		wb_wreg=>wb_wreg_i,
		wb_wdata=>wb_wdata_i,
		wb_hi=>wb_hi_i,
		wb_lo=>wb_lo_i,
		wb_whilo=>wb_whilo_i,

		wb_LLbit_we=>wb_LLbit_we_i,
		wb_LLbit_value=>wb_LLbit_value_i				
									       	
	);

	hilo_reg0:hilo_reg
	PORT MAP(
		clk=>clock,
		rst=>reset,
	
		--寫入連接埠
		we=>wb_whilo_i,
		hi_i=>wb_hi_i,
		lo_i=>wb_lo_i,
	
		--讀取連接埠1
		hi_o=>hi,
		lo_o=>lo	
	);
	
	ctrl0:ctrl
	PORT MAP(
		rst=>reset,
	
		stallreq_from_id=>stallreq_from_id,
	
  	--來自執行階段的暫停請求
		stallreq_from_ex=>stallreq_from_ex,

		stall=>stall       	
	);

	div0:div
	PORT MAP(
		clk=>clock,
		rst=>reset,
	
		signed_div_i=>signed_div,
		opdata1_i=>div_opdata1,
		opdata2_i=>div_opdata2,
		start_i=>div_start,
		annul_i=>'0',
	
		result_o=>div_result,
		ready_o=>div_ready
	);

	LLbit_reg0:LLbit_reg
	PORT MAP(
		clk=>clock,
		rst=>reset,
	  	flush=>'0',
	  
		--寫入連接埠
		LLbit_i=>wb_LLbit_value_i,
		we=>wb_LLbit_we_i,
	
		--讀取連接埠1
		LLbit_o=>LLbit_o
	
	);


end struct;