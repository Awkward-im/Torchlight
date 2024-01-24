{TODO: Add source file name to TMANFileInfo}
{TODO: add tree (dir with files)}
{TODO: rename dir}
{TODO: rename file}
{TODO: save compiled manifest size}
{TODO: calculate largest file size on parse and add. Or just on build?}
unit RGMan;

interface

uses
  Classes,
  rgfs,
  rgglobal;


type
  PMANFileInfo = ^TMANFileInfo;
  TMANFileInfo = object (TBaseFileInfo)
    ftime   :UInt64;    // MAN: TL2 only
    checksum:dword;     // MAN: CRC32
    size_s  :dword;     // ?? MAN: looks like source,not compiled, size (unusable)
    size_c  :dword;     // !! PAK: from TPAKFileHeader
    size_u  :dword;     // !! PAK: from TPAKFileHeader
    offset  :dword;     // !! MAN: PAK data block offset (??changed to "data" field)
    ftype   :byte;      // !! MAN: RGFileType unified type
//    exttype :byte;      // ?? removed files, for undo
//    hide    :ByteBool;  // ?? show or hide in lists
  end;

type
  PRGManifest = ^TRGManifest;
  TRGManifest = object (TRGDirList)
  private
    FLUnpacked:integer; // largest unpacked file size
    FLPacked  :integer; // largest   packed file size
    FPath:string; // disk path for unpacked files
  public
    Deleted:TDirEntries;
  public
    // not necessary fields
    root   :PUnicodeChar;   // same as first directory, MEDIA (usually)
    reserve:integer;        // "total" records count (GUTS gives more than put)
    largest:integer;        // largest source file size
  private
    function  GetSize(idx:integer):integer;

  // Main
  public
    procedure Init;
    procedure Free;

    function Parse(aptr:PByte; aver:integer):integer;
    function Build(const adir:string):integer;

    function SaveToStream(ast:TStream; aver:integer):integer;
    function SaveToFile  (const afname:string; aver:integer):integer;

  // wrappers
    function SearchFile(aentry:integer; aname:PUnicodeChar):PMANFileInfo;
    function SearchFile(apath,aname:PUnicodeChar):PMANFileInfo;
    function SearchFile(const fname:string):PMANFileInfo;

  // Properties statistic
  public
    property LargestPacked  :integer index 0 read GetSize;
    property LargestUnpacked:integer index 1 read GetSize;
  end;


{$IFDEF DEBUG}
function ParseMANMem(const aman:TRGManifest; afull:boolean=false):pointer;
//  Manifest to text file (DAT format)
procedure MANtoFile(const fname:string; const aman:TRGManifest; afull:boolean=false);
//  Text file (DAT format) to manifest
procedure FileToMAN(const fname:string; out aman:TRGManifest);
{$ENDIF DEBUG}


implementation

uses
  sysutils,

  rwmemory,

{$IFDEF DEBUG}
  rgnode,
  rgio.text,
{$ENDIF DEBUG}
  rgstream,
  rgfiletype;

{%REGION Common}
function TRGManifest.GetSize(idx:integer):integer;
var
  i:integer;
begin
       if idx=0 then result:=FLPacked
  else if idx=1 then result:=FLUnpacked;

  if result=0 then
  begin
    for i:=0 to FileCount-1 do
    begin
      if not IsFileDeleted(i) then
      begin
        if PMANFileInfo(Files[i])^.size_c>FLPacked   then FLPacked  :=PMANFileInfo(Files[i])^.size_c;
        if PMANFileInfo(Files[i])^.size_u>FLUnpacked then FLUnpacked:=PMANFileInfo(Files[i])^.size_u;
      end;
    end;

         if idx=0 then result:=FLPacked
    else if idx=1 then result:=FLUnpacked;
  end;
end;

procedure TRGManifest.Init;
begin
  inherited Init(SizeOf(TMANFileInfo));
end;

procedure TRGManifest.Free;
begin
  FreeMem(root);

  Finalize(Deleted);

  inherited Free;
end;
{%ENDREGION}

{%REGION Wrappers}
function TRGManifest.SearchFile(aentry:integer; aname:PUnicodeChar):PMANFileInfo;
begin
  result:=PMANFileInfo(inherited SearchFile(aentry, aname))
end;

function TRGManifest.SearchFile(apath,aname:PUnicodeChar):PMANFileInfo;
begin
  result:=PMANFileInfo(inherited SearchFile(apath, aname))
end;

function TRGManifest.SearchFile(const fname:string):PMANFileInfo;
begin
  result:=PMANFileInfo(inherited SearchFile(fname))
end;

{%ENDREGION}

{%REGION I/O}
{
  Parse Manifest from memory block addressed by aptr
}
function TRGManifest.Parse(aptr:PByte; aver:integer):integer;
const
  bufsize = 1024;
var
  lbuf:array [0..bufsize-1] of byte;
  i,j:integer;
  lcnt,lentries,lentry:integer;
begin
  result:=0;

  case aver of
    verTL2Mod,
    verTL2:begin
      i:=memReadWord(aptr);                   // 0002 version/signature
      if i>=2 then                            // 0000 - no "checksum" field??
        memReadDWord(aptr);                   // checksum?
      root:=memReadShortString(aptr);         // root directory !!
    end;

    verHob,
    verRGO,
    verRG :begin
    end;

  else
    exit;
  end;

//  InitManifest(aman);

  reserve :=memReadDWord(aptr);               // total directory records
  FileCapacity:=reserve;
  lentries:=memReadDWord(aptr);               // entries
  DirCapacity:=lentries;
  total:=0;

  {
    Use AddEntryDir (not AddPath) and AddEntryFile (not AddFile) to avoid doubling
    file records when autocreating parent path records and adds file without name
    (so, not able to check for doubles)
  }
  for i:=0 to lentries-1 do
  begin
    lentry:=AddEntryDir(memReadShortStringBuf(aptr,@lbuf,bufsize));
//    lentry:=AddPath(memReadShortStringBuf(aptr,@lbuf,bufsize));
    lcnt:=memReadDWord(aptr);
    for j:=0 to lcnt-1 do
    begin
      with PManFileInfo(Files[AddEntryFile(lentry)])^ do
//      with PManFileInfo(AddFile(lentry))^ do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=PAKTypeToCommon(memReadByte(aptr),aver);
        Name    :=memReadShortStringBuf(aptr,@lbuf,bufsize);
        offset  :=memReadDWord(aptr);
        size_s  :=memReadDWord(aptr);
        if (aver=verTL2   ) or
           (aver=verTL2Mod) then
        begin
          ftime:=QWord(memReadInteger64(aptr));
        end;
      end;
    end;
  end;

  result:=total;
end;

{$PUSH}
{$I-}
function TRGManifest.SaveToStream(ast:TStream; aver:integer):integer;
var
  p:PMANFileInfo;
  lpos,ltotalpos:integer;
  i,ltotal:integer;
begin
  try
    lpos:=ast.Position;

    case aver of
      verTL2Mod,
      verTL2: begin
        ast.WriteWord (2); // writing always "new" version
        ast.WriteDWord(0); // Hash (game don't check it anyway)
        ast.WriteShortString(root);
      end;

      verHob,
      verRGO,
      verRG: begin
      end;
    else
      exit(0);
    end;

    ltotalpos:=ast.Position;
    ast.WriteDWord(total); //!! maybe beter to calculate at runtime
    ast.WriteDWord(DirCount);

    ltotal:=0;
    for i:=0 to DirCount-1 do
    begin
      if not IsDirDeleted(i) then
      begin
        ast.WriteShortString(GetDirName(i));
        ast.WriteDWord(Dirs[i].count);

        if GetFirstFile(p,i)<>0 then
        repeat
          inc(ltotal);
          with p^ do
          begin
            ast.WriteDWord(checksum);
            ast.WriteByte(PAKTypeToReal(ftype,aver));
            ast.WriteShortString(p^.Name);
            ast.WriteDWord(offset);
            ast.WriteDWord(size_s);
            if (aver=verTL2   ) or
               (aver=verTL2Mod) then
              ast.WriteQWord(ftime);
          end;
        until GetNextFile(p)=0;
      end;
    end;

    if ltotal>total then
    begin
      total:=ltotal;
      lpos:=ast.Position;
      try
        ast.Position:=ltotalpos;
        ast.WriteDWord(total);
        ast.Position:=lpos;
      except
      end;
    end;

    result:=total;

  except
    result:=0;
    try
      ast.Position:=lpos;
    except
    end;
  end;
end;
{$POP}

function TRGManifest.SaveToFile(const afname:string; aver:integer):integer;
var
  lst:TMemoryStream;
begin
  result:=0;

  lst:=TMemoryStream.Create;
  try
    result:=SaveToStream(lst,aver);
    if result>0 then
      lst.SaveToFile(afname);
  finally
    lst.Free;
  end;
end;

function CheckFName(const adir,aname:UnicodeString):UnicodeString;
var
  lext:array [0..15] of UnicodeChar;
  lname:UnicodeString;
  lextpos,j,k:integer;
begin
  result:='';
  
  lextpos:=Length(aname);
  while lextpos>1 do
  begin
    dec(lextpos);
    if aname[lextpos]='.' then break;
  end;
  // extract ext
  k:=0;
  if lextpos>1 then
    for j:=lextpos to Length(aname) do
    begin
      lext[k]:=UpCase(aname[j]);
      inc(k);
    end;
  lext[k]:=#0;

  if (CompareWide(lext,'.TXT'      )=0) or
     (CompareWide(lext,'.BINDAT'   )=0) or
     (CompareWide(lext,'.BINLAYOUT')=0) then
  begin
    lname:=Copy(aname,1,lextpos-1);
    if FileExists(adir+lname) then exit;
  end
  else if CompareWide(lext,'.PNG')=0 then
  begin
    lname:=aname;
    lname[lextpos+1]:='D';
    lname[lextpos+2]:='D';
    lname[lextpos+3]:='S';
    if FileExists(adir+lname) then
      exit
    else
      exit(aname);
  end
  else
    lname:=aname;

  // can't use lext coz need to delete ext to get real sometime
  if PAKExtType(lname)<>typeUnknown then
    result:=lname;
end;

{
  Build files tree [from MEDIA folder] [from dir]
  excluding PNG if DDS presents
  [excluding data sources]
  as is, bin+src (data cmp to choose), bin, src
}
procedure CycleDir(const abasedir:UnicodeString; var aman:TRGManifest; aentry:integer);
var
  sr:TUnicodeSearchRec;
  lcurdir,ldir,lname:UnicodeString;
  j,i,lstart,lend:integer;
begin
  ldir:=aman.GetDirName(aentry);
  lcurdir:=abasedir+ldir;

  if FindFirst(lcurdir+'*.*',faAnyFile and faDirectory,sr)=0 then
  begin

    lstart:=aman.DirCount;

    repeat
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          lname:=sr.Name+'/';
          for j:=1 to Length(lname)-1 do lname[j]:=UpCase(lname[j]);
          aman.AddPath(PUnicodeChar(ldir+lname));
          with PMANFileInfo(aman.AddFile(aentry,PUnicodeChar(lname)))^ do
            ftype:=typeDirectory;
        end;
      end
      else
      begin
        lname:=CheckFName(abasedir+ldir,sr.Name);
        if lname<>'' then
        begin
          for j:=1 to Length(lname) do lname[j]:=UpCase(lname[j]);
          with PMANFileInfo(aman.AddFile(aentry,PUnicodeChar(lname)))^ do
          begin
            ftype :=PAKExtType(lname);
            ftime :=sr.Time;
            size_s:=sr.Size;
            //!!
            if aman.FLUnpacked<sr.Size then aman.FLUnpacked:=sr.Size;
          end;
        end;
      end;
    until FindNext(sr)<>0;

    FindClose(sr);
    lend:=aman.DirCount;

    for i:=lstart to lend-1 do
    begin
      CycleDir(abasedir,aman,i);
    end;  

  end;
end;

function TRGManifest.Build(const adir:string):integer;
var
  ls:UnicodeString;
begin
  result:=0;

  ls:=UnicodeString(adir);
  if not (ls[Length(ls)] in ['/','\']) then ls:=ls+'/';

  Init;

  AddPath(nil);
  CycleDir(ls,self,0);

  root:=CopyWide('MEDIA/');

  result:=total;
end;
{%ENDREGION}

{$IFDEF DEBUG}
function ParseMANMem(const aman:TRGManifest; afull:boolean=false):pointer;
var
  p:PMANFileInfo;
  lman,lp,lc:pointer;
  i:integer;
begin
  lman:=nil;

  lman:=AddGroup(nil,'MANIFEST');
//??  AddString (lman,'FILE' ,PUnicodeChar(ainfo.fname));
  if afull then
  begin
    AddInteger(lman,'TOTAL',aman.total);
    AddInteger(lman,'COUNT',aman.DirCapacity);
  end;

  for i:=0 to aman.DirCount-1 do
  begin
    if aman.IsDirDeleted(i) then continue;

    lp:=AddGroup(lman,'FOLDER');
    AddString (lp,'NAME' ,aman.GetDirName(i));
    if afull then
      AddInteger(lp,'COUNT',aman.Dirs[i].count);
    lp:=AddGroup(lp,'CHILDREN');


    if aman.GetFirstFile(p,i)<>0 then
    repeat
      lc:=AddGroup(lp,'CHILD');
      with p^ do
      begin
        AddString (lc,'NAME',Name);
        AddInteger(lc,'TYPE',ftype);  // required for TL2 type 18 (dir to delete)
        AddInteger(lc,'SIZE',size_s); // required for zero-size files (file to delete)
        if afull then
        begin
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
                      with PMANFileInfo(aman.AddFile(lentry))^ do
                      begin
                        name    :=AsString(FindNode(lg,'NAME'));
                        ftype   :=AsInteger(FindNode(lg,'TYPE'));
                        size_s  :=AsInteger(FindNode(lg,'SIZE'));
                        offset  :=AsInteger(FindNode(lg,'OFFSET'));
                        checksum:=AsUnsigned(FindNode(lg,'CRC'));
                        ftime   :=AsInteger64(FindNode(lg,'TIME'));
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
{$ENDIF DEBUG}

end.
