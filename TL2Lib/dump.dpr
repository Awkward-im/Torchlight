uses
  rgpak;

var
  lpi:TPAKInfo;
begin
  lpi.fname:=ParamStr(1);
  GetPAKInfo(lpi,piFullParse);
  writeln('Entries: ',Length(lpi.Entries));
  writeln('Total: ',lpi.total);
  DumpPAKInfo(lpi);
  FreePAKInfo(lpi);
end.
