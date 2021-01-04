{$I-}
uses
  sysutils,
  rgglobal,
  TL2Mod;

var
  ffin,ffout:file of byte;
  fname,fout:string;
  mi:TTL2ModInfo;
  ltmp:pbyte;
  lsize,fsize:integer;
begin
  if ParamCount()=0 then
  begin
    Writeln('Usage: mod2pak.exe <modname> [<pakname>]'#13#10+
            '  where <pakname> is unnecessary in form like (without quotes) "DATA0.PAK"');
    halt;
  end;

  fname:=ParamStr(1);
  if ReadModInfo(PChar(fname),mi) then
  begin
    if ParamCount()=1 then
      fout:=ChangeFileExt(fname,'.PAK')
//      fout:='DATA0.PAK'
    else
      fout:=ParamStr(2);

    Assign(ffin,fname);
    Reset(ffin);
    fsize:=FileSize(ffin);

    Assign(ffout,fout);
    Rewrite(ffout);
    Seek(ffin,mi.offData);
    lsize:=mi.offMan-mi.offData;
    GetMem    (      ltmp ,lsize);
    BlockRead (ffin ,ltmp^,lsize);
    BlockWrite(ffout,ltmp^,lsize);
    Close(ffout);

    Assign(ffout,fout+'.MAN');
    Rewrite(ffout);
    Seek(ffin,mi.offMan);
    fsize:=fsize-mi.offMan;
    if fsize>lsize then
      ReallocMem(ltmp,fsize);
    BlockRead (ffin ,ltmp^,fsize);
    BlockWrite(ffout,ltmp^,fsize);
    FreeMem(ltmp);
    Close(ffout);

    Close(ffin);
  end;

end.
