void DrawQdac() {
  TFile *f=new TFile("junk.root");
  f->cd("dthr_4/r333c0");
  TCanvas *c1 =new TCanvas("c1",NULL,0,0,700,500);
  c1->cd();
  TH1F *h = gPad->DrawFrame(0,0,600,16);
  h->GetXaxis()->SetTitle("Charge injection DAC");
  h->GetYaxis()->SetTitle("Mean time-over-threshold");
  h->SetTitle("row 333 column 0");
  qdac->SetMarkerStyle(20);
  qdac->SetMarkerSize(0.5);
  qdac->Draw("P");
}
