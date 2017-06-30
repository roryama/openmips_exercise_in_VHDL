--entity:  openmips_min_sopc
--File:    openmips_min_sopc.vhd
--Description:基於OpenMIPS處理器的一個簡單SOPC，用於驗證具備了
--              wishbone匯流排介面的openmips，該SOPC包含openmips、
--              wb_conmax、GPIO controller、flash controller，uart 
--              controller，以及用來模擬flash的模組flashmem，在其中
--              儲存指令，用來模擬外部ram的模組datamem，在其中儲存
--              資料，並且具有wishbone匯流排介面  
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.defines.all;
entity openmips_min_sopc is
	port (
			rst : in std_logic; 
			clk :in std_logic;
			--view data
			cccounsopc: OUT STD_LOGIC_VECTOR( InstAddrBus-1 DOWNTO 0 );
			HEX0: OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX1: OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX2: OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX3: OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX4: OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX5: OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX6: OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX7: OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 )
		  );
end openmips_min_sopc;

architecture struct of openmips_min_sopc is
	COMPONENT openmips
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
		ram_ce_o: out std_logic      --def
	);
	END COMPONENT;
	COMPONENT inst_rom
	PORT(
		ce: in std_logic;
		addr: in STD_LOGIC_VECTOR(InstAddrBus-1 DOWNTO 0);
		inst: out STD_LOGIC_VECTOR(InstBus-1 DOWNTO 0)
	);
	END COMPONENT;
	COMPONENT data_ram
	PORT(
		clock: in std_logic;
		ce: in std_logic;
		we: in std_logic;
		addr: in STD_LOGIC_VECTOR(DataAddrBus-1 DOWNTO 0);
		sel : in STD_LOGIC_VECTOR(3 DOWNTO 0);
		data_i : in STD_LOGIC_VECTOR(DataBus-1 DOWNTO 0);
		data_o : out  STD_LOGIC_VECTOR(DataBus-1 DOWNTO 0);
		--view data
		data_mem00:OUT STD_LOGIC_VECTOR(DataBus-1 DOWNTO 0)
	);
	END COMPONENT;
	COMPONENT hex_7seg
	PORT( 
		hex_digit:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		seg:OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
	END COMPONENT;
	--connect to inst_rom
	SIGNAL inst_addr: STD_LOGIC_VECTOR(InstAddrBus-1 DOWNTO 0);
	SIGNAL inst: STD_LOGIC_VECTOR(InstBus-1 DOWNTO 0);
	SIGNAL rom_ce: STD_LOGIC;
	SIGNAL mem_we_i: STD_LOGIC;
	SIGNAL mem_addr_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_data_i: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_data_o: STD_LOGIC_VECTOR(RegBus-1 DOWNTO 0);
	SIGNAL mem_sel_i: STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL mem_ce_i: STD_LOGIC;		
	SIGNAL view_data_mem: STD_LOGIC_VECTOR(DataBus-1 DOWNTO 0);
begin
	openmips0:openmips
	PORT MAP (		
		clock=> clk,
		reset=> rst,
	
		rom_addr_o=> inst_addr,
		rom_data_i=> inst,
		rom_ce_o=> rom_ce,

		cccounmips=>cccounsopc,
		
		ram_we_o=> mem_we_i,
		ram_addr_o=> mem_addr_i,
		ram_sel_o=> mem_sel_i,
		ram_data_o=> mem_data_i,
		ram_data_i=> mem_data_o,
		ram_ce_o=> mem_ce_i	
	);
	inst_rom0:inst_rom
	PORT MAP (
		ce => rom_ce,
		addr=>inst_addr,
		inst=>inst
	);
	data_ram0:data_ram
	PORT MAP (
		clock=>clk,
		ce=>mem_ce_i,
		we=>mem_we_i,
		addr=>mem_addr_i,
		sel=>mem_sel_i,
		data_i=>mem_data_i,
		data_o=>mem_data_o,
	
		data_mem00=>view_data_mem
	);
	dsp0:hex_7seg
	PORT MAP (
		hex_digit=>view_data_mem(3 DOWNTO 0),
		seg=>HEX0
	);	
	dsp1:hex_7seg
	PORT MAP (
		hex_digit=>view_data_mem(7 DOWNTO 4),
		seg=>HEX1
	);	
	dsp2:hex_7seg
	PORT MAP (
		hex_digit=>view_data_mem(11 DOWNTO 8),
		seg=>HEX2
	);	
	dsp3:hex_7seg
	PORT MAP (
		hex_digit=>view_data_mem(15 DOWNTO 12),
		seg=>HEX3
	);	
	dsp4:hex_7seg
	PORT MAP (
		hex_digit=>view_data_mem(19 DOWNTO 16),
		seg=>HEX4
	);	
	dsp5:hex_7seg
	PORT MAP (
		hex_digit=>view_data_mem(23 DOWNTO 20),
		seg=>HEX5
	);	
	dsp6:hex_7seg
	PORT MAP (
		hex_digit=>view_data_mem(27 DOWNTO 24),
		seg=>HEX6
	);	
	dsp7:hex_7seg
	PORT MAP (
		hex_digit=>view_data_mem(31 DOWNTO 28),
		seg=>HEX7
	);	
end struct;