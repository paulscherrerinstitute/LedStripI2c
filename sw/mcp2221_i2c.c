
/* User-space 'driver' for Microchip MPC 2221A usb-i2c bridge
 */

#include <stdio.h>
#include <stdlib.h>
#include <libusb-1.0/libusb.h>
#include <inttypes.h>
#include <assert.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>

struct Mcp2221Buf {
	uint8_t                  b[64];
};

struct ErrfnCtx {
	FILE *f;
};

typedef int (*Errfn)(struct ErrfnCtx *, const char *, ...);

struct mcp2221_dev {
    libusb_context          *ctx;
    libusb_device_handle    *devh;
    int                      rendp;
    int                      wendp;
    int                      intf;
	int                      dir;
	unsigned int             timeout_ms;
    Errfn                    errfn;
    struct ErrfnCtx         *errfp;
};


#define MICROCHIP_VENDID 0x04d8
#define MCP2221_DEVID    0x00dd

#define DIR_WR 1

#define MCP2221_SYSFREQ  12000000UL

#define AUTO_INC         0x80

static struct mcp2221_dev *devalloc()
{
struct mcp2221_dev *rval = malloc(sizeof(*rval));
	if ( rval ) {
		rval->ctx   =  0;
		rval->devh  =  0;
		rval->dir   = DIR_WR;
		rval->rendp = -1;
		rval->wendp = -1;
		rval->intf  = -1;
	}
	return rval;
}

void
mcp2221_dev_destroy(struct mcp2221_dev *dev)
{
	if ( !dev )
		return;

	if ( dev->devh && dev->intf >= 0 )
		libusb_release_interface( dev->devh, dev->intf );

	if ( dev->devh ) {
		libusb_close( dev->devh );
	}

	if ( dev->ctx )
		libusb_exit( dev->ctx );

	free(dev);
}

static int
errfn_silent(struct ErrfnCtx *errfnp, const char *fmt, ...)
{
	return 0;
}

static int
errfn_stderr(struct ErrfnCtx *ctx, const char *fmt, ...)
{
va_list ap;
int    rval;

	va_start(ap, fmt);
		rval = vfprintf(ctx->f ? ctx->f : stderr, fmt, ap);
	va_end(ap);

    return rval;
}

static struct ErrfnCtx errfnToStderr = {
  f : 0,
};

static struct ErrfnCtx *errfp_stderr = &errfnToStderr;

struct mcp2221_dev *
mcp2221_dev_create_1(int verbose, uint16_t vid, uint16_t pid, Errfn errfn, struct ErrfnCtx *errfp, unsigned int timeout_ms)
{
struct mcp2221_dev                          *rval = 0;
struct libusb_config_descriptor              *cfg = 0;
int                              i, l, hask, st;
struct mcp2221_dev                         *dev;
const struct libusb_endpoint_descriptor      *e;

	if ( ! (dev = devalloc()) ) {
		errfn(errfp, "No memory for device struct\n");
		return 0;
	}

	dev->timeout_ms = timeout_ms;

	if ( libusb_init( &dev->ctx ) ) {
		errfn(errfp, "Context init failed\n");
		goto bail;
	}

	if ( vid && pid ) {
		if ( ! (dev->devh = libusb_open_device_with_vid_pid( dev->ctx, vid, pid) ) ) {
			errfn(errfp, "Unable to find device 0x%04x:0x%04x\n", vid, pid);
			goto bail;
		}
	} else {
		errfn(errfp, "Missing VENDOR_ID or PRODUCT_ID\n");
		goto bail;
	}

	if ( libusb_get_active_config_descriptor( libusb_get_device( dev->devh ), &cfg ) ) {
		errfn(errfp, "Unable to get active configuration\n");
		goto bail;
	}

	for ( i = 0; i < cfg->bNumInterfaces; i++ ) {

		/* FIXME: should we care about altsettings? */

		if ( LIBUSB_CLASS_HID == cfg->interface[i].altsetting[0].bInterfaceClass ) {
			hask = libusb_kernel_driver_active( dev->devh, i );
			if ( verbose ) {
				printf("Interface (CLASS HID) #%i has %s active kernel driver\n", i, hask ? "a" : "no");
			}
			if ( hask ) {
				if ( (st = libusb_detach_kernel_driver( dev->devh, i )) ) {
					errfn(errfp, "Unable to detach kernel driver (interface #%i): %i\n", i, st);
					goto bail;
				} else {
					if ( verbose )
						printf("Kernel driver successfully detached\n");
				}
			}

			e = cfg->interface[i].altsetting[0].endpoint;

			for ( l = 0; l < cfg->interface[i].altsetting[0].bNumEndpoints; l++, e++ ) {
				if ( LIBUSB_TRANSFER_TYPE_INTERRUPT != (LIBUSB_TRANSFER_TYPE_MASK & e->bmAttributes) )
					continue;

				if ( (LIBUSB_ENDPOINT_DIR_MASK & e->bEndpointAddress) ) {
					if ( dev->rendp >= 0 ) {
						errfn(errfp, "Error: Multiple IN endpoints???\n");
						goto bail;
					}
					dev->rendp = e->bEndpointAddress;
				} else {
					if ( dev->wendp >= 0 ) {
						errfn(errfp, "Error: Multiple OUT endpoints???\n");
						goto bail;
					}
					dev->wendp = e->bEndpointAddress;
				}
			}
			break;
		}
	}

	if ( dev->rendp < 0 ) {
		errfn(errfp, "Unable to determine IN endpoint!\n");
		goto bail;
	}
	if ( dev->wendp < 0 ) {
		errfn(errfp, "Unable to determine OUT endpoint!\n");
		goto bail;
	}

	assert( i < cfg->bNumInterfaces );

	dev->intf = cfg->interface[i].altsetting[0].bInterfaceNumber;

	if ( verbose )
		printf("Using intf %u / endpoints: IN - 0x%02x OUT - 0x%02x\n", dev->intf, dev->rendp, dev->wendp);
	if ( (st = libusb_claim_interface( dev->devh, dev->intf ) ) ) {
		errfn(errfp, "Unable to claim interface %u: %i\n", dev->intf, st);
		goto bail;
	}

	dev->errfn = errfn;
	dev->errfp = errfp;

	/* initially, we don't know if the last operation was
	 * read or write since it may have happened before our
	 * life-time...
	 */
	dev->dir   = DIR_WR;

	rval = dev;
	dev  = 0;

bail:

	if ( cfg ) {
		libusb_free_config_descriptor( cfg );
	}

	mcp2221_dev_destroy( dev );

	return rval;
}

struct mcp2221_dev *
mcp2221_dev_create(int verbose, uint16_t vid, uint16_t pid)
{
	return mcp2221_dev_create_1( verbose, vid, pid, errfn_stderr, errfp_stderr, -1 );
}

static int
mcp2221_xfer(struct mcp2221_dev *dev, struct Mcp2221Buf *ibuf, struct Mcp2221Buf *obuf)
{
int st, put, got;

	if ( ! obuf ) {
		obuf = ibuf;
	}

	if ( (st = libusb_interrupt_transfer( dev->devh, dev->wendp, ibuf->b, sizeof(ibuf->b), &put, dev->timeout_ms)) ) {
		dev->errfn(dev->errfp, "mcp2221_xfer: WRITE XFER failed: %i\n", st);
		return st;
	}

	if ( put != sizeof(ibuf->b) ) {
		dev->errfn(dev->errfp, "mcp2221_xfer: WRITE XFER failed -- not all data written (only %i)\n", put);
		return LIBUSB_ERROR_IO;
	}

	if ( (st = libusb_interrupt_transfer( dev->devh, dev->rendp, obuf->b, sizeof(obuf->b), &got, dev->timeout_ms)) ) {
		dev->errfn(dev->errfp, "mcp2221_xfer: READ XFER failed: %i\n", st);
		return st;
	}

	if ( got != sizeof(obuf->b) ) {
		dev->errfn(dev->errfp, "mcp2221_xfer: READ XFER failed -- not all data read (only %i)\n", got);
		return LIBUSB_ERROR_IO;
	}

	return 0;
}

int
mcp2221_status_get(struct mcp2221_dev *dev, struct Mcp2221Buf *buf, int cancel, unsigned long speed)
{
int               st;
struct Mcp2221Buf mybuf;

	if ( !buf ) {
		buf = &mybuf;
	}

	buf->b[0] = 0x10;
	buf->b[1] = 0x00;
	buf->b[2] = (cancel ? 0x10 : 0x00);
	buf->b[3] = (speed  ? 0x20 : 0x00);
    buf->b[4] = (speed  ? MCP2221_SYSFREQ / speed : 0x00 );

	if ( (st = mcp2221_xfer( dev, buf, buf )) ) {
		dev->errfn(dev->errfp, "mcp2221_status_get(): transfer failed\n");
		return st;
	}
	return 0;
}

int
mcp2221_status(struct mcp2221_dev *dev, int cancel, unsigned long speed)
{
struct Mcp2221Buf buf;
int               st;


	if ( (st = mcp2221_status_get( dev, &buf, cancel, speed )) ) {
		dev->errfn(dev->errfp, "mcp2221_status(): transfer failed\n");
		return st;
	}

	printf("Current data buf cntr: %u\n", buf.b[13]);
	printf("Current speed divider: %u\n", buf.b[14]);
	printf("Current i2c timeout  : %u\n", buf.b[15]);
	printf("Current SCL pin value: %u\n", buf.b[22]);
	printf("Current SDA pin value: %u\n", buf.b[23]);
	printf("Current i2c r-pending: %u\n", buf.b[25]);

	return 0;
}

static int
mcp2221_drain(struct mcp2221_dev *dev)
{
struct Mcp2221Buf buf;
int               st;
	do {

		if ( (st = mcp2221_status_get(dev, &buf, 0, 0)) ) {
			return st;
		}

	} while ( buf.b[13] != 0 );
	
	return 0;
}

int
mcp2221_start_write(struct mcp2221_dev *dev, uint8_t sla, uint8_t *data, unsigned len, int stop)
{
struct Mcp2221Buf buf;
int               st;

	if ( len > 60 ) {
		dev->errfn( dev->errfp, "mcp2221_start_write(): Writing more than 60 bytes currently not supported\n");
		return LIBUSB_ERROR_INVALID_PARAM;
	}

	buf.b[0] = (stop ? 0x90 : 0x94);
	buf.b[1] = (len >> 0) & 0xff;
	buf.b[2] = (len >> 8) & 0xff;
    buf.b[3] = (sla<<1);
	if ( len > 0 ) {
		memcpy(buf.b + 4, data, len);
	}

	if ( (st = mcp2221_xfer(dev, &buf, &buf)) ) {
		dev->errfn( dev->errfp, "mcp2221_start_write(): transfer failed\n");
		return st;
	}

	if ( 0x00 != buf.b[1] ) {
		dev->errfn( dev->errfp, "mcp2221_start_write(): transfer failed (I2C was busy)\n");
		return LIBUSB_ERROR_BUSY;
	}
	

}

int
mcp2221_start_read(struct mcp2221_dev *dev, uint8_t sla, uint8_t *data, unsigned len, int restart)
{
struct Mcp2221Buf buf;
int               st;

	if ( len > 60 ) {
		dev->errfn( dev->errfp, "mcp2221_start_read(): Writing more than 60 bytes currently not supported\n");
		return LIBUSB_ERROR_INVALID_PARAM;
	}

	buf.b[0] = (restart ? 0x93 : 0x91);
	buf.b[1] = (len >> 0) & 0xff;
	buf.b[2] = (len >> 8) & 0xff;
    buf.b[3] = (sla<<1) | 1;

	if ( (st = mcp2221_xfer(dev, &buf, &buf)) ) {
		dev->errfn( dev->errfp, "mcp2221_start_read(): command transfer failed\n");
		return st;
	}

	if ( 0x00 != buf.b[1] ) {
		dev->errfn( dev->errfp, "mcp2221_start_read(): transfer failed (I2C was busy)\n");
		return LIBUSB_ERROR_BUSY;
	}

	mcp2221_drain(dev);

	buf.b[0] = 0x40;

	if ( (st = mcp2221_xfer(dev, &buf, &buf)) ) {
		dev->errfn( dev->errfp, "mcp2221_start_read(): readout transfer failed\n");
		return st;
	}

	if ( 0x00 != buf.b[1] || 60 < buf.b[3] ) {
		fprintf(stderr, "buf[1]: 0x%02x, buf[3]: 0x%02x\n", buf.b[1], buf.b[3]);
		dev->errfn( dev->errfp, "mcp2221_start_read(): readout error\n");
		return LIBUSB_ERROR_IO;
	}
	
	if ( len > buf.b[3] ) {
		len = buf.b[3];
	}
	memcpy(data, buf.b + 4, len);
	return len;
}

#if 0

static int
mcp2221_i2c_wr( cy32xx_dev *dev , uint8_t sla, uint8_t *buf, unsigned len )
{
int st, put;

	if ( 4 != sla ) {
		dev->errfn(dev->errfp, "Slave address must be 4\n");
		return CY32XX_INVALID_SLA;
	}

	if ( (st = libusb_interrupt_transfer( dev->devh, dev->wendp, buf, len, &put, dev->timeout_ms)) ) {
		dev->errfn(dev->errfp, "WRITE XFER failed: %i\n", st);
		return st;
	}

	dev->dir = DIR_WR;
	return put;
}

static int
mcp2221_rd( cy32xx_dev *dev , uint8_t sla, uint8_t *buf, unsigned len )
{
int     st, got;
uint8_t dbuf[1];

	if ( 4 != sla ) {
		dev->errfn(dev->errfp, "Slave address must be 4\n");
		return CY32XX_INVALID_SLA;
	}

	if ( len > 16 ) {
		/* cy3270 can only read 16 bytes at a time */
		len = 16;
	}

	if ( DIR_RD != dev->dir ) {
		/* Do 'dummy' read -- seems necessary to make changes visible with next 'real' read */
		if ( (st = libusb_interrupt_transfer( dev->devh, dev->rendp, dbuf, sizeof(dbuf), &got, dev->timeout_ms) ) ) {
			dev->errfn(dev->errfp, "WRITE XFER Dummy read failed: %i\n", st);
			return st;
		}
		dev->dir = DIR_RD;
	}

	if ( (st = libusb_interrupt_transfer( dev->devh, dev->rendp, buf, len, &got, dev->timeout_ms)) ) {
		dev->errfn(dev->errfp, "READ XFER failed: %i\n", st);
		return st;
	}
	return got;
}

int
cy32xx_read( cy32xx_dev *dev , uint8_t sla, uint8_t *buf, unsigned len )
{
	return dev->ops->read( dev, sla, buf, len );
}

int
cy32xx_write( cy32xx_dev *dev , uint8_t sla, uint8_t *buf, unsigned len )
{
	return dev->ops->write( dev, sla, buf, len );
}

#define CY3240_CTRL_READ  (1<<0)	/* Read    */
#define CY3240_CTRL_STRT  (1<<1)	/* Start   */
#define CY3240_CTRL_REST  (1<<2)	/* Restart */
#define CY3240_CTRL_STOP  (1<<3)	/* Stop    */
#define CY3240_CTRL_INIT  (1<<4)	/* Init    */
#define CY3240_CTRL_CNFG  (1<<5)	/* Config  */
#define CY3240_CTRL_TI2C  (0<<6)	/* Bustype */

#define CY3240_CTRL_CFG_SPEED_50	(2<<2)
#define CY3240_CTRL_CFG_SPEED_100	(0<<1)
#define CY3240_CTRL_CFG_SPEED_400	(1<<2)

#define CY3240_LENG_MORE        0x80

#define CY3240_INTRN_SLA		0x80	/* Slave address for internal operation */
#define CY3240_INTRN_PWR_EXT	0
#define CY3240_INTRN_PWR_5V 	1
#define CY3240_INTRN_PWR_3V 	2

#define CY3240_BUFLEN           64

#define CY3240_CTRL_OFF			0
#define CY3240_STAT_OFF			0
#define CY3240_LENG_OFF			1
#define CY3240_RSLT_OFF			1
#define CY3240_ADDR_OFF			2
#define CY3240_DATA_OFF			3

#define CY3240_LEN_MAX         61


static int cy3240_check( const char *nm, cy32xx_dev *dev )
{
	if ( CYPRESS_VENDID != dev->ops->vendid || CY3240_DEVID != dev->ops->devid ) {
		dev->errfn(dev->errfp, "%s called for unsupported device 0x%04"PRIx16"\n", nm, dev->ops->devid);
		return CY32XX_UNSUPPORTED;
	}
	return 0;
}


int
cy3240_config( cy32xx_dev *dev, uint8_t ctrl )
{
uint8_t buf[CY3240_BUFLEN];
int     st;
int     got,put;

	if ( (got = cy3240_check( "cy3240_config()", dev )) )
		return got;

	ctrl |= CY3240_CTRL_CNFG;

	buf[CY3240_CTRL_OFF] = ctrl;
	buf[CY3240_LENG_OFF] = 0;

	if ( (st = libusb_interrupt_transfer( dev->devh, dev->wendp, buf, sizeof(buf), &put, dev->timeout_ms)) ) {
		dev->errfn(dev->errfp, "WRITE XFER failed: %i\n", st);
		return st;
	}
	if ( (st = libusb_interrupt_transfer( dev->devh, dev->rendp, buf, sizeof(buf), &got, dev->timeout_ms) ) ) {
		dev->errfn(dev->errfp, "READ XFER failed: %i\n", st);
		return st;
	}
	if ( ! buf[CY3240_STAT_OFF] ) {
		dev->errfn(dev->errfp, "I2C Configuration returned with bad status %"PRIu8"\n", buf[CY3240_STAT_OFF]);
		return CY3240_BADCONFIGST;
	}
	return 1;
}

#define ERRBUFLEN 256
struct errfn_args {
	int     len;
	char    buf[];
};

static int
errfn_buf(cy32xx_errfn_param errfp, const char *fmt, ...)
{
va_list ap;
struct errfn_args *arg = (struct errfn_args*)errfp;
int    rval;

	va_start(ap, fmt);
		rval = vsnprintf(arg->buf, arg->len, fmt, ap );
	va_end(ap);
	return rval;
}

uint8_t *
cy32xx_scanbus( cy32xx_dev *dev )
{
uint8_t            buf[64];
uint8_t            sla, ctl;
uint8_t            *rval = 0;
int                st, k;
cy32xx_errfn       errfn_orig;
cy32xx_errfn_param errfp_orig;
struct errfn_args  *args = 0;

	ctl = CY3240_CTRL_STRT | CY3240_CTRL_STOP | CY3240_CTRL_READ;

	rval = malloc( sizeof(*rval) * 129 );

	args = malloc( sizeof(*args) + ERRBUFLEN );
	args->len = ERRBUFLEN;

	errfn_orig = dev->errfn;
	errfp_orig = dev->errfp;
	cy32xx_set_errfn( dev, errfn_buf, args );
	for ( sla = 0, k = 0; sla < 128; sla++ ) {
		if ( 0 == (st = cy32xx_read( dev, sla, buf, 0 )) ) {
			rval[k++] = sla;
		} else {
			if ( CY32XX_SLAVENOTFND != st ) {
				errfn_orig(errfp_orig, "%s", args->buf);
			}
		}
	}
	cy32xx_set_errfn( dev, errfn_orig, errfp_orig );
	free ( args );

	rval[k] = CY32XX_SLA_NONE;

	return rval;
}

#define SLA_NOSTART 0xffff

int
cy3240_xact( cy32xx_dev *dev, uint8_t rw, unsigned sla, uint8_t *dta, unsigned len )
{
uint8_t buf[CY3240_BUFLEN];
int     st;
int     put,got,i;
uint8_t ctrl;

	if ( (got = cy3240_check( "cy3240_xact()", dev )) )
		return got;

	if ( len > CY3240_LEN_MAX ) {
		dev->errfn(dev->errfp, "Requested transfer length > %u not supported; clamping...\n", CY3240_LEN_MAX);
		len = CY3240_LEN_MAX;
	}

	ctrl = 0;
	
	if ( sla != SLA_NOSTART )
		ctrl |= CY3240_CTRL_STRT;
	if ( dta )
		ctrl |= CY3240_CTRL_STOP;

	if ( rw ) {
		ctrl |= CY3240_CTRL_READ;
	} else {
		if ( dta )
			memcpy( &buf[CY3240_DATA_OFF], dta, len );
	}

	buf[CY3240_CTRL_OFF] = ctrl;
	buf[CY3240_LENG_OFF] = len;
	buf[CY3240_ADDR_OFF] = SLA_NOSTART == sla ? /* should't' matter */ 0 : sla;

printf("Writing...\n");
	if ( (st = libusb_interrupt_transfer( dev->devh, dev->wendp, buf, sizeof(buf), &put, dev->timeout_ms)) ) {
		dev->errfn(dev->errfp, "WRITE XFER failed: %i\n", st);
		return st;
	}

printf("Done.\nReading...\n");
	if ( (st = libusb_interrupt_transfer( dev->devh, dev->rendp, buf, sizeof(buf), &got, dev->timeout_ms) ) ) {
		dev->errfn(dev->errfp, "READ XFER failed: %i\n", st);
		return st;
	}
printf("Done.\n");

	if ( ! buf[CY3240_STAT_OFF] ) {
		dev->errfn(dev->errfp, "I2C Transfer failed with zero status (slave not found)\n");
		return CY32XX_SLAVENOTFND;
	}

	if ( rw ) {
		if ( dta )
			memcpy( dta, &buf[CY3240_RSLT_OFF], len );
	} else {
		for ( i=0; i<len-1; i++ ) {
			if ( !buf[CY3240_RSLT_OFF + i] ) {
				dev->errfn(dev->errfp, "I2C-Write: only %u bytes ACKed!\n", i);
				return i+1;
			}
		}
	}
	return len;
}

static int
cy3240_rd( cy32xx_dev *dev, uint8_t sla, uint8_t *buf, unsigned len )
{
	if ( sla > 127 ) {
		dev->errfn(dev->errfp, "cy3240_rd(): slave address must be < 128\n");
		return CY32XX_INVALID_SLA;
	}

	return cy3240_xact( dev, 1, sla, buf, len );
}

static int
cy3240_wr( cy32xx_dev *dev, uint8_t sla, uint8_t *buf, unsigned len )
{
	if ( sla > 127 ) {
		dev->errfn(dev->errfp, "cy3240_wr(): slave address must be < 128\n");
		return CY32XX_INVALID_SLA;
	}
	return cy3240_xact( dev, 0, sla, buf, len );
}

static int cy3240_in(cy32xx_dev *dev)
{
uint8_t dbuf[64];
int     st, got;
	/* By protocol-sniffing I found that this initial transfer is necessary
	 * in order to get the green light on the bridge to show and the
	 * thing to respond to further requests.
	 * Note that the transfer actually fails/times-out which we ignore...
	 */
	if ( (st = libusb_interrupt_transfer( dev->devh, dev->rendp, dbuf, sizeof(dbuf), &got, 100) ) ) {
#if 0
		dev->errfn(dev->errfp, "cy32xx_in: initial read failed: %i\n", st);
#endif
	}
	return 0;
}

#define CY3240_PWR(mode) (((mode)>>16) & 0xff)
#define CY3240_CLK(mode) (((mode)>> 8) & 0xff)
#define CY3240_MODE_VDEV	0x40
#define CY3240_MODE_INTP	0x20
#define CY3240_MODE_OK  	0x01

int
cy3240_mode_read( cy32xx_dev *dev )
{
uint8_t dta[2];
int     st;
	
	st = cy3240_xact( dev, 1, CY3240_INTRN_SLA, dta, sizeof(dta) );

	if ( st < 0 )
		return st;

	return (dta[0] << 16) | (dta[1] <<8) | st;
}

int
cy3240_pwr_set( cy32xx_dev *dev, uint8_t pwr )
{
int st;

	st = cy3240_xact( dev, 0, CY3240_INTRN_SLA, &pwr, 1 );

	return st < 0 ? st : 0;
}

const char *
cy32xx_get_desc( cy32xx_dev *dev )
{
	return dev->ops->desc;
}
#endif

int
mcp2221_rd_reg(struct mcp2221_dev *dev, uint8_t sla, uint8_t roff)
{
int st;
uint8_t val;

	if ( (st = mcp2221_start_write(dev, sla, &roff, 1, 0)) ) {
		return st;
	}
	if ( (st = mcp2221_start_read (dev, sla, &val, 1, 1)) < 0 ) {
		return st;
	}
	return val;
}

int
mcp2221_wr_reg(struct mcp2221_dev *dev, uint8_t sla, uint8_t roff, uint8_t val)
{
int     st;
uint8_t buf[2];

	buf[0] = roff;
	buf[1] = val;

	if ( (st = mcp2221_start_write(dev, sla, buf, sizeof(buf), 1)) ) {
		return st;
	}
	return 0;
}

static int
set_led(struct mcp2221_dev *dev, uint8_t sla, int led, uint8_t pwm, uint8_t iref)
{
int     f, t, st;
uint8_t pwreg = 0x08;
uint8_t irreg = 0x18;

	if ( led > 15 ) {
		return LIBUSB_ERROR_INVALID_PARAM;
	}

	if ( led < 0 ) {
		f = 0; t = 15;
	} else {
		f = t = led;
	}

	for ( ; f <= t; f++ ) {
		if ( (st = mcp2221_wr_reg( dev, sla, pwreg + f, pwm )) ) {
			dev->errfn(dev->errfp, "set_led: writing pwm (led %d) failed\n", f);
			return st;
		}
		if ( (st = mcp2221_wr_reg( dev, sla, irreg + f, iref )) ) {
			dev->errfn(dev->errfp, "set_led: writing pwm (led %d) failed\n", f);
			return st;
		}
	}

	return 0;
}

static int
set_led_ctl(struct mcp2221_dev *dev, uint8_t sla, uint16_t ctl)
{
uint8_t buf[5];
int     i;

	buf[0] = AUTO_INC | 0x02;

	for ( i = 0; i < 16; i++ ) {
		buf[ 1 + (i >> 2) ] &= ~ (3 << (2*(i & 3)));
		if ( ctl & (1<<i) ) {
			buf[ 1 + (i >> 2) ] |= (2 << (2*(i & 3)));
		}
	}

	return mcp2221_start_write( dev, sla, buf, sizeof(buf), 1 );
}

int
main(int argc, char **argv)
{
struct mcp2221_dev *dev = mcp2221_dev_create(1, MICROCHIP_VENDID, MCP2221_DEVID);
uint8_t             buf[60];
int                 got;
uint8_t             sla  = 0x69; /* 0x05, 0x69 */
uint8_t             addr = AUTO_INC | 0x00;
int                 i,j;
int                 rval   = 1;
struct timespec     wai;

uint8_t             slas[2] = {0x05, 0x69};

	if ( ! dev ) {
		return 1;
	}

 mcp2221_start_write( dev, sla, &addr, 1, 0 );
    got = mcp2221_start_read( dev, sla, buf, sizeof(buf), 1 );
	for (i=0; i<got; i++) {
		printf("r[%2i]: 0x%02x\n", i, buf[i]);
	}

	for ( j = 0; j < sizeof(slas)/sizeof(slas[0]); j++ ) {
		set_led_ctl( dev, slas[j], 0x0000 );
		set_led( dev, slas[j], -1, 0x40, 0x60 );
	}

	for ( j = 0; j < sizeof(slas)/sizeof(slas[0]); j++ ) {
		mcp2221_start_write( dev, slas[j], &addr, 1, 0 );
		got = mcp2221_start_read( dev, slas[j], buf, sizeof(buf), 1 );
		for (i=0; i<got; i++) {
			printf("r[%2i]: 0x%02x\n", i, buf[i]);
		}

		for ( i = 0; i < 16; i++ ) {
			set_led_ctl( dev, slas[j], (1<<i) );
			wai.tv_sec  = 0;
			wai.tv_nsec = 500000000;
			nanosleep( &wai, 0 );
		}
		set_led_ctl( dev, slas[j], 0x0000 );
	}

	rval = 0;
bail:
	mcp2221_dev_destroy( dev );
	return rval;
}
