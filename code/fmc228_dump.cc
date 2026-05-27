
#include <iostream>
#include <iomanip>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <netdb.h>
#include <time.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>

#include "amc502.hh"
#include "fmc228.hh"

using namespace std;
using namespace amc502;
using namespace fmc228;

int main(int argc,char **argv) {
  int ierr, i, s, strip;
  socklen_t namelen;
  int broadcast_enable;
  unsigned short port;
  struct sockaddr_in saddr, daddr;
  struct hostent *hp;
  unsigned int mask[4];

  if ( argc < 2 ) {
    cerr << "Usage: " << argv[0] << " <addr>" << endl;
    exit(1);
  }

  Amc502Interface *amc502 = new Amc502Interface(argv[1],47000);
  Fmc228Interface *fmc228 = new Fmc228Interface(amc502);

  cout << "FMC228 configuration diagnostic tool." << endl;
  cout << "M. Jones - September 7, 2021." << endl << endl;

  cout << "Checking clock routing..." << endl;
  cout << "The FMC228 receives a 10 MHz input clock on FMC_CLK2_BIDIR." << endl;
  cout << "Checking FMC_CLK2_BIDIR drivers on crossbar switch:" << endl;
  const unsigned char *sw = amc502->ReadCrossbarSwitch(1);
  cout << "Port 10 should drive FMC0_CLK2_BIDIR from input 0 (PLLCLKA_out)" << endl;
  cout << "Port 10 = 0x" << hex << setfill('0') << setw(2) << (int)sw[10] << " - ";
  cout << ((sw[10]==0x84)?"Yes":"No.") << endl;
  cout << "Port 14 should drive FMC1_CLK2_BIDIR from input 0 (PLLCLKA_out)" << endl;
  cout << "Port 14 = 0x" << hex << setfill('0') << setw(2) << (int)sw[14] << " - ";
  cout << ((sw[14]==0x84)?"Yes":"No.") << endl;
  cout << "Port 4 should be a terminated input." << endl;
  cout << "Port 4 = 0x" << hex << setfill('0') << setw(2) << (int)sw[4] << " - ";
  cout << ((sw[4]==0x40)?"Yes":"No.") << endl;

  cout << "The 10 MHz clock drives the LMK04828 PLL." << endl;
  cout << "Is the PLL locked to the input clock?" << endl;
  int lck0 = fmc228->SpiRead(LMK04828,0x182);
  int lck1 = fmc228->SpiRead(LMK04828,0x183);
  cout << "RB_PLL1_LD = 0x" << hex << setw(2) << setfill('0') << lck0 << " - ";
  cout << ((lck0&0x02)?"Yes":"No") << endl;
  cout << "RB_PLL2_LD = 0x" << hex << setw(2) << setfill('0') << lck1 << " - ";
  cout << ((lck1&0x02)?"Yes":"No") << endl;

  return 0;
}
