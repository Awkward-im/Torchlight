unit RGGlobal;

interface

{$DEFINE Interface}

uses
  logging;

//===== Common things =====

{$IF NOT DEFINED(TStringDynArray)}  type TStringDynArray  = array of String;  {$ENDIF}
{$IF NOT DEFINED(TIntegerDynArray)} type TIntegerDynArray = array of Integer; {$ENDIF}
{$IF NOT DEFINED(TInt64DynArray)}   type TInt64DynArray   = array of Int64;   {$ENDIF}
{$IF NOT DEFINED(TSingleDynArray)}  type TSingleDynArray  = array of Single;  {$ENDIF}
type
  TDictElement = record
    id   :integer;
    value:AnsiString;
  end;
  TDictDynArray = array of TDictElement;
type
 TDict64Element = record
   id   :Int64;
   value:AnsiString;
 end;
  TDict64DynArray = array of TDict64Element;
type
  TRGDebugLevel = (dlNone, dlNormal, dlDetailed);
var
{$IFDEF DEBUG}
  rgDebugLevel:TRGDebugLevel = dlDetailed;
{$ELSE}
  rgDebugLevel:TRGDebugLevel = dlNone;
{$ENDIF}

var
  RGLog :logging.TLog;

type
  TRGDoubleAction = (
    da_ask,          // ask for action
    da_stop,         // stop cycle
    da_skip,         // skip existing file
    da_skipdir,      // skip existing files in current dir (subdirs?)
    da_skipall,      // skip all existing files
    da_compare,      // compare and change
    da_overwrite,    // overwrite existing file
    da_overwritedir, // overwrite existing files in this dir (subdirs?)
    da_overwriteall, // overwrite all existing files (for binaries only?)
    da_renameold,    // rename existing (old) file (rename by template?)
    da_saveas        // rename new file (rename by template?)
  );

const
  TL1DataBase = 'tl1db.db';
  TL2DataBase = 'tl2db.db';
  TL2TextBase = 'tl2text.db';
  HobDataBase = 'hobdb.db';
  RGDataBase  = 'rgdb.db';
  RGODataBase = 'rgodb.db';
  TL2EditMod  = 'EDITORMOD.MOD';
  TL2ModData  = 'MOD.DAT';
  TL2GameVer  = $0001001900050002;
  TL1GameVer  = $0001000F00000000;

const
  strRootDir  = 'MEDIA/';

const
  RGDefaultExt     = '.MOD';
  RGDefReadFilter  = 'MOD files|*.MOD|PAK files|*.PAK|TL1 ZIP archives|*.ZIP|MAN files|*.MAN|Supported files|*.MOD;*.PAK;*.MAN;*.ZIP|All files|*.*';
  RGDefWriteFilter = 'TL2 MOD file|*.MOD|TL2 PAK file|*.PAK|Hob PAK file|*.PAK|Rebel Galaxy PAK file|*.PAK|Rebel Galaxy Outlaw PAK file|*.PAK|TL1 archive|*.ZIP';

//--- Constants

const
  SIGN_UNICODE = $FEFF;
  SIGN_UTF8    = $BFBBEF;

{%REGION Game version}
const
  verUnk    = 0;
  verTL1    = 1;
  verTL2    = 2;
  verHob    = 3;
  verRG     = 4;
  verRGO    = 5;
  verTL2Mod = -verTL2;
  verTL1adm = -verTL1;
  verTL1Mod = -verTL1;

const
  RGGames : array [0..5] of record
    ver :integer;
    name:string;
  end = (
    (ver:verTL1   ; name:'Torchlight I'),
    (ver:verTL2   ; name:'Torchlight II'),
    (ver:verTL2Mod; name:'Torchlight II Mod'),
    (ver:verHob   ; name:'Hob'),
    (ver:verRG    ; name:'Rebel Galaxy'),
    (ver:verRGO   ; name:'Rebel Galaxy Outlaw')
  );

function GetGameName(aver:integer):string;

{%ENDREGION Game version}

const
  FloatPrec :integer = 6;
  DoublePrec:integer = 8;

const
  BoolNumber:array [boolean] of string = ('0','1');

//--- Functions

{$i rg_split.inc}

function MakeMethod(Data, Code:Pointer):TMethod;

function  FileTimeToDateTime(const FileTime: Int64): TDateTime;
function  DateTimeToFileTime(adate: TDateTime): Int64;

function  IsNumber(astr:PWideChar):boolean;
function  RGStrToInt(src:PWideChar; var aval:QWord):boolean;
function  RGStrToInt(src:PWideChar):QWord;
function  RGIntToStr(dst:PWideChar; value:QWord):PWideChar;
procedure FixFloatStr(var astr:AnsiString);
procedure FixFloatStr(var astr:UnicodeString);

function  ReverseWords(aval:QWord):QWord;

function  ChooseEncoding(abuf:PByte):integer;
function  FastUpCase   (c:UnicodeChar):UnicodeChar;
function  StrToWide    (const src:AnsiString):PWideChar;
function  FastStrToWide(const src:AnsiString):PWideChar;
function  WideToStr    (src:PWideChar;asize:integer=-1):AnsiString;
function  FastWideToStr(src:PWideChar;asize:integer=-1):AnsiString;
procedure CopyWide     (var adst:PWideChar; asrc:PWideChar; alen:integer=0);
function  CopyWide     (asrc:PWideChar; alen:integer=0):PWideChar;
function  CompareWide  (s1,s2:PWideChar; alen:integer=0):integer;
function  CompareWideI (s1,s2:PWideChar; alen:integer=0):integer;
function  ConcatWide   (s1,s2:PWideChar):PWideChar;
function  CharPosWide  (c:WideChar; asrc:PWideChar):PWideChar;
function  PosWide      (asubstr,asrc:PWideChar):PWideChar;
function  GetLine    (var aptr:PByte):PAnsiChar;
function  GetLineWide(var aptr:PByte):PWideChar;
function  GetLineWide(var aptr:PByte; var buf:pointer; var asize:integer):PWideChar;
//procedure WriteWide(var buf:PByte; var idx:cardinal; atext:PWideChar);
function  BufLen(abuf:PAnsiChar; asize:cardinal):integer;
function  BufLen(abuf:PWideChar; asize:cardinal):integer;

function ExtractNameOnly(const aFilename: string):string;
function ExtractExt     (const aFileName: string):string;
function ExtractPath(const apath:UnicodeString):UnicodeString;
function ExtractPath(const apath:AnsiString   ):AnsiString;
function ExtractName(const apath:UnicodeString):UnicodeString;
function ExtractName(const apath:AnsiString   ):AnsiString;

const
  RGExtExts : array [0..4] of string = ('.TXT', '.BINDAT', '.BINLAYOUT', '.ADM', '.CMP');

function IsExtFile (var   srcname:UnicodeString):boolean;
function IsExtFile (var   srcname:AnsiString   ):boolean;
function FixFileExt(const srcname:string):string;
// don't touch abuf if can't open or size=0
function LoadFile(const aname:AnsiString; var abuf:PByte):integer;


{%REGION Data types}

const
  // DAT and some common type codes
  rgNotSet    = 0;
  rgInteger   = 1;
  rgFloat     = 2;
  rgDouble    = 3;
  rgUnsigned  = 4;
  rgString    = 5;
  rgBool      = 6;
  rgInteger64 = 7;
  rgTranslate = 8;
  rgNote      = 9;
//  rgWString
  // special
  rgNotValid  = -1;
  rgUnknown   = rgNotValid;
  // layout, custom, readonly
  rgVector2   = 100;
  rgVector3   = 101;
  rgVector4   = 102;
//  rgUIntList  = 110;
//  rgFloatList = 111;
  // user
  rgGroup     = rgNotSet;
  rgWord      = 200;
  rgByte      = 201;
  rgBinary    = 202;
  rgQWord     = 203;
  // special
  rgList      = $1000;

  rgValidNodeTypes = [rgNotSet,rgInteger,rgFloat,rgDouble,rgUnsigned,rgString,rgBool,
                      rgInteger64,rgTranslate,rgNote,rgVector2,rgVector3,rgVector4,
                      rgWord,rgByte,rgBinary,rgQWord];

function TypeToText(atype:integer):PWideChar;
function TextToType(atype:PWideChar):integer;

//===== Custom types =====

type
  TRGID      = Int64;
  TRGInteger = Int32;
  TRGFloat   = single; // 4 bytes
  TRGUInt    = UInt32;
  TRGDouble  = double; // 8 bytes

const
  RGIdEmpty = TRGID(-1);

type
  PIntVector3 = ^TIntVector3;
  TIntVector3 = packed record
    X: Int32;
    Y: Int32;
    Z: Int32;
  end;

type
  PVector2 = ^TVector2;
  TVector2 = packed record
    X: Single;
    Y: Single;
  end;
  PVector3 = ^TVector3;
  TVector3 = packed record
    X: Single;
    Y: Single;
    Z: Single;
  end;
  PVector4 = ^TVector4;
  TVector4 = packed record // quaternion
    X: Single;
    Y: Single;
    Z: Single;
    W: Single;
  end;
  PVector = ^TVector4;

type
  TMatrix4x4 = array [0..3,0..3] of single;

{%ENDREGION Data types}

{%REGION Savegame}

const
  tlsaveTL1         = $17;
//  tlsaveFirst    = $11; // TL2: Movie lists just after this version
  tlsaveTL2Minimal  = $38; // minimal acceptable version
  tlsaveTL2Encoded  = $3B; // "scramble" byte introduced
  tlsaveTL2Scramble = $3D; // new scramble method
  tlsaveTL2Checksum = $41; // checksum field added
  tlsaveTL2ModBind  = $43; // mod binding lists
  tlsaveTL2         = $44; // last (current) version
{
  0x09 - ? after 3c 4b(cnt)+1*x bytes
  0x11 - movies
  0x17 - !!!!!! TL1 1.15 savegame
  0x27 - Coords (-999, -999, -999)
  0x37 - ? 2b+2b(size)+[8b]
  0x38 - min for read/write
  0x3B - scramble
  0x3C - ? after 37, 2b (Cnt)+[8b]
  0x3D - new scramble method
  0x41 - checksum
  0x43 - mod lists (maybe something more)
  0x44 - mod version in mod list
}

const
  TL2Cheat  = 238;
type
  TL2IdList = array of TRGID;
type
  TL2IdVal = packed record
    id   :TRGID;
    value:Int32;
  end;
  TL2IdValList = array of TL2IdVal;

type
  TTL2Mod = packed record
    id     :TRGID;
    version:word;
  end;
  TTL2ModList = array of TTL2Mod;

type
  TTL2Function = packed record
    id :TRGID;
    unk:TRGID;
  end;
  TTL2FunctionList = array of TTL2Function;
type
  TTL2KeyMapping = packed record
    id      :TRGID;
    datatype:byte;   // (0=item, 2-skill)
    key     :word;   // or byte, (byte=3 or 0 for quick keys)
  end;
  TTL2KeyMappingList = array of TTL2KeyMapping;

type
  TL2Difficulty = (Casual, Normal, Veteran, Expert);
type
  TL2Sex = (male, female, unisex);

{%ENDREGION Savegame}

//===== Container =====

type
  PPAKFileHeader = ^TPAKFileHeader;
  TPAKFileHeader = packed record
    size_u:UInt32;
    size_c:UInt32;      // 0 means "no compression
  end;

type
  // fields are rearranged
  PTL2ModInfo = ^TTL2ModInfo;
  TTL2ModInfo = record
    modid   :Int64;
    gamever :QWord;
    title   :PUnicodeChar; // 255 max
    author  :PUnicodeChar; // 255 max
    descr   :PUnicodeChar; // 512 max
    website :PUnicodeChar; // 512 max
    download:PUnicodeChar; // 512 max
    filename:PUnicodeChar;
    // start of additional info
    steam_preview:PUnicodeChar;
    steam_tags   :PUnicodeChar;
    steam_descr  :PUnicodeChar;
    long_descr   :PUnicodeChar;
    // end of additional info
    dels    :array of PUnicodeChar;
    offData :DWord;
    offMan  :DWord;
    flags   :DWord;
    reqHash :Int64;
    reqs    :array of record
      name:PUnicodeChar;
      id  :Int64;       // just this field presents in MOD.DAT
      ver :Word;
    end;
    modver  :Word;
    modified:boolean;
  end;

//===== Other =====

procedure QuaternionToMatrix(const q:TVector4; out m:TMatrix4x4);

{%REGION Hash}

function CalcCheckSum(aptr:pByte; asize:cardinal):dword;
function RGHash (instr:PWideChar; alen:integer=0):dword;
function RGHashB(instr:PAnsiChar; alen:integer=0):dword;
function MurmurHash64B(var s; Len: Integer; Seed: UInt32) : UInt64;

{%ENDREGION Hash}

//==========================
//===== Implementation =====
//==========================

implementation

//----- Support -----

{$UNDEF Interface}

{$i rg_split.inc}

function MakeMethod(Data, Code:Pointer):TMethod;
begin
  Result.Data:=Data;
  Result.Code:=Code;
end;

type
  tTL2VerRec = record
    arr:array [0..3] of word;
  end;

function ReverseWords(aval:QWord):QWord;
begin
  result:=
    qword(tTL2VerRec(aval).arr[3])+
    qword(tTL2VerRec(aval).arr[2]) shl 16+
    qword(tTL2VerRec(aval).arr[1]) shl 32+
    qword(tTL2VerRec(aval).arr[0]) shl 48;
end;

function IsNumber(astr:PWideChar):boolean;
begin
  result:=false;
  if (astr=nil) or (astr^=#0) then exit;
  if astr^='-' then inc(astr);
  repeat
    if not (ord(astr^) in [ORD('0')..ORD('9')]) then exit;
    inc(astr);
  until astr^=#0;
  result:=true;
end;

function RGStrToInt(src:PWideChar; var aval:QWord):boolean;
var
  isminus:boolean;
begin
  result:=false;
  aval:=0;
  if (src=nil) or (src^=#0) then exit;
  isminus:=src^='-';
  if isminus then inc(src);
  repeat
    if not (ord(src^) in [ORD('0')..ORD('9')]) then exit;
    aval:=aval*10+ORD(src^)-ORD('0');
    inc(src);
  until src^=#0;
  if isminus then aval:=QWord(-Int64(aval));
  result:=true;
end;

function RGStrToInt(src:PWideChar):QWord;
var
  isminus:boolean;
begin
  result:=0;
  if src<>nil then
  begin
    isminus:=src^='-';
    if isminus then inc(src);
    while src^<>#0 do
    begin
      result:=result*10+ORD(src^)-ORD('0');
      inc(src);
    end;
    if isminus then result:=QWord(-Int64(result));
  end;
end;

function RGIntToStr(dst:PWideChar; value:QWord):PWideChar;
var
  i:dword;
  digits:integer;
begin
  i:=value;
  digits:=0;
  repeat
    i:=i div 10;
    inc(digits);
  until i=0;
  dst[digits]:=#0;
  repeat
    dec(digits);
    dst[digits]:=WideChar(ord('0')+(value mod 10));
    value:=value div 10;
  until digits=0;
  result:=dst;
end;

const
  FileTimeBase      = -109205.0;
  FileTimeStep: Extended = 24.0 * 60.0 * 60.0 * 1000.0 * 1000.0 * 10.0; // 100 nSec per Day

function FileTimeToDateTime(const FileTime: Int64): TDateTime;
begin
  Result := FileTime / FileTimeStep;
  Result := Result + FileTimeBase;
end;

function DateTimeToFileTime(adate: TDateTime): Int64;
begin
  adate  := adate - FileTimeBase;
  Result := Trunc(adate * FileTimeStep);
end;

procedure FixFloatStr(var astr:AnsiString);
var
  j,l:integer;
begin
  l:=Length(astr);
  j:=l;

  while j>1 do
  begin
    if      (astr[j]='0') then dec(j)
    else if (astr[j]='.') then
    begin
      dec(j);
      break;
    end
    else break;
  end;
  if (j=2) and (astr[1]='-') and (astr[2]='0') then
  begin
    astr[1]:='0';
    j:=1;
  end;
  if j<l then SetLength(astr,j);
end;

procedure FixFloatStr(var astr:UnicodeString);
var
  j,l:integer;
begin
  l:=Length(astr);
  j:=l;

  while j>1 do
  begin
    if      (astr[j]='0') then dec(j)
    else if (astr[j]='.') then
    begin
      dec(j);
      break;
    end
    else break;
  end;
  if (j=2) and (astr[1]='-') and (astr[2]='0') then
  begin
    astr[1]:='0';
    j:=1;
  end;
  if j<l then SetLength(astr,j);
end;

function ChooseEncoding(abuf:PByte):integer;
begin
  if (PWord(abuf)^=SIGN_UNICODE) or (PWord(abuf)^<256) then exit(2);
  if (PDword(abuf)^ and $00FFFFFF)=SIGN_UTF8 then exit(1);
  result:=0; // ANSI or UTF8
end;

function BufLen(abuf:PAnsiChar; asize:cardinal):integer;
begin
  if asize=0 then asize:=MemSize(abuf);
  result:=0;
  while (result<asize) and (abuf[result]<>#0) do inc(result);
end;

function BufLen(abuf:PWideChar; asize:cardinal):integer;
begin
  if asize=0 then asize:=MemSize(abuf);
  asize:=asize div SizeOf(WideChar);
  result:=0;
  while (result<asize) and (abuf[result]<>#0) do inc(result);
end;

function FastUpCase(c:UnicodeChar):UnicodeChar; inline;
begin
  result:=c;
  if ORD(c) in [97..122] then
    result:=UnicodeChar(ORD(c)-32);
end;

function FastStrToWide(const src:AnsiString):PWideChar;
var
  i:integer;
begin
  if src='' then exit(nil);

  GetMem(result,(length(src)+1)*SizeOf(WideChar));
  for i:=1 to length(src) do
    result[i-1]:=WideChar(ord(src[i]));
  result[length(src)]:=#0;
end;

function StrToWide(const src:AnsiString):PWideChar;
var
  pc:PAnsiChar;
  i:integer;
  b:boolean;
//  ws:UnicodeString;
begin
  if src='' then exit(nil);

  pc:=PAnsiChar(src);
  b:=false;
  while (pc^<>#0) do
  begin
    if ORD(pc^)>127 then
    begin
      b:=true;
      break;
    end;
    inc(pc);
  end;
  
  if not b then
    result:=FastStrToWide(src)
  else
  begin
    i:=Utf8ToUnicode(nil,0,PAnsiChar(src),Length(src));
    if i>0 then
    begin
      GetMem(result,(i+1)*SizeOf(WideChar));
      i:=Utf8ToUnicode(result,(i+1)*SizeOf(WideChar),PAnsiChar(src),Length(src));
      result[i-1]:=#0;
    end
    else
      result:=nil;
  end;
{
  ws:=UTF8Decode(src);
  GetMem(result,(Length(ws)+1)*SizeOf(WideChar));
  move(Pointer(ws)^,result^,Length(ws)*SizeOf(WideChar));
  result[Length(ws)]:=#0;
}
end;

function FastWideToStr(src:PWideChar;asize:integer=-1):AnsiString;
var
  i:integer;
begin
  if asize<0 then asize:=Length(src);
  if asize=0 then exit('');

  SetLength(result,asize);
  for i:=1 to asize do
    result[i]:=AnsiChar(ord(src[i-1]));
end;

function WideToStr(src:PWideChar;asize:integer=-1):AnsiString;
var
  ws:UnicodeString;
  pc:PWideChar;
  lsize:integer;
  b:boolean;
begin
  if (src=nil) or (src^=#0) or (asize=0) then exit('');

  pc:=src;
  lsize:=0;
  b:=false;
  if asize>0 then
  begin
    lsize:=asize;
    while pc^<>#0 do
    begin
      if ORD(pc^)>127 then
      begin
        b:=true;
        break;
      end;
      inc(pc);
    end;
  end
  else
  begin
    while pc^<>#0 do
    begin
      if ORD(pc^)>127 then b:=true;
      inc(pc);
      inc(lsize);
    end;
  end;

  if not b then
    result:=FastWideToStr(src,lsize)
  else
  begin
    SetLength(ws,lsize);
    move(src^,ws[1],lsize*SizeOf(WideChar));
    result:=UTF8Encode(ws);
  end;
end;

function ConcatWide(s1,s2:PWideChar):PWideChar;
var
  llen2,llen1:integer;
begin
  if s1=nil then
  begin
    result:=CopyWide(s2);
    exit;
  end;
  if s2=nil then
  begin
    result:=CopyWide(s1);
    exit;
  end;
  llen1:=Length(s1);
  llen2:=Length(s2);

  GetMem(result,(llen1+llen2+1)*SizeOf(WideChar));
  result[llen1+llen2]:=#0;
  move(s1^,result^      ,llen1*SizeOf(WideChar));
  move(s2^,result[llen1],llen2*SizeOf(WideChar));
end;

function CopyWide(asrc:PWideChar; alen:integer=0):PWideChar;
begin
  if (asrc=nil) or (asrc^=#0) then exit(nil);

  if alen=0 then
    alen:=Length(asrc);
  GetMem(    result ,(alen+1)*SizeOf(WideChar));
  move(asrc^,result^, alen   *SizeOf(WideChar));
  result[alen]:=#0;
end;

procedure CopyWide(var adst:PWideChar; asrc:PWideChar; alen:integer=0);
begin
  adst:=CopyWide(asrc,alen);
end;

function CompareWideI(s1,s2:PWideChar; alen:integer=0):integer;
var
  c1,c2:AnsiChar;
begin
  if s1=s2  then exit(0);
  if s1=nil then if s2^=#0 then exit(0) else exit(-1);
  if s2=nil then if s1^=#0 then exit(0) else exit( 1);

  repeat
    c1:=UpCase(AnsiChar(ORD(s1^)));
    c2:=UpCase(AnsiChar(ORD(s2^)));
    if c1>c2 then exit( 1);
    if c1<c2 then exit(-1);
    if s1^=#0  then exit( 0);
    dec(alen);
    if alen=0  then exit( 0);
    inc(s1);
    inc(s2);
  until false;
end;

function CompareWide(s1,s2:PWideChar; alen:integer=0):integer;
begin
  if s1=s2  then exit(0);
  if s1=nil then if s2^=#0 then exit(0) else exit(-1);
  if s2=nil then if s1^=#0 then exit(0) else exit( 1);

  repeat
    if s1^>s2^ then exit( 1);
    if s1^<s2^ then exit(-1);
    if s1^=#0  then exit( 0);
    dec(alen);
    if alen=0  then exit( 0);
    inc(s1);
    inc(s2);
  until false;
end;

function CharPosWide(c:WideChar; asrc:PWideChar):PWideChar;
begin
  result:=nil;
  if asrc<>nil then
    while asrc^<>#0 do
    begin
      if asrc^=c then
        exit(asrc);

      inc(asrc);
    end;
end;

function PosWide(asubstr,asrc:PWideChar):PWideChar;
var
  lstr2:SizeInt;
begin
  result:=nil;

  if (asubstr=nil) or (asrc=nil) then
    exit;

  while asrc^<>#0 do
  begin
    if asrc^=asubstr^ then
      break;
    inc(asrc);
  end;
  if asrc^=#0 then exit;
  lstr2:=Length(asubstr);
  while asrc^<>#0 do
  begin
    if (asrc^=asubstr^) and (CompareWide(asrc,asubstr,lstr2)=0) then Exit(asrc);
    inc(asrc);
  end;
end;

function GetLine(var aptr:PByte):PAnsiChar;
begin
  result:=PAnsiChar(aptr);

  while not (aptr^ in [0, 10, 13]) do inc(aptr);
  if aptr^<>0 then
  begin
    aptr^:=0;
    inc(aptr);
    while aptr^ in [10, 13] do inc(aptr);
  end;
end;

function GetLineWide(var aptr:PByte):PWideChar;
var
  lend:PWideChar;
begin
  result:=PWideChar(aptr);
  lend:=pointer(aptr);

  while not (ord(lend^) in [0, 10, 13]) do inc(lend);
  if ord(lend^)<>0 then
  begin
    lend^:=#0;
    inc(lend);
    while ord(lend^) in [10, 13] do inc(lend);
  end;

  aptr:=pointer(lend);
end;

function GetLineWide(var aptr:PByte; var buf:pointer; var asize:integer):PWideChar;
var
  lend:PWideChar;
  llen:integer;
begin
  result:=nil;
  lend:=pointer(aptr);

  while not (ord(lend^) in [0, 10, 13]) do inc(lend);

  llen:=PByte(lend)-aptr;
  if llen>0 then
  begin
    if (llen+SizeOf(WideChar))>=asize then
    begin
      asize:=Align(llen+SizeOf(WideChar),16);
      FreeMem(buf);
      GetMem(PByte(buf),asize);
    end;
    move(aptr^,PByte(buf)^,llen);
    result:=buf;
    PByte(buf)[llen  ]:=0;
    PByte(buf)[llen+1]:=0;
  end;
  
  while ord(lend^) in [10, 13] do inc(lend);
  aptr:=pointer(lend);
end;
{
procedure WriteWide(var buf:PByte; var idx:cardinal; atext:PWideChar);
const
  TMSGrow = 4096;
Var
  GC,NewIdx:PtrInt;
  lcnt:integer;
begin
  lcnt:=Length(atext)*SizeOf(WideChar);

  If lcnt=0 then
    exit;

  NewIdx:=idx+lcnt;
  GC:=MemSize(buf);
  If NewIdx>=GC then
  begin
    GC:=GC+(GC div 4);
    GC:=(GC+(TMSGrow-1)) and not (TMSGrow-1);

    ReallocMem(buf,GC);
  end;
  System.Move(atext^,buf[idx],lcnt);
  idx:=NewIdx;
end;
}

// from LazFileUtils
function ExtractNameOnly(const aFilename: string):string;
var
  StartPos: Integer;
  ExtPos: Integer;
begin
  if aFilename='' then exit('');

  StartPos:=length(aFilename)+1;
  while (StartPos>1)
  and not (aFilename[StartPos-1] in AllowDirectorySeparators)
  {$IF defined(Windows) or defined(HASAMIGA)}and (aFilename[StartPos-1]<>':'){$ENDIF}
  do
    dec(StartPos);
  ExtPos:=length(aFilename);
  while (ExtPos>=StartPos) and (aFilename[ExtPos]<>'.') do
    dec(ExtPos);
  if (ExtPos<StartPos) then ExtPos:=length(aFilename)+1;
  Result:=copy(aFilename,StartPos,ExtPos-StartPos);
end;

// modification of SysUtils
function ExtractPath(const apath:UnicodeString):UnicodeString;
var
  i:integer;
begin
  Result:='';
  i:=Length(apath);
  if i=0 then exit;
  dec(i);
  while (i>0) and (apath[i]<>'/') and (apath[i]<>'\') do Dec(i);
  if i>0 then result:=Copy(apath,1,i);
end;

function ExtractPath(const apath:AnsiString):AnsiString;
var
  i:integer;
begin
  Result:='';
  i:=Length(apath);
  if i=0 then exit;
  dec(i);
  while (i>0) and (apath[i]<>'/') and (apath[i]<>'\') do Dec(i);
  if i>0 then result:=Copy(apath,1,i);
end;

function ExtractName(const apath:UnicodeString):UnicodeString;
var
  i:integer;
begin
  Result:='';
  i:=Length(apath);
  if i=0 then exit;
  dec(i);
  while (i>0) and (apath[i]<>'/') and (apath[i]<>'\') do Dec(i);
  if i>0 then result:=copy(apath,i+1) else result:=apath;
end;

function ExtractName(const apath:AnsiString):AnsiString;
var
  i:integer;
begin
  Result:='';
  i:=Length(apath);
  if i=0 then exit;
  dec(i);
  while (i>0) and (apath[i]<>'/') and (apath[i]<>'\') do Dec(i);
  if i>0 then result:=copy(apath,i+1) else result:=apath;
end;

function ExtractExt(const aFileName: string):string;
var
  i,j:integer;
begin
  Result:='';
  i:=Length(aFileName);

  while (i>0) and not (aFileName[i] in ['/','\','.']) do Dec(i);

  if (i>0) and (aFileName[i]='.') then
  begin
    if (i=1) or ((i>1) and not (aFileName[i-1] in ['/','\'])) then
    begin
//      Result:=Copy(aFileName,i);

      SetLength(Result,Length(aFileName)-i+1);
      for j:=i to Length(aFileName) do
        Result[j-i+1]:=UpCase(aFileName[j]);
    end;
  end;
end;


function FixFileExt(const srcname:string):string; inline;
begin
  result:=srcname;
  IsExtFile(result);
end;

function IsExtFile(var srcname:UnicodeString):boolean;
var
  i,j,elen,slen:integer;
begin
  slen:=Length(srcname);
  for i:=0 to High(RGExtExts) do
  begin
    elen:=Length(RGExtExts[i]);
    if slen>elen then
    begin
      j:=slen;
      while (elen>0) and (UpCase(AnsiChar(Ord(srcname[j])))=RGExtExts[i,elen]) do
      begin
        dec(elen);
        dec(j);
      end;
      if elen=0 then
      begin
        if i=0 then
        begin
          slen:=j-1;
          while slen>1 do
          begin
            if AnsiChar(ord(srcname[slen]))='.' then
            begin
              SetLength(srcname,j);
              break;
            end;
            dec(slen);
          end;
          exit(true);
        end;
        SetLength(srcname,j);
        exit(true);
      end;
    end;
  end;
  result:=false;
end;

function IsExtFile(var srcname:AnsiString):boolean;
var
  i,j,elen,slen:integer;
begin
  slen:=Length(srcname);
  for i:=0 to High(RGExtExts) do
  begin
    elen:=Length(RGExtExts[i]);
    if slen>elen then
    begin
      j:=slen;
      while (elen>0) and (UpCase(srcname[j])=RGExtExts[i,elen]) do
      begin
        dec(elen);
        dec(j);
      end;
      if elen=0 then
      begin
        if i=0 then
        begin
          slen:=j-1;
          while slen>1 do
          begin
            if srcname[slen]='.' then
            begin
              SetLength(srcname,j);
              break;
            end;
            dec(slen);
          end;
          exit(true);
        end;
        SetLength(srcname,j);
        exit(true);
      end;
    end;
  end;
  result:=false;
end;

{$PUSH}
{$I-}
function LoadFile(const aname:AnsiString; var abuf:PByte):integer;
var
  f:file of byte;
begin
  Assign(f,aname);
  Reset(f);
  if IOResult=0 then
  begin
    result:=FileSize(f);
    if result>0 then
    begin
      GetMem(abuf,result+2);
      BlockRead(f,abuf^,result);
      Close(f);
      abuf[result  ]:=0;
      abuf[result+1]:=0;
    end;
  end;
  result:=0;
end;
{$POP}

function GetGameName(aver:integer):string;
var
  i:integer;
begin
  for i:=0 to High(RGGames) do
    if RGGames[i].ver=aver then
      exit(RGGames[i].name);

  result:='';
end;

{%REGION Data types}

const
  RGType : array [0..18] of record
    code:integer;
    name:PWideChar;
  end = (
    (code: rgNotSet   ; name: 'NOT SET'         ),
    (code: rgInteger  ; name: 'INTEGER'         ),
    (code: rgFloat    ; name: 'FLOAT'           ),
    (code: rgDouble   ; name: 'DOUBLE'          ),
    (code: rgUnsigned ; name: 'UNSIGNED INT'    ),
    (code: rgString   ; name: 'STRING'          ),
    (code: rgBool     ; name: 'BOOL'            ),
    (code: rgInteger64; name: 'INTEGER64'       ),
    (code: rgTranslate; name: 'TRANSLATE'       ),
    (code: rgNote     ; name: 'NOTE'            ),
    // special
    (code: rgNotValid ; name: 'NOT VALID'       ),
    // layout types (custom, text is readonly)
    (code: rgUnsigned ; name: 'UNSIGNED INTEGER'),
    (code: rgVector2  ; name: 'VECTOR2'         ), // base type = FLOAT
    (code: rgVector3  ; name: 'VECTOR3'         ), // base type = FLOAT
    (code: rgVector4  ; name: 'VECTOR4'         ), // base type = FLOAT
    (code: rgInteger64; name: 'INT64'           ),
//    (code: rgUIntList ; name: 'UINTLIST'        ), // base type = UNSIGNED INT
//    (code: rgFloatList; name: 'FLOATLIST'       ), // base type = FLOAT
    // user
    (code: rgWord     ; name: 'WORD'            ),
    (code: rgByte     ; name: 'BYTE'            ),
    (code: rgBinary   ; name: 'BINARY'          )
  );


function TypeToText(atype:integer):PWideChar;
var
  i:integer;
begin
  for i:=0 to High(RGType) do
    if atype=RGType[i].code then
      exit(RGType[i].name);

  result:=nil;
end;

function TextToType(atype:PWideChar):integer;
var
  i:integer;
begin
  if atype=nil then exit(rgNotSet);

  for i:=0 to High(RGType) do
    if CompareWideI(atype,RGType[i].name)=0 then
      exit(RGType[i].code);

  result:=rgNotValid;
end;

{%ENDREGION Data types}

//===== Other =====

procedure QuaternionToMatrix(const q:TVector4; out m:TMatrix4x4);
var
  wx,wy,wz,
  xx,xy,xz,
  yy,yz,
  zz,
  x2,y2,z2:single;
begin
  x2:=q.x+q.x;
  y2:=q.y+q.y;
  z2:=q.z+q.z;

  xx:=q.x*x2;
  xy:=q.x*y2;
  xz:=q.x*z2;

  yy:=q.y*y2;
  yz:=q.y*z2;
  zz:=q.z*z2;

  wx:=q.w*x2;
  wy:=q.w*y2;
  wz:=q.w*z2;

  m[0,0]:=1.0-(yy+zz);  m[1,0]:=xy+wz;        m[2,0]:=xz-wy;        m[3,0]:=0;
  m[0,1]:=xy-wz;        m[1,1]:=1.0-(xx+zz);  m[2,1]:=yz+wx;        m[3,1]:=0;
  m[0,2]:=xz+wy;        m[1,2]:=yz-wx;        m[2,2]:=1.0-(xx+yy);  m[3,2]:=0;
  m[0,3]:=0;            m[1,3]:=0;            m[2,3]:=0;            m[3,3]:=1;
end;

{%REGION Hash}

//--- Save file

{$PUSH}
{$Q-}
function CalcCheckSum(aptr:pByte; asize:cardinal):dword;
var
  lhash:Int64;
  i:integer;
begin
  result:=0;
  if asize>0 then
  begin
    lhash:=$14D3;

    for i:=0 to asize-1 do
    begin
      lhash:=(lhash+(lhash shl 5)+aptr[i]) and $FFFFFFFF;
    end;

    result:=dword(lhash);
  end;
end;
{$POP}

//--- DAT/Layout

{$PUSH}
{$Q-}
function RGHash(instr:PWideChar; alen:integer=0):dword;
var
  i:integer;
begin
  if alen=0 then alen:=Length(instr);
  result:=alen;
  for i:=0 to alen-1 do
    result:=(result SHR 27) xor (result SHL 5) xor ORD(instr[i]);
end;

function RGHashB(instr:PAnsiChar; alen:integer=0):dword;
var
  i:integer;
begin
  if alen=0 then alen:=Length(instr);
  result:=alen;
  for i:=0 to alen-1 do
    result:=(result SHR 27) xor (result SHL 5) xor ORD(instr[i]);
end;
{$POP}

//--- PAK/MOD
{$PUSH}
{$Q-}
{$R-}
function MurmurHash64B(var s; Len: Integer; Seed: UInt32) : UInt64;
const
  m = $5BD1E995;
  r = 24;
var
  h1, h2, k1, k2: UInt32;
  data: PUInt32;
begin
  h1 := Seed Xor Cardinal(Len);
  h2 := 0;
  data := PUInt32(@s);
  while Len >= 8 do
  begin
    k1 := data^;
    Inc(data);
    k1 := k1 * m;
    k1 := (k1 Xor (k1 Shr r)) * m;
    h1 := (h1 * m) Xor k1;

    k2 := data^;
    Inc(data);
    k2 := k2 * m;
    k2 := (k2 Xor (k2 Shr r)) * m;
    h2 := (h2 * m) Xor k2;
    Dec(Len,8);
  end;

  if Len >= 4 then
  begin
    k1 := data^;
    Inc(data);
    k1 := k1 * m;
    k1 := (k1 Xor (k1 Shr r)) * m;
    h1 := (h1 * m) Xor k1;
    Dec(Len,4);
  end;

  if Len > 0 then
  begin
    if Len > 1 then
    begin
      if Len > 2 then
        h2 := h2 Xor (UInt32(PByte(data)[2]) Shl 16);
      h2 := h2 Xor (UInt32(PByte(data)[1]) Shl 8);
    end;
    h2 := h2 Xor UInt32(PByte(data)^);
    h2 := h2 * m;
  end;

  h1 := (h1 Xor (h2 Shr 18)) * m;
  h2 := (h2 Xor (h1 Shr 22)) * m;
  h1 := (h1 Xor (h2 Shr 17)) * m;
  h2 := (h2 Xor (h1 Shr 19)) * m;

  Result := (UInt64(h1) Shl 32) Or h2;
end;
{$POP}

{%ENDREGION Hash}


initialization

  RGLog.Init;

finalization

  RGLog.Free;

end.
