uses tl2save;

var
  tr:TTL2SaveFile;
begin
  tr:=TTL2SaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.SaveToFile(ParamStr(1)+'.bin');
  tr.Free;
end.
