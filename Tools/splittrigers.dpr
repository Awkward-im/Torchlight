uses sysutils,rgglobal;

type
  TTL2Trigger = packed record
    flags1   :array [0..3] of Byte;
    flags2   :array [0..3] of Byte;
    f1      :TRGFloat; // 0x08
    f2      :TRGFloat; // 0x0C
    f3      :TRGFloat; // 0x10
    f4      :TRGFloat; // 0x14
    // fixed size block
    // real name finished by #00
    atype   :array [0..21] of WideChar; // 0x18
    // 0x34
{
    valf1   :RGFloat; // 0x34
    valf2   :RGFloat; // 0x38
    valf3   :RGFloat; // 0x3C
    valf_1  :RGFloat; // 0x40 maybe not
}
    // 0x44
    val_f1  :TRGFloat; // 0x44
    val_f2  :TRGFloat; // 0x48
    val_f3  :TRGFloat; // 0x4C
    val1_f1 :TRGFloat; // 0x50
    val1_f2 :TRGFloat; // 0x54
    val1_f3 :TRGFloat; // 0x58
    val1_f4 :TRGFloat; // 0x5C
    parentid:TRGID;    // 0x60
    unknown :TRGID;    // 0x68
    id      :TRGID;    // 0x70
    posx    :TRGFloat; // 0x78
    posy    :TRGFloat; // 0x7C
    posz    :TRGFloat; // 0x80
    val_i1  :Word;    // 0x84
    val_i2  :Word;    // 0x86
  end;

var
  f:file of byte;
  ls:string;
  i,j:integer;
  b:array of TTL2Trigger;
begin
  Assign(f,ParamStr(1));
  Reset(f);
  if IOResult=0 then
  begin
    BlockRead(f,i,4);
    SetLength(b,i);
    if i>0 then
    begin
      BlockRead(f,b[0],i*SizeOf(TTL2Trigger));
      ls:=ExtractNameOnly(ParamStr(1));
      MkDir(ls);
    end;
    Close(f);
    while i>0 do
    begin
      dec(i);
      Assign(f,ls+'\'+IntToStr(i)+'_'+FastWideToStr(@b[i].atype)+'.trg');
      Rewrite(f);
      if ParamCount=1 then
        BlockWrite(f,b[i],SizeOf(TTL2Trigger))
      else
      begin
        j:=Length(PWideChar(@b[i].atype));
        BlockWrite(f,j,2);
        BlockWrite(f,b[i].atype,(j+1)*2);
        BlockWrite(f,b[i].val_f1,61);
      end;
      Close(f);
    end;
  end;
end.
