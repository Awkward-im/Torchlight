uses
  dict,
  rgdict;

var
  f:file of byte;
  b:pbyte;
  d:tTransDict;
  i:integer;
begin
//  d.Init;
//  LoadTranslation(d,ParamStr(1));
  rgtags.Options:=[check_hash];
  rgtags.import(ParamStr(1));
{
  Assign(f,ParamStr(1));
  Reset(f);
  i:=FileSize(f);
  GetMem(b,i+2);
  BlockRead(f,b^,i);
  b[i  ]:=0;
  b[i+1]:=0;
  DictLoadTags(d,b);
  FreeMem(b);
  Close(f);
}
//  d.SortBy(1);
rgtags.export('out.dat',astext);
{
  for i:=0 to d.Count-1 do
    Writeln(d.Hashes[i],' : ',WideString(d.Tags[i]));
}
{
  d.SortBy(3);
  for i:=0 to d.Count-1 do
    Writeln(WideString(d.Tags[i]),#13#10,WideString(d.Values[i]));
}
//  d.Clear;
end.