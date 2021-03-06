library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity gbe_gmii_wrapper is
	generic(
		SIMULATE              : integer range 0 to 1 := 0;
		INCLUDE_DEBUG         : integer range 0 to 1 := 0;

		LATTICE_ECP3          : integer range 0 to 1 := 0;
		XILINX_SERIES7_ISE    : integer range 0 to 1 := 0;
		XILINX_SERIES7_VIVADO : integer range 0 to 1 := 0;

		INCLUDE_OPENCORES_MAC : integer range 0 to 1 := 0
	);
	port(
		SYS_CLK        : in  std_logic;
		RESET_IN       : in  std_logic;
		GBE_CLK_DV     : in  std_logic;
		GBE_RX_CLK     : in  std_logic;
		GBE_TX_CLK     : out std_logic;

		RX_DATA_IN     : in  std_logic_vector(7 downto 0);
		RX_DATA_DV_IN  : in  std_logic;
		RX_DATA_ER_IN  : in  std_logic;

		TX_DATA_OUT    : out std_logic_vector(7 downto 0);
		TX_DATA_DV_OUT : out std_logic;
		TX_DATA_ER_OUT : out std_logic;

		DEBUG_OUT      : out std_logic_vector(255 downto 0)
	);
end gbe_gmii_wrapper;

architecture Behavioral of gbe_gmii_wrapper is
	signal rx_data, tx_data                                        : std_logic_vector(7 downto 0);
	signal rx_dv, rx_gf, rx_bf, tx_dv, tx_fb, tx_ack, tx_done      : std_logic;
	signal mac_rx_ra, mac_rx_sop, mac_rx_eop, mac_rx_pa, mac_rx_rd : std_logic;
	signal mac_rx_data, mac_tx_data                                : std_logic_vector(31 downto 0);
	signal mac_rx_be, mac_tx_be                                    : std_logic_vector(1 downto 0);
	signal mac_tx_sop, mac_tx_eop, mac_tx_wr, mac_tx_wa            : std_logic;
	signal tx_clk                                                  : std_logic;

begin
	gbe_i : entity work.gbe_module_wrapper
		generic map(
			SIMULATE              => SIMULATE,
			INCLUDE_DEBUG         => INCLUDE_DEBUG,
			LATTICE_ECP3          => LATTICE_ECP3,
			XILINX_SERIES7_ISE    => XILINX_SERIES7_ISE,
			XILINX_SERIES7_VIVADO => XILINX_SERIES7_VIVADO
		)
		port map(
			SYS_CLK         => SYS_CLK,
			RESET_IN        => RESET_IN,
			GBE_RX_CLK      => tx_clk,
			GBE_TX_CLK      => tx_clk,
			RX_DATA_IN      => rx_data,
			RX_DATA_DV_IN   => rx_dv,
			RX_DATA_GF_IN   => rx_gf,
			RX_DATA_BF_IN   => rx_bf,
			TX_DATA_OUT     => tx_data,
			TX_DATA_DV_OUT  => tx_dv,
			TX_DATA_FB_OUT  => tx_fb,
			TX_DATA_ACK_IN  => tx_ack,
			TX_DATA_DONE_IN => tx_done,
			DEBUG_OUT       => open
		);

	OPENCORES_MAC_GEN : if INCLUDE_OPENCORES_MAC = 1 generate
		gbe_mac_bridge_i : entity work.gbe_to_mac_bridge
			generic map(
				SIMULATE              => SIMULATE,
				INCLUDE_DEBUG         => INCLUDE_DEBUG,
				LATTICE_ECP3          => LATTICE_ECP3,
				XILINX_SERIES7_ISE    => XILINX_SERIES7_ISE,
				XILINX_SERIES7_VIVADO => XILINX_SERIES7_VIVADO
			)
			port map(
				MAC_CLK_IN               => GBE_CLK_DV,
				GBE_CLK_IN               => tx_clk,
				RESET_IN                 => RESET_IN,
				MAC_TX_WA_IN             => mac_tx_wa,
				MAC_TX_WR_OUT            => mac_tx_wr,
				MAC_TX_DATA_OUT          => mac_tx_data,
				MAC_TX_BE_OUT            => mac_tx_be,
				MAC_TX_SOP_OUT           => mac_tx_sop,
				MAC_TX_EOP_OUT           => mac_tx_eop,
				GBE_TX_DATA_IN           => tx_data,
				GBE_TX_DV_IN             => tx_dv,
				GBE_TX_FB_IN             => tx_fb,
				GBE_TX_ACK_OUT           => tx_ack,
				GBE_DATA_STATS_VALID_OUT => tx_done,
				DEBUG_OUT                => open
			);

		mac_gbe_bridge_i : entity work.mac_to_gbe_bridge
			generic map(
				SIMULATE              => SIMULATE,
				INCLUDE_DEBUG         => INCLUDE_DEBUG,
				LATTICE_ECP3          => LATTICE_ECP3,
				XILINX_SERIES7_ISE    => XILINX_SERIES7_ISE,
				XILINX_SERIES7_VIVADO => XILINX_SERIES7_VIVADO
			)
			port map(
				MAC_CLK_IN      => GBE_CLK_DV,
				GBE_CLK_IN      => tx_clk,
				RESET_IN        => RESET_IN,
				MAC_RX_RA_IN    => mac_rx_ra,
				MAC_RX_RD_OUT   => mac_rx_rd,
				MAC_RX_DATA_IN  => mac_rx_data,
				MAC_RX_BE_IN    => mac_rx_be,
				MAC_RX_PA_IN    => mac_rx_pa,
				MAC_RX_SOP_IN   => mac_rx_sop,
				MAC_RX_EOP_IN   => mac_rx_eop,
				GBE_RX_DATA_OUT => rx_data,
				GBE_RX_DV_OUT   => rx_dv,
				GBE_RX_GF_OUT   => rx_gf,
				GBE_RX_BF_OUT   => open,
				DEBUG_OUT       => open
			);

		mac_i : entity work.MAC_top
			port map(
				--system signals
				Reset              => RESET_IN,
				Clk_125M           => GBE_RX_CLK,
				Clk_user           => GBE_CLK_DV,
				Clk_reg            => GBE_CLK_DV,
				Speed              => open,
				--user interface 
				Rx_mac_ra          => mac_rx_ra,
				Rx_mac_rd          => mac_rx_rd,
				Rx_mac_data        => mac_rx_data,
				Rx_mac_BE          => mac_rx_be,
				Rx_mac_pa          => mac_rx_pa,
				Rx_mac_sop         => mac_rx_sop,
				Rx_mac_eop         => mac_rx_eop,
				--user interface 
				Tx_mac_wa          => mac_tx_wa,
				Tx_mac_wr          => mac_tx_wr,
				Tx_mac_data        => mac_tx_data,
				Tx_mac_BE          => mac_tx_be,
				Tx_mac_sop         => mac_tx_sop,
				Tx_mac_eop         => mac_tx_eop,
				--pkg_lgth fifo
				Pkg_lgth_fifo_rd   => '1',
				Pkg_lgth_fifo_ra   => open,
				Pkg_lgth_fifo_data => open,
				--Phy interface         
				Gtx_clk            => tx_clk,
				Rx_clk             => GBE_RX_CLK,
				Tx_clk             => '0',
				Tx_er              => TX_DATA_ER_OUT,
				Tx_en              => TX_DATA_DV_OUT,
				Txd                => TX_DATA_OUT,
				Rx_er              => RX_DATA_ER_IN,
				Rx_dv              => RX_DATA_DV_IN,
				Rxd                => RX_DATA_IN,
				Crs                => '0',
				Col                => '0',
				--host interface
				CSB                => '1',
				WRB                => '1',
				CD_in              => x"0000",
				CD_out             => open,
				CA                 => x"00",
				--mdx
				Mdo                => open,
				MdoEn              => open,
				Mdi                => '0',
				Mdc                => open
			);

		GBE_TX_CLK <= tx_clk;

	end generate OPENCORES_MAC_GEN;

end Behavioral;