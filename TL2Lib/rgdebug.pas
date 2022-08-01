unit RGDebug;

interface

uses
  rgglobal;

function DumpPAKInfo(const ainfo:TPAKInfo):string;


implementation

uses
//  SysUtils,
  rgfiletype,
  rglogging;

function IntToStr(Value: Longint): string;
begin
 System.Str(Value, result);
end ;

function DumpPAKInfo(const ainfo:TPAKInfo):string;
var
  llog:TRGLog;
  ls,llsize:string;
  i,j:integer;
  lpack,lfiles,lprocess,ldir:integer;
  ldat,llay:integer;
  lmaxc,lmax,lmaxp,lmaxu,lcnt:integer;
begin
  llog.Init;

  llog.Add('Root: '+String(WideString(ainfo.Root)));
  lfiles:=0;
  lprocess:=0;
  ldir:=0;
  lpack:=0;
  llay:=0;
  ldat:=0;
  lcnt:=ainfo.total;
  lmaxp:=0;
  lmaxu:=0;
  lmax :=0;
  for i:=0 to High(ainfo.Entries) do
  begin
    llog.Add(IntToStr(i+1)+'  Directory: '+string(WideString(ainfo.Entries[i].name)));
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      dec(lcnt);
      with ainfo.Entries[i].Files[j] do
      begin
        llsize:='';
        if (ftype=typeDirectory) or (ftype=typeDelete) then
        begin
          inc(ldir);
          ls:='    Dir: ';
        end
        else
        begin
          inc(lfiles);
          ls:='    File: ';
          if size_s=0 then llsize:='##';
        end;
        if size_c>0 then inc(lpack);
        if lmaxp<size_c then lmaxp:=size_c;
        if lmaxu<size_u then lmaxu:=size_u;
        if (lmax <size_u) and (size_c<>0) then
        begin
          lmax :=size_u;
          lmaxc:=size_c;
        end;
        if ftype in [typeWDat,typeDat,typeLayout,typeHie,typeAnimation] then inc(lprocess);
        if ftype=typedat then inc(ldat);
        if ftype=typelayout then inc(llay);

        if size_s<>size_u then llsize:='!!';
        llog.Add(llsize+
            ls+string(widestring(name))+
            '; type:'       +PAKCategoryName(ftype)+
            '; source size:'+IntToStr(size_s)+
            '; compr:'      +IntToStr(size_c)+
            '; unpacked:'   +IntToStr(size_u));
      end;
    end;
  end;
  llog.Add('Total: '    +IntToStr(ainfo.total)+
           '; childs: ' +IntToStr(Length(ainfo.Entries))+
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
