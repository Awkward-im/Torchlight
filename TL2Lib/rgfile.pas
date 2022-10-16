{
  Unpack file
  Decompile file
  Compile file
  Pack file
}
unit RGFile;

interface

uses
  classes,
  rgglobal;


function PackedAlready(aBuf:PByte; asize:cardinal):boolean;

//===== [Un]Packing =====

function RGFileUnpack      (ain:PByte  ; ainsize:integer; var aout:PByte; aoutsize:integer=0):integer;
function RGFileUnpackStream(ain:TStream; ainsize:integer; var aout:PByte; aoutsize:integer=0):integer;
function RGFileUnpackFile  (const           fname:string; var aout:PByte; aoutsize:integer=0):integer;

// rgfiletype or here?
// check for source or binary

// in: data, size; out: crc, data, size. time and insize if needs
//function PackFile(var ainfo:TMANFileInfo; ain:PByte; out aout:PByte):integer;
//function CompileFile  (ain:PByte; ainsize:integer; out aout:PByte):integer;
//function DecompileFile(ain:PByte; ainsize:integer; out aout:PByte):integer;
function RGFilePackSafe(ain:PByte; ainsize:integer; var aout:PByte; var abufsize:integer):integer;
function RGFilePack    (ain:PByte; ainsize:integer; var aout:PByte; var abufsize:integer):integer;

function DecompileFile(ain:PByte; ainsize:integer; fname:PUnicodeChar; out aout:PWideChar):boolean;

/////////////////////////////////////////////////////////

implementation

uses
  sysutils,
  paszlib,
  zstream,
  bufstream,

  rgnode,
  rgio.dat,
  rgio.layout,
  rgio.text,
  
  rgfiletype;

const
  setData = [typeDAT, typeWDAT, typeAnimation, typeHIE, typeLayout, typeRAW];

type
  PPAKFileHeader = ^TPAKFileHeader;
  TPAKFileHeader = packed record
    size_u:UInt32;
    size_c:UInt32;      // 0 means "no compression
  end;

function PackedAlready(aBuf:PByte; asize:cardinal):boolean;
begin
  result:=false;

  if asize>12 then
  begin
    // 1 - have header, unpacked
    if (PPAKFileHeader(aBuf)^.size_c=0) then exit;
    // 2 - have header, packed
    if (PPAKFileHeader(aBuf)^.size_c=asize-SizeOf(TPAKFileHeader)) and
       (abuf[8]=$78) and (abuf[9]=$9C) then exit(true);
    // 3 - no header, packed
    if PWord(abuf)^=$9C78 then exit(true);
  end;
end;

//----- Unpack -----
{
function RGFileUnpackSafe(
        ain :PByte; ainsize :integer;
    var aout:PByte; var abufsize:integer):integer;
var
  indata,outdata: TMemoryStream;
  comprStream: TDecompressionStream;
begin
  indata:=TMemoryStream.Create();
  try
    indata.WriteBuffer(ain^,ainsize);
    indata.Position:=0;

    comprStream:=TDecompressionStream.Create(indata);
  
    outdata:=TMemoryStream.Create();
    try
      outdata.CopyFrom(comprStream,);

      result:=outdata.Size;
      if result>0 then
      begin
        if (aout=nil) or (abufsize<result) then // MemSize(aout)
        begin
          abufsize:=Align(result,4096);
          ReallocMem(aout,abufsize);
        end;
        outdata.Position:=0;
        outdata.ReadBuffer(aout^,result);
      end;
    finally
      outdata.free;
    end;

  finally
    indata.free;
  end;
end;
}
function RGFileUnpack(ain:PByte; ainsize:integer; var aout:PByte; aoutsize:integer=0):integer;
var
  lalloc:boolean;
begin
  result:=0;
  if (ain=nil) or (ainsize=0) then exit;

  lalloc:=aout=nil;
  if aout=nil then
  begin
    if aoutsize=0 then
      exit
    else
      GetMem(aout,aoutsize);
  end
  else if MemSize(aout)<aoutsize then
    ReallocMem(aout,Align(aoutsize,4096));

  if uncompress(
      PChar(aout),cardinal(aoutsize),
      PChar(ain ),cardinal(ainsize))=Z_OK then
    result:=aoutsize
  else
  begin
    if lalloc then
    begin
      FreeMem(aout);
      aout:=nil;
    end;
  end;
end;

function RGFileUnpackStream(ain:TStream; ainsize:integer; var aout:PByte; aoutsize:integer=0):integer;
var
  lin:PByte;
begin
  if not (ain is TMemoryStream) then
    GetMem(lin,ainsize)
  else
    lin:=(ain as TMemoryStream).Memory+ain.Position;

  ain.ReadBuffer(lin^,ainsize);
  result:=RGFileUnpack(lin,ainsize,aout,aoutsize);

  if not (ain is TMemoryStream) then
    FreeMem(lin);
end;

function RGFileUnpackFile(const fname:string; var aout:PByte; aoutsize:integer=0):integer;
var
  f:file of byte;
  lin:PByte;
  lsize:integer;
begin
  result:=0;
  Assign(f,fname);
  Reset(f);
  if IOResult=0 then
  begin
    lsize:=FileSize(f);
    if lsize>0 then
    begin
      GetMem(lin,lsize);
      BlockRead(f,lin^,lsize);
      result:=RGFileUnpack(lin,lsize,aout,aoutsize);
      FreeMem(lin);
    end;
    Close(f);
  end;
{
var
  st:TMemoryStream;
begin
  st:=TMemoryStream.Create();
  st.LoadFromFile(fname);
  if st.Size>0 then
  begin
    st.Position:=0;
    result:=GRFileUnpackStream(st,st.Size,aout,aoutsize);
  end;
  st.Free;
}
end;

//----- Pack -----

function RGFilePackSafe(
        ain :PByte; ainsize :integer;
    var aout:PByte; var abufsize:integer):integer;
var
  data: TMemoryStream;
  comprStream: TCompressionStream;
begin
  data:=TMemoryStream.Create();

  comprStream:=TCompressionStream.Create(clMax, data);
  try
    try
      comprStream.WriteBuffer(ain^,ainsize);
    finally
      comprStream.Free;
    end;

    result:=data.Size;
    if result>0 then
    begin
      if (aout=nil) or (abufsize<result) then // MemSize(aout)
      begin
        abufsize:=Align(result,4096);
        ReallocMem(aout,abufsize);
      end;
      data.Position:=0;
      data.ReadBuffer(aout^,result);
    end;
  finally
    data.free;
  end;
end;

function RGFilePack(
        ain :PByte; ainsize :integer;
    var aout:PByte; var abufsize:integer):integer;
var
  loutsize:integer;
  lalloc:boolean;
begin
  result:=0;

  if (ain=nil) or (ainsize=0) then exit;

  lalloc:=aout=nil;
  loutsize:=Round(ainsize*1.2)+12;
  if (aout=nil) or (abufsize<loutsize) then
  begin
    abufsize:=Align(loutsize,4096);
    ReallocMem(aout,abufsize);
  end;

  result:=abufsize;
  if compress(PChar(aout),cardinal(result),PChar(ain),cardinal(ainsize))<>Z_OK then
  begin
    result:=0;
    if lalloc then
    begin
      FreeMem(aout);
      aout:=nil;
      abufsize:=0;
    end;
  end;
end;


function DecompileFile(ain:PByte; ainsize:integer; fname:PUnicodeChar; out aout:PWideChar):boolean;
var
  p:pointer;
  ltype:integer;
begin
  result:=false;
  ltype:=PAKExtType(fname);
  if (ltype in setData) then
  begin
    if ltype=typeLayout then
      p:=ParseLayoutMem(ain,GetLayoutType(fname))
    else if ltype=typeRAW then
    else p:=ParseDatMem(ain);

    if p=nil then
      exit;

    result:=NodeToWide(p,aout);
    DeleteNode(p);
  end;
end;


initialization

end.
