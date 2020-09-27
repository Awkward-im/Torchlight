unit RGGlobal;

interface

//===== Common things =====

//--- Constants

const
  verUnk    = 0;
  verTL1    = 1;
  verTL2    = 2;
  verHob    = 3;
  verRG     = 4;
  verTL2Mod = -verTL2;

//--- Functions

procedure CopyWide(var adst:PWideChar; asrc:PWideChar);
function CopyWide(asrc:PWideChar):PWideChar;
function CompareWide(s1,s2:PWideChar):boolean;

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
  // special
  rgNotValid  = -1;
  rgUnknown   = rgNotValid;
  // layout, custom, readonly
  rgVector2   = 100;
  rgVector3   = 101;
  rgVector4   = 102;
  // user
  rgGroup     = rgNotSet;
  rgWord      = 200;
  rgByte      = 201;
  rgBinary    = 202;


function TypeToText(atype:integer):PWideChar;
function TextToType(atype:PWideChar):integer;

//=====  =====

type
  TRGID = Int64;
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

type
  TL2SaveHeader = packed record
    Sign    :DWord;      // 0x00000044 - format version
    Encoded :ByteBool;
    Checksum:Dword;
  end;
  TL2SaveFooter = packed record
    filesize:DWord;
  end;


//===== Other =====

procedure QuaternionToMatrix(const q:TVector4; out m:TMatrix4x4);

//==========================
//===== Implementation =====
//==========================

implementation

//----- Support -----

function CopyWide(asrc:PWideChar):PWideChar;
var
  llen:integer;
begin
  if (asrc=nil) or (asrc^=#0) then exit(nil);
  llen:=Length(asrc)+1;
  GetMem(    result ,llen*SizeOf(WideChar));
  move(asrc^,result^,llen*SizeOf(WideChar));
end;

procedure CopyWide(var adst:PWideChar; asrc:PWideChar);
begin
  adst:=CopyWide(asrc);
end;

function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);

  repeat
    if s1^<>s2^ then exit(false);
    if s1^= #0  then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;

//----- Data types -----

const
  RGType : array of record
    code:integer;
    name:PWideChar;
  end = (
    (code: rgNotSet   ; name: 'NOT SET'),
    (code: rgInteger  ; name: 'INTEGER'),
    (code: rgFloat    ; name: 'FLOAT'),
    (code: rgDouble   ; name: 'DOUBLE'),
    (code: rgUnsigned ; name: 'UNSIGNED INT'),
    (code: rgString   ; name: 'STRING'),
    (code: rgBool     ; name: 'BOOL'),
    (code: rgInteger64; name: 'INTEGER64'),
    (code: rgTranslate; name: 'TRANSLATE'),
    (code: rgNote     ; name: 'NOTE'),
    // special
    (code: rgNotValid ; name: 'NOT VALID'),
    // layout types (custom, text is readonly)
    (code: rgUnsigned ; name: 'UNSIGNED INTEGER'),
    (code: rgVector2  ; name: 'VECTOR2'),
    (code: rgVector3  ; name: 'VECTOR3'),
    (code: rgVector4  ; name: 'VECTOR4'),
    (code: rgInteger64; name: 'INT64'),
    // user
    (code: rgWord     ; name: 'WORD'),
    (code: rgByte     ; name: 'BYTE'),
    (code: rgBinary   ; name: 'BINARY')
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
    if CompareWide(atype,RGType[i].name) then
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

end.
