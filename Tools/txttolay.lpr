{$R ..\TL2Lib\dict.rc}

uses
  rgglobal,
  rgdict,
  rgnode,
  rgdictlayout,
  rgio.layout,
  rgio.text;

var
  p:pointer;
  ver:integer;
begin
  p:=ParseTextFile(PChar(ParamStr(1)));
  case UpCase(ParamStr(2)) of
    'TL2': ver:=verTL2;
    'RG' : ver:=verRG;
    'RGO': ver:=verRGO;
    'HOB': ver:=verHob;
  else
    ver:=verTL2;
  end;
  BuildLayoutFile(p,'out.layout',ver);
  DeleteNode(p);
end.
