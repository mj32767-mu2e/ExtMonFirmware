#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <string>

#include "amc502.hh"

#define COMP2

using namespace std;
using namespace amc502;

int main(int argc,char **argv) {
  int n, lv = 0;
  int icol = 0;
  if ( argc < 2 ) {
    cerr << "Usage: " << argv[0] << " <addr>" << endl;
    exit(1);
  }
  Amc502Interface *amc502 = new Amc502Interface(argv[1],47000);
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
//      cout << "Register " << hex << reg << " <-- " << val << dec << endl;

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
