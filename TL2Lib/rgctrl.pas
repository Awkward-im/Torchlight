unit RGController;

interface

uses
  RGGlobal,
  RGMAN,
  RGUpdate;

function RGCtrlGetFirst(p:pointer; const adir:string; const atypes:array of string):integer;
function RGCtrlGetNext (p:pointer):integer;

type
  TRGCtrlElement = record
  end;
type
  TRGController = object
  private
    FMAN:TRGManifest;
    FUpd:TRGUpdateList;
    FPAK:TPAKInfo;
  private
    function MakeDirList:integer;
    function MakeFileList():integer;
  public
    procedure Init;
    procedure Clear;
  public
    {
      Get first dir info
      ?? from root or from choosed ??
      result=0 - not found
    }
    function GetDirFirst:
    {
      Get next dir info
      result=0 - not found
    }
    function GetDirNext():
    {
      Get first file in dir
      ?? all or with choosed types/categories ??
      result=0 - not found
    }
    function GetFileFirst():
    {
      get next file info
      result=0 - not found
    }
    function GetFileNext():
    {
      Get file info
      ?? by name, "index" ??
      return structure as argument?
        time, CRC, size, packed/compiled/dir etc?
    }
    function GetFileInfo():
    {
      Get file content
      as is?
    }
    function GetFileData():                                                1 
  public
    function ApplyUpdate:integer;
  end;

implementation

function RGCtrlGetFirst(p:pointer; const adir:string; const atypes:array of string):integer;
begin
end;

function RGCtrlGetNext (p:pointer):integer;
begin
end;

end.

IsFileDir
GetFileType: source, compiled, packed | old, modified, new, deleted, removed=marked
source date, compilation date, (pack date)
place: PAK, disk, updater (mem or disk)
list, get file info, get file content

  PMANFileInfo = ^TMANFileInfo;
  TMANFileInfo = record // not real field order
    ftime   :UInt64;    // MAN: TL2 only
    data    :PByte;     // file memory placement address
    name    :cardinal;  // !! PAK path
    checksum:dword;     // MAN: CRC32
    size_s  :dword;     // ?? MAN: looks like source,not compiled, size (unusable)
    size_c  :dword;     // !! PAK: from TPAKFileHeader
    size_u  :dword;     // !! PAK: from TPAKFileHeader
    offset  :dword;     // !! MAN: PAK data block offset
    ftype   :byte;      // !! MAN: RGFileType unified type
    exttype :byte;      // ?? MAN, Updater,
    property FileName: read GetName write SetName
  end;

data<>nil   - content in memory else on disk
exttype=upd - memory or updater disk dir
exttype=man - man disk dir or pak
