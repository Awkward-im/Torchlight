unit TL2Stream;

interface

uses
  classes
  ,tl2types;


type
  TTL2Stream = class(TMemoryStream)
  public
    procedure SaveTheRest(const fname:string);
    
    // read
    function  ReadBytes(asize:cardinal):pointer;
    function  ReadByteString ():string;
    function  ReadShortString():string;
    function  ReadFloat:TL2Float;
    function  ReadCoord:TL2Coord;
    function  ReadShortStringList:TL2StringList;
    function  ReadIdList:TL2IdList;
    function  ReadIdValList:TL2IdValList;

    // write
    procedure WriteByteString (const astr:string);
    procedure WriteShortString(const astr:string);
    procedure WriteFloat(aval:TL2Float);
    procedure WriteCoord(aval:TL2Coord);
    procedure WriteShortStringList(alist:TL2StringList);
    procedure WriteIdList(alist:TL2IdList);
    procedure WriteIdValList(alist:TL2IdValList);
    procedure WriteFiller(alen:cardinal);
  end;

implementation


procedure TTL2Stream.SaveTheRest(const fname:string);
var
  f:file of byte;
begin
  AssignFile(f,fname);
  Rewrite(f);
  BlockWrite(f,PByte(Memory+Position)^,(Size-4-Position));
  CloseFile(f);
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

function TTL2Stream.ReadFloat:TL2Float;
begin
  Read(result,sizeOf(result));
end;

function TTL2Stream.ReadCoord:TL2Coord;
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

function TTL2Stream.ReadIdList:TL2IdList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    Read(result[0],lcnt*SizeOf(TL2ID));
  end;
end;

function TTL2Stream.ReadIdValList:TL2IdValList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    Read(result[0],lcnt*SizeOf(TL2IdVal));
  end;
end;

//----- Write data -----

procedure TTL2Stream.WriteByteString(const astr:string);
var
  ws:WideString;
begin
  WriteByte(Length(astr));
  if astr<>'' then
  begin
    ws:=UTF8Decode(astr);
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
    ws:=UTF8Decode(astr);
    Write(ws[1],Length(astr)*SizeOf(WideChar));
  end;
end;

procedure TTL2Stream.WriteFloat(aval:TL2Float);
begin
  Write(aval,SizeOf(aval));
end;

procedure TTL2Stream.WriteCoord(aval:TL2Coord);
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

procedure TTL2Stream.WriteIdList(alist:TL2IdList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  WriteDWord(lcnt);
  if lcnt>0 then
    Write(alist[0],lcnt*SizeOf(TL2ID));
end;

procedure TTL2Stream.WriteIdValList(alist:TL2IdValList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  WriteDWord(lcnt);
  if lcnt>0 then
    Write(alist[0],lcnt*SizeOf(TL2IdVal));
end;

procedure TTL2Stream.WriteFiller(alen:cardinal);
var
  i:integer;
begin
  for i:=0 to alen-1 do
    WriteByte($FF);
end;

end.
