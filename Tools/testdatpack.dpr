uses
  rgglobal,
  rgdatpack,
  rgdict;

var
  f:file of byte;
  b:pbyte;
  i:integer;
begin
  RGTags.Import('dictionary.txt');
  i:=DoBinFromFile(ParamStr(1),b,verTL2);
  Assign(f,ParamStr(1)+'.BIN');
  Rewrite(f);
  BlockWrite(f,b^,i);
  Close(f);
  freemem(b);
end.