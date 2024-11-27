{TODO: Read*string: add finalizing zero}
(*
  function TStream.ReadAnsiString: AnsiString;

  Var
    TheSize : Longint;
    P : PByte ;
  begin
    Result:='';
    ReadBuffer (TheSize,SizeOf(TheSize));
    SetLength(Result,TheSize);
    // Illegal typecast if no AnsiStrings defined.
    if TheSize>0 then
     begin
       ReadBuffer (Pointer(Result)^,TheSize);
       P:=Pointer(Result)+TheSize;
       p^:=0;
     end;
   end;
*)
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
    function  ReadByteStringWide ():PUnicodeChar;
    function  ReadShortStringWide(abuf:PUnicodeChar=nil):PUnicodeChar;
    function  ReadDWordStringWide():PUnicodeChar;
    function  ReadByteString ():string;
    function  ReadShortString():string;
    function  ReadDWordString():string;
    function  ReadShortStringUTF8():string;
    function  ReadFloat:single;
    function  ReadInt32:integer;
    function  ReadCoord:TVector3;
    function  ReadShortStringList:TL2StringList;
    function  ReadIdList:TL2IDList;
    function  ReadIdValList:TL2IDValList;

    // write
    procedure WriteByteAt (adata:Byte ; apos:cardinal);
    procedure WriteWordAt (adata:Word ; apos:cardinal);
    procedure WriteDWordAt(adata:DWord; apos:cardinal);
    procedure WriteQWordAt(adata:QWord; apos:cardinal);
    procedure WriteByteString (const astr:string);
    procedure WriteShortString(const astr:string);
    procedure WriteDWordString(const astr:string);
    procedure WriteShortStringUTF8(const astr:string);
    procedure WriteByteString (const astr:UnicodeString);
    procedure WriteShortString(const astr:UnicodeString);
    procedure WriteDWordString(const astr:UnicodeString);
    procedure WriteByteString (const astr:PWideChar);
    procedure WriteShortString(const astr:PWideChar);
    procedure WriteDWordString(const astr:PWideChar);
    procedure WriteShortStringUTF8(const astr:UnicodeString);
    procedure WriteFloat(aval:single);
    procedure WriteInt32(aval:integer);
    procedure WriteCoord(aval:TVector3);
    procedure WriteShortStringList(alist:TL2StringList);
    procedure WriteIdList(alist:TL2IDList);
    procedure WriteIdValList(alist:TL2IDValList);
    procedure WriteFiller(alen:cardinal);
  end;

type
  TTL2MemStream = class helper for TMemoryStream
  public
  { Dirty trick
    FCapacity = 0 and not changed
    so, assigned bufer must be free manually
    OR Capacity must be changed before
  }
    procedure SetBuffer(buf:pointer);
    procedure CutBuffer(var buf:pointer);
  end;


implementation


procedure TTL2MemStream.CutBuffer(var buf:pointer);
begin
  buf:=Memory;
  SetPointer(nil,0);
  Clear;
//  FSize:=0;
//  FPosition:=0;
//  SetCapacity (0);
end;

procedure TTL2MemStream.SetBuffer(buf:pointer);
begin
  Clear;
  SetPointer(buf,MemSize(buf));
//  FCapacity:=MemSize(buf);
//  FMemory:=Ptr;
//  FSize:=ASize;
end;

//----- Read data -----

function TTL2Stream.ReadBytes(asize:cardinal):pointer;
begin
  GetMem(result ,asize);
  Read  (result^,asize);
end;

function TTL2Stream.ReadByteStringWide():PUnicodeChar;
var
  lsize:cardinal;
begin
  lsize:=ReadByte();
  if lsize>0 then
  begin
    GetMem(result ,(lsize+1)*SizeOf(WideChar));
    Read  (result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;
{
function TTL2Stream.ReadShortStringWide():PUnicodeChar;
var
  lsize:cardinal;
begin
  lsize:=ReadWord();
  if lsize>0 then
  begin
    GetMem(result ,(lsize+1)*SizeOf(WideChar));
    Read  (result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;
}
function TTL2Stream.ReadShortStringWide(abuf:PUnicodeChar=nil):PUnicodeChar;
var
  lsize:cardinal;
begin
  lsize:=ReadWord();
  if lsize>0 then
  begin
    if abuf=nil then
      GetMem(result ,(lsize+1)*SizeOf(WideChar))
    else
      result:=abuf;
    Read(result^,lsize*SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
  begin
    if abuf<>nil then abuf[0]:=#0;
    result:=nil;
  end;
end;

function TTL2Stream.ReadDWordStringWide():PUnicodeChar;
var
  lsize:cardinal;
begin
  lsize:=ReadDWord();
  if lsize>0 then
  begin
    GetMem(result ,(lsize+1)*SizeOf(WideChar));
    Read  (result^, lsize   *SizeOf(WideChar));
    result[lsize]:=#0;
  end
  else
    result:=nil;
end;

function TTL2Stream.ReadByteString():string;
var
  ws:UnicodeString;
  lsize:cardinal;
begin
  lsize:=ReadByte();
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
  ws:UnicodeString;
  lsize:cardinal;
begin
  lsize:=ReadWord();
  if lsize>0 then
  begin
    SetLength(ws,lsize);
    Read(ws[1],lsize*SizeOf(WideChar));
    result:=UTF8Encode(ws);
  end
  else
    result:='';
end;

function TTL2Stream.ReadDWordString():string;
var
  ws:UnicodeString;
  lsize:cardinal;
begin
  lsize:=ReadDWord();
  if lsize>0 then
  begin
    SetLength(ws,lsize);
    Read(ws[1],lsize*SizeOf(WideChar));
    result:=UTF8Encode(ws);
  end
  else
    result:='';
end;

function TTL2Stream.ReadShortStringUTF8():string;
var
  lsize:cardinal;
begin
  lsize:=ReadWord();
  if lsize>0 then
  begin
    SetLength(result   ,lsize);
    Read     (result[1],lsize);
  end
  else
    result:='';
end;

function TTL2Stream.ReadFloat:single;
begin
  Read(result,sizeOf(result));
end;

function TTL2Stream.ReadInt32:integer;
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

procedure TTL2Stream.WriteByteAt(adata:Byte; apos:cardinal);
var
  lpos:cardinal;  
begin
  lpos:=Position;
  Position:=apos;
  WriteByte(adata);
  Position:=lpos;
end;

procedure TTL2Stream.WriteWordAt(adata:Word; apos:cardinal);
var
  lpos:cardinal;  
begin
  lpos:=Position;
  Position:=apos;
  WriteWord(adata);
  Position:=lpos;
end;

procedure TTL2Stream.WriteDWordAt(adata:DWord; apos:cardinal);
var
  lpos:cardinal;  
begin
  lpos:=Position;
  Position:=apos;
  WriteDWord(adata);
  Position:=lpos;
end;

procedure TTL2Stream.WriteQWordAt(adata:QWord; apos:cardinal);
var
  lpos:cardinal;  
begin
  lpos:=Position;
  Position:=apos;
  WriteQWord(adata);
  Position:=lpos;
end;

procedure TTL2Stream.WriteByteString(const astr:string);
var
  ws:UnicodeString;
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

procedure TTL2Stream.WriteByteString(const astr:UnicodeString);
begin
  if astr<>'' then
  begin
    WriteByte(Length(astr));
    Write(astr[1],Length(astr)*SizeOf(WideChar));
  end
  else
    WriteByte(0);
end;

procedure TTL2Stream.WriteByteString(const astr:PWideChar);
var
  llen:cardinal;
begin
  if astr<>nil then
  begin
    llen:=Length(astr);
    WriteByte(llen);
    Write(astr^,llen*SizeOf(WideChar));
  end
  else
    WriteByte(0);
end;

procedure TTL2Stream.WriteShortString(const astr:string);
var
  ws:UnicodeString;
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

procedure TTL2Stream.WriteShortString(const astr:UnicodeString);
begin
  if astr<>'' then
  begin
    WriteWord(Length(astr));
    Write(astr[1],Length(astr)*SizeOf(WideChar));
  end
  else
    WriteWord(0);
end;

procedure TTL2Stream.WriteShortString(const astr:PWideChar);
var
  llen:cardinal;
begin
  if astr<>nil then
  begin
    llen:=Length(astr);
    WriteWord(llen);
    Write(astr^,llen*SizeOf(WideChar));
  end
  else
    WriteWord(0);
end;

procedure TTL2Stream.WriteDWordString(const astr:string);
var
  ws:UnicodeString;
begin
  if astr<>'' then
  begin
    ws:=UTF8Decode(astr);
    WriteDWord(Length(ws));
    Write(ws[1],Length(ws)*SizeOf(WideChar));
  end
  else
    WriteDWord(0);
end;

procedure TTL2Stream.WriteDWordString(const astr:UnicodeString);
begin
  if astr<>'' then
  begin
    WriteDWord(Length(astr));
    Write(astr[1],Length(astr)*SizeOf(WideChar));
  end
  else
    WriteDWord(0);
end;

procedure TTL2Stream.WriteDWordString(const astr:PWideChar);
var
  llen:cardinal;
begin
  if astr<>nil then
  begin
    llen:=Length(astr);
    WriteDWord(llen);
    Write(astr^,llen*SizeOf(WideChar));
  end
  else
    WriteDWord(0);
end;

procedure TTL2Stream.WriteShortStringUTF8(const astr:string);
begin
  if astr<>'' then
  begin
    WriteWord(Length(astr));
    Write(astr[1],Length(astr));
  end
  else
    WriteWord(0);
end;

procedure TTL2Stream.WriteShortStringUTF8(const astr:UnicodeString);
var
  ls:String;
begin
  if astr<>'' then
  begin
    ls:=UTF8Encode(astr);
    WriteWord(Length(ls));
    Write(ls[1],Length(ls));
  end
  else
    WriteWord(0);
end;


procedure TTL2Stream.WriteFloat(aval:single);
begin
  Write(aval,SizeOf(aval));
end;

procedure TTL2Stream.WriteInt32(aval:integer);
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
