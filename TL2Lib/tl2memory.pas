{$CALLING cdecl}
unit TL2Memory;

interface

uses
  tl2types;

//function ReadIdList         (var buf:PByte):TL2IdList;
//function ReadShortStringList(var buf:PByte):TL2StringList;
function  ReadCoord      (var buf:PByte):TL2Coord; export;

function  ReadByte       (var buf:PByte):Byte; export;
function  ReadWord       (var buf:PByte):Word; export;
function  ReadDWord      (var buf:PByte):DWord; export;
function  ReadBool       (var buf:PByte):ByteBool; export;
function  ReadInteger    (var buf:PByte):Int32; export;
function  ReadUnsigned   (var buf:PByte):UInt32; export;
function  ReadInteger64  (var buf:PByte):Int64; export;
function  ReadFloat      (var buf:PByte):Single; export;
procedure ReadData       (var buf:PByte; var dst; alen:integer); export;
function  ReadByteString (var buf:PByte):PWideChar; export;
function  ReadShortString(var buf:PByte):PWideChar; export;
//procedure WriteByteString (var buf:PByte; const astr:string);
//procedure WriteShortString(var buf:PByte; const astr:string);

procedure WriteCoord      (var buf:PByte; var aval:TL2Coord); export;

procedure WriteByte       (var buf:PByte; aval:Byte); export;
procedure WriteWord       (var buf:PByte; aval:Word); export;
procedure WriteDWord      (var buf:PByte; aval:DWord); export;
procedure WriteBool       (var buf:PByte; aval:ByteBool); export;
procedure WriteInteger    (var buf:PByte; aval:Int32); export;
procedure WriteUnsigned   (var buf:PByte; aval:UInt32); export;
procedure WriteInteger64  (var buf:PByte; aval:Int64); export;
procedure WriteFloat      (var buf:PByte; aval:Single); export;
procedure WriteData       (var buf:PByte; var aval; alen:integer); export;
procedure WriteByteString (var buf:PByte; aval:PWideChar); export;
procedure WriteShortString(var buf:PByte; aval:PWideChar); export;

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

function ReadBool(var buf:PByte):ByteBool;
begin
  result:=pByte(buf)^<>0; inc(buf);
end;

function ReadInteger(var buf:PByte):Int32;
begin
  result:=pInt32(buf)^; inc(buf,SizeOf(Int32));
end;

function ReadUnsigned(var buf:PByte):UInt32;
begin
  result:=pUInt32(buf)^; inc(buf,SizeOf(UInt32));
end;

function ReadInteger64(var buf:PByte):Int64;
begin
  result:=pInt64(buf)^; inc(buf,SizeOf(Int64));
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
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

//----- Basic Write -----

procedure WriteByte(var buf:PByte; aval:Byte);
begin
  pByte(buf)^:=aval; inc(buf);
end;

procedure WriteWord(var buf:PByte; aval:Word);
begin
  pWord(buf)^:=aval; inc(buf,SizeOf(word));
end;

procedure WriteDWord(var buf:PByte; aval:DWord);
begin
  pDWord(buf)^:=aval; inc(buf,SizeOf(DWord));
end;

procedure WriteBool(var buf:PByte; aval:ByteBool);
begin
  if aval then pByte(buf)^:=1 else pByte(buf)^:=0; inc(buf);
end;

procedure WriteInteger(var buf:PByte; aval:Int32);
begin
  pInt32(buf)^:=aval; inc(buf,SizeOf(Int32));
end;

procedure WriteUnsigned(var buf:PByte; aval:UInt32);
begin
  pUInt32(buf)^:=aval; inc(buf,SizeOf(UInt32));
end;

procedure WriteInteger64(var buf:PByte; aval:Int64);
begin
  pInt64(buf)^:=aval; inc(buf,SizeOf(Int64));
end;

procedure WriteFloat(var buf:PByte; aval:Single);
begin
  pSingle(buf)^:=aval; inc(buf,SizeOf(Single));
end;

procedure WriteData(var buf:PByte; var aval; alen:integer);
begin
  move(pByte(@aval)^,buf^,alen); inc(buf,alen);
end;

procedure WriteByteString(var buf:PByte; aval:PWideChar);
var
  lsize:cardinal;
begin
  lsize:=Length(aval);
  WriteByte(buf,lsize);
  if lsize>0 then
    WriteData(buf,aval^,lsize*SizeOf(WideChar));
end;

procedure WriteShortString(var buf:PByte; aval:PWideChar);
var
  lsize:cardinal;
begin
  lsize:=Length(aval);
  WriteWord(buf,lsize);
  if lsize>0 then
    WriteData(buf,aval^,lsize*SizeOf(WideChar));
end;

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

procedure WriteCoord(var buf:PByte; var aval:TL2Coord);
begin
  WriteData(buf,aval,SizeOf(TL2Coord));
end;

exports
  ReadByte,
  ReadWord,
  ReadDWord,
  ReadBool,
  ReadInteger,
  ReadUnsigned,
  ReadInteger64,
  ReadFloat,
  ReadData,
  ReadByteString,
  ReadShortString,

  ReadCoord,

  WriteByte,
  WriteWord,
  WriteDWord,
  WriteBool,
  WriteInteger,
  WriteUnsigned,
  WriteInteger64,
  WriteFloat,
  WriteData,
  WriteByteString,
  WriteShortString,

  WriteCoord

  ;
  
end.
