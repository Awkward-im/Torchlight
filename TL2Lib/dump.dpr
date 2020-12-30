uses
  rgpak;

var
  lpi:TPAKInfo;
begin
  lpi.fname:=ParamStr(1);
  GetPAKInfo(lpi,piFullParse);
  DumpPAKInfo(lpi);
  ManToFile(ParamStr(1)+'.LOG',lpi);
  FreePAKInfo(lpi);
end.
