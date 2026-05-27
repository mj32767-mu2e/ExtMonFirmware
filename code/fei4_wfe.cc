#include <iostream>
#include <stdlib.h>
#include <assert.h>
#include <math.h>

#include "TROOT.h"
#include "TFile.h"
#include "TH1.h"
#include "TH2.h"
#include "TMath.h"
#include "TGraphErrors.h"
#include "TF1.h"

#include "fei4.hh"

using namespace std;
using namespace fei4;

int main(int argc,char **argv) {
  unsigned int bits[21];
  unsigned int counters[16];
  if ( argc < 7 ) {
    cerr << "Usage: " << argv[0] << " <addr> <chan> <c> <r> <tdac> <q>" << endl;
    exit(1);
  }

  int chan = atoi(argv[2]);
  Fei4Interface *fei4 = new Fei4Interface(argv[1]);
  fei4->LogBuffer(0);
  int ic = atoi(argv[3]);
  int ir = atoi(argv[4]);
  int tdac = atoi(argv[5]);
  int vdac = atoi(argv[6]);

  int vthrc = 8;
  int vthrf = 32;
  int clk320mhz = 1;

  fei4->ClearBuffer();
  fei4->WriteGlobalRegister(chan,"CMDcnt12",0x1004);
  fei4->WriteGlobalRegister(chan,"M13",0);
  fei4->WriteGlobalRegister(chan,"HD1",0);
  fei4->WriteGlobalRegister(chan,"HD0",0);
  fei4->WriteGlobalRegister(chan,"Trig_Lat",0xb3);
  fei4->WriteGlobalRegister(chan,"PlsrIDACRamp",180);
  fei4->WriteGlobalRegister(chan,"Trig_Count",4);
  fei4->WriteGlobalRegister(chan,"DHS",0);
  fei4->WriteGlobalRegister(chan,"PlsrDelay",30);
  fei4->WriteGlobalRegister(chan,"TDACVbp",255);
  fei4->WriteGlobalRegister(chan,"Vthin_Coarse",vthrc);
  fei4->WriteGlobalRegister(chan,"Vthin_Fine",vthrf);
  if ( clk320mhz ) {
    fei4->WriteGlobalRegister(chan,"320",1);
    fei4->WriteGlobalRegister(chan,"160",0);
    fei4->WriteGlobalRegister(chan,"c02",0);
    fei4->WriteGlobalRegister(chan,"c01",0);
    fei4->WriteGlobalRegister(chan,"c00",1);
    fei4->WriteGlobalRegister(chan,"c12",0);
    fei4->WriteGlobalRegister(chan,"c11",0);
    fei4->WriteGlobalRegister(chan,"c10",0);
    fei4->WriteGlobalRegister(chan,"80M",0);
    fei4->WriteGlobalRegister(chan,"40M",0);
    fei4->WriteGlobalRegister(chan,"LV0",1);
  }
  fei4->WriteModifiedRegisters(chan);
  fei4->WriteBuffer();

  fei4->ClearBuffer();
  if ( clk320mhz ) {
    fei4->Buffer()->Write(0xc8000000,0x10008000);
  }
  else {
    fei4->Buffer()->Write(0xc8000000,0x10000000);
  }
  fei4->WriteBuffer();

  int idc = ic/2;
  fei4::ClearFrontEndBits(bits);
  fei4::SetFrontEndBit(ic,ir,bits);

  cout << "Matching col " << ic << " row " << ir << endl;;

  fei4->ClearBuffer();
  fei4->ClearPixelSR(chan,COLPR_ALL);
  fei4->LoadPixelLatches(chan,COLPR_ALL,0x1fff);
  fei4->WriteBuffer();

  fei4->ClearBuffer();
  fei4->WritePixelSR(chan,COLPR_DC|idc,bits);
  int revbits = 0;
  for ( int ib=0; ib<5; ib++ ) {
    if ( (tdac&(1<<(4-ib))) ) {
      revbits |= (2<<ib);
    }
  }
  fei4->LoadPixelLatches(chan,COLPR_DC|idc,0x00c1|revbits);
  fei4->ClearPixelSR(chan,COLPR_DC|idc);
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
  fei4->WriteModifiedRegisters(chan);
  fei4->WriteGlobalRegister(chan,"Colpr_Addr",jdc);
  fei4->WriteModifiedRegisters(chan);
  fei4->WriteBuffer();

  cout << "  TDAC = " << tdac << endl;

  fei4->ClearBuffer();
  fei4->SetMatchPattern(chan,1,ic,ir,-1,-1);
  fei4->WriteBuffer();

  cout << "  row " << ir << " col " << ic << "..." << endl;

  fei4->ClearBuffer();
  fei4->WriteGlobalRegister(chan,"PlsrDAC",vdac);
  fei4->WriteModifiedRegisters(chan);
  fei4->ClearMatchCounters(chan);
  fei4->WriteBuffer();

//  fei4->Pulse(chan,0x66,4);

//  fei4->ReadMatchCounters(chan,counters);
//  cout << "  Matched " << (counters[1]&0xffff) << " / 100" << endl;
//  if ( counters[0] == 0 ) {
//    cout << "Error - no triggers detected." << endl;
//    exit(1);
//  }
//  double eff = (double)(counters[1]&0xffff)/100.0;
//  cout << "   vdac = " << vdac << ", eff = " << eff << endl;
}
