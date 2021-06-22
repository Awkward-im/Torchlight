uses
windows,
  classes,
  sysutils,
  rgglobal,
  TL2DatNode;

var
  tags:PTL2Node;
  ls:UTF8string;
  i,j:integer;
  id:dword;
  found:boolean;

  sl:TStringList;
begin
  LoadDict;

  tags:=ParseDatFile('tags.dat');

  sl:=TStringList.Create;
  sl.DefaultEncoding:=TEncoding.UTF8;

  i:=1;
  while i<tags^.childcount do
  begin
    id:=dword(tags^.children^[i].asInteger);

    found:=false;
    for j:=0 to High(dict) do
    begin
      if id=dict[j].hash then
      begin
        found:=true;

        if not CompareWide(
          PWideChar(UTF8ToString(dict[j].name)),
          tags^.children^[i-1].asString
          ) then
        begin
          sl.Add('dict code '+IntToStr(id)+' ('+IntToStr(integer(id))+') "'+
                 dict[j].name+'" "'+String(WideString(tags^.children^[i-1].asString))+'"');
        end;
      end;
    end;
    if not found then
      sl.Add(IntToStr(id)+':'+ls);

    inc(i,2);
  end;

  sl.SaveToFile('out.txt'{,TEncoding.UTF8});
  sl.Free;

  DeleteNode(tags);
end.
