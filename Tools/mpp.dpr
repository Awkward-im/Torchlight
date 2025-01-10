uses classes;
var
  st:tMemoryStream;
  x,y,i,j:integer;
  f1,f2,f3,f4:single;
  b:byte;
begin
  st:=TMemoryStream.Create;
  st.LoadFromFile(ParamStr(1));
  x:=st.ReadDWord;
  y:=st.ReadDWord;
  st.ReadData(f1);
  st.ReadData(f2);
  st.ReadData(f3);
  st.ReadData(f4);
  writeln('x=',x,'; y=',y);
  writeln('F1=',f1:6:2);
  writeln('F2=',f2:6:2);
  writeln('F3=',f3:6:2);
  writeln('F4=',f4:6:2);
  for j:=0 to y-1 do
  begin
    for i:=0 to x-1 do
    begin
      b:=st.ReadByte();
      if b=255 then write('#');
      if b=0 then write(' ');
      if b=1 then write('+');
//      write(CHR(b));
    end;
    writeln;
  end;
  st.Free;
end.