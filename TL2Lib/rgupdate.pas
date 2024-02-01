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
  rgfs,
  rgglobal;

const
  act_mark   = 0; // mark for delete (MOD data)
  act_data   = 1; // binary data
  act_file   = 2; // disk file
  act_copy   = 3; // just copy of original PAK data
  act_delete = 4; // delete from PAK
  act_dir    = 5; // disk directory with files
  act_reset  = 6; // delete from update (reset), event only

type
  PUpdateFileInfo = ^TUpdateFileInfo;
  TUpdateFileInfo = object(TFileInfo)
    act  :integer;
    fileu:PWideChar;
    usize:cardinal;
  end;

type
  TOnRGUpdate = procedure (idx:integer; act:integer) of object;
type
  TRGUpdateList = object (TRGDirList)
  private
    FOnUpdate:TOnRGUpdate;

    procedure ClearElement (arec:PUpdateFileInfo);
  public
    // Main
    procedure Init;
    procedure Free;

    // Mark as removed (delete update)
    procedure Remove(apath:PWideChar);
    // Remove update
    procedure Reset (apath:PWideChar);
    // Add file name as future update
    function Add(afile:PWideChar; apath:PWideChar; acontent:boolean=false):PUpdateFileInfo;
    // Add data as update
    function Add    (adata:PByte; asize:cardinal; apath:PWideChar):PUpdateFileInfo;
    // Add source data copy
    function AddCopy(adata:PByte; asize:cardinal; apath:PWideChar):PUpdateFileInfo;
    // Add data as update directly, not allocate
    function Use(adata:PByte; asize:cardinal; apath:PWideChar):PUpdateFileInfo;
    // Get data from update
    function  Get(info :PFileInfo; var aout:PByte):integer;
    function  Get(idx  :integer  ; var aout:PByte):integer;
    function  Get(apath:PWideChar; var aout:PByte):integer;

  public
    property OnUpdate:TOnRGUpdate read FOnUpdate write FOnUpdate;
  end;

implementation


const
  maxMemSize = 4*1024*1024; // max block sze to keep in memory, else - on disk


procedure TRGUpdateList.Init;
begin
  inherited Init(SizEOf(TUpdateFileInfo));

  FOnUpdate:=nil;
end;

procedure TRGUpdateList.Free;
var
  i:integer;
begin
  for i:=0 to FileCount-1 do
    if not IsFileDeleted(i) then
      ClearElement(PUpdateFileInfo(Files[i]));

  inherited Free;
end;

procedure TRGUpdateList.ClearElement(arec:PUpdateFileInfo);
begin
   with arec^ do
   begin
     case act of 
       act_copy,
       act_data: FreeMem(data);
       act_file: FreeMem(fileu);
     end;
   end;
end;

procedure TRGUpdateList.Reset(apath:PWideChar);
var
  p:PUpdateFileInfo;
begin
  p:=PUpdateFileInfo(Files[SearchFile(apath)]);
  if p<>nil then
  begin
    ClearElement(p);
//!!!!!!!!!1    DeleteFile(apath); //!! double search
//    if Assigned(OnUpdate) then OnUpdate(,act_reset);
  end;
end;

procedure TRGUpdateList.Remove(apath:PWideChar);
var
  p:PUpdateFileInfo;
begin
  p:=PUpdateFileInfo(Files[AddFile(apath)]);
  ClearElement(p);
  p^.act:=act_delete;
end;

function TRGUpdateList.Use(adata:PByte; asize:cardinal; apath:PWideChar):PUpdateFileInfo;
begin
  result:=PUpdateFileInfo(Files[AddFile(apath)]);
  ClearElement(result);
  with result^ do
  begin
    data :=adata;
    usize:=asize;
    act  :=act_data;
  end;
//  if Assigned(OnUpdate) then OnUpdate(,act_data);
end;

function TRGUpdateList.Add(adata:PByte; asize:cardinal; apath:PWideChar):PUpdateFileInfo;
var
  lptr:PByte;
begin
  GetMem(lptr,asize);
  move(adata^,lptr^,asize);

  result:=Use(lptr,asize,apath);
end;

function TRGUpdateList.AddCopy(adata:PByte; asize:cardinal; apath:PWideChar):PUpdateFileInfo;
begin
  result:=Add(adata,asize,apath);
  with result^ do
    act:=act_copy;
end;

function TRGUpdateList.Add(afile:PWideChar; apath:PWideChar; acontent:boolean=false):PUpdateFileInfo;
var
  f:file of byte;
  lptr:PByte;
  lsize:integer;
begin
  if not acontent then
  begin
    result:=PUpdateFileInfo(Files[AddFile(apath)]);
    ClearElement(result);
    with result^ do
    begin
      fileu:=CopyWide(afile);
      act  :=act_file;
//      if Assigned(OnUpdate) then OnUpdate(,act_file);
    end;
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
    result:=nil;
  end;
end;

function TRGUpdateList.Get(info:PFileInfo; var aout:PByte):integer;
var
  f:File of byte;
begin
  result:=0;
  if info<>nil then
  begin
    // read from file
    if PUpdateFileInfo(info)^.act=act_file then
    begin
      system.Assign(f,PUpdateFileInfo(info)^.fileu);
      system.Reset(f);
      if IOResult=0 then
      begin
        result:=FileSize(f);
        if result>0 then
        begin
          if (aout=nil) or (MemSize(aout)<result) then
          begin
            FreeMem(aout);
            GetMem(aout, result);
          end;
          BlockRead(f,aout^,result);
        end;
        system.Close(f);
      end;
    end
    // read from block
    else
    begin
      result:=PUpdateFileInfo(info)^.usize;
      if result>0 then
      begin
        if (aout=nil) or (MemSize(aout)<result) then
        begin
          FreeMem(aout);
          GetMem(aout, result);
        end;
        move(PByte(info^.data)^,aout^,result);
      end;
    end
  end;
end;

function TRGUpdateList.Get(idx:integer; var aout:PByte):integer; inline;
begin
  result:=Get(Files[idx],aout);
end;

function TRGUpdateList.Get(apath:PWideChar; var aout:PByte):integer; inline;
begin
  result:=Get(SearchFile(apath),aout)
end;

end.
