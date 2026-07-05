--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    05/31/2016 
-- Design Name:    mu2e_amc502
-- Module Name:    gbe_interface - RTL
-- Project Name:   Mu2e
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Gigabit ethernet slave
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hep337dev;
use hep337dev.iobus.all;
use hep337dev.xaui.all;

entity xaui_interface is
generic (
    mac_address : string := "00:00:00:00:00:00";
    ip_address : string := "192.168.42.253";
    netmask : string := "255.255.255.0";
    gateway : string := "192.168.40.1";
    jumpers : boolean := false;
    nstream : integer := 1;
    dhcp : boolean := false
  );
  port (
    busclk : in std_logic;
    iobus : in iobus_t;
    write_data : out std_logic_vector(31 downto 0);
    iobus_ready : out std_logic;
    interrupt : out std_logic;
    reset_out : out std_logic;
    ready_in : in std_logic;
    xgmii_rxclk : in std_logic;
    xgmii_txclk : in std_logic;
    xgmii_txd : out std_logic_vector(63 downto 0);
    xgmii_txc : out std_logic_vector(7 downto 0);
    xgmii_rxd : in std_logic_vector(63 downto 0);
    xgmii_rxc : in std_logic_vector(7 downto 0);
    xgmii_clk_lock : in std_logic;
    jumpered_address : in std_logic_vector(6 downto 0);
    configuration_vector_out : out std_logic_vector(6 downto 0);
    status_vector_in : in std_logic_vector(7 downto 0);
    sendpkt_trigger : in std_logic;
    udp_received : out std_logic;
    xgbe_stream_clka : out std_logic;
    xgbe_stream_wren : in std_logic_vector(nstream-1 downto 0);
    xgbe_stream_strobe : in std_logic_vector(nstream-1 downto 0);
    xgbe_stream_data : in xstream_data_array_t;
    xgbe_stream_free : out xstream_free_array_t;
    xgbe_trigger_stream_enable : out std_logic;
    xgbe_trigger_stream_data : out std_logic_vector(63 downto 0);
    debug_in : in std_logic_vector(5 downto 0)
  );
end xaui_interface;

architecture RTL of xaui_interface is

  component crc32x64
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;
--
--  The alternative is the crc32x64 component which does not use lookup rom
--  and is a wee bit slower.
--
  component crc32x64rom
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component crc32x64_table
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component crc32x64_slice
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component xaui_ethernet
  port (
    reset : in std_logic;
    clk : in std_logic;
    enable : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    my_hw_addr : in std_logic_vector(47 downto 0);
    saddr : out std_logic_vector(47 downto 0);
    daddr : out std_logic_vector(47 downto 0);
    src_ip : out std_logic_vector(31 downto 0);
    dst_ip : out std_logic_vector(31 downto 0);
    crc_valid : out std_logic;
    arp_enable : out std_logic;
    icmp_enable : out std_logic;
    udp_enable : out std_logic;
    ip_length : out std_logic_vector(15 downto 0)
  );
  end component;

  component xaui_arp
  port (
    reset : in  std_logic;
    clk : in  std_logic;
    enable : in  std_logic;
    din : in  std_logic_vector (63 downto 0);
    ip_address : in std_logic_vector(31 downto 0);
    hardware_type : out  std_logic_vector (15 downto 0);
    protocol_type : out  std_logic_vector (15 downto 0);
    hlen : out  std_logic_vector (7 downto 0);
    plen : out  std_logic_vector (7 downto 0);
    operation : out  std_logic_vector (15 downto 0);
    sender_ha : out  std_logic_vector (47 downto 0);
    sender_ip : out  std_logic_vector (31 downto 0);
    target_ha : out  std_logic_vector (47 downto 0);
    target_ip : out  std_logic_vector (31 downto 0);
    matched : out std_logic
  );
  end component;

  component xaui_icmp
  port (
    reset : in  std_logic;
    clk : in  std_logic;
    enable : in  std_logic;
    din : in  std_logic_vector (63 downto 0);
    icmp_type : out std_logic_vector(7 downto 0);
    icmp_code : out std_logic_vector(7 downto 0);
    icmp_cksum : out std_logic_vector(15 downto 0);
    echo_ident : out std_logic_vector(15 downto 0);
    echo_seq : out std_logic_vector(15 downto 0);
    icmp_data_we : out std_logic
  );
  end component;

  component xaui_arpreq
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    src_ha : in std_logic_vector(47 downto 0);
    src_ip : in std_logic_vector(31 downto 0);
    target_ip : in std_logic_vector(31 downto 0);
    my_netmask : in std_logic_vector(31 downto 0);
    gw_ip_address : in std_logic_vector(31 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    fcs : out std_logic;
    request : out std_logic;
    grant : in std_logic
  );
  end component;

  component xaui_arprep
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    src_ha : in std_logic_vector(47 downto 0);
    src_ip : in std_logic_vector(31 downto 0);
    dst_ha : in std_logic_vector(47 downto 0);
    dst_ip : in std_logic_vector(31 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    fcs : out std_logic;
    request : out std_logic;
    grant : in std_logic
  );
  end component;

  component xaui_icmprep
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    src_ha : in std_logic_vector(47 downto 0);
    src_ip : in std_logic_vector(31 downto 0);
    target_ha : in std_logic_vector(47 downto 0);
    dst_ip : in std_logic_vector(31 downto 0);
    ip_length : in std_logic_vector(15 downto 0);
    icmp_data_we : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    request : out std_logic;
    grant : in std_logic
  );
  end component;

  component xaui_icmpreq
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    issue_arp_request : out std_logic;
    arptab_lookup_ip : out std_logic_vector(31 downto 0);
    arptab_read : out std_logic;
    arptab_found : in std_logic;
    arptab_missing : in std_logic;
    dst_ha : in std_logic_vector(47 downto 0);
    src_ha : in std_logic_vector(47 downto 0);
    src_ip : in std_logic_vector(31 downto 0);
    dst_ip : in std_logic_vector(31 downto 0);
    sequence : in std_logic_vector(15 downto 0);
    identifier : in std_logic_vector(15 downto 0);
    length : in std_logic_vector(15 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    request : out std_logic;
    grant : in std_logic;
    stop : in std_logic;
    timer : out std_logic_vector(31 downto 0)
  );
  end component;

  component xaui_txbuffer
    port (
      reset : in std_logic;
      busy : out std_logic;
      clka : in std_logic;
      ena : in std_logic;
      wea : in std_logic_vector(3 downto 0);
      addra : in std_logic_vector(8 downto 0);
      dina : in std_logic_vector(31 downto 0);
      douta : out std_logic_vector(31 downto 0);
      cksum : out std_logic_vector(15 downto 0);
      clkb : in std_logic;
      addrb : in std_logic_vector(7 downto 0);
      doutb : out std_logic_vector(63 downto 0)
    );
  end component;

  component xaui_udp
  port (
    reset : in std_logic;
    clk : in std_logic;
    enable : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    src_port : out std_logic_vector(15 downto 0);
    dst_port : out std_logic_vector(15 downto 0);
    length : out std_logic_vector(15 downto 0);
    udp_data_we : out std_logic;
    udp_buffer_clear : out std_logic
  );
  end component;

  component xaui_udpbuffer
    port (
      reset : in std_logic;
      clka : in std_logic;
      wea : in std_logic;
      rxd : in std_logic_vector(63 downto 0);
      rxc : in std_logic_vector(7 downto 0);
      saddr : in std_logic_vector(31 downto 0);
      daddr : in std_logic_vector(31 downto 0);
      sport : in std_logic_vector(15 downto 0);
      dport : in std_logic_vector(15 downto 0);
      length : in std_logic_vector(15 downto 0);
      clkb : in std_logic;
      enb : in std_logic;
      addrb : in std_logic_vector(8 downto 0);
      doutb : out std_logic_vector(31 downto 0)
    );
  end component;

  component xaui_sendpkt
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    issue_arp_request : out std_logic;
    arptab_lookup_ip : out std_logic_vector(31 downto 0);
    arptab_read : out std_logic;
    arptab_found : in std_logic;
    arptab_missing : in std_logic;
    dst_ha : in std_logic_vector(47 downto 0);
    src_ha : in std_logic_vector(47 downto 0);
    src_ip : in std_logic_vector(31 downto 0);
    dst_ip : in std_logic_vector(31 downto 0);
    src_port : in std_logic_vector(15 downto 0);
    dst_port : in std_logic_vector(15 downto 0);
    udp_buffer_checksum : in std_logic_vector(15 downto 0);
    udp_buffer_length : in std_logic_vector(11 downto 0);
    addr : out std_logic_vector(7 downto 0);
    din : in std_logic_vector(63 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    fcs : out std_logic;
    request : out std_logic;
    grant : in std_logic
  );
  end component;

  component xaui_stream_buffer
  generic (
    index : integer := 0
  );
  port (
    rst : in std_logic;
    clk_a : in std_logic;
    wen_a : in std_logic;
    din_a : in std_logic_vector(63 downto 0);
    strobe_a : in std_logic;
    clk_b : in std_logic;
    dv_b : out std_logic;
    dout_b : out std_logic_vector(63 downto 0);
    rden_b : in std_logic;
    done_b : out std_logic;
    cksum : out std_logic_vector(15 downto 0);
    length : out std_logic_vector(11 downto 0);
    advance : in std_logic;
    free : out std_logic_vector(15 downto 0);
    lost : out std_logic_vector(15 downto 0);
    debug_state : out std_logic_vector(3 downto 0)
  );
  end component;

  component xaui_trigger
  port (
    reset : in std_logic;
    clka : in std_logic;
    wea : in std_logic;
    rxd : in std_logic_vector(63 downto 0);
    rxc : in std_logic_vector(7 downto 0);
    saddr : in std_logic_vector(31 downto 0);
    daddr : in std_logic_vector(31 downto 0);
    sport : in std_logic_vector(15 downto 0);
    dport : in std_logic_vector(15 downto 0);
    length : in std_logic_vector(15 downto 0);
    trigger_we : out std_logic
  );
  end component;

  component xaui_streampkt
    generic (
      index : integer := 0
    );
    port (
      reset : in std_logic;
      clk : in std_logic;
      strobe : in std_logic;
      busy : out std_logic;
      done : out std_logic;
      issue_arp_request : out std_logic;
      arptab_lookup_ip : out std_logic_vector(31 downto 0);
      arptab_read : out std_logic;
      arptab_found : in std_logic;
      arptab_missing : in std_logic;
      dst_ha : in std_logic_vector(47 downto 0);
      src_ha : in std_logic_vector(47 downto 0);
      src_ip : in std_logic_vector(31 downto 0);
      dst_ip : in std_logic_vector(31 downto 0);
      src_port : in std_logic_vector(15 downto 0);
      dst_port : in std_logic_vector(15 downto 0);
      buffer_cksum : in std_logic_vector(15 downto 0);
      buffer_length : in std_logic_vector(11 downto 0);
      buffer_rden : out std_logic;
      buffer_data : in std_logic_vector(63 downto 0);
      dout : out std_logic_vector(63 downto 0);
      cout : out std_logic_vector(7 downto 0);
      fcs : out std_logic;
      request : out std_logic;
      grant : in std_logic;
      debug_state : out std_logic_vector(3 downto 0)
    );
  end component;

  component arptab
    generic ( size : integer := 4 );
    port (
      reset : in std_logic;
      clk : in std_logic;
      read_strobe : in std_logic;
      write_strobe : in std_logic;
      my_ip_address : in std_logic_vector(31 downto 0);
      my_netmask : in std_logic_vector(31 downto 0);
      gw_ip_address : in std_logic_vector(31 downto 0);
      load_ip_addr : in std_logic_vector(31 downto 0);
      load_hw_addr : in std_logic_vector(47 downto 0);
      lookup_ip_addr : in std_logic_vector(31 downto 0);
      target_ip_addr : out std_logic_vector(31 downto 0);
      lookup_hw_addr : out std_logic_vector(47 downto 0);
      found : out std_logic;
      missing : out std_logic;
      entries : out std_logic_vector(7 downto 0);
      index : in std_logic_vector(7 downto 0);
      table_ip_addr : out std_logic_vector(31 downto 0);
      table_hw_addr : out std_logic_vector(47 downto 0);
      table_ref_count : out std_logic_vector(31 downto 0)
    );
  end component;

  component xaui_arbiter
    generic ( n : integer := 8 );
    port (
      reset : in std_logic;
      clk : in std_logic;
      request : in std_logic_vector(n-1 downto 0);
      grant : out std_logic_vector(n-1 downto 0)
    );
  end component;

  constant base_address : std_logic_vector(15 downto 0) := x"c300";
  constant address_mask : std_logic_vector(15 downto 0) := x"ffff";
  signal masked_address : std_logic_vector(15 downto 0);

  constant address_xaui_csr : std_logic_vector(15 downto 0) := x"0000";
  constant address_mac_addr_low : std_logic_vector(15 downto 0) := x"0018";
  constant address_mac_addr_high : std_logic_vector(15 downto 0) := x"001c";
  constant address_ip_addr : std_logic_vector(15 downto 0) := x"0020";
  constant address_netmask : std_logic_vector(15 downto 0) := x"0024";
  constant address_gateway : std_logic_vector(15 downto 0) := x"0028";

  constant address_streampkt_csr : std_logic_vector(15 downto 0) := x"0030";
  constant address_streampkt_daddr : std_logic_vector(15 downto 0) := x"0034";
  constant address_streampkt_ports : std_logic_vector(15 downto 0) := x"0038";
  constant address_streampkt_buffer : std_logic_vector(15 downto 0) := x"003c";
  constant address_streampkt_status : std_logic_vector(15 downto 0) := x"0040";

  constant address_arp_csr : std_logic_vector(15 downto 0) := x"0044";
  constant address_arp_lookup_ip : std_logic_vector(15 downto 0) := x"0048";
  constant address_arp_table_ip : std_logic_vector(15 downto 0) := x"004c";
  constant address_arp_table_ha_low : std_logic_vector(15 downto 0) := x"0050";
  constant address_arp_table_ha_high : std_logic_vector(15 downto 0) := x"0054";
  constant address_arp_table_refcount : std_logic_vector(15 downto 0) := x"0058";

  constant address_udp_buffer : std_logic_vector(15 downto 0) := x"0060";

  constant address_sendpkt_daddr : std_logic_vector(15 downto 0) := x"0064";
  constant address_sendpkt_ports : std_logic_vector(15 downto 0) := x"0068";
  constant address_icmpreq_csr : std_logic_vector(15 downto 0) := x"0070";
  constant address_icmpreq_sequence : std_logic_vector(15 downto 0) := x"0074";
  constant address_icmpreq_daddr : std_logic_vector(15 downto 0) := x"0078";
  constant address_icmpreq_timer : std_logic_vector(15 downto 0) := x"007c";

  constant address_txbuffer_status : std_logic_vector(15 downto 0) := x"0080";

  constant address_debug_arpinput : std_logic_vector(15 downto 0 ) := x"0094";
  constant address_debug_arpoutput_lo : std_logic_vector(15 downto 0 ) := x"0098";
  constant address_debug_arpoutput_hi : std_logic_vector(15 downto 0 ) := x"009c";
  constant address_source_ha_low : std_logic_vector(15 downto 0) := x"0100";
  constant address_source_ha_high : std_logic_vector(15 downto 0) := x"0104";
  constant address_target_ha_low : std_logic_vector(15 downto 0) := x"0108";
  constant address_target_ha_high : std_logic_vector(15 downto 0) := x"010c";

  constant address_rx_frame_counter : std_logic_vector(15 downto 0) := x"0200";
  constant address_rx_arp_counter : std_logic_vector(15 downto 0) := x"0204";
  constant address_rx_icmp_counter : std_logic_vector(15 downto 0) := x"0208";
  constant address_rx_udp_counter : std_logic_vector(15 downto 0) := x"020c";

  signal gw_ip_address : std_logic_vector(31 downto 0) := string_to_ipaddr(gateway);
  signal my_netmask : std_logic_vector(31 downto 0) := string_to_ipaddr(netmask);
  signal my_ip_address : std_logic_vector(31 downto 0) := string_to_ipaddr(ip_address);
  signal my_mac_addr : std_logic_vector(47 downto 0) := string_to_hwaddr(mac_address);
  signal sendpkt_daddr : std_logic_vector(31 downto 0) := x"00000000";
  signal sendpkt_ports : std_logic_vector(31 downto 0) := x"00000000";
  signal sendpkt_fcs : std_logic;
  signal sendpkt_dout : std_logic_vector(63 downto 0);
  signal sendpkt_cout : std_logic_vector(7 downto 0);
  signal sendpkt_request : std_logic;

  signal rx_frame_counter : unsigned(31 downto 0) := ( others => '0' );
  signal rx_arp_counter : unsigned(15 downto 0) := ( others => '0' );
  signal rx_icmp_counter : unsigned(15 downto 0) := ( others => '0' );
  signal rx_udp_counter : unsigned(15 downto 0) := ( others => '0' );

  signal xaui_csr : std_logic_vector(31 downto 0) := ( others => '0' );
  signal streampkt_csr : std_logic_vector(31 downto 0);
  signal streampkt_busy : std_logic_vector(nstream-1 downto 0);
  signal streampkt_state : std_logic_vector(15 downto 0);
  signal streampkt_strobe : std_logic_vector(nstream-1 downto 0) := ( others => '0' );

  signal streampkt_arpreq_strobe : std_logic_vector(nstream-1 downto 0) := ( others => '0' );
  signal streampkt_ports : std_logic_vector(31 downto 0);
  signal streampkt_daddr : std_logic_vector(31 downto 0);
  type streampkt_dout_t is array(nstream-1 downto 0) of std_logic_vector(63 downto 0);
  signal streampkt_dout : streampkt_dout_t;
  type streampkt_cout_t is array(nstream-1 downto 0) of std_logic_vector(7 downto 0);
  signal streampkt_cout : streampkt_cout_t;
  signal xaui_int : std_logic := '0';
  signal xaui_int_ack : std_logic := '0';
  signal latched_data : std_logic_vector(31 downto 0);
  signal rxd : std_logic_vector(63 downto 0);
  signal rxc : std_logic_vector(7 downto 0);
  signal udp_rxd : std_logic_vector(63 downto 0);
  signal udp_rxc : std_logic_vector(7 downto 0);
  signal odd_word : std_logic := '0';
  signal dword_pipe : std_logic_vector(63 downto 0);
  signal cword_pipe : std_logic_vector(7 downto 0);
  signal ioff : integer range 0 to 7 := 0;
  signal txd_pipe : std_logic_vector(2*64-1 downto 0);
  signal txc_pipe : std_logic_vector(2*8-1 downto 0);
  signal xaui_reset : std_logic := '0';
  signal soft_reset : std_logic := '0';

  signal frame : std_logic := '0';
  signal frame_start : std_logic := '0';
  signal frame_end : std_logic := '0';
  signal ethernet_src_ip : std_logic_vector(31 downto 0);
  signal ethernet_dst_ip : std_logic_vector(31 downto 0);

  signal send_preamble : std_logic;
  signal send_data : std_logic;
  signal ethernet_crc : std_logic;
  signal ethernet_crc_out : std_logic_vector(63 downto 0);
  signal ethernet_dout : std_logic_vector(63 downto 0);
  signal next_txd : std_logic_vector(63 downto 0);
  signal next_txc : std_logic_vector(7 downto 0);
  signal txd : std_logic_vector(63 downto 0) := x"0707070707070707";
  signal txc : std_logic_vector(7 downto 0) := x"ff";
  signal arpreq_fcs : std_logic;
  signal arprep_fcs : std_logic;
  signal send_fcs : std_logic;
  signal arpreq_strobe : std_logic;
  signal arpreq_busy : std_logic;
  signal arpreq_target_ip : std_logic_vector(31 downto 0);
  signal crc_en : std_logic := '0';
  signal crc_clr : std_logic := '1';
  signal crc_dout : std_logic_vector(63 downto 0);
  signal crc : std_logic_vector(31 downto 0);
  signal txframe : std_logic := '0';
  signal txframe_start : std_logic := '0';

  signal crc_valid : std_logic;
  signal arp_enable : std_logic;
  signal latched_arp_enable : std_logic_vector(1 downto 0);
  signal arp_htype : std_logic_vector(15 downto 0);
  signal arp_ptype : std_logic_vector(15 downto 0);
  signal arp_hlen : std_logic_vector(7 downto 0);
  signal arp_plen : std_logic_vector(7 downto 0);
  signal arp_operation : std_logic_vector(15 downto 0);
  signal arp_sender_ha : std_logic_vector(47 downto 0);
  signal arp_sender_ip : std_logic_vector(31 downto 0);
  signal arp_target_ha : std_logic_vector(47 downto 0);
  signal arp_target_ip : std_logic_vector(31 downto 0);
  signal arp_matched_ip : std_logic;
  signal arpreq_dout : std_logic_vector(63 downto 0);
  signal arpreq_cout : std_logic_vector(7 downto 0);
  signal arprep_dout : std_logic_vector(63 downto 0);
  signal arprep_cout : std_logic_vector(7 downto 0);

  signal arp_lookup_ip : std_logic_vector(31 downto 0);
  constant arptab_size : integer := 8;

  signal arp_csr : std_logic_vector(31 downto 0) := ( others => '0' );
  signal read_arp_csr : std_logic_vector(31 downto 0);
  signal arptab_found : std_logic;
  signal arptab_lookup_ip_addr : std_logic_vector(31 downto 0);
  signal arptab_target_ip_addr : std_logic_vector(31 downto 0);
  signal arptab_lookup_hw_addr : std_logic_vector(47 downto 0);
  signal arptab_read_ip_addr : std_logic_vector(31 downto 0);
  signal arptab_read_hw_addr : std_logic_vector(47 downto 0);
  signal arptab_read_refcount : std_logic_vector(31 downto 0);
  signal arptab_entries : std_logic_vector(7 downto 0);
  signal arptab_index : std_logic_vector(7 downto 0);
  signal arptab_read_strobe : std_logic := '0';
  signal arptab_write_strobe : std_logic := '0';
  signal matched_arprep_frame : std_logic := '0';
  signal matched_arpreq_frame : std_logic := '0';
  signal arptab_missing : std_logic;
  signal arptab_load_ip_addr : std_logic_vector(31 downto 0);
  signal arptab_load_hw_addr : std_logic_vector(47 downto 0);
  signal arp_reply_strobe : std_logic := '0';
  signal ethernet_source_ha : std_logic_vector(47 downto 0);
  signal ethernet_target_ha : std_logic_vector(47 downto 0);

  signal sendpkt_arptab_read_strobe : std_logic := '0';
  signal sendpkt_arpreq_strobe : std_logic := '0';
  signal sendpkt_lookup_ip : std_logic_vector(31 downto 0);
  signal matched_ip_address : std_logic := '0';

  signal icmp_enable : std_logic;
  signal latched_icmp_enable : std_logic_vector(1 downto 0);
  signal icmp_type : std_logic_vector(7 downto 0);
  signal icmp_code : std_logic_vector(7 downto 0);
  signal icmp_cksum : std_logic_vector(15 downto 0);
  signal icmp_echo_ident : std_logic_vector(15 downto 0);
  signal icmp_echo_seq : std_logic_vector(15 downto 0);
  signal icmp_data_we : std_logic := '0';

  signal icmpreq_sequence : std_logic_vector(31 downto 0);
  signal icmpreq_csr : std_logic_vector(31 downto 0);
  signal icmpreq_strobe : std_logic := '0';
  signal icmpreq_arpreq_strobe : std_logic := '0';
  signal icmpreq_arptab_read_strobe : std_logic := '0';
  signal icmpreq_daddr : std_logic_vector(31 downto 0);
  signal icmpreq_lookup_ip : std_logic_vector(31 downto 0);
  signal icmpreq_stop_timer : std_logic;
  signal icmpreq_timer : std_logic_vector(31 downto 0);

  signal icmprep_strobe : std_logic;
  signal icmprep_dout : std_logic_vector(63 downto 0);
  signal icmprep_cout : std_logic_vector(7 downto 0);
  signal icmpreq_dout : std_logic_vector(63 downto 0);
  signal icmpreq_cout : std_logic_vector(7 downto 0);

  signal ip_length : std_logic_vector(15 downto 0);
  signal udp_enable : std_logic;
  signal latched_udp_enable : std_logic_vector(1 downto 0);
  signal sendpkt_strobe : std_logic := '0';
  signal sendpkt_now : std_logic := '0';
  signal sendpkt_armed : std_logic := '0';
  signal sendpkt_busy : std_logic := '0';
  signal sendpkt_trigger_r : std_logic;

  signal txbuffer_write_enable : std_logic;
  signal txbuffer_read : std_logic_vector(31 downto 0);
  signal txbuffer_cksum : std_logic_vector(15 downto 0);
  signal txbuffer_length : std_logic_vector(11 downto 0);
  signal txbuffer_reset : std_logic;
  signal txbuffer_busy : std_logic;
  signal txbuffer_addressed : std_logic;
  signal txbuffer_addrb : std_logic_vector(7 downto 0);
  signal txbuffer_doutb : std_logic_vector(63 downto 0);

  signal udp_src_port : std_logic_vector(15 downto 0);
  signal udp_dst_port : std_logic_vector(15 downto 0);
  signal udp_length : std_logic_vector(15 downto 0);
  signal udp_buffer_addressed : std_logic_vector(3 downto 0);
  signal udp_buffer_read_enable : std_logic_vector(3 downto 0);
  signal udp_write : std_logic_vector(3 downto 0);
  signal udp_reset : std_logic_vector(3 downto 0);
  type udp_buffer_data_t is array(3 downto 0) of std_logic_vector(31 downto 0);
  signal udp_buffer_data : udp_buffer_data_t;
  signal udp_buffer_clear : std_logic;
  signal udp_received_strobe : std_logic;
  signal udp_received_pipe : std_logic_vector(5 downto 0);
  signal udp_buffer_busy : std_logic_vector(3 downto 0) := ( others => '0' );
  signal r_udp_buffer_busy : std_logic_vector(3 downto 0) := ( others => '0' );
  signal udp_buffer_free : std_logic_vector(3 downto 0) := ( others => '0' );
  signal udp_payload : std_logic;

  signal streampkt_data_available : std_logic_vector(nstream-1 downto 0) := ( others => '0' );
  signal streampkt_done : std_logic_vector(nstream-1 downto 0) := ( others => '0' );
  signal streampkt_advance : std_logic_vector(nstream-1 downto 0) := ( others => '0' );
  type streampkt_protocol_t is array(nstream-1 downto 0) of std_logic_vector(7 downto 0);
  signal streampkt_protocol : streampkt_protocol_t := ( others => ( others => '0' ) );
  type streampkt_buffer_length_t is array(nstream-1 downto 0) of std_logic_vector(11 downto 0);
  signal streampkt_buffer_length : streampkt_buffer_length_t := ( others => x"028" );
  type streampkt_buffer_cksum_t is array(nstream-1 downto 0) of std_logic_vector(15 downto 0);
  signal streampkt_buffer_cksum : streampkt_buffer_cksum_t := ( others => ( others => '0' ) );
  type streampkt_buffer_data_t is array(nstream-1 downto 0) of std_logic_vector(63 downto 0);
  signal streampkt_buffer_data : streampkt_buffer_data_t;
  signal streampkt_buffer_rden : std_logic_vector(nstream-1 downto 0);
  type streampkt_length_t is array(nstream-1 downto 0) of std_logic_vector(15 downto 0);
  signal streampkt_length : streampkt_length_t := ( others => ( others => '0' ) );
  type streampkt_buffer_free_t is array(nstream-1 downto 0) of std_logic_vector(15 downto 0);
  signal streampkt_buffer_free : streampkt_buffer_free_t := ( others => ( others => '0' ) );
  type streampkt_lost_packets_t is array(nstream-1 downto 0) of std_logic_vector(15 downto 0);
  signal streampkt_lost_packets : streampkt_lost_packets_t := ( others => ( others => '0' ) );
  signal streampkt_gated_strobe : std_logic_vector(nstream-1 downto 0);
  signal streampkt_gated_wren : std_logic_vector(nstream-1 downto 0);
  signal streampkt_fcs : std_logic_vector(nstream-1 downto 0);

  type streampkt_lookup_t is array(nstream-1 downto 0) of std_logic_vector(31 downto 0);
  signal streampkt_lookup_ip : streampkt_lookup_t;
  signal streampkt_arptab_read_strobe : std_logic_vector(nstream-1 downto 0);

  signal request : std_logic_vector(15 downto 0) := ( others => '0' );
  signal grant : std_logic_vector(15 downto 0) := ( others => '0' );

  signal udp_trigger_write : std_logic;
  signal trigger_we : std_logic;

  attribute mark_debug : string;
  attribute dont_touch : string;
  attribute mark_debug of frame : signal is "true";
  attribute dont_touch of frame : signal is "true";
  attribute mark_debug of rxd : signal is "true";
  attribute dont_touch of rxd : signal is "true";
  attribute mark_debug of rxc : signal is "true";
  attribute dont_touch of rxc : signal is "true";
  attribute mark_debug of grant : signal is "true";
  attribute dont_touch of grant : signal is "true";

--  attribute mark_debug of frame_start : signal is "true";
--  attribute mark_debug of frame_end : signal is "true";
--  attribute mark_debug of dword_pipe : signal is "true";
--  attribute mark_debug of cword_pipe : signal is "true";
--  attribute dont_touch of dword_pipe : signal is "true";
--  attribute dont_touch of cword_pipe : signal is "true";
--  attribute mark_debug of crc_valid : signal is "true";
--  attribute mark_debug of crc : signal is "true";
--  attribute mark_debug of txd : signal is "true";
--  attribute mark_debug of txc : signal is "true";
--  attribute mark_debug of icmprep_strobe : signal is "true";
--  attribute mark_debug of sendpkt_strobe : signal is "true";
--  attribute mark_debug of rx_frame_counter : signal is "true";
--  attribute mark_debug of latched_icmp_enable : signal is "true";

begin

  crc_imp : crc32x64_slice
  port map (
    clk => xgmii_rxclk,
    en => crc_en,
    clr => crc_clr,
    din => txd,
    cin => txc,
    dout => crc,
    valid => open
  );

  eth_imp : xaui_ethernet
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    enable => frame,
    din => rxd,
    cin => rxc,
    my_hw_addr => my_mac_addr,
    saddr => ethernet_source_ha,
    daddr => ethernet_target_ha,
    src_ip => ethernet_src_ip,
    dst_ip => ethernet_dst_ip,
    crc_valid => crc_valid,
    arp_enable => arp_enable,
    icmp_enable => icmp_enable,
    udp_enable => udp_enable,
    ip_length => ip_length
  );

  arp_imp : xaui_arp
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    enable => arp_enable,
    din => rxd,
    ip_address => my_ip_address,
    hardware_type => arp_htype,
    protocol_type => arp_ptype,
    hlen => arp_hlen,
    plen => arp_plen,
    operation => arp_operation,
    sender_ha => arp_sender_ha,
    sender_ip => arp_sender_ip,
    target_ha => arp_target_ha,
    target_ip => arp_target_ip,
    matched => arp_matched_ip
  );

  icmp_imp : xaui_icmp
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    enable => icmp_enable,
    din => rxd,
    icmp_type => icmp_type,
    icmp_code => icmp_code,
    icmp_cksum => icmp_cksum,
    echo_ident => icmp_echo_ident,
    echo_seq => icmp_echo_seq,
    icmp_data_we => icmp_data_we
  );

  arprep_imp : xaui_arprep
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    strobe => arp_reply_strobe,
    src_ha => my_mac_addr,
    src_ip => my_ip_address,
    dst_ha => arp_sender_ha,
    dst_ip => arp_sender_ip,
    dout => arprep_dout,
    cout => arprep_cout,
    fcs => arprep_fcs,
    request => request(0),
    grant => grant(0)
  );

  arpreq_imp : xaui_arpreq
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    strobe => arpreq_strobe,
    src_ha => my_mac_addr,
    src_ip => my_ip_address,
    target_ip => arpreq_target_ip,
    my_netmask => my_netmask,
    gw_ip_address => gw_ip_address,
    dout => arpreq_dout,
    cout => arpreq_cout,
    fcs => arpreq_fcs,
    request => request(1),
    grant => grant(1)
  );

  icmpreq_imp : xaui_icmpreq
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    strobe => icmpreq_strobe,
    issue_arp_request => icmpreq_arpreq_strobe,
    arptab_lookup_ip => icmpreq_lookup_ip,
    arptab_read => icmpreq_arptab_read_strobe,
    arptab_found => arptab_found,
    arptab_missing => arptab_missing,
    dst_ha => arptab_lookup_hw_addr,
    src_ha => my_mac_addr,
    dst_ip => icmpreq_daddr,
    src_ip => my_ip_address,
    sequence => icmpreq_sequence(15 downto 0),
    identifier => icmpreq_sequence(31 downto 16),
    length => icmpreq_csr(15 downto 0),
    dout => icmpreq_dout,
    cout => icmpreq_cout,
    request => request(3),
    grant => grant(3),
    stop => icmpreq_stop_timer,
    timer => icmpreq_timer
  );

  icmprep_imp : xaui_icmprep
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    strobe => icmprep_strobe,
    src_ha => my_mac_addr,
    src_ip => my_ip_address,
    target_ha => ethernet_source_ha,
    dst_ip => ethernet_src_ip,
    ip_length => ip_length,
    icmp_data_we => icmp_data_we,
    din => rxd,
    cin => rxc,
    dout => icmprep_dout,
    cout => icmprep_cout,
    request => request(2),
    grant => grant(2)
  );

  udp_imp : xaui_udp
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    enable => udp_enable,
    din => rxd,
    cin => rxc,
    src_port => udp_src_port,
    dst_port => udp_dst_port,
    length => udp_length,
    udp_data_we => udp_payload,
    udp_buffer_clear => udp_buffer_clear
  );

  gbuf : for i in 0 to 3 generate
    xudpbuf_imp : xaui_udpbuffer
    port map (
      reset => udp_reset(i),
      clka => xgmii_rxclk,
      wea => udp_write(i),
      rxd => rxd,
      rxc => rxc,
      saddr => ethernet_src_ip,
      daddr => ethernet_dst_ip,
      sport => udp_src_port,
      dport => udp_dst_port,
      length => udp_length,
      clkb => busclk,
      enb => udp_buffer_read_enable(i),
      addrb => iobus.io_address(10 downto 2),
      doutb => udp_buffer_data(i)
    );

--    udp_buffer_read_enable(i) <= '1' when iobus.io_addr_strobe = '1' and
--                                          masked_address = base_address and
--      iobus.io_address(15 downto 11) = std_logic_vector("10000"+to_unsigned(i,5))
--                                     else '0';
    udp_buffer_read_enable(i) <= '1' when iobus.io_addr_strobe = '1' and
                                          masked_address = base_address and
      iobus.io_address(15 downto 11) = std_logic_vector(to_unsigned(i+16,5))
                                     else '0';
    udp_reset(i) <= udp_buffer_clear when udp_buffer_busy(i) = '0' else '0';
    udp_write(i) <= udp_payload when udp_buffer_busy(i) = '0' and
                                     udp_dst_port /= x"eeee" else '0';
  end generate;

  trig_imp : xaui_trigger
  port map (
    reset => '0',
    clka => xgmii_rxclk,
    wea => udp_trigger_write,
    rxd => udp_rxd,
    rxc => udp_rxc,
    saddr => ethernet_src_ip,
    daddr => ethernet_dst_ip,
    sport => udp_src_port,
    dport => udp_dst_port,
    length => udp_length,
    trigger_we => trigger_we
  );
  udp_trigger_write <= udp_payload when udp_dst_port = x"eeee" else '0';
  xgbe_trigger_stream_enable <= trigger_we;

  txbuffer_imp : xaui_txbuffer
  port map (
    reset => txbuffer_reset,
    busy => txbuffer_busy,
    clka => busclk,
    ena => txbuffer_write_enable,
    wea => iobus.io_byte_enable,
    addra => iobus.io_address(10 downto 2),
    dina => iobus.io_write_data,
    douta => txbuffer_read,
    cksum => txbuffer_cksum,
    clkb => xgmii_rxclk,
    addrb => txbuffer_addrb,
    doutb => txbuffer_doutb
  );

  sendpkt_imp : xaui_sendpkt
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    strobe => sendpkt_strobe,
    issue_arp_request => sendpkt_arpreq_strobe,
    arptab_lookup_ip => sendpkt_lookup_ip,
    arptab_read => sendpkt_arptab_read_strobe,
    arptab_found => arptab_found,
    arptab_missing => arptab_missing,
    dst_ha => arptab_lookup_hw_addr,
    src_ha => my_mac_addr,
    dst_ip => sendpkt_daddr,
    src_ip => my_ip_address,
    src_port => sendpkt_ports(15 downto 0),
    dst_port => sendpkt_ports(31 downto 16),
    udp_buffer_checksum => txbuffer_cksum,
    udp_buffer_length => txbuffer_length,
    addr => txbuffer_addrb,
    din => txbuffer_doutb,
    dout => sendpkt_dout,
    cout => sendpkt_cout,
    fcs => sendpkt_fcs,
    request => request(4),
    grant => grant(4)
  );

  g_stream : for i in 0 to nstream-1 generate
    sb_imp : xaui_stream_buffer
    generic map (
      index => i
    )
    port map (
      rst => xaui_reset,
      clk_a => xgmii_txclk,
      wen_a => streampkt_gated_wren(i),
      strobe_a => streampkt_gated_strobe(i),
      din_a => xgbe_stream_data(i),
      clk_b => xgmii_rxclk,
      dv_b => streampkt_data_available(i),
      dout_b => streampkt_buffer_data(i),
      rden_b => streampkt_buffer_rden(i),
      done_b => streampkt_done(i),
      cksum => streampkt_buffer_cksum(i),
      length => streampkt_buffer_length(i),
      advance => streampkt_advance(i),
      free => streampkt_buffer_free(i),
      lost => streampkt_lost_packets(i),
      debug_state => streampkt_state(8*i+3 downto 8*i)
    );
    xgbe_stream_free(i) <= streampkt_buffer_free(i);

    streampkt_imp : xaui_streampkt
    generic map (
      index => i
    )
    port map (
      reset => xaui_reset,
      clk => xgmii_rxclk,
      strobe => streampkt_strobe(i),
      busy => streampkt_busy(i),
      done => streampkt_advance(i),
      issue_arp_request => streampkt_arpreq_strobe(i),
      arptab_lookup_ip => streampkt_lookup_ip(i),
      arptab_read => streampkt_arptab_read_strobe(i),
      arptab_found => arptab_found,
      arptab_missing => arptab_missing,
      dst_ha => arptab_lookup_hw_addr,
      src_ha => my_mac_addr,
      dst_ip => streampkt_daddr,
      src_ip => my_ip_address,
      src_port => streampkt_ports(15 downto 0),
      dst_port => streampkt_ports(31 downto 16),
      buffer_cksum => streampkt_buffer_cksum(i),
      buffer_length => streampkt_buffer_length(i),
      buffer_rden => streampkt_buffer_rden(i),
      buffer_data => streampkt_buffer_data(i),
      dout => streampkt_dout(i),
      cout => streampkt_cout(i),
      fcs => streampkt_fcs(i),
      request => request(8+i),
      grant => grant(8+i),
      debug_state => streampkt_state(8*i+7 downto 8*i+4)
    );

  end generate;

  arptab_imp : arptab
  generic map ( size => arptab_size )
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    read_strobe => arptab_read_strobe,
    write_strobe => arptab_write_strobe,
    my_ip_address => my_ip_address,
    my_netmask => my_netmask,
    gw_ip_address => gw_ip_address,
    load_ip_addr => arptab_load_ip_addr,
    load_hw_addr => arptab_load_hw_addr,
    lookup_ip_addr => arptab_lookup_ip_addr,
    target_ip_addr => arptab_target_ip_addr,
    lookup_hw_addr => arptab_lookup_hw_addr,
    found => arptab_found,
    missing => arptab_missing,
    entries => arptab_entries,
    index => arptab_index,
    table_ip_addr => arptab_read_ip_addr,
    table_hw_addr => arptab_read_hw_addr,
    table_ref_count => arptab_read_refcount
  );

  arbit_imp : xaui_arbiter
  generic map ( n => 16 )
  port map (
    reset => xaui_reset,
    clk => xgmii_rxclk,
    request => request,
    grant => grant
  );

  process ( streampkt_data_available, streampkt_busy )
    variable strobe_v : std_logic_vector(nstream-1 downto 0);
  begin
    strobe_v := ( others => '0' );
    for i in nstream-1 downto 0 loop
      strobe_v(i) := streampkt_data_available(i) and not streampkt_busy(i);
      if ( strobe_v(i) = '1' ) then
        report "Data available on stream " & integer'image(i);
      end if;
    end loop;
    streampkt_strobe <= strobe_v;
  end process;

  process ( xgmii_rxclk )
    variable dword : std_logic_vector(127 downto 0);
    variable cword : std_logic_vector(15 downto 0);
    variable joff : integer;
  begin
    if ( xgmii_rxclk'event and xgmii_rxclk = '1' ) then
      configuration_vector_out <= xaui_csr(6 downto 0);
      latched_udp_enable <= udp_enable & latched_udp_enable(latched_udp_enable'left downto 1);
      latched_icmp_enable <= icmp_enable & latched_icmp_enable(latched_icmp_enable'left downto 1);
      latched_arp_enable <= arp_enable & latched_arp_enable(latched_arp_enable'left downto 1);
      if ( crc_valid = '1' ) then
        rx_frame_counter <= rx_frame_counter + 1;
        if ( latched_arp_enable(0) = '1' ) then
          rx_arp_counter <= rx_arp_counter + 1;
        end if;
        if ( latched_icmp_enable(0) = '1' ) then
          rx_icmp_counter <= rx_icmp_counter + 1;
        end if;
        if ( latched_udp_enable(0) = '1' ) then
          rx_udp_counter <= rx_udp_counter + 1;
        end if;
      end if;

      if ( udp_received_strobe = '1' ) then
        udp_received_pipe <= ( others => '1' );
      else
        udp_received_pipe <= '0' & udp_received_pipe(udp_received_pipe'length-1 downto 1);
      end if;

      dword_pipe <= xgmii_rxd;
      cword_pipe <= xgmii_rxc;
      dword := xgmii_rxd & dword_pipe;
      cword := xgmii_rxc & cword_pipe;
      joff := ioff;
      frame_start <= '0';
      frame_end <= '0';
      for i in 0 to 7 loop
        if ( cword(i) = '1' ) then
          if ( dword(8*i+7 downto 8*i) = x"fb" ) then     -- /K27.7/ = ||S|| = start column
            frame_start <= '1';
            joff := i;
          end if;
          if ( dword(8*i+7 downto 8*i) = x"fd" ) then     -- /K29.7/ = ||T|| = terminate column
            frame_end <= '1';
          end if;
          if ( dword(8*i+7 downto 8*i) = x"07" ) then
            frame_end <= '1';
          end if;
        end if;
      end loop;
      ioff <= joff;
      if ( frame_start = '1' ) then
        frame <= '1';
      elsif ( frame_end = '1' ) then
        frame <= '0';
      end if;
      rxd <= dword(8*joff+63 downto 8*joff);
      rxc <= cword(joff+7 downto joff);
   
      udp_rxd(63 downto 48) <= dword(8*joff+15 downto 8*joff);
      udp_rxd(47 downto 0) <= rxd(63 downto 16);
    end if;
  end process;
  xgbe_trigger_stream_data <= udp_rxd;

  process ( busclk ) begin
    if ( busclk'event and busclk = '1' ) then

      if ( xaui_int = '0' ) then
        xaui_int_ack  <= '0';
      end if;

      r_udp_buffer_busy <= udp_buffer_busy;
      for i in 0 to 3 loop
        if ( r_udp_buffer_busy(i) = '0' ) then
          udp_buffer_free(i) <= '0';
        end if;
      end loop;

      sendpkt_trigger_r <= sendpkt_trigger;
      if ( sendpkt_now = '1' or
           ( sendpkt_armed = '1' and sendpkt_trigger_r = '1' ) ) then
        sendpkt_strobe <= '1';
        sendpkt_armed <= '0';
        sendpkt_now <= '0';
      end if;
      soft_reset <= '0';
      if ( iobus.io_addr_strobe = '1' and masked_address = base_address ) then
        iobus_ready <= '1';
        if ( iobus.io_write_strobe = '1' ) then
          case iobus.io_address(15 downto 0) is
            when address_xaui_csr =>
              xaui_csr <= iobus.io_write_data;
              soft_reset <= iobus.io_write_data(31);
              if ( xaui_int = '1' and iobus.io_write_data(24) = '1' ) then
                xaui_int_ack <= '1';
              end if;
            when address_ip_addr =>
              my_ip_address(31 downto 7) <= iobus.io_write_data(31 downto 7);
              if ( not jumpers ) then
                my_ip_address(6 downto 0) <= iobus.io_write_data(6 downto 0);
              end if;
            when address_arp_lookup_ip =>
              arp_lookup_ip <= iobus.io_write_data;
            when address_arp_csr =>
              arpreq_strobe <= iobus.io_write_data(31);
              arp_csr <= iobus.io_write_data;
            when address_netmask =>
              my_netmask <= iobus.io_write_data;
            when address_gateway =>
              gw_ip_address <= iobus.io_write_data;
            when address_icmpreq_sequence =>
              icmpreq_sequence <= iobus.io_write_data;
            when address_icmpreq_csr =>
              icmpreq_csr <= '0' & iobus.io_write_data(30 downto 0);
              icmpreq_strobe <= iobus.io_write_data(31);
              icmpreq_sequence(15 downto 0) <= std_logic_vector(unsigned(icmpreq_sequence(15 downto 0))+1);
            when address_icmpreq_daddr =>
              icmpreq_daddr <= iobus.io_write_data;
            when address_sendpkt_ports =>
              sendpkt_ports <= iobus.io_write_data;
           when address_udp_buffer =>
              udp_buffer_free <= iobus.io_write_data(3 downto 0);
            when address_sendpkt_daddr =>
              sendpkt_daddr <= iobus.io_write_data;
            when address_txbuffer_status =>
              txbuffer_reset <= iobus.io_write_data(31);
              sendpkt_now <= iobus.io_write_data(30);
              sendpkt_armed <= iobus.io_write_data(29);
              txbuffer_length <= iobus.io_write_data(27 downto 16);
            when address_streampkt_csr =>
              streampkt_csr <= iobus.io_write_data;
            when address_streampkt_ports =>
              streampkt_ports <= iobus.io_write_data;
            when address_streampkt_daddr =>
              streampkt_daddr <= iobus.io_write_data;
            when others =>

          end case;
        end if;

        if ( iobus.io_read_strobe = '1' ) then
          case iobus.io_address(15 downto 0) is
            when address_xaui_csr =>
              latched_data <= not ready_in & xaui_csr(30 downto 25) & xaui_int &
                              xgmii_clk_lock & xaui_csr(22) & debug_in &
                              status_vector_in & xaui_csr(7 downto 0);
            when address_mac_addr_low =>
              latched_data <= my_mac_addr(31 downto 0);
            when address_mac_addr_high =>
              latched_data <= x"0000" & my_mac_addr(47 downto 32);
            when address_ip_addr =>
              latched_data <= my_ip_address;
            when address_netmask =>
              latched_data <= my_netmask;
            when address_gateway =>
              latched_data <= gw_ip_address;
            when address_debug_arpinput =>
              latched_data <= arptab_lookup_ip_addr;
            when address_debug_arpoutput_lo =>
              latched_data <= arptab_lookup_hw_addr(31 downto 0);
            when address_debug_arpoutput_hi =>
              latched_data <= x"0000" & arptab_lookup_hw_addr(47 downto 32);
            when address_arp_lookup_ip =>
              latched_data <= arp_lookup_ip;
            when address_arp_table_ip =>
              latched_data <= arptab_read_ip_addr;
            when address_arp_table_ha_low =>
              latched_data <= arptab_read_hw_addr(31 downto 0);
            when address_arp_table_ha_high =>
              latched_data <= x"0000" & arptab_read_hw_addr(47 downto 32);
            when address_arp_table_refcount =>
              latched_data <= arptab_read_refcount;
            when address_arp_csr =>
              latched_data <= read_arp_csr;
            when address_source_ha_low =>
              latched_data <= ethernet_source_ha(31 downto 0);
            when address_source_ha_high =>
              latched_data <= x"0000" & ethernet_source_ha(47 downto 32);
            when address_target_ha_low =>
              latched_data <= ethernet_target_ha(31 downto 0);
            when address_target_ha_high =>
              latched_data <= x"0000" & ethernet_target_ha(47 downto 32);
            when address_icmpreq_daddr =>
              latched_data <= icmpreq_daddr;
            when address_icmpreq_sequence =>
              latched_data <= icmpreq_sequence;
            when address_icmpreq_timer =>
              latched_data <= icmpreq_timer; 
            when address_icmpreq_csr =>
              latched_data <= icmpreq_csr;
            when address_udp_buffer =>
              latched_data(31 downto 4) <= ( others => '0' );
              latched_data(3 downto 0) <= udp_buffer_busy;
            when address_sendpkt_daddr =>
              latched_data <= sendpkt_daddr;
            when address_sendpkt_ports =>
              latched_data <= sendpkt_ports;
            when address_rx_frame_counter =>
              latched_data <= std_logic_vector(rx_frame_counter);
            when address_rx_arp_counter =>
              latched_data <= x"0000" & std_logic_vector(rx_arp_counter);
            when address_rx_icmp_counter =>
              latched_data <= x"0000" & std_logic_vector(rx_icmp_counter);
            when address_rx_udp_counter =>
              latched_data <= x"0000" & std_logic_vector(rx_udp_counter);

            when address_txbuffer_status =>
              latched_data <= '0' & sendpkt_busy & sendpkt_armed & '0' & txbuffer_length & txbuffer_cksum;
            when address_streampkt_csr =>
              latched_data(31 downto 24+nstream) <= ( others => '0' );
              latched_data(24+nstream-1 downto 24) <= streampkt_busy;
              latched_data(23 downto 16+nstream) <= ( others => '0' );
              latched_data(16+nstream-1 downto 16) <= streampkt_csr(16+nstream-1 downto 16);
              latched_data(15 downto 0) <= streampkt_state;
            when address_streampkt_daddr =>
              latched_data <= streampkt_daddr;
            when address_streampkt_ports =>
              latched_data <= streampkt_ports;
            when others =>
              latched_data <= x"f8f8f8f8";
--
--  udp buffers are at 0xc3008000
--
              if ( iobus.io_address(15 downto 11) = "10000" ) then
                udp_buffer_addressed(0) <= '1';
              elsif ( iobus.io_address(15 downto 11) = "10001" ) then
                udp_buffer_addressed(1) <= '1';
              elsif ( iobus.io_address(15 downto 11) = "10010" ) then
                udp_buffer_addressed(2) <= '1';
              elsif ( iobus.io_address(15 downto 11) = "10011" ) then
                udp_buffer_addressed(3) <= '1';
--
--  tx buffers are at 0xc300c000
--
              elsif ( iobus.io_address(15 downto 11) = "11000" ) then
                txbuffer_addressed <= '1';
              else

              end if;

          end case;
        end if;
      else
        iobus_ready <= '0';
        latched_data <= ( others => '0' );
        udp_buffer_addressed <= ( others => '0' );
        txbuffer_addressed <= '0';
        txbuffer_reset <= '0';
        if ( grant(4) = '1' ) then
          sendpkt_strobe <= '0';
        end if;
        if ( grant(1) = '1' ) then
          arpreq_strobe <= '0';
        end if;
        if ( grant(3) = '1' ) then
          icmpreq_strobe <= '0';
        end if;
      end if;
    end if;
  end process;

  interrupt <= xaui_int;
  matched_ip_address <= '1' when ethernet_dst_ip = my_ip_address else '0';
--
--  We don't want to catch the UDP packets that contain trigger data since
--  these are passed directly through to the trigger processor at high rates.
--
  udp_received_strobe <= '1' when crc_valid = '1' and
                                  latched_udp_enable(0) = '1' and
                                  matched_ip_address = '1' and
                                  udp_dst_port /= x"eeee"
                             else '0';
  masked_address <= iobus.io_address(31 downto 16) and address_mask;

  write_data <= txbuffer_read when txbuffer_addressed = '1' else
                udp_buffer_data(0) when udp_buffer_addressed(0) = '1' else
                udp_buffer_data(1) when udp_buffer_addressed(1) = '1' else
                udp_buffer_data(2) when udp_buffer_addressed(2) = '1' else
                udp_buffer_data(3) when udp_buffer_addressed(3) = '1' else
                latched_data;

  txbuffer_write_enable <= '1' when iobus.io_write_strobe = '1' and
                                    iobus.io_addr_strobe = '1' and
                                    masked_address = base_address and
                                    iobus.io_address(15 downto 11) = "11000"
                               else '0';

  sendpkt_busy <= txbuffer_busy or grant(4) or sendpkt_strobe;

  arpreq_busy <= arpreq_strobe or grant(1);
  icmpreq_stop_timer <= crc_valid when latched_icmp_enable(0) = '1' and
                                       icmpreq_sequence(15 downto 0) = icmp_echo_seq and
                                       icmpreq_sequence(31 downto 16) = icmp_echo_ident else '0';

  read_arp_csr <= arpreq_busy & arp_csr(30 downto 28) & sendpkt_arptab_read_strobe &
                  sendpkt_arpreq_strobe & arptab_missing & arptab_found &
                  std_logic_vector(to_unsigned(arptab_size,8)) &
                  arptab_entries & arp_csr(7 downto 0);
  arptab_index <= arp_csr(7 downto 0);
  arptab_load_ip_addr <= arp_sender_ip;
  arptab_load_hw_addr <= arp_sender_ha;
  arpreq_target_ip <= arp_lookup_ip;
  arptab_write_strobe <= arp_reply_strobe or matched_arprep_frame;
  matched_arpreq_frame <= '1' when crc_valid = '1' and latched_arp_enable(0) = '1' and arp_operation = x"0001" else '0';
  matched_arprep_frame <= '1' when crc_valid = '1' and latched_arp_enable(0) = '1' and arp_operation = x"0002" else '0';
  arp_reply_strobe <= '1' when matched_arpreq_frame = '1' and arp_matched_ip = '1' else '0';

  icmprep_strobe <= '1' when crc_valid = '1' and latched_icmp_enable(0) = '1' and icmp_type = x"08" else '0';

--
--  This process selects which ip address to look up in the arp table.
--
  process ( sendpkt_lookup_ip, icmpreq_lookup_ip, streampkt_lookup_ip, grant )
    variable lookup_ip : std_logic_vector(31 downto 0);
  begin
    lookup_ip := ( others => '0' );
    if ( grant(4) = '1' ) then
      lookup_ip := sendpkt_lookup_ip;
    elsif ( grant(3) = '1' ) then
      lookup_ip := icmpreq_lookup_ip;
    else
      for i in 0 to nstream-1 loop
        if ( grant(8+i) = '1' ) then
          lookup_ip := streampkt_lookup_ip(i);
        end if;
      end loop;
    end if;
    arptab_lookup_ip_addr <= lookup_ip;
  end process;

  masked_address <= iobus.io_address(31 downto 16) and address_mask;

  process ( xgmii_rxclk )
    variable new_txd : std_logic_vector(2*64-1 downto 0);
    variable new_txc : std_logic_vector(2*8-1 downto 0);
    variable selected : boolean;
  begin
    if ( xgmii_rxclk'event and xgmii_rxclk = '1' ) then
      selected := false;
      if ( grant(0) = '1' ) then
        txd <= arprep_dout;
        txc <= arprep_cout;
        selected := true;
      elsif ( grant(1) = '1' ) then
        txd <= arpreq_dout;
        txc <= arpreq_cout;
        selected := true;
      elsif ( grant(2) = '1' ) then
        txd <= icmprep_dout;
        txc <= icmprep_cout;
        selected := true;
      elsif ( grant(3) = '1' ) then
        txd <= icmpreq_dout;
        txc <= icmpreq_cout;
        selected := true;
      elsif ( grant(4) = '1' ) then
        txd <= sendpkt_dout;
        txc <= sendpkt_cout;
        selected := true;
      else
        for i in 0 to nstream-1 loop
          if ( grant(8+i) = '1' ) then
            txd <= streampkt_dout(i);
            txc <= streampkt_cout(i);
            selected := true;
          end if;
        end loop;
      end if;
      if ( not selected ) then
        txd <= x"0707070707070707";
        txc <= x"ff";
      end if;
      new_txd := txd & txd_pipe(txd_pipe'left downto 64);
      new_txc := txc & txc_pipe(txc_pipe'left downto 8);
      if ( txc = x"01" and txd(7 downto 0) = x"fb" ) then
        crc_clr <= '0';
        crc_en <= '1';
      elsif ( txc = x"00" ) then
        crc_clr <= '0';
        crc_en <= '1';
      else
        for i in 0 to 7 loop
          if ( new_txc(i) = '1' and crc_en = '1' ) then
            new_txc(i+4 downto i) := "10000";
            new_txd(8*i+39 downto 8*i) := x"fd" & crc;
            for j in i+5 to 15 loop
              new_txd(8*j+7 downto 8*j) := x"07";
              new_txc(j) := '1';
            end loop;
            crc_clr <= '1';
            crc_en <= '0';
            exit;
          end if;
        end loop;
      end if;
      txd_pipe <= new_txd;
      txc_pipe <= new_txc;
    end if;
  end process;

  process ( xgmii_rxclk ) begin
    if ( xgmii_rxclk'event and xgmii_rxclk = '1' ) then
      if ( udp_received_strobe = '1' ) then
        xaui_int <= '1';
        if ( udp_buffer_busy(0) = '0' ) then
          udp_buffer_busy(0) <= '1';
        elsif ( udp_buffer_busy(1) = '0' ) then
          udp_buffer_busy(1) <= '1';
        elsif ( udp_buffer_busy(2) = '0' ) then
          udp_buffer_busy(2) <= '1';
        elsif ( udp_buffer_busy(3) = '0' ) then
          udp_buffer_busy(3) <= '1';
        end if;
      elsif ( xaui_int_ack = '1' ) then
        xaui_int <= '0';
      end if;
      for i in 0 to 3 loop
        if ( udp_buffer_free(i) = '1' ) then
          udp_buffer_busy(i) <= '0';
        end if;
      end loop;

    end if;
  end process;

  xaui_reset <= xaui_csr(30);
  reset_out <= soft_reset;

--
--  This process generates arptab_read_strobe as the logical or of all the
--  requests.
--
  process ( grant,
            icmpreq_arptab_read_strobe,
            sendpkt_arptab_read_strobe,
            streampkt_arptab_read_strobe )
    variable strobe : std_logic;
  begin
    strobe := '0';
    if ( grant(4) = '1' ) then
      strobe := sendpkt_arptab_read_strobe;
    elsif ( grant(3) = '1' ) then
      strobe := icmpreq_arptab_read_strobe;
    else
      for i in 0 to streampkt_arptab_read_strobe'left loop
        if ( grant(8+i) = '1' ) then
          strobe := strobe or streampkt_arptab_read_strobe(i);
        end if;
      end loop;
    end if;
    arptab_read_strobe <= strobe;
  end process;

  g_jumpers : if ( jumpers ) generate
    my_mac_addr(3 downto 0) <= jumpered_address(3 downto 0);
    my_ip_address(3 downto 0) <= jumpered_address(3 downto 0);
  end generate;

  streampkt_gated_strobe <= xgbe_stream_strobe and streampkt_csr(16+nstream-1 downto 16);
  streampkt_gated_wren <= xgbe_stream_wren and streampkt_csr(16+nstream-1 downto 16);

  xgbe_stream_clka <= xgmii_txclk;

  xgmii_txd <= txd_pipe(63 downto 0);
  xgmii_txc <= txc_pipe(7 downto 0);

  udp_received <= udp_received_pipe(0);

end RTL;
