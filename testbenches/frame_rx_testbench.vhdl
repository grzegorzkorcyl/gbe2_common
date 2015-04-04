library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity frame_rx_testbench is
end frame_rx_testbench;

architecture Behavioral of frame_rx_testbench is
	signal rx_clk, sys_clk                   : std_logic;
	signal reset                             : std_logic;
	signal client_rxd1                       : std_logic_vector(7 downto 0);
	signal client_rx_dv1, client_good_frame1 : std_logic;

begin
	UUT : entity work.frame_rx
		generic map(
			SIMULATE              => 1,
			INCLUDE_DEBUG         => 1,
			LATTICE_ECP3          => 0,
			XILINX_SERIES7_ISE    => 1,
			XILINX_SERIES7_VIVADO => 0
		)
		port map(
			RESET                   => RESET,
			SYS_CLK                 => sys_clk,
			MY_MAC_IN               => x"1111efbe0000",
			MAC_RX_CLK_IN           => rx_clk,
			MAC_RXD_IN              => client_rxd1,
			MAC_RX_DV_IN            => client_rx_dv1,
			MAC_RX_EOF_IN           => client_good_frame1,
			RC_RD_EN_IN             => '0',
			RC_Q_OUT                => open,
			RC_FRAME_WAITING_OUT    => open,
			RC_LOADING_DONE_IN      => '0',
			RC_FRAME_SIZE_OUT       => open,
			RC_FRAME_PROTO_OUT      => open,
			RC_SRC_MAC_ADDRESS_OUT  => open,
			RC_DEST_MAC_ADDRESS_OUT => open,
			RC_SRC_IP_ADDRESS_OUT   => open,
			RC_DEST_IP_ADDRESS_OUT  => open,
			RC_SRC_UDP_PORT_OUT     => open,
			RC_DEST_UDP_PORT_OUT    => open,
			RC_ID_IP_OUT            => open,
			RC_FO_IP_OUT            => open,
			RC_REDIRECT_TRAFFIC_IN  => '0',
			RC_CHECKSUM_OUT         => open,
			DEBUG_OUT               => open
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
		client_rxd1 <= x"01";           -- id
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"03";           -- id
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";           -- f/o
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"00";           -- f/o
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ff";           -- ttl
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"11";           -- udp
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
		-- udp headers
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"61";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"a8";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"61";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"a8";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"02";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"2c";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"aa";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"bb";
		-- payload
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ab";

		for i in 1 to 100 loop
			wait until rising_edge(rx_clk);
			client_rxd1 <= std_logic_vector(to_unsigned(i, 8));
		end loop;

		wait until rising_edge(rx_clk);
		client_rxd1 <= x"cd";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"ef";
		wait until rising_edge(rx_clk);
		client_rxd1 <= x"aa";
		wait until rising_edge(rx_clk);
		client_good_frame1 <= '1';

		wait until rising_edge(rx_clk);
		client_rx_dv1      <= '0';
		client_good_frame1 <= '0';

		wait;

	end process testbench_process;

end Behavioral;
