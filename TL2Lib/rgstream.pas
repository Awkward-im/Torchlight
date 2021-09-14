unit RGStream;

interface

uses
  classes
  ,rgglobal;


type
  TTL2Stream = class helper for TStream
  public
    // read
    function  ReadBytes(asize:cardinal):pointer;
    function  ReadByteString ():string;
    function  ReadShortString():string;
    function  ReadFloat:single;
    function  ReadCoord:TVector3;
    function  ReadShortStringList:TL2StringList;
    function  ReadIdList:TL2IDList;
    function  ReadIdValList:TL2IDValList;

    // write
    procedure WriteByteString (const astr:string);
    procedure WriteShortString(const astr:string);
    procedure WriteByteString (const astr:WideString);
    procedure WriteShortString(const astr:WideString);
    procedure WriteFloat(aval:single);
    procedure WriteCoord(aval:TVector3);
    procedure WriteShortStringList(alist:TL2StringList);
    procedure WriteIdList(alist:TL2IDList);
    procedure WriteIdValList(alist:TL2IDValList);
    procedure WriteFiller(alen:cardinal);
  end;

type
  TTL2MemStream = class helper for TMemoryStream
  public
    procedure SetBuffer(buf:pointer);
  end;

implementation

procedure TTL2MemStream.SetBuffer(buf:pointer);
var
  lsize:PtrInt;
begin
  Clear;
  { Dirty trick
    FCapacity = 0 and not changed
    so, assigned bufer must be free manually
    OR Capacity must be changed before
  }
  SetPointer(buf,MemSize(buf));
end;

//----- Read data -----

function TTL2Stream.ReadBytes(asize:cardinal):pointer;
begin
  GetMem(result ,asize);
  Read  (result^,asize);
end;

function TTL2Stream.ReadByteString():string;
var
  ws:WideString;
  lsize:cardinal;
begin
  lsize:=ReadByte;
  if lsize>0 then
  begin
{
    SetLength(result,lsize*3);
    i:=UnicodeToUtf8(PChar(result),Length(result),PWideChar(self.Memory+self.Position),lsize);
    if i>0 then
    begin
      SetLength(result,i);
    end;
}    
    
    SetLength(ws,lsize);
    Read(ws[1],lsize*SizeOf(WideChar));
    result:=UTF8Encode(ws);
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
    result:=UTF8Encode(ws);
  end
  else
    result:='';
end;

function TTL2Stream.ReadFloat:single;
begin
  Read(result,sizeOf(result));
end;

function TTL2Stream.ReadCoord:TVector3;
begin
  Read(result,sizeOf(result));
end;

function TTL2Stream.ReadShortStringList:TL2StringList;
var
  lcnt:cardinal;
  i:integer;
begin
  result:=nil;
  lcnt:=ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
      result[i]:=ReadShortString;
  end;
end;

function TTL2Stream.ReadIdList:TL2IDList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    Read(result[0],lcnt*SizeOf(TRGID));
  end;
end;

function TTL2Stream.ReadIdValList:TL2IDValList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    Read(result[0],lcnt*SizeOf(TL2IDVal));
  end;
end;

//----- Write data -----

procedure TTL2Stream.WriteByteString(const astr:string);
var
  ws:WideString;
begin
  if astr<>'' then
  begin
    ws:=UTF8Decode(astr);
    WriteByte(Length(ws));
    Write(ws[1],Length(ws)*SizeOf(WideChar));
  end
  else
    WriteByte(0);
end;

procedure TTL2Stream.WriteByteString(const astr:WideString);
begin
  if astr<>'' then
  begin
    WriteByte(Length(astr));
    Write(astr[1],Length(astr)*SizeOf(WideChar));
  end
  else
    WriteByte(0);
end;

procedure TTL2Stream.WriteShortString(const astr:string);
var
  ws:WideString;
begin
  if astr<>'' then
  begin
    ws:=UTF8Decode(astr);
    WriteWord(Length(ws));
    Write(ws[1],Length(ws)*SizeOf(WideChar));
  end
  else
    WriteWord(0);
end;

procedure TTL2Stream.WriteShortString(const astr:WideString);
begin
  if astr<>'' then
  begin
    WriteWord(Length(astr));
    Write(astr[1],Length(astr)*SizeOf(WideChar));
  end
  else
    WriteWord(0);
end;

procedure TTL2Stream.WriteFloat(aval:single);
begin
  Write(aval,SizeOf(aval));
end;

procedure TTL2Stream.WriteCoord(aval:TVector3);
begin
  Write(aval,SizeOf(aval));
end;

procedure TTL2Stream.WriteShortStringList(alist:TL2StringList);
var
  i:integer;
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  WriteDWord(lcnt);
  for i:=0 to lcnt-1 do
    WriteShortString(alist[i]);
end;

procedure TTL2Stream.WriteIdList(alist:TL2IDList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  WriteDWord(lcnt);
  if lcnt>0 then
    Write(alist[0],lcnt*SizeOf(TRGID));
end;

procedure TTL2Stream.WriteIdValList(alist:TL2IDValList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  WriteDWord(lcnt);
  if lcnt>0 then
    Write(alist[0],lcnt*SizeOf(TL2IDVal));
end;

procedure TTL2Stream.WriteFiller(alen:cardinal);
var
  i:integer;
begin
  for i:=0 to alen-1 do
    WriteByte($FF);
end;

end.
