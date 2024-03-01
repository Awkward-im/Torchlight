uses classes;
var
  sl:TStringList;
begin
  sl:=TStringList.Create;
  sl.Sorted:=true;
  sl.LoadFromFile(ParamStr(1));
  sl.Sort;
  sl.SaveToFile('sorted.txt');
  sl.Free;
end.