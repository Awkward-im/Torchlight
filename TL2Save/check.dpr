uses tl2save,tl2db;

var
  tr:TTL2SaveFile;
begin
  LoadBases;
  tr:=TTL2SaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.parse;
  tr.FixModdedItems;
  tr.prepare;
  tr.SaveToFile(ParamStr(1)+'.bin');
  tr.Free;
  FreeBases;
end.
