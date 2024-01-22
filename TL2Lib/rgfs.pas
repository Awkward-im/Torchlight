UNIT rgfs;

interface

uses
  TextCache,
  rgglobal;


type
  PBaseFileInfo = ^TBaseFileInfo;
  TBaseFileInfo = object
    name    :cardinal;   // TextCache index
    next    :integer;    // next file in current directory
    data    :integer;    // dir: index in DIR list
  end;

type
  PDirEntry = ^TDirEntry;
  TDirEntry = record
    name:cardinal;      // TextCache index
    parent,             // parent dir index
    index,              // index of file record for dir
    count,              // ??count of child files and dirs
    first,
    last:integer;
  end;
  TDirEntries = array of TDirEntry;

type
  PRGManifest = ^TRGManifest;
  TRGManifest = object
  private
    FDirCount    :integer; // total count of Entries
    FDirDelFirst :integer; // first deleted Entry index. 0, if unknown
    FFileCount   :integer; // total count of file records
    FFileDelFirst:integer; // first index of deleted files
  private
    FModified :boolean;
    Names  :TTextCache;
    FFiles :PByte;
    FCapacity:integer;
    FInfoSize:integer;
  public
    Dirs   :TDirEntries;
  public
    // not necessary fields
    total  :integer;        // total "file" elements. Can be calculated when needs
  private
    function  SetName(aname:PUnicodeChar):integer;
    procedure SetDirName(idx:integer; aname:PUnicodeChar);
    function  GetFilesCapacity():integer;
    procedure SetFilesCapacity(acnt:cardinal);
    function  GetDirsCapacity():integer;
    procedure SetDirsCapacity(acnt:cardinal);

    function  IsFileDeleted(idx:integer):boolean; inline;

  private
    // Add file record to Man, no data
    function  AddEntryFile(aentry:integer; aname:PUnicodeChar=nil):integer;
    // Add dir name to main dir list
    function  AddEntryDir (const apath:PUnicodeChar=pointer(-1)):integer;
    // Add dirs with full path (with parents if needs)
    function  DoAddPath   (const apath:UnicodeString):integer;
    procedure DoDeletePath(const apath:UnicodeString);
    procedure DeleteEntry    (aentry:integer);
    procedure DeleteEntryFile(aentry:integer; aname:PUnicodeChar);

    function  GetFileInfoPtr(idx:integer):PBaseFileInfo;

  private
    property Files[idx:integer]:PBaseFileInfo read GetFileInfoPtr;

  // Main
  public
    procedure Init(aInfoSize:integer=SizeOf(TBaseFileInfo));
    procedure Free;

  // Get info
  public
    function SearchPath(apath:PUnicodeChar):integer;
    function SearchFile(aentry:integer; aname:PUnicodeChar):PBaseFileInfo;
    function SearchFile(apath,aname:PUnicodeChar):PBaseFileInfo;
    function SearchFile(const fname:string):PBaseFileInfo;

    function IsDirDeleted(aentry:integer):boolean;

    function GetHash   (idx:integer):PUnicodeChar;
    function GetName   (idx:integer):PUnicodeChar;
    function GetDirName(idx:integer):PUnicodeChar;

    // result<0 means "end"
    function GetFirstFile(out p:pointer; aentry:integer):integer;
    function GetNextFile (var p:pointer):integer;

  // Change info
  public
    function AddPath(apath:PUnicodeChar):integer;
    function AddPath(const apath:string):integer;

    function AddFile(apath,aname:PUnicodeChar):pointer;

    procedure DeletePath(apath:PUnicodeChar);
    procedure DeletePath(const apath:string);
    procedure DeleteFile(apath,aname:PUnicodeChar);

    function RenameDir(const apath, oldname, newname:PUnicodeChar):integer;
    function RenameDir(const apath, newname:string):integer;

  // Properties statistic
  public
    property EntriesCount:integer read FDirCount;
//    property FilesCount  :integer read FFileCount;
//    property Entries  [idx:integer]:PMANDirEntry read GetEntry;
    property DirName[idx:integer]:PUnicodeChar read GetDirName write SetDirName;
//    property FileName[p:PMANFileInfo]:PUnicodeChar read GetFileName;
//    property Files   [aentry:integer; idx:integer]:PMANFileInfo read GetEntryFile;
//    property FileName[aentry:integer; idx:integer]:PunicodeChar read GetFileName;

  // Properties runtime
  public
    property Modified:boolean read FModified;
  end;


implementation

uses
  sysutils;

const
  incEBase = 512;
  incEntry = 256;
  incFBase = 128;
  incFFile = 16;

{%REGION Support}
// Upper case, no starting slashes but with ending
function TransformPath(apath:string):UnicodeString;
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
  if (apath[lsize]<>'\') or (apath[lsize]<>'/') then inc(lrsize);
  SetLength(result,lrsize);

  j:=1;
  while i<=lsize do
  begin
    if apath[i]='\' then
      result[j]:='/'
    else
      result[j]:=UpCase(apath[i]);
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
  if (apath[lsize]<>'\') or (apath[lsize]<>'/') then inc(lrsize);
  SetLength(result,lrsize);

  j:=1;
  while i<=lsize do
  begin
    if apath[i]='\' then
      result[j]:='/'
    else
      result[j]:=UpCase(apath[i]);
    inc(i);
    inc(j);
  end;

  if result[lrsize]<>'/' then result[lrsize]:='/';
end;

function TRGManifest.IsDirDeleted(aentry:integer):boolean; inline;
begin
  result:=Dirs[aentry].name=cardinal(-1);
end;

function TRGManifest.IsFileDeleted(idx:integer):boolean; inline;
begin
  result:=Files[idx]^.name=0;
end;
{%ENDREGION Support}

{%REGION Getters/Setters}
function TRGManifest.GetFileInfoPtr(idx:integer):PBaseFileInfo;
begin
  if (idx>=0) and (idx<FFileCount) then
    result:=PBaseFileInfo(FFiles+idx*FInfoSize)
  else
    result:=nil;
end;

function TRGManifest.SetName(aname:PUnicodeChar):integer; inline;
begin
  result:=names.Append(aname);
end;

function TRGManifest.GetName(idx:integer):PUnicodeChar; inline;
begin
  result:=PUnicodeChar(names[idx]);
end;

function TRGManifest.GetHash(idx:integer):PUnicodeChar; inline;
begin
  result:=PUnicodeChar(names.hash[idx]);
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
  result:=FCapacity;
end;

procedure TRGManifest.SetFilesCapacity(acnt:cardinal);
begin
  if acnt>FCapacity then
  begin
    FCapacity:=acnt;
    ReallocMem(FFiles,FCapacity*FInfoSize);
  end;
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
{%ENDREGION Getters/Setters}

{%REGION Common}
function TRGManifest.GetFirstFile(out p:pointer; aentry:integer):integer;
begin
  result:=Dirs[aentry].first;
  if result>=0 then p:=Files[result];
end;

function TRGManifest.GetNextFile(var p:pointer):integer;
begin
  result:=PBaseFileInfo(p)^.next;
  if result>=0 then p:=Files[result];
end;
{%ENDREGION Common}

{%REGION Main}
procedure TRGManifest.Init(aInfoSize:integer=SizeOf(TBaseFileInfo));
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

  FInfoSize:=aInfoSize;

  FDirDelFirst :=-1;
  FFileDelFirst:=-1;
end;

procedure TRGManifest.Free;
begin
  names.Clear;

  Finalize(Dirs);
  FDirCount:=0;

  FDirDelFirst:=-1;

  FreeMem(FFiles);
  FCapacity:=0;
  FFileCount:=0;
  FFileDelFirst:=-1;
end;
{%ENDREGION Main}

{%REGION Search}
function TRGManifest.SearchPath(apath:PUnicodeChar):integer;
var
  p:UnicodeString;
  i:integer;
begin
  p:=TransformPath(apath);
  for i:=0 to FDirCount-1 do
  begin
    if not IsDirDeleted(i) then
      if CompareWide(GetDirName(i),PUnicodeChar(p))=0 then
        exit(i);
  end;

  result:=-1;
end;

function TRGManifest.SearchFile(aentry:integer; aname:PUnicodeChar):PBaseFileInfo;
var
  p:array [0..255] of WideChar;
  pc:PUnicodeChar;
begin
  if (aentry>=0) and (aentry<FDirCount) then
  begin
    pc:=@p;
    while aname^<>#0 do
    begin
      pc^:=UpCase(aname^);
      inc(aname);
      inc(pc);
    end;
    pc^:=#0;
    pc:=@p;

    if GetFirstFile(result,aentry)<>0 then
      repeat
        if CompareWide(GetName(result^.name),pc)=0 then exit;
      until GetNextFile(result)=0;
  end;
  
  result:=nil;
end;

function TRGManifest.SearchFile(apath,aname:PUnicodeChar):PBaseFileInfo;
begin
  result:=SearchFile(SearchPath(apath),aname);
end;

function TRGManifest.SearchFile(const fname:string):PBaseFileInfo;
var
  lpath,lname:UnicodeString;
begin
  lname:=TransformPath(fname);//UpCase(UnicodeString(fname));
  lpath:=ExtractFilePath(lname);
  lname:=ExtractFileName(lname);

  result:=SearchFile(pointer(lpath),pointer(lname));
end;
{%ENDREGION}

{%REGION File}
  {%REGION Add}
function TRGManifest.AddEntryFile(aentry:integer; aname:PUnicodeChar=nil):integer;
var
  lrec:PBaseFileInfo;
  i,lnew:integer;
begin
  //!!
  if aentry<0 then exit(-1);
{
  // expand if needs
  if FFileCount=0 then
  begin
    SetFilesCapacity(incFBase);
    FFileCount:=1;
  end;
}
  // Get deleted or append
  if FFileDelFirst>=0 then
  begin
    result:=FFileDelFirst;
    FFileDelFirst:=Files[result]^.next;
  end
  else
  begin
    lnew:=FFileCount;

    if FFileCount=GetFilesCapacity() then
    begin
      if FFileCount=0 then
        SetFilesCapacity(incFBase)
      else
        SetFilesCapacity(FFileCount+incFFile);
    end;
    inc(FFileCount);
  end;

  // links
  i:=Dirs[aentry].last;
  if i>=0 then
    Files[i]^.next:=result
  else
    Dirs[aentry].first:=result;

  Dirs[aentry].last:=lnew;
  inc(Dirs[aentry].count);

  // data
  lrec:=Files[result];
  FillChar(lrec^,FInfoSize,0);
  if aname<>nil then
    lrec^.name:=SetName(aname);
  lrec^.next:=-1;

  inc(total);
end;

//  Add file with relative path. requires root dir to get physical file info like time and size
function TRGManifest.AddFile(apath,aname:PUnicodeChar):pointer;
var
  lentry:integer;
begin
  lentry:=AddPath(apath);
  if lentry<0 then exit(nil);

  result:=SearchFile(lentry,aname);
  if result<>nil then exit;

  // add record if file was not found
  result:=Files[AddEntryFile(lentry,aname)];
end;

  {%ENDREGION Add}

  {%REGION Delete}
procedure TRGManifest.DeleteEntryFile(aentry:integer; aname:PUnicodeChar);
var
  p:PBaseFileInfo;
  prev,idx:integer;
begin
  if (aentry>=0) and (aentry<FDirCount) then
  begin
    idx:=Dirs[aentry].first;
    if idx>=0 then
    begin
      prev:=-1;
      repeat
        p:=Files[idx];
        // Mark as delete, put to Delete list
        if CompareWide(GetName(p^.name),aname)=0 then
        begin
          dec(total);
          dec(Dirs[aentry].count);
          // cut the deleting
          if prev>=0 then
            Files[prev]^.next:=p^.next
          else
            Dirs[aentry].first:=p^.next;

          if Dirs[aentry].last=idx then
            Dirs[aentry].last:=prev;

          p^.name:=0;
          p^.next:=FFileDelFirst;
          FFileDelFirst:=idx;

          dec(total);

          break;
        end;
        prev:=idx;
        idx:=p^.next;
      until idx<0;
    end;
  end;
end;

procedure TRGManifest.DeleteFile(apath,aname:PUnicodeChar); inline;
begin
  DeleteEntryFile(SearchPath(apath),aname);
end;
  {%ENDREGION Delete}
{%ENDREGION File}

{%REGION Entry}
  {%REGION Add}
function TRGManifest.AddEntryDir(const apath:PUnicodeChar=pointer(-1)):integer;
begin
  // Check for first allocation. It have empty name ALWAYS
  if GetDirsCapacity()=0 then
  begin
    SetDirsCapacity(incEBase);

    Dirs[0].name  :=0;
    Dirs[0].parent:=-1;
    Dirs[0].count :=0;
    Dirs[0].first :=-1;
    Dirs[0].last  :=-1;

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

  if apath<>pointer(-1) then
    Dirs[result].name:=SetName(apath)
  else
    Dirs[result].name:=0;
  
  inc(total);
end;

function TRGManifest.DoAddPath(const apath:UnicodeString):integer;
var
  lslash,lparentdir,ldir:integer;
begin
  // if exists already
  result:=SearchPath(PUnicodeChar(apath));
  if result>=0 then exit;

  // add parent dir
  lslash:=Length(apath)-1;
  while (lslash>1) and (apath[lslash]<>'/') do dec(lslash);

  if lslash>1 then
    lparentdir:=DoAddPath(Copy(apath,1,lslash))
  else
  begin
    if apath[1]<>'/' then lslash:=0;
    lparentdir:=0;
  end;

  ldir:=AddEntryFile(lparentdir,PUnicodeChar(apath)+lslash);

  result:=AddEntryDir(PUnicodeChar(apath));
  Dirs[result].parent:=lparentdir;
  Dirs[result].index :=ldir;

  Files[ldir]^.data:=result;
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
  if FDirCount=0 then
    AddEntryDir(nil);

  if apath='' then exit(0);

  result:=DoAddPath(TransformPath(apath));
end;
  {%ENDREGION Add}

  {%REGION Delete}
procedure TRGManifest.DeleteEntry(aentry:integer);
var
  p:PBaseFileInfo;
  lfile{,ldir,pcw}:PUnicodeChar;
begin
  if aentry>0 then
  begin
    dec(total);
    // delete files
    if GetFirstFile(p,aentry)<>0 then
    begin
//      ldir:=GetDirName(aentry);
      repeat
        lfile:=GetName(p^.name);
        if lfile[Length(lfile)-1]='/' then
        begin
          DeleteEntry(p^.data);
{
          pcw:=ConcatWide(ldir,lfile);
          DeleteEntry(SearchPath(pcw));
          FreeMem(pcw);
}
        end;
        DeleteEntryFile(aentry,lfile); //!! double check
      until GetNextFile(p)=0;
    end;

    // move from dir list to deleted dir list
    Dirs[aentry].name:=cardinal(-1);
    Dirs[aentry].last:=FDirDelFirst;
    FDirDelFirst:=aentry;
  end;
end;

procedure TRGManifest.DoDeletePath(const apath:UnicodeString);
var
  i,lslash:integer;
begin
  i:=SearchPath(PUnicodeChar(apath));
  if i>=0 then
  begin
    // delete from parent entry
    lslash:=Length(apath)-1;
    while (lslash>1) and (apath[lslash]<>'/') do dec(lslash);
    if lslash>1 then
    begin
      DeleteEntryFile(Dirs[i].parent,PUnicodeChar(apath)+lslash);
//      DeleteFile(PUnicodeChar(Copy(apath,1,lslash)),PUnicodeChar(apath)+lslash);
    end;

    DeleteEntry(i);
  end;
end;

procedure TRGManifest.DeletePath(apath:PUnicodeChar); inline;
begin
  DoDeletePath(TransformPath(apath));
end;

procedure TRGManifest.DeletePath(const apath:string); inline;
begin
  DoDeletePath(TransformPath(apath));
end;
  {%ENDREGION Delete}

  {%REGION Rename}
function TRGManifest.RenameDir(const apath, oldname, newname:PUnicodeChar):integer;
var
  lpath,lold,lnew:UnicodeString;
  lname:PUnicodeChar;
  p:PBaseFileInfo;
  lentry,lparent,i,llen:integer;
begin
  result:=0;

  lpath:=TransformPath(apath);
  lold :=lpath+TransformPath(oldname);

  lentry:=SearchPath(PUnicodeChar(lold));
  if lentry>=0 then
  begin
    lparent:=Dirs[lentry].parent;
    // Search if new path exists already
    lnew:=TransformPath(newname);
    if GetFirstFile(p,lparent)<>0 then //always
      repeat
        if CompareWide(GetName(p^.name),PUnicodeChar(lnew))=0 then exit;
      until GetNextFile(p)=0;
    
    // replace old
    Files[Dirs[lentry].index]^.name:=SetName(PUnicodeChar(lnew));
    lnew:=lpath+lnew;
    SetDirName(lentry,PUnicodeChar(lnew));

    llen:=Length(lold);
    // rename children
    for i:=0 to FDirCount-1 do
    begin
      if (i<>lparent) and (i<>lentry) and not IsDirDeleted(i) then
      begin
        lname:=GetDirName(i);
        if CompareWide(PUnicodeChar(lold),lname,llen)=0 then
        begin
          SetDirName(i,PUnicodeChar(lnew+Copy(lname,llen+1)));
        end;
      end;
    end;
  end;
end;

function TRGManifest.RenameDir(const apath, newname:string):integer;
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

{%ENDREGION Entry}

end.
