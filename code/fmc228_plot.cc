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
#include <pthread.h>
#include <semaphore.h>

#include "TApplication.h"
#include "TROOT.h"
#include "TFile.h"
#include "TCanvas.h"
#include "TText.h"
#include "TGraph.h"
#include "TPolyMarker.h"
#include "TH1.h"
#include "TF1.h"
#include "TLine.h"

#define BUFLEN 2048
#define NBUF 512

static unsigned char recvbuf[NBUF][BUFLEN];
int ibuf = 0;
sem_t sem;

static int colors[] = { 46, 38, 41, 30 };
using namespace std;

void *Receiver(void *threadid) {
  int s, dlen, len;
  struct sockaddr_in saddr, daddr;

  unsigned short port = *(unsigned short *)threadid;
  if ( ( s = socket(AF_INET,SOCK_DGRAM,0) ) < 0 ) {
    cerr << "Receiver: socket() - " << strerror(errno) << endl;
    goto bail;
  }
  bzero((char *)&saddr,sizeof(saddr));
  saddr.sin_family = AF_INET;
  saddr.sin_addr.s_addr = htonl(INADDR_ANY);
  saddr.sin_port = htons(port);

  if ( bind(s,(struct sockaddr *)&saddr,sizeof(saddr)) < 0 ) {
    cerr << "Receiver: bind() - " << strerror(errno) << endl;
    goto bail;
  }
  cout << "Listening on port " << port << endl;
  while(1) {
    dlen = sizeof(daddr);
    int len;
    if ( ( len = recvfrom(s,(void *)recvbuf[ibuf],BUFLEN,0,(struct sockaddr *)&daddr,(socklen_t *)&dlen) ) < 0 ) {
      cerr << "Receiver: recvfrom() - " << strerror(errno) << endl;
      goto bail;
    }
    sem_wait(&sem);
    ibuf = (ibuf+1)%NBUF;
    sem_post(&sem);
  }

bail:
  pthread_exit(NULL);
}

int main(int argc,char **argv) {

  unsigned short port;
  pthread_t thread;
  int iptr;

  if ( argc < 2 ) {
    cerr << "Usage: " << argv[0] << " <port>" << endl;
    exit(1);
  }
  port = atoi(argv[1]);

  double vmax = 100;
  double vmin = -2000;
//  double vmax = 64;
//  double vmin = -256;
  TApplication app("fmc228",&argc,argv);
  gROOT->SetStyle("Plain");

  TCanvas *c1 = new TCanvas("c1",NULL,0,0,700,500);
  c1->cd();
  c1->SetFillColor(1);
  c1->Draw();
  TH1F *h_frame = gPad->DrawFrame(0,vmin,2048,vmax);
  h_frame->SetLineColor(0);
  h_frame->GetXaxis()->SetTitleFont(42);
  h_frame->GetYaxis()->SetTitleFont(42);
  h_frame->GetXaxis()->SetLabelFont(42);
  h_frame->GetYaxis()->SetLabelFont(42);
  h_frame->GetXaxis()->SetTitleColor(0);
  h_frame->GetYaxis()->SetTitleColor(0);
  h_frame->GetXaxis()->SetAxisColor(0);
  h_frame->GetYaxis()->SetAxisColor(0);
  h_frame->GetXaxis()->SetLabelColor(0);
  h_frame->GetYaxis()->SetLabelColor(0);
  h_frame->GetXaxis()->SetTitle("Time (ns)");
  TLine *l = new TLine();
  l->SetLineColor(11);
  for ( int i=0; i<=2048; i+=256 ) {
    l->DrawLine(i,vmin,i,vmax);
  }
  l->DrawLine(0,vmax,2048,vmax);
  c1->Update();

  if ( sem_init(&sem,0,1) != 0 ) {
    cerr << argv[0] << ": sem_init() - " << strerror(errno) << endl;
    exit(1);
  }
  pthread_create(&thread,NULL,Receiver,(void *)&port);
  int jptr = 0;
  TGraph *g[4];
  TLine *ldecay = new TLine();

  for ( int i=0; i<4; i++ ) {
    g[i] = NULL;
  }
  double xx[16384], yy[16384];

  TFile *fout = new TFile("fmc228_plot.root","RECREATE");
  fout->cd();
  fout->Close();
  int evtnum = 1;

  unsigned int bits = 0;
  while ( 1 ) {
    sem_wait(&sem);
    iptr = ibuf;
    sem_post(&sem);
    if ( iptr != jptr ) {
      unsigned int *buf = (unsigned int *)recvbuf[jptr];
      cout << "Buffer " << jptr << "  @" << (void *)buf
           << " = " << hex << setw(8) << setfill('0') << buf[0] << dec;
      int ichan = buf[0]&0x03;
      int ibuf = (buf[0]>>4)&0x0f;
      int ifrag = (buf[0]>>12)&0xf;
      int nfrag = (buf[0]>>8)&0xf;
      bits |= 1<<(ichan*nfrag+ifrag);
      if ( nfrag == 0 ) nfrag = 16;
      cout << "  Ch. " << ichan << " buf " << ibuf << " frag " << ifrag << "/" << nfrag << endl;
      const int pkt_size = 128;   // in 32-bit words
      for ( int i=0; i<pkt_size; i++ ) {
        unsigned int word = buf[1+i];
        int k = 2*(ifrag*pkt_size+i);
        unsigned short w;
        short v;
        w = (word>>4)&0xfff;
        v = (w&0x800)?-((w^0xfff)+1):w;
        int cs = word&0x0f;
//        if ( i < 4 || i > pkt_size-5 ) {
//          cout << "k = " << k << " v = " << v << endl;
//        }
        xx[k] = k;
        yy[k] = v - 128*ichan;
        k += 1;
        w = (word>>20)&0xfff;
        v = (w&0x800)?-((w^0xfff)+1):w;
        cs = (word>>16)&0x0f;
        xx[k] = k;
        yy[k] = v - 128*ichan;
//        if ( i < 4 || i > pkt_size-5 ) {
//          cout << "k = " << k << " v = " << v << endl;
//        }
      }
//      cout << "Trailer: 0x" << setw(8) << setfill('0') << hex << buf[129] << dec << endl;

      if ( ifrag == nfrag-1 ) {
        if ( ichan == 3 ) {
          if ( bits != 0xffffffff ) {
            cout << "Missing data: " << setw(8) << hex << setfill('0') << bits << endl;
          }
          bits = 0;

        }
        if ( g[ichan] != NULL ) delete g[ichan];
        g[ichan] = new TGraph(nfrag*pkt_size*2,xx,yy);
        g[ichan]->SetLineColor(colors[ichan]);
        g[ichan]->Draw("L");
        if ( ichan == 3 ) {
          TFile *fout = new TFile("fmc228_plot.root","UPDATE");
          fout->cd();
          char dirname[64];
          sprintf( dirname, "event_%06d", evtnum++ );
          TDirectory *dir = fout->mkdir(dirname);
          dir->cd();
          if ( g[0] != NULL ) g[0]->Write("channel_0");
          if ( g[1] != NULL ) g[1]->Write("channel_1");
          if ( g[2] != NULL ) g[2]->Write("channel_2");
          if ( g[3] != NULL ) g[3]->Write("channel_3");
          fout->Close();
        }
        c1->Update();
      }
      jptr = (jptr+1)%NBUF;
    }
  }

  return 0;
}
