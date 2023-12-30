{$R ..\TL2Lib\dict.rc}

uses
  rgglobal,
  rgnode,
  rgdictlayout,
  rgio.layout,
  rgio.text;

var
  p:pointer;
begin
  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  p:=ParseLayoutFile(ParamStr(1));
  BuildTextFile(p,'out.txt');
  DeleteNode(p);
end.
