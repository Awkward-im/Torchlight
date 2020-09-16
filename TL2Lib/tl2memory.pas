{$CALLING cdecl}
unit TL2Memory;

interface

uses
  tl2types;

//----- Read -----

function  ReadByte       (var buf:PByte):Byte; export;
function  ReadWord       (var buf:PByte):Word; export;
function  ReadDWord      (var buf:PByte):DWord; export;
function  ReadBool       (var buf:PByte):ByteBool; export;
function  ReadInteger    (var buf:PByte):Int32; export;
function  ReadUnsigned   (var buf:PByte):UInt32; export;
function  ReadInteger64  (var buf:PByte):Int64; export;
function  ReadFloat      (var buf:PByte):Single; export;
function  ReadDouble     (var buf:PByte):Double; export;

procedure ReadData       (var buf:PByte; var dst; alen:integer); export;
function  ReadCoord      (var buf:PByte):TL2Coord; export;

function  ReadByteString (var buf:PByte):PWideChar; export;
function  ReadShortString(var buf:PByte):PWideChar; export;
function  ReadDwordString(var buf:PByte):PWideChar; export;
function  ReadShortStringUTF8(var buf:PByte):PWideChar; export;

//function  ReadShortStringList(var buf:PByte):TL2StringList; export;
function  ReadIdList     (var buf:PByte):TL2IdList; export;
function  ReadIdValList  (var buf:PByte):TL2IdValList; export;

//----- write -----

procedure WriteByte       (var buf:PByte; aval:Byte); export;
procedure WriteWord       (var buf:PByte; aval:Word); export;
procedure WriteDWord      (var buf:PByte; aval:DWord); export;
procedure WriteBool       (var buf:PByte; aval:ByteBool); export;
procedure WriteInteger    (var buf:PByte; aval:Int32); export;
procedure WriteUnsigned   (var buf:PByte; aval:UInt32); export;
procedure WriteInteger64  (var buf:PByte; aval:Int64); export;
procedure WriteFloat      (var buf:PByte; aval:Single); export;
procedure WriteDouble     (var buf:PByte; aval:Double); export;

procedure WriteData       (var buf:PByte; var aval; alen:integer); export;
procedure WriteCoord      (var buf:PByte; var aval:TL2Coord); export;

procedure WriteByteString (var buf:PByte; aval:PWideChar); export;
procedure WriteShortString(var buf:PByte; aval:PWideChar); export;

procedure WriteIdList     (var buf:PByte; alist:TL2IdList); export;
procedure WriteIdValList  (var buf:PByte; alist:TL2IdValList); export;

//procedure WriteShortStringList(var buf:PByte; alist:TL2StringList); export;
//procedure WriteByteString (var buf:PByte; const astr:string);
//procedure WriteShortString(var buf:PByte; const astr:string);


implementation

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

function ReadDouble(var buf:PByte):Double;
begin
  result:=pDouble(buf)^; inc(buf,SizeOf(Double));
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
    GetMem  (    result ,(lsize+1)*SizeOf(WideChar));
    ReadData(buf,result^, lsize   *SizeOf(WideChar));
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
  if (lsize>0) and (lsize<$FFFF) then
  begin
    GetMem  (    result ,(lsize+1)*SizeOf(WideChar));
    ReadData(buf,result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

function ReadDwordString(var buf:PByte):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=ReadDWord(buf);
  if lsize>0 then
  begin
    GetMem  (    result ,(lsize+1)*SizeOf(WideChar));
    ReadData(buf,result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

function ReadShortStringUTF8(var buf:PByte):PWideChar;
var
//  ls:WideString;
//  lutf8:PAnsiChar;
  i:integer;
  lsize:cardinal;
begin
  lsize:=ReadWord(buf);
  if (lsize>0) and (lsize<$FFFF) then
  begin
    GetMem(result,(lsize+1)*SizeOf(WideChar));
    i:=UTF8ToUnicode(result,lsize,PChar(buf),lsize);
    inc(buf,lsize);
    if i>0 then
    begin
      ReallocMem(result,i*SizeOf(WideChar));
      result[i-1]:=#0;
    end
    else
    begin
      FreeMem(result);
      result:=nil;
    end;
    
{    GetMem(lutf8,(lsize+1));
    ReadData(buf,lutf8^,lsize);
    lutf8[lsize]:=#0;
    ls:=UTF8Decode(lutf8);
    FreeMem(lutf8);
    GetMem(result,(Length(ls)+1)*SizeOf(WideChar));
    move(PWideChar(ls)^,result^,(Length(ls)+1)*SizeOf(WideChar));
}
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

procedure WriteDouble(var buf:PByte; aval:Double);
begin
  pDouble(buf)^:=aval; inc(buf,SizeOf(Double));
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

function ReadIdList(var buf:PByte):TL2IdList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=ReadDword(buf);
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    ReadData(buf,result[0],lcnt*SizeOf(TL2ID));
  end;
end;

function ReadIdValList(var buf:PByte):TL2IdValList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=ReadDword(buf);
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    ReadData(buf,result[0],lcnt*SizeOf(TL2IdVal));
  end;
end;
{
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

procedure WriteCoord(var buf:PByte; var aval:TL2Coord);
begin
  WriteData(buf,aval,SizeOf(TL2Coord));
end;
{
procedure WriteShortStringList(var buf:PByte; alist:TL2StringList);
var
  lcnt,i:integer;
begin
  lcnt:=Length(alist);
  WriteWord(buf,cardinal(lcnt));
  for i:=0 to lcnt-1 do
    WriteShortString(buf,alist[i]);
end;
}
procedure WriteIdList(var buf:PByte; alist:TL2IdList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  WriteWord(buf,lcnt);
  if lcnt>0 then
    WriteData(buf,alist[0],lcnt*SizeOf(TL2ID));
end;

procedure WriteIdValList(var buf:PByte; alist:TL2IdValList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  WriteWord(buf,lcnt);
  if lcnt>0 then
    WriteData(buf,alist[0],lcnt*SizeOf(TL2IdVal));
end;

//===== Exports =====

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
  ReadShortStringUTF8,

//  ReadShortStringList,
  ReadIdList,
  ReadIdValList,
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

//  WriteShortStringList,
  WriteIdList,
  WriteIdValList,
  WriteCoord

  ;
  
end.
