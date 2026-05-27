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

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library hep337dev;
use hep337dev.iobus.all;
use hep337dev.gbe.all;

entity gbe_interface is
generic (
    mac_address : string := "00:00:00:00:00:00";
    ip_address : string := "192.168.40.253";
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
    reset_done : in std_logic;
    mmcm_locked : in std_logic;
    jumpered_address : in std_logic_vector(6 downto 0);
    gmii_clk : in std_logic;
    gmii_txd : out std_logic_vector(7 downto 0);
    gmii_tx_en : out std_logic;
    gmii_tx_er : out std_logic;
    gmii_rxd : in std_logic_vector(7 downto 0);
    gmii_rx_dv : in std_logic;
    gmii_rx_er : in std_logic;
    gbe_stream_clka : out std_logic;
    gbe_stream_wren : in std_logic_vector(nstream-1 downto 0);
    gbe_stream_strobe : in std_logic_vector(nstream-1 downto 0);
    gbe_stream_data : in stream_data_array_t(nstream-1 downto 0);
    gbe_stream_free : out stream_free_array_t(nstream-1 downto 0)
  );
end gbe_interface;

architecture RTL of gbe_interface is

  component ethernet
    port (
      reset : in std_logic;
      clk : in std_logic;
      enable : in std_logic;
      din : in std_logic_vector(7 downto 0);
      saddr : out std_logic_vector(47 downto 0);
      daddr : out std_logic_vector(47 downto 0);
      frame_type : out std_logic_vector(15 downto 0);
      arp_enable : out std_logic;
      ip_enable : out std_logic;
      payload : out std_logic;
      frame_strobe : out std_logic;
      crc_valid : out std_logic
    );
  end component;

  component arpreq
    generic ( id : integer := 0 );
    port (
      reset : in std_logic;
      clk : in std_logic;
      strobe : in std_logic;
      src_ha : in std_logic_vector(47 downto 0);
      src_ip : in std_logic_vector(31 downto 0);
      target_ip : in std_logic_vector(31 downto 0);
      my_netmask : in std_logic_vector(31 downto 0);
      gw_ip_address : in std_logic_vector(31 downto 0);
      dout : out std_logic_vector(7 downto 0);
      request : out std_logic;
      enable : in std_logic_vector(3 downto 0)
    );
  end component;

  component arprep
    generic ( id : integer := 0 );
    port (
      reset : in std_logic;
      clk : in std_logic;
      strobe : in std_logic;
      src_ha : in std_logic_vector(47 downto 0);
      src_ip : in std_logic_vector(31 downto 0);
      dst_ha : in std_logic_vector(47 downto 0);
      dst_ip : in std_logic_vector(31 downto 0);
      dout : out std_logic_vector(7 downto 0);
      request : out std_logic;
      enable : in std_logic_vector(3 downto 0)
    );
  end component;

  component ip
  port (
    reset : in std_logic;
    clk : in std_logic;
    enable : in std_logic;
    din : in std_logic_vector(7 downto 0);
    ip_address : in std_logic_vector(31 downto 0);
    ip_version : out std_logic_vector(3 downto 0);
    ip_ihl: out std_logic_vector(3 downto 0);
    ip_length : out std_logic_vector(15 downto 0);
    ip_identification : out std_logic_vector(15 downto 0);
    ip_flags : out std_logic_vector(2 downto 0);
    ip_fragment : out std_logic_vector(12 downto 0);
    ip_ttl : out std_logic_vector(7 downto 0);
    ip_protocol : out std_logic_vector(7 downto 0);
    ip_saddr : out std_logic_vector(31 downto 0);
    ip_daddr : out std_logic_vector(31 downto 0);
    header_cksum_valid : out std_logic;
    data_cksum_valid : out std_logic;
    buffer_clear : out std_logic;
    icmp_enable : out std_logic;
    udp_enable : out std_logic;
    payload : out std_logic;
    matched : out std_logic
  );
  end component;

  component icmp
  port (
    reset : in std_logic;
    clk : in std_logic;
    enable : in std_logic;
    din : in std_logic_vector(7 downto 0);
    icmp_type : out std_logic_vector(7 downto 0);
    icmp_code : out std_logic_vector(7 downto 0);
    echo_ident : out std_logic_vector(15 downto 0);
    echo_seq : out std_logic_vector(15 downto 0);
    echo_timestamp : out std_logic_vector(15 downto 0);
    icmp_data_we : out std_logic
  );
  end component;

  component udp
  port (
    reset : in std_logic;
    clk : in std_logic;
    enable : in std_logic;
    din : in std_logic_vector(7 downto 0);
    src_port : out std_logic_vector(15 downto 0);
    dst_port : out std_logic_vector(15 downto 0);
    length : out std_logic_vector(15 downto 0);
    udp_data_we : out std_logic;
    udp_buffer_clear : out std_logic
  );
  end component;

  component udpbuffer
  port (
    reset : in std_logic;
    clka : in std_logic;
    wea : in std_logic;
    dina : in std_logic_vector(7 downto 0);
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

  component txether
    port (
      reset : in std_logic;
      clk : in std_logic;
      saddr : in std_logic_vector(47 downto 0);
      daddr : in std_logic_vector(47 downto 0);
      sel : in std_logic_vector(15 downto 0);
      enable : out std_logic_vector(3 downto 0);
      ip_header : out std_logic;
      header : out std_logic;
      crc : out std_logic;
      ifg : out std_logic;
      din : in std_logic_vector(7 downto 0);
      dout : out std_logic_vector(7 downto 0);
      crc_out : out std_logic_vector(7 downto 0);
      txen : out std_logic
    );
  end component;

  component ipheader
    port (
      reset : in std_logic;
      clk : in std_logic;
      strobe : in std_logic;
      length : in std_logic_vector(15 downto 0);
      protocol : in std_logic_vector(7 downto 0);
      saddr : in std_logic_vector(31 downto 0);
      daddr : in std_logic_vector(31 downto 0);
      dout : out std_logic_vector(7 downto 0);
      checksum : out std_logic_vector(15 downto 0)
    );
  end component;

  component txbuffer
    port (
      reset : in std_logic;
      clka : in std_logic;
      ena : in std_logic;
      wea : in std_logic_vector(3 downto 0);
      addra : in std_logic_vector(8 downto 0);
      dina : in std_logic_vector(31 downto 0);
      douta : out std_logic_vector(31 downto 0);
      cksum : out std_logic_vector(15 downto 0);
      clkb : in std_logic;
      addrb : in std_logic_vector(10 downto 0);
      doutb : out std_logic_vector(7 downto 0)
    );
  end component;

  component icmprep
  generic ( id : integer := 0 );
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    din : in std_logic_vector(7 downto 0);
    wr_en : in std_logic;
    clear : in std_logic;
    protocol : out std_logic_vector(7 downto 0);
    length : out std_logic_vector(15 downto 0);
    ip_header_cksum : in std_logic_vector(15 downto 0);
    dout : out std_logic_vector(7 downto 0);
    request : out std_logic;
    enable : in std_logic_vector(3 downto 0)
  );
  end component;

  component sendpkt
    generic ( id : integer := 0 );
    port (
      reset : in std_logic;
      clk : in std_logic;
      strobe : in std_logic;
      saddr : in std_logic_vector(31 downto 0);
      daddr : in std_logic_vector(31 downto 0);
      sport : in std_logic_vector(15 downto 0);
      dport : in std_logic_vector(15 downto 0);
      arp_strobe : out std_logic;
      arptab_found : in std_logic;
      arptab_missing : in std_logic;
      issue_arp_request : out std_logic;
      protocol : out std_logic_vector(7 downto 0);
      length : out std_logic_vector(15 downto 0);
      ip_header_checksum : in std_logic_vector(15 downto 0);
      udp_buffer_checksum : in std_logic_vector(15 downto 0);
      buffer_length : in std_logic_vector(13 downto 0);
      addr : out std_logic_vector(10 downto 0);
      din : in std_logic_vector(7 downto 0);
      dout : out std_logic_vector(7 downto 0);
      request : out std_logic;
      enable : in std_logic_vector(3 downto 0)
    );
  end component;

  component gbe_stream_buffer
  port (
    rst : in std_logic;
    clk_a : in std_logic;
    wen_a : in std_logic;
    din_a : in std_logic_vector(31 downto 0);
    strobe_a : in std_logic;
    clk_b : in std_logic;
    dv_b : out std_logic;
    dout_b : out std_logic_vector(7 downto 0);
    rden_b : in std_logic;
    strobe_b : out std_logic;
    cksum : out std_logic_vector(15 downto 0);
    length : out std_logic_vector(15 downto 0);
    free : out std_logic_vector(15 downto 0);
    lost : out std_logic_vector(15 downto 0)
  );
  end component;

  component streampkt
    generic ( id : integer := 0 );
    port (
      reset : in std_logic;
      clk : in std_logic;
      strobe : in std_logic;
      busy : out std_logic;
      saddr : in std_logic_vector(31 downto 0);
      daddr : in std_logic_vector(31 downto 0);
      sport : in std_logic_vector(15 downto 0);
      dport : in std_logic_vector(15 downto 0);
      buffer_length : in std_logic_vector(15 downto 0);
      buffer_cksum : in std_logic_vector(15 downto 0);
      buffer_rden : out std_logic;
      buffer_data : in std_logic_vector(7 downto 0);
      arp_strobe : out std_logic;
      arptab_found : in std_logic;
      arptab_missing : in std_logic;
      issue_arp_request : out std_logic;
      protocol : out std_logic_vector(7 downto 0);
      length : out std_logic_vector(15 downto 0);
      dout : out std_logic_vector(7 downto 0);
      request : out std_logic;
      enable : in std_logic_vector(3 downto 0)
    );
  end component;

  component arp
    port (
      reset : in std_logic;
      clk : in std_logic;
      enable : in std_logic;
      din : in std_logic_vector(7 downto 0);
      ip_address : in std_logic_vector(31 downto 0);
      hardware_type : out std_logic_vector(15 downto 0);
      protocol_type : out std_logic_vector(15 downto 0);
      hlen : out std_logic_vector(7 downto 0);
      plen : out std_logic_vector(7 downto 0);
      operation : out std_logic_vector(15 downto 0);
      sender_ha : out std_logic_vector(47 downto 0);
      sender_ip : out std_logic_vector(31 downto 0);
      target_ha : out std_logic_vector(47 downto 0);
      target_ip : out std_logic_vector(31 downto 0);
      matched : out std_logic
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

  constant base_address : std_logic_vector(15 downto 0) := x"c100";
  constant address_mask : std_logic_vector(15 downto 0) := x"ffff";
  signal masked_address : std_logic_vector(15 downto 0);

  constant address_gbe_csr : std_logic_vector(15 downto 0) := x"0000";
  constant address_mac_addr_low : std_logic_vector(15 downto 0) := x"0018";
  constant address_mac_addr_high : std_logic_vector(15 downto 0) := x"001c";
  constant address_ip_addr : std_logic_vector(15 downto 0) := x"0020";
  constant address_netmask : std_logic_vector(15 downto 0) := x"0024";
  constant address_gateway : std_logic_vector(15 downto 0) := x"0028";
  constant address_ip_daddr : std_logic_vector(15 downto 0) := x"002c";
  constant address_arp_csr : std_logic_vector(15 downto 0) := x"0044";
  constant address_arp_lookup_ip : std_logic_vector(15 downto 0) := x"0048";
  constant address_arp_table_ip : std_logic_vector(15 downto 0) := x"004c";
  constant address_arp_table_ha_low : std_logic_vector(15 downto 0) := x"0050";
  constant address_arp_table_ha_high : std_logic_vector(15 downto 0) := x"0054";
  constant address_arp_table_refcount : std_logic_vector(15 downto 0) := x"0058";
  constant address_udp_buffer : std_logic_vector(15 downto 0) := x"0060";
  constant address_sendpkt_daddr : std_logic_vector(15 downto 0) := x"0064";
  constant address_sendpkt_ports : std_logic_vector(15 downto 0) := x"0068";

  constant address_streampkt_csr : std_logic_vector(15 downto 0) := x"0070";
  constant address_streampkt_status : std_logic_vector(15 downto 0) := x"0074";
  constant address_streampkt_buffer : std_logic_vector(15 downto 0) := x"0078";
  constant address_streampkt_daddr_0 : std_logic_vector(15 downto 0) := x"0080";
  constant address_streampkt_daddr_1 : std_logic_vector(15 downto 0) := x"0084";
  constant address_streampkt_ports_0 : std_logic_vector(15 downto 0) := x"0090";
  constant address_streampkt_ports_1 : std_logic_vector(15 downto 0) := x"0094";

  constant address_source_ha_low : std_logic_vector(15 downto 0) := x"0100";
  constant address_source_ha_high : std_logic_vector(15 downto 0) := x"0104";
  constant address_target_ha_low : std_logic_vector(15 downto 0) := x"0108";
  constant address_target_ha_high : std_logic_vector(15 downto 0) := x"010c";
  constant address_frame_type : std_logic_vector(15 downto 0) := x"0110";
  constant address_txbuffer_status : std_logic_vector(15 downto 0) := x"7c00";

  signal gbe_csr : std_logic_vector(31 downto 0);
  signal gbe_int : std_logic := '0';
  signal gbe_int_ack : std_logic := '0';

  signal ip_enable : std_logic;
  signal ip_buffer_clear : std_logic;
  signal ip_payload : std_logic;
  signal ip_version : std_logic_vector(3 downto 0);
  signal ip_ihl : std_logic_vector(3 downto 0);
  signal ip_length : std_logic_vector(15 downto 0);
  signal ip_ident : std_logic_vector(15 downto 0);
  signal ip_flags : std_logic_vector(2 downto 0);
  signal ip_fragment : std_logic_vector(12 downto 0);
  signal ip_ttl : std_logic_vector(7 downto 0);
  signal ip_protocol : std_logic_vector(7 downto 0);
  signal ip_header_cksum_valid : std_logic;
  signal ip_data_cksum_valid : std_logic;
  signal ip_daddr : std_logic_vector(31 downto 0);
  signal ip_saddr : std_logic_vector(31 downto 0) := x"00000000";
  signal ip_header_enable : std_logic;
  signal ip_header_txd : std_logic_vector(7 downto 0);
  signal ip_header_cksum : std_logic_vector(15 downto 0);
  signal matched_ip_address : std_logic;

  signal udp_enable : std_logic;
  signal udp_src_port : std_logic_vector(15 downto 0);
  signal udp_dst_port : std_logic_vector(15 downto 0);
  signal udp_length : std_logic_vector(15 downto 0);
  signal udp_buffer_clear : std_logic;
  signal udp_buffer_addressed : std_logic_vector(1 downto 0);
  signal udp_buffer_read_enable : std_logic_vector(1 downto 0);
  signal udp_payload : std_logic;
  signal udp_write : std_logic_vector(1 downto 0);
  signal udp_reset : std_logic_vector(1 downto 0);
  signal udp_buffer_busy : std_logic_vector(1 downto 0) := ( others => '0' );
  signal r_udp_buffer_busy : std_logic_vector(1 downto 0) := ( others => '0' );
  signal udp_buffer_free : std_logic_vector(1 downto 0) := ( others => '0' );

  type udp_buffer_data_t is array(1 downto 0) of std_logic_vector(31 downto 0);
  signal udp_buffer_data : udp_buffer_data_t;
  signal udp_received_strobe : std_logic;

  signal frame_strobe : std_logic;
  signal frame_crc_valid : std_logic;
  signal frame_type : std_logic_vector(15 downto 0);

  signal arp_enable : std_logic;
  signal arp_hardware_type : std_logic_vector(15 downto 0);
  signal arp_protocol_type : std_logic_vector(15 downto 0);
  signal arp_hlen : std_logic_vector(7 downto 0);
  signal arp_plen : std_logic_vector(7 downto 0);
  signal arp_operation : std_logic_vector(15 downto 0);
  signal arp_sender_ha : std_logic_vector(47 downto 0);
  signal arp_sender_ip : std_logic_vector(31 downto 0);
  signal arp_target_ha : std_logic_vector(47 downto 0);
  signal arp_target_ip : std_logic_vector(31 downto 0);
  signal matched_arpreq_address : std_logic;
  signal arp_csr : std_logic_vector(31 downto 0);
  signal arp_lookup_ip : std_logic_vector(31 downto 0);

  constant arptab_size : natural := 16;

  signal arptab_found : std_logic;
  signal arptab_lookup_ip_addr : std_logic_vector(31 downto 0);
  signal arptab_target_ip_addr : std_logic_vector(31 downto 0);
  signal arptab_lookup_hw_addr : std_logic_vector(47 downto 0);
  signal arptab_read_ip_addr : std_logic_vector(31 downto 0);
  signal arptab_read_hw_addr : std_logic_vector(47 downto 0);
  signal arptab_read_refcount : std_logic_vector(31 downto 0);
  signal arptab_entries : std_logic_vector(7 downto 0);
  signal arptab_read_strobe : std_logic := '0';
  signal arptab_write_strobe : std_logic := '0';
  signal arptab_missing : std_logic;
  signal arptab_load_ip_addr : std_logic_vector(31 downto 0);
  signal arptab_load_hw_addr : std_logic_vector(47 downto 0);
  signal arp_reply_strobe : std_logic := '0';
  signal arp_request_strobe : std_logic;
  signal arpreq_dout : std_logic_vector(7 downto 0);
  signal arprep_dout : std_logic_vector(7 downto 0);

  signal sendpkt_arptab_read_strobe : std_logic := '0';
  signal sendpkt_arpreq_strobe : std_logic;
  signal streampkt_arptab_read_strobe : std_logic_vector(nstream-1 downto 0) := ( others => '0' );
  signal streampkt_arpreq_strobe : std_logic_vector(nstream-1 downto 0);
  signal matched_arpreq_frame : std_logic := '0';
  signal matched_arprep_frame : std_logic := '0';
  signal matched_icmpreq_frame : std_logic := '0';
  signal matched_icmprep_frame : std_logic := '0';
  signal matched_udp_frame : std_logic := '0';

  signal ethernet_payload : std_logic;
  signal ethernet_source_ha : std_logic_vector(47 downto 0);
  signal ethernet_target_ha : std_logic_vector(47 downto 0);

  signal read_arp_csr : std_logic_vector(31 downto 0);
  signal arptab_index : std_logic_vector(7 downto 0);

  type streampkt_dout_t is array(nstream-1 downto 0) of std_logic_vector(7 downto 0);
  signal streampkt_dout : streampkt_dout_t;

  signal sendpkt_strobe : std_logic := '0';
  signal sendpkt_daddr : std_logic_vector(31 downto 0) := x"00000000";
  signal sendpkt_ports : std_logic_vector(31 downto 0) := x"00000000";
  signal sendpkt_dout : std_logic_vector(7 downto 0);

  signal streampkt_csr : std_logic_vector(31 downto 0);
  type streampkt_daddr_t is array(nstream-1 downto 0) of std_logic_vector(31 downto 0);
  signal streampkt_daddr : streampkt_daddr_t;
  type streampkt_ports_t is array(nstream-1 downto 0) of std_logic_vector(31 downto 0);
  signal streampkt_ports : streampkt_ports_t;

  signal streampkt_buffer_we : std_logic;
  signal streampkt_read_enable : std_logic;
  type streampkt_protocol_t is array(nstream-1 downto 0) of std_logic_vector(7 downto 0);
  signal streampkt_protocol : streampkt_protocol_t := ( others => ( others => '0' ) );
  type streampkt_buffer_length_t is array(nstream-1 downto 0) of std_logic_vector(15 downto 0);
  signal streampkt_buffer_length : streampkt_buffer_length_t := ( others => x"0028" );
  type streampkt_buffer_cksum_t is array(nstream-1 downto 0) of std_logic_vector(15 downto 0);
  signal streampkt_buffer_cksum : streampkt_buffer_cksum_t := ( others => ( others => '0' ) );
  signal streampkt_busy : std_logic_vector(nstream-1 downto 0);
  signal streampkt_strobe : std_logic_vector(nstream-1 downto 0) := ( others => '0' );
  signal streampkt_data_available : std_logic_vector(nstream-1 downto 0) := ( others => '0' );
  signal streampkt_done : std_logic_vector(nstream-1 downto 0) := ( others => '0' );
  type streampkt_buffer_data_t is array(nstream-1 downto 0) of std_logic_vector(7 downto 0);
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

  signal icmp_reply_strobe : std_logic := '0';
  signal icmp_reply_protocol : std_logic_vector(7 downto 0);
  signal icmp_reply_length : std_logic_vector(15 downto 0);
  signal icmp_enable : std_logic;
  signal icmp_type : std_logic_vector(7 downto 0);
  signal icmp_code : std_logic_vector(7 downto 0);
  signal icmp_echo_timestamp : std_logic_vector(15 downto 0);
  signal icmp_echo_ident : std_logic_vector(15 downto 0);
  signal icmp_echo_seq : std_logic_vector(15 downto 0);
  signal icmprep_dout : std_logic_vector(7 downto 0);
  signal icmp_data_we : std_logic := '0';
  signal icmp_buffer_clear : std_logic;

  signal gw_ip_address : std_logic_vector(31 downto 0) := string_to_ipaddr(gateway);
  signal my_netmask : std_logic_vector(31 downto 0) := string_to_ipaddr(netmask);
  signal my_ip_address : std_logic_vector(31 downto 0) := string_to_ipaddr(ip_address);
  signal my_mac_addr : std_logic_vector(47 downto 0) := string_to_hwaddr(mac_address);

  signal ethernet_crc : std_logic;
  signal ethernet_ifg : std_logic;
  signal ethernet_header : std_logic;
  signal dout : std_logic_vector(7 downto 0);
  signal den : std_logic;
  signal ethernet_dout : std_logic_vector(7 downto 0);
  signal ethernet_crc_out : std_logic_vector(7 downto 0);
  signal arpreq_target_ip : std_logic_vector(31 downto 0);
  signal ethernet_dest_ip : std_logic_vector(31 downto 0);
  signal sendpkt_length : std_logic_vector(15 downto 0);
  signal sendpkt_protocol : std_logic_vector(7 downto 0);


  signal length : std_logic_vector(15 downto 0);
  signal protocol : std_logic_vector(7 downto 0);
  signal ethernet_dest_ha : std_logic_vector(47 downto 0);
  signal eth_tx_source : std_logic_vector(15 downto 0) := ( others => '0' );
  signal eth_tx_enable : std_logic_vector(3 downto 0);

  signal latched_data : std_logic_vector(31 downto 0);

  signal txbuffer_write_enable : std_logic;
  signal txbuffer_read : std_logic_vector(31 downto 0);
  signal txbuffer_cksum : std_logic_vector(15 downto 0);
  signal txbuffer_length : std_logic_vector(13 downto 0);
  signal txbuffer_reset : std_logic;
  signal txbuffer_addressed : std_logic;
  signal txbuffer_addrb : std_logic_vector(10 downto 0);
  signal txbuffer_doutb : std_logic_vector(7 downto 0);

begin

  ethernet_imp : ethernet
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    enable => gmii_rx_dv,
    din => gmii_rxd,
    saddr => ethernet_source_ha,
    daddr => ethernet_target_ha,
    frame_type => frame_type,
    arp_enable => arp_enable,
    ip_enable => ip_enable,
    payload => ethernet_payload,
    frame_strobe => frame_strobe,
    crc_valid => frame_crc_valid
  );

  arp_imp : arp
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    enable => arp_enable,
    din => gmii_rxd,
    ip_address => my_ip_address,
    hardware_type => arp_hardware_type,
    protocol_type => arp_protocol_type,
    hlen => arp_hlen,
    plen => arp_plen,
    operation => arp_operation,
    sender_ha => arp_sender_ha,
    sender_ip => arp_sender_ip,
    target_ha => arp_target_ha,
    target_ip => arp_target_ip,
    matched => matched_arpreq_address
  );

  arptab_imp : arptab
  generic map ( size => arptab_size )
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk, 
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

  ip_imp : ip
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    enable => ip_enable,
    din => gmii_rxd,
    ip_address => my_ip_address,
    ip_version => ip_version,
    ip_ihl => ip_ihl,
    ip_length => ip_length,
    ip_identification => ip_ident,
    ip_flags => ip_flags,
    ip_fragment => ip_fragment,
    ip_ttl => ip_ttl,
    ip_protocol => ip_protocol,
    ip_saddr => ip_saddr,
    ip_daddr => ip_daddr,
    header_cksum_valid => ip_header_cksum_valid,
    data_cksum_valid => ip_data_cksum_valid,
    buffer_clear => ip_buffer_clear,
    icmp_enable => icmp_enable,
    udp_enable => udp_enable,
    payload => ip_payload,
    matched => matched_ip_address
  );

  icmp_imp : icmp
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    enable => icmp_enable,
    din => gmii_rxd,
    icmp_type => icmp_type,
    icmp_code => icmp_code,
    echo_ident => icmp_echo_ident,
    echo_seq => icmp_echo_seq,
    echo_timestamp => icmp_echo_timestamp,
    icmp_data_we => icmp_data_we
  );

  udp_imp : udp
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    enable => udp_enable,
    din => gmii_rxd,
    src_port => udp_src_port,
    dst_port => udp_dst_port,
    length => udp_length,
    udp_data_we => udp_payload,
    udp_buffer_clear => udp_buffer_clear
  );

--  udp_write(0) <= udp_payload;
--  udp_write(1) <= udp_payload;
--  udp_reset(0) <= udp_buffer_clear;
--  udp_reset(1) <= udp_buffer_clear;

--  process ( udp_buffer_clear, udp_payload, udp_buffer_busy ) begin
--    if ( udp_buffer_busy(0) = '0' ) then
--      udp_reset(0) <= udp_buffer_clear;
--      udp_write(0) <= udp_payload;
--    elsif ( udp_buffer_busy(1) = '0' ) then
--      udp_reset(1) <= udp_buffer_clear;
--      udp_write(1) <= udp_payload;
--    end if;
--  end process;

--  udp_reset(0) <= udp_buffer_clear when udp_buffer_busy(0) = '0' else udp_reset(0);
--  udp_write(0) <= udp_payload when udp_buffer_busy(0) = '0' else udp_write(0);
--  udp_reset(1) <= udp_buffer_clear when udp_buffer_busy(1) = '0' else udp_reset(1);
--  udp_write(1) <= udp_payload when udp_buffer_busy(1) = '0' else udp_write(1);

  gbuf : for i in 0 to 1 generate
    udpbuf_imp : udpbuffer
    port map (
      reset => udp_reset(i),
      clka => gmii_clk,
      wea => udp_write(i),
      dina => gmii_rxd,
      saddr => ip_saddr,
      daddr => ip_daddr,
      sport => udp_src_port,
      dport => udp_dst_port,
      length => udp_length,
      clkb => busclk,
      enb => udp_buffer_read_enable(i),
      addrb => iobus.io_address(10 downto 2),
      doutb => udp_buffer_data(i)
    );
  end generate;


  tx_imp : txether
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    saddr => my_mac_addr,
    daddr => ethernet_dest_ha,
    sel => eth_tx_source,
    enable => eth_tx_enable,
    ip_header => ip_header_enable,
    header => ethernet_header,
    crc => ethernet_crc,
    ifg => ethernet_ifg,
    din => dout,
    dout => ethernet_dout,
    crc_out => ethernet_crc_out,
    txen => den
  );

  ipheader_imp : ipheader
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    strobe => ip_header_enable,
    length => length,
    protocol => protocol,
    saddr => my_ip_address,
    daddr => ethernet_dest_ip,
    dout => ip_header_txd,
    checksum => ip_header_cksum
  );

  arprep_imp : arprep
  generic map ( id => 1 )
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    strobe => arp_reply_strobe,
    src_ha => my_mac_addr,
    src_ip => my_ip_address,
    dst_ha => arp_sender_ha,
    dst_ip => arp_sender_ip,
    dout => arprep_dout,
    request => eth_tx_source(1),
    enable => eth_tx_enable
  );

  arpreq_imp : arpreq
  generic map ( id => 2 )
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    strobe => arp_request_strobe,
    src_ha => my_mac_addr,
    src_ip => my_ip_address,
    target_ip => arpreq_target_ip,
    my_netmask => my_netmask,
    gw_ip_address => gw_ip_address,
    dout => arpreq_dout,
    request => eth_tx_source(2),
    enable => eth_tx_enable
  );

  icmprep_imp : icmprep
  generic map ( id => 4 )
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    strobe => icmp_reply_strobe,
    din => gmii_rxd,
    wr_en => icmp_data_we,
    clear => icmp_buffer_clear,
    protocol => icmp_reply_protocol,
    length => icmp_reply_length,
    ip_header_cksum => ip_header_cksum,
    dout => icmprep_dout,
    request => eth_tx_source(4),
    enable => eth_tx_enable
  );

  txbuffer_imp : txbuffer
  port map (
    reset => txbuffer_reset,
    clka => busclk,
    ena => txbuffer_write_enable,
    wea => iobus.io_byte_enable, 
    addra => iobus.io_address(10 downto 2),
    dina => iobus.io_write_data,
    douta => txbuffer_read,
    cksum => txbuffer_cksum,
    clkb => gmii_clk,
    addrb => txbuffer_addrb,
    doutb => txbuffer_doutb
  );

  sendpkt_imp : sendpkt
  generic map ( id => 5 )
  port map (
    reset => gbe_csr(30),
    clk => gmii_clk,
    strobe => sendpkt_strobe,
    saddr => my_ip_address,
    daddr => sendpkt_daddr,
    sport => sendpkt_ports(31 downto 16),
    dport => sendpkt_ports(15 downto 0),
    arp_strobe => sendpkt_arptab_read_strobe,
    arptab_found => arptab_found,
    arptab_missing => arptab_missing,
    issue_arp_request => sendpkt_arpreq_strobe,
    protocol => sendpkt_protocol,
    length => sendpkt_length,
    ip_header_checksum => ip_header_cksum,
    udp_buffer_checksum => txbuffer_cksum,
    buffer_length => txbuffer_length,
    addr => txbuffer_addrb,
    din => txbuffer_doutb,
    dout => sendpkt_dout,
    request => eth_tx_source(5),
    enable => eth_tx_enable
  );

  g_stream : for i in 0 to nstream-1 generate
    sb_imp : gbe_stream_buffer
    port map (
      rst => gbe_csr(30),
      clk_a => gmii_clk,
      wen_a => streampkt_gated_wren(i),
      strobe_a => streampkt_gated_strobe(i),
      din_a => gbe_stream_data(i),

      clk_b => gmii_clk,
      dv_b => streampkt_data_available(i),
      dout_b => streampkt_buffer_data(i),
      rden_b => streampkt_buffer_rden(i),
      strobe_b => streampkt_done(i),
      cksum => streampkt_buffer_cksum(i),
      length => streampkt_buffer_length(i),
      free => streampkt_buffer_free(i),
      lost => streampkt_lost_packets(i)
    );
    gbe_stream_free(i) <= streampkt_buffer_free(i);

    streampkt_imp : streampkt
    generic map ( id => 8+i )
    port map (
      reset => gbe_csr(30),
      clk => gmii_clk,
      strobe => streampkt_strobe(i),
      busy => streampkt_busy(i),
      saddr => my_ip_address,
      daddr => streampkt_daddr(i),
      sport => streampkt_ports(i)(31 downto 16),
      dport => streampkt_ports(i)(15 downto 0),
      buffer_length => streampkt_buffer_length(i),
      buffer_cksum => streampkt_buffer_cksum(i),
      buffer_rden => streampkt_buffer_rden(i),
      buffer_data => streampkt_buffer_data(i),
      arp_strobe => streampkt_arptab_read_strobe(i),
      arptab_found => arptab_found,
      arptab_missing => arptab_missing,
      issue_arp_request => streampkt_arpreq_strobe(i),
      protocol => streampkt_protocol(i),
      length => streampkt_length(i),
      dout => streampkt_dout(i),
      request => eth_tx_source(8+i),
      enable => eth_tx_enable
    );
  end generate;

  process ( busclk ) begin
    if ( busclk'event and busclk = '1' ) then
      r_udp_buffer_busy <= udp_buffer_busy;
      if ( gbe_int = '0' ) then
        gbe_int_ack  <= '0';
      end if;
      if ( r_udp_buffer_busy(0) = '0' ) then
        udp_buffer_free(0) <= '0';
      end if;
      if ( r_udp_buffer_busy(1) = '0' ) then
        udp_buffer_free(1) <= '0';
      end if;

      if ( iobus.io_addr_strobe = '1' and masked_address = base_address ) then
        iobus_ready <= '1';
        if ( iobus.io_write_strobe = '1' ) then
          case iobus.io_address(15 downto 0) is
            when address_gbe_csr =>
              gbe_csr <= iobus.io_write_data;
              if ( gbe_int = '1' and iobus.io_write_data(16) = '1' ) then
                gbe_int_ack <= '1';
              end if;
            when address_ip_addr =>
              my_ip_address(31 downto 4) <= iobus.io_write_data(31 downto 4);
              if ( not jumpers ) then
                my_ip_address(3 downto 0) <= iobus.io_write_data(3 downto 0);
              end if;
            when address_arp_lookup_ip =>
              arp_lookup_ip <= iobus.io_write_data;
            when address_arp_csr =>
              arp_csr <= iobus.io_write_data;
            when address_netmask =>
              my_netmask <= iobus.io_write_data;
            when address_gateway =>
              gw_ip_address <= iobus.io_write_data;
            when address_sendpkt_ports =>
              sendpkt_ports <= iobus.io_write_data;
            when address_udp_buffer =>
              udp_buffer_free <= iobus.io_write_data(1 downto 0);
            when address_sendpkt_daddr =>
              sendpkt_daddr <= iobus.io_write_data;
            when address_streampkt_csr =>
              streampkt_csr <= iobus.io_write_data;
            when address_streampkt_ports_0 =>
              streampkt_ports(0) <= iobus.io_write_data;
            when address_streampkt_ports_1 =>
              streampkt_ports(1) <= iobus.io_write_data;
            when address_streampkt_daddr_0 =>
              streampkt_daddr(0) <= iobus.io_write_data;
            when address_streampkt_daddr_1 =>
              streampkt_daddr(1) <= iobus.io_write_data;
            when address_txbuffer_status =>
              txbuffer_reset <= iobus.io_write_data(31);
              sendpkt_strobe <= iobus.io_write_data(30);
              txbuffer_length <= iobus.io_write_data(29 downto 16);
            when others =>

          end case;
        end if;

        if ( iobus.io_read_strobe = '1' ) then
          case iobus.io_address(15 downto 0) is
            when address_gbe_csr =>
              latched_data <= gbe_csr(31 downto 30) &
                              reset_done & mmcm_locked &
                              gbe_csr(27 downto 17) & gbe_int &
                              gbe_csr(15 downto 7) & jumpered_address;
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
            when address_udp_buffer =>
              latched_data(31 downto 2) <= ( others => '0' );
              latched_data(1 downto 0) <= udp_buffer_busy;
            when address_sendpkt_daddr =>
              latched_data <= sendpkt_daddr;
            when address_sendpkt_ports =>
              latched_data <= sendpkt_ports;
            when address_streampkt_csr =>
              latched_data(31 downto 24+nstream) <= ( others => '0' );
              latched_data(24+nstream-1 downto 24) <= streampkt_busy;
              latched_data(23 downto 16+nstream) <= ( others => '0' );
              latched_data(16+nstream-1 downto 16) <= streampkt_csr(16+nstream-1 downto 16);
              latched_data(15 downto 0) <= streampkt_csr(15 downto 0);
            when address_streampkt_daddr_0 =>
              latched_data <= streampkt_daddr(0);
            when address_streampkt_daddr_1 =>
              latched_data <= streampkt_daddr(1);
            when address_streampkt_ports_0 =>
              latched_data <= streampkt_ports(0);
            when address_streampkt_ports_1 =>
              latched_data <= streampkt_ports(1);
            when address_streampkt_buffer =>
              latched_data <= streampkt_buffer_cksum(0) & streampkt_buffer_length(0);
            when address_streampkt_status =>
              latched_data <= streampkt_buffer_free(0) & streampkt_lost_packets(0);
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
            when address_frame_type =>
              latched_data <= x"0000" & frame_type;
            when address_txbuffer_status =>
              latched_data <= "00" & txbuffer_length & txbuffer_cksum;
            when others =>
              latched_data <= x"f8f8f8f8";
--
--  udp buffers are at 0xc1008000
--
              if ( iobus.io_address(15 downto 11) = "10000" ) then
                udp_buffer_addressed(0) <= '1';
              elsif ( iobus.io_address(15 downto 11) = "10001" ) then
                udp_buffer_addressed(1) <= '1';
--
--  tx buffers are at 0xc100c000
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
        sendpkt_strobe <= '0';
      end if;
    end if;
  end process;

  process ( gmii_clk ) begin
    if ( gmii_clk'event and gmii_clk = '1' ) then
      if ( gbe_csr(30) = '1' ) then
        gbe_int <= '0';
      else
        if ( udp_received_strobe = '1' ) then
          gbe_int <= '1';
          if ( udp_buffer_busy(0) = '0' ) then
            udp_buffer_busy(0) <= '1';
          elsif ( udp_buffer_busy(1) = '0' ) then
            udp_buffer_busy(1) <= '1';
          end if;
        elsif ( gbe_int_ack = '1' ) then
          gbe_int <= '0';
        end if;
      end if;
      if ( udp_buffer_free(0) = '1' ) then
        udp_buffer_busy(0) <= '0';
--        udp_reset(0) <= udp_buffer_clear;
--        udp_write(0) <= udp_payload;
      end if;
      if ( udp_buffer_free(1) = '1' ) then
        udp_buffer_busy(1) <= '0';
--        udp_reset(1) <= udp_buffer_clear;
--        udp_write(1) <= udp_payload;
      end if;

    end if;
  end process;

  reset_out <= gbe_csr(31);

--  udp_reset(0) <= udp_buffer_clear when udp_buffer_busy(0) = '0' else udp_reset(0);
--  udp_write(0) <= udp_payload when udp_buffer_busy(0) = '0' else udp_write(0);
--  udp_reset(1) <= udp_buffer_clear when udp_buffer_busy(1) = '0' else udp_reset(1);
--  udp_write(1) <= udp_payload when udp_buffer_busy(1) = '0' else udp_write(1);
  udp_reset(0) <= udp_buffer_clear when udp_buffer_busy(0) = '0' else '0';
  udp_write(0) <= udp_payload when udp_buffer_busy(0) = '0' else '0';
  udp_reset(1) <= udp_buffer_clear when udp_buffer_busy(1) = '0' else '0';
  udp_write(1) <= udp_payload when udp_buffer_busy(1) = '0' else '0';

  masked_address <= iobus.io_address(31 downto 16) and address_mask;
  udp_buffer_read_enable(0) <= '1' when iobus.io_addr_strobe = '1' and
                                        masked_address = base_address and 
                                        iobus.io_address(15 downto 11) = "10000"
                                   else '0';
  udp_buffer_read_enable(1) <= '1' when iobus.io_addr_strobe = '1' and
                                        masked_address = base_address and 
                                        iobus.io_address(15 downto 11) = "10001"
                                   else '0';

  txbuffer_write_enable <= '1' when iobus.io_write_strobe = '1' and
                                    iobus.io_addr_strobe = '1' and
                                    masked_address = base_address and
                                    iobus.io_address(15 downto 11) = "11000"
                               else '0';

  streampkt_buffer_we <= '1' when iobus.io_write_strobe = '1' and
                                  iobus.io_addr_strobe = '1' and
                                  masked_address = base_address and
                                  iobus.io_address(15 downto 0) = address_streampkt_buffer
                             else '0';

  streampkt_gated_strobe <= gbe_stream_strobe and streampkt_csr(16+nstream-1 downto 16);
  streampkt_gated_wren <= gbe_stream_wren and streampkt_csr(16+nstream-1 downto 16);

  write_data <= txbuffer_read when txbuffer_addressed = '1' else
                udp_buffer_data(0) when udp_buffer_addressed(0) = '1' else
                udp_buffer_data(1) when udp_buffer_addressed(1) = '1' else
                latched_data;

  read_arp_csr <= arp_csr(31 downto 28) & sendpkt_arptab_read_strobe &
                  sendpkt_arpreq_strobe & arptab_missing & arptab_found &
                  std_logic_vector(to_unsigned(arptab_size,8)) &
                  arptab_entries & arp_csr(7 downto 0);

  arptab_index <= arp_csr(7 downto 0);
  arptab_load_ip_addr <= arp_sender_ip;
  arptab_load_hw_addr <= arp_sender_ha;
  matched_arpreq_frame <= '1' when frame_strobe = '1' and arp_enable = '1' and arp_operation = x"0001" else '0';
  matched_arprep_frame <= '1' when frame_strobe = '1' and arp_enable = '1' and arp_operation = x"0002" else '0';
  matched_icmprep_frame <= '1' when frame_strobe = '1' and ip_enable = '1' and ip_protocol = x"01" and icmp_type = x"00" else '0';
  matched_icmpreq_frame <= '1' when frame_strobe = '1' and ip_enable = '1' and ip_protocol = x"01" and icmp_type = x"08" else '0';
  matched_udp_frame <= '1' when frame_strobe = '1' and ip_enable = '1' and ip_protocol = x"11" else '0';

  process ( sendpkt_arptab_read_strobe, streampkt_arptab_read_strobe )
    variable strobe : std_logic;
  begin
    strobe := sendpkt_arptab_read_strobe;
    for i in 0 to streampkt_arptab_read_strobe'left loop
      strobe := strobe or streampkt_arptab_read_strobe(i);
    end loop;
    arptab_read_strobe <= strobe;
  end process;

  arp_reply_strobe <= '1' when frame_strobe = '1' and
                               frame_crc_valid = '1' and
                               matched_arpreq_frame = '1' and
                               matched_arpreq_address = '1' else '0';
  arptab_write_strobe <= arp_reply_strobe or matched_arprep_frame;
  arptab_lookup_ip_addr <= sendpkt_daddr;

  icmp_reply_strobe <= '1' when frame_strobe = '1' and matched_icmpreq_frame = '1' and matched_ip_address = '1' else '0';
  icmp_buffer_clear <= '1' when ip_enable = '1' and ip_protocol = x"01" and ip_buffer_clear = '1' else '0';

  udp_received_strobe <= '1' when frame_strobe = '1' and matched_udp_frame = '1' and matched_ip_address = '1' else '0';

  process ( eth_tx_source, arp_sender_ha,
            ethernet_source_ha, ip_saddr, icmp_reply_length, icmp_reply_protocol,
            arptab_lookup_hw_addr, sendpkt_daddr, sendpkt_length, sendpkt_protocol,
            streampkt_daddr, arptab_lookup_hw_addr, streampkt_length, streampkt_protocol )
    variable eth_dest_ha_v : std_logic_vector(47 downto 0);
    variable eth_dest_ip_v : std_logic_vector(31 downto 0);
    variable length_v : std_logic_vector(15 downto 0);
    variable protocol_v : std_logic_vector(7 downto 0);
  begin
    eth_dest_ha_v := ( others => '0' );
    eth_dest_ip_v := ( others => '0' );
    length_v := x"0000";
    protocol_v := x"00";
    if ( eth_tx_source(1) = '1' ) then
      eth_dest_ha_v := arp_sender_ha;
    elsif ( eth_tx_source(2) = '1' ) then
      eth_dest_ha_v := x"ffffffffffff";
    elsif ( eth_tx_source(4) = '1' ) then
      eth_dest_ha_v := ethernet_source_ha;
      eth_dest_ip_v := ip_saddr;
      length_v := icmp_reply_length;
      protocol_v := icmp_reply_protocol;
    elsif ( eth_tx_source(5) = '1' ) then
      eth_dest_ha_v := arptab_lookup_hw_addr;
      eth_dest_ip_v := sendpkt_daddr;
      length_v := sendpkt_length;
      protocol_v := sendpkt_protocol;
    else
      for i in nstream-1 downto 0 loop
        if ( eth_tx_source(8+i) = '1' ) then
          eth_dest_ip_v := streampkt_daddr(i);
          eth_dest_ha_v := arptab_lookup_hw_addr;
          length_v := streampkt_length(i);
          protocol_v := streampkt_protocol(i);
        end if;
      end loop;
    end if;
    ethernet_dest_ha <= eth_dest_ha_v;
    ethernet_dest_ip <= eth_dest_ip_v;
    length <= length_v;
    protocol <= protocol_v;
  end process;

  process ( ethernet_header, ethernet_crc, ip_header_enable, eth_tx_enable,
            ethernet_dout, ethernet_crc_out, ip_header_txd, arprep_dout,
            arpreq_dout, icmprep_dout, sendpkt_dout, streampkt_dout,
            ethernet_crc, ethernet_ifg, streampkt_busy,
            streampkt_data_available )
    variable strobe_v : std_logic_vector(nstream-1 downto 0);
    variable dout_v : std_logic_vector(7 downto 0);
  begin
    strobe_v := ( others => '0' );
    if ( ethernet_crc = '0' and ethernet_ifg = '0' ) then
      for i in nstream-1 downto 0 loop
        strobe_v(i) := streampkt_data_available(i) and not streampkt_busy(i);
      end loop;
    end if;
    streampkt_strobe <= strobe_v;
    dout_v := x"00";
    if ( ethernet_crc = '1' ) then
      dout_v := ethernet_crc_out;
    elsif ( ethernet_header = '1' ) then
      dout_v := ethernet_dout;
    elsif ( ip_header_enable = '1' ) then
      dout_v := ip_header_txd;
    elsif ( eth_tx_enable = "0001" ) then
      dout_v := arprep_dout;
    elsif ( eth_tx_enable = "0010" ) then
      dout_v := arpreq_dout;
    elsif ( eth_tx_enable = "0100" ) then
      dout_v := icmprep_dout;
    elsif ( eth_tx_enable = "0101" ) then
      dout_v := sendpkt_dout;
    elsif ( eth_tx_enable(3) = '1' ) then
      for i in nstream-1 downto 0 loop
        if ( to_integer(unsigned(eth_tx_enable(2 downto 0))) = i ) then
          dout_v := streampkt_dout(i);
        end if;
      end loop;
    end if;
    dout <= dout_v;
  end process;
    
  arp_request_strobe <= arp_csr(31) or sendpkt_arpreq_strobe;
  arpreq_target_ip <= arptab_target_ip_addr when sendpkt_arpreq_strobe = '1' else arp_lookup_ip;

--  streampkt_strobe(0) <= '0' when ethernet_crc = '1' else
--                         '0' when ethernet_ifg = '1' else
--                         '0' when streampkt_busy(0) = '1' else
--                         streampkt_data_available(0);

--  dout <= ethernet_crc_out when ethernet_crc = '1' else
--          ethernet_dout when ethernet_header = '1' else
--          ip_header_txd when ip_header_enable = '1' else
--          arprep_dout when eth_tx_enable = "0001" else
--          arpreq_dout when eth_tx_enable = "0010" else
--          icmprep_dout when eth_tx_enable = "0100" else
--          sendpkt_dout when eth_tx_enable = "0101" else
--          streampkt_dout(0) when eth_tx_enable = "1000" else
--          x"00";

  g_jumpers : if ( jumpers ) generate
    my_mac_addr(3 downto 0) <= jumpered_address(3 downto 0);
    my_ip_address(3 downto 0) <= jumpered_address(3 downto 0);
  end generate;

  gbe_stream_clka <= gmii_clk;

  interrupt <= gbe_int;
  gmii_txd <= dout;
  gmii_tx_en <= den;
  gmii_tx_er <= '0';

end RTL;
