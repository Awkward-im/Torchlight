uses
  classes,
  sysutils,
  rgglobal;

var
  f:file of byte;
  sl:TStringList;
  buf,lp:pByte;
  ls:string;
  i,lsize:integer;
begin
  Assign(f,ParamStr(1));
  Reset(f);
  lsize:=FileSize(f);
  GetMem(buf,lsize);
  BlockRead(f,buf^,lsize);
  Close(f);
  sl:=TStringList.Create;

  lp:=buf;
  repeat
    while (lp^=0) and (lp<(buf+lsize)) do inc(lp);
    if lp>=(buf+lsize) then break;
    if (lp+1)^=0 then
    // wide
    begin
      sl.Add(String(WideString(PWideChar(lp))));
      inc(lp,(Length(PWideChar(lp))+1)*2);
    end
    else
    begin
      sl.Add(PAnsiChar(lp));
      inc(lp,Length(PAnsiChar(lp))+1);
    end;
  until false;

  sl.SaveToFile('outstr.txt');
  sl.Sort;
  for i:=0 to sl.Count-1 do
  begin
    ls:=sl[i];
    if ls<>'' then
      sl[i]:=IntToStr(RGHash(PChar(ls),Length(ls)))+':'+ls;
  end;
  sl.SaveToFile('outhash.txt');

  FreeMem(buf);
  sl.Free;
end.
