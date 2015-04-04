library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity main_control_testbench is
end main_control_testbench;

architecture Behavioral of main_control_testbench is
	signal rx_clk                            : std_logic;
	signal reset                             : std_logic;
	signal client_rxd1                       : std_logic_vector(7 downto 0);
	signal client_rx_dv1, client_good_frame1 : std_logic;

	signal rc_src_mac                 : std_logic_vector(47 downto 0);
	signal rc_dest_mac                : std_logic_vector(47 downto 0);
	signal rc_src_ip                  : std_logic_vector(31 downto 0);
	signal rc_dest_ip                 : std_logic_vector(31 downto 0);
	signal rc_src_udp                 : std_logic_vector(15 downto 0);
	signal rc_dest_udp                : std_logic_vector(15 downto 0);
	signal rc_id_ip                   : std_logic_vector(15 downto 0);
	signal rc_fo_ip                   : std_logic_vector(15 downto 0);
	signal rc_rd_en                   : std_logic;
	signal rc_q                       : std_logic_vector(8 downto 0);
	signal rc_loading_done            : std_logic;
	signal rc_frame_proto             : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	signal rc_frame_ready             : std_logic;
	signal rc_frame_size, rc_checksum : std_logic_vector(15 downto 0);
	signal my_mac                     : std_logic_vector(47 downto 0);
	signal sys_clk                    : std_logic;

begin
	frame_rx_i : entity work.frame_rx
		generic map(
			SIMULATE              => 1,
			INCLUDE_DEBUG         => 1,
			LATTICE_ECP3          => 0,
			XILINX_SERIES7_ISE    => 1,
			XILINX_SERIES7_VIVADO => 0
		)
		port map(
			RESET                   => RESET,
			SYS_CLK                 => rx_clk,
			MY_MAC_IN               => my_mac,
			MAC_RX_CLK_IN           => rx_clk,
			MAC_RXD_IN              => client_rxd1,
			MAC_RX_DV_IN            => client_rx_dv1,
			MAC_RX_EOF_IN           => client_good_frame1,
			RC_RD_EN_IN             => rc_rd_en,
			RC_Q_OUT                => rc_q,
			RC_FRAME_WAITING_OUT    => rc_frame_ready,
			RC_LOADING_DONE_IN      => rc_loading_done,
			RC_FRAME_SIZE_OUT       => rc_frame_size,
			RC_FRAME_PROTO_OUT      => rc_frame_proto,
			RC_SRC_MAC_ADDRESS_OUT  => rc_src_mac,
			RC_DEST_MAC_ADDRESS_OUT => rc_dest_mac,
			RC_SRC_IP_ADDRESS_OUT   => rc_src_ip,
			RC_DEST_IP_ADDRESS_OUT  => rc_dest_ip,
			RC_SRC_UDP_PORT_OUT     => rc_src_udp,
			RC_DEST_UDP_PORT_OUT    => rc_dest_udp,
			RC_ID_IP_OUT            => rc_id_ip,
			RC_FO_IP_OUT            => rc_fo_ip,
			RC_REDIRECT_TRAFFIC_IN  => '0',
			RC_CHECKSUM_OUT         => rc_checksum,
			DEBUG_OUT               => open
		);

	UUT : entity work.trb_net16_gbe_main_control
		generic map(
			SIMULATE              => 1,
			INCLUDE_DEBUG         => 1,
			LATTICE_ECP3          => 0,
			XILINX_SERIES7_ISE    => 1,
			XILINX_SERIES7_VIVADO => 0,
			RX_PATH_ENABLE        => 1,
			INCLUDE_READOUT       => '0',
			INCLUDE_SLOWCTRL      => '0',
			INCLUDE_DHCP          => '1',
			INCLUDE_ARP           => '1',
			INCLUDE_PING          => '1',
			READOUT_BUFFER_SIZE   => 1,
			SLOWCTRL_BUFFER_SIZE  => 1
		)
		port map(
			CLK                    => rx_clk,
			CLK_125                => rx_clk,
			RESET                  => RESET,
			MC_RESET_LINK_IN       => RESET,
			RC_FRAME_WAITING_IN    => rc_frame_ready,
			RC_LOADING_DONE_OUT    => rc_loading_done,
			RC_DATA_IN             => rc_q,
			RC_RD_EN_OUT           => rc_rd_en,
			RC_FRAME_SIZE_IN       => rc_frame_size,
			RC_FRAME_PROTO_IN      => rc_frame_proto,
			RC_SRC_MAC_ADDRESS_IN  => rc_src_mac,
			RC_DEST_MAC_ADDRESS_IN => rc_dest_mac,
			RC_SRC_IP_ADDRESS_IN   => rc_src_ip,
			RC_DEST_IP_ADDRESS_IN  => rc_dest_ip,
			RC_SRC_UDP_PORT_IN     => rc_src_udp,
			RC_DEST_UDP_PORT_IN    => rc_dest_udp,
			RC_ID_IP_IN            => rc_id_ip,
			RC_FO_IP_IN            => rc_fo_ip,
			RC_CHECKSUM_IN         => rc_checksum,
			TC_TRANSMIT_CTRL_OUT   => open,
			TC_DATA_OUT            => open,
			TC_RD_EN_IN            => '1',
			TC_FRAME_SIZE_OUT      => open,
			TC_FRAME_TYPE_OUT      => open,
			TC_DEST_MAC_OUT        => open,
			TC_DEST_IP_OUT         => open,
			TC_DEST_UDP_OUT        => open,
			TC_SRC_MAC_OUT         => open,
			TC_SRC_IP_OUT          => open,
			TC_SRC_UDP_OUT         => open,
			TC_IP_PROTOCOL_OUT     => open,
			TC_IDENT_OUT           => open,
			TC_CHECKSUM_OUT        => open,
			TC_TRANSMIT_DONE_IN    => '1',
			PCS_AN_COMPLETE_IN     => '1',
			MC_MY_MAC_IN           => x"1111efbe0000",
			MC_MY_MAC_OUT          => my_mac,
			MAC_READY_CONF_IN      => '1',
			MC_UNIQUE_ID_IN        => (others => '1'),
			DEBUG_OUT              => open
		);
	process
	begin
		rx_clk <= '1';
		wait for 4 ns;
		rx_clk <= '0';
		wait for 4 ns;
	end process;

	process
	begin
		sys_clk <= '1';
		wait for 5 ns;
		sys_clk <= '0';
		wait for 5 ns;
	end process;

	testbench_process : process
	begin
		reset              <= '1';
		client_rx_dv1      <= '0';
		client_rxd1        <= x"00";
		client_good_frame1 <= '0';
		wait for 100 ns;
		reset <= '0';
		wait for 100 ns;

		wait for 1 us;

		wait until rising_edge(rx_clk);
		client_rx_dv1 <= '1';
		-- dest mac
		client_rxd1   <= x"ff";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ff";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ff";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ff";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ff";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ff";
		wait until rising_edge(rx_clk);
		-- src mac
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"aa";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"bb";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"cc";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"dd";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ee";
		wait until rising_edge(rx_clk);
		-- frame type
		client_rxd1 <= x"08";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		-- ip headers
		client_rxd1 <= x"45";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"10";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"01";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"5a";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"49";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ff";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"01";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"cc";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"cc";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"c0";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"a8";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"01";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"c0";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"a8";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"02";
		-- ping headers
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"08";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"47";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"d3";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"0d";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"3c";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"01";
		wait until rising_edge(rx_clk);
		-- ping data
		client_rxd1 <= x"8c";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"da";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"e7";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"4d";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"36";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"c4";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"0d";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"08";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"09";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"0a";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"0b";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"0c";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"0d";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"0e";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"0f";
		wait until rising_edge(rx_clk);
		client_good_frame1 <= '1';
		client_rxd1        <= x"aa";

		wait until rising_edge(rx_clk);
		client_rx_dv1      <= '0';
		client_good_frame1 <= '0';

		--		wait until rising_edge(rx_clk);
		--		client_rx_dv1 <= '1';
		--		-- dest mac
		--		client_rxd1   <= x"ff";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ff";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ff";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ff";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ff";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ff";
		--		wait until rising_edge(rx_clk);
		--		-- src mac
		--		client_rxd1 <= x"00";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"aa";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"bb";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"cc";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"dd";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ee";
		--		wait until rising_edge(rx_clk);
		--		-- frame type
		--		client_rxd1 <= x"08";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"00";
		--		wait until rising_edge(rx_clk);
		--		-- ip headers
		--		client_rxd1 <= x"45";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"10";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"01";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"5a";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"01";           -- id
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"03";           -- id
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"00";           -- f/o
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"00";           -- f/o
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ff";           -- ttl
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"11";           -- udp
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"cc";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"cc";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"c0";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"a8";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"00";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"01";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"c0";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"a8";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"00";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"02";
		--		-- udp headers
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"61";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"a8";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"61";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"a8";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"02";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"2c";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"aa";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"bb";
		--		-- payload
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ab";
		--
		--		for i in 1 to 100 loop
		--			wait until rising_edge(rx_clk);
		--			client_rxd1 <= std_logic_vector(to_unsigned(i, 8));
		--		end loop;
		--
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"cd";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"ef";
		--		wait until rising_edge(rx_clk);
		--		client_rxd1 <= x"aa";
		--		wait until rising_edge(rx_clk);
		--		client_good_frame1 <= '1';
		--
		--		wait until rising_edge(rx_clk);
		--		client_rx_dv1      <= '0';
		--		client_good_frame1 <= '0';

		wait;

	end process testbench_process;

end Behavioral;
