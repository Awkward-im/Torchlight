unit RGDebug;

interface

uses
  rgglobal,
  rgpak;

function DumpPAKInfo(const ainfo:TRGPAK):string;


implementation

uses
//  SysUtils,
  logging,
  rgfiletype,
  rgman
  ;

function IntToStr(Value: Longint): string;
begin
  System.Str(Value, result);
end ;

function DumpPAKInfo(const ainfo:TRGPAK):string;
var
  llog:TLog;
  p:PMANFileInfo;
  ls,llsize:string;
  i:integer;
  lpack,lfiles,lprocess,ldir:integer;
  ldat,llay:integer;
  lmaxc,lmax,lmaxp,lmaxu,lcnt:integer;
begin
  llog.Init;

  llog.Add('Root: '+String(WideString(ainfo.man.Root)));
  lfiles:=0;
  lprocess:=0;
  ldir:=0;
  lpack:=0;
  llay:=0;
  ldat:=0;
  lcnt:=ainfo.man.total;
  lmaxp:=0;
  lmaxu:=0;
  lmax :=0;
  for i:=0 to ainfo.man.EntriesCount-1 do
  begin
    if ainfo.man.IsDirDeleted(i) then continue;

    llog.Add(IntToStr(i+1)+'  Directory: '+string(WideString(ainfo.man.DirName[i])));
    if ainfo.man.GetFirstFile(p,i)<>0 then
    repeat
      dec(lcnt);
      llsize:='';
      if (p^.ftype=typeDirectory) or (p^.ftype=typeDelete) then
      begin
        inc(ldir);
        ls:='    Dir: ';
      end
      else
      begin
        inc(lfiles);
        ls:='    File: ';
        if p^.size_s=0 then llsize:='##';
      end;
      if p^.size_c>0 then inc(lpack);
      if lmaxp<p^.size_c then lmaxp:=p^.size_c;
      if lmaxu<p^.size_u then lmaxu:=p^.size_u;
      if (lmax<p^.size_u) and (p^.size_c<>0) then
      begin
        lmax :=p^.size_u;
        lmaxc:=p^.size_c;
      end;
      if p^.ftype in [typeWDat,typeDat,typeLayout,typeHie,typeAnimation] then inc(lprocess);
      if p^.ftype=typeDAT then inc(ldat);
      if p^.ftype=typeLayout then inc(llay);

      if p^.size_s<>p^.size_u then llsize:='!!';
      llog.Add(llsize+
          ls+string(widestring(ainfo.man.GetName(p^.name)))+
          '; type:'       +PAKCategoryName(p^.ftype)+
          '; source size:'+IntToStr(p^.size_s)+
          '; compr:'      +IntToStr(p^.size_c)+
          '; unpacked:'   +IntToStr(p^.size_u));
    until ainfo.man.GetNextFile(p)=0;
  end;
  llog.Add('Total: '    +IntToStr(ainfo.man.total)+
           '; childs: ' +IntToStr(ainfo.man.EntriesCount)+
           '; rest: '   +IntToStr(lcnt)+
           '; process: '+IntToStr(lprocess));
  llog.Add('Max packed size: '      +IntToStr(lmaxp)+' (0x'+HexStr(lmaxp,8)+')');
  llog.Add('Max unpacked size: '    +IntToStr(lmaxu)+' (0x'+HexStr(lmaxu,8)+')');
  llog.Add('Max uncompressed size: '+IntToStr(lmax )+' (0x'+HexStr(lmax ,8)+')');
  llog.Add('It''s compressed size: '+IntToStr(lmaxc)+' (0x'+HexStr(lmaxc,8)+')');
  llog.Add('Packed '                +IntToStr(lpack));
  llog.Add('Files '+IntToStr(lfiles));
  llog.Add('Dirs ' +IntToStr(ldir));
  llog.Add('Total '+IntToStr(lfiles+ldir+lprocess));
  llog.Add('DAT: ' +IntToStr(ldat)+'; LAYOUT: '+IntToStr(llay));

  result:=llog.Text;
  llog.Free;
end;

end.
