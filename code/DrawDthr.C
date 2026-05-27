void DrawDthr() {
  TFile *f=new TFile("junk.root");
  f->cd("dthr_4/r333c0");
  TCanvas *c1 = new TCanvas("c1",NULL,0,0,700,500);
  c1->cd();
  TH1F *h = gPad->DrawFrame(0,0,32,300);
  h->SetTitle("column 0 row 333");
  h->GetXaxis()->SetTitle("TDAC trim value");
  h->GetYaxis()->SetTitle("Threshold (DAC counts)");
  TGraph *tdac = (TGraph *)f->Get("/dthr_4/r333c0/tdac");
  tdac->SetMarkerStyle(20);
  tdac->Draw("P");
  TF1 *func = new TF1("func","pol2",0,32);
  tdac->Fit(func);
  double a = func->GetParameter(2);
  double b = func->GetParameter(1);
  double c = func->GetParameter(0);
  double v = 100;
  double x = (-b-sqrt(b*b-4*a*(c-v)))/(2*a);
  TLine *l = new TLine(x,0,x,100);
  l->Draw();
  l->DrawLine(x,100,0,100);

}
