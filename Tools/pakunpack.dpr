uses
  rgglobal,
  rgpak;

var
  lpi:TPAKInfo;
begin
  GetPAKInfo(ParamStr(1),lpi,piParse);
  UnpackAll(lpi,'');
  FreePAKInfo(lpi);
end.
