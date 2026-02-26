uses tlsave;

var
  tr:TTLSaveFile;
begin
  tr:=TTLSaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.SaveToFile(ParamStr(1)+'.bin');
  tr.Free;
end.
