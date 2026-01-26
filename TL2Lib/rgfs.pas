{
  Tree-like directory+files structure
  have dir-only array with full paths, xref with tree nodes
  one list with file/dir records
  global text cache
}
{NOTE: "/" for dir name useful in MAN and list view}
{TODO: Make difference, added or found existing file/dir}
{TODO: Remove finishing "/" at file create/rename if exists}
{TODO: Add finishing "/" at dir create/rename if not exists}
{TODO: option for co-exists file and dir with same name}
{TODO: don't keep full path name initially, just make it by request (clear on cnahge)}
{TODO: make different Names for Files and Dirs (to use double search for Dirs)}
{TODO: make Names text cache NOT global. But FileInfo is not part of DirList}
{TODO: remove "count" field for Dirs? anyway, GetFirst/Next used}
{TODO: remove "total" changes/saving coz total = DirCount+FileCount (except deleted)}
{TODO: check all variant of AddPath/AddFile what we uses (i.e. PUnicodeChar, AnsiString...}
{TODO: Add file record on AddPath too (for Runtime). But AppendFile for MAN.Parse}
{TODO: keep/calc info about all sub-dir and files, not direct children only}
unit RGFS;

interface

type
  PBaseInfo = ^TBaseInfo;
  TBaseInfo = object
  private
    fname:integer;

    function  GetFileName():PUnicodeChar;
    procedure SetFileName(aname:PUnicodeChar);
    function  GetFileNameLen():integer;
//  public
  protected
    index:integer;      // Index of Files and Dir arrays. Or offset
  public
    procedure SameNameAs(afi:PBaseInfo);
    function  IsSameName(afi:PBaseInfo):boolean;

    property Name   :PUnicodeChar read GetFileName write SetFileName;
    property NameLen:integer      read GetFileNameLen;
  end;

type
  PBaseFileInfo = ^TBaseFileInfo;
  TBaseFileInfo = object(TBaseInfo)
  private
    parent:integer;     // parent dir index
    next  :integer;     // next file in current directory
  private
    _ftype  :word;      // MAN: RGFileType unified type

    function GetFType:word;
  public
    property ftype:word read GetFType write _ftype;
  end;

type
  PFileInfo = ^TFileInfo;
  TFileInfo = object(TBaseFileInfo)
  public
    ftime   :UInt64;
    size    :cardinal;
    checksum:dword;
  end;

type
  PDirInfo = ^TDirInfo;
  TDirInfo = object(TBaseInfo)
    count,              // count of child files and dirs (from first to last)
    first,
    last :integer;
  end;
  TDirEntries = array of TDirInfo;

const
  faAdd      = 0; // file/dir added
  faRename   = 1; // file/dir renamed
  faDeleting = 2; // file/dir deleted
  faDeleted  = 3; // file/dir deleted
  faMove     = 4; // unimplemented. need to know old path
type
  TRGOnChange = function(actrl:pointer; idx:integer; aevent:integer):integer of object;

type
  PRGDirList = ^TRGDirList;

  { TRGDirList }

  TRGDirList = object
  private
    FDirCount    :integer; // total count of Entries
    FDirDelFirst :integer; // first deleted Entry index. 0, if unknown
    FFileCount   :integer; // total count of file records
    FFileDelFirst:integer; // first index of deleted files
  private
    FFiles   :PByte;       // TBaseFileInfo and it modifications buffer
    FInfoSize:integer;     // Size of single buffer element
    FCapacity:integer;     // Fileinfo buffer and oriental name cache capacity
    FCase    :boolean;     // translate to UpCase or keep original (not used atm)
    FModified:boolean;
    FOnChange:TRGOnChange;

  protected
    function  GetFileInfoPtr(idx:integer):PBaseFileInfo;
    function  DoAddFile (apath:PUnicodeChar):integer;
    function  DoAddPath (apath:PUnicodeChar):integer;               // Add dirs with full path, no event
    function  DoAddFile (adir:integer; aname:PUnicodeChar):integer; // Add file, no event
    function  DoAddDir  (adir:integer; aname:PUnicodeChar):integer;

  private
    function  GetFilesCapacity():integer;
    procedure SetFilesCapacity(acnt:integer);
    function  GetDirsCapacity ():integer;
    procedure SetDirsCapacity (acnt:integer);

    // Upper case, no starting slashes but with ending
    function TransformPath(const apath:AnsiString):UnicodeString;
    function TransformPath(apath:PUnicodeChar    ):UnicodeString;

    function  AppendFile(adir:integer; aname:PUnicodeChar):integer; // Add record to list, no link
    procedure DeleteFileRec(aidx:integer);                          // Delete record, no check for dir (!!!!event)

    function  AppendDir   (apath:PUnicodeChar):integer;   // Add record to list, no link
    procedure DeleteDir   (adir:integer);                 // Delete dir with childs, not from parent

    function  DoSearchPath(apath:PUnicodeChar):integer;
    function  DoSearch(adir:integer; aname:PUnicodeChar):integer;

    function DoRename    (aidx:integer; aname:PUnicodeChar):boolean;
    function DoRenameFile(aidx:integer; aname:PUnicodeChar):boolean;

    function  OnChangeDef(actrl:pointer; idx:integer; aevent:integer):integer;
    procedure SetOnChange(aproc:TRGOnChange);

    //--- PUBLIC area ---

  // Base
  public
    procedure Init(aInfoSize:integer=SizeOf(TBaseFileInfo); aCase:boolean=false);
    procedure Clear;
    procedure Free;
    procedure Link; // Set Dir array "index" field to proper Files array element number

  public
    function SearchPath(apath:PUnicodeChar):integer;
    function SearchPath(const apath:AnsiString):integer;

    // files and dirs are not the same. mean, "/" at the end is NOT ignored
    function SearchFile(adir:integer; aname:PUnicodeChar):integer;
    function SearchFile(apath,aname:PUnicodeChar):integer;
    function SearchFile(apath:PUnicodeChar):integer;
    function SearchFile(const apath:AnsiString):integer;
    function IsNameExists(adir:integer; const aname:AnsiString):integer;

    // result=0 means "end"
    function GetFirstFile(out p:pointer; adir:integer):integer;
    function GetNextFile (var p:pointer):integer;

    function GetFirstFile(out idx:integer; adir:integer):boolean;
    function GetNextFile (var idx:integer):boolean;

  // Change info
  public
    function  AddFile(adir:integer      ; aname:PUnicodeChar):integer;
    function  AddFile(apath:PUnicodeChar; aname:PUnicodeChar):integer;
    function  AddFile(apath:PUnicodeChar):integer;

    procedure DeleteFile(aidx:integer);
    procedure DeleteFile(adir:integer; aname:PUnicodeChar);
    procedure DeleteFile(apath,aname:PUnicodeChar);

    // right now: just delete at old place and create at new. no any data copied
    function MoveFile(aidx:integer; adir :integer     ):integer;
    function MoveFile(aidx:integer; apath:PUnicodeChar):integer;

    function AddDir(adir:integer; aname:PUnicodeChar):integer;
    function AddPath(apath:PUnicodeChar):integer;
    function AddPath(const apath:AnsiString):integer;

    procedure DeletePath(adir:integer);
    procedure DeletePath(apath:PUnicodeChar);
    procedure DeletePath(const apath:AnsiString);

    function Rename(const apath, aname:AnsiString):boolean;
    function Rename(adir:integer; oldname, newname:PUnicodeChar):boolean;
    function Rename(aidx:integer; aname:PUnicodeChar):boolean;

    //!!! DO NOT USE (not reay yet)
//    function MoveDir(adir:integer; adst:integer):integer;
//    function MoveDir(adir:integer; adst:PUnicodeChar):integer;
    procedure CopyFileInfo(afrom,ato:PFileInfo);

  
  // Properties
  public
    Dirs:TDirEntries;
    total:integer;         // total "file" elements. Can be calculated when needs. Not used atm

    function IsDirDeleted (adir:integer):boolean;
    function IsFileDeleted(aidx:integer):boolean;
    function IsDir        (aidx:integer):boolean;       // check what File record is for dir
    function NameOfFile   (aidx:integer):PUnicodeChar;  // get file name
    function PathOfFile   (aidx:integer):PUnicodeChar;  // get parent Dir name
    function FileDir      (aidx:integer):integer;       // get parent Dir index
    function AsDir        (aidx:integer):integer;       // get Dir array index of idx-ed file
    function AsFile       (adir:integer):integer;       // get File array index from Dir list index

    function DirName      (adir:integer):PUnicodeChar;  // like NameOfFile (was: without trailing slash)
                                                        // looks like not used atm
    function IndexOf(p:pointer):integer;                // not used atm

    property DirCount    :integer read FDirCount;
    property DirCapacity :integer read GetDirsCapacity  write SetDirsCapacity;
    property FileCapacity:integer read GetFilesCapacity write SetFilesCapacity;
    property FileCount   :integer read FFileCount;

    property Files[idx:integer]:PBaseFileInfo read GetFileInfoPtr;

  // Events
  public
    property OnChange:TRGOnChange read FOnChange write SetOnChange;

  // Properties runtime
  public
    property Modified:boolean read FModified;
    property IsCaseSensitive:boolean read FCase write FCase;
  end;

{
  Check file name to include or not. skip unknown, png if dds presents
    and compiled data files if source presents
  in : dir and filename to check
  out: empty to skip, lname to include
}
function CheckFName(const adir,aname:UnicodeString):UnicodeString;
procedure CopyInfo(afrom, ato:PFileInfo);


implementation

uses
  SysUtils,
  TextCache,
  RGGlobal,
  RGFileType
  ;

const
  MidFNameLen = 48; // middle file name length for buffer reserve
var
  Names:TTextCache;

const
  incEBase = 512;
  incEntry = 256;
  incFBase = 128;
  incFFile = 16;

function SetName(aname:PUnicodeChar):integer; inline;
begin
//  result:=names.Add(aname);
  result:=names.Append(aname);
end;

function GetName(idx:integer):PUnicodeChar; inline;
begin
  result:=PUnicodeChar(names[idx]);
end;

{%REGION Base}

function TBaseInfo.GetFileName():PUnicodeChar;
begin
  result:=GetName(self.fname);
end;

procedure TBaseInfo.SetFileName(aname:PUnicodeChar);
begin
  self.fname:=SetName(aname);
end;

function TBaseInfo.GetFileNameLen():integer;
begin
  result:=names.len[self.fname];
end;

procedure TBaseInfo.SameNameAs(afi:PBaseInfo); inline;
begin
  fname:=afi^.fname;
end;

function TBaseInfo.IsSameName(afi:PBaseInfo):boolean; inline;
begin
  result:=fname=afi^.fname;
end;

function TBaseFileInfo.GetFType:word;
begin
  if _ftype=typeUnknown then _ftype:=RGTypeOfExt(Name);
  result:=_ftype;
end;

{%ENDREGION Base}

{%REGION Support}

function TRGDirList.IsDir(aidx:integer):boolean;
var
  p:PUnicodeChar;
begin
  if (aidx<0) or (aidx>=FFileCount) then exit(false);
  with Files[aidx]^ do
  begin
    p:=Name;
    result:=(p<>nil) and (p[NameLen-1]='/');
  end;
end;

function TRGDirList.TransformPath(const apath:AnsiString):UnicodeString;
var
  i,j,lsize,lrsize:integer;
begin
  if apath='' then
  begin
    result:='';
    exit;
  end;

  i:=1;
  lsize:=Length(apath);
  while (apath[i]='\') or (apath[i]='/') do inc(i);
  lrsize:=lsize-i+1;
  if (apath[lsize]<>'\') and (apath[lsize]<>'/') then inc(lrsize);
  SetLength(result,lrsize);

  j:=1;
  while i<=lsize do
  begin
    if apath[i]='\' then result[j]:='/'
    else if FCase   then result[j]:=UnicodeChar(ORD(apath[i]))
    else                 result[j]:=UnicodeChar(ORD(UpCase(apath[i])));
    inc(i);
    inc(j);
  end;

  {if result[lrsize]<>'/' then }result[lrsize]:='/';
end;

function TRGDirList.TransformPath(apath:PUnicodeChar):UnicodeString;
var
  i,j,lsize,lrsize:integer;
begin
  if (apath=nil) or (apath^=#0) then
  begin
    result:='';
    exit;
  end;

  i:=0;
  lsize:=Length(apath)-1;
  while (apath[i]='\') or (apath[i]='/') do inc(i);
  lrsize:=(lsize+1)-i;
  if (apath[lsize]<>'\') and (apath[lsize]<>'/') then inc(lrsize);
  // case when path='/'
  if lrsize=0 then lrsize:=1;
  SetLength(result,lrsize);

  j:=1;
  while i<=lsize do
  begin
    if apath[i]='\' then result[j]:='/'
    else if FCase   then result[j]:=apath[i]
    else                 result[j]:=FastUpCase(apath[i]);
    inc(i);
    inc(j);
  end;

  {if result[lrsize]<>'/' then }result[lrsize]:='/';
end;

function TRGDirList.IsDirDeleted(adir:integer):boolean; inline;
begin
  result:=(adir<0) or (adir>=FDirCount) or ((adir>0) and (Dirs[adir].Name=nil));
end;

function TRGDirList.IsFileDeleted(aidx:integer):boolean; inline;
begin
  result:=(aidx<0) or (aidx>=FFileCount) or (Files[aidx]^.Name=nil);
end;

function TRGDirList.NameOfFile(aidx:integer):PUnicodeChar; inline;
begin
  if not IsFileDeleted(aidx) then result:=Files[aidx]^.Name else result:=nil;
end;

function TRGDirList.PathOfFile(aidx:integer):PUnicodeChar; inline;
begin
  if not IsFileDeleted(aidx) then result:=Dirs[Files[aidx]^.parent].Name else result:=nil;
end;

function TRGDirList.FileDir(aidx:integer):integer; inline;
begin
  if IsFileDeleted(aidx) then
    result:=0
  else
    result:=Files[aidx]^.parent;
end;

function TRGDirList.AsDir(aidx:integer):integer; inline;
begin
  if IsDir(aidx) then result:=Files[aidx]^.index else result:=-1;
end;

function TRGDirList.AsFile(adir:integer):integer; inline;
begin
  if not IsDirDeleted(adir) then result:=Dirs[adir].index else result:=-1;
end;

function TRGDirList.DirName(adir:integer):PUnicodeChar; inline;
begin
  if not IsDirDeleted(adir) then
    result:=Files[Dirs[adir].index]^.Name
  else
    result:=nil;
end;

function TRGDirList.IndexOf(p:pointer):integer; inline;
begin
  result:=UIntPtr(PByte(p)-PByte(FFiles)) div SizeOf(FInfoSize);
end;

function TRGDirList.OnChangeDef(actrl:pointer; idx:integer; aevent:integer):integer;
begin
  result:=1;
end;

procedure TRGDirList.SetOnChange(aproc:TRGOnChange); inline;
begin
  if aproc=nil then
    FOnChange:=@OnChangeDef
  else
    FOnChange:=aproc;
end;

{%ENDREGION Support}

{%REGION Getters/Setters}

function TRGDirList.GetFileInfoPtr(idx:integer):PBaseFileInfo;
begin
  if (idx>=0) and (idx<FFileCount) then
    result:=PBaseFileInfo(FFiles+idx*FInfoSize)
  else
    result:=nil;
end;

function TRGDirList.GetFilesCapacity():integer; inline;
begin
  result:=FCapacity;
end;

procedure TRGDirList.SetFilesCapacity(acnt:integer);
begin
  if acnt>FCapacity then
  begin
    if Names.Count<acnt then
    begin
      Names.Count:=acnt;
      Names.Capacity:=acnt*MidFNameLen;
    end;
    FCapacity:=acnt;
    ReallocMem(FFiles,FCapacity*FInfoSize);
  end;
end;

function TRGDirList.GetDirsCapacity():integer; inline;
begin
  result:=Length(Dirs);
end;

procedure TRGDirList.SetDirsCapacity(acnt:integer);
begin
  if acnt>Length(Dirs) then
  begin
    if Names.Count<acnt then Names.Count:=acnt;
    SetLength(Dirs,acnt);
  end;
end;

{%ENDREGION Getters/Setters}

{%REGION Common}

function TRGDirList.GetFirstFile(out p:pointer; adir:integer):integer;
begin
  if (adir<0) or (adir>=FDirCount) then exit(0);

  result:=Dirs[adir].first;
  if result>=0 then p:=Files[result];
  inc(result);
end;

function TRGDirList.GetNextFile(var p:pointer):integer;
begin
  result:=PBaseFileInfo(p)^.next;
  if result>=0 then p:=Files[result];
  inc(result);
end;

function TRGDirList.GetFirstFile(out idx:integer; adir:integer):boolean;
begin
  if (adir<0) or (adir>=FDirCount) then exit(false);

  idx:=Dirs[adir].first;
  result:=idx>=0;
end;

function TRGDirList.GetNextFile(var idx:integer):boolean;
begin
  idx:=Files[idx]^.next;
  result:=idx>=0;
end;

procedure TRGDirList.Link;
var
  buf:array [0..511] of UnicodeChar;
  p:PBaseFileInfo;
  i,ldir:integer;
begin
  for i:=0 to FileCount-1 do
  begin
    if isDir(i) then
    begin
      p:=Files[i];
      ldir:=Dirs[p^.parent].NameLen;
      move (Dirs[p^.parent].Name^, buf[0]   , ldir);
      move (p^             .Name^, buf[ldir], p^.NameLen+1);

      ldir:=DoSearchPath(@buf[0]);
      if ldir>=0 then
      begin
        Dirs [ldir].index:=i;
        p^.index:=ldir;
      end;
    end;
  end;
end;

{%ENDREGION Common}

{%REGION Main}

procedure TRGDirList.Init(aInfoSize:integer=SizeOf(TBaseFileInfo); aCase:boolean=false);
begin
  FillChar(self,SizeOf(self),0);
  FCase:=aCase;
  OnChange:=nil;

  FInfoSize:=aInfoSize;

  FDirDelFirst :=-1;
  FFileDelFirst:=-1;
end;

procedure TRGDirList.Clear;
begin
  Finalize(Dirs);
  Dirs:=nil;
  FDirCount:=0;

  FDirDelFirst:=-1;
  total:=0;

  FreeMem(FFiles);
  FFiles:=nil;
  FCapacity:=0;
  FFileCount:=0;
  FFileDelFirst:=-1;
end;

procedure TRGDirList.Free;
begin
  Clear;
end;

{%ENDREGION Main}

{%REGION Search}

function TRGDirList.DoSearchPath(apath:PUnicodeChar):integer;
var
  i:integer;
begin
  if apath=nil then exit(0);

  for i:=0 to FDirCount-1 do
  begin
    if not IsDirDeleted(i) then
    begin
      if CompareWide(Dirs[i].Name,apath)=0 then
        exit(i);
    end;
  end;

  result:=-1;
end;

function TRGDirList.SearchPath(apath:PUnicodeChar):integer; inline;
begin
  if apath=nil then exit(0);
  result:=DoSearchPath(PUnicodeChar(TransformPath(apath)));
end;

function TRGDirList.SearchPath(const apath:AnsiString):integer; inline;
begin
  if apath='' then exit(0);
  result:=DoSearchPath(PUnicodeChar(TransformPath(apath)));
end;

function TRGDirList.DoSearch(adir:integer; aname:PUnicodeChar):integer;
begin
  if (aname<>nil) and (aname^<>#0) and
     not IsDirDeleted(adir) then
  begin
    if GetFirstFile(result,adir) then
      repeat
        if CompareWide(Files[result]^.Name,aname)=0 then exit;
      until not GetNextFile(result);
  end;

  result:=-1;
end;

function TRGDirList.SearchFile(adir:integer; aname:PUnicodeChar):integer;
var
  p:array [0..255] of UnicodeChar;
  pc:PUnicodeChar;
begin
  if IsDirDeleted(adir) or (aname=nil) then exit(-1);

  if not FCase then
  begin
    pc:=@p;
    while aname^<>#0 do
    begin
      pc^:=FastUpCase(aname^);
      inc(aname);
      inc(pc);
    end;
    pc^:=#0;
    pc:=@p;
  end
  else
    pc:=aname;

  result:=DoSearch(adir,pc);
end;

function TRGDirList.SearchFile(apath:PUnicodeChar):integer;
var
  lpath,lname:UnicodeString;
  llen:integer;
begin
  llen:=Length(apath);
  if llen=0 then exit(-1);

  if apath[llen-1]='/' then
  begin
    result:=DoSearchPath(PUnicodeChar(TransformPath(apath)));
    if result>=0 then
      result:=AsFile(result);
  end
  else
  begin
    lname:=UnicodeString(apath);
    if not FCase then lname:=UpCase(lname); //!!
    lpath:=ExtractPath(lname);

    result:=DoSearchPath(pointer(lpath));
    if result>=0 then
      result:=DoSearch(result, @PUnicodeChar(lname)[Length(lpath)]);
  end;
end;

function TRGDirList.SearchFile(const apath:AnsiString):integer;
var
  lpath,lname:UnicodeString;
begin
  if apath='' then exit(-1);

  if apath[Length(apath)]='/' then
  begin
    result:=DoSearchPath(PUnicodeChar(TransformPath(apath)));
    if result>=0 then
      result:=AsFile(result);
  end
  else
  begin
    lname:=UnicodeString(apath);
    if not FCase then lname:=UpCase(lname); //!!
    lpath:=ExtractPath(lname);

    result:=DoSearchPath(pointer(lpath));
    if result>=0 then
      result:=DoSearch(result, @PUnicodeChar(lname)[Length(lpath)]);
  end;
end;

function TRGDirList.SearchFile(apath,aname:PUnicodeChar):integer;
begin
  if apath=nil then
    result:=0
  else
    result:=SearchPath(apath);
  if result>=0 then
    result:=SearchFile(result,aname);
end;

function TRGDirList.IsNameExists(adir:integer; const aname:AnsiString):integer;
var
  lname,liname:PWideChar;
  lfile,llen,lilen:integer;
begin
  result:=-1;
  if (aname='') or IsDirDeleted(adir) then exit;

  llen:=Length(aname);
  if FCase then
    lname:=FastStrToWide(aname)
  else
    lname:=FastStrToWide(UpCase(aname));
  if lname[llen-1]='/' then
  begin
    dec(llen);
    lname[llen]:=#0;
  end;

  if GetFirstFile(lfile,adir) then
  begin
    repeat
      with Files[lfile]^ do
      begin
        lilen :=NameLen;
        liname:=Name;
      end;
      if (lilen=llen) or (((lilen-1)=llen) and (liname[llen]='/')) then
        if CompareWide(lname,liname,llen)=0 then
        begin
          result:=lfile;
          break;
        end;
    until not GetNextFile(lfile);
  end;
  FreeMem(lname);
end;

{%ENDREGION Search}

{%REGION Move}

function TRGDirList.MoveFile(aidx:integer; adir:integer):integer;
begin
  result:=AddFile(adir,Files[aidx]^.Name);
  if result>=0 then
    DeleteFile(aidx);
end;

function TRGDirList.MoveFile(aidx:integer; apath:PUnicodeChar):integer;
var
  ldir:integer;
begin
  ldir:=SearchPath(apath);
  if ldir>=0 then
    result:=MoveFile(aidx,ldir)
  else
    result:=-1;
end;
(*
function TRGDirList.MoveDir(adir:integer; adst:integer):integer;
begin
  // SearchFile dst name
  // if not exists, add file to parent and remove old, rename all children dirs
  // if exists... try to move all children to dst, rename all children dirs
  // if exists empty then delete old. if moving empty then ignore
  // else: fast. [dst.last].next:=src.first; dst.last=src.last
  // else: slow. check ALL files and subs
  if adst>=0 then
    result:=MoveDir(adir,adst)
  else
    result:=-1;
end;

function TRGDirList.MoveDir(adir:integer; adst:PUnicodeChar):integer;
var
  ldir:integer;
begin
  ldir:=SearchPath(adst); // AddPath(adst);
  if ldir>=0 then
    result:=MoveDir(adir,ldir)
  else
    result:=-1;
end;
*)

{%ENDREGION Move}

{%REGION Add}
function TRGDirList.AppendFile(adir:integer; aname:PUnicodeChar):integer;
var
  lrec:PBaseFileInfo;
  p:array [0..255] of UnicodeChar;
  pc:PUnicodeChar;
  i:integer;
begin
  result:=-1;
  if adir<0 then exit;
  if FDirCount=0 then AppendDir(nil);
  if adir>=FDirCount then exit;

  // Get from deleted or append
  if FFileDelFirst>=0 then
  begin
    result:=FFileDelFirst;
    FFileDelFirst:=Files[result]^.next;
  end
  else
  begin
    if FFileCount=GetFilesCapacity() then
    begin
      if FFileCount=0 then
        SetFilesCapacity(incFBase)
      else
        SetFilesCapacity(FFileCount+incFFile);
    end;

    result:=FFileCount;
    inc(FFileCount);
  end;

  // links
  i:=Dirs[adir].last;
  if i>=0 then
    Files[i]^.next:=result
  else
    Dirs[adir].first:=result;

  Dirs[adir].last:=result;
  inc(Dirs[adir].count);

  // data
  lrec:=Files[result];
  FillChar(lrec^,FInfoSize,0); // requires for case of "deleted" cell
  if (aname=nil) or (aname^=#0) then
    lrec^.Name:=nil
  else
  begin
    if not FCase then
    begin
      pc:=@p;
      while aname^<>#0 do
      begin
        pc^:=FastUpCase(aname^);
        inc(aname);
        inc(pc);
      end;
      pc^:=#0;
      lrec^.Name:=@p;
    end
    else
      lrec^.Name:=aname;
  end;

  lrec^.next  :=-1;
  lrec^.parent:=adir;

  inc(total);
end;

procedure InitDirElement(var adir:TDirInfo; apath:PUnicodeChar);
begin
  adir.count:=0;
  adir.first:=-1;
  adir.last :=-1;
  adir.index:=-1;
  adir.Name :=apath;
end;

function TRGDirList.AppendDir(apath:PUnicodeChar):integer;
begin
  // Check for first allocation. It have empty name ALWAYS
  if GetDirsCapacity()=0 then
    SetDirsCapacity(incEBase);
  if FDirCount=0 then
  begin
    InitDirElement(Dirs[0],nil);
    FDirCount:=1;
    inc(total);
  end;

  if (apath=nil) or (apath^=#0) then exit(0);

  // Get from deleted or append
  if FDirDelFirst>0 then
  begin
    result:=FDirDelFirst;
    FDirDelFirst:=Dirs[result].last; // use field "last" for next deleted entry
  end
  else
  begin
    result:=FDirCount;
    if FDirCount=GetDirsCapacity() then
      SetDirsCapacity(FDirCount+incEntry);
    inc(FDirCount);
  end;

  InitDirElement(Dirs[result],apath);
  inc(total);
end;


function TRGDirList.DoAddFile(adir:integer; aname:PUnicodeChar):integer;
begin
  result:=SearchFile(adir,aname);
  if result<0 then
    result:=AppendFile(adir,aname);
end;

function TRGDirList.DoAddFile(apath:PUnicodeChar):integer;
var
  lpath:UnicodeString;
begin
  if apath<>nil then
  begin
    lpath:=ExtractPath(apath);
    // can't use AddPath with event
    // coz not sure what will set "source" for Ctrl for example
    result:=DoAddFile(DoAddPath(PUnicodeChar(lpath)), @apath[Length(lpath)]);
  end
  else
    result:=DoAddFile(0,nil);
end;

function TRGDirList.DoAddPath(apath:PUnicodeChar):integer;
var
  lpath:array [0..299] of UnicodeChar;
  lslash,lparent,lfile:integer;
begin
  result:=DoSearchPath(apath);
  if result>=0 then exit;

  // SearchFile dir name start
  lslash:=Length(apath)-2;
  while (lslash>0) and (apath[lslash]<>'/') do dec(lslash);

  // add parent dir
  if lslash>0 then
  begin
    inc(lslash);
    move(apath^,lpath[0],lslash*SizeOf(UnicodeChar));
    lpath[lslash]:=#0;
    lparent:=DoAddPath(lpath);
  end
  else
    lparent:=0;

  result:=AppendDir(apath);

  lfile:=DoAddFile(lparent, apath+lslash);
  Dirs[result].index:=lfile;
  with Files[lfile]^ do
  begin
    index:=result;
    ftype:=typeDirectory;
  end;
end;

function TRGDirList.DoAddDir(adir:integer; aname:PUnicodeChar):integer;
var
  pc:PUnicodeChar;
  lfile:integer;
begin
  pc:=ConcatWide(Dirs[adir].Name,aname);
  result:=DoSearchPath(pc);
  if result<0 then
  begin
    result:=AppendDir(pc);

    lfile:=DoAddFile(adir, aname);
    Dirs[result].index:=lfile;
    with Files[lfile]^ do
    begin
      index:=result;
      ftype:=typeDirectory;
    end;
  end;
  FreeMem(pc);
end;


function TRGDirList.AddFile(adir:integer; aname:PUnicodeChar):integer;
var
  lcnt:integer;
begin
  lcnt:=total;
  result:=DoAddFile(adir,aname);
  if total>lcnt then OnChange(@self,result,faAdd);
end;

function TRGDirList.AddFile(apath:PUnicodeChar; aname:PUnicodeChar):integer;
begin
  result:=AddFile(AddPath(apath),aname);
end;

function TRGDirList.AddFile(apath:PUnicodeChar):integer;
var
  lcnt:integer;
begin
  lcnt:=total;
  result:=DoAddFile(apath);
  if total>lcnt then OnChange(@self,result,faAdd);
end;

function TRGDirList.AddDir(adir:integer; aname:PUnicodeChar):integer;
var
  lcnt:integer;
begin
  lcnt:=total;
  result:=DoAddDir(adir,aname);
  if total>lcnt then OnChange(@self,result,faAdd);
end;

function TRGDirList.AddPath(apath:PUnicodeChar):integer;
var
  lcnt:integer;
begin
  if (apath=nil) or (apath^=#0) then exit(AppendDir(nil));

  lcnt:=total;
  result:=DoAddPath(PUnicodeChar(TransformPath(apath)));
  if total>lcnt then OnChange(@self,AsFile(result),faAdd);
end;

function TRGDirList.AddPath(const apath:AnsiString):integer;
var
  lcnt:integer;
begin
  if apath='' then exit(AppendDir(nil));

  lcnt:=total;
  result:=DoAddPath(PUnicodeChar(TransformPath(apath)));
  if total>lcnt then OnChange(@self,AsFile(result),faAdd);
end;

{%ENDREGION Add}

{%REGION Rename}

function TRGDirList.DoRenameFile(aidx:integer; aname:PUnicodeChar):boolean;
var
  ldir,lidx:integer;
begin
  // check for existing file with same name
  ldir:=Files[aidx]^.parent;
  lidx:=SearchFile(ldir, aname);
  // here time to ask, rewrite or not
  if lidx<0 then
  begin
    Files[aidx]^.Name:=aname;
    result:=true;
  end
  else
    result:=false;
end;

function TRGDirList.DoRename(aidx:integer; aname:PUnicodeChar):boolean;
var
  lnew:UnicodeString;
  lold,lname:PUnicodeChar;
  i,llen:integer;
  lisdir:boolean;
begin
  result:=false;

  lisdir:=IsDir(aidx);
  llen:=Length(aname);

  SetLength(lnew,llen+1);
  for i:=1 to llen do
  begin
    if FCase then lnew[i]:=aname^
    else lnew[i]:=FastUpCase(aname^);
    inc(aname);
  end;
  if lisdir then
  begin
    if lnew[llen]<>'/' then
    begin
      inc(llen);
      lnew[llen]:='/';
    end;
  end
  else
  begin
    if lnew[llen]='/' then
      dec(llen);
  end;
  SetLength(lnew,llen);

  if DoRenameFile(aidx,PUnicodeChar(lnew)) then
  begin
    result:=true;
    if lisdir then
    begin
      with Dirs[AsDir(aidx)] do
      begin
        lold:=Name;
        llen:=NameLen;
      end;
      lnew:=UnicodeString(PathOfFile(aidx))+lnew;

      // rename children
      for i:=0 to FDirCount-1 do
      begin
        if not IsDirDeleted(i) then
        begin
          lname:=Dirs[i].Name;
          if CompareWide(PUnicodeChar(lold),lname,llen)=0 then
            Dirs[i].Name:=PUnicodeChar(lnew+Copy(lname,llen+1));
        end;
      end;
    end;
  end;
end;

function TRGDirList.Rename(aidx:integer; aname:PUnicodeChar):boolean;
begin
  result:=DoRename(aidx,aname);
  if result then
    OnChange(@self,aidx,faRename);
end;

function TRGDirList.Rename(const apath, aname:AnsiString):boolean;
var
  pc:PUnicodeChar;
  lidx:integer;
begin
  lidx:=SearchFile(apath);
  if lidx>=0 then
  begin
    pc:=FastStrToWide(aname);
    result:=DoRename(lidx,pc);
    FreeMem(pc);
    if result then
      OnChange(@self,lidx,faRename);
  end;
end;

function TRGDirList.Rename(adir:integer; oldname, newname:PUnicodeChar):boolean; inline;
begin
  result:=Rename(SearchFile(adir,oldname),newname);
end;

{%ENDREGION Rename}

{%REGION Delete}

procedure TRGDirList.DeleteFileRec(aidx:integer);
begin
  with Files[aidx]^ do
  begin
    Name:='';
    next:=FFileDelFirst;
  end;
  FFileDelFirst:=aidx;
  dec(total);
end;

procedure TRGDirList.DeleteDir(adir:integer);
var
  lidx,ldel:integer;
begin
  if adir>0 then
  begin
    if GetFirstFile(lidx,adir) then
    begin
      repeat
        ldel:=lidx;
        GetNextFile(lidx);

        if isDir(ldel) then
          DeleteDir(asDir(ldel));

        DeleteFileRec(ldel);
      until lidx<0;
    end;

    // move from dir list to deleted dir list
    Dirs[adir].Name:='';
    Dirs[adir].last :=FDirDelFirst;
    FDirDelFirst:=adir;
    dec(total);
  end;
end;

procedure TRGDirList.DeleteFile(aidx:integer);
var
  p:PBaseFileInfo;
  ldir,prev,lidx:integer;
begin
  if IsFileDeleted(aidx) then exit;

  ldir:=Files[aidx]^.parent; // ldir:=FileDir(aidx)

  if GetFirstFile(lidx,ldir) then
  begin
    prev:=-1;
    repeat
      if lidx=aidx then
      begin
        OnChange(@self,aidx,faDeleting);

        p:=Files[aidx];

        dec(Dirs[ldir].count);

        // cut the deleting
        if prev>=0 then
          Files[prev]^.next:=p^.next
        else
          Dirs[ldir].first:=p^.next;

        if Dirs[ldir].last=aidx then
          Dirs[ldir].last:=prev;

        if IsDir(aidx) then
          DeleteDir(AsDir(aidx));

        DeleteFileRec(aidx);

        OnChange(@self,aidx,faDeleted);

        break;
      end;

      prev:=lidx;
    until not GetNextFile(lidx);
  end;
end;

procedure TRGDirList.DeleteFile(adir:integer; aname:PUnicodeChar); inline;
begin
  DeleteFile(SearchFile(adir,aname));
end;

procedure TRGDirList.DeleteFile(apath,aname:PUnicodeChar); inline;
begin
  DeleteFile(SearchFile(apath,aname));
end;

procedure TRGDirList.DeletePath(adir:integer); inline;
begin
  if not IsDirDeleted(adir) then
    DeleteFile(AsFile(adir));
end;

procedure TRGDirList.DeletePath(apath:PUnicodeChar); inline;
begin
  DeletePath(SearchPath(apath));
end;

procedure TRGDirList.DeletePath(const apath:AnsiString); inline;
begin
  DeletePath(SearchPath(apath));
end;

{%ENDREGION Delete}

procedure TRGDirList.CopyFileInfo(afrom,ato:PFileInfo);
begin
  ato^.size    :=afrom^.size;
  ato^.ftime   :=afrom^.ftime;
  ato^.checksum:=afrom^.checksum;
end;


function CheckFName(const adir,aname:UnicodeString):UnicodeString;
var
  lext:array [0..15] of UnicodeChar;
  lname:UnicodeString;
  lextpos,j,k:integer;
begin
  lextpos:=Length(aname);
  if aname[lextpos]='/' then
    exit(aname);

  result:='';
  
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
      lext[k]:=FastUpCase(aname[j]);
      inc(k);
    end;
  lext[k]:=#0;

  if (CompareWide(lext,'.TXT'      )=0) or
     (CompareWide(lext,'.BINDAT'   )=0) or
     (CompareWide(lext,'.BINLAYOUT')=0) or
     (CompareWide(lext,'.CMP'      )=0) or
     (CompareWide(lext,'.ADM'      )=0) then
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
  if RGTypeOfExt(PUnicodeChar(lname))<>typeUnknown then
    result:=lname;
end;

procedure CopyInfo(afrom, ato:PFileInfo);
begin
  ato^.SameNameAs(afrom);
  ato^.size    :=afrom^.size;
  ato^.ftime   :=afrom^.ftime;
  ato^.checksum:=afrom^.checksum;
  ato^._ftype  :=afrom^._ftype;
end;


initialization

  names.Init(false);

finalization

  names.Clear;

end.
