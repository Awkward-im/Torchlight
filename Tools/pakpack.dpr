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
  lpi.man.build(ParamStr(1));
  lpi.Directory:=ParamStr(1);
  lpi.Name  :='tedt';
  lpi.Version:=verTL2;
  lpi.packAll();

  lpi.Free;
  writeln(GetTickCount64 - t);
end.
