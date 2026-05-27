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
  if ( argc < 5 ) {
    cerr << "Usage: " << argv[0] << " <addr> <chan> <icol> <irow>" << endl;
    exit(1);
  }
  int ichan = atoi(argv[2]);;
  int icol = atoi(argv[3]);
  int irow = atoi(argv[4]);
  int clk320mhz = 1;
  int dig_inject = 0;
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
  int vthrc = 12;
  int vthrf = 128;
  int tdac = 7;
  fei4->ClearBuffer();
  if ( dig_inject ) {
    fei4->WriteGlobalRegister(ichan,"CMDcnt12",0x1003);
    fei4->WriteGlobalRegister(ichan,"M13",0);
    fei4->WriteGlobalRegister(ichan,"PLL",1);
    fei4->WriteGlobalRegister(ichan,"SME",0);
    fei4->WriteGlobalRegister(ichan,"HD1",0);
    fei4->WriteGlobalRegister(ichan,"HD0",0);
    fei4->WriteGlobalRegister(ichan,"Trig_Lat",175);
    fei4->WriteGlobalRegister(ichan,"PlsrIDACRamp",180);
    fei4->WriteGlobalRegister(ichan,"Trig_Count",1);
    fei4->WriteGlobalRegister(ichan,"PlsrDAC",1);
    fei4->WriteGlobalRegister(ichan,"DHS",1);
    fei4->WriteGlobalRegister(ichan,"PlsrDelay",1);
    fei4->WriteGlobalRegister(ichan,"TDACVbp",255);
    fei4->WriteGlobalRegister(ichan,"Vthin_Coarse",vthrc);
    fei4->WriteGlobalRegister(ichan,"Vthin_Fine",vthrf);
  }
  else {
    fei4->WriteGlobalRegister(ichan,"CMDcnt12",0x1004);
    fei4->WriteGlobalRegister(ichan,"M13",0);
    fei4->WriteGlobalRegister(ichan,"HD1",0);
    fei4->WriteGlobalRegister(ichan,"HD0",0);
    fei4->WriteGlobalRegister(ichan,"Trig_Lat",0xb3);
    fei4->WriteGlobalRegister(ichan,"PlsrIDACRamp",180);
    fei4->WriteGlobalRegister(ichan,"Trig_Count",2);
    fei4->WriteGlobalRegister(ichan,"DHS",0);
    fei4->WriteGlobalRegister(ichan,"PlsrDelay",30);
    fei4->WriteGlobalRegister(ichan,"TDACVbp",255);
    fei4->WriteGlobalRegister(ichan,"PlsrDAC",999);
    fei4->WriteGlobalRegister(ichan,"Vthin_Coarse",vthrc);
    fei4->WriteGlobalRegister(ichan,"Vthin_Fine",vthrf);
  }
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
    fei4->Buffer()->Write(0xc8000000,0x10008000);
  }
  else {
    fei4->Buffer()->Write(0xc8000000,0x10000000);
  }
  fei4->WriteBuffer();

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
  fei4->ClearBuffer();
  fei4::ClearFrontEndBits(bits);
  int nmatch = 0;
  if ( dig_inject ) {
    fei4::SetFrontEndBit((icol-1)%2,irow-1,bits);
    fei4::SetFrontEndBit((icol)%2,irow-1,bits);
    fei4::SetFrontEndBit((icol-1)%2,irow+1,bits);
    fei4::SetFrontEndBit((icol)%2,irow+1,bits);

    fei4->SetMatchPattern(ichan,1,icol-1,irow-1,-1,-1);
    fei4->SetMatchPattern(ichan,2,icol,irow-1,-1,-1);
    fei4->SetMatchPattern(ichan,3,icol-1,irow+1,-1,-1);
    fei4->SetMatchPattern(ichan,4,icol,irow+1,-1,-1);
    nmatch = 4;
  }
  else {
    fei4::SetFrontEndBit((icol-1)%2,irow-1,bits);

    fei4->SetMatchPattern(ichan,1,icol-1,irow-1,-1,-1);
    nmatch = 1;
  }
  fei4->WriteFrontEnd(ichan,bits);
  cout << "Channel " << ichan << " (C,R)=("
       << icol << "," << irow << ") " << (clk320mhz?"320 MHz":"160 MHz")
       << " " << (dig_inject?"digital":"analog") << " injection." << endl;

  int jdc;
  if ( dig_inject ) {
//
//   Load bit 1 in double column 0 from the pixel shift register
//
    fei4->LoadPixelLatches(ichan,(icol-1)/2,0x0001);
    jdc = (icol-1)/2;
  }
  else {
    fei4->WritePixelSR(ichan,COLPR_DC|(icol-1)/2,bits);
    int revbits = 0;
    for ( int ib=0; ib<5; ib++ ) {
      if ( (tdac&(1<<(4-ib))) ) {
        revbits |= (2<<ib);
      }
    }
    fei4->LoadPixelLatches(ichan,COLPR_DC|(icol-1)/2,0x00c1|revbits);
    fei4->ClearPixelSR(ichan,COLPR_DC|(icol-1)/2);
    if ( icol == 1 ) {
      jdc = 0;
    }
    else if ( icol < 78 ) {
      jdc = icol/2;
    }
    else {
      jdc = 39;
    }
  }
  fei4->WriteGlobalRegister(ichan,"Colpr_Addr",jdc);
  fei4->WriteModifiedRegisters(ichan);
  fei4->WriteBuffer();

  fei4->Buffer()->Write(0xc8000014,0x40000000);   // reset hot pixel counters
  fei4->Buffer()->Write(0xc8000014,0x00000000);
  fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa380000);   // run mode
  fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
  fei4->WriteBuffer();

  fei4->ClearBuffer();
  fei4->Buffer()->Write(0xc8000014,0xc0000000|ichan);
  fei4->Buffer()->Write(0xc8000014,0x00000000|ichan);
  fei4->WriteBuffer();

  int ind[9];

  fei4->ClearBuffer();
  fei4->Buffer()->Write(0xc8000014,0x80000000|ichan);
  fei4->Buffer()->WaitClear(0xc8000014,0x80000000);
  fei4->ClearMatchCounters(ichan);
  fei4->WriteBuffer();

  fei4->ClearBuffer();
  fei4->Buffer()->Write(0xc8000014,0x40000000|ichan);
  fei4->Buffer()->Write(0xc8000014,0x00000000|ichan);
  fei4->Buffer()->Write(0xc8000004,0x80660a08);   // generate pulse
  fei4->WriteBuffer();

  sleep(1);

  unsigned int counters[16];
  fei4->ReadMatchCounters(ichan,counters);
  for ( int i=0; i<nmatch; i++ ) {
    cout << "Pixel (r,c) = (" << ((counters[i+1]>>16)&0x1f) << "," << ((counters[i+1]>>25)&0x7f) << ") = " << (counters[i+1]&0xffff) << endl;
  }

  fei4->ClearBuffer();
  ind[0] = fei4->Buffer()->Read(0xc8000014);
  ind[1] = fei4->Buffer()->Read(0xc8001060|ichan*0x100);
  ind[2] = fei4->Buffer()->Read(0xc8001064|ichan*0x100);
  ind[3] = fei4->Buffer()->Read(0xc8001068|ichan*0x100);
  ind[4] = fei4->Buffer()->Read(0xc800106c|ichan*0x100);
  ind[5] = fei4->Buffer()->Read(0xc8001070|ichan*0x100);
  ind[6] = fei4->Buffer()->Read(0xc8001074|ichan*0x100);
  ind[7] = fei4->Buffer()->Read(0xc8001078|ichan*0x100);
  ind[8] = fei4->Buffer()->Read(0xc800107c|ichan*0x100);
  fei4->WriteBuffer();

  for ( int i=0; i<8; i++ ) {
    int row, col, count;
    unsigned int word = fei4->Buffer()->RxData(ind[i+1],1);
    if ( word != 0 ) {
      count = word&0xffff;
      col = (word>>25)&0x7f;
      row = (word>>16)&0x1ff;
      cout << "Hot pixel counter " << i << " = " << hex << setw(8) << word << " : (r,c) = " << dec << row << "," << col << " = " << count << endl;
    }
  }

}
