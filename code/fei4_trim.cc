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

int efficiency(Fei4Interface *fei4,int chan,int n,double &eff,double &eeff) {
  unsigned int counters[16];
  fei4->ClearBuffer();
  fei4->ClearMatchCounters(chan);
  fei4->WriteBuffer();

  int mod = 8;
  for ( int ip=0; ip<n/mod; ip++ ) {
    fei4->Pulse(chan,0x66,mod);
  }
  if ( n%mod > 0 ) {
    fei4->Pulse(chan,0x66,n%mod);
  }

  fei4->ReadMatchCounters(chan,counters);
  if ( counters[0] == 0 ) {
    cout << "Error - no triggers detected." << endl;
    return 1;
  }
  eff = (double)(counters[1]&0xffff)/n;
  eeff = sqrt(eff*(1-eff)/n);
  return 0;
}

void scan_efficiency(Fei4Interface *fei4,int chan,
                     const char *name,int v0,int v1,
                     vector<int> &val, vector<double> &eff,
                     vector<double> &eeff,double &v50) {
  int ntrig = 50;
  int npt = 5;
  int scan = 0;
  int dv = (v1-v0)/npt;
  int vs[3] = { v0, (v0+v1)/2, v1 };
  double es[3] = { 0, 0, 1 };
  if ( scan ) {
    for ( int v=v0; v<=v1; v+=dv ) {
      fei4->ClearBuffer();
      fei4->Buffer()->Write(FEI4_CMD(chan),0xaa070000);   // conf mode
      fei4->Buffer()->WaitClear(FEI4_CMD(chan),0x80000000);
      fei4->WriteBuffer();

      fei4->ClearBuffer();
      fei4->WriteGlobalRegister(chan,name,v);
      fei4->WriteModifiedRegisters(chan);
      fei4->WriteBuffer();

//      cout << "  " << name << " <-- " << v << endl;

      double e, ee;
      if ( efficiency(fei4,chan,ntrig,e,ee) == 0 ) {
        val.push_back(v);
        eff.push_back(e);
        eeff.push_back(ee==0?1.0/ntrig:ee);
        if ( e < 0.01 ) vs[0] = v;
        if ( e > 0.99 && vs[2] == 0 ) {
          vs[2] = v;
          break;
        }
      }
    }
  }

  es[0] = 0;
  es[2] = 1;
//  cout << "Bounded by (" << vs[0] << "," << vs[2] << ")" << endl;
  while ( vs[2]-vs[0] > 1 ) {
    vs[1] = 0.5*(vs[2]+vs[0]);
    fei4->ClearBuffer();
    fei4->Buffer()->Write(FEI4_CMD(chan),0xaa070000);   // conf mode
    fei4->Buffer()->WaitClear(FEI4_CMD(chan),0x80000000);
    fei4->WriteBuffer();

    fei4->ClearBuffer();
    fei4->WriteGlobalRegister(chan,name,vs[1]);
    fei4->WriteModifiedRegisters(chan);
    fei4->WriteBuffer();

//    cout << "  " << name << " <-- " << vs[1] << endl;

    double e, ee;
    ntrig = 500-300*(es[2]-es[0]);
    if ( efficiency(fei4,chan,ntrig,e,ee) == 0 ) {
      val.push_back(vs[1]);
      eff.push_back(e);
      eeff.push_back(ee==0?1.0/ntrig:ee);
      es[1] = e;
      if ( e > 0.5 ) {
        vs[2] = vs[1];
        es[2] = e;
      }
      if ( e < 0.5 ) {
        vs[0] = vs[1];
        es[0] = e;
      }
    }
  }
  if ( es[2]-es[0] > 0 ) {
    v50 = vs[0]+(vs[2]-vs[0])*(0.5-es[0])/(es[2]-es[0]);
//    cout << "vs[0] = " << vs[0] << ", es[0] = " << es[0] << endl;
//    cout << "vs[1] = " << vs[1] << ", es[1] = " << es[1] << endl;
//    cout << "vs[2] = " << vs[2] << ", es[2] = " << es[2] << endl;
  }
  else {
    v50 = -1;
  }
  cout << "v50 = " << v50 << endl;
}

void write_pixel(Fei4Interface *fei4,int ichan,
                 int ic,int ir,int tdac,int fdac) {
  unsigned int bits[21];
  int idc = ic/2;
  fei4->ClearBuffer();
  fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa070000);   // conf mode
  fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
  fei4->WriteBuffer();
  fei4->ClearBuffer();
  fei4->ClearPixelSR(ichan,COLPR_ALL);
  fei4->LoadPixelLatches(ichan,COLPR_ALL,0x1fff);
  fei4->WriteBuffer();
  fei4->ClearBuffer();
  fei4::ClearFrontEndBits(bits);
  fei4::SetFrontEndBit(ic,ir,bits);
  fei4->WriteFrontEnd(ichan,bits);
  fei4->ClearBuffer();
  fei4->WritePixelSR(ichan,COLPR_DC|idc,bits);
  int revbits = 0;
  for ( int ib=0; ib<5; ib++ ) {
    if ( (tdac&(1<<(4-ib))) ) {
      revbits |= (2<<ib);
    }
  }
  revbits |= (fdac&0x0f)<<9;
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
  fei4->WriteGlobalRegister(ichan,"Colpr_Addr",jdc);
  fei4->WriteModifiedRegisters(ichan);
  fei4->WriteBuffer();
}

int main(int argc,char **argv) {
  if ( argc < 7 ) {
    cerr << "Usage: " << argv[0] << " <addr> <chan> <c> <r> <dthr> <file>" << endl;
    exit(1);
  }
  int ichan = atoi(argv[2]);
  int ic0, ic1;
  int ir0, ir1;
  char *p;
  if ( ( p = strchr(argv[3],'-') ) == NULL ) {
    ic0 = ic1 = atoi(argv[3]);
  }
  else {
    ic0 = atoi(argv[3]);
    ic1 = atoi(p+1);
  }

  if ( ( p = strchr(argv[4],'-') ) == NULL ) {
    ir0 = ir1 = atoi(argv[4]);
  }
  else {
    ir0 = atoi(argv[4]);
    ir1 = atoi(p+1);
  }

  if ( ic0 < 0 || ic1 > 79 ) {
    cout << "Bad column range." << endl;
    exit(1);
  }
  if ( ir0 < 0 || ir1 > 335 ) {
    cout << "Bad row range." << endl;
    exit(1);
  }

  int vthrc = atoi(argv[5]);
  TFile *fout = NULL;
  const int ntdac = 9;
  const int tdac[ntdac] = {  0, 4,  8, 12, 16, 20, 24, 28, 31 };
  TGraphErrors *g_tdac[ntdac];
  for ( int i=0; i<ntdac; i++ ) g_tdac[i] = NULL;
  TH1F *h_tuntrim = NULL;
  TH1F *h_ttrim = NULL;
  TH1F *h_funtrim = NULL;
  TH1F *h_ftrim = NULL;
  fout = new TFile(argv[6],"UPDATE");
  char label[16];
  sprintf( label, "dthr_%d", vthrc );
  if ( ! fout->cd(label) ) {
    fout->mkdir(label);
    fout->cd(label);
  }
  h_tuntrim = (TH1F *)gDirectory->Get("tdac_untrimmed");
  if ( h_tuntrim == NULL ) {
    h_tuntrim = new TH1F("tdac_untrimmed","Untrimmed Vdac",125,0,250);
  }
  h_ttrim = (TH1F *)gDirectory->Get("tdac_trimmed");
  if ( h_ttrim == NULL ) {
    h_ttrim = new TH1F("tdac_trimmed","Trimmed Vdac",125,0,250);
  }
  h_funtrim = (TH1F *)gDirectory->Get("fdac_untrimmed");
  if ( h_funtrim == NULL ) {
    h_funtrim = new TH1F("fdac_untrimmed","Untrimmed TOT",64,0,16);
  }
  h_ftrim = (TH1F *)gDirectory->Get("fdac_trimmed");
  if ( h_ftrim == NULL ) {
    h_ftrim = new TH1F("fdac_trimmed","Trimmed TOT",64,0,16);
  }

  TF1 *pol2 = new TF1("pol2","pol2",0,31);
  TF1 *func = new TF1("func","[0]+[1]*exp(-x*[2])",0,16);

  Fei4Interface *fei4 = new Fei4Interface(argv[1]);

//  int vthrf = 128;
  int vthrf = 32;
  int clk320mhz = 1;
  double vtrim = 100.0;
  int full_analysis = 1;

  fei4->ClearBuffer();
  fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa070000);   // conf mode
  fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
  fei4->WriteBuffer();

  fei4->ClearBuffer();
  fei4->WriteGlobalRegister(ichan,"CMDcnt12",0x1004);
  fei4->WriteGlobalRegister(ichan,"M13",0);
  fei4->WriteGlobalRegister(ichan,"HD1",0);
  fei4->WriteGlobalRegister(ichan,"HD0",0);
  fei4->WriteGlobalRegister(ichan,"Trig_Lat",0xb3);
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
    fei4->Buffer()->Write(0xc8000000,0x10008000);
  }
  else {
    fei4->Buffer()->Write(0xc8000000,0x10000000);
  }
  fei4->WriteBuffer();

  for ( int ic=ic0; ic<=ic1; ic++ ) {
    for ( int ir=ir0; ir<=ir1; ir++ ) {

      cout << "------------------------------------------------------" << endl;
      cout << "   Row " << ir << ", column " << ic << endl;
      cout << "------------------------------------------------------" << endl;
      sprintf( label, "dthr_%d", vthrc );
      fout->cd(label);
      sprintf( label, "r%dc%d", ir, ic );
      if ( ! gDirectory->cd(label) ) {
        gDirectory->mkdir(label);
        gDirectory->cd(label);
      }
      for ( int i=0; i<ntdac; i++ ) {
        g_tdac[i] = new TGraphErrors();
      }

//
//   Loop over tdac values
//
      TGraph *g_td = new TGraph();
      for ( int it=0; it<ntdac; it++ ) {

        write_pixel(fei4,ichan,ic,ir,tdac[it],0);

        fei4->ClearBuffer();
        fei4->SetMatchPattern(ichan,1,ic,ir,-1,-1);
        fei4->WriteBuffer();
        cout << "  TDAC = " << tdac[it] << endl;

        vector<int> value;
        vector<double> eff;
        vector<double> eeff;
        double v50;

        scan_efficiency(fei4,ichan,"PlsrDAC",1,1023,value,eff,eeff,v50);
        if ( isnormal(v50) && v50 < 1022 && v50 > 1 ) {
          g_td->SetPoint(it,tdac[it],v50);
        }

        for ( int i=0; i<value.size(); i++ ) {
//          cout << setw(2) << i << "   " << setw(4) << value[i] << "   "
//               << setw(5) << fixed << setprecision(3) << eff[i] << " +- "
//               << eeff[i] << endl;
          g_tdac[it]->SetPoint(i,value[i],eff[i]);
          g_tdac[it]->SetPointError(i,0.0,eeff[i]);
        }
        char label[16];
        sprintf( label, "tdac_%d", tdac[it] );
//        g_tdac[it]->Write(label);
      }
      g_td->Write("tdac");

      if ( full_analysis ) {
        g_td->Fit(pol2);
        if ( h_tuntrim != NULL ) h_tuntrim->Fill(pol2->Eval(0),1);
        double a = pol2->GetParameter(2);
        double b = pol2->GetParameter(1);
        double c = pol2->GetParameter(0);
        double trim = (vtrim-c)/b;
        cout << "Trim value(1) = " << trim << endl;
        trim = (-b-sqrt(b*b-4*a*(c-vtrim)))/(2*a);
        cout << "Trim value(2) = " << trim << endl;
        int dtrim = (int)round(trim);
        if ( dtrim < 0 ) dtrim = 0;
        if ( dtrim > 31 ) dtrim = 31;
        if ( h_ttrim != NULL ) h_ttrim->Fill(pol2->Eval(dtrim),1);

        write_pixel(fei4,ichan,ic,ir,dtrim,0);

        fei4->ClearBuffer();
        fei4->SetMatchPattern(ichan,1,ic,ir,-1,-1);
        for ( int iq=0; iq<14; iq++ ) {
          fei4->SetMatchPattern(ichan,iq+2,ic,ir,iq,-1);
        }
        fei4->WriteBuffer();
        int ntrig = 100;
        TGraph *g_qdac = new TGraph();
        int ipt = 0;
        for ( int v=90; v<=550; v+=5 ) {
          fei4->ClearBuffer();
          fei4->Buffer()->Write(FEI4_CMD(ichan),0xaa070000);   // conf mode
          fei4->Buffer()->WaitClear(FEI4_CMD(ichan),0x80000000);
          fei4->WriteBuffer();

          fei4->ClearBuffer();
          fei4->WriteGlobalRegister(ichan,"Trig_Count",1);
          fei4->WriteGlobalRegister(ichan,"PlsrDAC",v);
          fei4->WriteModifiedRegisters(ichan);
          fei4->ClearMatchCounters(ichan);
          fei4->WriteBuffer();
  
//          cout << "  " << "PlsrDAC" << " <-- " << v << endl;

          for ( int i=0; i<10; i++ ) {
            fei4->Pulse(ichan,0x66,8);
          }
          unsigned int counters[16];
          fei4->ReadMatchCounters(ichan,counters);
          double sy = 0;
          double sxy = 0;
          for ( int i=0; i<16; i++ ) {
            if ( i > 1 ) {
              sy += (counters[i]&0xffff);
              sxy += (i-2)*(counters[i]&0xffff);
            }
          }
          if ( sy > 0 ) {
            double q = sxy/sy;
            g_qdac->SetPoint(ipt++,v,q);
          }
        }
        g_qdac->Write("qdac");

        fei4->ClearBuffer();
        fei4->WriteGlobalRegister(ichan,"PlsrDAC",350);
        fei4->WriteModifiedRegisters(ichan);
        fei4->WriteBuffer();
        TGraph *g_fdac = new TGraph();
        for ( int iq=0; iq<16; iq++ ) {
          write_pixel(fei4,ichan,ic,ir,dtrim,iq);
          fei4->ClearBuffer();
          fei4->ClearMatchCounters(ichan);
          fei4->WriteBuffer();

          for ( int i=0; i<10; i++ ) {
            fei4->Pulse(ichan,0x66,8);
          }

          unsigned int counters[16];
          fei4->ReadMatchCounters(ichan,counters);
          double sy = 0;
          double sxy = 0;
          for ( int i=0; i<16; i++ ) {
            if ( i > 1 ) {
              sy += (counters[i]&0xffff);
              sxy += (i-2)*(counters[i]&0xffff);
            }
          }
          if ( sy > 0 ) {
            double q = sxy/sy;
            g_fdac->SetPoint(iq,iq,q);
          }
        }
        func->SetParameters(3.5,10,0.15);
        g_fdac->Fit("func");
        g_fdac->Write("fdac");
        h_funtrim->Fill(func->Eval(0),1);

        a = func->GetParameter(0);
        b = func->GetParameter(1);
        c = func->GetParameter(2);
        trim = log(b/(8-a))/c;
        cout << "Fdac trim value = " << trim << endl;
        dtrim = (int)round(trim);
        if ( dtrim < 0 ) dtrim = 0;
        if ( dtrim > 15 ) dtrim = 15;
        if ( h_ftrim != NULL ) h_ftrim->Fill(func->Eval(dtrim),1);
    
      }
    }
  }

  if ( fout != NULL ) {
    fout->cd();
    fout->Write();
    gROOT->GetListOfFiles()->Remove(fout);
    fout->Close();
  }

}
