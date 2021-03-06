LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

--********
-- creates a reply for an incoming ARP request

entity trb_net16_gbe_protocol_ARP is
	generic(
		SIMULATE              : integer range 0 to 1 := 0;
		INCLUDE_DEBUG         : integer range 0 to 1 := 0;

		LATTICE_ECP3          : integer range 0 to 1 := 0;
		XILINX_SERIES7_ISE    : integer range 0 to 1 := 0;
		XILINX_SERIES7_VIVADO : integer range 0 to 1 := 0
	);
	port(
		CLK                    : in  std_logic; -- system clock
		RESET                  : in  std_logic;

		-- INTERFACE	
		MY_MAC_IN              : in  std_logic_vector(47 downto 0);
		MY_IP_IN               : in  std_logic_vector(31 downto 0);
		PS_DATA_IN             : in  std_logic_vector(8 downto 0);
		PS_WR_EN_IN            : in  std_logic;
		PS_ACTIVATE_IN         : in  std_logic;
		PS_RESPONSE_READY_OUT  : out std_logic;
		PS_BUSY_OUT            : out std_logic;
		PS_SELECTED_IN         : in  std_logic;
		PS_SRC_MAC_ADDRESS_IN  : in  std_logic_vector(47 downto 0);
		PS_DEST_MAC_ADDRESS_IN : in  std_logic_vector(47 downto 0);
		PS_SRC_IP_ADDRESS_IN   : in  std_logic_vector(31 downto 0);
		PS_DEST_IP_ADDRESS_IN  : in  std_logic_vector(31 downto 0);
		PS_SRC_UDP_PORT_IN     : in  std_logic_vector(15 downto 0);
		PS_DEST_UDP_PORT_IN    : in  std_logic_vector(15 downto 0);

		TC_RD_EN_IN            : in  std_logic;
		TC_DATA_OUT            : out std_logic_vector(8 downto 0);
		TC_FRAME_SIZE_OUT      : out std_logic_vector(15 downto 0);
		TC_FRAME_TYPE_OUT      : out std_logic_vector(15 downto 0);
		TC_IP_PROTOCOL_OUT     : out std_logic_vector(7 downto 0);
		TC_IDENT_OUT           : out std_logic_vector(15 downto 0);
		TC_DEST_MAC_OUT        : out std_logic_vector(47 downto 0);
		TC_DEST_IP_OUT         : out std_logic_vector(31 downto 0);
		TC_DEST_UDP_OUT        : out std_logic_vector(15 downto 0);
		TC_SRC_MAC_OUT         : out std_logic_vector(47 downto 0);
		TC_SRC_IP_OUT          : out std_logic_vector(31 downto 0);
		TC_SRC_UDP_OUT         : out std_logic_vector(15 downto 0);
		
		RECEIVED_FRAMES_OUT    : out std_logic_vector(15 downto 0);
		SENT_FRAMES_OUT        : out std_logic_vector(15 downto 0);
		-- END OF INTERFACE

		-- debug
		DEBUG_OUT              : out std_logic_vector(63 downto 0)
	);
end trb_net16_gbe_protocol_ARP;

architecture trb_net16_gbe_protocol_ARP of trb_net16_gbe_protocol_ARP is

	type dissect_states is (IDLE, READ_FRAME, DECIDE, LOAD_FRAME, WAIT_FOR_LOAD, CLEANUP);
	signal dissect_current_state, dissect_next_state : dissect_states;

	signal saved_opcode    : std_logic_vector(15 downto 0);
	signal saved_sender_ip : std_logic_vector(31 downto 0);
	signal saved_target_ip : std_logic_vector(31 downto 0);
	signal data_ctr        : integer range 0 to 30;
	signal values          : std_logic_vector(223 downto 0);
	signal tc_data         : std_logic_vector(8 downto 0);

	signal state          : std_logic_vector(3 downto 0);

begin
	values(15 downto 0)    <= x"0100";  -- hardware type
	values(31 downto 16)   <= x"0008";  -- protocol type
	values(39 downto 32)   <= x"06";    -- hardware size
	values(47 downto 40)   <= x"04";    -- protocol size
	values(63 downto 48)   <= x"0200";  --opcode (reply)
	values(111 downto 64)  <= MY_MAC_IN; -- sender (my) mac
	values(143 downto 112) <= MY_IP_IN;
	values(191 downto 144) <= PS_SRC_MAC_ADDRESS_IN; -- target mac
	values(223 downto 192) <= saved_sender_ip; -- target ip

	DISSECT_MACHINE_PROC : process(RESET, CLK)
	begin
		if (RESET = '1') then
			dissect_current_state <= IDLE;
		elsif rising_edge(CLK) then
			dissect_current_state <= dissect_next_state;
		end if;
	end process DISSECT_MACHINE_PROC;

	DISSECT_MACHINE : process(dissect_current_state, MY_IP_IN, PS_WR_EN_IN, PS_ACTIVATE_IN, PS_DATA_IN, data_ctr, PS_SELECTED_IN, saved_target_ip)
	begin
		case dissect_current_state is
			when IDLE =>
				state <= x"1";
				if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
					dissect_next_state <= READ_FRAME;
				else
					dissect_next_state <= IDLE;
				end if;

			when READ_FRAME =>
				state <= x"2";
				if (PS_DATA_IN(8) = '1') then
					dissect_next_state <= DECIDE;
				else
					dissect_next_state <= READ_FRAME;
				end if;

			when DECIDE =>
				state <= x"3";
				if (saved_target_ip = MY_IP_IN) then
					dissect_next_state <= WAIT_FOR_LOAD;
				-- in case the request is not for me, drop it
				else
					dissect_next_state <= IDLE;
				end if;

			when WAIT_FOR_LOAD =>
				state <= x"4";
				if (PS_SELECTED_IN = '1') then
					dissect_next_state <= LOAD_FRAME;
				else
					dissect_next_state <= WAIT_FOR_LOAD;
				end if;

			when LOAD_FRAME =>
				state <= x"5";
				if (data_ctr = 28) then
					dissect_next_state <= CLEANUP;
				else
					dissect_next_state <= LOAD_FRAME;
				end if;

			when CLEANUP =>
				state              <= x"e";
				dissect_next_state <= IDLE;

		end case;
	end process DISSECT_MACHINE;

	DATA_CTR_PROC : process(CLK)
	begin
		if rising_edge(CLK) then
			if (RESET = '1') or (dissect_current_state = IDLE and PS_WR_EN_IN = '0') then
				data_ctr <= 1;
			elsif (dissect_current_state = WAIT_FOR_LOAD) then
				data_ctr <= 1;
			elsif (dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
				data_ctr <= data_ctr + 1;
			elsif (dissect_current_state = READ_FRAME and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then -- in case of saving data from incoming frame
				data_ctr <= data_ctr + 1;
			elsif (dissect_current_state = LOAD_FRAME and PS_SELECTED_IN = '1' and TC_RD_EN_IN = '1') then -- in case of constructing response
				data_ctr <= data_ctr + 1;
			end if;
		end if;
	end process DATA_CTR_PROC;

	SAVE_VALUES_PROC : process(CLK)
	begin
		if rising_edge(CLK) then
			if (RESET = '1') then
				saved_opcode    <= (others => '0');
				saved_sender_ip <= (others => '0');
				saved_target_ip <= (others => '0');
			elsif (dissect_current_state = READ_FRAME) then
				case (data_ctr) is
					when 6 =>
						saved_opcode(7 downto 0) <= PS_DATA_IN(7 downto 0);
					when 7 =>
						saved_opcode(15 downto 8) <= PS_DATA_IN(7 downto 0);

					when 13 =>
						saved_sender_ip(7 downto 0) <= PS_DATA_IN(7 downto 0);
					when 14 =>
						saved_sender_ip(15 downto 8) <= PS_DATA_IN(7 downto 0);
					when 15 =>
						saved_sender_ip(23 downto 16) <= PS_DATA_IN(7 downto 0);
					when 16 =>
						saved_sender_ip(31 downto 24) <= PS_DATA_IN(7 downto 0);

					when 23 =>
						saved_target_ip(7 downto 0) <= PS_DATA_IN(7 downto 0);
					when 24 =>
						saved_target_ip(15 downto 8) <= PS_DATA_IN(7 downto 0);
					when 25 =>
						saved_target_ip(23 downto 16) <= PS_DATA_IN(7 downto 0);
					when 26 =>
						saved_target_ip(31 downto 24) <= PS_DATA_IN(7 downto 0);

					when others => null;
				end case;
			end if;
		end if;
	end process SAVE_VALUES_PROC;

	TC_DATA_PROC : process(CLK)
	begin
		if rising_edge(CLK) then
			tc_data(8) <= '0';

			if (dissect_current_state = LOAD_FRAME) then
				for i in 0 to 7 loop
					tc_data(i) <= values((data_ctr - 1) * 8 + i);
				end loop;
				-- mark the last byte
				if (data_ctr = 28) then
					tc_data(8) <= '1';
				end if;
			else
				tc_data(7 downto 0) <= (others => '0');
			end if;

			TC_DATA_OUT <= tc_data;

		end if;
	end process TC_DATA_PROC;

	PS_RESPONSE_SYNC : process(CLK)
	begin
		if rising_edge(CLK) then
			if (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = LOAD_FRAME or dissect_current_state = CLEANUP) then
				PS_RESPONSE_READY_OUT <= '1';
			else
				PS_RESPONSE_READY_OUT <= '0';
			end if;

			if (dissect_current_state = IDLE) then
				PS_BUSY_OUT <= '0';
			else
				PS_BUSY_OUT <= '1';
			end if;
		end if;
	end process PS_RESPONSE_SYNC;

	TC_FRAME_SIZE_OUT <= x"001c";       -- fixed frame size

	TC_FRAME_TYPE_OUT  <= x"0608";
	TC_DEST_MAC_OUT    <= PS_SRC_MAC_ADDRESS_IN;
	TC_DEST_IP_OUT     <= x"00000000";  -- doesnt matter
	TC_DEST_UDP_OUT    <= x"0000";      -- doesnt matter
	TC_SRC_MAC_OUT     <= MY_MAC_IN;
	TC_SRC_IP_OUT      <= x"00000000";  -- doesnt matter
	TC_SRC_UDP_OUT     <= x"0000";      -- doesnt matter
	TC_IP_PROTOCOL_OUT <= x"00";        -- doesnt matter
	TC_IDENT_OUT       <= (others => '0'); -- doesn't matter

end trb_net16_gbe_protocol_ARP;


