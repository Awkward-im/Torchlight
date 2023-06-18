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
  ??Convert combined PAK to MOD
}
unit RGPAK;

interface

uses
  classes,
  rgman,
  rgglobal;

//===== Container =====

const
  piNoParse   = 0; // just PAK version and MAN offset
  piParse     = 1; // TL2 MOD info, MAN content
  piFullParse = 2; // with packed/unpacked file size

type
  PPAKInfo = ^TRGPAK;
  TRGPAK = object
  private
    FStream:TStream;
    maxsize:integer;         // max [unpacked] file size
  public
    man    :TRGManifest;
    modinfo:TTL2ModInfo;
  private
    FSrcDir :String;         // PAK file directory
    FName   :String;         // filename only or fullname
    FSize   :longword;       // total PAK size
    FTime   :UInt64;         // PAK file timestamp
    FOffData:longword;       // data offset // IntPtr for memory address?
    FOffMan :longword;       // MAN offset
    FVersion:integer;
  private
    // return file name with proper ext
    function  MakeDataFileName:String;
    function  MakeManFileName :String;
    function  GetOpenStatus:boolean;
    // set (if available) largest packed / unpacked file sizes
    procedure GetMaxSizes  (out acmax,aumax:integer);
    // version, data and manifest offsets
    function  GetBaseInfo  (const aname:string):integer;
    // modinfo and manifest
    function  GetCommonInfo(const aname:string):boolean;
    // file sizes to manifest
    function  GetSizesInfo ():boolean;
    // TL2 data hash calculation
    function  PAKHash(ast:TStream; asize:integer):dword;
  public
    procedure Init;
    procedure Free;
    function  OpenPAK:boolean;
    procedure ClosePAK;
    function  GetInfo(const aname:string; aparse:integer=piNoParse):boolean;
  public
//    function ExtractFile(const apath, aname:UnicodeString; out asize_u:integer; ast:TStream   ):integer;
    function ExtractFile(const apath, aname:UnicodeString; out asize_u:integer; var abuf:PByte):integer;
  public
    function  UnpackSingle(afi:PMANFileInfo; var aout:PByte):integer;

    function  UnpackFile(const afile:string; var aout:PByte):integer;
    function  UnpackFile(const afile:string; const adir:string):boolean;
    function  UnpackFile(apath,aname:PUnicodeChar; var aout:PByte):integer;
    function  UnpackFile(apath,aname:PUnicodeChar; const adir:string):boolean;

    function  UnpackAll (const adir:string):boolean;
  public
    procedure PackAll;
  public
    property opened:boolean read GetOpenStatus;

    // get from OS file info
    property Size      :longword read FSize;
    property Time      :UInt64   read FTime;
    // get from call
    property Name      :String   read FName   write FName;
    property Directory :String   read FSrcDir write FSrcDir;
    // get from parsing, changing by code
    property DataOffset:longword read FOffData;
    property MANOffset :longword read FOffMan;
    // get from parsing but can be changed later
    property Version   :integer  read FVersion write FVersion;
  end;

function RGPAKGetVersion(const aname:string):integer;

type
  TPAKProgress = function(const ainfo:TRGPAK; adir:integer; afile:PMANFileInfo):integer;
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
  paszlib,
  bufstream,
  {$IFDEF DEBUG}
  logging,
  {$ENDIF}
  rgdebug,

  rgfiletype,
  tl2mod;

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
type
  PPAKFileHeader = ^TPAKFileHeader;
  TPAKFileHeader = packed record
    size_u:UInt32;
    size_c:UInt32;      // 0 means "no compression
  end;


procedure TRGPAK.Init();
begin
  FillChar(self,SizeOf(TRGPAK),0);
  FVersion:=verUnk;

  man.Init;
end;

procedure TRGPAK.Free();
begin
  ClosePAK;
  man.Free();
  ClearModInfo(modinfo);

  // clear
  FName  :='';
  FSrcDir:='';
  FillChar(self,SizeOf(TRGPAK),0);
  FVersion:=verUnk;
end;

function TRGPAK.MakeDataFileName():String;
begin
  case FVersion of
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
    verHob,
    verRGO,
    verRG    : result:=FSrcDir+FName+'.PAK';
    verTL2   : result:=FSrcDir+FName+'.PAK.MAN';
    verTL2Mod: result:=FSrcDir+FName+'.MOD';
  else
    result:='';
  end;
end;

procedure TRGPAK.GetMaxSizes(out acmax,aumax:integer);
begin
  if ABS(FVersion)=verTL2 then
  begin
    aumax:=man.LargestUnpacked;
    acmax:=man.LargestPacked;
    if acmax=0 then acmax:=maxsize;
  end
  else
  begin
    acmax:=man.LargestPacked;
    aumax:=man.LargestUnpacked;
    if aumax=0 then aumax:=maxsize;
  end;
end;

//----- PAK/MOD -----

function TRGPAK.GetOpenStatus:boolean; inline;
begin
  result:=FStream<>nil;
end;

function TRGPAK.OpenPAK:boolean;
begin
  result:=false;

  if (FName='') or (FSize=0) then exit;

  if FStream=nil then
  begin
    if FSize<=MaxSizeForMem then //!!!!!!! get it just in Get Basic Info atm
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
  lhdr2:TTL2PAKHeader absolute buf;
  lhdro:TRGOPAKHeader absolute buf;
  lmi  :TTL2ModTech   absolute buf;
  f:file of byte;
  lext:string;
begin
  FVersion:=verUnk;
  FOffData:=0;
  FOffMan :=0;

  if aname<>'' then
  begin
    FSrcDir:=(ExtractFilePath    (aname));
    FName  :=(ExtractFilenameOnly(aname));
  end
  else
    exit;

  //--- Check by ext

  lext:=UpCase(ExtractFileExt(aname));

  if lext='.MAN' then
  begin
    FName:=ExtractFilenameOnly(FName);
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
//      FOffData:=SizeOf(TPAKHeader);
    end
    else if lhdr.Version=5 then
    begin
      if lhdro.ManSize=(FSize-lhdro.ManOffset) then
      begin
        FVersion:=verRGO;
//        FOffData:=SizeOf(TRGOPAKHeader);
      end
      else
      begin
        FVersion:=verHob;
//        FOffData:=SizeOf(TPAKHeader);
      end;
    end;

    FOffData:=0;
    FOffMan :=lhdr.ManOffset;
  end
  else
  begin
    // if we have MOD header
    if ((lmi.version=4) and (lmi.gamever[0]=1)) or
       (lext='.MOD') then
    begin
      FVersion:=verTL2Mod;
      FOffData:=lmi.offData;
      FOffMan :=lmi.offMan;
    end
    else
    begin
      FVersion:=verTL2;
//      FOffData:=SizeOf(TTL2PAKHeader);
      FOffData:=0;
      FOffMan :=0;
    end;
  end;

  result:=FVersion;
end;
{$POP}

function TRGPAK.GetCommonInfo(const aname:string):boolean;
var
  f:file of byte;
  ltmp:PByte;
  lsize:integer;
begin
  result:=false;

  //--- Parse: TL2ModInfo

  if FVersion=verTL2Mod then
    ReadModInfo(PChar(aname),modinfo);

  //--- Parse: read manifest

  man.Init;

  if (FVersion=verTL2) and (Pos('.MAN',aname)<6) then
    Assign(f,aname+'.MAN')
  else
    Assign(f,aname);
  Reset(f);
  if IOResult<>0 then exit;
  
  lsize:=FileSize(f)-FOffMan;
  if lsize>0 then
  begin
    GetMem(ltmp,lsize);
    Seek(f,FOffMan);
    BlockRead(f,ltmp^,lsize);
    result:=man.Parse(ltmp,FVersion)>0;
    FreeMem(ltmp);
  end;
  Close(f);
end;

{$PUSH}
{$I-}
function TRGPAK.GetSizesInfo():boolean;
var
  lfhdr:TPAKFileHeader;
  p:PMANFileInfo;
  lStream:TStream;
  i:integer;
begin
  result:=false;

  if FOffData>0 then // mean, we read base info and this file is not .MAN
  begin
    // OpenPAK code analog
    if FSize<=MaxSizeForMem then
    begin
      lStream:=TMemoryStream.Create;
      try
        TMemoryStream(lStream).LoadFromFile(MakeDataFileName());
      except
        FreeAndNil(lStream);
      end;
    end
    else
    begin
      try
        lStream:=TBufferedFileStream.Create(MakeDataFileName(),fmOpenRead);
      except
      end;
    end;

    if lStream<>nil then
    begin
      for i:=0 to man.EntriesCount-1 do
      begin
        if man.IsDirDeleted(i) then continue;

        if man.GetFirstFile(p,i)<>0 then
        repeat
          if p^.offset<>0 then
          begin
            lStream.Seek(FOffData+p^.offset,soBeginning);
    //        lfhdr.size_u:=0;
    //        lfhdr.size_c:=0;
            lStream.ReadBuffer(lfhdr,SizeOf(lfhdr));
            p^.size_u:=lfhdr.size_u;
            p^.size_c:=lfhdr.size_c;
          end;
        until man.GetNextFile(p)=0;
      end;
      // ClosePAK analog
      FreeAndNil(lStream);
    end;
    
    result:=true;
  end;
end;
{$POP}

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
      if fsize=0 then
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
  lPAK.Init();
  result:=lPAK.GetBaseInfo(aname);
{
  if lPAKGetInfo(aname,piNoParse) then
    result:=lPAK.Version
  else
    result:=verUnk;
}
  lPAK.Free();
end;

//===== Files =====

function TRGPAK.ExtractFile(
    const apath, aname:UnicodeString;
    out asize_u:integer; var abuf:PByte):integer;
var
  p:PMANFileInfo;
  lfhdr:TPAKFileHeader;
  f:file of byte;
begin
  result:=0;

  p:=man.SearchFile(PUnicodeChar(apath),PUnicodeChar(aname));
  if p=nil then Exit;

  if opened then
  begin
    FStream.Seek(FOffData+p^.offset,soBeginning);
    FStream.ReadBuffer(lfhdr,SizeOf(lfhdr));
    p^.size_u:=lfhdr.size_u;
    p^.size_c:=lfhdr.size_c;
    asize_u  :=lfhdr.size_u;
    result   :=lfhdr.size_c;
    // for unpacked saves
    if result=0 then result:=lfhdr.size_u;
    if result>0 then
    begin
      if (abuf=nil) or (result>MemSize(abuf)) then
        ReallocMem(abuf,Align(result,BufferPageSize));
      FStream.ReadBuffer(abuf^,result);
    end;
//    if lclosed then ClosePAK;
  end
  else
  begin
    Assign(f,MakeDataFileName());
    Reset(f);
    if IOResult=0 then
    begin
      Seek(f,FOffData+p^.offset);
      BlockRead(f,lfhdr,SizeOf(lfhdr));
      p^.size_u:=lfhdr.size_u;
      p^.size_c:=lfhdr.size_c;
      asize_u  :=lfhdr.size_u;
      result   :=lfhdr.size_c;
      // for unpacked saves
      if result=0 then result:=lfhdr.size_u;
      if result>0 then
      begin
        if (abuf=nil) or (result>MemSize(abuf)) then
          ReallocMem(abuf,Align(result,BufferPageSize));
        BlockRead(f,abuf^,result);
      end;
      Close(f);
    end;
  end;
end;

//----- Unpack -----

function TRGPAK.UnpackSingle(afi:PMANFileInfo; var aout:PByte):integer;
var
  f:file of byte;
  lfhdr:TPAKFileHeader;
  lin:PByte;
begin
  result:=0;

  if afi<>nil then
  begin
    if afi^.size_s=0 then exit;

    if opened then
    begin
      FStream.Position:=FOffData+afi^.offset;
      FStream.ReadBuffer(lfhdr,SizeOf(lfhdr));

      afi^.size_u:=lfhdr.size_u;
      afi^.size_c:=lfhdr.size_c;

      if (aout=nil) or (MemSize(aout)<lfhdr.size_u) then
        ReallocMem(aout,Align(lfhdr.size_u,BufferPageSize));

      if lfhdr.size_c>0 then
      begin
        if (FStream is TMemoryStream) then
        begin
          uncompress(
              PChar(aout),lfhdr.size_u,
              PChar(TMemoryStream(FStream).Memory+FStream.Position),lfhdr.size_c);
        end
        else
        begin
          GetMem(lin,lfhdr.size_c);
          FStream.ReadBuffer(lin^,lfhdr.size_c);

          uncompress(
              PChar(aout),lfhdr.size_u,
              PChar(lin ),lfhdr.size_c);

          FreeMem(lin);
        end;
      end
      else
      begin
        FStream.ReadBuffer(aout^,lfhdr.size_u);
      end;
    end
    else
    begin
      Assign(f,MakeDataFileName());
      Reset(f);
      if IOResult<>0 then exit;

      Seek(f,FOffData+afi^.offset);
      BlockRead(f,lfhdr,SizeOf(lfhdr));

      afi^.size_u:=lfhdr.size_u;
      afi^.size_c:=lfhdr.size_c;

      if (aout=nil) or (MemSize(aout)<lfhdr.size_u) then
        ReallocMem(aout,Align(lfhdr.size_u,BufferPageSize));

      if lfhdr.size_c>0 then
      begin
        GetMem(lin,lfhdr.size_c);
        BlockRead(f,lin^,lfhdr.size_c);

        uncompress(
            PChar(aout),lfhdr.size_u,
            PChar(lin ),lfhdr.size_c);

        FreeMem(lin);
      end
      else
      begin
        BlockRead(f,aout^,lfhdr.size_u);
      end;

      Close(f);
    end;

    result:=lfhdr.size_u;
  end;
end;

function TRGPAK.UnpackFile(const afile:string; var aout:PByte):integer;
begin
  result:=UnpackSingle(man.SearchFile(afile),aout);
end;

function TRGPAK.UnpackFile(apath,aname:PUnicodeChar; var aout:PByte):integer;
begin
  result:=UnpackSingle(man.SearchFile(apath,aname),aout);
end;

function TRGPAK.UnpackFile(const afile:string; const adir:string):boolean;
var
  f:file of byte;
  ldir:string;
  lout:PByte;
  lsize:integer;
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

    Assign(f,ldir+'\'+ExtractFileName(afile));
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
  lsize:integer;
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
  result:=false;

  //--- Analize MAN part

  if man.EntriesCount=0 then
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

  ForceDirectories{CreateDir}(ldir+'MEDIA'); //!! ainfo.root

  //--- Unpacking

  lout:=nil;
  lres:=0;

  for i:=0 to man.EntriesCount-1 do
  begin
    if man.IsDirDeleted(i) then continue;

    //!! dir filter here
    if OnPAKProgress<>nil then
    begin
      lres:=OnPAKProgress(self,i,nil);
      if lres<>0 then break;
    end;
    lcurdir:=ldir+UnicodeString(man.GetDirName(i));
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
        Assign (f,lcurdir+UnicodeString(man.GetName(p^.name)));
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
function TRGPAK.PAKHash(ast:TStream; asize:integer):dword;
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

{$PUSH}
{$I-}
procedure TRGPAK.PackAll();
var
  f:file of byte;
  spak:TFileStream;
  p:PManFileInfo;
  TL2PAKHeader:TTL2PAKHeader; //??
  RGOPAKHeader:TRGOPAKHeader; //??
  PAKHeader:TPAKHeader;       //??
  lmodinfo:TTL2ModTech;
  lout,lin:PByte;
  ldir:PUnicodeChar;
  lname:PUnicodeChar;
  lsname:string;
  lManPos,lPakPos,lisize,losize:longword;
  largest_u,largest_c:integer;
  i,lres:integer;
begin
  //--- Initialization

  lsname:=MakeDataFileName();
  if lsname='' then exit;

  GetMaxSizes(largest_c,largest_u);
  if largest_u>0 then
  begin
    lisize:=Align(largest_u,BufferPageSize);
    losize:=Round(lisize*1.2)+12;
    GetMem(lin ,lisize);
    GetMem(lout,losize);
  end
  else
  begin
    lisize:=0;
    lin   :=nil;
    lout  :=nil;
  end;

  //--- Write MOD
  if FVersion=verTL2Mod then
  begin
    // use (if implemented) WriteModInfoStream
    lPakPos:=WriteModInfo(PChar(lsname),modinfo);
    spak:=TFileStream.Create(lsname,fmOpenReadWrite); //!! backup old??
    spak.Position:=lPakPos;
  end
  //--- Write PAK
  else
  begin  
    lPakPos:=0;
    spak:=TFileStream.Create(lsname,fmCreate); //!! backup old??
  end;

  // Just reserve place
  case ABS(FVersion) of
    verTL2: spak.Write(TL2PAKHeader,SizeOf(TTL2PAKHeader));
    verRGO: spak.Write(RGOPAKHeader,SizeOf(TRGOPAKHeader));
  else      spak.Write(PAKHeader   ,SizeOf(TPAKHeader));
  end;

  for i:=0 to man.EntriesCount-1 do
  begin
    if man.IsDirDeleted(i) then continue;

    ldir:=ConcatWide(PUnicodeChar(UnicodeString(FSrcDir)),man.GetDirName(i)); //!!!!

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
      
      p^.offset:=spak.Position;

      //--- Read file into memory

      //?? use "p^.filename" field if exists?
      lname:=ConcatWide(ldir,man.GetName(p^.name));
      Assign(f,lname);
      FreeMem(lname);
      Reset(f);
      if IOResult<>0 then continue;

      p^.size_u:=FileSize(f);
      if lisize<p^.size_u then
      begin
        lisize:=Align(p^.size_u,BufferPageSize);
        losize:=Round(lisize*1.2)+12;
        ReallocMem(lin ,lisize);
        ReallocMem(lout,losize);
      end;
      BlockRead(f,lin^,p^.size_u);
      Close(f);

      //--- Process

      p^.checksum:=crc32(0,PChar(lin),p^.size_u);

      spak.Write(p^.size_u,4);
      if largest_u<p^.size_u then largest_u:=p^.size_u;
      // write uncompressed
      if not PAKTypeInfo(p^.ftype,FVersion)^._pack then
      begin
        spak.WriteDword(0);
        spak.Write(lin^,p^.size_u);
      end
      else
      begin
        p^.size_c:=losize;
        if compress(PChar(lout),p^.size_c,PChar(lin),p^.size_u)<>Z_OK then //!!!
        begin
          if OnPAKProgress<>nil then
          begin
            lres:=OnPAKProgress(self,-i,p);
            if lres<>0 then break;
          end;
        end;
        
        if largest_c<p^.size_c then largest_c:=p^.size_c;

        spak.Write(p^.size_c,4);
        spak.Write(lout^,p^.size_c);
      end;

    until man.GetNextFile(p)=0;
    FreeMem(ldir);
  end;

  FreeMem(lin);
  FreeMem(lout);

//spak.Flush;

  //--- Write MAN

  lManPos:=spak.Size;

  if FVersion=verTL2 then
    man.SaveToFile(MakeManFileName(),FVersion)
  else
  begin
    if FVersion=verTL2Mod then
    begin
      move(modinfo,lmodinfo,SizeOf(TTL2ModTech));
      QWord(lmodinfo.gamever):=ReverseWords(modinfo.gamever);
      lmodinfo.version:=4;
      lmodinfo.modver :=modinfo.modver;
      lmodinfo.offData:=lPakPos;
      lmodinfo.offMan :=spak.Size;

      spak.Position:=0;
      spak.Write(lmodinfo,SizeOf(lmodinfo));
    end;
    spak.Position:=spak.Size;
    man.SaveToStream(spak,FVersion);
  end;

  //--- Change PAK Header
  
  spak.Position:=lPakPos;

  case ABS(FVersion) of
    verTL2: begin
      TL2PAKHeader.MaxCSize:=largest_c;
      TL2PAKHeader.Hash    :=PAKHash(spak,lManPos-lPakPos);
      spak.Write(TL2PAKHeader,SizeOf(TTL2PAKHeader))
    end;
    verRGO: begin
      RGOPAKHeader.Version  :=5;
      RGOPAKHeader.Reserved :=0;
      RGOPAKHeader.ManOffset:=lManPos;
      RGOPAKHeader.ManSize  :=spak.Size-lManPos;
      RGOPAKHeader.MaxUSize :=largest_u;
      spak.Write(RGOPAKHeader,SizeOf(TRGOPAKHeader));
    end;
  else
    if      ABS(FVersion)=verHob then PAKHeader.Version:=5
    else if ABS(FVersion)=verRG  then PAKHeader.Version:=1;
    PAKHeader.Reserved :=0;
    PAKHeader.ManOffset:=lManPos;
    PAKHeader.MaxUSize :=largest_u;
    spak.Write(PAKHeader,SizeOf(TPAKHeader));
  end;

  spak.Free;
end;
{$POP}

{TODO: pack separate file}
procedure PackFile(var ainfo:TRGPAK;
    apath,aname:PUnicodeChar;
    abuf:PByte; asize:integer);
var
  mi:PMANFileInfo;
begin
  // just add to MAN or remove from pack or modify MAN
  if (asize=0) or (abuf=nil) then ;

  mi:=ainfo.man.SearchFile(apath,aname);
  if mi<>nil then
  begin
    // Compile if needs
    // Pack file
{
  TMANFileInfo = record // not real field order
    ftime   :UInt64;    // TL2 only
    name    :PUnicodeChar; // name in MAN
    nametxt :PUnicodeChar; // source (text format) name
    checksum:dword;     // CRC32
    size_s  :dword;     // looks like source,not compiled, size (unusable)
    size_c  :dword;     // from TPAKFileHeader
    size_u  :dword;     // from TPAKFileHeader
    offset  :dword;
    ftype   :byte;
  end;

1 - source file
2 - packed data
3 - packed size
4 - unpacked size
5 - PAK position
6 - MAN position
      
    function CompressFile(fname:PUnicodeChar; out abuf:PByte; out psize:integer; aver:integer=verTL2):integer;
    var
      f:file of byte;
      lbuf:PByte;
    begin
      result:=0;
      Assign(f,fname);
      Reset(f);
      if IOResult=0 then
      begin
        result:=FileSize(f);
        GetMem(lbuf,result);
        BlockRead(f,lbuf^,result);
      
        if not GetExtInfo(fname,aver)^._pack then
        begin
          abuf:=lbuf;
          psize:=result;
        end
        else
        begin
          psize:=Round(Align(result,BufferPageSize)*1.2)+12;
          GetMem(abuf,psize);
          
          if compress(abuf,psize,lbuf,result)<>Z_OK then
          begin
            if OnPAKProgress<>nil then
            begin
              lres:=OnPAKProgress(ainfo,-i,p);
              if lres<>0 then break;
            end;
          end;
        end;
        Close(f);
      end;
    end;
}
    // replace in PAK if not greater than existing
    // or add to the end
  end
  else
  begin
    // Add to MAN, add to the end of PAK
//    mi:=rgman.AddFile(ainfo.man,apath,aname);
  end;
end;

//----- something -----
{$IFDEF DEBUG}
function DoProgress(const ainfo:TRGPAK; adir:integer; afile:PMANFileInfo):integer;
var
//  ldir:string;
  p,l:PUnicodeChar;
begin
  result:=0;
//  ldir:=WideToStr(ainfo.man.GetDirName(ABS(adir)));
  if adir<0 then
  begin
    p:=ConcatWide(ainfo.man.GetDirName(ABS(adir)),ainfo.man.GetName(afile^.name));
    l:=ConcatWide('Skipping dummy ',p);
    RGLog.Add(WideToStr(l));
//    RGLog.Add('Skipping dummy ' +WideToStr(p));
    FreeMem(p);
    FreeMem(l);
//    RGLog.Add('Skipping dummy ' +ldir+WideToStr(ainfo.man.GetName(afile^.name)))
  end
  else if afile<>nil then
  begin
    p:=ConcatWide(ainfo.man.GetDirName(adir),ainfo.man.GetName(afile^.name));
    l:=ConcatWide('Processing file ',p);
    RGLog.Add(WideToStr(l));
//    RGLog.Add('Processing file '+WideToStr(p));
    FreeMem(p);
    FreeMem(l);
//    RGLog.Add('Processing file '+ldir+WideToStr(ainfo.man.GetName(afile^.name)))
  end
  else
  begin
    p:=ConcatWide('Processing dir ',ainfo.man.GetDirName(adir));
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
        ReallocMem(ltmp,fsize);
      BlockRead (ffin ,ltmp^,fsize);
      BlockWrite(ffout,ltmp^,fsize);
      FreeMem(ltmp);
      CloseFile(ffout);

{
      fin.Free;
}
      CloseFile(ffin);

      // DAT file
      SaveModConfiguration(mi,PChar(lfname+'.DAT'));

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
    LoadModConfiguration(PChar(amod),lmi)
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

  if      FileExists(lname+'.DAT'  ) then LoadModConfiguration(PChar(lname+'.DAT'  ),lmi)
  else if FileExists(ldir+'MOD.DAT') then LoadModConfiguration(PChar(ldir+'MOD.DAT'),lmi)
  else
  begin
    MakeModInfo(lmi);
    lmi.title:=StrToWide(aname);
  end;
  
  result:=RGPAKCombine(lname+'.PAK', lname+'.PAK.MAN', lmi, adir);

  ClearModInfo(lmi);
end;


initialization
{$IFDEF DEBUG}
  OnPAKProgress:=@DoProgress;
{$ELSE}
  OnPAKProgress:=nil;
{$ENDIF}
end.
