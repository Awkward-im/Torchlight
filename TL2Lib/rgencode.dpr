{$R ..\TL2Lib\dict.rc}

uses
  rgdict,
  rgnode,
  rgglobal,
  rgio.text,
  rgio.layout;

var
  p0,p1:pointer;
  f:file of byte;
  lsize:integer;
begin
  RGTags.Import('RGDICT','TEXT');
  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  
  p0:=ParseTextFile(PChar(ParamStr(1)));
  lsize:=BuildLayoutMem(p0,p1,verTL2);
  DeleteNode(p0);
  Assign(f,'out.layout');
  Rewrite(f);
  BlockWrite(f,p1^,lsize);
  Close(f);
  FreeMem(p1);
end.
