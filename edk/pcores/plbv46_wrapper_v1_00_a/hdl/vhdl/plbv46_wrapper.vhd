library IEEE;
use IEEE.Std_Logic_1164.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.family.all;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.or_gate128;
use proc_common_v3_00_a.ipif_mirror128;

library plbv46_slave_burst_v1_01_a;
library plbv46_master_single_v1_01_a;

library plbv46_wrapper_v1_00_a;

-------------------------------------------------------------------------------
-- Entity Section
-------------------------------------------------------------------------------

entity plbv46_wrapper is

  generic (
    C_FAMILY                    : STRING                        := "virtex5";

    C_BASEADDR                  : STD_LOGIC_VECTOR              := X"FFFFFFFF";
    C_HIGHADDR                  : STD_LOGIC_VECTOR              := X"00000000";
    -- PLBv46 slave single block generics
    C_SPLB_AWIDTH               : integer                       := 32;
    C_SPLB_DWIDTH               : integer                       := 32;
    C_SPLB_P2P                  : integer range 0 to 1          := 0;
    C_SPLB_MID_WIDTH            : integer range 0 to 4          := 1;
    C_SPLB_NUM_MASTERS          : integer range 1 to 16         := 1;
    C_SPLB_NATIVE_DWIDTH        : integer range 32 to 32        := 32;
    C_SPLB_SUPPORT_BURSTS       : integer range 0 to 1          := 0;
    --
    C_MPLB_AWIDTH : INTEGER range 32 to 36 := 32;
    C_MPLB_DWIDTH : INTEGER range 32 to 128 := 32;
    C_MPLB_NATIVE_DWIDTH : INTEGER range 32 to 32 := 32
    );
  port (
    --PLBv46 SLAVE SINGLE INTERFACE
    -- system signals
    SPLB_Clk                  : in  std_logic;
    SPLB_Rst                  : in  std_logic;
    -- Bus slave signals
    PLB_ABus                  : in  std_logic_vector(0 to C_SPLB_AWIDTH-1);
    PLB_PAValid               : in  std_logic;
    PLB_masterID              : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_RNW                   : in  std_logic;
    PLB_BE                    : in  std_logic_vector(0 to (C_SPLB_DWIDTH/8)-1);
    PLB_size                  : in  std_logic_vector(0 to 3);
    PLB_type                  : in  std_logic_vector(0 to 2);
    PLB_wrDBus                : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);

    --slave DCR Bridge response signals
    Sl_addrAck                : out std_logic;
    Sl_SSize                  : out std_logic_vector(0 to 1);
    Sl_wait                   : out std_logic;
    Sl_rearbitrate            : out std_logic;
    Sl_wrDAck                 : out std_logic;
    Sl_wrComp                 : out std_logic;
    Sl_rdDBus                 : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdDAck                 : out std_logic;
    Sl_rdComp                 : out std_logic;
    Sl_MBusy                  : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr                 : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr                 : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

    -- Unused Bus slave signals
    PLB_UABus                 : in  std_logic_vector(0 to 31);
    PLB_SAValid               : in  std_logic;
    PLB_rdPrim                : in  std_logic;
    PLB_wrPrim                : in  std_logic;
    PLB_abort                 : in  std_logic;
    PLB_busLock               : in  std_logic;
    PLB_MSize                 : in  std_logic_vector(0 to 1);
    PLB_lockErr               : in  std_logic;
    PLB_wrBurst               : in  std_logic;
    PLB_rdBurst               : in  std_logic;
    PLB_wrPendReq             : in  std_logic;
    PLB_rdPendReq             : in  std_logic;
    PLB_wrPendPri             : in  std_logic_vector(0 to 1);
    PLB_rdPendPri             : in  std_logic_vector(0 to 1);
    PLB_reqPri                : in  std_logic_vector(0 to 1);
    PLB_TAttribute            : in  std_logic_vector(0 to 15);

    -- Unused Slave Response Signals
    Sl_wrBTerm                : out std_logic;
    Sl_rdWdAddr               : out std_logic_vector(0 to 3);
    Sl_rdBTerm                : out std_logic;
    Sl_MIRQ                   : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

    -- IP Interconnect (IPIC) port signals -----------------------------------------
    Bus2IP_Clk              : out std_logic;
    Bus2IP_Reset            : out std_logic;
    IP2Bus_Data             : in  std_logic_vector (0 to 31); 
    IP2Bus_WrAck            : in  std_logic;
    IP2Bus_RdAck            : in  std_logic;
    IP2Bus_AddrAck          : in  std_logic;  
    IP2Bus_Error            : in  std_logic;
    Bus2IP_Addr             : out std_logic_vector (0 to 31);
    Bus2IP_Data             : out std_logic_vector (0 to 31);  
    Bus2IP_RNW              : out std_logic;
    Bus2IP_BE               : out std_logic_vector (0 to 3);  
    Bus2IP_Burst            : out std_logic;
    Bus2IP_BurstLength      : out std_logic_vector (0 to 7);
    Bus2IP_WrReq            : out std_logic;
    Bus2IP_RdReq            : out std_logic;
    Bus2IP_CS               : out std_logic;
    Bus2IP_RdCE             : out std_logic;
    Bus2IP_WrCE             : out std_logic;

    -- System Ports
     MPLB_Clk         : In  std_logic;
     MPLB_Rst         : In  std_logic;
     MD_error         : Out std_logic;
     
     -- Master Request/Qualifiers to PLB (outputs)
     M_request        : out std_logic;
     M_priority       : out std_logic_vector(0 to 1);
     M_busLock        : out std_logic;
     M_RNW            : out std_logic;
     M_BE             : out std_logic_vector(0 to (C_MPLB_DWIDTH/8) - 1);
     M_MSize          : out std_logic_vector(0 to 1);
     M_size           : out std_logic_vector(0 to 3);
     M_type           : out std_logic_vector(0 to 2);
     M_TAttribute     : out std_logic_vector(0 to 15);
     M_lockErr        : out std_logic;
     M_abort          : out std_logic;
     M_UABus          : out std_logic_vector(0 to 31);
     M_ABus           : out std_logic_vector(0 to 31);
     M_wrDBus         : out std_logic_vector(0 to C_MPLB_DWIDTH-1);
     M_wrBurst        : out std_logic;
     M_rdBurst        : out std_logic;

     -- PLB Reply to Master (inputs)
     PLB_MAddrAck     : in  std_logic;
     PLB_MSSize       : in  std_logic_vector(0 to 1);
     PLB_MRearbitrate : in  std_logic;
     PLB_MTimeout     : in  std_logic;
     PLB_MBusy        : in  std_logic;
     PLB_MRdErr       : in  std_logic;
     PLB_MWrErr       : in  std_logic;
     PLB_MIRQ         : in  std_logic;
     PLB_MRdDBus      : in  std_logic_vector(0 to C_MPLB_DWIDTH-1);
     PLB_MRdWdAddr    : in  std_logic_vector(0 to 3);
     PLB_MRdDAck      : in  std_logic;
     PLB_MRdBTerm     : in  std_logic;
     PLB_MWrDAck      : in  std_logic;
     PLB_MWrBTerm     : in  std_logic;
     
     
     -- IP Master Request/Qualifers
     IP2Bus_MstRd_Req           : In  std_logic;
     IP2Bus_MstWr_Req           : In  std_logic;
     IP2Bus_Mst_Addr            : in  std_logic_vector(0 to C_MPLB_AWIDTH-1);
     IP2Bus_Mst_BE              : in  std_logic_vector(0 to (C_MPLB_NATIVE_DWIDTH/8) -1);     
     IP2Bus_Mst_Lock            : In  std_logic;
     IP2Bus_Mst_Reset           : In  std_logic;
     
     -- IP Request Status Reply
     Bus2IP_Mst_CmdAck          : Out std_logic;
     Bus2IP_Mst_Cmplt           : Out std_logic;
     Bus2IP_Mst_Error           : Out std_logic;
     Bus2IP_Mst_Rearbitrate     : Out std_logic;
     Bus2IP_Mst_Cmd_Timeout     : out std_logic;
     
     
    -- IPIC Read data  
     Bus2IP_MstRd_d             : out std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1); 
     Bus2IP_MstRd_src_rdy_n     : Out std_logic;
     
    -- IPIC Write data  
     IP2Bus_MstWr_d             : In  std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1); 
     Bus2IP_MstWr_dst_rdy_n     : Out  std_logic
    );
end entity plbv46_wrapper;

-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------
architecture implementation of plbv46_wrapper is
-------------------------------------------------------------------------------
-- Constant Declarations

constant ZERO_PADS : std_logic_vector(0 to 31) := X"00000000";

-- Decoder address range definition constants starts
constant ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
        (
        ZERO_PADS & C_BASEADDR, -- IP user0 base address
	ZERO_PADS & C_HIGHADDR  -- IP user0 high address
        );
constant ARD_NUM_CE_ARRAY     : INTEGER_ARRAY_TYPE :=
        (
        0 => 1
        );
-- Decoder address range definition constants ends
-------------------------------------------------------------------------------
signal bus2IP_CS_i     : std_logic_vector(0 to (ARD_ADDR_RANGE_ARRAY'LENGTH/2)-1);
signal bus2IP_RdCE_i   : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
signal bus2IP_WrCE_i   : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);

signal Bus2IP_BurstLength_i : std_logic_vector (0 to log2(16 * (C_SPLB_DWIDTH/8)));

begin  -- architecture implementation

----------------------------------
-- INSTANTIATE PLBv46 SLAVE SINGLE
----------------------------------
   PLBv46_IPIF_I : entity plbv46_slave_burst_v1_01_a.plbv46_slave_burst
     generic map
      (
       C_ARD_ADDR_RANGE_ARRAY      => ARD_ADDR_RANGE_ARRAY,
       C_ARD_NUM_CE_ARRAY          => ARD_NUM_CE_ARRAY,

       C_SPLB_P2P                  => C_SPLB_P2P,
       C_SPLB_MID_WIDTH            => C_SPLB_MID_WIDTH,
       C_SPLB_NUM_MASTERS          => C_SPLB_NUM_MASTERS,
       C_SPLB_AWIDTH               => C_SPLB_AWIDTH,
       C_SPLB_DWIDTH               => C_SPLB_DWIDTH,
       C_SIPIF_DWIDTH              => C_SPLB_NATIVE_DWIDTH,
       C_FAMILY                    => C_FAMILY
      )
     port map
      (
      -- System signals ---------------------------------------------------
      SPLB_Clk                     => SPLB_Clk,
      SPLB_Rst                     => SPLB_Rst,
      -- Bus Slave signals ------------------------------------------------
      PLB_ABus                     => PLB_ABus,
      PLB_UABus                    => PLB_UABus,
      PLB_PAValid                  => PLB_PAValid,
      PLB_SAValid                  => PLB_SAValid,
      PLB_rdPrim                   => PLB_rdPrim,
      PLB_wrPrim                   => PLB_wrPrim,
      PLB_masterID                 => PLB_masterID,
      PLB_abort                    => PLB_abort,
      PLB_busLock                  => PLB_busLock,
      PLB_RNW                      => PLB_RNW,
      PLB_BE                       => PLB_BE,
      PLB_MSize                    => PLB_MSize,
      PLB_size                     => PLB_size,
      PLB_type                     => PLB_type,
      PLB_lockErr                  => PLB_lockErr,
      PLB_wrDBus                   => PLB_wrDBus,
      PLB_wrBurst                  => PLB_wrBurst,
      PLB_rdBurst                  => PLB_rdBurst,
      PLB_wrPendReq                => PLB_wrPendReq,
      PLB_rdPendReq                => PLB_rdPendReq,
      PLB_wrPendPri                => PLB_wrPendPri,
      PLB_rdPendPri                => PLB_rdPendPri,
      PLB_reqPri                   => PLB_reqPri,
      PLB_TAttribute               => PLB_TAttribute,
      -- Slave Response Signals -------------------------------------------
      Sl_addrAck                   => Sl_addrAck,
      Sl_SSize                     => Sl_SSize,
      Sl_wait                      => Sl_wait,
      Sl_rearbitrate               => Sl_rearbitrate,
      Sl_wrDAck                    => Sl_wrDAck,
      Sl_wrComp                    => Sl_wrComp,
      Sl_wrBTerm                   => Sl_wrBTerm,
      Sl_rdDBus                    => Sl_rdDBus,
      Sl_rdWdAddr                  => Sl_rdWdAddr,
      Sl_rdDAck                    => Sl_rdDAck,
      Sl_rdComp                    => Sl_rdComp,
      Sl_rdBTerm                   => Sl_rdBTerm,
      Sl_MBusy                     => Sl_MBusy,
      Sl_MWrErr                    => Sl_MWrErr,
      Sl_MRdErr                    => Sl_MRdErr,
      Sl_MIRQ                      => Sl_MIRQ,
      -- IP Interconnect (IPIC) port signals ------------------------------
      Bus2IP_Clk                   => Bus2IP_Clk,
      Bus2IP_Reset                 => Bus2IP_Reset,
      IP2Bus_Data                  => IP2Bus_Data,
      IP2Bus_WrAck                 => IP2Bus_WrAck,
      IP2Bus_RdAck                 => IP2Bus_RdAck,
      IP2Bus_AddrAck               => IP2Bus_AddrAck,
      IP2Bus_Error                 => IP2Bus_Error,
      Bus2IP_Addr                  => Bus2IP_Addr,
      Bus2IP_Data                  => Bus2IP_Data,
      Bus2IP_RNW                   => Bus2IP_RNW,
      Bus2IP_BE                    => Bus2IP_BE,
      Bus2IP_Burst                 => Bus2IP_Burst,
      Bus2IP_BurstLength           => Bus2IP_BurstLength_i,
      Bus2IP_WrReq                 => Bus2IP_WrReq,
      Bus2IP_RdReq                 => Bus2IP_RdReq,
      Bus2IP_CS                    => bus2IP_CS_i,
      Bus2IP_RdCE                  => bus2IP_RdCE_i,
      Bus2IP_WrCE                  => bus2IP_WrCE_i
      );
Bus2IP_CS   <= bus2IP_CS_i(0);
Bus2IP_RdCE <= bus2IP_RdCE_i(0);
Bus2IP_WrCE <= bus2IP_WrCE_i(0);
Bus2IP_BurstLength <= Bus2IP_BurstLength_i(0 to 7);
PLBv46_MAS_I : entity plbv46_master_single_v1_01_a.plbv46_master_single
generic map 
(
 C_MPLB_AWIDTH => C_MPLB_AWIDTH,
 C_MPLB_DWIDTH => C_MPLB_DWIDTH,
 C_MPLB_NATIVE_DWIDTH => C_MPLB_NATIVE_DWIDTH
 )
port map 
(

MPLB_Clk => MPLB_Clk,
MPLB_Rst => MPLB_Rst,

M_request => M_request,
M_priority => M_priority,
M_busLock => M_busLock,
M_RNW => M_RNW,
M_BE => M_BE,
M_MSize => M_MSize,
M_size => M_size,
M_type => M_type,
M_TAttribute => M_TAttribute,
M_lockErr => M_lockErr,
M_abort => M_abort,
M_UABus => M_UABus,
M_ABus => M_ABus,
M_wrDBus => M_wrDBus,
M_wrBurst => M_wrBurst,
M_rdBurst => M_rdBurst,

PLB_MAddrAck => PLB_MAddrAck,
PLB_MSSize => PLB_MSSize,
PLB_MRearbitrate => PLB_MRearbitrate,
PLB_MTimeout => PLB_MTimeout,
PLB_MBusy => PLB_MBusy,
PLB_MRdErr => PLB_MRdErr,
PLB_MWrErr => PLB_MWrErr,
PLB_MIRQ => PLB_MIRQ,
PLB_MRdDBus => PLB_MRdDBus,
PLB_MRdWdAddr => PLB_MRdWdAddr,
PLB_MRdDAck => PLB_MRdDAck,
PLB_MRdBTerm => PLB_MRdBTerm,
PLB_MWrDAck => PLB_MWrDAck,
PLB_MWrBTerm => PLB_MWrBTerm,


IP2Bus_MstRd_Req => IP2Bus_MstRd_Req,
IP2Bus_MstWr_Req => IP2Bus_MstWr_Req,
IP2Bus_Mst_Addr => IP2Bus_Mst_Addr,
IP2Bus_Mst_BE => IP2Bus_Mst_BE,
IP2Bus_Mst_Lock => IP2Bus_Mst_Lock,
IP2Bus_Mst_Reset => IP2Bus_Mst_Reset,

Bus2IP_Mst_CmdAck => Bus2IP_Mst_CmdAck,
Bus2IP_Mst_Cmplt => Bus2IP_Mst_Cmplt,
Bus2IP_Mst_Error => Bus2IP_Mst_Error,
Bus2IP_Mst_Rearbitrate => Bus2IP_Mst_Rearbitrate,
Bus2IP_Mst_Cmd_Timeout => Bus2IP_Mst_Cmd_Timeout,


Bus2IP_MstRd_d => Bus2IP_MstRd_d,
Bus2IP_MstRd_src_rdy_n => Bus2IP_MstRd_src_rdy_n,

IP2Bus_MstWr_d => IP2Bus_MstWr_d,
Bus2IP_MstWr_dst_rdy_n => Bus2IP_MstWr_dst_rdy_n
);
end architecture implementation;
