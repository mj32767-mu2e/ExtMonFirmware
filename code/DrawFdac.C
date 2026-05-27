void DrawFdac() {
  TFile *f=new TFile("junk.root");
  f->cd("dthr_4/r333c0");
  TCanvas *c1 =new TCanvas("c1",NULL,0,0,700,500);
  c1->cd();
  TH1F *h = gPad->DrawFrame(0,0,16,16);
  h->GetXaxis()->SetTitle("FDAC value");
  h->GetYaxis()->SetTitle("Mean time-over-threshold");
  h->SetTitle("row 333 column 0 - Vdac = 350");
  fdac->SetMarkerStyle(20);
  fdac->SetMarkerSize(0.5);
  fdac->Draw("P");
  TF1 *func = (TF1 *)fdac->GetFunction("func");
  double a = func->GetParameter(0);
  double b = func->GetParameter(1);
  double c = func->GetParameter(2);
  double trim = log(b/(8-a))/c;
  TLine *l = new TLine(trim,0,trim,8);
  l->Draw();
  l->DrawLine(0,8,trim,8);
  
}
