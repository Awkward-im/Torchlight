unit RGGlobal;

interface

{$DEFINE Interface}

uses
  logging;

//===== Common things =====

{$IF NOT DEFINED(TIntegerDynArray)} type TIntegerDynArray = array of Integer; {$ENDIF}
{$IF NOT DEFINED(TInt64DynArray)}   type TInt64DynArray   = array of Int64;   {$ENDIF}
{$IF NOT DEFINED(TSingleDynArray)}  type TSingleDynArray  = array of Single;  {$ENDIF}

var
  RGLog :logging.TLog;

const
  TL2DataBase = 'tl2db2.db';
  TL2EditMod  = 'EDITORMOD.MOD';
  TL2ModData  = 'MOD.DAT';

//--- Constants

const
  verUnk    = 0;
  verTL1    = 1;
  verTL2    = 2;
  verHob    = 3;
  verRG     = 4;
  verRGO    = 5;
  verTL2Mod = -verTL2;

//--- Functions

{$i rg_split.inc}

function  ReverseWords(aval:QWord):QWord;
function  StrToWide(const src:string):PWideChar;
function  WideToStr(src:PWideChar):string;
procedure CopyWide(var adst:PWideChar; asrc:PWideChar; alen:integer=0);
function  CopyWide(asrc:PWideChar; alen:integer=0):PWideChar;
function  CompareWide(s1,s2:PWideChar; alen:integer=0):integer;
function  ConcatWide (s1,s2:PWideChar):PWideChar;
function  CharPosWide(c:WideChar; asrc:PWideChar):PWideChar;
function  PosWide(asubstr,asrc:PWideChar):PWideChar;
function  GetLineWide(var aptr:PByte; var buf:pointer; var asize:integer):PWideChar;
//procedure WriteWide(var buf:PByte; var idx:cardinal; atext:PWideChar);
function  BufLen(abuf:PAnsiChar; asize:cardinal):integer;
function  BufLen(abuf:PWideChar; asize:cardinal):integer;

function ExtractFileNameOnly(const aFilename: string):string;
function ExtractFileExt     (const aFileName: string):string;

//===== Data type codes =====

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
  rgUIntList  = 110;
  rgFloatList = 111;
  // user
  rgGroup     = rgNotSet;
  rgWord      = 200;
  rgByte      = 201;
  rgBinary    = 202;


function TypeToText(atype:integer):PWideChar;
function TextToType(atype:PWideChar):integer;

//=====  =====

type
  TRGID      = Int64;
  TRGInteger = Int32;
  TRGFloat   = single;
  TRGUInt    = UInt32;

const
  RGIdEmpty = TRGID(-1);

type
  TVector2 = packed record
    X: Single;
    Y: Single;
  end;
  TVector3 = packed record
    X: Single;
    Y: Single;
    Z: Single;
  end;
  TVector4 = packed record // quaternion
    X: Single;
    Y: Single;
    Z: Single;
    W: Single;
  end;
type
  TMatrix4x4 = array [0..3,0..3] of single;

//===== TL2 Savegame related =====

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
  TL2StringList = array of string;

type
  TL2Difficulty = (Casual, Normal, Veteran, Expert);
type
  TL2Sex = (male, female, unisex);

//----- Global savegame file structures -----

const
  tl2saveFirst    = $11; // ??
  tl2saveMinimal  = $38; // minimal acceptable version
  tl2saveEncoded  = $3B; // "scramble" byte introduced
  tl2saveScramble = $3D; // new scramble method
  tl2saveChecksum = $41; // checksum field added
//  $43
  tl2saveCurrent  = $44; // last (current) version
{
  0x11 - movies
  0x17 - !!!!!! TL1 1.15 savegame
  0x27 - Coords (-999, -999, -999)
  0x38 - min for read/write
  0x3B - scramble
  0x3D - new scramble method
  0x41 - checksum
  0x43 - ?mod lists?
  0x44 - mod version in mod list
}

type            	
  TL2SaveHeader = packed record
    Version :DWord;
    Encoded :ByteBool;
    Checksum:Dword;
  end;
  TL2SaveFooter = packed record
    filesize:DWord;
  end;

//===== Container =====

type
  // fields are rearranged
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
  end;

//===== Other =====

procedure QuaternionToMatrix(const q:TVector4; out m:TMatrix4x4);

//===== Hash =====

function CalcCheckSum(aptr:pByte; asize:cardinal):dword;
function RGHash (instr:PWideChar; alen:integer=0):dword;
function RGHashB(instr:PAnsiChar; alen:integer=0):dword;
function MurmurHash64B(var s; Len: Integer; Seed: UInt32) : UInt64;

//==========================
//===== Implementation =====
//==========================

implementation

//----- Support -----

{$UNDEF Interface}

{$i rg_split.inc}

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

function StrToWide(const src:string):PWideChar;
var
  i:integer;
//  ws:WideString;
begin
  if src='' then exit(nil);

  i:=Utf8ToUnicode(nil,0,pchar(src),length(src));
  if i>0 then
  begin
    GetMem(result,(i+1)*SizeOf(WideChar));
    i:=Utf8ToUnicode(result,(i+1)*SizeOf(WideChar),pchar(src),length(src));
    result[i-1]:=#0;
  end;
{
  ws:=UTF8Decode(src);
  GetMem(result,(Length(ws)+1)*SizeOf(WideChar));
  move(Pointer(ws)^,result^,Length(ws)*SizeOf(WideChar));
  result[Length(ws)]:=#0;
}
end;

function WideToStr(src:PWideChar):string;
var
  ws:WideString;
  lsize:integer;
begin
  lsize:=Length(src);
  if lsize=0 then exit('');

  SetLength(ws,lsize);
  move(src^,ws[1],lsize*SizeOf(WideChar));
  result:=UTF8Encode(ws);
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

function GetLineWide(var aptr:PByte; var buf:pointer; var asize:integer):PWideChar;
var
  lend:PWideChar;
  llen:integer;
begin
  result:=nil;
  lend:=pointer(aptr);

  while not (lend^ in [#0, #10, #13]) do inc(lend);

  llen:=PByte(lend)-aptr;
  if llen>0 then
  begin
    if (llen+SizeOf(WideChar))>=asize then
    begin
      asize:=Align(llen+SizeOf(WideChar),16);
      ReallocMem(PByte(buf),asize);
    end;
    move(aptr^,PByte(buf)^,llen);
    result:=buf;
    PByte(buf)[llen  ]:=0;
    PByte(buf)[llen+1]:=0;
  end;
  
  while lend^ in [#10, #13] do inc(lend);
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
function ExtractFileNameOnly(const aFilename: string):string;
var
  StartPos: Integer;
  ExtPos: Integer;
begin
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
function ExtractFileExt(const aFileName: string):string;
var
  i:integer;
begin
  Result:='';
  i:=Length(aFileName);

  while (i>0) and not (aFileName[i] in ['/','\','.']) do Dec(i);

  if (i>0) and (aFileName[i]='.') then
  begin
    if (i>1) and not (aFileName[i-1] in ['/','\']) then
      Result:=Copy(aFileName,i);
  end;
end;

//----- Data types -----

const
  RGType : array of record
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
    (code: rgUIntList ; name: 'UINTLIST'        ), // base type = UNSIGNED INT
    (code: rgFloatList; name: 'FLOATLIST'       ), // base type = FLOAT
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
    if CompareWide(atype,RGType[i].name)=0 then
      exit(RGType[i].code);

  result:=rgNotValid;
end;

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

//===== Hash =====

//--- Save file

{$PUSH}
{$Q-}
function CalcCheckSum(aptr:pByte; asize:cardinal):dword;
var
  i:integer;
begin
  if asize>0 then
  begin
    result:=$14D3;

    for i:=0 to asize-1 do
    begin
      result:=result+(result shl 5)+aptr[i];
    end;
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


initialization

  RGLog.Init;

finalization

  RGLog.Free;

end.
