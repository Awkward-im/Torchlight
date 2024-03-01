uses
  sysutils,
  classes,
  rgglobal;

var
  sl:TStringList;
  i:integer;
begin
  sl:=TStringList.Create;
  sl.CaseSensitive:=true;
  sl.Sorted:=true;
  sl.LoadFromFile(ParamStr(1));
  sl.Sort;
  sl.SaveToFile('sorted.txt');
  sl.Sorted:=false;
  for i:=0 to sl.Count-1 do
  begin
    sl[i]:=IntToStr(rghashb(pchar(sl[i]),Length(sl[i])))+':'+sl[i];
  end;
  sl.Sorted:=true;
  sl.Sort;
  sl.SaveToFile('hashed.txt');
  sl.Free;
end.
