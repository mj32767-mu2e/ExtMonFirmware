void DrawFtrim() {
  TCanvas *c2 = new TCanvas("c2",NULL,0,0,700,500);
  c2->cd();
  TFile *f2 = new TFile("channel_0.root");
  TH1F *tt = (TH1F *)f2->Get("/dthr_4/fdac_trimmed");
  TH1F *tu = (TH1F *)f2->Get("/dthr_4/fdac_untrimmed");
  f2->cd("dthr_4");
  tt->SetMaximum(2000);
  cout << "tt bin width = " << tt->GetBinWidth(1) << endl;
  tt->Draw();
  tu->SetLineColor(2);
  tu->Draw("same");
  tt->GetXaxis()->SetTitle("Mean time-over-threshold");
  tt->GetYaxis()->SetTitle("Entries per 0.25 TOT counts");
}
