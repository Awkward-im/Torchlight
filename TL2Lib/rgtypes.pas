unit RGTypes;

interface

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


implementation

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

function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);
  repeat
    if s1^<>s2^ then exit(false);
    if s1^=#0 then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;


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

end.
