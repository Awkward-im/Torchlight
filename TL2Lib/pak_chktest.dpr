{$O-}
var
  f:file of byte;
  i:integer;
  ofs,step:longword;
  fsize,seed:qword;
  chk:integer;
  lbyte:byte;
begin
  Assign(f,ParamStr(1));
  Reset(f);
  fsize:=FileSize(f);
  seed:=(fsize shr 32)+(fsize and $FFFFFFFF)*$29777B41;
  seed:=25+((seed and $FFFFFFFF) mod 51);
  if seed>75 then seed:=75;

  step:=fsize div seed;
  if step<2 then step:=2;
  ofs:=8;
  chk:=fsize;
writeln('Seed=',seed,'; step=',step);

  while ofs<fsize do
  begin
    seek(f,ofs);
    BlockRead(f,lbyte,1);
    chk:=((chk*33)+shortint(lbyte)) and $FFFFFFFF;
    ofs:=ofs+step;
  end;
  Seek(f,fsize-1);
  BlockRead(f,lbyte,1);
  chk:=((chk*33)+shortint(lbyte {shl 24})) and $FFFFFFFF;

  Close(f);

  writeln(HexStr(chk,8));
end.
