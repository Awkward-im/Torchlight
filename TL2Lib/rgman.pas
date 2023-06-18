{TODO: add tree (dir with files)}
{TODO: rename dir}
{TODO: rename file}
{TODO: save compiled manifest size}
{TODO: calculate largest file size on parse and add. Or just on build?}
unit RGMan;

interface

uses
  Classes,
  TextCache,
  rgglobal;


type
  PMANFileInfo = ^TMANFileInfo;
  TMANFileInfo = record // not real field order
    ftime   :UInt64;    // MAN: TL2 only
{
    memadr  :PByte;     // file memory placement address
}
    name    :cardinal;  // !! MAN: TextCache index
//    fname   :string;    // disk filename
//    nametxt :PUnicodeChar; // source (text format) name
    checksum:dword;     // MAN: CRC32
    size_s  :dword;     // ?? MAN: looks like source,not compiled, size (unusable)
    size_c  :dword;     // !! PAK: from TPAKFileHeader
    size_u  :dword;     // !! PAK: from TPAKFileHeader
    offset  :dword;     // !! MAN: PAK data block offset
    next    :integer;
    ftype   :byte;      // !! MAN: RGFileType unified type
  end;
  TMANFileInfos = array of TMANFileInfo;

type
  PMANDirEntry = ^TMANDirEntry;
  TMANDirEntry = record
    name:cardinal;      // TextCache index
    count,
    first,
    last:integer;
  end;
  TMANDirEntries = array of TMANDirEntry;

type
  PRGManifest = ^TRGManifest;
  TRGManifest = object
  private
    FDirCount    :integer; // total count of Entries
    FDirDelFirst :integer; // first deleted Entry index. 0, if unknown
    FFileCount   :integer; // total count of file records
    FFileDelFirst:integer; // first index of deleted files
  private
    FLUnpacked:integer; // largest unpacked file size
    FLPacked  :integer; // largest   packed file size
  private
    FModified :boolean;
    Names  :TTextCache;
    Files  :TMANFileInfos;
  public
    Dirs   :TMANDirEntries;
    Deleted:TMANDirEntries;
  public
    // not necessary fields
    root   :PUnicodeChar;   // same as first directory, MEDIA (usually)
    total  :integer;        // total "file" elements. Can be calculated when needs
    reserve:integer;        // "total" records count (GUTS gives more than put)
    largest:integer;        // largest source file size
  private
    function  SetName(aname:PUnicodeChar):integer;
    procedure SetDirName(idx:integer; aname:PUnicodeChar);
    function  GetFilesCapacity():integer;
    procedure SetFilesCapacity(acnt:cardinal);
    function  GetDirsCapacity():integer;
    procedure SetDirsCapacity(acnt:cardinal);
    function  GetSize(idx:integer):integer;

    function  IsFileDeleted(idx:integer):boolean; inline;
    function  AddEntryFile(aentry:integer; aname:PUnicodeChar=nil):PManFileInfo;
    function  AddEntryDir (const apath:PUnicodeChar=pointer(-1)):integer;
    function  DoAddPath(const apath:UnicodeString):integer;
    procedure DeleteEntry    (aentry:integer);
    procedure DeleteEntryFile(aentry:integer; aname:PUnicodeChar);
  public
    procedure Init;
    procedure Free;

    function Parse(aptr:PByte; aver:integer):integer;
    function Build(const adir:string):integer;
//    function Clone(out aman:TRGManifest):integer;

    function SaveToStream(ast:TStream; aver:integer):integer;
    function SaveToFile  (const afname:string; aver:integer):integer;

    function SearchPath(apath:PUnicodeChar):integer;
    function SearchFile(aentry:integer; aname:PUnicodeChar):PMANFileInfo;
    function SearchFile(apath,aname:PUnicodeChar):PMANFileInfo;
    function SearchFile(const fname:string):PMANFileInfo;

    function IsDirDeleted(aentry:integer):boolean;

    function AddPath(apath:PUnicodeChar):integer;
    function AddPath(const apath:string):integer;

    function AddFile(apath,aname:PUnicodeChar):PMANFileInfo;

    function GetName   (idx:integer):PUnicodeChar;
    function GetDirName(idx:integer):PUnicodeChar;

    // result=0 means "end"
    function GetFirstFile(out p:PMANFileInfo; aentry:integer):integer;
    function GetNextFile (var p:PMANFileInfo):integer;

    procedure DeletePath(apath:PUnicodeChar);
    procedure DeletePath(const apath:string);
    procedure DeleteFile(apath,aname:PUnicodeChar);

    function RenameDir(const apath, oldname, newname:string):integer;
    function RenameDir(const apath, newname:string):integer;

  public
    property EntriesCount:integer read FDirCount;
//    property FilesCount  :integer read FFileCount;
    property LargestPacked  :integer index 0 read GetSize;
    property LargestUnpacked:integer index 1 read GetSize;
//    property Entries  [idx:integer]:PMANDirEntry read GetEntry;
    property DirName[idx:integer]:PUnicodeChar read GetDirName write SetDirName;
//    property FileName[p:PMANFileInfo]:PUnicodeChar read GetFileName;
//    property Files   [aentry:integer; idx:integer]:PMANFileInfo read GetEntryFile;
//    property FileName[aentry:integer; idx:integer]:PunicodeChar read GetFileName;
  public
    property Modified:boolean read FModified;
  end;


{$IFDEF DEBUG}
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

const
  incEBase = 512;
  incEntry = 256;
  incFBase = 128;
  incFFile = 16;

{%REGION Support}
// Upper case, no starting slashes but with ending
function TransformPath(apath:PUnicodeChar):UnicodeString;
var
  i,lsize:integer;
begin
  result:=UpCase(UnicodeString(apath));
  lsize:=Length(result);
  for i:=1 to lsize do
    if result[i]='\' then result[i]:='/';
  i:=1;
  while result[i]='/' do inc(i);
  dec(i);
  if i>0 then Delete(result,1,i); dec(lsize,i);

  if result[lsize]<>'/' then result:=result+'/';
end;

function TRGManifest.IsDirDeleted(aentry:integer):boolean; inline;
begin
  result:=Dirs[aentry].name=cardinal(-1);
end;

function TRGManifest.IsFileDeleted(idx:integer):boolean; inline;
begin
  result:=Files[idx].name=0;
end;
{%ENDREGION}

{%REGION Getters/Setters}
function TRGManifest.SetName(aname:PUnicodeChar):integer; inline;
begin
  result:=names.Append(aname);
end;

function TRGManifest.GetName(idx:integer):PUnicodeChar; inline;
begin
  result:=PUnicodeChar(names[idx]);
end;

function TRGManifest.GetDirName(idx:integer):PUnicodeChar;
begin
  if (idx>0) and (idx<FDirCount) and not IsDirDeleted(idx) then
    result:=GetName(Dirs[idx].name)
  else
    result:=nil;
end;

procedure TRGManifest.SetDirName(idx:integer; aname:PUnicodeChar); inline;
begin
  if (idx>0) and (idx<FDirCount) then
    Dirs[idx].name:=SetName(aname);
end;

function TRGManifest.GetFilesCapacity():integer; inline;
begin
  result:=Length(Files);
end;

procedure TRGManifest.SetFilesCapacity(acnt:cardinal);
begin
  if acnt>Length(Files) then
    SetLength(Files,acnt);
end;

function TRGManifest.GetDirsCapacity():integer; inline;
begin
  result:=Length(Dirs);
end;

procedure TRGManifest.SetDirsCapacity(acnt:cardinal);
begin
  if acnt>Length(Dirs) then
    SetLength(Dirs,acnt);
end;
{%ENDREGION}

{%REGION Common}
function TRGManifest.GetFirstFile(out p:PMANFileInfo; aentry:integer):integer;
begin
  result:=Dirs[aentry].first;
  if result<>0 then p:=@Files[result];
end;

function TRGManifest.GetNextFile(var p:PMANFileInfo):integer;
begin
  result:=p^.next;
  if result<>0 then p:=@Files[result];
end;

function TRGManifest.GetSize(idx:integer):integer;
var
  i:integer;
begin
       if idx=0 then result:=FLPacked
  else if idx=1 then result:=FLUnpacked;

  if result=0 then
  begin
    for i:=0 to FFileCount-1 do
    begin
      if not IsFileDeleted(i) then
      begin
        if Files[i].size_c>FLPacked   then FLPacked  :=Files[i].size_c;
        if Files[i].size_u>FLUnpacked then FLUnpacked:=Files[i].size_u;
      end;
    end;

         if idx=0 then result:=FLPacked
    else if idx=1 then result:=FLUnpacked;
  end;
end;

procedure TRGManifest.Init;
begin
  FillChar(self,SizeOf(self),0);
{
  cntEntry:=0;
  cntFiles:=0;

  Initialize(Entries);
  Initialize(Deleted);
  Initialize(Files);
//  FillChar(aman,SizeOf(aman),0); //!!
}
  names.Init(false);
end;

procedure TRGManifest.Free;
begin
  FreeMem(root);

  names.Clear;
  Finalize(Dirs);
  Finalize(Deleted);
  Finalize(Files);
end;
{%ENDREGION}

{%REGION Search}
function TRGManifest.SearchPath(apath:PUnicodeChar):integer;
var
  i:integer;
begin
  for i:=0 to FDirCount-1 do
  begin
    if not IsDirDeleted(i) then
      if CompareWide(GetDirName(i),apath)=0 then
        exit(i);
  end;

  result:=-1;
end;

function TRGManifest.SearchFile(aentry:integer; aname:PUnicodeChar):PMANFileInfo;
begin
  if (aentry>=0) and (aentry<FDirCount) then
  begin
    if GetFirstFile(result,aentry)<>0 then
      repeat
        if CompareWide(GetName(result^.name),aname)=0 then exit;
      until GetNextFile(result)=0;
  end;
  
  result:=nil;
end;

function TRGManifest.SearchFile(apath,aname:PUnicodeChar):PMANFileInfo;
begin
  result:=SearchFile(SearchPath(apath),aname);
end;

function TRGManifest.SearchFile(const fname:string):PMANFileInfo;
var
  lpath,lname:UnicodeString;
begin
  lname:=UpCase(UnicodeString(fname));
  lpath:=ExtractFilePath(lname);
  lname:=ExtractFileName(lname);

  result:=SearchFile(pointer(lpath),pointer(lname));
end;
{%ENDREGION}

{%REGION File}
  {%REGION Add}
function TRGManifest.AddEntryFile(aentry:integer; aname:PUnicodeChar=nil):PManFileInfo;
var
  i,lnew:integer;
begin
  //!!
  if aentry<0 then exit(nil);

  // expand if needs
  if FFileCount=0 then
  begin
    SetFilesCapacity(incFBase);
    FFileCount:=1;
  end;

  // Get deleted or append
  if FFileDelFirst<>0 then
  begin
    lnew:=FFileDelFirst;
    FFileDelFirst:=Files[lnew].next;
  end
  else
    lnew:=FFileCount;

  if FFileCount=GetFilesCapacity() then
    SetFilesCapacity(FFileCount+incFFile);

  // links
  i:=Dirs[aentry].last;
  if i>0 then
    Files[i].next:=lnew
  else
    Dirs[aentry].first:=lnew;

  Dirs[aentry].last:=lnew;
  inc(Dirs[aentry].count);

  // data
  result:=@Files[lnew];
  FillChar(result^,SizeOf(result^),0);
  if aname<>nil then
    result^.name:=SetName(aname);

  if lnew=FFileCount then inc(FFileCount);
  inc(total);
end;

//  Add file with relative path. requires root dir to get physical file info like time and size
function TRGManifest.AddFile(apath,aname:PUnicodeChar):PMANFileInfo;
var
  lentry:integer;
begin
  lentry:=AddPath(apath);
  if lentry<0 then exit(nil);

  result:=SearchFile(lentry,aname);
  if result<>nil then exit;

  // add record if file was not found
  result:=AddEntryFile(lentry,aname);

  with result^ do
  begin
    name :=SetName(aname);
    ftype:=PAKExtType(aname); //!! not requires at start but good for filter
  end;

end;
  {%ENDREGION Add}

  {%REGION Delete}
procedure TRGManifest.DeleteEntryFile(aentry:integer; aname:PUnicodeChar);
var
  p:PMANFileInfo;
  prev,idx:integer;
begin
  if (aentry>=0) and (aentry<FDirCount) then
  begin
    idx:=Dirs[aentry].first;
    if idx>0 then
    begin
      prev:=0;
      repeat
        p:=@Files[idx];
        if CompareWide(GetName(p^.name),aname)=0 then
        begin
          dec(total);
          dec(Dirs[aentry].count);
          // cut the deleting
          if prev<>0 then
            Files[prev].next:=p^.next
          else if p^.next<>0 then
            Dirs[aentry].first:=p^.next;

          p^.name:=0;
          p^.next:=FFileDelFirst;
          FFileDelFirst:=idx;
          break;
        end;
        prev:=idx;
        idx:=p^.next;
      until idx=0;
    end;
  end;
end;

procedure TRGManifest.DeleteFile(apath,aname:PUnicodeChar);
var
  i:integer;
begin
  i:=SearchPath(apath);
  if i>0 then
  begin
    DeleteEntryFile(i,aname);
//    dec(total);
  end;
end;
  {%ENDREGION Delete}
{%ENDREGION File}

{%REGION Entry}
  {%REGION Add}
function TRGManifest.AddEntryDir(const apath:PUnicodeChar=pointer(-1)):integer;
begin
  // Check for first allocation. It have empty name ALWAYS
  if GetDirsCapacity()=0 then
    SetDirsCapacity(incEBase);

  if FDirCount=0 then
  begin
    FillChar(Dirs[0],SizeOf(Dirs[0]),0); //??
    FDirCount:=1;
  end;

  if (apath=nil) or (apath^=#0) then exit(0);

  // search for empty place in the middle
  if FDirDelFirst>0 then
  begin
    result:=FDirDelFirst;
    FDirDelFirst:=Dirs[result].last;
  end
  else
    result:=FDirCount;
  
  // not found - add to the end
  if result=FDirCount then
  begin
    // expand if needs
    if FDirCount=GetDirsCapacity() then
      SetDirsCapacity(FDircount+incEntry);

    inc(FDirCount);
  end;
  FillChar(Dirs[result],SizeOf(TMANDirEntry),0);

  if apath<>pointer(-1) then
    Dirs[result].name:=SetName(apath);
  
  inc(total);
end;

function TRGManifest.DoAddPath(const apath:UnicodeString):integer;
var
  lslash,lentry:integer;
begin
  // if exists already
  result:=SearchPath(PUnicodeChar(apath));
  if result>=0 then exit;

  // add parent dir
  lslash:=Length(apath)-1;
  while (lslash>1) and (apath[lslash]<>'/') do dec(lslash);
  if lslash>1 then
  begin
    lentry:=DoAddPath(Copy(apath,1,lslash));

    with AddEntryFile(lentry,PUnicodeChar(apath)+lslash)^ do
      ftype:=typeDirectory;
  end;

  result:=AddEntryDir(PUnicodeChar(apath));
end;

function TRGManifest.AddPath(apath:PUnicodeChar):integer;
begin
  if FDirCount=0 then
    AddEntryDir(nil);
  
  if (apath=nil) or (apath^=#0) then exit(0);
  
  result:=DoAddPath(TransformPath(apath));
end;

function TRGManifest.AddPath(const apath:string):integer;
begin
  result:=AddPath(PUnicodeChar(UnicodeString(apath)))
end;
  {%ENDREGION Add}

  {%REGION Delete}
procedure TRGManifest.DeleteEntry(aentry:integer);
var
  p:PMANFileInfo;
  lfile,ldir,pcw:PUnicodeChar;
begin
  if aentry>0 then
  begin
    dec(total);
    // delete files
    if GetFirstFile(p,aentry)<>0 then
    begin
      ldir:=GetDirName(aentry);
      repeat
        lfile:=GetName(p^.name);
        if p^.ftype=typeDirectory then
        begin
          pcw:=ConcatWide(ldir,lfile);
          DeleteEntry(SearchPath(pcw));
          FreeMem(pcw);
        end
        else
          DeleteEntryFile(aentry,lfile); //!! double check
      until GetNextFile(p)=0;
    end;

    Dirs[aentry].name:=cardinal(-1);
    Dirs[aentry].last:=FDirDelFirst;
    FDirDelFirst:=aentry;
  end;
end;

procedure TRGManifest.DeletePath(apath:PUnicodeChar);
var
  i,lslash:integer;
begin
  i:=SearchPath(apath);
  if i>=0 then
  begin
    // delete from parent entry
    lslash:=Length(apath)-1;
    while (lslash>1) and (apath[lslash]<>'/') do dec(lslash);
    if lslash>1 then
    begin
      DeleteFile(PUnicodeChar(Copy(apath,1,lslash)),PUnicodeChar(apath)+lslash);
    end;

    DeleteEntry(i);
  end;
end;

procedure TRGManifest.DeletePath(const apath:string);
begin
  DeletePath(PUnicodeChar(UnicodeString(apath)));
end;
  {%ENDREGION Delete}

  {%REGION Rename}
function TRGManifest.RenameDir(const apath, oldname, newname:string):integer;
var
  lpath,lpathnew,lold,lnew:UnicodeString;
  lname:PUnicodeChar;
  lpold,p:PMANFileInfo;
  lentry,lparent,i:integer;
begin
  result:=0;
  //!!!! Transform path to upcase with '/' at the end
  lpath:=UnicodeString(apath);
  // Search parent
  lparent:=SearchPath(PUnicodeChar(lpath));
  if lparent>=0 then
  begin
    //!!!! Transform names to upcase with '/' at the end
    lold:=UnicodeString(oldname);
    lpathnew:=lpath;
    lpath:=lpath+lold;
    // Search old
    lentry:=SearchPath(PUnicodeChar(lpath));
    if lentry>0 then
    begin
      lnew:=UnicodeString(newname);
      lpold:=nil;
      // Search file record in parent and check for existing new
      if GetFirstFile(p,lparent)<>0 then
      begin
        repeat
          lname:=GetName(p^.name);
          //!! compare with not dir only but files too
          if CompareWide(lname,PUnicodeChar(lnew))=0 then exit;
          if (lpold=nil) and (CompareWide(lname,PUnicodeChar(lold))=0) then lpold:=p;
        until GetNextFile(p)=0;
        if lpold<>nil then
        begin
          lpold^.name:=SetName(PUnicodeChar(lnew));
          lpathnew:=lpathnew+lnew;
          // replace
          Dirs[lentry].name:=SetName(PUnicodeChar(lpathnew));
          // rename children
          for i:=0 to FDirCount-1 do
          begin
            if (i<>lparent) and (i<>lentry) and not IsDirDeleted(i) then
            begin
              lname:=GetDirName(i);
              if PosWide(PUnicodeChar(lpath),lname)=lname then
                ; //!! Replace lpath to lpathnew
            end;
          end;
        end;
      end;
    end;
  end;
end;

function TRGManifest.RenameDir(const apath, newname:string):integer;
var
  lslash:integer;
begin
  lslash:=Length(apath)-1;
  while (lslash>1) and (apath[lslash]<>'/') do dec(lslash);
  if lslash>1 then
    result:=RenameDir(Copy(apath,1,lslash),Copy(apath,lslash+1),newname)
  else
    result:=RenameDir('',apath,newname)
end;
  {%ENDREGION Rename}

{%ENDREGION Entry}

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
  lentries:=memReadDWord(aptr);               // entries
  SetDirsCapacity(lentries);
  total:=0;

  for i:=0 to lentries-1 do
  begin
    lentry:=AddEntryDir(memReadShortStringBuf(aptr,@lbuf,bufsize));
    lcnt:=memReadDWord(aptr);
    for j:=0 to lcnt-1 do
    begin
      with AddEntryFile(lentry)^ do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=PAKTypeToCommon(memReadByte(aptr),aver);
        name    :=SetName(memReadShortStringBuf(aptr,@lbuf,bufsize));
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
    ast.WriteDWord(FDirCount);

    ltotal:=0;
    for i:=0 to FDirCount-1 do
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
            ast.WriteShortString(GetName(name));
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

    lstart:=aman.FDirCount;

    repeat
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          lname:=sr.Name+'/';
          for j:=1 to Length(lname)-1 do lname[j]:=UpCase(lname[j]);
          aman.AddEntryDir(PUnicodeChar(ldir+lname));
          with aman.AddEntryFile(aentry,PUnicodeChar(lname))^ do
            ftype:=typeDirectory;
        end;
      end
      else
      begin
        lname:=CheckFName(abasedir+ldir,sr.Name);
        if lname<>'' then
        begin
          for j:=1 to Length(lname) do lname[j]:=UpCase(lname[j]);
          with aman.AddEntryFile(aentry,PUnicodeChar(lname))^ do
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
    lend:=aman.FDirCount;

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

  AddEntryDir(nil);
  CycleDir(ls,self,0);

  root:=CopyWide('MEDIA/');

  result:=total;
end;
{%ENDREGION}

{$IFDEF DEBUG}
procedure MANtoFile(const fname:string; const aman:TRGManifest; afull:boolean=false);
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
    AddInteger(lman,'COUNT',aman.GetDirsCapacity());
  end;

  for i:=0 to aman.FDirCount-1 do
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
        AddString (lc,'NAME',aman.GetName(name));
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

  BuildTextFile(lman,PChar(fname));
  DeleteNode(lman);
end;

procedure FileToMAN(const fname:string; out aman:TRGManifest);
var
  lman,lp,lg,lc:pointer;
  pw:PUnicodeChar;
  i,j,k,lentry:integer;
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
            if IsNodeName(lc,'COUNT') then aman.SetDirsCapacity(AsInteger(lc));
          end;

          rgGroup: begin
            if IsNodeName(lc,'FOLDER') then
            begin
              if aman.GetDirsCapacity()=0 then
                aman.SetDirsCapacity(GetGroupCount(lc));

              for j:=0 to GetChildCount(lc)-1 do
              begin
                lentry:=aman.AddEntryDir();
                lp:=GetChild(lc,j);
                case GetNodeType(lp) of
                  rgString: begin
                    if IsNodeName(lp,'NAME') then
                      aman.Dirs[lentry].name:=aman.SetName(AsString(lp));
                  end;

                  rgInteger: begin
                    if IsNodeName(lp,'COUNT') then
                      aman.SetFilesCapacity(aman.FFileCount+AsInteger(lp));
                  end;

                  rgGroup: begin
                    if IsNodeName(lp,'CHILDREN') then
                    begin
{
                      if Length(aman.Entries[j].Files)=0 then
                        SetLength(aman.Entries[j].Files,GetGroupCount(lp));
}
                      for k:=0 to GetChildCount(lp)-1 do
                      begin
                        lg:=GetChild(lp,k);
                        if (GetNodeType(lg)=rgGroup) and
                           (IsNodeName(lg,'CHILD')) then
                        begin

                          with aman.AddEntryFile(lentry)^ do
                            case GetNodeType(lg) of
                              rgInteger: begin
                                pw:=GetNodeName(lg);
                                if      CompareWide(pw,'TYPE'  )=0 then ftype :=AsInteger(lg)
                                else if CompareWide(pw,'SIZE'  )=0 then size_s:=AsInteger(lg)
                                else if CompareWide(pw,'OFFSET')=0 then offset:=AsInteger(lg);
                              end;
                              rgString   : name    :=aman.SetName(AsString(lg));
                              rgUnsigned : checksum:=AsUnsigned(lg);
                              rgInteger64: ftime   :=AsInteger64(lg);
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
    end;

    DeleteNode(lman);
  end;
end;
{$ENDIF DEBUG}

end.
