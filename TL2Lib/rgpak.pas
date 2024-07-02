{TODO: control man.size_s. (0 means "do not write, delete"). How to change? TL2.size_s=size}
{TODO: choose, FOffMan and FOffData in TRGPAK or modinfo}
{TODO: Check PAK size and time for changes while used}
{TODO: keep stream/buffer handles for already opened data}
{
  + Unpack all files (decode as separate task)
  + Unpack separate file[s]
  + Pack all files
  Pack separate file[s]
    Append to PAK (if new or larger)
    Add on place  (if exist and not larger)
  Reassemble PAK (no repack) = compact
  * Split   PAK to   PAK and MAN (now MOD as in  only)
  * Combine PAK from PAK and MAN (now MOD as out only)
  + Convert combined PAK to MOD
}
unit RGPAK;

interface

uses
  classes,
  zipper,
  rgfs,
  rgman,
  rgglobal;

//===== Container =====

const
  piNoParse   = 0; // just PAK version and MAN offset
  piParse     = 1; // TL2 MOD info, MAN content
  piFullParse = 2; // with packed/unpacked file size

type

  { TRGPAK }

  TRGPAK = class
  private
    FStream:TStream;
    FBuf   :PByte;
    // ZIP: buffer for extracted file
    FUnZipper: TUnZipper;
    FUnpSize :cardinal;
    function UnpackFromPAK(afi: PManFileInfo; var aout: PByte): cardinal;
    function UnpackFromZip(afi: PManFileInfo; var aout: PByte): cardinal;
  public
    man    :TRGManifest;
    modinfo:TTL2ModInfo;
  private
    FSrcDir :String;         // PAK file directory
    FName   :String;         // filename only or fullname
    FSize   :longword;       // total PAK size
    FTime   :UInt64;         // PAK file timestamp
    FVersion:integer;
  private
    // return file name with proper ext
    function  MakeDataFileName:String;
    function  MakeManFileName :String;
    function  GetOpenStatus:boolean;
    // version, data and manifest offsets
    function  GetBaseInfo  (const aname:string):integer;
    // modinfo and manifest
    function  GetCommonInfo(const aname:string):boolean;
    // file sizes to manifest
    function  GetSizesInfo ():boolean;
    // TL2 data hash calculation
    function  PAKHash(ast:TStream; asize:int64):dword;

    Procedure CStream(Sender : TObject; var AStream : TStream; AItem : TFullZipFileEntry);
    Procedure DStream(Sender : TObject; var AStream : TStream; AItem : TFullZipFileEntry);

    procedure ReadModDat(const aname: string);

  public
    constructor Create;
    destructor Destroy; override;

    function  OpenPAK(force:boolean=false):boolean;
    procedure ClosePAK;
    function  GetInfo(const aname:string; aparse:integer=piNoParse):boolean;
    function  Clone(const aname:string):boolean;
    function  Rename(const newname:string):boolean;
  public
    // Just Extract file from PAK, not unpack it
    // not actual for TL1's zip
    function  ExtractFile(afi:PManFileInfo; out asize_u:cardinal; var abuf:PByte):cardinal;
    function  ExtractFile(const apath, aname:UnicodeString; out asize_u:cardinal; var abuf:PByte):cardinal;
  public
    function  UnpackSingle(afi:PManFileInfo; var aout:PByte):cardinal;

    function  UnpackFile(const afile:string; var aout:PByte):cardinal;
    function  UnpackFile(const afile:string; const adir:string):boolean;
    function  UnpackFile(apath,aname:PUnicodeChar; var aout:PByte):cardinal;
    function  UnpackFile(apath,aname:PUnicodeChar; const adir:string):boolean;

    function  UnpackAll (const adir:string):boolean;

  public
    {
      CreatePAK based on Manifest (didn't tested)
    }
    procedure Build;

    {
      Create new PAK file on disk, prepare header (and modinfo)
    }
    function  CreatePAK(const afname:string; amod:PTL2ModInfo; aver:integer):integer;
    {
      Packed file writing. Returns file offset in data block
    }
    function  WritePackedFile(adata:PByte; asize_u,asize_c:dword):dword;
    {
      [Un]packed file writing. Only. No compilation. Returns size of writed data
    }
    function  WriteFile(adata:PByte; asize:integer; apack:boolean; var offset:dword):dword;
    {
      Write Manifest, update header
    }
    procedure FinishPAK;
(*
    {
      Add directory to MAN
      OnProgress
    }
    function  AddDirectory(apath:PWideChar):integer;
    {
      Add file record to MAN, write file to PAK
    }
    procedure AddFile(adir:integer; ainfo:PFileInfo; asize_c:integer=0);
*)
  
  public
    property opened:boolean read GetOpenStatus;

    // get from OS file info
    property Size      :longword read FSize;
    property Time      :UInt64   read FTime;
    // get from call
    property Name      :String   read FName   write FName;
    property Directory :String   read FSrcDir write FSrcDir;
    // get from parsing, changing by code
    property DataOffset:longword read modinfo.offData;
    property ManOffset :longword read modinfo.offMan;
    // get from parsing but can be changed later
    property Version   :integer  read FVersion write FVersion;
  end;

function RGPAKGetVersion(const aname:string):integer;

type
  TPAKProgress = function(const ainfo:TRGPAK; adir:integer; afile:PManFileInfo):integer;
var
  OnPAKProgress:TPAKProgress=nil;

//===== Manipulation =====

function RGPAKSplit  (const asrc:string; const adir:string=''; const afname:string=''):integer;
function RGPAKCombine(const apak,aman:string;
                      amod:PByte; asize:integer;
                      const adir:string=''):integer;
function RGPAKCombine(const apak,aman:string;
                      const amod:TTL2ModInfo;
                      const adir:string=''):integer;
function RGPAKCombine(const apak,aman,amod:string; const adir:string=''):integer;
function RGPAKCombine(const asdir,aname:string; const adir:string=''):integer;

/////////////////////////////////////////////////////////

implementation

uses
  sysutils,
  bufstream,

  rgfile,
  rgfiletype,
  rgmod;

//===== Container =====

const
  MaxSizeForMem   = 24*1024*1024;
  BufferStartSize = 64*1024;
  BufferPageSize  = 04*1024;

type
  TTL2PAKHeader = packed record
    MaxCSize:dword;     // largest packed file size in PAK
    Hash    :dword;
  end;
type
  TPAKHeader = packed record
    Version  :word;
    Reserved :dword;
    ManOffset:dword;
    MaxUSize :dword;    // largest UNpacked file size
  end;
type
  TRGOPAKHeader = packed record
    Version  :word;
    Reserved :dword;
    ManOffset:dword;
    ManSize  :dword;
    MaxUSize :dword;    // largest UNpacked file size
  end;


constructor TRGPAK.Create();
begin
  inherited;

  FVersion:=verUnk;

  man.Init;
end;

destructor TRGPAK.Destroy();
begin
  ClosePAK;
  man.Free();
  ClearModInfo(modinfo);
  FreeMem(FBuf);
  FUnZipper.Free;

  inherited;
end;

function TRGPAK.MakeDataFileName():String;
begin
  case FVersion of
    verTL1   : result:=FSrcDir+FName+'.ZIP';
    verTL2,
    verHob,
    verRGO,
    verRG    : result:=FSrcDir+FName+'.PAK';
    verTL2Mod: result:=FSrcDir+FName+'.MOD';
  else
    result:='';
  end;
end;

function TRGPAK.MakeManFileName():String;
begin
  case FVersion of
    verTL1   : result:=FSrcDir+FName+'.ZIP';
    verHob,
    verRGO,
    verRG    : result:=FSrcDir+FName+'.PAK';
    verTL2   : result:=FSrcDir+FName+'.PAK.MAN';
    verTL2Mod: result:=FSrcDir+FName+'.MOD';
  else
    result:='';
  end;
end;

//----- PAK/MOD -----

function TRGPAK.GetOpenStatus:boolean; inline;
begin
  result:=FStream<>nil;
end;

function TRGPAK.OpenPAK(force:boolean=false):boolean;
begin
  if (FName='') or (FSize=0) then exit(false);
  if ABS(FVersion) in [verUnk, verTL1] then exit(false);

  if FStream=nil then
  begin
    if (FSize<=MaxSizeForMem) or force then //!!!!!!! get it just in Get Basic Info atm
    begin
      FStream:=TMemoryStream.Create;
      try
        TMemoryStream(FStream).LoadFromFile(MakeDataFileName());
      except
        FreeAndNil(FStream);
      end;
    end
    else
    begin
      try
        FStream:=TBufferedFileStream.Create(MakeDataFileName(),fmOpenRead);
      except
      end;
    end;
  end;
  result:=FStream<>nil;
end;

procedure TRGPAK.ClosePAK; inline;
begin
  FreeAndNil(FStream);
end;

{$PUSH}
{$I-}
function TRGPAK.GetBaseInfo(const aname:string):integer;
var
  buf:array [0..31] of byte;
  lhdr :TPAKHeader    absolute buf;
//  lhdr2:TTL2PAKHeader absolute buf;
  lhdro:TRGOPAKHeader absolute buf;
  lmi  :TTL2ModTech   absolute buf;
  f:file of byte;
  lext:string;
begin
  FVersion:=verUnk;

  modinfo.offData:=0;
  modinfo.offMan :=0;

  if aname<>'' then
  begin
    FSrcDir:=(ExtractFilePath    (aname));
    FName  :=(ExtractFilenameOnly(aname));
  end
  else
    exit(verUnk);

  //--- Check by ext

  lext:=ExtractFileExt(aname);

  if lext='.ZIP' then
  begin
    FVersion:=verTL1;
    exit(verTL1);
  end;

  if lext='.MAN' then
  begin
    FVersion:=verTL2;
    exit(verTL2);
  end
  else if lext='.MOD' then
   FVersion:=verTL2Mod;

  //--- Check by data

  Assign(f,aname);
  Reset(f);
  if IOResult<>0 then exit(verUnk);

  FSize:=FileSize(f);
  if FSize=0 then
  begin
    Close(f);
    exit(verUnk);
  end;

  buf[0]:=0;
  BlockRead(f,buf,SizeOf(buf));
  Close(f);

  // check PAK version
  if (FVersion=verUnk) and (lhdr.Reserved=0) then
  begin
    if lhdr.Version=1 then
    begin
      FVersion:=verRG;
    end
    else if lhdr.Version=5 then
    begin
      if lhdro.ManSize=(FSize-lhdro.ManOffset) then
      begin
        FVersion:=verRGO;
      end
      else
      begin
        FVersion:=verHob;
      end;
    end;

    modinfo.offData:=0;
    modinfo.offMan :=lhdr.ManOffset;
  end
  else
  begin
    // if we have MOD header
    if ((lmi.version=4) and (lmi.gamever[0]=1)) or
       (lext='.MOD') then
    begin
      FVersion:=verTL2Mod;
      modinfo.offData:=lmi.offData;
      modinfo.offMan :=lmi.offMan;
    end
    else
    begin
      FVersion:=verTL2;
      // really, it zero already
      modinfo.offData:=0;
      modinfo.offMan :=0;
    end;
  end;

  result:=FVersion;
end;
{$POP}

function FixSize(var abuf:PByte; asize:integer):integer;
begin
  if abuf<>nil then
    result:=MemSize(abuf)
  else result:=0;

  if (abuf=nil) or (result<(asize+2)) then
  begin
    if abuf<>nil then FreeMem(abuf);
    result:=Align(asize+2,BufferPageSize);
    GetMem(abuf, result);
  end;
end;

//--- Unzip to memory buffer helpers (events OnCreateStream and OnDoneStream) ---

Procedure TRGPAK.CStream(Sender : TObject; var AStream : TStream; AItem : TFullZipFileEntry);
begin
  AStream:=TMemoryStream.Create;
end;

Procedure TRGPAK.DStream(Sender : TObject; var AStream : TStream; AItem : TFullZipFileEntry);
begin
  if AItem<>nil then
  begin
    FUnpSize:=AStream.Size;
    FixSize(FBuf,FUnpSize);

    move((AStream as TMemoryStream).Memory^,FBuf^,FUnpSize);
    PWord(FBuf+FUnpSize)^:=0;
  end;
  AStream.Free;
end;

procedure TRGPAK.ReadModDat(const aname:string);
var
  lname:string;
  lpos,i,lrootlen:integer;
begin
  lrootlen:=-1;
  
  for i:=0 to FUnZipper.Entries.Count-1 do
  begin

    lname:=UpCase(FUnZipper.Entries[i].ArchiveFileName);

    if lrootlen<0 then
    begin
      lpos:=Pos('MEDIA/',lname);
      if lpos>0 then
      begin
        if lpos=1 then lrootlen:=0
        else
        begin
          if lname[lpos-1]='/' then
          begin
            lrootlen:=lpos-1;
            man.Root:=pointer(UnicodeString(Copy(FUnZipper.Entries[i].ArchiveFileName,1,lrootlen)));
          end;
        end;
      end;
      if lrootlen>=0 then
        continue;
    end;

    if ExtractName(lname)='MOD.DAT' then
    begin
      if lrootlen<0 then
      begin
        man.Root:=pointer(UnicodeString(ExtractFilePath(FUnZipper.Entries[i].ArchiveFileName)));
        lrootlen:=Length(man.Root);
      end;
      FUnZipper.UnZipFile(FUnZipper.Entries[i].ArchiveFileName);
      ReadModConfig(FBuf,modinfo);

      break;
    end;
  end;

  if lrootlen<0 then lrootlen:=0;

  if modinfo.title=nil then
  begin
    if man.Root<>nil then
    begin
      modinfo.title:=CopyWide(man.Root);
      modinfo.title[lrootlen]:=#0;
    end
    else
    begin
      modinfo.title:=CopyWide(
        pointer(UnicodeString(ExtractFileNameOnly(aname))));
    end;
  end;
end;


function TRGPAK.GetCommonInfo(const aname:string):boolean;
var
  f:file of byte;
  ltmp:PByte;
  lsize:integer;
begin
  result:=false;

  if FVersion=verUnk then exit;

  man.Init;

  //--- Parse: TL1 zip file + mod info

  if ABS(FVersion)=verTL1 then
  begin

    FUnZipper:=TUnZipper.Create;

    FUnZipper.FileName:=aname;
    FUnZipper.UseUTF8:=True;
    FUnZipper.OnCreateStream:=@CStream;
    FUnZipper.OnDoneStream  :=@DStream;
    FUnZipper.Examine;

    ReadModDat(aname);
    result:=man.ParseZip(FUnZipper)>0;

    exit;
  end;

  //--- Parse: TL2ModInfo

  if FVersion=verTL2Mod then
    ReadModInfo(PChar(aname),modinfo);

  //--- Parse: read manifest

  if (FVersion=verTL2) and (Pos('.MAN',aname)<6) then
    Assign(f,aname+'.MAN')
  else
    Assign(f,aname);
  Reset(f);
  if IOResult<>0 then exit;
  
  lsize:=FileSize(f)-modinfo.offMan;
  if lsize>0 then
  begin
    GetMem(ltmp,lsize);
    Seek(f,modinfo.offMan);
    BlockRead(f,ltmp^,lsize);
    result:=man.Parse(ltmp,FVersion)>0;
    FreeMem(ltmp);
  end;
  Close(f);
end;

function TRGPAK.GetSizesInfo():boolean;
var
  lfhdr:TPAKFileHeader;
  p:PManFileInfo;
  i:integer;
begin
  if FVersion=verTL1 then exit(true);

  result:=false;

  if man.FileCount>0 then
  begin
    if OpenPAK then
    begin
      for i:=0 to man.DirCount-1 do
      begin
        if man.IsDirDeleted(i) then continue;

        if man.GetFirstFile(p,i)<>0 then
        repeat
          if p^.offset<>0 then
          begin
            FStream.Seek(modinfo.offData+p^.offset,soBeginning);
            FStream.ReadBuffer(lfhdr,SizeOf(lfhdr));
            p^.size_u:=lfhdr.size_u;
            p^.size_c:=lfhdr.size_c;
          end;
        until man.GetNextFile(p)=0;
      end;
      ClosePAK;
      result:=true;
    end;
  end;
end;

{
  Parse PAK/MOD/MAN file named ainfo.fname
}
function TRGPAK.GetInfo(const aname:string; aparse:integer=piNoParse):boolean;
begin
  result:=GetBaseInfo(aname)<>verUnk;

  if aparse<>piNoParse then
  begin
    result:=GetCommonInfo(aname);
    
    if aparse=piFullParse then
    begin
      if FSize=0 then
        result:=false
      else
        result:=GetSizesInfo();
    end;

  end;
end;

function RGPAKGetVersion(const aname:string):integer;
var
  lPAK:TRGPAK;
begin
  lPAK:=TRGPAK.Create();
  result:=lPAK.GetBaseInfo(aname);
{
  if lPAKGetInfo(aname,piNoParse) then
    result:=lPAK.Version
  else
    result:=verUnk;
}
  lPAK.Free();
end;

// need to check for existing PAK/MOD and MAN name. 
function TRGPAK.Clone(const aname:string):boolean;
var
  lin,lout:TStream;
  ls:string;
begin
  result:=false;

  ls:=MakeDataFileName();
  if ls=aname then exit;

//function ChangeFileExt(const FileName, Extension: PathStr): PathStr;

  ClosePAK();

  lin :=TFileStream.Create(ls,fmOpenRead);
  lout:=TFileStream.Create(aname,fmCreate);
  lout.CopyFrom(lin,lin.Size);
  lout.Free;
  lin.Free;
  if FVersion=verTL2 then
  begin
    ls:=MakeManFileName();

    lin :=TMemoryStream.Create; TMemoryStream(lin).LoadFromFile(ls);
    lout:=TFileStream.Create(aname+'.MAN',fmCreate);
    lout.CopyFrom(lin,lin.Size);
    lout.Free;
    lin.Free;
  end;

end;

function TRGPAK.Rename(const newname:string):boolean;
var
  old,new:string;
begin
  ClosePAK();
  old  :=MakeDataFileName();
  FName:=ExtractFilenameOnly(newname);
  new  :=MakeDataFileName();
  DeleteFile(new);
  result:=RenameFile(old,new);
  if result and (FVersion=verTL2) then
  begin
    DeleteFile(new+'.MAN');
    result:=RenameFile(old+'.MAN',new+'.MAN');
  end;
end;

//===== Files =====

function TRGPAK.ExtractFile(
    afi:PManFileInfo; out asize_u:cardinal; var abuf:PByte):cardinal;
var
  lfhdr:TPAKFileHeader;
  f:file of byte;
begin
  result:=0;

  if ABS(FVersion)=verTL1 then
  begin
    asize_u:=0;
    result :=0;
    exit;
  end;

  if opened then
  begin
    FStream.Seek(modinfo.offData+afi^.offset,soBeginning);
    FStream.ReadBuffer(lfhdr,SizeOf(lfhdr));
    afi^.size_u:=lfhdr.size_u;
    afi^.size_c:=lfhdr.size_c;
    asize_u    :=lfhdr.size_u;
    result     :=lfhdr.size_c;

    if result=0 then result:=lfhdr.size_u;
    if result>0 then
    begin
      if (abuf=nil) or (result>MemSize(abuf)) then
      begin
        FreeMem(abuf);
        GetMem(abuf,Align(result,BufferPageSize));
      end;
      FStream.ReadBuffer(abuf^,result);
    end;
  end
  else
  begin
    Assign(f,MakeDataFileName());
    Reset(f);
    if IOResult=0 then
    begin
      Seek(f,modinfo.offData+afi^.offset);
      BlockRead(f,lfhdr,SizeOf(lfhdr));
      afi^.size_u:=lfhdr.size_u;
      afi^.size_c:=lfhdr.size_c;
      asize_u    :=lfhdr.size_u;
      result     :=lfhdr.size_c;

      if result=0 then result:=lfhdr.size_u;
      if result>0 then
      begin
        if (abuf=nil) or (result>MemSize(abuf)) then
        begin
          FreeMem(abuf);
          GetMem(abuf,Align(result,BufferPageSize));
        end;
        BlockRead(f,abuf^,result);
      end;
      Close(f);
    end;
  end;
end;

function TRGPAK.ExtractFile(
    const apath, aname:UnicodeString;
    out asize_u:cardinal; var abuf:PByte):cardinal;
var
  idx:integer;
begin
  idx:=man.SearchFile(PUnicodeChar(apath),PUnicodeChar(aname));
  if idx<0 then Exit(0);

  result:=ExtractFile(PMANFileInfo(man.Files[idx]),asize_u,abuf);
end;

//----- Unpack -----

function TRGPAK.UnpackFromZip(afi:PManFileInfo; var aout:PByte):cardinal;
var
  lin:PByte;
begin
  result:=0;

  FUnZipper.UnzipOneFile(FUnZipper.Entries[afi^.offset]);
//  FUnZipper.UnZipFile(FUnZipper.Entries[afi^.offset].ArchiveFileName);

  lin:=aout;
  aout:=FBuf;
  FBuf:=lin;

  result:=FUnpSize;
end;

function TRGPAK.UnpackFromPAK(afi:PManFileInfo; var aout:PByte):cardinal;
var
  lin:PByte;
  lsize_u,lsize_c:cardinal;
begin
  result:=0;
  if afi=nil then exit;
//  if afi^.size_s=0 then exit;

  lin:=nil;
  lsize_c:=ExtractFile(afi,lsize_u,lin);
  if lsize_c>0 then
  begin
    if lsize_c=lsize_u then
    begin
      result:=lsize_u;
      if (aout=nil) or (lsize_u>MemSize(aout)) then
      begin
        FreeMem(aout);
        aout:=lin;
        exit;
      end
      else
        move(lin^,aout^,lsize_u);
    end
    else
      result:=RGFileUnpack(lin,lsize_c,aout,lsize_u);
    FreeMem(lin);
  end;
end;

function TRGPAK.UnpackSingle(afi:PManFileInfo; var aout:PByte):cardinal;
begin
  if afi=nil then exit(0);

  if ABS(FVersion)=verTL1 then
    result:=UnpackFromZip(afi,aout)
  else
    result:=UnpackFromPAK(afi,aout);
end;

function TRGPAK.UnpackFile(const afile:string; var aout:PByte):cardinal;
var
  lfi:PManFileInfo;
begin
  lfi:=PManFileInfo(man.Files[man.SearchFile(afile)]);
  if lfi=nil then exit(0);

  if ABS(FVersion)=verTL1 then
    result:=UnpackFromZip(lfi,aout)
  else
    result:=UnpackFromPAK(lfi,aout);
//  result:=UnpackSingle(PManFileInfo(man.Files[man.SearchFile(afile)]),aout);
end;

function TRGPAK.UnpackFile(apath,aname:PUnicodeChar; var aout:PByte):cardinal;
var
  lfi:PManFileInfo;
begin
  lfi:=PManFileInfo(man.Files[man.SearchFile(apath,aname)]);
  if lfi=nil then exit(0);

  if ABS(FVersion)=verTL1 then
  begin
    result:=UnpackFromZip(lfi,aout);
  end
  else
    result:=UnpackFromPAK(lfi,aout);
//  result:=UnpackSingle(PManFileInfo(man.Files[man.SearchFile(apath,aname)]),aout);
end;

function TRGPAK.UnpackFile(const afile:string; const adir:string):boolean;
var
  f:file of byte;
  ldir:string;
  lout:PByte;
  lsize:cardinal;
begin
  lout:=nil;
  lsize:=UnpackFile(afile, lout);
  if lsize>0 then
  begin
    if adir='' then
      ldir:=ExtractFilePath(afile)
    else
      ldir:=adir;
    ForceDirectories(ldir);

    Assign(f,ldir+'\'+ExtractName(afile));
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,lout^,lsize);
      Close(f);
    end;
    FreeMem(lout);
  end;

  result:=lsize>0;
end;

function TRGPAK.UnpackFile(apath,aname:PUnicodeChar; const adir:string):boolean;
var
  f:file of byte;
  ldir:UnicodeString;
  lout:PByte;
  lsize:cardinal;
begin
  lout:=nil;
  lsize:=UnpackFile(apath, aname, lout);
  if lsize>0 then
  begin
    if adir='' then
      ldir:=apath
    else
      ldir:=UnicodeString(adir);
    ForceDirectories(ldir);

    Assign(f,ldir+'\'+aname);
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,lout^,lsize);
      Close(f);
    end;
    FreeMem(lout);
  end;

  result:=lsize>0;
end;

{$PUSH}
{$I-}
//!! filter needs
function TRGPAK.UnpackAll(const adir:string):boolean;
var
  f:file of byte;
  ldir,lcurdir:UnicodeString;
  p:PManFileInfo;
  lout:PByte;
  i:integer;
  lres:integer;
begin
  if ABS(FVersion)=verTL1 then
  begin
    FUnZipper.OutputPath:=adir;
    FUnzipper.UnzipAllFiles;

    exit(true);
  end;

  result:=false;

  //--- Analize MAN part

  if man.DirCount=0 then
  begin
    exit;
  end;

  //--- Prepare source file

  OpenPAK();
  
  //--- Creating destination dir

  if adir<>'' then
  begin
//    FSrcDir:={UnicodeString}(adir+'/'); //??
    ldir:=UnicodeString(adir)+'\'
  end
  else
    ldir:='';

  ForceDirectories(ldir+'MEDIA'); //!! ainfo.root

  //--- Unpacking

  lout:=nil;
  lres:=0;

  for i:=0 to man.DirCount-1 do
  begin
    if man.IsDirDeleted(i) then continue;

    //!! dir filter here
    if OnPAKProgress<>nil then
    begin
      lres:=OnPAKProgress(self,i,nil);
      if lres<>0 then break;
    end;
    lcurdir:=ldir+UnicodeString(man.Dirs[i].name);
    if lcurdir<>'' then
      ForceDirectories(lcurdir);

    if man.GetFirstFile(p,i)<>0 then
    repeat
      if (p^.offset>0) and (p^.size_s>0) then
      begin
        //!! file filter here
        if OnPAKProgress<>nil then
        begin
          lres:=OnPAKProgress(self,i,p);
          if lres<>0 then break;
        end;

        UnpackSingle(p,lout);

        // save file
        Assign (f,lcurdir+UnicodeString(p^.name));
        Rewrite(f);
        if IOResult=0 then
        begin
          BlockWrite(f,lout^,p^.size_u);
          Close(f);
        end;

      end
      //!! size/offset = 0 means "delete file"
      else
      begin
        if OnPAKProgress<>nil then
        begin
          lres:=OnPAKProgress(self,-i,p);
          if lres<>0 then break;
        end;

        //!! if type = 'delete dir' then remove dir
      end;

    until man.GetNextFile(p)=0;

    if lres<>0 then break;
  end;

  FreeMem(lout);

  ClosePAK();

  result:=true;
end;
{$POP}

//--- TL2 version only

{$PUSH}
{$Q-,R-}
function TRGPAK.PAKHash(ast:TStream; asize:Int64):dword;
var
  lpos,lhash:Int64;
  seed:QWord;
  lofs:qword;
  step:integer;
  lbyte:byte;
begin
  result:=0;

  if asize=0 then exit;

  lpos:=ast.Position;

  seed:=(asize shr 32)+(asize and $FFFFFFFF)*$29777B41;
  seed:=25+((seed and $FFFFFFFF) mod 51);
  if seed>75 then seed:=75;

  step:=asize div seed;
  if step<2 then step:=2;
  lhash:=asize;

  lofs:=lpos+8; // +SizeOf(TTL2Header) ??
  while lofs<(lpos+asize) do
  begin
    ast.Position:=lofs;
    lbyte:=ast.ReadByte();
    lhash:=((lhash*33)+shortint(lbyte)) and $FFFFFFFF;
    lofs:=lofs+step;
  end;
  ast.Position:=lpos+asize-1;
  lbyte:=ast.ReadByte();

  result:=dword(((lhash*33)+shortint(lbyte)) and $FFFFFFFF);

  ast.Position:=lpos;
end;
{$POP}

//----- Pack -----
(*
{TODO: pack separate file}
procedure PackFile(var ainfo:TRGPAK;
    apath,aname:PUnicodeChar;
    abuf:PByte; asize:integer);
var
  mi:PManFileInfo;
  lbuf:PByte;
  lsize:cardinal;
begin
  // just add to MAN or remove from pack or modify MAN
  if (asize=0) or (abuf=nil) then ;

  mi:=PManFileInfo(ainfo.man.Files[ainfo.man.SearchFile(apath,aname)]);
  if mi<>nil then
  begin
    // Compile if needs
    // Pack file if need to pack
    lsize:=0;
    lbuf:=nil;
    lsize:=RGFilePack(abuf,asize,lbuf,lsize);
    if lsize<=mi^.size_c then
     // patch
    else
    ; // rewrite to the end

    // replace in PAK if not greater than existing
    // or add to the end
  end
  else
  begin
    // Add to MAN, add to the end of PAK
//    mi:=rgman.AddFile(ainfo.man,apath,aname);
  end;
end;
*)
//----- something -----
{$IFDEF DEBUG}
function DoProgress(const ainfo:TRGPAK; adir:integer; afile:PManFileInfo):integer;
var
//  ldir:string;
  p,l:PUnicodeChar;
begin
  result:=0;
//  ldir:=WideToStr(ainfo.man.GetDirName(ABS(adir)));
  if adir<0 then
  begin
    p:=ConcatWide(ainfo.man.Dirs[ABS(adir)].name,afile^.name);
    l:=ConcatWide('Skipping dummy ',p);
    RGLog.Add(WideToStr(l));
//    RGLog.Add('Skipping dummy ' +WideToStr(p));
    FreeMem(p);
    FreeMem(l);
//    RGLog.Add('Skipping dummy ' +ldir+WideToStr(ainfo.man.GetName(afile^.name)))
  end
  else if afile<>nil then
  begin
    p:=ConcatWide(ainfo.man.Dirs[adir].name,afile^.name);
    l:=ConcatWide('Processing file ',p);
    RGLog.Add(WideToStr(l));
//    RGLog.Add('Processing file '+WideToStr(p));
    FreeMem(p);
    FreeMem(l);
//    RGLog.Add('Processing file '+ldir+WideToStr(ainfo.man.GetName(afile^.name)))
  end
  else
  begin
    p:=ConcatWide('Processing dir ',ainfo.man.Dirs[adir].name);
    RGLog.Add(WideToStr(p));
    FreeMem(p);
//    RGLog.Add('Processing dir '+WideToStr(ainfo.man.GetDirName(adir)));
//    RGLog.Add('Processing dir '+ldir);
  end;
end;
{$ENDIF}

//===== Manipulation =====

function RGPAKSplit(const asrc:string; const adir:string=''; const afname:string=''):integer;
var
  ffin,ffout: file of byte;
  mi:TTL2ModInfo;
  lfname:string;
  ltmp:pbyte;
  lsize,fsize:integer;
begin
  result:=-1;

  // .MOD files only
  if (Length(asrc)>4) and
     (Pos('.MOD',UpCase(asrc))=(Length(asrc)-3)) then
  begin
    if ReadModInfo(PChar(asrc),mi) then
    begin
      if adir='' then
        lfname:=ExtractFilePath(asrc)
      else
      begin
        lfname:=adir;
        if not (lfname[Length(lfname)] in ['\','/']) then lfname:=lfname+'\';
      end;
      if lfname<>'' then ForceDirectories(lfname);
      if afname='' then
        lfname:=lfname+ExtractFileNameOnly(asrc)
      else
        lfname:=lfname+afname;

{
      fin:=TFileStream.Create(asrc,fmOpenRead);
}
      AssignFile(ffin,asrc);
      Reset(ffin);
      fsize:=FileSize(ffin);

      // PAK file
{
      fout:=TFileStream.Create(lfname+'.PAK',fmCreate);
      fin.Position:=mi.offData;
      fout.CopyFrom(fin,mi.offMan-mi.offData);
      fout.Free;
}
      AssignFile(ffout,lfname+'.PAK');
      Rewrite(ffout);
      Seek(ffin,mi.offData);
      lsize:=mi.offMan-mi.offData;
      GetMem    (      ltmp ,lsize);
      BlockRead (ffin ,ltmp^,lsize);
      BlockWrite(ffout,ltmp^,lsize);
      CloseFile(ffout);

      // MAN file
{
      fout:=TFileStream.Create(lfname+'.PAK.MAN',fmCreate);
      fin.Position:=mi.offMan;
      fout.CopyFrom(fin,fin.Size-mi.offMan);
      fout.Free;
}
      AssignFile(ffout,lfname+'.PAK.MAN');
      Rewrite(ffout);
      Seek(ffin,mi.offMan);
      fsize:=fsize-mi.offMan;
      if fsize>lsize then
      begin
        FreeMem(ltmp);
        GetMem(ltmp,fsize);
      end;
      BlockRead (ffin ,ltmp^,fsize);
      BlockWrite(ffout,ltmp^,fsize);
      FreeMem(ltmp);
      CloseFile(ffout);

{
      fin.Free;
}
      CloseFile(ffin);

      // DAT file
      SaveModConfig(mi,PChar(lfname+'.DAT'));

      result:=0;
    end;
    ClearModInfo(mi);
  end;
end;

function RGPAKCombine(const apak,aman:string;
                      amod:PByte; asize:integer;
                      const adir:string=''):integer;
var
  fin,fout:TFileStream;
  lname,ldir:string;
begin
  result:=-1;

  if FileExists(apak) and
     FileExists(aman) then
  begin
    lname:=ExtractFileNameOnly(apak);
    if adir<>'' then
    begin
      ldir:=adir;
    end
    else
      ldir:=ExtractFileDir(apak);
    if ldir<>'' then
    begin
      if not (ldir[Length(ldir)] in ['\','/']) then ldir:=ldir+'\';
      ForceDirectories(ldir);
    end;

    fout:=TFileStream.Create(ldir+lname+'.MOD',fmCreate);

    fin:=TFileStream.Create(apak,fmOpenRead);

    PTL2ModTech(amod)^.offData:=asize;
    PTL2ModTech(amod)^.offMan :=asize+fin.Size;
    fout.Write(amod^,asize);

    fout.CopyFrom(fin,fin.Size);
    fin.Free;

    fin:=TFileStream.Create(aman,fmOpenRead);
    fout.CopyFrom(fin,fin.Size);
    fin.Free;

    fout.Free;

    result:=0;
  end;
end;

function RGPAKCombine(const apak,aman:string;
                      const amod:TTL2ModInfo;
                      const adir:string=''):integer;
var
  lbuf:PByte;
  lsize:integer;
begin
  lsize:=WriteModInfo(lbuf,amod);
  result:=RGPAKCombine(apak,aman,lbuf,lsize,adir);
  FreeMem(lbuf);
end;

function RGPAKCombine(const apak,aman,amod:string; const adir:string=''):integer;
var
  lmi:TTL2ModInfo;
begin
  if FileExists(amod) then
    LoadModConfig(PChar(amod),lmi)
  else
  begin
    MakeModInfo(lmi);
    lmi.title:=StrToWide(ExtractFileNameOnly(apak));
  end;
  result:=RGPAKCombine(apak,aman,lmi,adir);

  ClearModInfo(lmi);
end;

function RGPAKCombine(const asdir,aname:string; const adir:string=''):integer;
var
  lmi:TTL2ModInfo;
  lname,ldir:string;
begin
  ldir:=asdir;
  if ldir<>'' then
    if not (ldir[Length(ldir)] in ['\','/']) then ldir:=ldir+'\';
  lname:=ldir+aname;

  if      FileExists(lname+'.DAT'  ) then LoadModConfig(PChar(lname+'.DAT'  ),lmi)
  else if FileExists(ldir+'MOD.DAT') then LoadModConfig(PChar(ldir+'MOD.DAT'),lmi)
  else
  begin
    MakeModInfo(lmi);
    lmi.title:=StrToWide(aname);
  end;
  
  result:=RGPAKCombine(lname+'.PAK', lname+'.PAK.MAN', lmi, adir);

  ClearModInfo(lmi);
end;


function TRGPAK.CreatePAK(const afname:string; amod:PTL2ModInfo; aver:integer):integer;
var
  TL2PAKHeader:TTL2PAKHeader;
  RGOPAKHeader:TRGOPAKHeader;
  PAKHeader   :TPAKHeader;
  lsname:string;
begin
  result:=0;
{
  Free;
  Init;
}
  //--- Initialization

  FVersion:=aver;
  FSrcDir :=ExtractFilePath(afname);
  FName   :=ExtractFileNameOnly(afname);
  if FBuf=nil then GetMem(FBuf,BufferStartSize);
  man.Root:=nil;

  lsname:=MakeDataFileName();
  if lsname='' then exit;

  FStream:=TFileStream.Create(lsname,fmCreate);

  //--- Write MOD info

  if amod<>@modinfo then
  begin
    if amod<>nil then
      CopyModInfo(modinfo,amod^)
    else
      MakeModInfo(modinfo);
  end;

  if FVersion=verTL2Mod then
    WriteModInfoStream(FStream,modinfo);

  {!!!!!!!!!!!!!!!!old offset must be saved for reading!!!!!!!!!!!!!!}
  modinfo.offData:=FStream.Position;

  // Just reserve place
  case ABS(FVersion) of
    verTL2: FStream.Write(TL2PAKHeader,SizeOf(TTL2PAKHeader));
    verRGO: FStream.Write(RGOPAKHeader,SizeOf(TRGOPAKHeader));
  else      FStream.Write(PAKHeader   ,SizeOf(TPAKHeader));
  end;
end;

procedure TRGPAK.FinishPAK;
var
  TL2PAKHeader:TTL2PAKHeader;
  RGOPAKHeader:TRGOPAKHeader;
  PAKHeader:TPAKHeader;
  lmodinfo:TTL2ModTech;
begin
  //--- Write MAN

  if FVersion=verTL2 then
  begin
    modinfo.offMan:=0;
    man.SaveToFile(MakeManFileName(),FVersion);
  end
  else
  begin
    modinfo.offMan:=FStream.Size;
    if FVersion=verTL2Mod then
    begin
      lmodinfo.version:=4;
      lmodinfo.modver :=modinfo.modver;
      lmodinfo.offData:=modinfo.offData;
      lmodinfo.offMan :=modinfo.offMan;
      QWord(lmodinfo.gamever):=ReverseWords(modinfo.gamever);

      FStream.Position:=0;
      FStream.Write(lmodinfo,SizeOf(lmodinfo));
      FStream.Position:=FStream.Size;
    end;
    man.SaveToStream(FStream,FVersion);
  end;

  //--- Change PAK Header
  
  FStream.Position:=modinfo.offData;

  case ABS(FVersion) of
    verTL2: begin
      TL2PAKHeader.MaxCSize:=man.LargestPacked;
      TL2PAKHeader.Hash    :=PAKHash(FStream,modinfo.offMan-modinfo.offData);
      FStream.Write(TL2PAKHeader,SizeOf(TTL2PAKHeader))
    end;
    verRGO: begin
      RGOPAKHeader.Version  :=5;
      RGOPAKHeader.Reserved :=0;
      RGOPAKHeader.ManOffset:=modinfo.offMan;
      RGOPAKHeader.ManSize  :=FStream.Size-modinfo.offMan;
      RGOPAKHeader.MaxUSize :=man.LargestUnpacked;
      FStream.Write(RGOPAKHeader,SizeOf(TRGOPAKHeader));
    end;
  else
    if      ABS(FVersion)=verHob then PAKHeader.Version:=5
    else if ABS(FVersion)=verRG  then PAKHeader.Version:=1;
    PAKHeader.Reserved :=0;
    PAKHeader.ManOffset:=modinfo.offMan;
    PAKHeader.MaxUSize :=man.LargestUnpacked;
    FStream.Write(PAKHeader,SizeOf(TPAKHeader));
  end;

  ClosePAK();
end;

function TRGPAK.WritePackedFile(adata:PByte; asize_u,asize_c:dword):dword;
begin
  result:=FStream.Position-modinfo.offData;
  FStream.WriteDword(asize_u);
  if asize_u=asize_c then
    FStream.WriteDword(0)
  else
    FStream.WriteDword(asize_c);
  FStream.Write(adata^,asize_c);
end;

function TRGPAK.WriteFile(adata:PByte; asize:integer; apack:boolean; var offset:dword):dword;
var
  lsize:cardinal;
begin
  if (adata<>nil) and (asize>0) then
  begin
    // write as is
    if not apack then
    begin
      offset:=WritePackedFile(adata,asize,asize);
      result:=asize;
    end
    // unpacked but need to pack
    else
    begin
      if FBuf=nil then
        lsize:=0
      else
        lsize:=MemSize(FBuf);
      result:=RGFilePack(adata,asize,FBuf,lsize);

      if result>0 then
        offset:=WritePackedFile(FBuf,asize,result);
    end;

    if OnPAKProgress<>nil then
    begin
//      if OnPAKProgress(self,adir,p)<>0 then break;
    end;
  end
  else
  begin
    result:=0;

    if OnPAKProgress<>nil then
    begin
//      if OnPAKProgress(self,-adir,nil{p})<>0 then break;
    end;
  end;

  if result=0 then offset:=0;
end;
(*
function TRGPAK.AddDirectory(apath:PWideChar):integer;
begin
  result:=man.AddPath(apath);
  if OnPAKProgress<>nil then
  begin
    if OnPAKProgress(self,result,nil)<>0 then
      result:=-1;
  end;
end;

procedure TRGPAK.AddFile(adir:integer; ainfo:PFileInfo; asize_c:integer=0);
var
  p:PManFileInfo;
begin
  p:=PManFileInfo(man.Files[man.CloneFile(adir,ainfo)]);
  p^.size_c:=asize_c;

//  {p^.size_c:=}WriteFile(p^.data,^.size_u,GetExtInfo(p^.name,Version)^._pack,p^.offset);
end;
*)
{
  Use Manifest to build PAK from disk files
}
procedure TRGPAK.Build;
var
  f:file of byte;
  lname,ldir:PWideChar;
  p:PManFileInfo;
  lin:PByte;
  lisize,i,lres:integer;
begin
  CreatePak(FSrcDir+FName+'.TMP',@modinfo,FVersion);

  lin:=nil;
  lisize:=0;

  // not necessary but sort by dir
  for i:=0 to man.DirCount-1 do
  begin
    if man.IsDirDeleted(i) then continue;

    ldir:=ConcatWide(PUnicodeChar(UnicodeString(FSrcDir)),man.Dirs[i].name); //!!!!

    if man.GetFirstFile(p,i)<>0 then
    repeat
      if (p^.ftype in [typeDirectory,typeDelete]) or
         (p^.size_s = 0) then
      begin
        if OnPAKProgress<>nil then
        begin
          lres:=OnPAKProgress(self,-i,p);
          if lres<>0 then break;
        end;
        continue;
      end;

      if OnPAKProgress<>nil then
      begin
        lres:=OnPAKProgress(self,i,p);
        if lres<>0 then break;
      end;
      
      //--- Read file into memory

      //?? use "p^.filename" field if exists?
      lname:=ConcatWide(ldir,p^.name);
      Assign(f,lname);
      FreeMem(lname);
      Reset(f);
      if IOResult<>0 then continue;

      p^.size_u:=FileSize(f);

      if lisize<p^.size_u then
      begin
        lisize:=Align(p^.size_u,BufferPageSize);
        FreeMem(lin);
        GetMem(lin,lisize);
      end;
      BlockRead(f,lin^,p^.size_u);
      Close(f);

      WriteFile(lin,p^.size_u,PakTypeInfo(p^.ftype,FVersion)^._pack,p^.offset);

    until man.GetNextFile(p)=0;
    FreeMem(ldir);
  end;
  
  FreeMem(lin);

  FinishPAK;
end;


initialization
{$IFDEF DEBUG}
  OnPAKProgress:=@DoProgress;
{$ELSE}
  OnPAKProgress:=nil;
{$ENDIF}
end.
