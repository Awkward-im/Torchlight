{$O-}
{
man:
  hash = 0x202A (8234)
  ofs = 0
}
const
  pakLo   = 25;
  pakHi   = 75;
  pakofs  = 8;
  pakhash = 0;
  manLo   = 15;
  manHi   = 25;
  manofs  = 6;
  manhash = $202A;
const
  rndLo  = manLo;
  rndHi  = manHi;
  stoff  = manofs;
  sthash = manhash;

var
  f:file of byte;
  ofs,step:longword;
  fsize,seed:qword;
  chk:integer;
  lbyte:byte;
begin
  Assign(f,ParamStr(1));
  Reset(f);

  fsize:=FileSize(f);
  seed:=(fsize shr 32)+(fsize and $FFFFFFFF)*$29777B41;
  seed:=rndLo+((seed and $FFFFFFFF) mod (rndHi-rndLo+1));
  if seed>rndHi then seed:=rndHi;

  step:=fsize div seed;
  if step<2 then step:=2;

  ofs:=stoff;
  if sthash=0 then
    chk:=fsize
  else
    chk:=sthash;

writeln('seed=',seed,'; step=',step);

  while ofs<fsize do
  begin
    seek(f,ofs);
    BlockRead(f,lbyte,1);
    chk:=integer(((int64(chk)*33)+shortint(lbyte)) and $FFFFFFFF);
    ofs:=ofs+step;
  end;
  Seek(f,fsize-1);
  BlockRead(f,lbyte,1);
  chk:=integer(((int64(chk)*33)+shortint(lbyte )) and $FFFFFFFF);

  Close(f);

  writeln(HexStr(chk,8));
end.
