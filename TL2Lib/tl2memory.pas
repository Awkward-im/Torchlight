unit TL2Memory;

interface

uses
  tl2types;

//function ReadIdList         (var buf:PByte):TL2IdList;
//function ReadShortStringList(var buf:PByte):TL2StringList;
function ReadCoord          (var buf:PByte):TL2Coord;

function  ReadByte       (var buf:PByte):Byte;
function  ReadWord       (var buf:PByte):Word;
function  ReadDWord      (var buf:PByte):DWord;
function  ReadQWord      (var buf:PByte):QWord;
function  ReadFloat      (var buf:PByte):Single;
procedure ReadData       (var buf:PByte; var dst; alen:integer);
function  ReadByteString (var buf:PByte):PWideChar;
function  ReadShortString(var buf:PByte):PWideChar;
//procedure WriteByteString (var buf:PByte; const astr:string);
//procedure WriteShortString(var buf:PByte; const astr:string);


implementation


procedure SaveDump(const aname:PChar; aptr:pByte; asize:cardinal);
var
  f:file of byte;
begin
  AssignFile(f,aname);
  Rewrite(f);
  BlockWrite(f,aptr^,asize);
  CloseFile(f);
end;

//----- Basic Read -----

function ReadByte(var buf:PByte):Byte;
begin
  result:=pByte(buf)^; inc(buf);
end;

function ReadWord(var buf:PByte):Word;
begin
  result:=pWord(buf)^; inc(buf,SizeOf(word));
end;

function ReadDWord(var buf:PByte):DWord;
begin
  result:=pDWord(buf)^; inc(buf,SizeOf(DWord));
end;

function ReadQWord(var buf:PByte):QWord;
begin
  result:=pQWord(buf)^; inc(buf,SizeOf(QWord));
end;

function ReadFloat(var buf:PByte):Single;
begin
  result:=pSingle(buf)^; inc(buf,SizeOf(Single));
end;

procedure ReadData(var buf:PByte; var dst; alen:integer);
begin
  move(buf^,pByte(@dst)^,alen); inc(buf,alen);
end;

function ReadByteString(var buf:PByte):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=ReadByte(buf);
  if lsize>0 then
  begin
    GetMem(result,(lsize+1)*SizeOf(WideChar));
    ReadData(buf,result^,lsize*SizeOf(WideChar));
//    move(buf^,result^,lsize*SizeOf(WideChar));
//    inc(buf,lsize*SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

function ReadShortString(var buf:PByte):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=ReadWord(buf);
  if lsize>0 then
  begin
    GetMem(result,(lsize+1)*SizeOf(WideChar));
    ReadData(buf,result^,lsize*SizeOf(WideChar));
//    move(buf^,result^,lsize*SizeOf(WideChar));
//    inc(buf,lsize*SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

//----- Basic Write -----

//----- Complex read -----
{
function ReadIdList(var buf:PByte):TL2IdList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=ReadDWord(buf);
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    ReadData(buf,result[0],lcnt*SizeOf(TL2ID));
  end;
end;

function ReadShortStringList(var buf:PByte):TL2StringList;
var
  lcnt:cardinal;
  i:integer;
begin
  result:=nil;
  lcnt:=ReadDword(buf);
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
      result[i]:=ReadShortString(buf);
  end;
end;
}
function ReadCoord(var buf:PByte):TL2Coord;
begin
  ReadData(buf,result,SizeOf(TL2Coord));
end;


//----- Complex write -----
{
procedure WriteByteString(var buf:PByte; const astr:PWideChar);
var
  llen:integer;
begin
  lllen:=Length(astr);
  WriteByte(buf,llen);
  if llen>0 then
    WriteData(buf,astr,llen*SizeOf(WideChar));
end;

procedure WriteShortString(var buf:PByte; const astr:PWideChar);
var
  llen:integer;
begin
  lllen:=Length(astr);
  WriteWord(buf,llen);
  if llen>0 then
    WriteData(buf,astr,llen*SizeOf(WideChar));
end;
}
exports
  ReadByte,
  ReadWord,
  ReadDWord,
  ReadQWord,
  ReadFloat,
  ReadData,
  ReadByteString,
  ReadShortString,

  ReadCoord
  ;
  
end.
