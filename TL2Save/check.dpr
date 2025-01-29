uses tl2save,rgdb;

var
  tr:TTL2SaveFile;
begin
  RGDBLoadBase;
  tr:=TTL2SaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.parse;
  tr.FixModdedItems;
  tr.prepare;
  tr.SaveToFile(ParamStr(1)+'.bin');
  tr.Free;
  RGDBFreeBase;
end.
