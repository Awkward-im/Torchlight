{$I-}
uses
  classes,
  rgglobal,
  rgpak;

var
  ffin,ffpak,ffman:file of byte;
  fout:string;
  lpak:TPAKInfo;
  ltmp:pbyte;
begin
  if ParamCount()=0 then
  begin
    Writeln('Usage: mod2pak.exe <modname> [<pakname>]'#13#10+
            '  where <pakname> is unnecessary in form like (without quotes) "DATA0.PAK"');
    halt;
  end;

  if GetPAKInfo(ParamStr(1),lpak) then
  begin
    if lpak.ver=verTL2Mod then
    begin
      if ParamCount()=1 then
        fout:='DATA0.PAK'
      else
        fout:=ParamStr(2);

      Assign(ffin,ParamStr(1));
      Reset(ffin);

      Assign(ffpak,fout);
      Rewrite(ffpak);
      Seek(ffin,lpak.data);
      GetMem    (      ltmp ,lpak.man-lpak.data);
      BlockRead (ffin ,ltmp^,lpak.man-lpak.data);
      BlockWrite(ffpak,ltmp^,lpak.man-lpak.data);
      FreeMem(ltmp);
      Close(ffpak);

      Assign(ffman,fout+'.MAN');
      Rewrite(ffman);
      Seek(ffin,lpak.man);
      GetMem    (      ltmp ,lpak.fsize-lpak.man);
      BlockRead (ffin ,ltmp^,lpak.fsize-lpak.man);
      BlockWrite(ffman,ltmp^,lpak.fsize-lpak.man);
      FreeMem(ltmp);
      Close(ffman);

      Close(ffin);
    end;
  end;

end.