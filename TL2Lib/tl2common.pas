unit TL2Common;

interface

uses
   classes
  ,tl2types
  ;

procedure SaveDump(const aname:string; aptr:pByte; asize:cardinal);

function ReadIdList         (AStream:TStream):TL2IdList;
function ReadShortStringList(AStream:TStream):TL2StringList;
function ReadCoord          (AStream:TStream):TL2Coord;

function  ReadByteString  (AStream:TStream):string;
function  ReadShortString (AStream:TStream):string;
procedure WriteByteString (AStream:TStream; const astr:string);
procedure WriteShortString(AStream:TStream; const astr:string);


implementation


procedure SaveDump(const aname:string; aptr:pByte; asize:cardinal);
var
  f:file of byte;
begin
  AssignFile(f,aname);
  Rewrite(f);
  BlockWrite(f,aptr^,asize);
  CloseFile(f);
end;

function ReadIdList(AStream:TStream):TL2IdList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=AStream.ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    AStream.Read(result[0],lcnt*SizeOf(TL2ID));
  end;
end;

function ReadByteString(AStream:TStream):string;
var
  ws:WideString;
  lsize:cardinal;
begin
  lsize:=AStream.ReadByte;
  if lsize>0 then
  begin
    SetLength(ws,lsize);
    AStream.Read(ws[1],lsize*SizeOf(WideChar));
    result:=UTF8Encode(ws);
  end
  else
    result:='';
end;

function ReadShortString(AStream:TStream):string;
var
  ws:WideString;
  lsize:cardinal;
begin
  lsize:=AStream.ReadWord;
  if lsize>0 then
  begin
    SetLength(ws,lsize);
    AStream.Read(ws[1],lsize*SizeOf(WideChar));
    result:=UTF8Encode(ws);
  end
  else
    result:='';
end;

procedure WriteByteString(AStream:TStream; const astr:string);
var
  ws:WideString;
begin
  AStream.WriteByte(Length(astr));
  if astr<>'' then
  begin
    ws:=UTF8Decode(astr);
    AStream.Write(ws[1],Length(astr)*SizeOf(WideChar));
  end;
end;

procedure WriteShortString(AStream:TStream; const astr:string);
var
  ws:WideString;
begin
  AStream.WriteWord(Length(astr));
  if astr<>'' then
  begin
    ws:=UTF8Decode(astr);
    AStream.Write(ws[1],Length(astr)*SizeOf(WideChar));
  end;
end;

function ReadShortStringList(AStream:TStream):TL2StringList;
var
  lcnt:cardinal;
  i:integer;
begin
  result:=nil;
  lcnt:=AStream.ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
      result[i]:=ReadShortString(AStream);
  end;
end;

function ReadCoord(AStream:TStream):TL2Coord;
begin
  AStream.Read(result,SizeOf(TL2Coord));
end;

end.
