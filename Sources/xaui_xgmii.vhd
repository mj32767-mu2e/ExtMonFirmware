--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    09:52:00 12/23/2021 
-- Design Name:    amc502
-- Module Name:    xaui_xgmii - RTL
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.2
-- Description:    Interface between GTX transceivers and XAUI
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

library unisim;
use unisim.vcomponents.all;

entity xaui_xgmii is
  port (
    dclk : in std_logic;
    reset : in std_logic;
    clk156_in_p : in std_logic;
    clk156_in_n : in std_logic;
    xgmii_rxclk : out std_logic;
    xgmii_txclk : out std_logic;
    xgmii_txd : in std_logic_vector(63 downto 0);
    xgmii_txc : in std_logic_vector(7 downto 0);
    xgmii_rxd : out std_logic_vector(63 downto 0);
    xgmii_rxc : out std_logic_vector(7 downto 0);
    xgmii_clk_lock : out std_logic;
    xaui_tx_l0_p : out std_logic;
    xaui_tx_l0_n : out std_logic;
    xaui_tx_l1_p : out std_logic;
    xaui_tx_l1_n : out std_logic;
    xaui_tx_l2_p : out std_logic;
    xaui_tx_l2_n : out std_logic;
    xaui_tx_l3_p : out std_logic;
    xaui_tx_l3_n : out std_logic;
    xaui_rx_l0_p : in std_logic;
    xaui_rx_l0_n : in std_logic;
    xaui_rx_l1_p : in std_logic;
    xaui_rx_l1_n : in std_logic;
    xaui_rx_l2_p : in std_logic;
    xaui_rx_l2_n : in std_logic;
    xaui_rx_l3_p : in std_logic;
    xaui_rx_l3_n : in std_logic;
    signal_detect : in std_logic_vector(3 downto 0);
    debug : out std_logic_vector(5 downto 0);
    configuration_vector : in std_logic_vector(6 downto 0);
    status_vector : out std_logic_vector(7 downto 0)
  );
end xaui_xgmii;

architecture RTL of xaui_xgmii is

  component gtwizard_3
  port (
    SOFT_RESET_TX_IN                        : in   std_logic;
    SOFT_RESET_RX_IN                        : in   std_logic;
    DONT_RESET_ON_DATA_ERROR_IN             : in   std_logic;
    Q0_CLK1_GTREFCLK_PAD_N_IN               : in   std_logic;
    Q0_CLK1_GTREFCLK_PAD_P_IN               : in   std_logic;

    GT0_TX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT0_RX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT0_DATA_VALID_IN                       : in   std_logic;
 
    GT0_TXUSRCLK_OUT                        : out  std_logic;
    GT0_TXUSRCLK2_OUT                       : out  std_logic;
    GT0_RXUSRCLK_OUT                        : out  std_logic;
    GT0_RXUSRCLK2_OUT                       : out  std_logic;

    --_________________________________________________________________________
    --GT0  (X1Y0)
    --____________________________CHANNEL PORTS________________________________
    ---------------------------- Channel - DRP Ports  --------------------------
    gt0_drpaddr_in                          : in   std_logic_vector(8 downto 0);
    gt0_drpdi_in                            : in   std_logic_vector(15 downto 0);
    gt0_drpdo_out                           : out  std_logic_vector(15 downto 0);
    gt0_drpen_in                            : in   std_logic;
    gt0_drprdy_out                          : out  std_logic;
    gt0_drpwe_in                            : in   std_logic;
    --------------------------- Digital Monitor Ports --------------------------
    gt0_dmonitorout_out                     : out  std_logic_vector(7 downto 0);
    --------------------- RX Initialization and Reset Ports --------------------
    gt0_eyescanreset_in                     : in   std_logic;
    gt0_rxuserrdy_in                        : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt0_eyescandataerror_out                : out  std_logic;
    gt0_eyescantrigger_in                   : in   std_logic;
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt0_rxdata_out                          : out  std_logic_vector(15 downto 0);
    ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
    gt0_rxdisperr_out                       : out  std_logic_vector(1 downto 0);
    gt0_rxnotintable_out                    : out  std_logic_vector(1 downto 0);
    --------------------------- Receive Ports - RX AFE -------------------------
    gt0_gtxrxp_in                           : in   std_logic;
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt0_gtxrxn_in                           : in   std_logic;
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt0_rxdfelpmreset_in                    : in   std_logic;
    gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt0_rxoutclkfabric_out                  : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                        : in   std_logic;
    gt0_rxpmareset_in                       : in   std_logic;
    ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
    gt0_rxcharisk_out                       : out  std_logic_vector(1 downto 0);
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt0_rxresetdone_out                     : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                        : in   std_logic;
    gt0_txuserrdy_in                        : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt0_txdata_in                           : in   std_logic_vector(15 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt0_gtxtxn_out                          : out  std_logic;
    gt0_gtxtxp_out                          : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt0_txoutclkfabric_out                  : out  std_logic;
    gt0_txoutclkpcs_out                     : out  std_logic;
    --------------------- Transmit Ports - TX Gearbox Ports --------------------
    gt0_txcharisk_in                        : in   std_logic_vector(1 downto 0);
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt0_txresetdone_out                     : out  std_logic;

    --____________________________COMMON PORTS________________________________
    GT0_QPLLLOCK_OUT : out std_logic;
    GT0_QPLLREFCLKLOST_OUT  : out std_logic;
    GT0_QPLLOUTCLK_OUT  : out std_logic;
    GT0_QPLLOUTREFCLK_OUT : out std_logic;

    sysclk_in                               : in   std_logic

  );
  end component;

  component gtwizard_4
  port
  (
    SYSCLK_IN                               : in   std_logic;
    SOFT_RESET_TX_IN                        : in   std_logic;
    SOFT_RESET_RX_IN                        : in   std_logic;
    DONT_RESET_ON_DATA_ERROR_IN             : in   std_logic;
    GT0_TX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT0_RX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT0_DATA_VALID_IN                       : in   std_logic;

    --_________________________________________________________________________
    --GT0  (X1Y0)
    --____________________________CHANNEL PORTS________________________________
    ---------------------------- Channel - DRP Ports  --------------------------
    gt0_drpaddr_in                          : in   std_logic_vector(8 downto 0);
    gt0_drpclk_in                           : in   std_logic;
    gt0_drpdi_in                            : in   std_logic_vector(15 downto 0);
    gt0_drpdo_out                           : out  std_logic_vector(15 downto 0);
    gt0_drpen_in                            : in   std_logic;
    gt0_drprdy_out                          : out  std_logic;
    gt0_drpwe_in                            : in   std_logic;
    --------------------------- Digital Monitor Ports --------------------------
    gt0_dmonitorout_out                     : out  std_logic_vector(7 downto 0);
    --------------------- RX Initialization and Reset Ports --------------------
    gt0_eyescanreset_in                     : in   std_logic;
    gt0_rxuserrdy_in                        : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt0_eyescandataerror_out                : out  std_logic;
    gt0_eyescantrigger_in                   : in   std_logic;
    ------------------ Receive Ports - FPGA RX Interface Ports -----------------
    gt0_rxusrclk_in                         : in   std_logic;
    gt0_rxusrclk2_in                        : in   std_logic;
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt0_rxdata_out                          : out  std_logic_vector(15 downto 0);
    ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
    gt0_rxdisperr_out                       : out  std_logic_vector(1 downto 0);
    gt0_rxnotintable_out                    : out  std_logic_vector(1 downto 0);
    --------------------------- Receive Ports - RX AFE -------------------------
    gt0_gtxrxp_in                           : in   std_logic;
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt0_gtxrxn_in                           : in   std_logic;
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt0_rxdfelpmreset_in                    : in   std_logic;
    gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt0_rxoutclk_out                        : out  std_logic;
    gt0_rxoutclkfabric_out                  : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                        : in   std_logic;
    gt0_rxpmareset_in                       : in   std_logic;
    ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
    gt0_rxcharisk_out                       : out  std_logic_vector(1 downto 0);
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt0_rxresetdone_out                     : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                        : in   std_logic;
    gt0_txuserrdy_in                        : in   std_logic;
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    gt0_txusrclk_in                         : in   std_logic;
    gt0_txusrclk2_in                        : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt0_txdata_in                           : in   std_logic_vector(15 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt0_gtxtxn_out                          : out  std_logic;
    gt0_gtxtxp_out                          : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt0_txoutclk_out                        : out  std_logic;
    gt0_txoutclkfabric_out                  : out  std_logic;
    gt0_txoutclkpcs_out                     : out  std_logic;
    --------------------- Transmit Ports - TX Gearbox Ports --------------------
    gt0_txcharisk_in                        : in   std_logic_vector(1 downto 0);
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt0_txresetdone_out                     : out  std_logic;


    --____________________________COMMON PORTS________________________________
    GT0_QPLLLOCK_IN : in std_logic;
    GT0_QPLLREFCLKLOST_IN  : in std_logic;
    GT0_QPLLRESET_OUT  : out std_logic;
    GT0_QPLLOUTCLK_IN  : in std_logic;
    GT0_QPLLOUTREFCLK_IN : in std_logic

  );
  end component;

  signal rxchbond : std_logic_vector(4 downto 0);
  signal count : std_logic_vector(7 downto 0);
  signal soft_reset : std_logic := '0';
  signal hard_reset : std_logic := '0';
  signal qpll_lock : std_logic;
  signal gtx_rx_reset_done : std_logic_vector(3 downto 0);
  signal gtx_tx_reset_done : std_logic_vector(3 downto 0);
  signal fsm_rx_reset_done : std_logic_vector(3 downto 0);
  signal fsm_tx_reset_done : std_logic_vector(3 downto 0);
  signal user_ready : std_logic := '0';
  signal rxusrclk : std_logic;
  signal rxusrclk2 : std_logic;
  signal txusrclk : std_logic;
  signal txusrclk2 : std_logic;
  signal qpll_refclklost : std_logic;
  signal qpll_outclk : std_logic;
  signal qpll_refclk : std_logic;
  signal rx_reset_done : std_logic_vector(3 downto 0);
  signal tx_reset_done : std_logic_vector(3 downto 0);
  type reset_state_t is ( Idle, Resetting, ResetDone, ResetWait, Done );
  signal reset_state : reset_state_t := Idle;
  signal aligned : std_logic_vector(3 downto 0);
  signal chan_aligned : std_logic_vector(3 downto 0);
  signal pcs_rxd : std_logic_vector(63 downto 0);
  signal pcs_rxc : std_logic_vector(7 downto 0);
  signal pcs_txd : std_logic_vector(63 downto 0);
  signal pcs_txc : std_logic_vector(7 downto 0);
  signal xgmii_txd_r : std_logic_vector(63 downto 0);
  signal xgmii_txc_r : std_logic_vector(7 downto 0);
  signal xaui_rx_p : std_logic_vector(3 downto 0);
  signal xaui_rx_n : std_logic_vector(3 downto 0);
  signal xaui_tx_p : std_logic_vector(3 downto 0);
  signal xaui_tx_n : std_logic_vector(3 downto 0);
  signal ros_code : std_logic_vector(7 downto 0);
  signal rand_poly : std_logic_vector(7 downto 0) := "00000001";
  signal pcs_rmax : std_logic_vector(5 downto 0) := "010000";
  type pcs_state_t is ( Frame, TermFill, SendSync, TermSync, TermAlign, SendAlign, SendSkip );
  signal pcs_txd_state : pcs_state_t := SendAlign;
  type pcs_d_t is array(3 downto 0) of std_logic_vector(63 downto 0);
  type pcs_c_t is array(3 downto 0) of std_logic_vector(7 downto 0);
  signal pcs_rxd_pipe : pcs_d_t;
  signal pcs_rxc_pipe : pcs_c_t;
  type pcs_deskew_t is array(3 downto 0) of integer range 0 to 5;
  signal pcs_deskew : pcs_deskew_t;
  signal nframe : integer range 0 to 31;
  signal rframe : integer range 0 to 31;
  signal sendk : std_logic := '0';
  type txd_fifo_t is array(63 downto 0) of std_logic_vector(63 downto 0);
  type txc_fifo_t is array(63 downto 0) of std_logic_vector(7 downto 0);
  signal txd_fifo : txd_fifo_t;
  signal txc_fifo : txc_fifo_t;
  signal i : integer range 0 to 63 := 0;
  signal j : integer range 0 to 63 := 0;
  signal i_r : integer range 0 to 63 := 0;
  signal j_r : integer range 0 to 63 := 0;
  signal drop : std_logic := '0';
  signal slush : integer range -64 to 63 := 0;

  attribute mark_debug : string;
  attribute dont_touch : string;
--  attribute mark_debug of reset_state : signal is "true";
--  attribute mark_debug of pcs_rxd : signal is "true";
--  attribute mark_debug of pcs_rxc : signal is "true";
--  attribute mark_debug of pcs_txd : signal is "true";
--  attribute mark_debug of pcs_txc : signal is "true";
--  attribute mark_debug of soft_reset : signal is "true";
--  attribute mark_debug of hard_reset : signal is "true";
--  attribute mark_debug of user_ready : signal is "true";
--  attribute mark_debug of aligned : signal is "true";
--  attribute mark_debug of chan_aligned : signal is "true";
--  attribute mark_debug of ros_code : signal is "true";
--  attribute dont_touch of ros_code : signal is "true";
--  attribute mark_debug of pcs_rxd_pipe : signal is "true";
--  attribute dont_touch of pcs_rxd_pipe : signal is "true";
--  attribute mark_debug of pcs_rxc_pipe : signal is "true";
--  attribute dont_touch of pcs_rxc_pipe : signal is "true";
--  attribute mark_debug of pcs_deskew : signal is "true";
--  attribute dont_touch of pcs_deskew : signal is "true";
--  attribute mark_debug of nframe : signal is "true";
--  attribute mark_debug of rframe : signal is "true";
--  attribute mark_debug of pcs_txd_state : signal is "true";
--  attribute mark_debug of rand_poly : signal is "true";
--  attribute mark_debug of drop : signal is "true";
--  attribute mark_debug of i : signal is "true";
--  attribute mark_debug of j : signal is "true";
--  attribute mark_debug of slush : signal is "true";
--  attribute mark_debug of i_r : signal is "true";
--  attribute mark_debug of j_r : signal is "true";

begin

  gt3_imp : gtwizard_3
  port map (
    SOFT_RESET_TX_IN => soft_reset,
    SOFT_RESET_RX_IN => soft_reset,
    DONT_RESET_ON_DATA_ERROR_IN => '1',
    Q0_CLK1_GTREFCLK_PAD_N_IN => clk156_in_n,
    Q0_CLK1_GTREFCLK_PAD_P_IN => clk156_in_p,
    GT0_TX_FSM_RESET_DONE_OUT => fsm_tx_reset_done(0),
    GT0_RX_FSM_RESET_DONE_OUT => fsm_rx_reset_done(0),
    GT0_DATA_VALID_IN => '1',
    GT0_TXUSRCLK_OUT => txusrclk,
    GT0_TXUSRCLK2_OUT => txusrclk2,
    GT0_RXUSRCLK_OUT => rxusrclk,
    GT0_RXUSRCLK2_OUT => rxusrclk2,
    gt0_drpaddr_in => "000000000",
    gt0_drpdi_in => x"0000",
    gt0_drpdo_out => open,
    gt0_drpen_in => '0',
    gt0_drprdy_out => open,
    gt0_drpwe_in => '0',
    gt0_dmonitorout_out => open,
    gt0_eyescanreset_in => '0',
    gt0_rxuserrdy_in => user_ready,
    gt0_eyescandataerror_out => open,
    gt0_eyescantrigger_in => '0',
    gt0_rxdata_out => pcs_rxd(15 downto 0),
    gt0_rxdisperr_out => open,
    gt0_rxnotintable_out => open,
    gt0_gtxrxp_in => xaui_rx_l0_p,
    gt0_gtxrxn_in => xaui_rx_l0_n,
    gt0_rxdfelpmreset_in => hard_reset,
    gt0_rxmonitorout_out => open,
    gt0_rxmonitorsel_in => "00",
    gt0_rxoutclkfabric_out => open,
    gt0_gtrxreset_in => hard_reset,
    gt0_rxpmareset_in => hard_reset,
    gt0_rxcharisk_out => pcs_rxc(1 downto 0),
    gt0_rxresetdone_out => gtx_rx_reset_done(0),
    gt0_gttxreset_in => hard_reset,
    gt0_txuserrdy_in => user_ready,
    gt0_txdata_in => pcs_txd(15 downto 0),
    gt0_gtxtxn_out => xaui_tx_l0_n,
    gt0_gtxtxp_out => xaui_tx_l0_p,
    gt0_txoutclkfabric_out => open,
    gt0_txoutclkpcs_out => open,
    gt0_txcharisk_in => pcs_txc(1 downto 0),
    gt0_txresetdone_out => gtx_tx_reset_done(0),
    GT0_QPLLLOCK_OUT => qpll_lock,
    GT0_QPLLREFCLKLOST_OUT => qpll_refclklost,
    GT0_QPLLOUTCLK_OUT => qpll_outclk,
    GT0_QPLLOUTREFCLK_OUT => qpll_refclk,
    sysclk_in => dclk
  );

  xgmii_rxclk <= rxusrclk2;
--  xgmii_txclk <= txusrclk2;
  xgmii_txclk <= rxusrclk2;
  xgmii_clk_lock <= qpll_lock;


--  clk156_bufg : bufg
--  port map (
--    i => rxusrclk2,
--    o => clk156_out
--  );

  g_gtx : for i in 1 to 3 generate
    gt4_imp : gtwizard_4
    port map (
      SYSCLK_IN => dclk,
      SOFT_RESET_TX_IN => soft_reset,
      SOFT_RESET_RX_IN => soft_reset,
      DONT_RESET_ON_DATA_ERROR_IN => '1',
      GT0_TX_FSM_RESET_DONE_OUT => fsm_tx_reset_done(i),
      GT0_RX_FSM_RESET_DONE_OUT => fsm_rx_reset_done(i),
      GT0_DATA_VALID_IN => '1',

      gt0_drpaddr_in => "000000000",
      gt0_drpclk_in => dclk,
      gt0_drpdi_in => x"0000",
      gt0_drpdo_out => open,
      gt0_drpen_in => '0',
      gt0_drprdy_out => open,
      gt0_drpwe_in => '0',
      gt0_dmonitorout_out => open,
      gt0_eyescanreset_in => '0',
      gt0_rxuserrdy_in => user_ready,
      gt0_eyescandataerror_out => open,
      gt0_eyescantrigger_in => '0',
      gt0_rxusrclk_in => rxusrclk,
      gt0_rxusrclk2_in => rxusrclk2,
      gt0_rxdata_out => pcs_rxd(16*i+15 downto 16*i),
      gt0_rxdisperr_out => open,
      gt0_rxnotintable_out => open,
      gt0_gtxrxp_in => xaui_rx_p(i),
      gt0_gtxrxn_in => xaui_rx_n(i),
      gt0_rxdfelpmreset_in => hard_reset,
      gt0_rxmonitorout_out => open,
      gt0_rxmonitorsel_in => "00",
      gt0_rxoutclk_out => open,
      gt0_rxoutclkfabric_out => open,
      gt0_gtrxreset_in => hard_reset,
      gt0_rxpmareset_in => hard_reset,
      gt0_rxcharisk_out => pcs_rxc(2*i+1 downto 2*i),
      gt0_rxresetdone_out => gtx_rx_reset_done(i),
      gt0_gttxreset_in => hard_reset,
      gt0_txuserrdy_in => user_ready,
      gt0_txusrclk_in => txusrclk,
      gt0_txusrclk2_in => txusrclk2,
      gt0_txdata_in => pcs_txd(16*i+15 downto 16*i),
      gt0_gtxtxn_out => xaui_tx_n(i),
      gt0_gtxtxp_out => xaui_tx_p(i),
      gt0_txoutclk_out => open,
      gt0_txoutclkfabric_out => open,
      gt0_txoutclkpcs_out => open,
      gt0_txcharisk_in => pcs_txc(2*i+1 downto 2*i),
      gt0_txresetdone_out => open,
      GT0_QPLLLOCK_IN => qpll_lock,
      GT0_QPLLREFCLKLOST_IN => qpll_refclklost,
      GT0_QPLLRESET_OUT => open,
      GT0_QPLLOUTCLK_IN => qpll_outclk,
      GT0_QPLLOUTREFCLK_IN => qpll_refclk
    );
  end generate;

  xaui_rx_p(0) <= xaui_rx_l0_p;
  xaui_rx_n(0) <= xaui_rx_l0_n;
  xaui_rx_p(1) <= xaui_rx_l1_p;
  xaui_rx_n(1) <= xaui_rx_l1_n;
  xaui_rx_p(2) <= xaui_rx_l2_p;
  xaui_rx_n(2) <= xaui_rx_l2_n;
  xaui_rx_p(3) <= xaui_rx_l3_p;
  xaui_rx_n(3) <= xaui_rx_l3_n;
  xaui_tx_l0_p <= xaui_tx_p(0);
  xaui_tx_l0_n <= xaui_tx_n(0);
  xaui_tx_l1_p <= xaui_tx_p(1);
  xaui_tx_l1_n <= xaui_tx_n(1);
  xaui_tx_l2_p <= xaui_tx_p(2);
  xaui_tx_l2_n <= xaui_tx_n(2);
  xaui_tx_l3_p <= xaui_tx_p(3);
  xaui_tx_l3_n <= xaui_tx_n(3);

  process ( dclk ) begin
    if ( dclk'event and dclk = '1' ) then
      case reset_state is
      when Idle =>
        if ( reset = '1' ) then
          hard_reset <= '1';
          count <= x"40";
          user_ready <= '0';
          reset_state <= Resetting;
        end if;
      when Resetting =>
        count <= std_logic_vector(unsigned(count)-1);
        if ( count = x"00" ) then
          reset_state <= ResetDone;
          hard_reset <= '0';
        end if;
      when ResetDone =>
        if ( qpll_lock = '1' ) then
          reset_state <= ResetWait;
        end if;
      when ResetWait =>
        if ( gtx_rx_reset_done = "1111" and gtx_tx_reset_done = "1111" ) then
          reset_state <= Done;
          user_ready <= '1';
        end if;
      when Done =>
        if ( reset = '0' ) then
          reset_state <= Idle;
        end if;
      end case;
    end if;
  end process;

  process ( rxusrclk2 )
    variable deskew : boolean := false;
  begin
    if ( rxusrclk2'event and rxusrclk2 = '1' ) then
      pcs_rxd_pipe(0)(47 downto 0) <= pcs_rxd_pipe(0)(63 downto 16);
      pcs_rxd_pipe(0)(63 downto 48) <= pcs_rxd(15 downto 0);
      pcs_rxd_pipe(1)(47 downto 0) <= pcs_rxd_pipe(1)(63 downto 16);
      pcs_rxd_pipe(1)(63 downto 48) <= pcs_rxd(31 downto 16);
      pcs_rxd_pipe(2)(47 downto 0) <= pcs_rxd_pipe(2)(63 downto 16);
      pcs_rxd_pipe(2)(63 downto 48) <= pcs_rxd(47 downto 32);
      pcs_rxd_pipe(3)(47 downto 0) <= pcs_rxd_pipe(3)(63 downto 16);
      pcs_rxd_pipe(3)(63 downto 48) <= pcs_rxd(63 downto 48);

      pcs_rxc_pipe(0)(5 downto 0) <= pcs_rxc_pipe(0)(7 downto 2);
      pcs_rxc_pipe(0)(7 downto 6) <= pcs_rxc(1 downto 0);
      pcs_rxc_pipe(1)(5 downto 0) <= pcs_rxc_pipe(1)(7 downto 2);
      pcs_rxc_pipe(1)(7 downto 6) <= pcs_rxc(3 downto 2);
      pcs_rxc_pipe(2)(5 downto 0) <= pcs_rxc_pipe(2)(7 downto 2);
      pcs_rxc_pipe(2)(7 downto 6) <= pcs_rxc(5 downto 4);
      pcs_rxc_pipe(3)(5 downto 0) <= pcs_rxc_pipe(3)(7 downto 2);
      pcs_rxc_pipe(3)(7 downto 6) <= pcs_rxc(7 downto 6);

      pcs_deskew(0) <= 3;
      if ( pcs_rxc_pipe(0)(2) = '1' and
           pcs_rxd_pipe(0)(23 downto 16) = x"7c" ) then
        for j in 1 to 3 loop
          for k in 0 to 4 loop
            if ( pcs_rxc_pipe(j)(k) = '1' and
                 pcs_rxd_pipe(j)(8*k+7 downto 8*k) = x"7c" ) then
              pcs_deskew(j) <= 1+k;
            end if;
          end loop;
        end loop;
      end if;
      if ( pcs_rxc_pipe(0)(3) = '1' and
           pcs_rxd_pipe(0)(31 downto 24) = x"7c" ) then
        for j in 1 to 3 loop
          for k in 0 to 5 loop
            if ( pcs_rxc_pipe(j)(k) = '1' and
                 pcs_rxd_pipe(j)(8*k+7 downto 8*k) = x"7c" ) then
              pcs_deskew(j) <= k;
            end if;
          end loop;
        end loop;
      end if;

      for i in 0 to 3 loop
        xgmii_rxc(i) <= pcs_rxc_pipe(i)(pcs_deskew(i));
        xgmii_rxd(8*i+7 downto 8*i) <= pcs_rxd_pipe(i)(8*pcs_deskew(i)+7 downto 8*pcs_deskew(i));
        xgmii_rxc(4+i) <= pcs_rxc_pipe(i)(pcs_deskew(i)+1);
        xgmii_rxd(8*i+39 downto 8*i+32) <= pcs_rxd_pipe(i)(8*pcs_deskew(i)+15 downto 8*pcs_deskew(i)+8);
      end loop;

    end if;
  end process;

  process ( rxusrclk2, i, j, slush ) 
    variable splat : integer;
  begin
    if ( rxusrclk2'event and rxusrclk2 = '1' ) then
      j_r <= j;
      i_r <= i;
      splat := i_r - j_r;
--
--  These can wrap around so that when i=0 and j=63
--  we would like splat to be 1.
--
--  If j > i then we definitely don't want to drop anything.
--
      if ( splat < -32 ) then
        splat := 64 + splat;
      end if;
      slush <= splat;
      if ( slush < 32 or xgmii_txc /= x"ff" or xgmii_txd /= x"0707070707070707" ) then
        txd_fifo(i) <= xgmii_txd;
        txc_fifo(i) <= xgmii_txc;
        i <= i + 1;
        drop <= '0';
      else -- slush >= 32 and txc = ff and txd == 07070707...
        drop <= '1';
      end if;
    end if;
  end process;

  process ( txusrclk2, i, j ) begin
    if ( txusrclk2'event and txusrclk2 = '1' ) then
      if ( i /= j ) then
        xgmii_txd_r <= txd_fifo(j);
        xgmii_txc_r <= txc_fifo(j);
        j <= j + 1;
      else
        xgmii_txd_r <= x"0707070707070707";
        xgmii_txc_r <= x"ff";
      end if;
    end if;
  end process;

  process ( txusrclk2, nframe, rframe, pcs_txd_state )
    variable txd : std_logic_vector(7 downto 0);
    variable pcs : std_logic_vector(63 downto 0);
    variable n : integer range 0 to 31 := nframe;
    variable r : integer range 0 to 31 := rframe;
    variable state : pcs_state_t := pcs_txd_state;
    variable lsb : std_logic;
    variable ext : std_logic_vector(7 downto 0);
    constant poly : std_logic_vector(7 downto 0) := "11000000";
    variable rand : std_logic_vector(7 downto 0);
  begin
    if ( txusrclk2'event and txusrclk2 = '1' ) then
--      xgmii_txd_r <= xgmii_txd;
--      xgmii_txc_r <= xgmii_txc;

      rand := rand_poly;
      for i in 0 to 7 loop

        if ( i = 0 or i = 4 ) then
          lsb := rand(0);
          for j in 0 to 7 loop
            ext(j) := lsb;
          end loop;
          rand := ( '0' & rand(7 downto 1) ) xor ( ext and poly );
        end if;

        txd := xgmii_txd_r(8*i+7 downto 8*i);
        if ( xgmii_txc_r(i) = '0' ) then
          pcs(8*i+7 downto 8*i) := txd;   -- Send data
        elsif ( txd = x"fb" ) then
          pcs(8*i+7 downto 8*i) := txd;   -- Send start (should be in column 0)
          state := Frame;
        elsif ( txd = x"fd" ) then
          pcs(8*i+7 downto 8*i) := txd;   -- Send terminate
          state := TermFill;
        elsif ( state = TermFill ) then   -- Pad the terminate
          pcs(8*i+7 downto 8*i) := x"bc";
        elsif ( txd = x"07" and state = SendSync ) then
          pcs(8*i+7 downto 8*i) := x"bc";   -- Sync = ||K||
        elsif ( txd = x"07" and state = TermSync ) then
          pcs(8*i+7 downto 8*i) := x"bc";   -- Sync = ||K||
        elsif ( txd = x"07" and state = SendAlign ) then
          pcs(8*i+7 downto 8*i) := x"7c";   -- Align = ||A||
        elsif ( txd = x"07" and state = TermAlign ) then
          pcs(8*i+7 downto 8*i) := x"7c";   -- Align = ||A||
        elsif ( txd = x"07" and state = SendSkip ) then
          pcs(8*i+7 downto 8*i) := x"1c";   -- Skip = ||R||
        else
          pcs(8*i+7 downto 8*i) := txd;   -- Should not happen
        end if;

        if ( i = 3 or i = 7 ) then
          case state is
          when TermFill =>
            if ( sendk = '1' ) then
              sendk <= '0';
              state := TermSync;
            elsif ( n < r ) then
              sendk <= '0';
              state := TermSync;
            else
              sendk <= '1';
              state := TermAlign;
              r := to_integer(unsigned('1' & rand(3 downto 0)));
              n := 0;
            end if;
          when TermAlign =>
            n := n + 1;
            state := SendSkip;
          when TermSync =>
            n := n + 1;
            state := SendSkip;
          when SendSync =>
            n := n + 1;
            if ( n >= r ) then
              state := SendAlign;
              r := to_integer(unsigned('1' & rand(3 downto 0)));
              n := 0;
            elsif ( lsb = '1' ) then
              state := SendSync;
            else
              state := SendSkip;
            end if;
          when SendAlign =>
            n := n + 1;
            if ( lsb = '1' ) then
              state := SendSync;
            else
              state := SendSkip;
            end if;
          when SendSkip =>
            n := n + 1;
            if ( n >= r ) then
              state := SendAlign;
              r := to_integer(unsigned('1' & rand(3 downto 0)));
              n := 0;
            elsif ( lsb = '1' ) then
              state := SendSync;
            else
              state := SendSkip;
            end if;
          when Frame =>
            if ( n < r ) then
              n := n + 1;
            end if;
          end case;
        end if;
      end loop;
      nframe <= n;
      rframe <= r;
      rand_poly <= rand;
      pcs_txd_state <= state;

      pcs_txc(0) <= xgmii_txc_r(0);
      pcs_txc(2) <= xgmii_txc_r(1);
      pcs_txc(4) <= xgmii_txc_r(2);
      pcs_txc(6) <= xgmii_txc_r(3);
      pcs_txc(1) <= xgmii_txc_r(4);
      pcs_txc(3) <= xgmii_txc_r(5);
      pcs_txc(5) <= xgmii_txc_r(6);
      pcs_txc(7) <= xgmii_txc_r(7);
      pcs_txd(7 downto 0) <= pcs(7 downto 0);
      pcs_txd(23 downto 16) <= pcs(15 downto 8);
      pcs_txd(39 downto 32) <= pcs(23 downto 16);
      pcs_txd(55 downto 48) <= pcs(31 downto 24);
      pcs_txd(15 downto 8) <= pcs(39 downto 32);
      pcs_txd(31 downto 24) <= pcs(47 downto 40);
      pcs_txd(47 downto 40) <= pcs(55 downto 48);
      pcs_txd(63 downto 56) <= pcs(63 downto 56);
    end if;
  end process;

  ros_code(0) <=
    '1' when pcs_rxc(0) = '1' and pcs_rxd(7 downto 0) = x"1c" else '0';
  ros_code(1) <=
    '1' when pcs_rxc(0) = '1' and pcs_rxd(7 downto 0) = x"7c" else '0';
  ros_code(2) <=
    '1' when pcs_rxc(0) = '1' and pcs_rxd(7 downto 0) = x"bc" else '0';
  ros_code(3) <=
    '1' when pcs_rxc(0) = '1' and pcs_rxd(7 downto 0) = x"fb" else '0';
  ros_code(4) <=
    '1' when pcs_rxc(0) = '1' and pcs_rxd(7 downto 0) = x"fd" else 
    '1' when pcs_rxc(1) = '1' and pcs_rxd(15 downto 8) = x"fd" else 
    '1' when pcs_rxc(2) = '1' and pcs_rxd(23 downto 16) = x"fd" else 
    '1' when pcs_rxc(3) = '1' and pcs_rxd(31 downto 24) = x"fd" else 
    '1' when pcs_rxc(4) = '1' and pcs_rxd(39 downto 32) = x"fd" else 
    '1' when pcs_rxc(5) = '1' and pcs_rxd(47 downto 40) = x"fd" else 
    '1' when pcs_rxc(6) = '1' and pcs_rxd(55 downto 48) = x"fd" else 
    '1' when pcs_rxc(7) = '1' and pcs_rxd(63 downto 56) = x"fd" else '0';
  ros_code(5) <=
    '1' when pcs_rxc(0) = '1' and pcs_rxd(7 downto 0) = x"fe" else '0';
  ros_code(6) <=
    '1' when pcs_rxc(0) = '1' and pcs_rxd(7 downto 0) = x"9c" else '0';
  ros_code(7) <=
    '1' when pcs_rxc(0) = '1' and pcs_rxd(7 downto 0) = x"5c" else '0';
  debug <= ( others => '0' );
  status_vector <= ( others => '0' );

end RTL;
