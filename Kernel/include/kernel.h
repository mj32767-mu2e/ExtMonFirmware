#ifndef __KERNEL__
#define __KERNEL__

void _putch(char);
void _puts(const char *);
char _getch();
char *_gets(char *,int);
char __getch();
void __putch(char);
void __puts(const char *);
void _print_hex_byte(unsigned int);
void _print_hex_short(unsigned int);
void _print_hex_long(unsigned int);
void _print_int(unsigned int);
int _isprint(char);
int _isspace(char);
int _isdigit(char);
int _ishexdigit(char);
// char _tolower(char);
int _atoi(const char *);
unsigned int _atoh(const char *);
char *_token(char *);
int _strcmp(const char *,const char *);
int _strlen(const char *);
void _print_ip_addr(unsigned int);
void _print_mac_addr(unsigned int,unsigned int);
unsigned int _parse_ip(const char *);
int _printf(const char *,...);
unsigned short _nextport();
void _init_kernel();

extern int _interrupt;

#endif
