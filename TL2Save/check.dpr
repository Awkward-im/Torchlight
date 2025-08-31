uses tlsave,rgdb;

var
  tr:TTLSaveFile;
begin
  RGDBLoadBase;
  tr:=TTLSaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.parse;
  tr.FixModdedItems;
  tr.prepare;
  tr.SaveToFile(ParamStr(1)+'.bin');
  tr.Free;
  RGDBFreeBase;
end.
