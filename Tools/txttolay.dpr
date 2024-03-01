{$R ..\TL2Lib\dict.rc}

uses
  rgglobal,
  rgnode,
  rgdictlayout,
  rgio.layout,
  rgio.text;

var
  p:pointer;
  ver:integer;
begin
  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

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
