#include <iostream>
#include <stdlib.h>

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
  if ( argc < 2 ) {
    cerr << "Usage: " << argv[0] << " <addr>" << endl;
    exit(1);
  }
  int clk320mhz = 1;
  int chmask = 0x03cf;
//  int chmask = 0x000f;
//  int chmask = 0x03c0;
  int ntrig = 12;
  int vthrc = 5;
  int vthrf = 64;
  Fei4Interface *fei4 = new Fei4Interface(argv[1]);
  fei4->LogBuffer(0);

  for ( int ichan=0; ichan<23; ichan++ ) {
    if ( chmask&(1<<ichan) ) {
      cout << "Configuring channel " << ichan << endl;
      fei4->ClearBuffer();
      fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa070000);   // conf mode
      fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
      fei4->WriteBuffer();
//
//  It is necessary to start the chip off in a well defined state so
//  that the global registers match the model in local memory
//
      fei4->Configure(ichan);


//
      fei4->ClearBuffer();
      fei4->WriteGlobalRegister(ichan,"DisableColCnfg0",0);
      fei4->WriteGlobalRegister(ichan,"DisableColCnfg1",0);
      fei4->WriteGlobalRegister(ichan,"DisableColCnfg2",0);
      fei4->WriteGlobalRegister(ichan,"PlsrDAC",1);
      fei4->WriteGlobalRegister(ichan,"CMDcnt12",0x1004);
      fei4->WriteGlobalRegister(ichan,"M13",0);
      fei4->WriteGlobalRegister(ichan,"HD0",1);
      fei4->WriteGlobalRegister(ichan,"HD1",0);
      fei4->WriteGlobalRegister(ichan,"PLL",1);
      fei4->WriteGlobalRegister(ichan,"SME",0);
      fei4->WriteGlobalRegister(ichan,"PPW",0);
      fei4->WriteGlobalRegister(ichan,"HOR",0);
      fei4->WriteGlobalRegister(ichan,"DHS",0);
      fei4->WriteGlobalRegister(ichan,"PlsrDelay",30);
      fei4->WriteGlobalRegister(ichan,"PlsrIDACRamp",180);
      fei4->WriteModifiedRegisters(ichan);
      fei4->WriteBuffer();

      fei4->ClearBuffer();
      fei4->WriteGlobalRegister(ichan,"Trig_Lat",158);
      fei4->WriteGlobalRegister(ichan,"Trig_Count",ntrig);
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
//
//  Enable all pixels
// 
      for ( int idc=0; idc<40; idc++ ) {
        fei4->ClearBuffer();
        fei4::SetFrontEndBits(bits);
        fei4->WritePixelSR(ichan,COLPR_DC|idc,bits);
        fei4->WriteBuffer();
        fei4->ClearBuffer();
        fei4->LoadPixelLatches(ichan,COLPR_DC|idc,0x0002);
        fei4->WriteBuffer();
      }
    }
  }

  fei4->ClearBuffer();
  if ( clk320mhz ) {
    fei4->Buffer()->Write(0xc8000000,0x00008006);   // enable 320 Mbps
  }
  else {
    fei4->Buffer()->Write(0xc8000000,0x00000006);   // disable 320 Mbps
  }
  fei4->Buffer()->Write(0xc8000014,0x40000000);   // reset hot pixel counters
  fei4->Buffer()->Write(0xc8000014,0x00000000);

  fei4->Buffer()->Write(0xc8000008,0x00000000|chmask|ntrig<<24);   //  Channel mask and number bc's per trigger
//
//  Reset the buffer manager
//
  fei4->Buffer()->Write(0xc8000000,0x08008006);
  fei4->Buffer()->Write(0xc8000000,0x00008006);
//
//  Define external trigger condition
//
  fei4->Buffer()->Write(0xc2000014,0x00400800);
  fei4->WriteBuffer();

  fei4->ClearBuffer();
  for ( int ichan=0; ichan<23; ichan++ ) {
    if ( chmask&(1<<ichan) ) {
      fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa380000);   // run mode  1010 1010 0011 1000
//                                                                      __33 3344 4455 5555
      fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
    }
  }
  fei4->WriteBuffer();
  usleep(100000);

  fei4->ClearBuffer();
  for ( int ichan=0; ichan<23; ichan++ ) {
    if ( chmask&(1<<ichan) ) {
      fei4->Buffer()->Write(FEI4_CMD(ichan),0xb4000000);   // ECR
      fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
    }
  }
  fei4->WriteBuffer();
  usleep(100000);

  fei4->ClearBuffer();
  for ( int ichan=0; ichan<23; ichan++ ) {
    if ( chmask&(1<<ichan) ) {
      fei4->Buffer()->Write(FEI4_CMD(ichan),0xb0010000);   // BCR
      fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
    }
  }
  fei4->WriteBuffer();
  usleep(100000);

  fei4->ClearBuffer();
  if ( clk320mhz ) {
    fei4->Buffer()->Write(0xc8000000,0x00008106);
  }
  else {
    fei4->Buffer()->Write(0xc8000000,0x00000106);
  }
  fei4->Buffer()->Write(0xc8000020,0x0000af09);
  fei4->WriteBuffer();

}
