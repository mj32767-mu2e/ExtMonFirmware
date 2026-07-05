#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <string>

#include "amc502.hh"

#undef COMP2

using namespace std;
using namespace amc502;

const char *csr_fields[] = { "master PLL locked",
                             "slave PLL locked",
                             "mmcm locked",
                             "no clock input",
                             "no feedback input" };
const char *freq_name[] = { "generated bcoclk",
                            "generated sysclk",
                            "recovered bcoclk",
                            "recovered sysclk",
                            "fpclkb",
                            "tdaq",
                            "clk100mhz",
                            "gmiiclk",
                            "156.25mhz",
                            "fpclke",
                            "fpclkg"
                           };
struct s_zl30162_reg {
  unsigned int addr;
  const char *name;
} zl30162_regs[] = { { 0x022, "dpll_isr_status" },
                     { 0x080, "ref0_base_freq hi" },
                     { 0x081, "ref0_base_freq lo" },
                     { 0x180, "dpll_hold_lock_status" },
                     { 0x181, "ext_fb_ctrl" },
                     { 0x182, "dpll_config" },
                     { 0x183, "dpll_lock_selection" },
                     { 0x1b0, "synth_drive_pll" },
                     { 0x1b1, "synth_enable" },
                     { 0x1b6, "sync_fail_flag_status" }
                   };

int main(int argc,char **argv) {
  int n, lv = 0;
  int icol = 0;
  int ierr;
  if ( argc < 2 ) {
    cerr << "Usage: " << argv[0] << " <addr> [-i] [-r <addr>] [-w <addr> <val>]" << endl;
    exit(1);
  }
  Amc502Interface *amc502 = new Amc502Interface(argv[1],47000);
  if ( argc > 2 && strcmp(argv[2],"-i") == 0 ) {
    amc502->ClearBuffer();
    int index = amc502->Buffer()->Read(0xc0000000);
    amc502->Buffer()->Send();
    if ( ( ierr = amc502->Buffer()->Receive() ) < 0 ) {
      cout << "Receive error..." << endl;
      exit(1);
    }
    int amc502_csr = amc502->Buffer()->RxData(index,1);
    cout << "AMC502 csr = 0x" << hex << setw(8) << setfill('0') << amc502_csr << endl;
    amc502_csr >>= 22;
    for ( int i=0; i<5; i++ ) {
      cout << "  " << csr_fields[i] << " = " << (amc502_csr&1) << endl;
      amc502_csr >>= 1;
    }
    for ( int i=0; i<11; i++ ) {
      cout << "  " << freq_name[i] << " = " << dec << fixed << setprecision(3) << 1e-6*amc502->ReadFrequency(i) << endl;
    }

    int chip_rev = amc502->I2cReadByte(ZL30162,1);
    int hw_rev = amc502->I2cReadByte(ZL30162,2);
    cout << "ZL30162 chip rev. " << chip_rev << " HW rev. " << hw_rev << endl;

    cout << "Clearing sync_fail_flag bits..." << endl;
    amc502->I2cWriteByte(ZL30162,0x1b7,0x0f);
    amc502->I2cWriteByte(ZL30162,0x1b7,0x00);

    for ( int i=0; i<10; i++ ) {
      cout << "  0x" << hex << setw(3) << zl30162_regs[i].addr
           << "  " << zl30162_regs[i].name
           << " = 0x" << hex << setw(2) << setfill('0') << amc502->I2cReadByte(ZL30162,zl30162_regs[i].addr) << endl;
    }

    unsigned short synth0_base_freq =
      (amc502->I2cReadByte(ZL30162,0x1b8)<<8) |
      amc502->I2cReadByte(ZL30162,0x1b9);
    unsigned short synth0_base_freq_mult =
      (amc502->I2cReadByte(ZL30162,0x1ba)<<8) |
      amc502->I2cReadByte(ZL30162,0x1bb);
    unsigned short synth0_base_freq_den =
      (amc502->I2cReadByte(ZL30162,0x1bc)<<8) |
      amc502->I2cReadByte(ZL30162,0x1bd);
    unsigned short synth0_base_freq_num =
      (amc502->I2cReadByte(ZL30162,0x1be)<<8) |
      amc502->I2cReadByte(ZL30162,0x1bf);
    double synth0_freq = 1e-6*synth0_base_freq*synth0_base_freq_mult*
                         synth0_base_freq_num/synth0_base_freq_den;
    cout << "Synth0 base frequency = " << hex << setfill('0') << setw(4) << synth0_base_freq << " * "
                                       << hex << setfill('0') << setw(4) << synth0_base_freq_mult << " * "
                                       << hex << setfill('0') << setw(4) << synth0_base_freq_num << " / "
                                       << hex << setfill('0') << setw(4) << synth0_base_freq_den << " = "
                                       << synth0_freq << " MHz" << endl;

    int synth1_base_freq =
      (amc502->I2cReadByte(ZL30162,0x1c0)<<8) |
      amc502->I2cReadByte(ZL30162,0x1c1);
    int synth1_base_freq_mult =
      (amc502->I2cReadByte(ZL30162,0x1c2)<<8) |
      amc502->I2cReadByte(ZL30162,0x1c3);
    int synth1_base_freq_den =
      (amc502->I2cReadByte(ZL30162,0x1c4)<<8) |
      amc502->I2cReadByte(ZL30162,0x1c5);
    int synth1_base_freq_num =
      (amc502->I2cReadByte(ZL30162,0x1c6)<<8) |
      amc502->I2cReadByte(ZL30162,0x1c7);
    double synth1_freq = 1e-6*synth1_base_freq*synth1_base_freq_mult*
                         synth1_base_freq_num/synth1_base_freq_den;
    cout << "Synth1 base frequency = " << hex << setfill('0') << setw(4) << synth1_base_freq << " * "
                                       << hex << setfill('0') << setw(4) << synth1_base_freq_mult << " * "
                                       << hex << setfill('0') << setw(4) << synth1_base_freq_num << " / "
                                       << hex << setfill('0') << setw(4) << synth1_base_freq_den << " = "
                                       << synth1_freq << " MHz" << endl;

    exit(0);
  }
  else if ( argc > 3 && strcmp(argv[2],"-r") == 0 ) {
    unsigned int addr = strtol(argv[3],NULL,16);
    int val = amc502->I2cReadByte(ZL30162,addr);
    cout << "Register 0x" << hex << setw(3) << fixed << setfill('0') << addr << " = 0x" << setw(2) << val << endl;
    exit(0);
  }
  else if ( argc > 4 && strcmp(argv[2],"-w") == 0 ) {
    unsigned int addr = strtol(argv[3],NULL,16);
    unsigned int val = strtol(argv[4],NULL,16);
    amc502->I2cWriteByte(ZL30162,addr,val);
    cout << "Register 0x" << hex << setw(3) << fixed << setfill('0') << addr << " <-- 0x" << setw(2) << val << endl;
    exit(0);
  }
  string line;
  do {
    getline(cin,line);
    size_t p = line.find("Register address");

    if ( p != string::npos ) {
      p += 16;
      int reg = strtol(line.substr(p).c_str(),NULL,16);
      p = line.find("=",p);
      p += 2;
      int val = strtol(line.substr(p).c_str(),NULL,16);
      cout << "Register " << hex << reg << " <-- " << val << dec << endl;

#ifdef COMP1
      if ( reg == 0 ) {
        n = 1;
        lv = val;
      }
      if ( val != lv || reg == 0x2ff ) {
        cout << "{" << n << "," << lv << "}," << endl;
        n = 1;
        lv = val;
      }
      else {
        n += 1;
      }
#endif

#ifdef COMP2
      if ( reg == 0 ) {
        cout << "const unsigned short reg_000_0ff[] = {" << endl;
      }
      if ( reg == 0x100 ) {
        cout << " };" << endl;
        cout << "const unsigned short reg_100_1ff[] = {" << endl;
      }
      if ( reg == 0x200 ) {
        cout << " };" << endl;
        cout << "const unsigned short reg_200_2ff[] = {" << endl;
      }
      if ( val != 0 ) {
        icol += 1;
        if ( icol == 8 ) {
          cout << endl;
          icol = 0;
        }
        cout << " 0x" << hex << setw(2) << setfill('0') << (reg&0xff) << setw(2) << setfill('0') << val << dec << ",";
      }
#endif
      amc502->I2cWriteByte(ZL30162,reg,val);
    }
  }
  while ( ! cin.eof() );
  cout << " };" << endl;
}
