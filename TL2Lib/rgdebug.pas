unit RGDebug;

interface

uses
  rgglobal,
  rgman,
  rgpak;

function DumpPAKInfo(const ainfo:TRGPAK):string;

function ParseMANMem(const aman:TRGManifest; afull:boolean=false):pointer;
//  Manifest to text file (DAT format)
procedure MANtoFile(const fname:string; const aman:TRGManifest; afull:boolean=false);
//  Text file (DAT format) to manifest
procedure FileToMAN(const fname:string; out aman:TRGManifest);


implementation

uses
//  SysUtils,
  logging,
  rgfiletype,
  rgNode,
  rgIO.Text
  ;

function IntToStr(Value: Longint): string;
begin
  System.Str(Value, result);
end ;

function DumpPAKInfo(const ainfo:TRGPAK):string;
var
  llog:TLog;
  p:PManFileInfo;
  ls,llsize:string;
  i:integer;
  lpack,lfiles,lprocess,ldir:integer;
  ldat,llay:integer;
  lmaxc,lmax,lmaxp,lmaxu,lcnt:integer;
begin
  llog.Init;

  llog.Add('Root: '+FastWideToStr(ainfo.man.Root));
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
  for i:=0 to ainfo.man.DirCount-1 do
  begin
    if ainfo.man.IsDirDeleted(i) then continue;

    llog.Add(IntToStr(i+1)+'  Directory: '+FastWideToStr(ainfo.man.Dirs[i].name));
    if ainfo.man.GetFirstFile(p,i)<>0 then
    repeat
      dec(lcnt);
      llsize:='';
      if (p^.ftype=typeDirectory) then
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
      if (p^.ftype=typeData) or (p^.ftype=typeLayout) then inc(lprocess);
      if p^.ftype=typeData   then inc(ldat);
      if p^.ftype=typeLayout then inc(llay);

      if p^.size_s<>p^.size_u then llsize:='!!';
      llog.Add(llsize+
          ls+FastWideToStr(p^.name)+
          '; type:'       +RGTypeGroupName(p^.ftype)+
          '; source size:'+IntToStr(p^.size_s)+
          '; compr:'      +IntToStr(p^.size_c)+
          '; unpacked:'   +IntToStr(p^.size_u));
    until ainfo.man.GetNextFile(p)=0;
  end;
  llog.Add('Total: '    +IntToStr(ainfo.man.total)+
           '; childs: ' +IntToStr(ainfo.man.DirCount)+
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

function ParseMANMem(const aman:TRGManifest; afull:boolean=false):pointer;
var
  p:PManFileInfo;
  lman,lp,lc:pointer;
  i:integer;
begin
  lman:=nil;

  lman:=AddGroup(nil,'MANIFEST');
//??  AddString (lman,'FILE' ,PUnicodeChar(ainfo.fname));
  if afull then
  begin
    AddInteger(lman,'TOTAL',aman.total);
    AddInteger(lman,'COUNT',aman.DirCount);
  end;

  for i:=0 to aman.DirCount-1 do
  begin
    if aman.IsDirDeleted(i) then continue;

    lp:=AddGroup(lman,'FOLDER');
    AddString (lp,'NAME' ,aman.Dirs[i].name);
    if afull then
      AddInteger(lp,'COUNT',aman.Dirs[i].count);
    lp:=AddGroup(lp,'CHILDREN');


    if aman.GetFirstFile(p,i)<>0 then
    repeat
      lc:=AddGroup(lp,'CHILD');
      with p^ do
      begin
        AddString (lc,'NAME',Name);
        // "COMMON" type output, not "REAL" coz no version in MAN, in PAK only
        AddInteger(lc,'TYPE',ftype);  // required for TL2 type 18 (dir to delete)
        AddInteger(lc,'SIZE',size_s); // required for zero-size files (file to delete)
        if afull then
        begin
          AddInteger (lc,'BIN'   ,size_u);
          AddInteger (lc,'PACKED',size_c);
          AddUnsigned(lc,'CRC'   ,checksum);
          AddInteger (lc,'OFFSET',offset);
//          if ABS(ainfo.ver)=verTL2 then
          if ftime<>0 then
            AddInteger64(lc,'TIME',ftime);
        end;
      end;
   until aman.GetNextFile(p)=0
  end;

  result:=lman;
end;

procedure MANtoFile(const fname:string; const aman:TRGManifest; afull:boolean=false);
var
  lman:pointer;
begin
  lman:=ParseMANMem(aman, afull);
  if lman<>nil then
  begin
    BuildTextFile(lman,PChar(fname));
    DeleteNode(lman);
  end;
end;

procedure FileToMAN(const fname:string; out aman:TRGManifest);
var
  lman,lp,lg,lc:pointer;
  i,j,k,lentry,lcnt:integer;
begin
  lman:=ParseTextFile(PChar(fname));
  if lman<>nil then
  begin
    if IsNodeName(lman,'MANIFEST') then
    begin

      for i:=0 to GetChildCount(lman)-1 do
      begin
        lc:=GetChild(lman,i);
        case GetNodeType(lc) of
          rgString: begin
//            if IsNodeName(lc,'FILE') then ainfo.fname:=AsString(lc);
          end;

          rgInteger: begin
            if IsNodeName(lc,'TOTAL') then aman.total:=AsInteger(lc);
            if IsNodeName(lc,'COUNT') then aman.DirCapacity:=AsInteger(lc);
          end;

          rgGroup: begin
            if IsNodeName(lc,'FOLDER') then
            begin
              if aman.DirCapacity=0 then
                aman.DirCapacity:=GetGroupCount(lc);

              // folders
              for j:=0 to GetChildCount(lc)-1 do
              begin
                lentry:=aman.AddPath(AsString(FindNode(lc,'NAME')));
                lcnt:=AsInteger(FindNode(lc,'COUNT'));
                if lcnt>0 then
                  aman.FileCapacity:=aman.FileCount+lcnt;

                lp:=FindNode(lc,'CHILDREN');
                if lp<>nil then
                begin
{
                  if Length(aman.Entries[j].Files)=0 then
                    SetLength(aman.Entries[j].Files,GetGroupCount(lp));
}
                  // children
                  for k:=0 to GetChildCount(lp)-1 do
                  begin
                    lg:=GetChild(lp,k);
                    if (GetNodeType(lg)=rgGroup) and
                       (IsNodeName(lg,'CHILD')) then
                    begin
                      with PManFileInfo(aman.Files[aman.AddFile(lentry,nil)])^ do
                      begin
                        name    :=AsString   (FindNode(lg,'NAME'  ));
                        ftype   :=AsInteger  (FindNode(lg,'TYPE'  ));
                        size_s  :=AsInteger  (FindNode(lg,'SIZE'  ));
                        offset  :=AsInteger  (FindNode(lg,'OFFSET'));
                        checksum:=AsUnsigned (FindNode(lg,'CRC'   ));
                        ftime   :=AsInteger64(FindNode(lg,'TIME'  ));
                      end;

                    end;
                  end; // children

                end;
              end; // folders

            end;
          end;

        end;

      end;
    end;

    DeleteNode(lman);
  end;
end;

end.
