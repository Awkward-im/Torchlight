uses
  rgfile;

var
  f:file of byte;
  i:integer;
  bin,bout:PByte;
begin
  Assign(f,ParamStr(1));
  Reset(f);
  if IOResult=0 then
  begin
    i:=FileSize(f);
    GetMem(bin,i);
    bout:=nil;
    BlockRead(f,bin^,i);
    Close(f);
    i:=RGFileUnpackBufSafe(bin,i,bout);
    if i>0 then
    begin
      Assign(f,ParamStr(1)+'.out');
      Rewrite(f);
      if IOResult=0 then
      begin
	      BlockWrite(f,bout^,i);
        Close(f);
      end;
    end;
    FreeMem(bin);
    FreeMem(bout);
  end;
end.
