void PlotTdac(const char *file) {
  TCanvas *c1 = new TCanvas("c1",NULL,0,0,700,500);
  c1->cd();
  gPad->DrawFrame(0,0,32,500);
  TFile *f=new TFile(file);
  for ( int ic=0; ic<80; ic++ ) {
    char label[32];
    sprintf( label, "dthr_4/r334c%d/tdac", ic );
    TGraph *g = (TGraph *)f->Get(label);
    g->Draw("L");
  }
/*
  for ( int ic=0; ic<80; ic++ ) {
    char label[32];
    sprintf( label, "dthr_4/r4c%d/tdac", ic );
    TGraph *g = (TGraph *)f->Get(label);
    g->SetLineColor(2);
    g->Draw("L");
  }
*/
}
