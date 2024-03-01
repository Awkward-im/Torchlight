UNIT rgtree;

interface

uses
  Classes,
  TextCache,
  rgglobal;


type
  PRGBaseTreeNode = ^TRGBaseTreeNode;
  TRGBaseTreeNode = object
  private
    ftext :cardinal;   // musthave, node value
    parent:integer;    // musthave for full paths/siblings, delete
    next  :integer;    // musthave, next node (sibling)
//    prev:integer;      // not used, reverse cycle, fast access when delete
//    root:integer;      // fast access for global settings, init/destroy
    first:integer;     // musthave, Group (dir) node, start of children
    last:integer;      // not sure, Group (dir) node. fast access for adding
    count:integer;     // not used, Group (dir) node, fast abs index, amount to write?

    function  GetName():PUnicodeChar;
    procedure SetName(aname:PUnicodeChar);
  public
    property Name:PUnicodeChar read GetFileName write SetFileName;
  end;

type
  PRGBaseTree = ^TRGBaseTree;
  TRGBaseTree = object
  private
    FList :PByte;
    FCapacity:integer;
    FNodeSize:integer;
    FNodeCount    :integer; // total count of Entries
    FNodeDelFirst :integer; // first deleted Entry index. 0, if unknown
    FModified :boolean;

  private
    function  GetCapacity():integer;
    procedure SetCapacity(acnt:integer);

    // lowlevel functions
    function GetHash(idx:integer):dword;

    function GetNodePtr(idx:integer):PBaseTreeNode;

    procedure DeleteEntryFile(aentry:integer; aname:PUnicodeChar);

  //--- PUBLIC area ---

  // Base
  public
    procedure Init(aInfoSize:integer=SizeOf(TBaseFileInfo));
    procedure Free;

  // Get data
  public
    function SearchPath(apath:PUnicodeChar):integer;
    function Search(anode:pointer; aname:PUnicodeChar):PBaseTreeNode;

    // result=0 means "end"
    function GetFirst(out p:pointer; anode:pointer):integer;
    function GetNext (var p:pointer):integer;

  // Change info
  public
    // Add file record, no check, no data
    function  Add   (anode:pointer; aname:PUnicodeChar=nil):pointer;
    procedure Delete(anode:pointer);

  // Properties
  public
    function IsNodeDeleted(idx:integer):boolean;

    property Capacity:integer read GetFilesCapacity write SetFilesCapacity;
    property Count   :integer read FFileCount;
    property Nodes[idx:integer]:PBaseTreeNode read GetNodePtr;

  // Properties runtime
  public
    property Modified:boolean read FModified;
  end;


implementation

uses
  sysutils;

var
  Names:TTextCache;

const
  incEBase = 512;
  incEntry = 256;
  incFBase = 128;
  incFFile = 16;

{%REGION Support}

function SetName(aname:PUnicodeChar):integer; inline;
begin
  result:=names.Add(aname);
end;

function GetName(idx:integer):PUnicodeChar; inline;
begin
  result:=PUnicodeChar(names[idx]);
end;

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
  if (apath[lsize]<>'\') and (apath[lsize]<>'/') then inc(lrsize);
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
  if (apath[lsize]<>'\') and (apath[lsize]<>'/') then inc(lrsize);
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

function TRGDirList.IsFileDeleted(idx:integer):boolean; inline;
begin
  result:=Nodes[idx]^.fname=nil;
end;

function TBaseFileInfo.GetFileName():PUnicodeChar; inline;
begin
  result:=GetName(self.fname);
end;

procedure TBaseFileInfo.SetFileName(aname:PUnicodeChar); inline;
begin
  self.fname:=SetName(aname);
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

function TRGDirList.GetHash(idx:integer):dword; inline;
begin
  result:=names.hash[idx];
end;

function TRGDirList.GetDirName(idx:integer):PUnicodeChar;
begin
  if (idx>0) and (idx<FDirCount) and not IsDirDeleted(idx) then
    result:=GetName(Dirs[idx].name)
  else
    result:=nil;
end;

procedure TRGDirList.SetDirName(idx:integer; aname:PUnicodeChar); inline;
begin
  if (idx>0) and (idx<FDirCount) then
    Dirs[idx].name:=SetName(aname);
end;

function TRGDirList.GetFilesCapacity():integer; inline;
begin
  result:=FCapacity;
end;

procedure TRGDirList.SetFilesCapacity(acnt:integer);
begin
  if acnt>FCapacity then
  begin
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
    SetLength(Dirs,acnt);
end;
{%ENDREGION Getters/Setters}

{%REGION Common}
function TRGDirList.GetFirst(out p:pointer; aentry:integer):integer;
begin
  result:=Dirs[aentry].first;
  if result>=0 then p:=Files[result];
  inc(result);
end;

function TRGDirList.GetNext(var p:pointer):integer;
begin
  result:=PBaseFileInfo(p)^.next;
  if result>=0 then p:=Files[result];
  inc(result);
end;
{%ENDREGION Common}

{%REGION Main}
procedure TRGDirList.Init(aInfoSize:integer=SizeOf(TBaseFileInfo));
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
  FInfoSize:=aInfoSize;

  FDirDelFirst :=-1;
  FFileDelFirst:=-1;
end;

procedure TRGDirList.Free;
begin
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
function TRGDirList.SearchFile(aentry:integer; aname:PUnicodeChar):PBaseFileInfo;
var
  p:array [0..255] of WideChar;
  pc:PUnicodeChar;
begin
  if (aname<>nil) and (aname^<>#0) and (aentry>=0) and (aentry<FDirCount) then
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
        if CompareWide(result^.Name,pc)=0 then exit;
      until GetNextFile(result)=0;
  end;
  
  result:=nil;
end;

{%ENDREGION}

{%REGION File}
  {%REGION Add}
function TRGDirList.AddEntryFile(aentry:integer; aname:PUnicodeChar=nil):integer;
var
  lrec:PBaseFileInfo;
  i:integer;
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
    result:=FFileCount;

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

  Dirs[aentry].last:=result;
  inc(Dirs[aentry].count);

  // data
  lrec:=Files[result];
  FillChar(lrec^,FInfoSize,0);
  if aname<>nil then
    lrec^.Name:=aname;
  lrec^.next:=-1;

  inc(total);
end;

function TRGDirList.AddFile(adir:integer; aname:PUnicodeChar=nil):pointer;
begin
  result:=SearchFile(adir,aname);
  if result<>nil then exit;

  // add record if file was not found
  result:=Files[AddEntryFile(adir,aname)];
end;

  {%ENDREGION Add}

  {%REGION Delete}
procedure TRGDirList.DeleteEntryFile(aentry:integer; aname:PUnicodeChar);
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
        if CompareWide(p^.Name,aname)=0 then
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

          p^.Name:='';
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

procedure TRGDirList.DeleteFile(apath,aname:PUnicodeChar); inline;
begin
  DeleteEntryFile(SearchPath(apath),aname);
end;
  {%ENDREGION Delete}
{%ENDREGION File}

{%REGION Entry}
  {%REGION Add}
function TRGDirList.AddEntryDir(apath:PUnicodeChar=pointer(-1)):integer;
begin
  // Check for first allocation. It have empty name ALWAYS
  if GetDirsCapacity()=0 then
    SetDirsCapacity(incEBase);
  if FDirCount=0 then
  begin
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

  if apath=pointer(-1) then apath:=nil;
  SetDirName(result,apath);
  
  inc(total);
end;

function TRGDirList.DoAddPath(const apath:UnicodeString):integer;
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

function TRGDirList.AddPath(apath:PUnicodeChar):integer;
begin
  if FDirCount=0 then
    AddEntryDir(nil);
  
  if (apath=nil) or (apath^=#0) then exit(0);
  
  result:=DoAddPath(TransformPath(apath));
end;

function TRGDirList.AddPath(const apath:string):integer;
begin
  if FDirCount=0 then
    AddEntryDir(nil);

  if apath='' then exit(0);

  result:=DoAddPath(TransformPath(apath));
end;
  {%ENDREGION Add}

  {%REGION Delete}
procedure TRGDirList.DeleteEntry(aentry:integer);
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
        lfile:=p^.Name;
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

procedure TRGDirList.DoDeletePath(const apath:UnicodeString);
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

procedure TRGDirList.DeletePath(apath:PUnicodeChar); inline;
begin
  DoDeletePath(TransformPath(apath));
end;

procedure TRGDirList.DeletePath(const apath:string); inline;
begin
  DoDeletePath(TransformPath(apath));
end;
  {%ENDREGION Delete}

  {%REGION Rename}
function TRGDirList.RenameDir(const apath, oldname, newname:PUnicodeChar):integer;
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
        if CompareWide(p^.Name,PUnicodeChar(lnew))=0 then exit;
      until GetNextFile(p)=0;
    
    // replace old
    Files[Dirs[lentry].index]^.Name:=PUnicodeChar(lnew);
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

{%ENDREGION Entry}

initialization

  names.Init(false);

finalization

  names.Clear;

end.
