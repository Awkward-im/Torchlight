uses
  rgpak;

var
  lpi:TPAKInfo;
begin
  lpi.fname:=ParamStr(1);
  GetPAKInfo(lpi,piParse);
  UnpackAll(@lpi,'');
  FreePAKInfo(lpi);
end.
