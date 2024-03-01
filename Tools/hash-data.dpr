uses classes, rgglobal, sysutils;
var
  sl:TStringList;
  i:integer;
begin
  sl:=TStringList.Create;
//  sl.Sorted:=true;
  sl.LoadFromFile(ParamStr(1));
  for i:=0 to sl.Count-1 do
  begin
    sl[i]:=sl[i]+','+IntToStr(DWord(RGHashB(PAnsiChar(sl[i]))));
  end;
  sl.SaveToFile('hashed.txt');
  sl.Free;
end.