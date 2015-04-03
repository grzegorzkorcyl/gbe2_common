library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_512x72_generic_wrapper is
	generic(
		SIMULATE              : integer range 0 to 1 := 0;
		INCLUDE_DEBUG         : integer range 0 to 1 := 0;

		LATTICE_ECP3          : integer range 0 to 1 := 0;
		XILINX_SERIES7_ISE    : integer range 0 to 1 := 0;
		XILINX_SERIES7_VIVADO : integer range 0 to 1 := 0
	);
	port(
		WR_CLK_IN : in  std_logic;
		RD_CLK_IN : in  std_logic;
		RESET_IN  : in  std_logic;

		DATA_IN   : in  std_logic_vector(8 downto 0);
		WR_EN_IN  : in  std_logic;

		DATA_OUT  : out std_logic_vector(8 downto 0);
		RD_EN_IN  : in  std_logic;

		FULL_OUT  : out std_logic;
		EMPTY_OUT : out std_logic;

		DEBUG_OUT : out std_logic_vector(255 downto 0)
	);
end entity fifo_512x72_generic_wrapper;

architecture RTL of fifo_512x72_generic_wrapper is
begin
	LATTICE_ECP3_gen : if LATTICE_ECP3 = 1 generate
		receive_fifo : fifo_512x72
			port map(
				Data    => DATA_IN,
				WrClock => WR_CLK_IN,
				RdClock => RD_CLK_IN,
				WrEn    => WR_EN_IN,
				RdEn    => RD_EN_IN,
				Reset   => RESET_IN,
				RPReset => RESET_IN,
				Q       => DATA_OUT,
				Empty   => EMPTY_OUT,
				Full    => FULL_OUT
			);
	end generate LATTICE_ECP3_gen;

	XILINX_SERIES7_ISE_gen : if XILINX_SERIES7_ISE = 1 generate
		receive_fifo : fifo_512x72
			port map(
				din    => DATA_IN,
				wr_clk => WR_CLK_IN,
				rd_clk => RD_CLK_IN,
				wr_en  => WR_EN_IN,
				rd_en  => RD_EN_IN,
				rst    => RESET_IN,
				dout   => DATA_OUT,
				empty  => EMPTY_OUT,
				full   => FULL_OUT
			);
	end generate XILINX_SERIES7_ISE_gen;

end architecture RTL;