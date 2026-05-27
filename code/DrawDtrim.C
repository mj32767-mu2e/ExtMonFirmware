void DrawDtrim() {
  TCanvas *c2 = new TCanvas("c2",NULL,0,0,700,500);
  c2->cd();
  TFile *f2 = new TFile("channel_0.root");
  TH1F *tt = (TH1F *)f2->Get("/dthr_4/tdac_trimmed");
  TH1F *tu = (TH1F *)f2->Get("/dthr_4/tdac_untrimmed");
  f2->cd("dthr_4");
  tt->SetMaximum(1500);
  cout << "tt bin width = " << tt->GetBinWidth(1) << endl;
  tt->Draw();
  tu->SetLineColor(2);
  tu->Draw("same");
  tt->GetXaxis()->SetTitle("Threshold");
  tt->GetYaxis()->SetTitle("Entries per 2 DAC counts");
}
