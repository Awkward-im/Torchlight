uses
  rgglobal,
  rgnode,
  rgio.text;

var
  p,p1,p2:pointer;
  ls1,ls2:WideString;
  i:integer;
begin
  p:=ParseTextFile(PChar(ParamStr(1)));
  if p<>nil then
  begin
    p1:=GetChild(p,1);
    for i:=0 to GetChildCount(p1) do
    begin
      p2:=GetChild(p1,i);
      Str(AsInteger(FindNode(p2,'ID')),ls1);
      ls2:=AsString (FindNode(p2,'NAME'));
      writeln(ls1,',',ls2);
    end;
  end;
  DeleteNode(p);
end.
