uses
  TL2DatNode;

var
  p,pp,ppp:PTL2Node;
  i,j:integer;
begin
  p:=ParseDatFile(PChar(paramstr(1)));
  for i:=0 to p^.childcount-1 do
  begin
    pp:=@(p^.children^[i]);
    for j:=pp^.childcount-1 downto 0 do
    begin
      if (pp^.children^[j].name='FILE') or (pp^.children^[j].name='PROPERTY') then
      begin
        ppp:=@(pp^.children^[j]);
        DeleteNode(ppp);
      end;
    end;
  end;
  WriteDatTree(p,'out.dat');
  DeleteNode(p);
end.
  