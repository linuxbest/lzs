#include "systemc.h"
#include <stdint.h>
#include <arpa/inet.h>
typedef uint32_t u32;

typedef struct soul_desc_hw {
	u32    next_dsr;
	u32    dma_address;
	u32    dma_length;
	u32    sts_ctrl_app0;

	u32    app1;
	u32    app2;
	u32    app3;
	u32    app4;
}*p_desc_hw, desc_hw;

enum {
	/* dma state and control bit */
	DMA_STS_CTRL_ERR = 0x80000000,
	DMA_STS_CTRL_INT = 0x40000000,
	DMA_STS_CTRL_CMP = 0x10000000,
	DMA_STS_CTRL_SOF = 0x08000000,
	DMA_STS_CTRL_EOF = 0x04000000,

	/* dma command set */
	DMA_CMD_C_SHIFT = 31, /* compress */
	DMA_CMD_D_SHIFT = 30, /* decompress */
	DMA_CMD_M_SHIFT = 29, /* memcpy */
	DMA_CMD_S_SHIFT = 28, /* state */

	/* dcr ranges from 0x80 */
	LL_TX_OFFSET     = 0x00000000,
	LL_RX_OFFSET     = 0x00000008,
	LL_DMACR_OFFSET  = 0x00000010,

	LL_NDESC_OFFSET  = 0x00000000,
	LL_BUFA_OFFSET   = 0x00000001,
	LL_BUFL_OFFSET   = 0x00000002,
	LL_CDESC_OFFSET  = 0x00000003,
	LL_TDESC_OFFSET  = 0x00000004,
	LL_CR_OFFSET     = 0x00000005,
	LL_IRQ_OFFSET    = 0x00000006,
	LL_SR_OFFSET     = 0x00000007,

	/* TX_RX irq state */
	TX_RX_IRQ_ERROR = 0x000000004,
	TX_RX_IRQ_DELAY = 0x000000002,
	TX_RX_IRQ_COALE = 0x000000001,
	TX_RX_IRQ_MASK  = 0x000000007,

	/* TX_RX channel control */
	TX_RX_IRQ_ALL_EN_MASK = 0x00000087,
	TX_RX_IRQ_INT_RELOAD  = 0x00000300,

	TX_IRQ_COUNT_COAL     = 0x00010000,
	TX_IRQ_TIMEOUT_COAL   = 0xd1000000,

	RX_IRQ_COUNT_COAL     = 0x00010000,
	RX_IRQ_TIMEOUT_COAL   = 0xd1000000,

	/* DMA Control */
	DMACR_SW_RESET_MASK     = 0x00000001,
	DMACR_TAIL_PTR_EN_MASK  = 0x00000004,
};
#define SIG_PACKET 3
SC_MODULE(lldma_tb)
{
public:
    /* plb slave */
    sc_in<bool>           Bus2IP_Clk;
    sc_in<bool>           Bus2IP_Reset;
    sc_out< sc_uint<32> > IP2Bus_Data;
    sc_out< bool >        IP2Bus_WrAck;
    sc_out< bool >        IP2Bus_RdAck;
    sc_out< bool >        IP2Bus_AddrAck;
    sc_out< bool >        IP2Bus_Error;
    sc_in < sc_uint<32> > Bus2IP_Addr;
    sc_in < sc_uint<32> > Bus2IP_Data;
    sc_in < bool >        Bus2IP_RNW;
    sc_in < sc_uint<4> >  Bus2IP_BE;
    sc_in < bool >        Bus2IP_Burst;
    sc_in < sc_uint<8> > Bus2IP_BurstLength;
    sc_in < bool >        Bus2IP_CS;
    sc_in < bool >        Bus2IP_WrReq;
    sc_in < bool >        Bus2IP_RdReq;
    sc_in < bool >        Bus2IP_RdCE;
    sc_in < bool >        Bus2IP_WrCE;

    /* plb master */
    sc_out <bool>          IP2Bus_MstRd_Req;
    sc_out <bool>          IP2Bus_MstWr_Req;
    sc_out < sc_uint<32> > IP2Bus_Mst_Addr;
    sc_out < sc_uint<4> >  IP2Bus_Mst_BE;
    sc_out <bool>          IP2Bus_Mst_Lock;
    sc_out <bool>          IP2Bus_Mst_Reset;

    sc_in <bool>           Bus2IP_Mst_CmdAck;
    sc_in <bool>           Bus2IP_Mst_Cmplt;
    sc_in <bool>           Bus2IP_Mst_Error;
    sc_in <bool>           Bus2IP_Mst_Rearbitrate;
    sc_in <bool>           Bus2IP_Mst_Cmd_Timeout;

    sc_in < sc_uint<32> >  Bus2IP_MstRd_d;
    sc_in <bool>           Bus2IP_MstRd_src_rdy_n;

    sc_out < sc_uint<32> > IP2Bus_MstWr_d;
    sc_in <bool>           Bus2IP_MstWr_dst_rdy_n;

    sc_in <bool>           tx_interrupt;
    sc_in <bool>           rx_interrupt;

    sc_out <bool>          DCR_Read;
    sc_out <bool>          DCR_Write;
    sc_out < sc_uint<10> > DCR_ABus;
    sc_out < sc_uint<32> > DCR_Sl_DBus;
    sc_in  <bool>          Sl_dcrAck;
    sc_in  < sc_uint<32> > Sl_dcrDBus;
    sc_in  <bool>          Sl_dcrTimeoutWait;

    void mem_model();
    void tb_thread();
    void dcr_out32(uint16_t off, uint32_t val);
    uint32_t dcr_in32(uint16_t off);

    void iomem_out32(uint32_t off, uint32_t val);
    uint32_t iomem_in32(uint32_t off);

    SC_CTOR(lldma_tb)
    {
	    SC_METHOD(mem_model);
	    sensitive_pos << Bus2IP_Clk;

	    SC_THREAD(tb_thread);
    }

    ~lldma_tb()
    {
    }
};

#define DEF_LEN 0x040
static int dma_base = 0x80;

static unsigned char base0[512*1024*1024];

void lldma_tb::tb_thread(void)
{
	unsigned int i = 0;
	int stage = 0, status;
	int err= 0;
	int j = 0;
	p_desc_hw tx_desc = (p_desc_hw)(base0);
	p_desc_hw rx_desc = (p_desc_hw)(base0 + 0x1000);

	/* I hardware initialization */
	DCR_Read.write(0);
	DCR_Write.write(0);
		/* initilization for dcr bus */
	for (i = 0; i < 100; i ++)
		wait(Bus2IP_Clk->posedge_event());

	dcr_out32(dma_base + LL_DMACR_OFFSET, DMACR_SW_RESET_MASK);

	status = DMACR_SW_RESET_MASK;
	while (status & DMACR_SW_RESET_MASK) {
		status = dcr_in32(dma_base + LL_DMACR_OFFSET);
	}

	/* using the tailer mode only */
	dcr_out32(dma_base + LL_DMACR_OFFSET, DMACR_TAIL_PTR_EN_MASK);

	/* enable rx/tx interrupts and coalescing */
	status = dcr_in32(dma_base + LL_TX_OFFSET + LL_CR_OFFSET);
	dcr_out32(dma_base +  LL_TX_OFFSET + LL_CR_OFFSET,
			status | TX_RX_IRQ_ALL_EN_MASK | TX_RX_IRQ_INT_RELOAD |
			TX_IRQ_COUNT_COAL | TX_IRQ_TIMEOUT_COAL);

	status = dcr_in32(dma_base + LL_RX_OFFSET + LL_CR_OFFSET);
	dcr_out32(dma_base + LL_RX_OFFSET + LL_CR_OFFSET,
			status | TX_RX_IRQ_ALL_EN_MASK | TX_RX_IRQ_INT_RELOAD |
			RX_IRQ_COUNT_COAL | RX_IRQ_TIMEOUT_COAL);

	dcr_out32(dma_base + LL_RX_OFFSET + LL_CDESC_OFFSET,
			(uint32_t)rx_desc-(uint32_t)base0);
	dcr_out32(dma_base + LL_TX_OFFSET + LL_CDESC_OFFSET,
		       	(uint32_t)tx_desc-(uint32_t)base0);

	/* II prepare the tx and rx desc */
		/* II.I header */
/*==============================================================*/
	tx_desc->next_dsr = htonl((u32)tx_desc + 32 - (u32)base0);
	tx_desc->dma_address = htonl(0x10000);
	tx_desc->dma_length  = htonl(DEF_LEN);
	tx_desc->sts_ctrl_app0 = htonl(DMA_STS_CTRL_SOF);
	tx_desc->app1 = htonl(1 << DMA_CMD_M_SHIFT);
	tx_desc->app2 = htonl(DEF_LEN * 3);

	rx_desc->next_dsr = htonl((u32)rx_desc + 32 -(u32)base0);
	rx_desc->dma_address = htonl(0x80000);
	rx_desc->dma_length  = htonl(DEF_LEN);
	rx_desc->sts_ctrl_app0 =  0;

		/* II.II middle */
        for (j = 0; j < SIG_PACKET -2; j ++) {
		tx_desc = (p_desc_hw)((u32)tx_desc + 32*(j+1));
		rx_desc = (p_desc_hw)((u32)rx_desc + 32*(j+1));

		tx_desc->next_dsr = htonl((u32)tx_desc + 32 - (u32)base0);
		tx_desc->dma_address = htonl(0x10000 + (j+1) * DEF_LEN);
		tx_desc->dma_length  = htonl(DEF_LEN);
		tx_desc->sts_ctrl_app0 = 0;

		rx_desc->next_dsr = htonl((u32)rx_desc + 32 - (u32)base0);
		rx_desc->dma_address = htonl(0x80000 + (j+1) * DEF_LEN);
		rx_desc->dma_length  = htonl(DEF_LEN);
		rx_desc->sts_ctrl_app0 = 0;
	}
		/* II.III footer */
	tx_desc = (p_desc_hw)((u32)tx_desc + 32);
	rx_desc = (p_desc_hw)((u32)rx_desc + 32);

	tx_desc->next_dsr = htonl((u32)tx_desc + 32 - (u32)base0);
	tx_desc->dma_address = htonl(0x10000 + (SIG_PACKET-1) * DEF_LEN);
	tx_desc->dma_length  = htonl(DEF_LEN);
	tx_desc->sts_ctrl_app0 =
		htonl(DMA_STS_CTRL_EOF | DMA_STS_CTRL_INT);

	rx_desc->next_dsr = htonl((u32)rx_desc + 32 - (u32)base0);
	rx_desc->dma_address = htonl(0x80000 + (SIG_PACKET-1) * DEF_LEN);
	rx_desc->dma_length  = htonl(DEF_LEN);
	rx_desc->sts_ctrl_app0 = htonl(DMA_STS_CTRL_INT);

		/* II.IV add 2 single packets */
/*-------------------------------------------------------------*/
	tx_desc = (p_desc_hw)((u32)tx_desc + 32);
	rx_desc = (p_desc_hw)((u32)rx_desc + 32);

	tx_desc->next_dsr = htonl((u32)tx_desc + 32 - (u32)base0);
	tx_desc->dma_address = htonl(0x10000 + SIG_PACKET * DEF_LEN);
	tx_desc->dma_length  = htonl(DEF_LEN);
	tx_desc->sts_ctrl_app0 =
		htonl(DMA_STS_CTRL_EOF | DMA_STS_CTRL_INT |DMA_STS_CTRL_SOF);
	tx_desc->app1 = htonl(1 << DMA_CMD_M_SHIFT);
	tx_desc->app2 = htonl(DEF_LEN);

	rx_desc->next_dsr = htonl((u32)rx_desc + 32 - (u32)base0);
	rx_desc->dma_address = htonl(0x80000 + SIG_PACKET * DEF_LEN);
	rx_desc->dma_length  = htonl(DEF_LEN);
	rx_desc->sts_ctrl_app0 = htonl(DMA_STS_CTRL_INT);

/*-------------------------------------------------------------*/
	tx_desc = (p_desc_hw)((u32)tx_desc + 32);
	rx_desc = (p_desc_hw)((u32)rx_desc + 32);

	tx_desc->next_dsr = 0;
	tx_desc->dma_address = htonl(0x10000 + (SIG_PACKET+1) * DEF_LEN);
	tx_desc->dma_length  = htonl(DEF_LEN);
	tx_desc->sts_ctrl_app0 =
		htonl(DMA_STS_CTRL_EOF | DMA_STS_CTRL_INT| DMA_STS_CTRL_SOF);
	tx_desc->app1 = htonl(1 << DMA_CMD_M_SHIFT);
	tx_desc->app2 = htonl(DEF_LEN);

	rx_desc->next_dsr = 0;
	rx_desc->dma_address = htonl(0x80000 + (SIG_PACKET+1) * DEF_LEN);
	rx_desc->dma_length  = htonl(DEF_LEN);
	rx_desc->sts_ctrl_app0 = htonl(DMA_STS_CTRL_INT);

/***************************************************************/
	/* III feed the data */
	for(i = 0; i < 4096 * (SIG_PACKET + 2); i+=4)
		*(unsigned int *)(base0 + 0x10000 +i) = htonl(i);
		/* flush the plb */
	for (i = 0; i < 0x100; i++)
		wait(Bus2IP_Clk->posedge_event());
	/* IV launch */

	dcr_out32(dma_base + LL_RX_OFFSET + LL_TDESC_OFFSET,
			(uint32_t)rx_desc-(uint32_t)base0);
	dcr_out32(dma_base + LL_TX_OFFSET + LL_TDESC_OFFSET,
			(uint32_t)tx_desc-(uint32_t)base0);

	printf("issue the task completed.\n");
	/* V wait for interrupt */
	for(;;) {
		wait(Bus2IP_Clk->posedge_event());
#if 0
		if (tx_interrupt.read()) {
			stage++;
			status = dcr_in32(dma_base +  LL_TX_OFFSET + LL_IRQ_OFFSET);
			dcr_out32(dma_base +  LL_TX_OFFSET + LL_IRQ_OFFSET, status);
			printf("tx interrupt is on.\n");
		}
#endif
		if (rx_interrupt.read()) {
			stage++;
			status = dcr_in32(dma_base +  LL_RX_OFFSET + LL_IRQ_OFFSET);
			dcr_out32(dma_base +  LL_RX_OFFSET + LL_IRQ_OFFSET, status);
			printf("rx interrupt is on.\n");
		}
		if (stage == 3)
			break;
	}
		/* flush the data */
	for (i = 0; i < 0x100; i++)
		wait(Bus2IP_Clk->posedge_event());

	printf("prepare to verify the result.\n");

	/* VI verification */
	for(i = 0; i < DEF_LEN * (SIG_PACKET + 2); i+=4) {
		if(*(unsigned int *)(base0 + 0x80000 +i) != ntohl(i)) {
			printf("[%x]!=[%x]\n", i, *(unsigned int*)(base0 + 0x80000 + i));
			err++;
		}
	}

	if (err != 0) 
		printf("failed.\n");
	else
		printf("passed.\n");
}

/*
 * wrapper function for dcr read/write
 */
void lldma_tb::dcr_out32(uint16_t off, uint32_t val)
{
	int i;
	DCR_Write.write(1);
	DCR_ABus.write(off);
	DCR_Sl_DBus.write(val);
	for (i = 0; i < 16; i++) {
		wait (Bus2IP_Clk->posedge_event());
		if (Sl_dcrAck.read())
			break;
		/*printf("%s: dcr out %08x, %08x\n",
				sc_time_stamp().to_string().c_str(), off, val);*/
	}
	DCR_Write.write(0);
        DCR_Sl_DBus.write(0);
	wait (Bus2IP_Clk->posedge_event());
}

uint32_t lldma_tb::dcr_in32(uint16_t off)
{
	uint32_t val, i;
	DCR_Read.write(1);
	DCR_ABus.write(off);
	for (i = 0; i < 16; i ++) {
		wait (Bus2IP_Clk->posedge_event());
		val = Sl_dcrDBus.read();
		if (Sl_dcrAck.read())
			break;
		/*printf("%s: dcr in %08x, %08x\n",
				sc_time_stamp().to_string().c_str(), off, val);*/
	}
	DCR_Read.write(0);
	wait (Bus2IP_Clk->posedge_event());
	return val;
}
/*
 * wrapper function for iomem read/write
 */
void lldma_tb::iomem_out32(uint32_t off, uint32_t val)
{
	IP2Bus_MstWr_Req.write(1);
	IP2Bus_Mst_Addr.write(off);
	IP2Bus_Mst_BE.write(0xf);

	IP2Bus_MstWr_d.write(val);

	for(;;) {
		wait (Bus2IP_Clk->posedge_event());
		if (Bus2IP_Mst_CmdAck.read())
			break;
	}
	IP2Bus_MstWr_Req.write(0);
	for(;;) {
		wait (Bus2IP_Clk->posedge_event());
		if (Bus2IP_Mst_Cmplt.read())
				break;
	}
}

uint32_t lldma_tb::iomem_in32(uint32_t off)
{
	uint32_t val;
	IP2Bus_MstRd_Req.write(1);
	IP2Bus_Mst_Addr.write(off);
	IP2Bus_Mst_BE.write(0);

	for(;;) {
		wait (Bus2IP_Clk->posedge_event());
		if (Bus2IP_Mst_CmdAck.read())
			break;
	}
	IP2Bus_MstRd_Req.write(0);
	for (;;) {
		wait (Bus2IP_Clk->posedge_event());
		if (Bus2IP_MstRd_src_rdy_n.read() == 0)
			break;
	}
	return Bus2IP_MstRd_d.read();
}

/*
 * memory model
 */
void lldma_tb::mem_model()
{
	uint32_t val = 0;
	static uint32_t addr, burst = 0;
	
	/* TODO hope in burst mode the address is only first address */
	if (Bus2IP_CS.read() == 0) {
		IP2Bus_RdAck.write(0);
		IP2Bus_WrAck.write(0);
		IP2Bus_AddrAck.write(0);
		burst = 0;
		return;
	} else if (burst == 0 && Bus2IP_Burst.read()) { /* cal for burst read */
		addr = Bus2IP_Addr.read();
		addr &= 0x1fffffff;
		burst = 1;
	}
	if (Bus2IP_WrReq.read()) {/* writing using the address direct is ok */
		addr = Bus2IP_Addr.read();
		addr &= 0x1fffffff;
		val = Bus2IP_Data.read();
		base0[addr+3] = (val >> 0 ) & 0xff;
		base0[addr+2] = (val >> 8 ) & 0xff;
		base0[addr+1] = (val >> 16) & 0xff;
		base0[addr+0] = (val >> 24) & 0xff;
		IP2Bus_AddrAck.write(1);
		IP2Bus_WrAck.write(1);
	} else if (Bus2IP_RdReq.read() && burst) { /* must cal my our self */
		val =   (base0[addr+3] << 0)| 
			(base0[addr+2] << 8)|
			(base0[addr+1] << 16)|
			(base0[addr+0] << 24);
		IP2Bus_Data.write(val);
		IP2Bus_RdAck.write(1);
		IP2Bus_AddrAck.write(1);
	} else if (Bus2IP_RdCE.read()) {
		addr = Bus2IP_Addr.read();
		addr &= 0x1fffffff;
		val =   (base0[addr+3] << 0)| 
			(base0[addr+2] << 8)|
			(base0[addr+1] << 16)|
			(base0[addr+0] << 24);
		IP2Bus_Data.write(val);
		IP2Bus_RdAck.write(1);
		IP2Bus_AddrAck.write(0);
	}
	if (burst && (Bus2IP_WrReq.read()|Bus2IP_RdReq.read())) {
		addr += 4;
	}
}

/*
 * export systemC
 */
SC_MODULE_EXPORT(lldma_tb);
