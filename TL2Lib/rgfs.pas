{
  Tree-like directory+files structure
  have dir-only array with full paths, xref with tree nodes
  one list with file/dir records
  global text cache
}
{TODO: make Names text cache NOT global. But FileInfo is not part of DirList}
{TODO: remove "total" changes/saving coz total = DirCount+FileCount (except deleted)}
{TODO: implement Files.data=Dir index for dirs}
{TODO: check all variant of AddPath/AddFile what we uses (i.e. PUnicodeChar, string...}
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
  public
    procedure SameNameAs(afi:PBaseInfo);
    function  IsSameName(afi:PBaseInfo):boolean;

    property Name   :PUnicodeChar read GetFileName write SetFileName;
    property NameLen:integer      read GetFileNameLen;
  end;

type
  PFileInfo = ^TFileInfo;
  TFileInfo = object(TBaseInfo)
  private
    parent:integer;     // parent dir index
    next  :integer;     // next file in current directory
  public
    ftime   :UInt64;    // MAN: TL2 only
    checksum:dword;     // MAN: CRC32
  end;

type
  PDirInfo = ^TDirInfo;
  TDirInfo = object(TBaseInfo)
    count,              // count of child files and dirs (from first to last)
    first,
    last :integer;
    index:integer;      // Index of Files array for this dir
  end;
  TDirEntries = array of TDirInfo;

type
  PRGDirList = ^TRGDirList;
  TRGDirList = object
  private
    FDirCount    :integer; // total count of Entries
    FDirDelFirst :integer; // first deleted Entry index. 0, if unknown
    FFileCount   :integer; // total count of file records
    FFileDelFirst:integer; // first index of deleted files
  private
    FModified :boolean;
    FFiles :PByte;
    FCapacity:integer;
    FInfoSize:integer;

  private
    function  GetFilesCapacity():integer;
    procedure SetFilesCapacity(acnt:integer);
    function  GetDirsCapacity():integer;
    procedure SetDirsCapacity(acnt:integer);

    function GetHash(idx:integer):dword;

    function GetFileInfoPtr(idx:integer):PFileInfo;

    // Add dirs with full path (with parents if needs)
    function  DoAddPath   (apath:PWideChar):integer;
    procedure DoDeletePath(apath:PWideChar);
    procedure DeleteDir    (adir:integer);

    function  SearchPathNorm(apath:PUnicodeChar):integer;
    procedure DeleteFileRec(aidx:integer);

  //--- PUBLIC area ---

  // Base
  public
    procedure Init(aInfoSize:integer=SizeOf(TFileInfo));
    procedure Clear;
    procedure Free;
    // Set Dir array "index" field to proper Files array element number
    // like cycle of AsDir for all dir-describing Files elements
    procedure Link;

  public
    function SearchPath(apath:PUnicodeChar):integer;
    function SearchPath(const apath:string):integer;

    function SearchFile(adir:integer; aname:PUnicodeChar):integer;
    function SearchFile(apath,aname:PUnicodeChar):integer;
    function SearchFile(const fname:string):integer;

    // result=0 means "end"
    function GetFirstFile(out p:pointer; adir:integer):integer;
    function GetNextFile (var p:pointer):integer;

    function GetFirstFile(out idx:integer; adir:integer):boolean;
    function GetNextFile (var idx:integer):boolean;

  // Change info
  public
    //!! no check for "dir" name
    function  AppendFile(adir:integer; aname:PUnicodeChar):integer;
    {
      Add File record after check for existing
    }
    function  AddFile  (adir:integer; aname:PUnicodeChar):integer;
    function  CloneFile(adir:integer; afile:PFileInfo   ):integer;
    {
      Add File record with path creation
    }
    function  AddFile(apath:PUnicodeChar; aname:PUnicodeChar):integer;
    function  AddFile(apath:PUnicodeChar):integer;

    procedure DeleteFile(aidx:integer);
    procedure DeleteFile(adir:integer; aname:PUnicodeChar);
    procedure DeleteFile(apath,aname:PUnicodeChar);

    procedure MoveFile(aidx:integer; adir :integer);
    procedure MoveFile(aidx:integer; apath:PUnicodeChar);

    // Add dir name to main dir list, no check, !! no parent
    function AppendDir(apath:PUnicodeChar):integer;
    {
      Add dir name to main dir list with UpCase and check for existing
    }
    function AddPath(apath:PUnicodeChar):integer;
    function AddPath(const apath:string):integer;

    procedure DeletePath(adir:integer);
    procedure DeletePath(apath:PUnicodeChar);
    procedure DeletePath(const apath:string);

    function RenameDir(const apath, oldname, newname:PUnicodeChar):integer;
    function RenameDir(const apath, newname:string):integer;

    //!!! DO NOT USE (not reay yet)
//    function MoveDir(adir:integer; adst:integer):integer;
//    function MoveDir(adir:integer; adst:PUnicodeChar):integer;

  // Properties
  public
    Dirs:TDirEntries;
    total:integer;         // total "file" elements. Can be calculated when needs

    property DirCount   :integer read FDirCount;
    property DirCapacity:integer read GetDirsCapacity write SetDirsCapacity;

    function IsDirDeleted (adir:integer):boolean;
    function IsFileDeleted(aidx:integer):boolean;
    // check what File record is for dir
    function IsDir        (aidx:integer):boolean;
    function PathOfFile   (aidx:integer):PWideChar;
    // get Dir array index with idx-ed file
    function FileDir      (aidx:integer):integer;
    // get Dir array index of idx-ed file (if idx-ed file is directory)
    function AsDir        (aidx:integer):integer;
    // get File array index from Dir list index
    function AsFile       (adir:integer):integer;
    // like GetFileName (just with trailing slash ignoring)
    function DirName      (adir:integer):PWideChar;
    function IndexOf(p:pointer):integer;

    property FileCapacity:integer read GetFilesCapacity write SetFilesCapacity;
    property FileCount   :integer read FFileCount;
    property Files[idx:integer]:PFileInfo read GetFileInfoPtr;

  // Properties runtime
  public
    property Modified:boolean read FModified;
  end;


implementation

uses
  sysutils,
  TextCache,
  rgglobal;

const
  MidFNameLen = 48; // middle file name length for buffer reserve
var
  Names:TTextCache;

const
  incEBase = 512;
  incEntry = 256;
  incFBase = 128;
  incFFile = 16;

{%REGION Support}

// Upper case, no starting slashes but with ending
function TransformPath(const apath:string):UnicodeString;
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
    if apath[i]='\' then
      result[j]:='/'
    else
      result[j]:=UnicodeChar(ORD(UpCase(apath[i])));
    inc(i);
    inc(j);
  end;

  if result[lrsize]<>'/' then result[lrsize]:='/';
end;

// Upper case, no starting slashes but with ending
function TransformPath(apath:PUnicodeChar):UnicodeString;
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
    if apath[i]='\' then
      result[j]:='/'
    else
      result[j]:=FastUpCase(apath[i]);
    inc(i);
    inc(j);
  end;

  if result[lrsize]<>'/' then result[lrsize]:='/';
end;

function SetName(aname:PUnicodeChar):integer; inline;
begin
  result:=names.Add(aname);
end;

function GetName(idx:integer):PUnicodeChar; inline;
begin
  result:=PUnicodeChar(names[idx]);
end;


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

function TRGDirList.IsDir(aidx:integer):boolean;
var
  p:PUnicodeChar;
begin
  with Files[aidx]^ do
  begin
    p:=Name;
    result:=(p<>nil) and (p[NameLen-1]='/');
  end;
end;

function TRGDirList.IsDirDeleted(adir:integer):boolean; inline;
begin
  result:=(adir<>0) and (Dirs[adir].Name=nil);
end;

function TRGDirList.IsFileDeleted(aidx:integer):boolean; inline;
begin
  result:=Files[aidx]^.Name=nil;
end;

function TRGDirList.PathOfFile(aidx:integer):PWideChar; inline;
begin
  result:=Dirs[Files[aidx]^.parent].Name;
end;

function TRGDirList.FileDir(aidx:integer):integer; inline;
begin
  result:=Files[aidx]^.parent;
end;

function TRGDirList.AsDir(aidx:integer):integer;
var
  lp:PUnicodeChar;
begin
  lp:=ConcatWide(PathOfFile(aidx), Files[aidx]^.Name);
  result:=SearchPathNorm(lp);
  FreeMem(lp);
end;

function TRGDirList.AsFile(adir:integer):integer;
var
  lpath:PUnicodeChar;
  lslash,ldir:integer;
  c:UnicodeChar;
begin
// if files "data" set to index, can be done by cycle, else...
// search parent path and "file" name
  lpath:=Dirs[adir].Name;
  if lpath=nil then exit(-1);

  lslash:=Length(lpath)-2;
  while (lslash>0) and (lpath[lslash]<>'/') do dec(lslash);

  if lslash>0 then
  begin
    inc(lslash);
    c:=lpath[lslash];
    lpath[lslash]:=#0;
    ldir:=SearchPathNorm(lpath);
    lpath:=lpath+lslash;
    lpath^:=c;
  end
  else
    ldir:=0;

  result:=SearchFile(ldir,lpath);
end;

function TRGDirList.DirName(adir:integer):PWideChar;
var
  lpath:PWideChar;
  lslash:integer;
begin
//  result:=Files[Dirs[adir].index]^.Name;

  lpath:=Dirs[adir].Name;
  if lpath=nil then exit(nil);

  lslash:=Length(lpath)-2;
  while (lslash>0) and (lpath[lslash]<>'/') do dec(lslash);

  if lslash>0 then
    result:=lpath+lslash+1
  else
    result:=lpath;
end;

function TRGDirList.IndexOf(p:pointer):integer; inline;
//var i:integer;
begin
{
  for i:=1 to FileCount-1 do
    if Files[i]=p then exit(i);
  exit(0);
}
  result:=UIntPtr(PByte(p)-PByte(FFiles)) div SizeOf(FInfoSize);
end;
{%ENDREGION Support}

{%REGION Getters/Setters}
function TRGDirList.GetFileInfoPtr(idx:integer):PFileInfo;
begin
  if (idx>=0) and (idx<FFileCount) then
    result:=PFileInfo(FFiles+idx*FInfoSize)
  else
    result:=nil;
end;

function TRGDirList.GetHash(idx:integer):dword; inline;
begin
  result:=names.hash[idx];
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
  result:=Dirs[adir].first;
  if result>=0 then p:=Files[result];
  inc(result);
end;

function TRGDirList.GetNextFile(var p:pointer):integer;
begin
  result:=PFileInfo(p)^.next;
  if result>=0 then p:=Files[result];
  inc(result);
end;

function TRGDirList.GetFirstFile(out idx:integer; adir:integer):boolean;
begin
  if adir<0 then exit(false);

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
  p:PFileInfo;
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

      ldir:=SearchPathNorm(@buf[0]);
      if ldir>=0 then
      begin
        Dirs [ldir].index:=i;
//        Files[i   ].data :=pointer(ldir);
      end;
    end;
  end;
end;

{%ENDREGION Common}

{%REGION Main}
procedure TRGDirList.Init(aInfoSize:integer=SizeOf(TFileInfo));
begin
  FillChar(self,SizeOf(self),0);

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
function TRGDirList.SearchPathNorm(apath:PUnicodeChar):integer;
var
  i:integer;
begin
  for i:=0 to FDirCount-1 do
  begin
    if not IsDirDeleted(i) then
      if CompareWide(Dirs[i].Name,apath)=0 then
        exit(i);
  end;

  result:=-1;
end;

function TRGDirList.SearchPath(apath:PUnicodeChar):integer;
begin
  result:=SearchPathNorm(PUnicodeChar(TransformPath(apath)));
end;

function TRGDirList.SearchPath(const apath:string):integer;
begin
  result:=SearchPathNorm(PUnicodeChar(TransformPath(apath)));
end;

function TRGDirList.SearchFile(adir:integer; aname:PUnicodeChar):integer;
var
  p:array [0..255] of WideChar;
  pc:PUnicodeChar;
begin
  if (aname<>nil) and (aname^<>#0) and
     (adir>=0) and (adir<FDirCount) then
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

    if GetFirstFile(result,adir) then
      repeat
        if CompareWide(Files[result]^.Name,pc)=0 then exit;
      until not GetNextFile(result);
  end;
  
  result:=-1;
end;

function TRGDirList.SearchFile(apath,aname:PUnicodeChar):integer;
begin
  result:=SearchFile(SearchPath(apath),aname);
end;

function TRGDirList.SearchFile(const fname:string):integer;
var
  lpath,lname:UnicodeString;
begin
  lname:=UnicodeString(fname);
  lpath:=ExtractPath(lname);
  lname:=ExtractName(lname); // copy(lname,Length(lpath)+1); Delete(lname,1,Length(lpath));

  result:=SearchFile(pointer(lpath),pointer(lname));
end;
{%ENDREGION Search}

{%REGION File}
  {%REGION Add}
function TRGDirList.AppendFile(adir:integer; aname:PUnicodeChar):integer;
var
  lrec:PFileInfo;
  p:array [0..255] of WideChar;
  pc:PUnicodeChar;
  i:integer;
begin
  //!!
  if adir<0 then exit(-1);
  if FDirCount=0 then AppendDir(nil);

  // Get deleted or append
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
      begin
        SetFilesCapacity(incFBase);
{
        FFileCount:=1;               // MUST BE before Files[] using
        lrec:=Files[0];
        FillChar(lrec^,FInfoSize,0); // if ReallocMem used, it clear memory already
        lrec^.Name  :='';
        lrec^.next  :=-1;
        lrec^.parent:=-1;
}
      end
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
    pc:=@p;
    while aname^<>#0 do
    begin
      pc^:=FastUpCase(aname^);
      inc(aname);
      inc(pc);
    end;
    pc^:=#0;
    lrec^.Name:=@p{aname};
  end;

  lrec^.next  :=-1;
  lrec^.parent:=adir;

  inc(total);
end;

function TRGDirList.AddFile(adir:integer; aname:PUnicodeChar):integer;
begin
  result:=SearchFile(adir,aname);
  if result<0 then
    result:=AppendFile(adir,aname);
end;

function TRGDirList.AddFile(apath:PUnicodeChar; aname:PUnicodeChar):integer;
begin
  result:=AddFile(AddPath(apath),aname);
end;

function TRGDirList.AddFile(apath:PUnicodeChar):integer;
begin
  result:=AddFile(PUnicodeChar(ExtractPath(apath)),PUnicodeChar(ExtractName(apath)));
end;

function TRGDirList.CloneFile(adir:integer; afile:PFileInfo):integer;
begin
  // not search for empty name anyway
  result:=AppendFile(adir,''{afile^.Name});
  // can't use move(afile^,Files[result]^,FInfoSize);
  // coz afile and new can be different types
  // can't use assign coz it will copy "parent" and "next" fields too

  with Files[result]^ do
  begin
    fname   :=afile^.fname;
    ftime   :=afile^.ftime;
    checksum:=afile^.checksum;
  end;

end;
  {%ENDREGION Add}

  {%REGION Delete}
procedure TRGDirList.DeleteFileRec(aidx:integer);
begin
{!!
  if IsDir(aidx) then
  begin
    DeleteDir(Files[aidx]^.data);
  end;
}
  with Files[aidx]^ do
  begin
    Name:='';
    next:=FFileDelFirst;
//    FreeMem(data);
  end;
  FFileDelFirst:=aidx;
  dec(total);
end;

procedure TRGDirList.DeleteFile(aidx:integer);
var
  p:PFileInfo;
  ldir,prev,lidx:integer;
begin
  if aidx<0 then exit;

  ldir:=Files[aidx]^.parent;

  if GetFirstFile(lidx,ldir) then
  begin
    prev:=-1;
    repeat
      if lidx=aidx then
      begin
        p:=Files[lidx];

        dec(Dirs[ldir].count);

        // cut the deleting
        if prev>=0 then
          Files[prev]^.next:=p^.next
        else
          Dirs[ldir].first:=p^.next;

        if Dirs[ldir].last=lidx then
          Dirs[ldir].last:=prev;

        DeleteFileRec(lidx);
        break;
      end;

      prev:=lidx;
    until not GetNextFile(lidx);
  end;
end;

procedure TRGDirList.DeleteFile(adir:integer; aname:PUnicodeChar); inline;
begin
  // yes, 2 times cycle through dir files, to search index and to delete
  // less code, more time
  DeleteFile(SearchFile(adir,aname));
end;

procedure TRGDirList.DeleteFile(apath,aname:PUnicodeChar); inline;
begin
  DeleteFile(SearchPath(apath),aname);
end;
  {%ENDREGION Delete}

procedure TRGDirList.MoveFile(aidx:integer; adir :integer);
begin
  CloneFile(adir,Files[aidx]);
  DeleteFile(aidx);
end;

procedure TRGDirList.MoveFile(aidx:integer; apath:PUnicodeChar);
var
  ldir:integer;
begin
  ldir:=SearchPath(apath);
  if ldir>=0 then
    MoveFile(aidx,ldir);
end;

{%ENDREGION File}

{%REGION Entry}
  {%REGION Add}
function TRGDirList.AppendDir(apath:PUnicodeChar):integer;
begin
  // Check for first allocation. It have empty name ALWAYS
  if GetDirsCapacity()=0 then
    SetDirsCapacity(incEBase);
  if FDirCount=0 then
  begin
    Dirs[0].Name :='';
    Dirs[0].count:=0;
    Dirs[0].first:=-1;
    Dirs[0].last :=-1;
    Dirs[0].index:=-1;

    FDirCount:=1;
    inc(total);
  end;

  if (apath=nil) or (apath^=#0) then exit(0);

  // search for empty place in the middle
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

  Dirs[result].count:=0;
  Dirs[result].first:=-1;
  Dirs[result].last :=-1;
  Dirs[result].index:=-1;
  Dirs[result].Name :=apath;

  inc(total);
end;

// path going as caps, no starting "/", with finishing "/" already
function TRGDirList.DoAddPath(apath:PWideChar):integer;
var
  lslash{,lparentdir,ldir}:integer;
  lc:WideChar;
begin
  // if exists already
  result:=SearchPathNorm(apath);
  if result>=0 then exit;

  // search dir name start
  lslash:=Length(apath)-2;
  while (lslash>0) and (apath[lslash]<>'/') do dec(lslash);

  // add parent dir
  if lslash>0 then
  begin
    lc:=apath[lslash+1];
    apath[lslash+1]:=#0; // "cut" text AFTER "/"
    {lparentdir:=}DoAddPath(apath);
    apath[lslash+1]:=lc;
  end
;//  else lparentdir:=0;

  result:=AppendDir(apath);
{!!
  ldir:=AppendFile(lparentdir,PUnicodeChar(apath)+lslash);
  Files[ldir]^.data:=result;

  Dirs[result].index :=ldir;
}
end;

function TRGDirList.AddPath(apath:PUnicodeChar):integer;
begin
  if (apath=nil) or (apath^=#0) then exit(AppendDir(nil));
  
  result:=DoAddPath(PWideChar(TransformPath(apath)));
end;

function TRGDirList.AddPath(const apath:string):integer;
begin
  if apath='' then exit(AppendDir(nil));

  result:=DoAddPath(PWideChar(TransformPath(apath)));
end;
  {%ENDREGION Add}

  {%REGION Delete}
procedure TRGDirList.DeleteDir(adir:integer);
var
  lidx,ldel:integer;
begin
  if adir>0 then
  begin
    // clear dir: no search, no shifts, just 1 by 1
    if GetFirstFile(lidx,adir) then
    begin
      repeat
        ldel:=lidx;
        if not GetNextFile(lidx) then break;
        if isDir(ldel) then
          DeletePath(asDir(ldel))
        else
          DeleteFileRec(ldel);
      until false;
      if isDir(ldel) then
        DeletePath(asDir(ldel))
      else
        DeleteFileRec(ldel);
    end;

    // move from dir list to deleted dir list
    Dirs[adir].Name:='';
    Dirs[adir].last :=FDirDelFirst;
    FDirDelFirst:=adir;
    dec(total);
  end;
end;

// path going as caps, no starting "/", with finishing "/" already
procedure TRGDirList.DeletePath(adir:integer);
var
  lpath:PWideChar;
  lparent,lslash:integer;
  lc:WideChar;
begin
  if adir>=0 then
  begin
    lpath:=Dirs[adir].Name;

    // search dir name start
    lslash:=Dirs[adir].NameLen-2;
    while (lslash>0) and (lpath[lslash]<>'/') do dec(lslash);

    // delete from parent dir
    if lslash>0 then
    begin
      lc:=lpath[lslash+1];
      lpath[lslash+1]:=#0; // "cut" text AFTER "/"
      lparent:=SearchPath(lpath);
      lpath[lslash+1]:=lc;
      
      DeleteFile(lparent,lpath+lslash+1);
//      DeleteFile(Files[Dirs[i].index]^.parent,PUnicodeChar(apath)+lslash);
//      DeleteFile(PUnicodeChar(Copy(apath,1,lslash)),PUnicodeChar(apath)+lslash);
    end
    else
      DeleteFile(0,lpath);

    // requires till .data will not work
    DeleteDir(adir);

  end;
end;

procedure TRGDirList.DoDeletePath(apath:PWideChar);
begin
  DeletePath(SearchPathNorm(apath));
end;

procedure TRGDirList.DeletePath(apath:PUnicodeChar); inline;
begin
  DoDeletePath(PWideChar(TransformPath(apath)));
end;

procedure TRGDirList.DeletePath(const apath:string); inline;
begin
  DoDeletePath(PWideChar(TransformPath(apath)));
end;
  {%ENDREGION Delete}

  {%REGION Rename}
function TRGDirList.RenameDir(const apath, oldname, newname:PUnicodeChar):integer;
var
  lpath,lold,lnew,loldname:UnicodeString;
  lname:PUnicodeChar;
  p:PFileInfo;
  lfile,ldir,lparent,i,llen:integer;
begin
  result:=0;

  lpath   :=TransformPath(apath);
  loldname:=TransformPath(oldname);
  lold    :=lpath+loldname;

  ldir:=SearchPathNorm(PUnicodeChar(lold));
  if ldir>=0 then
  begin
    lparent:=SearchPathNorm(PUnicodeChar(lpath));
//    lparent:=Files[Dirs[ldir].index]^.parent;            //!!!!!

    // Search if new path exists already
    lnew:=TransformPath(newname);
    lfile:=0;
    if GetFirstFile(i,lparent) then // always (at least, old name)
      repeat
        p:=Files[i];
        if CompareWide(p^.Name,PUnicodeChar(lnew))=0 then exit;
        if CompareWide(p^.Name,PUnicodeChar(loldname))=0 then begin lfile:=i; break; end;
      until not GetNextFile(i);
    
    result:=1;
    // replace old
    Files[lfile]^.Name:=PUnicodeChar(lnew);
//    Files[Dirs[ldir].index]^.Name:=PUnicodeChar(lnew);   //!!!!!
    lnew:=lpath+lnew;
    Dirs[ldir].Name:=PUnicodeChar(lnew);

    llen:=Length(lold);
    // rename children
    for i:=0 to FDirCount-1 do
    begin
      if (i<>lparent) and (i<>ldir) and not IsDirDeleted(i) then
      begin
        lname:=Dirs[i].Name;
        if CompareWide(PUnicodeChar(lold),lname,llen)=0 then
        begin
          Dirs[i].Name:=PUnicodeChar(lnew+Copy(lname,llen+1));
          inc(result);
        end;
      end;
    end;
  end;
end;

function TRGDirList.RenameDir(const apath, newname:string):integer;
var
  lpath,lname,lnew:UnicodeString;
  lslash:integer;
begin
  lpath:=TransformPath(apath);
  lnew:=UnicodeString(newname);
  lslash:=Length(lpath)-1;
  while (lslash>1) and (lpath[lslash]<>'/') do dec(lslash);
  if lslash>1 then
  begin
    lname:=Copy(lpath,lslash+1);
    SetLength(lpath,lslash);
    result:=RenameDir(PUnicodeChar(lpath),PUnicodeChar(lname),PUnicodeChar(lnew));
  end
  else
    result:=RenameDir('',PUnicodeChar(lpath),PUnicodeChar(lnew))
end;
  {%ENDREGION Rename}
(*
function TRGDirList.MoveDir(adir:integer; adst:integer):integer;
begin
  // search dst name
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
{%ENDREGION Entry}

initialization

  names.Init(false);

finalization

  names.Clear;

end.
