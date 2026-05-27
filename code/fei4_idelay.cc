#include <iostream>
#include <stdlib.h>

#include "fei4.hh"

using namespace std;
using namespace fei4;

int main(int argc,char **argv) {
  if ( argc < 3 ) {
    cerr << "Usage: " << argv[0] << " <addr> <chan>" << endl;
    exit(1);
  }
  int ichan = atoi(argv[2]);
  int clk320mhz = 1;
  Fei4Interface *fei4 = new Fei4Interface(argv[1]);
  fei4->LogBuffer(0);

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
//  Set default operating parameters in global registers
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
  fei4->WriteGlobalRegister(ichan,"Trig_Count",1);
  fei4->WriteGlobalRegister(ichan,"Vthin_Coarse",8);
  fei4->WriteGlobalRegister(ichan,"Vthin_Fine",32);

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
    fei4->Buffer()->Write(0xc8000000,0x30008006);   // enable 320 Mbps
  }
  else {
    fei4->Buffer()->Write(0xc8000000,0x30000006);   // disable 320 Mbps
  }
  fei4->Buffer()->Write(0xc8000014,0x40000000);   // reset hot pixel counters
  fei4->Buffer()->Write(0xc8000014,0x00000000);
  fei4->WriteBuffer();

  for ( int idelay=0; idelay<32; idelay++ ) {
    fei4->ClearBuffer();
    fei4->Buffer()->Write(0xc8000014,0x40000000);   // reset hot pixel counters
    fei4->Buffer()->Write(0xc8000014,0x00000000);
    int ind_sof = fei4->Buffer()->Read(0xc800104c|ichan<<8);
    int ind_eof = fei4->Buffer()->Read(0xc8001050|ichan<<8);
    fei4->WriteBuffer();
    int nsof = fei4->Buffer()->RxData(ind_sof,1);
    int neof = fei4->Buffer()->RxData(ind_eof,1);

    fei4->ClearBuffer();
    fei4->Buffer()->Write(0xc8000014,0x90000000|idelay<<16|ichan);
    fei4->Buffer()->Write(0xc8001004|ichan<<8,0x861c0000);  //  Read reg 28
    fei4->Buffer()->WaitClear(0xc8001004|ichan<<8,0x80000000);  //  Read reg 28
    fei4->Buffer()->Write(0xc8001004|ichan<<8,0x861c0000);  //  Read reg 28
    fei4->Buffer()->WaitClear(0xc8001004|ichan<<8,0x80000000);  //  Read reg 28
    fei4->Buffer()->Write(0xc8001004|ichan<<8,0x861c0000);  //  Read reg 28
    fei4->Buffer()->WaitClear(0xc8001004|ichan<<8,0x80000000);  //  Read reg 28
    fei4->Buffer()->Write(0xc8001004|ichan<<8,0x861c0000);  //  Read reg 28
    fei4->Buffer()->WaitClear(0xc8001004|ichan<<8,0x80000000);  //  Read reg 28
    ind_sof = fei4->Buffer()->Read(0xc800104c|ichan<<8);
    ind_eof = fei4->Buffer()->Read(0xc8001050|ichan<<8);
    fei4->WriteBuffer();
    int msof = fei4->Buffer()->RxData(ind_sof,1);
    int meof = fei4->Buffer()->RxData(ind_eof,1);

    cout << "idelay = " << idelay << ", SOF/EOF = " << nsof << "/" << neof << " --> " << msof << "/" << meof << endl;
  }
}
