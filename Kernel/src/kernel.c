#include "mb_interface.h"
// #include "xil_printf.h"
#include <stdarg.h>

#define UART_SR (*(volatile unsigned char *)(0x80000008))
#define UART_RX (*(volatile unsigned char *)(0x80000000))
#define UART_TX (*(volatile unsigned char *)(0x80000004))

#define XIN_ISR (*(volatile unsigned int *)0x80000030)
#define XIN_IPR (*(volatile unsigned int *)0x80000034)
#define XIN_IER (*(volatile unsigned int *)0x80000038)
#define XIN_IAR (*(volatile unsigned int *)0x8000003C)

#define INTC_INT_MASK 0x00010000
#define INTC_FIT1_MASK 0x00000080
#define INTC_UART_RX_MASK 0x00000004
#define INTC_UART_TX_MASK 0x00000002

#define UART_BUFFER_SIZE 128

#define IOBUS_CLOCK_TIME             (*(volatile unsigned int *)(0xc0000020))

#define IOBUS_GBE_CSR                (*(volatile unsigned int *)(0xc1000000))
#define IOBUS_GBE_UDP_SR             (*(volatile unsigned int *)(0xc1000060))

struct s_udpbuffer {
  unsigned char buf[0x7f0];
  unsigned int saddr;
  unsigned int daddr;
  unsigned short dport;
  unsigned short sport;
  unsigned int length;
};

#define IOBUS_GBE_UDP_BUFFER         ((volatile unsigned int *)(0xc1008000))

#define IOBUS_GBE_UDP_SADDR          (*(volatile unsigned int *)(0xc10087f0))
#define IOBUS_GBE_UDP_DADDR          (*(volatile unsigned int *)(0xc10087f4))
#define IOBUS_GBE_UDP_PORTS          (*(volatile unsigned int *)(0xc10087f8))
#define IOBUS_GBE_UDP_LENGTH         (*(volatile unsigned int *)(0xc10087fc))

#define IOBUS_GBE_TXUDP_DADDR        (*(volatile unsigned int *)(0xc1000064))
#define IOBUS_GBE_TXUDP_PORTS        (*(volatile unsigned int *)(0xc1000068))
#define IOBUS_GBE_TXUDP_CSR          (*(volatile unsigned int *)(0xc1007c00))
#define IOBUS_GBE_TXUDP_BUFFER       ((volatile unsigned int *)(0xc100c000))

#define ETHIO_NOP 0
#define ETHIO_WRITE 1
#define ETHIO_SET 2
#define ETHIO_RECV 3
#define ETHIO_READ 4
#define ETHIO_RESET 5
#define ETHIO_DEFAULT 6
#define ETHIO_WAITCLR 7
#define ETHIO_WAITSET 8

char _uart_txbuf[UART_BUFFER_SIZE];
volatile int _uart_txbuf_i = 0;
volatile int _uart_txbuf_j = 0;
char _uart_rxbuf[UART_BUFFER_SIZE];
volatile int _uart_rxbuf_i = 0;
volatile int _uart_rxbuf_j = 0;
int _interrupt;

void handler(void) __attribute__ ((interrupt_handler));

const char *cint[4] = { "    EXT", "    FIT", "UART Tx", "UART Rx" };
unsigned int nint[4] = { 0, 0, 0, 0 };
unsigned int tboot = 0;   // boot time
static int ier = 0;

char __getch() {
  while ( ! (UART_SR&0x01) );
  return(UART_RX);
}

void __putch(char c) {
  while ( (UART_SR&0x08) );
  UART_TX = c;
}

void __puts(const char *p) {
  while ( (*p) != '\0' ) __putch(*p++);
}

void _putch(char c) {
  int i = _uart_txbuf_i;
  _uart_txbuf[i] = c;
  i = (i+1)%UART_BUFFER_SIZE;
  while ( i == _uart_txbuf_j );
  _uart_txbuf_i = i;

  XIN_IER = 0;
  ier |= INTC_UART_TX_MASK;
  XIN_IER = ier;
}

void _puts(const char *c) {
  while ( *c != '\0' ) {
    _putch(*c++);
  }
}

char _getch() {
  char c;
  int j;

  j = _uart_rxbuf_j;
  while ( _uart_rxbuf_i == j );
  c = _uart_rxbuf[j];
  j = (j+1)%UART_BUFFER_SIZE;
  _uart_rxbuf_j = j;
  return c;
}

char *_gets(char *buf,int n) {
  char *p = buf;
  char c;
  int i, m = n;

  *p = '\0';
  if ( m == 0 ) return buf;
  do {
    c = _getch();
    if ( c == 0x15 ) {
      for ( i=m; i<n; i++ ) _putch('\b');
      for ( i=m; i<n; i++ ) _putch(' ');
      for ( i=m; i<n; i++ ) _putch('\b');
      m = n;
      p = buf;
    }
    else if ( c == 0x08 ) {
      if ( m != n ) {
        _putch('\b');
        _putch(' ');
        _putch('\b');
        m++;
        p--;
      }
    }
    else if ( m > 1 ) {
      _putch(c);
      *p++ = c;
      *p = '\0';
      m--;
    }
  }
  while ( c != '\n' && c != '\r' && c != 0x03 );
  return buf;
}

void _print_hex_short(unsigned int w) {
  unsigned char i, n;
  for ( i=0; i<4; i++ ) {
    n = (w>>12)&0x0f;
    if ( n < 10 ) {
      _putch(n+'0');
    }
    else {
      _putch(n-10+'a');
    }
    w <<= 4;
  }
}

void _print_hex_long(unsigned int w) {
  unsigned char i, n;
  for ( i=0; i<8; i++ ) {
    n = (w>>28)&0x0f;
    if ( n < 10 ) {
      _putch(n+'0');
    }
    else {
      _putch(n-10+'a');
    }
    w <<= 4;
  }
}

void _print_int(unsigned int i) {
  int a, c = 1000000000;
  do {
    a = i/c;
    if ( a == 0 ) c /= 10;
  }
  while ( c != 0 && a == 0 );
  if ( c == 0 ) {
    _putch('0');
  }
  else {
    do {
      _putch(a+'0');
      i -= a*c;
      c /= 10;
      if ( c > 0 ) a = i/c;
    }
    while ( c > 0 );
  }
}

void _print_hex_byte(unsigned char w) {
  int i;
  char c;
  for ( i=0; i<2; i++ ) {
    c = (w>>((1-i)*4))&0x0f;
    if ( c < 10 ) {
      c += '0';
    }
    else {
      c += 'a' - 10;
    }
    _putch(c);
  }
}

int _isspace(char c) {
  return c == ' ' || c == '\f' || c == '\n' ||
         c == '\r' || c == '\t' || c == '\v';
}

int _isprint(char c) {
  return c > 0x1f && c < 0x7f;
}

char *_token(char *line) {
  static char *p;
  char *q;

  if ( line != NULL ) p = line;
  while ( *p != '\0' && _isspace(*p) ) p++;
  q = p;
  while ( *p != '\0' && ! _isspace(*p) ) p++;
  if ( *p != '\0' ) {
    *p++ = '\0';
  }
  return *q!='\0'?q:NULL;
}

int _strcmp(const char *a,const char *b) {
  const char *pa = a, *pb = b;
  while ( *pa != '\0' && *pb != '\0' && *pa == *pb ) {
    pa++;
    pb++;
  }
  if ( *pa == *pb ) return 0;
  if ( *pa == '\0' ) return -1;
  if ( *pb == '\0' ) return 1;
  return (*pa<*pb)?-1:1;
}

int _strlen(const char *a) {
  int n = 0;
  while ( *a++ != '\0' ) n++;
  return n;
}

int _isdigit(char c) {
  return c >= '0' && c <= '9';
}

char _tolower(char c) {
  return c>='A'&&c<='Z'?c-'A'+'a':c;
}

int _ishexdigit(char c) {
  char d = _tolower(c);
  return ( d >= '0' && d <= '9' ) || ( d >= 'a' && d <= 'f' );
}

int _atoi(const char *p) {
  int i = 0, s = 1;
  if ( *p == '-' ) {
    s = -1;
    p++;
  }
  while ( _isdigit(*p) && *p != '\0' ) {
    i *= 10;
    i += *p++ - '0';
  }
  return s*i;
}

unsigned int _atoh(const char *p) {
  int i = 0;
  while ( _ishexdigit(*p) && *p != '\0' ) {
    i <<= 4;
    if ( *p >= '0' && *p <= '9' ) {
      i |= *p-'0';
    }
    else {
      i |= _tolower(*p) - 'a' + 10;
    }
    p++;
  }
  return i;
}

void _print_mac_addr(unsigned int high,unsigned int low) {
  _print_hex_byte((high>>8)&0xff);
  _putch(':');
  _print_hex_byte(high&0xff);
  _putch(':');
  _print_hex_byte((low>>24)&0xff);
  _putch(':');
  _print_hex_byte((low>>16)&0xff);
  _putch(':');
  _print_hex_byte((low>>8)&0xff);
  _putch(':');
  _print_hex_byte(low&0xff);
}

void _print_ip_addr(unsigned int ip) {
  _print_int((ip>>24)&0xff);
  _putch('.');
  _print_int((ip>>16)&0xff);
  _putch('.');
  _print_int((ip>>8)&0xff);
  _putch('.');
  _print_int(ip&0xff);
}

unsigned int _parse_ip(const char *p) {
  unsigned int ip = 0;
  int i;
  for ( i=0; i<4; i++ ) {
    ip |= _atoi(p)<<(8*(3-i));
    if ( i < 3 ) {
      while ( _isdigit(*p) ) p++;
      if ( *p++ != '.' ) {
        return 0;
      }
    }
  }
  return ip;
}

unsigned short _nextport() {
  static unsigned short next = 0;
  if ( next == 0 ) next = 49152;
  return next++;
}

int _printf(const char *fmt,...) {
  va_list ap;
  int i, d, w, z, l;
  unsigned int u;
  unsigned long long v;
  const char *p, *s;
  char *q, buf[24];
  va_start(ap,fmt);
  p = fmt;

  while ( *p != '\0' ) {
    z = 0;
    w = 0;
    if ( *p != '%' ) {
      _putch(*p++);
      continue;
    }
here:
    if ( *(p+1) != '\0' ) {
      p++;
      if ( *p == '%' ) {
        _putch(*p++);
        continue;
      }
      if ( *p == '0' ) {
        z = 1;
        goto here;
      }
    else if ( *p > '0' && *p <= '9' ) {
        w = _atoi(p);
        goto here;
      }
      if ( *p == 's' || *p == 'd' || *p == 'x' || *p == 'u' || *p == 'l' ) {
        if ( *p == 's' ) {
          s = va_arg(ap,const char *);
          z = 0;
        }
        else {
          if ( *p == 'd' || *p == 'u' ) {
            d = va_arg(ap,int);
            q = buf;
            if ( d < 0 && *p == 'd' ) {
              d = -d;
              _putch('-');
            }
            q = buf+sizeof(buf)-1;
            *q-- = '\0';
            do {
              *q-- = '0' + d%10;
              d /= 10;
            }
            while ( d > 0 );
            s = ++q;
          }
          else if ( *p == 'l' ) {
            v = va_arg(ap,unsigned long long);
            q = buf+sizeof(buf)-1;
            *q-- = '\0';
            do {
              *q-- = '0' + (v%10L);
              v /= 10L;
            }
            while ( v > 0 );
            s = ++q;
          }
          else {
            u = va_arg(ap,unsigned int);
            q = buf+11;
            *q = '\0';
            while ( u != 0 ) {
              q -= 1;
              if ( (u&0x0f) < 10 ) {
                *q = (u&0x0f) + '0';
              }
              else {
                *q = (u&0x0f) - 10 + 'a';
              }
              u >>= 4;
            }
            s = q;
          }
        }
        l = _strlen(s);
        if ( w > l ) {
          for ( i=0; i<w-l; i++ ) _putch(z?'0':' ');
        }
        _puts(s);
      }
    }
    p++;
  }

  va_end(ap);
  return 0;
}

void exception(void) {
  __asm__("nop");
}

void handler(void) {
  unsigned int ack = 0;
  unsigned short sport;
  unsigned short dport;
  unsigned char tag, cmd;
  unsigned char *b, *p;
  unsigned int ibuf, t, len, addr, data, saddr, count;
  struct s_udpbuffer *udp;
  int i, j;
  char c;

  if ( (XIN_IPR&INTC_INT_MASK) ) {
    IOBUS_GBE_CSR |= INTC_INT_MASK;
    while ( (IOBUS_GBE_UDP_SR&0x03) ) {  // Currently only two UDP buffers.
      ibuf = 0;
      udp = (struct s_udpbuffer *)IOBUS_GBE_UDP_BUFFER;
      while ( (IOBUS_GBE_UDP_SR&(1<<ibuf)) == 0 ) {
        ibuf += 1;
        udp += 1;
      }
      sport = udp->sport;
      dport = udp->dport;
      saddr = udp->saddr;
      if ( sport == 123 ) {
        b = udp->buf+32;
        for ( i=0; i<4; i++ ) {
          t = (t<<8)|(*b++);
        }
        t -= 2208988800U;
        tboot = t - ( IOBUS_CLOCK_TIME - tboot );
        IOBUS_CLOCK_TIME = t;
      }
      else if ( dport == 47000 ) {
        for ( i=0; i<256; i++ ) IOBUS_GBE_TXUDP_BUFFER[i] = 0;
        IOBUS_GBE_TXUDP_CSR = 0x80000000;    //  Clear checksum
        b = udp->buf;
        p = (unsigned char *)IOBUS_GBE_TXUDP_BUFFER;

        while ( *b != 0x00 ) {
          tag = b[0];
          cmd = b[1];
          len = (b[2]<<8)+b[3];
          b += 4;
          if ( cmd == ETHIO_NOP ) {
            *p++ = tag;
            *p++ = cmd | 0x80;
            *p++ = 0;
            *p++ = 0;
          }
          else if ( cmd == ETHIO_READ ) {
            addr = (b[0]<<24) | (b[1]<<16) | (b[2]<<8) | b[3];
            b += 4;
            data = *((volatile unsigned long *)addr);
            *p++ = tag;
            *p++ = cmd | 0x80;
            *p++ = 0;
            *p++ = 8;
            *p++ = (addr>>24)&0xff;
            *p++ = (addr>>16)&0xff;
            *p++ = (addr>>8)&0xff;
            *p++ = addr&0xff;
            *p++ = (data>>24)&0xff;
            *p++ = (data>>16)&0xff;
            *p++ = (data>>8)&0xff;
            *p++ = data&0xff;
          }
          else if ( cmd == ETHIO_WRITE ||
                    cmd == ETHIO_WAITCLR ||
                    cmd == ETHIO_WAITSET ) {
            addr = (b[0]<<24) | (b[1]<<16) | (b[2]<<8) | b[3];
            b += 4;
            data = (b[0]<<24) | (b[1]<<16) | (b[2]<<8) | b[3];
            b += 4;
            if ( cmd == ETHIO_WAITCLR || cmd == ETHIO_WAITSET ) {
              count = 0;
              count = (b[0]<<24) | (b[1]<<16) | (b[2]<<8) | b[3];
              b += 4;
            }
            if ( cmd == ETHIO_WRITE ) {
              *((volatile unsigned int *)addr) = data;
              *p++ = tag;
              *p++ = cmd | 0x80;
              *p++ = 0;
              *p++ = 0;
            }
            else if ( cmd == ETHIO_WAITCLR || cmd == ETHIO_WAITSET ) {
              i = 0;
              do {
                i += 1;
                if ( cmd == ETHIO_WAITCLR && (*((volatile unsigned int *)addr)&data) == 0 ) break;
                if ( cmd == ETHIO_WAITSET && (*((volatile unsigned int *)addr)&data) != 0 ) break;
              }
              while ( i < count );
              *p++ = tag;
              *p++ = cmd | 0x80;
              *p++ = 0;
              *p++ = 4;
              *p++ = (i>>24)&0xff;
              *p++ = (i>>16)&0xff;
              *p++ = (i>>8)&0xff;
              *p++ = i&0xff;
            }
          }
        }
        len = p - (unsigned char *)IOBUS_GBE_TXUDP_BUFFER;
        IOBUS_GBE_TXUDP_DADDR = saddr;
        IOBUS_GBE_TXUDP_PORTS = (dport<<16) | sport;
        IOBUS_GBE_TXUDP_CSR = (len<<16);
        IOBUS_GBE_TXUDP_CSR |= 0x40000000;
      }
      IOBUS_GBE_UDP_SR = (1<<ibuf);   // Free UDP buffer
    }
    nint[0] += 1;
    ack |= INTC_INT_MASK;
  }

  if ( (XIN_IPR&INTC_UART_TX_MASK) ) {
    nint[2] += 1;
    j = _uart_txbuf_j;
    UART_TX = _uart_txbuf[j];
    j = (j+1)%UART_BUFFER_SIZE;
    _uart_txbuf_j = j;
    if ( _uart_txbuf_j == _uart_txbuf_i ) {
      ier &= ~INTC_UART_TX_MASK;
      XIN_IER = ier;
    }
    ack |= INTC_UART_TX_MASK;
  }

  if ( (XIN_IPR&INTC_UART_RX_MASK) ) {
    nint[3] += 1;
    i = _uart_rxbuf_i;
    c = UART_RX;
    if ( c == 0x03 ) {
      _puts("Interrupt\n\r" );
      _interrupt = 1;
    }
    else {
      _uart_rxbuf[i] = c;
      i = (i+1)%UART_BUFFER_SIZE;
      if ( i != _uart_rxbuf_j ) {
        _uart_rxbuf_i = i;
      }
    }
    ack |= INTC_UART_RX_MASK;
  }

  if ( (XIN_IPR&INTC_FIT1_MASK) ) {
    nint[1] += 1;
    ack |= INTC_FIT1_MASK;
  }

  XIN_IAR = ack;
}

void _init_kernel() {
  ier = INTC_INT_MASK|INTC_FIT1_MASK|INTC_UART_RX_MASK;
  XIN_IER = ier;
}
