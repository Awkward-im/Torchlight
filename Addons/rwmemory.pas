{$UNDEF DoExport}
{.$DEFINE DoExport}
{$IFDEF DoExport}
  {$CALLING cdecl}
{$ELSE}
  {$DEFINE export;:=}
{$ENDIF DoExport}  

unit RWMemory;

interface

//----- Read -----

function  memReadByte     (var buf:PByte):Byte; export;
function  memReadWord     (var buf:PByte):Word; export;
function  memReadDWord    (var buf:PByte):DWord; export;
function  memReadQWord    (var buf:PByte):QWord; export;
function  memReadShort    (var buf:PByte):Int16; export;

procedure memReadData     (var buf:PByte; out dst; alen:integer); export;
//function  memReadCoord    (var buf:PByte):TVector3; export;

function  memReadBool     (var buf:PByte):ByteBool; export;
function  memReadInteger  (var buf:PByte):Int32; export;
function  memReadUnsigned (var buf:PByte):UInt32; export;
function  memReadInteger64(var buf:PByte):Int64; export;
function  memReadFloat    (var buf:PByte):Single; export;
function  memReadDouble   (var buf:PByte):Double; export;

function  memReadByteString     (var buf:PByte):PWideChar; export;
function  memReadShortString    (var buf:PByte):PWideChar; export;
function  memReadDwordString    (var buf:PByte):PWideChar; export;
function  memReadShortStringUTF8(var buf:PByte):PWideChar; export;

function  memReadByteStringBuf (var buf:PByte; astr:PByte; asize:integer):PWideChar; export;
function  memReadShortStringBuf(var buf:PByte; astr:PByte; asize:integer):PWideChar; export;
function  memReadDwordStringBuf(var buf:PByte; astr:PByte; asize:integer):PWideChar; export;

//function  ReadShortStringList(var buf:PByte):TL2StringList; export;
//function  memReadIdList   (var buf:PByte):TL2IdList; export;
//function  memReadIdValList(var buf:PByte):TL2IdValList; export;

//----- write -----

procedure memWriteByte     (var buf:PByte; aval:Byte); export;
procedure memWriteWord     (var buf:PByte; aval:Word); export;
procedure memWriteDWord    (var buf:PByte; aval:DWord); export;
procedure memWriteQWord    (var buf:PByte; aval:QWord); export;
procedure memWriteShort    (var buf:PByte; aval:Int16); export;

procedure memWriteData     (var buf:PByte; aval:pointer; alen:integer); export;
//procedure memWriteCoord    (var buf:PByte; const aval:TVector3); export;

procedure memWriteBool     (var buf:PByte; aval:ByteBool); export;
procedure memWriteInteger  (var buf:PByte; aval:Int32); export;
procedure memWriteUnsigned (var buf:PByte; aval:UInt32); export;
procedure memWriteInteger64(var buf:PByte; aval:Int64); export;
procedure memWriteFloat    (var buf:PByte; aval:Single); export;
procedure memWriteDouble   (var buf:PByte; aval:Double); export;

procedure memWriteByteString (var buf:PByte; aval:PWideChar); export;
procedure memWriteShortString(var buf:PByte; aval:PWideChar); export;
procedure memWriteDWordString(var buf:PByte; aval:PWideChar); export;

//procedure memWriteIdList   (var buf:PByte; const alist:TL2IdList); export;
//procedure memWriteIdValList(var buf:PByte; const alist:TL2IdValList); export;

//procedure WriteShortStringList(var buf:PByte; alist:TL2StringList); export;
//procedure WriteByteString (var buf:PByte; const astr:string);
//procedure WriteShortString(var buf:PByte; const astr:string);


implementation

//----- Basic Read -----

function memReadByte(var buf:PByte):Byte;
begin
  result:=pByte(buf)^; inc(buf);
end;

function memReadWord(var buf:PByte):Word;
begin
  result:=pWord(buf)^; inc(buf,SizeOf(word));
end;

function memReadDWord(var buf:PByte):DWord;
begin
  result:=pDWord(buf)^; inc(buf,SizeOf(DWord));
end;

function memReadQWord(var buf:PByte):QWord;
begin
  result:=pQWord(buf)^; inc(buf,SizeOf(QWord));
end;

function memReadBool(var buf:PByte):ByteBool;
begin
  result:=pByte(buf)^<>0; inc(buf);
end;

function memReadShort(var buf:PByte):Int16;
begin
  result:=pInt16(buf)^; inc(buf,SizeOf(Int16));
end;

function memReadInteger(var buf:PByte):Int32;
begin
  result:=pInt32(buf)^; inc(buf,SizeOf(Int32));
end;

function memReadUnsigned(var buf:PByte):UInt32;
begin
  result:=pUInt32(buf)^; inc(buf,SizeOf(UInt32));
end;

function memReadInteger64(var buf:PByte):Int64;
begin
  result:=pInt64(buf)^; inc(buf,SizeOf(Int64));
end;

function memReadFloat(var buf:PByte):Single;
begin
  result:=pSingle(buf)^; inc(buf,SizeOf(Single));
end;

function memReadDouble(var buf:PByte):Double;
begin
  result:=pDouble(buf)^; inc(buf,SizeOf(Double));
end;

procedure memReadData(var buf:PByte; out dst; alen:integer);
begin
  move(buf^,pByte(@dst)^,alen); inc(buf,alen);
end;

function memReadByteString(var buf:PByte):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=memReadByte(buf);
  if lsize>0 then
  begin
    GetMem     (    result ,(lsize+1)*SizeOf(WideChar));
    memReadData(buf,result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

function memReadByteStringBuf(var buf:PByte; astr:PByte; asize:integer):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=memReadByte(buf);
  if (lsize>0) and (lsize<asize) then
  begin
    result:=PWideChar(astr);
    memReadData(buf,result^, lsize*SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
  begin
//    dec(buf);
//    inc(buf,lsize*SizeOf(WideChar));
    result:=nil;
  end;
end;

function memReadShortString(var buf:PByte):PWideChar;
var
  lsize:Integer;
begin
  lsize:=memReadShort(buf);
  if lsize>0 then
  begin
    GetMem     (    result ,(lsize+1)*SizeOf(WideChar));
    memReadData(buf,result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

function memReadShortStringBuf(var buf:PByte; astr:PByte; asize:integer):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=memReadShort(buf);
  if (lsize>0) and (lsize<asize) then
  begin
    result:=PWideChar(astr);
    memReadData(buf,result^, lsize*SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
  begin
//    dec(buf,SizeOf(Int16)); //????
//    inc(buf,lsize*SizeOf(WideChar));
    result:=nil;
  end;
end;

function memReadDwordString(var buf:PByte):PWideChar;
var
  lsize:integer;
begin
  lsize:=memReadInteger(buf);
  if lsize>0 then
  begin
    GetMem     (    result ,(lsize+1)*SizeOf(WideChar));
    memReadData(buf,result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

function memReadDwordStringBuf(var buf:PByte; astr:PByte; asize:integer):PWideChar;
var
  lsize:cardinal;
begin
  lsize:=memReadInteger(buf);
  if (lsize>0) and (lsize<asize) then
  begin
    result:=PWideChar(astr);
    memReadData(buf,result^, lsize*SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
  begin
//    dec(buf,SizeOf(Int32));
//    inc(buf,lsize*SizeOf(WideChar));
    result:=nil;
  end;
end;

function memReadShortStringUTF8(var buf:PByte):PWideChar;
var
//  ls:UnicodeString;
//  lutf8:PAnsiChar;
  i:integer;
  lsize:integer;
begin
  lsize:=memReadShort(buf);

  if lsize>0 then
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

procedure memWriteByte(var buf:PByte; aval:Byte);
begin
  pByte(buf)^:=aval; inc(buf);
end;

procedure memWriteWord(var buf:PByte; aval:Word);
begin
  pWord(buf)^:=aval; inc(buf,SizeOf(word));
end;

procedure memWriteDWord(var buf:PByte; aval:DWord);
begin
  pDWord(buf)^:=aval; inc(buf,SizeOf(DWord));
end;

procedure memWriteQWord(var buf:PByte; aval:QWord);
begin
  pQWord(buf)^:=aval; inc(buf,SizeOf(QWord));
end;

procedure memWriteBool(var buf:PByte; aval:ByteBool);
begin
  if aval then pByte(buf)^:=1 else pByte(buf)^:=0; inc(buf);
end;

procedure memWriteShort(var buf:PByte; aval:Int16);
begin
  pInt16(buf)^:=aval; inc(buf,SizeOf(Int16));
end;

procedure memWriteInteger(var buf:PByte; aval:Int32);
begin
  pInt32(buf)^:=aval; inc(buf,SizeOf(Int32));
end;

procedure memWriteUnsigned(var buf:PByte; aval:UInt32);
begin
  pUInt32(buf)^:=aval; inc(buf,SizeOf(UInt32));
end;

procedure memWriteInteger64(var buf:PByte; aval:Int64);
begin
  pInt64(buf)^:=aval; inc(buf,SizeOf(Int64));
end;

procedure memWriteFloat(var buf:PByte; aval:Single);
begin
  pSingle(buf)^:=aval; inc(buf,SizeOf(Single));
end;

procedure memWriteDouble(var buf:PByte; aval:Double);
begin
  pDouble(buf)^:=aval; inc(buf,SizeOf(Double));
end;

procedure memWriteData(var buf:PByte; aval:pointer; alen:integer);
begin
  move(pByte(aval)^,buf^,alen); inc(buf,alen);
end;

procedure memWriteByteString(var buf:PByte; aval:PWideChar);
var
  lsize:cardinal;
begin
  lsize:=Length(aval);
  memWriteByte(buf,lsize);
  if lsize>0 then
    memWriteData(buf,aval,lsize*SizeOf(WideChar));
end;

procedure memWriteShortString(var buf:PByte; aval:PWideChar);
var
  lsize:cardinal;
begin
  lsize:=Length(aval);
  memWriteWord(buf,lsize);
  if lsize>0 then
    memWriteData(buf,aval,lsize*SizeOf(WideChar));
end;

procedure memWriteDWordString(var buf:PByte; aval:PWideChar);
var
  lsize:cardinal;
begin
  lsize:=Length(aval);
  memWriteDWord(buf,lsize);
  if lsize>0 then
    memWriteData(buf,aval,lsize*SizeOf(WideChar));
end;

procedure memWriteShortStringUTF8(var buf:PByte; aval:PWideChar);
var
  pc:PChar;
  lsize:cardinal;
begin
  lsize:=Length(aval);
  GetMem(pc,(lsize+1)*SizeOf(WideChar));
  lsize:=UnicodeToUTF8(pc,lsize+1,aval,lsize)-1;

  memWriteWord(buf,lsize);
  if lsize>0 then
    memWriteData(buf,pc,lsize);
  
  FreeMem(pc);
end;

//----- Complex read -----
{
function memReadIdList(var buf:PByte):TL2IdList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=memReadDword(buf);
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    memReadData(buf,result[0],lcnt*SizeOf(TRGID));
  end;
end;

function memReadIdValList(var buf:PByte):TL2IdValList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=memReadDword(buf);
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    memReadData(buf,result[0],lcnt*SizeOf(TL2IdVal));
  end;
end;
}{
function memReadShortStringList(var buf:PByte):TL2StringList;
var
  lcnt:cardinal;
  i:integer;
begin
  result:=nil;
  lcnt:=memReadDword(buf);
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
      result[i]:=memReadShortString(buf);
  end;
end;
}
{
function memReadCoord(var buf:PByte):TVector3;
begin
  memReadData(buf,result,SizeOf(TVector3));
end;
}

//----- Complex write -----

{
procedure memWriteCoord(var buf:PByte; const aval:TVector3);
begin
  memWriteData(buf,@aval,SizeOf(TVector3));
end;
}
{
procedure memWriteShortStringList(var buf:PByte; alist:TL2StringList);
var
  lcnt,i:integer;
begin
  lcnt:=Length(alist);
  memWriteWord(buf,cardinal(lcnt));
  for i:=0 to lcnt-1 do
    memWriteShortString(buf,alist[i]);
end;
}
{
procedure memWriteIdList(var buf:PByte; const alist:TL2IdList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  memWriteWord(buf,lcnt);
  if lcnt>0 then
    memWriteData(buf,@alist[0],lcnt*SizeOf(TRGID));
end;

procedure memWriteIdValList(var buf:PByte; const alist:TL2IdValList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(alist);
  memWriteWord(buf,lcnt);
  if lcnt>0 then
    memWriteData(buf,@alist[0],lcnt*SizeOf(TL2IdVal));
end;
}
//===== Exports =====
{$IFDEF DoExport}
exports
  memReadByte,
  memReadWord,
  memReadDWord,
  memReadShort,
  memReadBool,
  memReadInteger,
  memReadUnsigned,
  memReadInteger64,
  memReadFloat,
  memReadData,
  memReadByteString,
  memReadShortString,
  memReadShortStringUTF8,

//  ReadShortStringList,
//  memReadIdList,
//  memReadIdValList,
//  memReadCoord,

  memWriteByte,
  memWriteWord,
  memWriteDWord,
  memWriteBool,
  memWriteInteger,
  memWriteUnsigned,
  memWriteInteger64,
  memWriteFloat,
  memWriteData,
  memWriteByteString,
  memWriteShortString,
  memWriteDWordString

//  WriteShortStringList,
//  memWriteIdList,
//  memWriteIdValList,
//  memWriteCoord

  ;
{$ENDIF DoExport}  

end.
