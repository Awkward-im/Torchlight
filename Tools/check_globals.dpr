uses
  sysutils,
  rgdict,
  rgglobal,
  rgnode;

var
  lnode,snode,node:pointer;
  pcw:PWideChar;
  ls,ls1:WideString;
  shash,dhash:dword;
  j,i,lcnt:integer;
begin
  node:=ParseDatFile('GLOBALS.DAT.TXT');

  snode:=GetChild(node,0);
  for i:=0 to GetChildCount(snode)-1 do
  begin
    lnode:=GetChild(snode,i);
    pcw:=GetNodeName(lnode);
    if Char(pcw[0]) in ['0'..'9'] then
    begin
      shash:=dword(StrToInt64(WideString(pcw)));
      pcw:=AsString(lnode);
      ls1:=WideString(pcw);
      SetLength(ls,Length(ls1));
//j:=Pos('-\n',ls1);
//if j>0 then SetLength(ls1,j+2);
      lcnt:=0;
      for j:=1 to Length(ls1) do
      begin
        if Char(ls1[j]) in ['a'..'z'] then
        begin
          inc(lcnt);
          ls[lcnt]:=UpCase(ls1[j]);
        end
        else if Char(ls1[j]) in ['A'..'Z','0'..'9','-','.'] then
        begin
          inc(lcnt);
          ls[lcnt]:=ls1[j];
        end;
      end;
      if lcnt>20 then lcnt:=20;
      SetLength(ls,lcnt);
//!!!UNICODE
      dhash:=RGHash(pointer(ls),Length(ls));
      if shash<>dhash then writeln('!!',shash,':',dhash,'#',ls,'#',WideString(pcw))
      else writeln(shash,':',WideString(pcw));
    end;
  end;
  DeleteNode(node);
end.
