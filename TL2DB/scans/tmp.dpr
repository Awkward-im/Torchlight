uses
  TL2DatNode;
var
  p:PTL2Node;
  ls,lls:string;
  i:integer;
begin
  p:=parsedatfile('FAMEGATE.DAT');

  ls:='';
  for i:=0 to p^.childcount-1 do
  begin
    if p^.children^[i].nodeType=ntGroup then
    begin
      Str(p^.children^[i].children^[1].asFloat:0:4,lls);
      ls:=ls+lls+',';
    end;
  end;
  DeleteNode(p);
  writeln(ls);
end.
