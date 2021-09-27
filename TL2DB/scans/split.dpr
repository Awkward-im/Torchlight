var
  fin,fout:file of byte;
  ls:string;
  cnt,i:integer;
  buf:array [0..135] of byte;
begin
  AssignFile(fin,ParamStr(1));
  Reset(fin);
  BlockRead(fin,cnt,4);
  for i:=0 to cnt-1 do
  begin
    BlockRead(fin,buf,136);
    ls:=string(widestring(PWideChar(pointer(@buf[24]))));
    AssignFile(fout,'trigger_'+ls+'_'+HexStr(i,4)+'.dmp');
    Rewrite(fout);
    BlockWrite(fout,buf,136);
    CloseFile(fout);
  end;
  CloseFile(fin);
end.
