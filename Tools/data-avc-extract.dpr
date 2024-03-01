uses
  classes;

var
  f:File Of Byte;
  sl:TStringList;
  lstr:array [0..127] of AnsiChar;
  buf,lptr:PByte;
  lsize,i:integer;
begin
  buf:=nil;
  Assign(f,ParamStr(1));
  Reset(f);
  if IOResult=0 then
  begin
    lsize:=FileSize(f);
    GetMem(buf,lsize);
    BlockRead(f,buf^,lsize);
    Close(f);
  end;
  if buf<>nil then
  begin
    lptr:=buf;
    sl:=TStringList.Create;
    sl.Sorted:=true;
    while (lptr-buf)<lsize do
    begin
      if (lptr[0]=ORD('?')) and (lptr[1]=ORD('A')) and
         (lptr[2]=ORD('V')) and (lptr[3]=ORD('C')) then
      begin
        inc(lptr,3);
        i:=0;
        while (lptr^<>0) and (lptr^<>ORD('@')) do
        begin
          lstr[i]:=AnsiChar(lptr^);
          inc(i);
          inc(lptr);
        end;
        lstr[i]:=#0;
        sl.Add(lstr);
      end;
      inc(lptr);
    end;

    sl.Sort;
    sl.SaveToFile('data-out.txt');
    sl.Free;
    FreeMem(buf);
  end;
end.