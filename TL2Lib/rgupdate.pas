{TODO: move TUpdateElement to MAN.TMANFileInfo}
{TODO: Add time of update}
{TODO: keep data in file if size too big. FDir+'\'+hash. Delete on clear}
{TODO: separate packed and unpacked data}
{TODO: Keep dir and filename separately (Hash still for full name)}
{TODO: Get: use existing data block? how to control?}
{TODO: Add directory (clear that dir files records}
{TODO: Add files with check of dirs (skip if inside if filename, not context?)}
{TODO: get "Count" with directory scan}
{TODO: decease, keep file type or not}
{
  Add file
  Remove file
  Reset file
  Search file
  Get file
}
unit RGUpdate;

interface

uses
  rgglobal;

const
  act_mark   = 0; // mark for delete (MOD data)
  act_data   = 1; // binary data
  act_file   = 2; // disk file
  act_copy   = 3; // just copy of original PAK data
  act_delete = 4; // delete from PAK
  act_dir    = 5; // disk directory with files

type
  PUpdateElement = ^TUpdateElement;
  TUpdateElement = record
    time :TDateTime;
    path :PWideChar;       // file path inside PAK (dir with name)
    id   :dword;           // hash for faster search
//    size :cardinal;        // data or file size?
    case act:integer of
      act_data: (
        data :PByte;       // binary file data
        usize:cardinal;    // data size
//        psize:cardinal;
      );
      act_file: (
        fileu:PWideChar    // external file name
      );
  end;

type
  TRGUpdateList = object
  private
    FList  :array of TUpdateElement;
    FCount :integer;    // amount of real elements
    FDir   :PWideChar;  // path to save files

    procedure Sort;
    function GetElementCount:integer;
    function GetElement(i:integer):TUpdateElement;

    function  CreateElement(apath:PWideChar):integer;
    procedure ClearElement (idx:integer);
    procedure DeleteElement(idx:integer);

    function  AddInternal(adata:PByte; asize:cardinal; apath:PWideChar):integer;
    // Search for updated
    function  Search(aid  :dword    ):integer;
    function  Search(apath:PWideChar; acase:boolean=false):integer;
  public
    // Main
    procedure Create;
    procedure Clear;

    // Actions
    // Mark as removed (delete update)
    procedure Remove(apath:PWideChar);
    // Remove update
    procedure Reset (apath:PWideChar);
    // Add file name as future update
    function Add(afile:PWideChar; apath:PWideChar; acontent:boolean=false):dword;
    // Add data as update
    function Add    (adata:PByte; asize:cardinal; apath:PWideChar):dword;
    // Add source data copy
    function AddCopy(adata:PByte; asize:cardinal; apath:PWideChar):dword;
    // Add data as update directly, not allocate
    function Use(adata:PByte; asize:cardinal; apath:PWideChar):dword;
    // Get data from update
    function  Get(apath:PWideChar; var aout:PByte):integer;

    property  Count :integer read GetElementCount;
    property  Element[i:integer]:TUpdateElement read GetElement; default;
  end;

implementation


const
  maxMemSize = 4*1024*1024; // max block sze to keep in memory, else - on disk


procedure TRGUpdateList.Create;
begin
  FCount :=0;
  FList  :=nil; //??
end;

function TRGUpdateList.Search(aid:dword):integer;
var
  i:integer;
begin
  for i:=0 to FCount-1 do
    if FList[i].id=aid then exit(i);

  result:=-1;
end;

function TRGUpdateList.Search(apath:PWideChar; acase:boolean=false):integer;
var
  ls:array [0..511] of WideChar;
  i:integer;
begin
  if apath<>nil then
  begin
    if not acase then
    begin
      i:=0;
      while apath^<>#0 do
      begin
        if apath^='\' then
          ls[i]:='/'
        else
          ls[i]:=UpCase(apath^);
        inc(apath);
        inc(i);
      end;
      ls[i]:=#0;
      apath:=@ls
    end;

    for i:=0 to FCount-1 do
      if CompareWide(FList[i].path,apath)=0 then exit(i);
  end;
  result:=-1;
end;

procedure TRGUpdateList.ClearElement(idx:integer);
begin
  case FList[idx].act of 
    act_copy,
    act_data: FreeMem(FList[idx].data);
    act_file: FreeMem(FList[idx].fileu);
  end;
end;

function TRGUpdateList.CreateElement(apath:PWideChar):integer;
var
  ls:array [0..511] of WideChar;
  i:integer;
begin
  i:=0;
  while apath^<>#0 do
  begin
    if apath^='\' then
      ls[i]:='/'
    else
      ls[i]:=UpCase(apath^);
    inc(apath);
    inc(i);
  end;
  ls[i]:=#0;

  i:=Search(@ls,true);
  // Found element
  if i>=0 then
  begin
    ClearElement(i);
  end
  else
  begin
    i:=FCount;
    // check for unused list space at the end
    if i=system.Length(FList) then //!!!! expand list
    begin
      SetLength(FList,i+16);
    end;

    FList[i].path:=CopyWide(ls);
    FList[i].id  :=RGHash(ls);
//    FList[i].time:=Now();

    inc(FCount);
  end;
  result:=i;
end;

procedure TRGUpdateList.DeleteElement(idx:integer);
begin
  FreeMem(FList[idx].path);
  ClearElement(idx);

  if idx<(FCount-1) then
    move(FList[idx+1],FList[idx],(FCount-1-idx)*SizeOf(TUpdateElement));
end;

procedure TRGUpdateList.Clear;
var
  i:integer;
begin
  for i:=FCount-1 downto 0 do
    DeleteElement(i);

  FCount:=0;
  SetLength(FList,0);
end;

procedure TRGUpdateList.Reset(apath:PWideChar);
var
  i:integer;
begin
  i:=Search(apath);
  if i>=0 then
  begin
    DeleteElement(i);
    dec(FCount);
  end;
end;

procedure TRGUpdateList.Remove(apath:PWideChar);
begin
  FList[CreateElement(apath)].act:=act_delete;
end;

function TRGUpdateList.Use(adata:PByte; asize:cardinal; apath:PWideChar):dword;
var
  i:integer;
begin
  i:=CreateElement(apath);
  FList[i].data :=adata;
  FList[i].usize:=asize;
  FList[i].act  :=act_data;
  result:=FList[i].id;
end;

function TRGUpdateList.AddInternal(adata:PByte; asize:cardinal; apath:PWideChar):integer;
var
  i:integer;
begin
  i:=CreateElement(apath);
  GetMem(FList[i].data,asize);
  move(adata^,FList[i].data^,asize);
  FList[i].usize:=asize;
  result:=i;
end;

function TRGUpdateList.Add(adata:PByte; asize:cardinal; apath:PWideChar):dword;
var
  i:integer;
begin
  i:=AddInternal(adata,asize,apath);
  FList[i].act:=act_data;
  result:=Flist[i].id;
end;

function TRGUpdateList.AddCopy(adata:PByte; asize:cardinal; apath:PWideChar):dword;
var
  i:integer;
begin
  i:=AddInternal(adata,asize,apath);
  FList[i].act:=act_copy;
  result:=FList[i].id;
end;

function TRGUpdateList.Add(afile:PWideChar; apath:PWideChar; acontent:boolean=false):dword;
var
  f:file of byte;
  lptr:PByte;
  i,lsize:integer;
begin
  if not acontent then
  begin
    i:=CreateElement(apath);
    FList[i].fileu:=CopyWide(afile);
    FList[i].act  :=act_file;
    result:=FList[i].id;
  end
  else
  begin
    system.Assign(f,afile);
    system.Reset(f);
    if IOResult=0 then
    begin
      lsize:=FileSize(f);
      if lsize>0 then
      begin
        GetMem(lptr,lsize);
        BlockRead(f,lptr^,lsize);
      end;
      system.Close(f);

      result:=Use(lptr,lsize,apath);
      exit;
    end;
    result:=0;
  end;
end;

function TRGUpdateList.Get(apath:PWideChar; var aout:PByte):integer;
var
  f:File of byte;
  i:integer;
begin
  result:=0;
  i:=Search(apath);
  if i>=0 then
  begin
    // read from file
    if FList[i].act=act_file then
    begin
      system.Assign(f,FList[i].fileu);
      system.Reset(f);
      if IOResult=0 then
      begin
        result:=FileSize(f);
        if result>0 then
        begin
          if (aout=nil) or (MemSize(aout)<result) then
            ReallocMem(aout, result);
          BlockRead(f,aout^,result);
        end;
        system.Close(f);
      end;
    end
    // read from block
    else
    begin
      result:=FList[i].usize;
      if result>0 then
      begin
        if (aout=nil) or (MemSize(aout)<result) then
          ReallocMem(aout, result);
        move(FList[i].data^,aout^,result);
      end;
    end
  end;
end;

procedure TRGUpdateList.Sort;
begin
end;

function TRGUpdateList.GetElementCount:integer;
begin
  result:=FCount;
end;

function TRGUpdateList.GetElement(i:integer):TUpdateElement;
begin
  if (i>=0) and (i<FCount) then
    result:=FList[i];
end;

end.
