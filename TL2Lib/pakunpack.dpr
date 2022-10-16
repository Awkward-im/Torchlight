uses
  sysutils,
  rgglobal,
  rgpak;

var
  lpi:TRGPAK;
  t:longint;
begin
  t := GetTickCount64;
  lpi.Init;
  lpi.GetInfo(ParamStr(1),piParse);
  lpi.UnpackAll('');

  lpi.Free;
  writeln(GetTickCount64 - t);
end.
