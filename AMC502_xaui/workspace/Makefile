OPTS=-I../../Kernel/include -I./include -L./lib
SRCS=../../Kernel/src/kernel.c
LIBS=-lgcc -lc -lm -lxil

monitor_amc502_xaui.elf : monitor_amc502_xaui.c platform.c lscript.ld
	mb-gcc -Wl,-T -Wl,./lscript.ld $(OPTS) -mlittle-endian -mcpu=v11.0 -mxl-soft-mul -Wl,--no-relax -Wl,--gc-sections -o "monitor_amc502_xaui.elf" monitor_amc502_xaui.c $(SRCS) platform.c $(LIBS)

