#include <iostream>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <vector>

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
  if ( argc < 3 ) {
    cerr << "Usage: " << argv[0] << " <addr> <dthr> [file]" << endl;
    exit(1);
  }
  int vthrc = atoi(argv[2]);
  TFile *fout = NULL;
  if ( argc > 3 ) {
    fout = new TFile(argv[3],"UPDATE");
  }

  Fei4Interface *fei4 = new Fei4Interface(argv[1]);

  int vthrf = 32;
  int clk320mhz = 1;
  double vtrim = 100.0;
  int full_analysis = 1;

  for ( int ichan=0; ichan<10; ichan++ ) {
    if ( ichan == 4 || ichan == 5 ) continue;
    cout << "Configuring channel " << ichan << endl;
    fei4->ClearBuffer();
    fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa070000);   // conf mode
    fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
    fei4->WriteBuffer();

    fei4->ClearBuffer();
    fei4->WriteGlobalRegister(ichan,"CMDcnt12",0x1004);
    fei4->WriteGlobalRegister(ichan,"M13",0);
    fei4->WriteGlobalRegister(ichan,"HD1",0);
    fei4->WriteGlobalRegister(ichan,"HD0",0);
    fei4->WriteGlobalRegister(ichan,"Trig_Lat",0x60);
    fei4->WriteGlobalRegister(ichan,"PlsrIDACRamp",180);
    fei4->WriteGlobalRegister(ichan,"Trig_Count",1);
    fei4->WriteGlobalRegister(ichan,"DHS",0);
    fei4->WriteGlobalRegister(ichan,"PlsrDelay",30);
    fei4->WriteGlobalRegister(ichan,"TDACVbp",255);
    fei4->WriteGlobalRegister(ichan,"Vthin_Coarse",vthrc);
    fei4->WriteGlobalRegister(ichan,"Vthin_Fine",vthrf);
    if ( clk320mhz ) {
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
    else {
      fei4->WriteGlobalRegister(ichan,"320",0);
      fei4->WriteGlobalRegister(ichan,"160",1);
      fei4->WriteGlobalRegister(ichan,"c02",1);
      fei4->WriteGlobalRegister(ichan,"c01",0);
      fei4->WriteGlobalRegister(ichan,"c00",0);
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
    if ( clk320mhz ) {
      fei4->Buffer()->Write(0xc8000000,0x10008100);
    }
    else {
      fei4->Buffer()->Write(0xc8000000,0x10000100);
    }
    fei4->WriteBuffer();

    int tdac = 8;
    int fdac = 8;
    unsigned int bits[21];

    int ic;
    for ( int idc=0; idc<40; idc++ ) {
      fei4::SetFrontEndBits(bits);
      fei4->ClearBuffer();
      fei4->WritePixelSR(ichan,COLPR_DC|idc,bits);
      fei4->LoadPixelLatches(ichan,COLPR_DC|idc,0x0001);
      fei4->WriteBuffer();
    }
  }
}
