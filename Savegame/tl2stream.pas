unit TL2Stream;

interface

uses
  classes;


type
  TTL2Stream = class(TMemoryStream)
  public
    function  ReadByteString ():string;
    function  ReadShortString():string;
    function  ReadSingle:single;
    procedure WriteByteString (const astr:string);
    procedure WriteShortString(const astr:string);
    procedure WriteSingle(aval:single);
  end;

implementation

function TTL2Stream.ReadByteString():string;
var
  ws:WideString;
  lsize:cardinal;
begin
  lsize:=ReadByte;
  if lsize>0 then
  begin
    SetLength(ws,lsize);
    Read(ws[1],lsize*SizeOf(WideChar));
    {result:=ws; // }result:=UTF8Encode(ws);
  end
  else
    result:='';
end;

function TTL2Stream.ReadShortString():string;
var
  ws:WideString;
  lsize:cardinal;
begin
  lsize:=ReadWord;
  if lsize>0 then
  begin
    SetLength(ws,lsize);
    Read(ws[1],lsize*SizeOf(WideChar));
    {result:=ws; // }result:=UTF8Encode(ws);
  end
  else
    result:='';
end;

function TTL2Stream.ReadSingle:single;
begin
  ReadData(result);
end;

procedure TTL2Stream.WriteByteString(const astr:string);
var
  ws:WideString;
begin
  WriteByte(Length(astr));
  if astr<>'' then
  begin
    {ws:=astr; // }ws:=UTF8Decode(astr);
    Write(ws[1],Length(astr)*SizeOf(WideChar));
  end;
end;

procedure TTL2Stream.WriteShortString(const astr:string);
var
  ws:WideString;
begin
  WriteWord(Length(astr));
  if astr<>'' then
  begin
    {ws:=astr; // }ws:=UTF8Decode(astr);
    Write(ws[1],Length(astr)*SizeOf(WideChar));
  end;
end;

procedure TTL2Stream.WriteSingle(aval:single);
begin
  WriteData(aval);
end;

end.
