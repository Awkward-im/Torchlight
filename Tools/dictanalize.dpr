{$R ..\TL2Lib\dicttag.rc}
uses
  rgdict;

var
  i,j:integer;
  cnt:array [' '..'z'] of integer;
  c:Char;
begin
  RGTags.Import('RGDICT','TEXT');
  FillChar(cnt,SizeOf(cnt),0);
  for i:=0 to RGTags.Count-1 do
  begin
    for j:=0 to Length(RGTags.Tags[i])-1 do
    begin
      c:=AnsiChar(RGTags.Tags[i][j]);
      if c in [' '..'z'] then
        inc(cnt[c]);
    end;
  end;
  for c:=' ' to 'z' do
    writeln(c,#9,cnt[c]);

end.