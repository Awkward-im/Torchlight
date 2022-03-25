{
  Export to text form
  Import from text form
  Build recursively
  Parse Binary
  Build Binary
  Search file
  Add file(s)/dir(s)
  ??Delete files(s)/dir(s)
  mark as deleted
}
{%TODO finish FileToMan}
{%TODO finish CycleDir (BuildManifest)}

unit RGMan;

interface

uses
  Classes,
  rgglobal;

function BuildManifest(const adir:string; out ainfo:TPAKInfo):integer;

{
  Parse Manifest from memory block addressed by aptr
}
procedure ParseManifest(var ainfo:TPAKInfo; aptr:PByte);
{
  Save Manifest (binary data) to stream
}
function ManSaveToStream(ast:TStream; const ainfo:TPAKInfo):integer;
{
  Save Manifest (binary data) to .PAK.MAN file (name in PAKInfo)
}
function  WriteManifest(const ainfo:TPAKInfo):integer;

{
  Manifest to text file (DAT format)
}
procedure MANtoFile(const fname:string; const ainfo:TPAKInfo; afull:boolean=false);
{
  Text file (DAT format) to manifest
  Status: undone
}
procedure FileToMAN(const fname:string; out ainfo:TPAKInfo);

{
  Search single file record
}
function SearchFile(const ainfo:TPAKInfo; const fname:string):PMANFileInfo;
function SearchFile(const ainfo:TPAKInfo; apath,aname:PWideChar):PMANFileInfo;


implementation

uses
  sysutils,
  rgstream,
  rgmemory,
  rglogging,
  rgnode,
  rgio.text,
  rgfiletype;

{
  Parse Manifest from memory block addressed by aptr
}
procedure ParseManifest(var ainfo:TPAKInfo; aptr:PByte);
var
  i,j:integer;
  ltotal,lcnt:integer;
begin
  case ainfo.ver of
    verTL2Mod,
    verTL2:begin
      i:=memReadWord(aptr);                    // 0002 version/signature
      if i>=2 then                             // 0000 - no "checksum" field??
        memReadDWord(aptr);                    // checksum?
      ainfo.root:=memReadShortString(aptr);    // root directory !!
    end;

    verHob,
    verRGO,
    verRG :begin
    end;

  else
    exit;
  end;

  ainfo.total:=memReadDWord(aptr);             // total directory records
  SetLength(ainfo.Entries,memReadDWord(aptr)); // entries
  ltotal:=0;

{!!!!!!!!
  1 record - empty name, children - 'MEDIA/'
  next  - entries for files   like 'MEDIA/SKILLS.RAW'
  after - entried for folders like 'MEDIA/UNITS/'
!!!!!!!!}
  for i:=0 to High(ainfo.Entries) do
  begin
    ainfo.Entries[i].name:=memReadShortString(aptr);
    lcnt:=memReadDWord(aptr);
    SetLength(ainfo.Entries[i].Files,lcnt);
    inc(ltotal,lcnt);

    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      with ainfo.Entries[i].Files[j] do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=PAKTypeRealToCommon(memReadByte(aptr),ainfo.ver);
        name    :=memReadShortString(aptr);
        offset  :=memReadDWord(aptr);
        size_s  :=memReadDWord(aptr);
        if (ainfo.ver=verTL2) or (ainfo.ver=verTL2Mod) then
        begin
          ftime:=QWord(memReadInteger64(aptr));
        end;
      end;
    end;
  end;

//  ainfo.total:=ltotal; //!!!! keep real children count
end;

{$PUSH}
{$I-}
function ManSaveToStream(ast:TStream; const ainfo:TPAKInfo):integer;
var
  lpos:integer;
  i,j:integer;
begin
  try
    lpos:=ast.Position;

    case ainfo.ver of
      verTL2Mod,
      verTL2: begin
        ast.WriteWord(2);  // writing always "new" version
        ast.WriteDWord(0); //!! Hash
        ast.WriteShortString(ainfo.root);
      end;

      verHob,
      verRGO,
      verRG: begin
      end;
    else
      exit(0);
    end;

    ast.WriteDWord(ainfo.total);
    ast.WriteDWord(Length(ainfo.Entries));

    for i:=0 to High(ainfo.Entries) do
    begin
      ast.WriteShortString (ainfo.Entries[i].name);
      ast.WriteDWord(Length(ainfo.Entries[i].Files));

      for j:=0 to High(ainfo.Entries[i].Files) do
      begin
        with ainfo.Entries[i].Files[j] do
        begin
          ast.WriteDWord(checksum);
          ast.WriteByte(PAKTypeCommonToReal(ftype,ainfo.ver));
          ast.WriteShortString(name);
          ast.WriteDWord(offset);
          ast.WriteDWord(size_s);
          if (ainfo.ver=verTL2) or
             (ainfo.ver=verTL2Mod) then
            ast.WriteQWord(ftime);
        end;
      end;
    end;

    result:=ainfo.total;

  except
    result:=0;
    try
      ast.Position:=lpos;
    except
    end;
  end;
end;
{$POP}

function WriteManifest(const ainfo:TPAKInfo):integer;
var
  lst:TMemoryStream;
begin
  result:=0;

  lst:=TMemoryStream.Create;
  try
    result:=ManSaveToStream(lst,ainfo);
    if result>0 then
      lst.SaveToFile(PWideChar(ainfo.fname+'.PAK.MAN'));
  finally
    lst.Free;
  end;
end;

{
  Build files tree [from MEDIA folder] [from dir]
  excluding PNG if DDS presents
  [excluding data sources]
  as is, bin+src (data cmp to choose), bin, src
}
procedure CycleDir(const adir:string; asl:TStringList);
var
  sr:TSearchRec;
  lname:AnsiString;
  i,
  lstart,lend,l,ldir,lpng,ldds:integer;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    lpng:=0; // amount of PNG files  in current directory
    ldds:=0; // amount of DDS files  in current directory
    ldir:=0; // amount of subfolders in current directory
    lstart:=asl.Count; // starting index (if single array used)

    repeat
      lname:=adir+'\'+sr.Name;
{
   Вырезание исходного пути
   Преобразование в заглавное
}
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
{
   замена "\" на "/"
   в конце "/"
   счётчик
}

//!!!!          CycleDir(lname)

          asl.Add(sr.Name+'/'); //!!!! remove asset dir
          inc(ldir);
        end;
      end
      else
      begin
{
  счётчик PNG, DDS
  сразу тип по расширению?
  запоминание времени и размера
}
        l:=Length(sr.Name);
        if l>4 then
          if (sr.Name[l-4]='.') then
          begin
            if (sr.Name[l-3] in ['P','p']) and
               (sr.Name[l-2] in ['N','n']) and
               (sr.Name[l-1] in ['G','g']) then inc(lpng);
            {
            begin
              if FileExists(ReplaceExt(sr.Name,'.DDS') then continue;
            end;
            }

            if (sr.Name[l-3] in ['D','d']) and
               (sr.Name[l-2] in ['D','d']) and
               (sr.Name[l-1] in ['S','s']) then inc(ldds);
          end;

         //!!!! remove asset dir
        asl.AddObject(adir+sr.Name+'='+IntToStr(sr.Time),TObject(UIntPtr(sr.Size)));
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
    lend:=asl.Count; // after last index (if single array used)
{
    //!! remove PNG if DDS found
    if (lpng>0) and (ldds>0) then
    begin
      for i:=lstart to lend-1 do
      begin
        if Pos('.PNG=') then
        begin
          if Pos('.DDS=') then
          begin

            dec(ldds);
            if ldds=0 then break;
          end;
          
          dec(lpng);
          if lpng=0 then break;
        end;
      end;
    end;
}

    if ldir>0 then
    begin
      for i:=lstart to lend-1 do
      begin
        if asl[i][Length(asl[i])]='/' then
        begin
          CycleDir(adir+asl[i],asl);
          dec(ldir);
          if ldir=0 then break;
        end;
      end;  
    end;

  end;
end;

function BuildManifest(const adir:string; out ainfo:TPAKInfo):integer;
var
  sl:TStringList;
  ls:string;
  i,j:integer;
begin
  result:=0;

  sl:=TStringList.Create;
  CycleDir(adir,sl);
  for i:=0 to sl.Count-1 do
  begin
    ls:=sl[i];
    for j:=1 to Length(ls) do
    begin
      if      ls[j]='\' then ls[j]:='/'
      else if ls[j]='=' then break
      else    ls[j]:=UpCase(ls[j]);
    end;
    sl[i]:=ls;
  end;
  sl.Sorted:=true;
  sl.Sort;

{$IFDEF DEBUG}
  for i:=0 to sl.Count-1 do
  begin
    RGLog.Add(sl[i]);
  end;
  RGLog.SaveToFile('log.txt');
{$ENDIF}

  sl.Free;
end;

procedure MANtoFile(const fname:string; const ainfo:TPAKInfo; afull:boolean=false);
var
  lman,lp,lc:pointer;
  i,j:integer;
begin
  lman:=nil;

  lman:=AddGroup(nil,'MANIFEST');
  AddString (lman,'FILE' ,PWideChar(WideString(ainfo.fname)));
  if afull then
  begin
    AddInteger(lman,'TOTAL',ainfo.total);
    AddInteger(lman,'COUNT',Length(ainfo.Entries));
  end;

  for i:=0 to High(ainfo.Entries) do
  begin
    lp:=AddGroup(lman,'FOLDER');
    AddString (lp,'NAME' ,ainfo.Entries[i].name);
    if afull then
      AddInteger(lp,'COUNT',Length(ainfo.Entries[i].Files));
    lp:=AddGroup(lp,'CHILDREN');
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      lc:=AddGroup(lp,'CHILD');
      with ainfo.Entries[i].Files[j] do
      begin
        AddString (lc,'NAME',name);
        AddInteger(lc,'TYPE',ftype);  // required for TL2 type 18 (dir to delete)
        AddInteger(lc,'SIZE',size_s); // required for zero-size files (file to delete)
        if afull then
        begin
          AddUnsigned(lc,'CRC'   ,checksum);
          AddInteger (lc,'OFFSET',offset);
          if ABS(ainfo.ver)=verTL2 then
            AddInteger64(lc,'TIME',ftime);
        end;
      end;
    end;
  end;

  BuildTextFile(lman,PChar(fname));
  DeleteNode(lman);
end;

procedure FileToMAN(const fname:string; out ainfo:TPAKInfo);
var
  lman,lp,lg,lc:pointer;
  i,j,k:integer;
//  l:integer;
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
            if IsNodeName(lc,'FILE') then
            ;
          end;

          rgInteger: begin
            if IsNodeName(lc,'TOTAL') then
            ;
            if IsNodeName(lc,'COUNT') then
            ;
          end;

          rgGroup: begin
            if IsNodeName(lc,'FOLDER') then
            begin
              for j:=0 to GetChildCount(lc)-1 do
              begin
                lp:=GetChild(lc,j);
                case GetNodeType(lp) of
                  rgString: begin
                    if IsNodeName(lc,'NAME') then
                    ;
                  end;

                  rgInteger: begin
                    if IsNodeName(lc,'COUNT') then
                    ;
                  end;

                  rgGroup: begin
                    if IsNodeName(lc,'CHILDREN') then
                    begin
                      for k:=0 to GetChildCount(lp)-1 do
                      begin
                        lg:=GetChild(lp,k);
                        if (GetNodeType(lg)=rgGroup) and
                           (IsNodeName(lg,'CHILD')) then
                        begin

                          // name for file
                          // type for dir
                          // size for "deleted"
{
                          case GetNodeType(lg) of
                            rgString: begin
                            end;

                            rgInteger: begin
                            end;
                            rgUnsigned: ;
                            rgInteger64:;
                          end;
}                        
                        end;
                      end;
                    end;
                  end;

                end;

              end;
            end;
          end;

        end;

      end;
    end;

    DeleteNode(lman);
  end;
end;

//----- Search -----

function SearchFile(const ainfo:TPAKInfo; apath,aname:PWideChar):PMANFileInfo;
var
  lentry:PMANDirEntry;
  i,j:integer;
begin
  for i:=0 to High(ainfo.Entries) do
  begin
    lentry:=@(ainfo.Entries[i]);

    if CompareWide(lentry^.name,apath)=0 then
    begin
      for j:=0 to High(lentry^.Files) do
      begin
        if CompareWide(lentry^.Files[j].name,aname)=0 then
        begin
          exit(@(lentry^.Files[j]));
        end;
      end;

      break;
    end;
  end;

  result:=nil;
end;

function SearchFile(const ainfo:TPAKInfo; const fname:string):PMANFileInfo;
var
  lpath,lname:WideString;
begin
  lname:=UpCase(WideString(fname));
  lpath:=ExtractFilePath(lname);
  lname:=ExtractFileName(lname);

  result:=SearchFile(ainfo,pointer(lpath),pointer(lname));
end;

end.
