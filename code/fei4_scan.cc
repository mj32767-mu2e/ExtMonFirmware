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

int efficiency(Fei4Interface *fei4,int chan,int n,double *eff,double *eeff) {
  unsigned int counters[16];
  fei4->ClearBuffer();
  fei4->ClearMatchCounters(chan);
  fei4->WriteBuffer();

  for ( int ip=0; ip<n/5; ip++ ) {
    fei4->Pulse(chan,0x66,5);
    usleep(1000);
  }

  fei4->ReadMatchCounters(chan,counters);
  if ( counters[0] == 0 ) {
    cout << "Error - no triggers detected." << endl;
    return 1;
  }
  for ( int i=0; i<10; i++ ) {
    eff[i] = (double)(counters[i+1]&0xffff)/n;
    eeff[i] = sqrt(eff[i]*(1-eff[i])/n);
  }
  return 0;
}

void scan_efficiency(Fei4Interface *fei4,int chan,
                     const char *name,int v0,int v1,int npt, int *val,
                     double *eff, double *eeff, int *status) {
  int ntrig = 1000;
  int v = v0;
  int dv = (v1-v0+1)/npt;
  for ( int i=0; i<npt; i++ ) {
    fei4->ClearBuffer();
    fei4->Buffer()->Write(FEI4_CMD(chan),0xaa070000);   // conf mode
    fei4->Buffer()->WaitClear(FEI4_CMD(chan),0x80000000);
    fei4->WriteBuffer();

    fei4->ClearBuffer();
    fei4->WriteGlobalRegister(chan,name,v);
    fei4->WriteModifiedRegisters(chan);
    fei4->WriteBuffer();

    val[i] = v;
    status[i] = efficiency(fei4,chan,ntrig,eff+10*i,eeff+10*i);
    v += dv;
  }
}

int main(int argc,char **argv) {
  unsigned int bits[21];
  if ( argc < 7 ) {
    cerr << "Usage: " << argv[0] << " <addr> <chan> <c> <r> <tdac> <vdac>" << endl;
    exit(1);
  }

  int chan = atoi(argv[2]);
  Fei4Interface *fei4 = new Fei4Interface(argv[1]);
  fei4->LogBuffer(0);
  int icol = atoi(argv[3]);
  int ir = atoi(argv[4]);
  int tdac = atoi(argv[5]);
  int vdac = atoi(argv[6]);

  int vthrc = 64;
  int vthrf = 128;
  int ntrig = 1000;
  int clk320mhz = 0;

  fei4->ClearBuffer();
  fei4->Buffer()->Write(FEI4_CMD(chan),0xaa070000);   // conf mode
  fei4->Buffer()->WaitClear(FEI4_CMD(chan),0x80000000);
  fei4->WriteBuffer();

  fei4->ClearBuffer();
  fei4->WriteGlobalRegister(chan,"CMDcnt12",0x1004);
  fei4->WriteGlobalRegister(chan,"M13",0);
  fei4->WriteGlobalRegister(chan,"HD1",0);
  fei4->WriteGlobalRegister(chan,"HD0",0);
  fei4->WriteGlobalRegister(chan,"Trig_Lat",0xb3);
  fei4->WriteGlobalRegister(chan,"PlsrIDACRamp",180);
  fei4->WriteGlobalRegister(chan,"Trig_Count",3);
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
  else {
    fei4->WriteGlobalRegister(chan,"320",0);
    fei4->WriteGlobalRegister(chan,"160",1);
    fei4->WriteGlobalRegister(chan,"c02",1);
    fei4->WriteGlobalRegister(chan,"c01",0);
    fei4->WriteGlobalRegister(chan,"c00",0);
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

  fei4->ClearBuffer();
  fei4->ClearPixelSR(chan,COLPR_ALL);
  fei4->LoadPixelLatches(chan,COLPR_ALL,0x1fff);
  fei4->WriteBuffer();

  for ( int ic=icol; ic<icol+10; ic+=2 ) {
    int idc = ic/2;
    fei4::ClearFrontEndBits(bits);
    fei4::SetFrontEndBit(ic,ir,bits);
    fei4::SetFrontEndBit(ic+1,ir,bits);
    fei4->WriteFrontEnd(chan,bits);
  
    cout << "Matching col " << ic << " row " << ir << endl;;

    fei4->ClearBuffer();
    fei4->WritePixelSR(chan,COLPR_DC|idc,bits);
    int revbits = 0;
    for ( int ib=0; ib<5; ib++ ) {
      if ( (tdac&(1<<(4-ib))) ) {
        revbits |= (2<<ib);
      }
    }
    fei4->LoadPixelLatches(chan,COLPR_DC|idc,0x00c1|revbits);
    fei4->WriteBuffer();

    fei4->ClearBuffer();
    fei4->ClearPixelSR(chan,COLPR_DC|idc);
    fei4->WriteBuffer();

    fei4->ClearBuffer();
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
  }
  cout << "  TDAC = " << tdac << endl;

  fei4->ClearBuffer();
  for ( int j=0; j<10; j++ ) {
    fei4->SetMatchPattern(chan,j+1,icol+j,ir,-1,-1);
  }
  fei4->WriteBuffer();

  cout << "  row " << ir << " col " << icol << "..." << endl;

  fei4->ClearBuffer();
  fei4->WriteGlobalRegister(chan,"PlsrDAC",vdac);
  fei4->WriteModifiedRegisters(chan);
  fei4->WriteBuffer();

  const int npt = 16;
  int status[npt];
  int value[npt];
  double eff[npt*10], eeff[npt*10];

//  scan_efficiency(fei4,chan,"Vthin_Coarse",0,32,npt,value,eff,eeff,status);
  scan_efficiency(fei4,chan,"PlsrDAC",200,800,npt,value,eff,eeff,status);
//  scan_efficiency(fei4,chan,"Vthin_Fine",0,255,npt,value,eff,eeff,status);

  for ( int i=0; i<npt; i++ ) {
    cout << setw(2) << i << "   " << setw(4) << value[i];
    for ( int j=0; j<10; j++ ) {
      cout << "  " << setw(5) << fixed << setprecision(3) << eff[10*i+j];
    }
    cout << endl;
  }

}
