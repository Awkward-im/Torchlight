unit RGCtrl;

interface

uses
  RGGlobal,
  RGFS,
  RGMAN,
  RGPAK,
  RGUpdate;

type
  PRGCtrlInfo = ^TRGCtrlInfo;
  TRGCtrlInfo = object(TBaseInfo)
    source:integer; // MAN index
    update:integer; // updater index
  end;

type
  PFullFileInfo = ^TFullFileInfo;
  TFullFileInfo = record
    name    :PWideChar;
    path    :PWideChar;
    ftime   :UInt64;    // MAN: TL2 only
    size_u  :dword;     // !! PAK: from TPAKFileHeader
// dev only
    size_c  :dword;     // !! PAK: from TPAKFileHeader
    checksum:dword;     // MAN: CRC32
    size_s  :dword;     // ?? MAN: looks like source,not compiled, size (unusable)
    offset  :dword;     // !! MAN: PAK data block offset (??changed to "data" field)
// unnecessary
    ftype   :byte;      // !! MAN: RGFileType unified type
  end;

type

  { TRGController }

  TRGController = object(TRGDirList)
  private
    FMAN:TRGManifest;
    FUpd:TRGUpdateList;
    FPAK:TRGPAK;
  private
//    function MakeDirList:integer;
//    function MakeFileList():integer;
    procedure CtrlUpdate(idx:integer; act:integer);

    function SearchUpdate(idx:integer):integer;
    function SearchSource(idx:integer):integer;

  public
    procedure Init;
//    procedure Clear;
    function Rebuild():integer;
    
    // Build file list and file info
    procedure GetFullInfo(idx:integer; var info:TFullFileInfo);

    // Get file content (preview etc)
    function GetFile(idx:integer          ; var buf:PByte):integer;
    function GetFile(fname:PWideChar      ; var buf:PByte):integer;
    function GetFile(apath,aname:PWideChar; var buf:PByte):integer;

    // Save info
  public
    {
      Get first dir info
      ?? from root or from choosed ??
      result=0 - not found
    }
//    function GetDirFirst:
    {
      Get next dir info
      result=0 - not found
    }
//    function GetDirNext():
    {
      Get first file in dir
      ?? all or with choosed types/categories ??
      result=0 - not found
    }
//    function GetFileFirst():
    {
      get next file info
      result=0 - not found
    }
//    function GetFileNext():
    {
      Get file info
      ?? by name, "index" ??
      return structure as argument?
        time, CRC, size, packed/compiled/dir etc?
    }
//    function GetFileInfo():
    {
      Get file content
      as is?
    }
//    function GetFileData():                                                1 
  public
//    function ApplyUpdate():integer;
  end;

implementation

{ TRGController }

procedure TRGController.Init;
begin
  Inherited Init(SizeOf(TRGCtrlInfo));

  FUpd.OnUpdate:=@CtrlUpdate;
end;

function TRGController.Rebuild(): integer;
var
  ldir,ldirs,lfiles:integer;
  lidx,lfile:integer;
begin
  result:=0;

  // No need to check for existing
  for ldirs:=0 to FMAN.DirCount-1 do
  begin
    if not FMAN.IsDirDeleted(ldirs) then
    begin
      ldir:=AppendDir(FMAN.Dirs[ldirs].name);
      for lfiles:=0 to FMAN.Dirs[ldirs].count-1 do
      begin
        if FMAN.GetFirstFile(lidx,ldir) then
        repeat
          lfile:=AppendFile(ldir,FMAN.Files[lidx]^.name);
          with PRGCtrlInfo(Files[lfile])^ do
          begin
            source:=lidx;
          end;
        until not FMAN.GetNextFile(lidx);
      end;
    end;
  end;

  // MUST check for existing
  for ldirs:=0 to FUpd.DirCount-1 do
  begin
    if not FUpd.IsDirDeleted(ldirs) then
    begin
      ldir:=AddPath(FUpd.Dirs[ldirs].name);
      for lfiles:=0 to FUpd.Dirs[ldirs].count-1 do
      begin
        if FUpd.GetFirstFile(lidx,ldir) then
        repeat
          with PRGCtrlInfo(AddFile(ldir,FUpd.Files[lidx]^.name))^ do
          begin
            update:=lidx;
          end;
        until not FUpd.GetNextFile(lidx);
      end;
    end;
  end;
end;

function TRGController.SearchUpdate(idx:integer):integer;
var
  i:integer;
begin
  for i:=1 to FileCount-1 do
  begin
    with PRGCtrlInfo(Files[i])^ do
    begin
      if (update=idx) and not IsFileDeleted(idx) then
        exit(i);
    end;
  end;
  result:=0;
end;

function TRGController.SearchSource(idx:integer):integer;
var
  i:integer;
begin
  for i:=1 to FileCount-1 do
  begin
    with PRGCtrlInfo(Files[i])^ do
    begin
      if (source=idx) and not IsFileDeleted(idx) then
        exit(i);
    end;
  end;
  result:=0;
end;

procedure TRGController.CtrlUpdate(idx:integer; act:integer);
var
  p:PRGCtrlInfo;
  i:integer;
begin
  i:=SearchUpdate(idx);

  case act of
    act_mark,
    act_delete: begin
    end;

    act_data,
    act_copy,
    act_file: begin
      if i=0 then
      begin
        with PRGCtrlInfo(AddFile(FUpd.PathOfFile(idx),FUpd.Files[idx]^.name))^ do
        begin
          update:=idx;
        end;
      end;
    end;

    // not realized yet
    act_dir: begin
    end;

    act_reset: begin
      if i<>0 then
      begin
        p:=PRGCtrlInfo(Files[i]);
        if p^.source=0 then // no MAN element, time to delete
          DeleteFile(i)
        else
          p^.update:=0;
      end;
    end;
  end;
end;

procedure TRGController.GetFullInfo(idx:integer; var info:TFullFileInfo);
begin
end;

function TRGController.GetFile(idx:integer; var buf:PByte):integer;
var
  p:PRGCtrlInfo;
begin
  p:=PRGCtrlInfo(Files[idx]);
  if p^.update=0 then   // get from MAN/PAK
  begin
    result:=FPAK.UnpackFile(PathOfFile(idx),p^.name,buf);
  end
  else                  // get from updater
  begin
    result:=FUpd.Get(p^.update,buf);
  end;
end;

function TRGController.GetFile(fname:PWideChar; var buf:PByte):integer;
begin
  result:=GetFile(SearchFile(fname),buf);
end;

function TRGController.GetFile(apath,aname:PWideChar; var buf:PByte):integer;
begin
  result:=GetFile(SearchFile(apath,aname),buf);
end;

end.
