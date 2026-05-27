#include <iostream>
#include <stdlib.h>
#include <math.h>

#include "fei4.hh"

using namespace std;
using namespace fei4;

int main(int argc,char **argv) {
  unsigned int bits[21] = { 0x00000000, 0x00000000, 0x00000000,
                            0x00000000, 0x00000000, 0x00000000,
                            0x00000000, 0x00000000, 0x00000000,
                            0x00000000, 0x00000000, 0x00000000,
                            0x00000000, 0x00000000, 0x00000000,
                            0x00000000, 0x00000000, 0x00000000,
                            0x00000000, 0x00000000, 0x00000000 };
  unsigned int counters[16];

  if ( argc < 5 ) {
    cerr << "Usage: " << argv[0] << " <addr> <chan> <icol> <irow>" << endl;
    exit(1);
  }
  int ichan = atoi(argv[2]);
  int icol = atoi(argv[3]);
  int irow = atoi(argv[4]);
  Fei4Interface *fei4 = new Fei4Interface(argv[1]);
  fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
  fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa070000);   // conf mode
  fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
  fei4->WriteBuffer();
//
//  It is necessary to start the chip off in a well defined state so
//  that the global registers match the model in local memory
//
  fei4->Configure(ichan);
  fei4->WriteBuffer();
//
//  Set default operating parameters in global registers
//

  int vthrc = 0;
  int vthrf = 128;
  int fast = 1;

  fei4->ClearBuffer();
  fei4->WriteGlobalRegister(ichan,"CMDcnt12",0x1004);
  fei4->WriteGlobalRegister(ichan,"M13",0);
  fei4->WriteGlobalRegister(ichan,"HD1",0);
  fei4->WriteGlobalRegister(ichan,"HD0",0);
  fei4->WriteGlobalRegister(ichan,"Trig_Lat",0xb3);
  fei4->WriteGlobalRegister(ichan,"PlsrIDACRamp",180);
  fei4->WriteGlobalRegister(ichan,"PlsrDACbias",96);
  fei4->WriteGlobalRegister(ichan,"GADCCompBias",237);
  fei4->WriteGlobalRegister(ichan,"Trig_Count",15);
  fei4->WriteGlobalRegister(ichan,"DHS",0);
  fei4->WriteGlobalRegister(ichan,"PlsrDelay",30);
  fei4->WriteGlobalRegister(ichan,"TDACVbp",255);
  fei4->WriteGlobalRegister(ichan,"Vthin_Coarse",vthrc);
  fei4->WriteGlobalRegister(ichan,"Vthin_Fine",vthrf);
  fei4->WriteModifiedRegisters(ichan);
  fei4->WriteBuffer();

  if ( fast ) {
    fei4->WriteGlobalRegister(ichan,"320",1);
    fei4->WriteGlobalRegister(ichan,"160",0);
    fei4->WriteGlobalRegister(ichan,"c02",0);
    fei4->WriteGlobalRegister(ichan,"c01",0);
    fei4->WriteGlobalRegister(ichan,"c00",1);
    fei4->WriteGlobalRegister(ichan,"c12",0);
    fei4->WriteGlobalRegister(ichan,"c11",0);
    fei4->WriteGlobalRegister(ichan,"c10",0);
    fei4->WriteGlobalRegister(ichan,"80M",0);
    fei4->WriteGlobalRegister(ichan,"40M",0);
    fei4->WriteGlobalRegister(ichan,"LV0",1);
  }

  fei4->WriteModifiedRegisters(ichan);
  fei4->WriteBuffer();

  fei4->ClearBuffer();
  if ( fast ) {
    fei4->Buffer()->Write(0xc8000000,0x30008006);   // enable 320 Mbps
  }
  else {
    fei4->Buffer()->Write(0xc8000000,0x30000006);   // disable 320 Mbps
  }
  fei4->Buffer()->Write(0xc8000014,0x40000000);   // reset hot pixel counters
  fei4->Buffer()->Write(0xc8000014,0x00000000);
  fei4->WriteBuffer();

  int ic = icol-1;
  int ir = irow-1;

  for ( int k=0; k<20; k++ ) {
    int tdac = k;

    cout << "Conf mode..." << endl;
    fei4->ClearBuffer();
    fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa070000);   // conf mode
    fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
    fei4->WriteBuffer();
//
//  Clear all pixel latches by first clearing the shift register and
//  then loading all bits of the pixel latches
//
    fei4->ClearBuffer();
    fei4->ClearPixelSR(ichan,COLPR_ALL);
    fei4->LoadPixelLatches(ichan,COLPR_ALL,0x1fff);
    fei4->WriteBuffer();
//
//  Set the bit corresponding to row 1 column 1 and write to the pixel
//  shift register
// 
    int idc = ic/2;
    fei4->ClearBuffer();
    fei4::ClearFrontEndBits(bits);
    fei4::SetFrontEndBit((icol-1)%2,irow-1,bits);
    fei4->WritePixelSR(ichan,COLPR_DC|idc,bits);
    int revbits = 0;
    for ( int ib=0; ib<5; ib++ ) {
      if ( (tdac&(1<<(4-ib))) ) {
        revbits |= (2<<ib);
      }
    }
    fei4->LoadPixelLatches(ichan,COLPR_DC|idc,0x00c1|revbits);
    fei4->ClearPixelSR(ichan,COLPR_DC|idc);

    int jdc;
    if ( ic == 0 ) {
      jdc = 0;
    }
    else if ( ic < 77 ) {
      jdc = (ic+1)/2;
    }
    else {
      jdc = 39;
    }
    cout << "ic = " << ic << ", jdc = " << jdc << ", ir = " << ir << endl;
    fei4->WriteModifiedRegisters(ichan);
    fei4->WriteGlobalRegister(ichan,"Colpr_Addr",jdc);
    fei4->WriteModifiedRegisters(ichan);
    fei4->WriteBuffer();
    cout << "  TDAC = " << tdac << endl;
    int vstep = 1;
    int vmin = 0;
    int allone = 0;
    int allzero = 0;
    int done = 0;
    int vdac = 2000;
    int dv = 4;
    int ipt = 0;

    fei4->ClearBuffer();
    fei4->WriteGlobalRegister(ichan,"PlsrDAC",vdac);
    fei4->WriteModifiedRegisters(ichan);
    fei4->WriteBuffer();
    int j = 0;
    fei4->ClearBuffer();
    fei4->SetMatchPattern(ichan,j+1,ic,ir,-1,-1);
    fei4->ClearMatchCounters(ichan);
    fei4->WriteBuffer();

//
//  Pulse sets the chips in run mode, does the pulses, then puts them back
//  into configuration mode.
//
    for ( int ipulse=0; ipulse<16; ipulse++ ) {
      fei4->Pulse(ichan,0x66,8);
    }

    fei4->ReadMatchCounters(ichan,counters);
    double eff = (double)(counters[j+1]&0xffff)/counters[0];
    if ( eff < 0.99 ) allone = 0;
    if ( eff > 0.01 ) allzero = 0;
    double eeff = sqrt(eff*(1-eff)/counters[0]);
    if ( eeff < 0.01 ) eeff = 0.01;
    cout << "vdac = " << vdac << ", Eff= " << eff << " +- " << eeff << endl;
  }
}
