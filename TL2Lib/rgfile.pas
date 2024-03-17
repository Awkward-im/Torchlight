{
  Usable for separated (not in container) files. Use RGPack unit for containers
  
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


const
  tofRaw       = 0;   // raw binary data
  tofPacked    = 1;   // packed binary data
  tofRawHdr    = 2;   // raw binary data with header
  tofPackedHdr = 3;   // packed binary data with header
  tofSrc       = 4;   // source
  tofSrcBin    = 5;   // compiled source
  tofEmpty     = $FF;

// return tof* consts
function RGTypeOfFile(aBuf:PByte; aname:PWideChar=nil):integer;
// return tof* for packed state
function RGTypeOfFile(aBuf:PByte; asize:cardinal):integer;
// return true if text DAT/LAYOUT file type
function IsSource(aBuf:PByte; aname:PWideChar=nil):boolean;

//===== [Un]Packing =====

{
  Unpack:
    in  - pbyte_in/stream; insize; [pbyte_out, outsize, bufsize]
    out - pbyte_out; outsize
  Note:
    ????Use aout as buf if not NIL, reallocate if needs
}
function RGFileUnpack      (ain:PByte  ; ainsize:cardinal; var aout:PByte; aoutsize:cardinal=0):cardinal;
function RGFileUnpackStream(ain:TStream; ainsize:cardinal; var aout:PByte; aoutsize:cardinal=0):cardinal;
function RGFileUnpackFile  (const fname:string           ; var aout:PByte; aoutsize:cardinal=0):cardinal;

// rgfiletype or here?
// check for source or binary

{
  Pack:
    in  - pbyte_in; insize, [pbyte_out]
    out - pbyte_out; outsize, bufsize
  Note:
    Use aout as buf if not NIL, reallocate if needs
}
// in: data, size; out: crc, data, size. time and insize if needs
//function PackFile(var ainfo:TManFileInfo; ain:PByte; out aout:PByte):integer;
function RGFilePackSafe(ain:PByte; ainsize:cardinal; var aout:PByte; var abufsize:cardinal):cardinal;
function RGFilePack    (ain:PByte; ainsize:cardinal; var aout:PByte; var abufsize:cardinal):cardinal;

//===== [De]compilation =====

function DecompileFile(ain:PByte; ainsize:cardinal; fname:PUnicodeChar;
                       out aout; asUTF8:boolean=false):boolean;
function DecompileFile(ain:PByte; ainsize:cardinal; const fname:string;
                       out aout; asUTF8:boolean=false):boolean;
function CompileFile  (ain:PByte; fname:PUnicodeChar; out aout:PByte; aver:integer):cardinal;
function CompileFile  (ain:PByte; const fname:string; out aout:PByte; aver:integer):cardinal;

const
  RGExtExts : array [0..2] of string = ('.TXT', '.BINDAT', '.BINLAYOUT');

function FixFileExt(const srcname:string):string;

/////////////////////////////////////////////////////////

implementation

uses
  sysutils,
  paszlib,
  zstream,
//  bufstream,

  rgnode,
  rgio.dat,
  rgio.layout,
  rgio.raw,
  rgio.text,
  
  rgfiletype;


function RGTypeOfFile(aBuf:PByte; aname:PWideChar=nil):integer;
begin
  if aBuf=nil then exit(tofEmpty);

  result:=RGTypeOfFile(aBuf,MemSize(aBuf));
  if result=tofRaw then
  begin
    if PakExtType(aname) in setData then
      if IsSource(aBuf, nil) then
        result:=tofSrc
      else
        result:=tofSrcBin;
  end;
end;

function RGTypeOfFile(aBuf:PByte; asize:cardinal):integer;
begin
  result:=tofRaw;

  if asize>8 then
  begin
    // 1 - have header, unpacked
    if (PPAKFileHeader(aBuf)^.size_u=asize-SizeOf(TPAKFileHeader)) and
       (PPAKFileHeader(aBuf)^.size_c=0) then exit(tofRawHdr);

    if asize>12 then
    begin
      // 2 - have header, packed
      if (PPAKFileHeader(aBuf)^.size_c=asize-SizeOf(TPAKFileHeader)) and
         (abuf[8]=$78) and (abuf[9]=$9C) then exit(tofPackedHdr);
      // 3 - no header, packed
      if PWord(abuf)^=$9C78 then exit(tofPacked);
    end;
  end;
end;

function IsSource(aBuf:PByte; aname:PWideChar=nil):boolean;
begin
  if aBuf<>nil then
  begin
    if aname<>nil then
      result:=PakExtType(aname) in setData
    else
      result:=true;
    if result then
    begin
      if (PDWord(abuf)^=(SIGN_UTF8   +ORD('[') shl 24)) or
         (PDWord(abuf)^=(SIGN_UNICODE+ORD('[') shl 16)) or
         ((Char(abuf^)='[') and (Char(abuf[1]) in [#0,']','_','0'..'9','A'..'Z','a'..'z'])) then
        exit(true);
    end;
  end;
  result:=false;
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
          FreeMem(aout);
          GetMem(aout,abufsize);
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
function RGFileUnpack(ain:PByte; ainsize:cardinal; var aout:PByte; aoutsize:cardinal=0):cardinal;
var
  lin:PByte;
  lsize,lbufsize:cardinal;
  ltof:integer;
begin
  result:=0;
  if (ain=nil){ or (ainsize=0)} then exit;

  ltof:=RGTypeOfFile(ain,ainsize);

  // correct in buf and size
  if (ltof=tofRawHdr) or (ltof=tofPackedHdr) then
  begin
    lin  :=ain    +SizeOf(TPAKFileHeader);
    lsize:=ainsize-SizeOf(TPAKFileHeader);

    if aoutsize=0 then
      aoutsize:=PPAKFileHeader(lin)^.size_u;
  end
  else
  begin
    lin  :=ain;
    lsize:=ainsize;
  end;

  // correct in size (pak with size_c=0)
  if (lsize=0) and (aoutsize>0) then lsize:=aoutsize;
  if  lsize=0 then exit;

  // correct out size
  if aoutsize<lsize then aoutsize:=lsize;

  // correct out buf
  if aout=nil then
    lbufsize:=0
  else
    lbufsize:=MemSize(aout);

  if lbufsize<aoutsize then
  begin
    FreeMem(aout);
    GetMem(aout,Align(aoutsize,4096));
  end;

  // process
  if (ltof=tofRaw) or (ltof=tofRawHdr) then
  begin
    move(lin^,aout^,lsize);
    exit(lsize);
  end
  else
  begin
    if uncompress(
        PChar(aout),aoutsize,
        PChar(ain ),lsize)=Z_OK then
      exit(aoutsize);
  end;
{?? clear out buf if unsuccesful? for what?
  if lbufsize=0 then
  begin
    FreeMem(aout);
    aout:=nil;
  end;
}
end;

function RGFileUnpackStream(ain:TStream; ainsize:cardinal; var aout:PByte; aoutsize:cardinal=0):cardinal;
var
  lin:PByte;
  lms:boolean;
begin
  lms:=ain is TMemoryStream;

  if not lms then
  begin
    GetMem(lin,ainsize);
    ain.ReadBuffer(lin^,ainsize);
  end
  else
    lin:=TMemoryStream(ain).Memory+ain.Position;

  result:=RGFileUnpack(lin,ainsize,aout,aoutsize);

  if not lms then
    FreeMem(lin);
end;

function RGFileUnpackFile(const fname:string; var aout:PByte; aoutsize:cardinal=0):cardinal;
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
    result:=RGFileUnpackStream(st,st.Size,aout,aoutsize);
  end;
  st.Free;
}
end;

//----- Pack -----

function RGFilePackSafe(
        ain :PByte; ainsize :cardinal;
    var aout:PByte; var abufsize:cardinal):cardinal;
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
        FreeMem(aout);
        GetMem(aout,abufsize);
      end;
      data.Position:=0;
      data.ReadBuffer(aout^,result);
    end;
  finally
    data.free;
  end;
end;

function RGFilePack(
        ain :PByte; ainsize :cardinal;
    var aout:PByte; var abufsize:cardinal):cardinal;
var
  loutsize:cardinal;
  lalloc:boolean;
begin
  result:=0;

  if (ain=nil) or (ainsize=0) then exit;

  lalloc:=aout=nil;
  loutsize:=Round(ainsize*1.2)+12;
  if (aout=nil) or (abufsize<loutsize) then
  begin
    abufsize:=Align(loutsize,4096);
    FreeMem(aout);
    GetMem(aout,abufsize);
  end;

  result:=abufsize;
  if compress(PChar(aout),result,PChar(ain),ainsize)<>Z_OK then
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


//----- Decompilation -----

function DecompileFile(ain:PByte; ainsize:cardinal; fname:PUnicodeChar;
                       out aout; asUTF8:boolean=false):boolean;
var
  p:pointer;
  ldata:PByte;
  ltype,ltof:integer;
begin
  result:=false;
  ltype:=PAKExtType(fname);
  if (ltype in setData) then
  begin
    if IsSource(ain) then
    begin
{
      if (ain[0]=$FF) or (ain[1]=0) then
        PWideChar(aout):=CopyWide(PWideChar(ain))
      else
}
      begin
        GetMem(PByte(aout),ainsize);
        move(ain^,PByte(aout)^,ainsize);
      end;
      exit;
    end;

    ltof:=RGTypeOfFile(ain,ainsize);
    if ltof in [tofPacked, tofPackedHdr] then
    begin
      ldata:=nil;
      RGFileUnpack(ain,ainsize,ldata);
    end
    else
    begin
      ldata:=ain;
    end;
    
    if      ltype=typeLayout then p:=ParseLayoutMem(ldata,GetLayoutType(fname))
    else if ltype=typeRAW    then p:=ParseRawMem   (ldata,fname) // or do nothing
    else                          p:=ParseDatMem   (ldata,fname);

    if ldata<>ain then FreeMem(ldata);

    if p=nil then
    begin
      // special case, different format for TL2 and others
{
      if ltype=typeImageset then
      begin
        ltof:=Length(PAnsiChar(ldata))+1;
        GetMem(PByte(aout),ltof);
        move(ain^,PByte(aout)^,ltof);
        result:=true;
      end;
}
      exit;
    end;

    if asUTF8 then
      result:=NodeToUTF8(p,PAnsiChar(aout))
    else
      result:=NodeToWide(p,PWideChar(aout));
    DeleteNode(p);
  end;
end;

function DecompileFile(ain:PByte; ainsize:cardinal; const fname:string;
                       out aout; asUTF8:boolean=false):boolean;
{
var
  p:pointer;
  ldata:PByte;
  ltype,ltof:integer;
}
begin
  result:=DecompileFile(ain,ainsize,PUnicodeChar(UnicodeString(fname)),aout,asUTF8);
{
  result:=false;
  ltype:=PAKExtType(fname);
  if (ltype in setData) then
  begin
    ltof:=RGTypeOfFile(ain,ainsize);
    if ltof in [tofPacked, tofPackedHdr] then
    begin
      ldata:=nil;
      RGFileUnpack(ain,ainsize,ldata);
    end
    else
    begin
      ldata:=ain;
    end;
    
    if      ltype=typeLayout then p:=ParseLayoutMem(ldata,GetLayoutType(fname))
    else if ltype=typeRAW    then p:=ParseRawMem   (ldata,fname) // or do nothing
    else                          p:=ParseDatMem   (ldata,fname);

    if ldata<>ain then FreeMem(ldata);

    if p=nil then
      exit;

    result:=NodeToWide(p,aout);
    DeleteNode(p);
  end;
}
end;

function CompileFile(ain:PByte; fname:PUnicodeChar; out aout:PByte; aver:integer):cardinal;
var
  p:pointer;
  ltype:integer;
begin
  result:=0;
  ltype:=PAKExtType(fname);
  if (ltype in setData) then
  begin
    p:=ParseTextMem(ain);
    if p=nil then
      exit;

    if      ltype=typeLayout then result:=BuildLayoutMem(p,aout,ABS(aver))
    else if ltype=typeRAW    then result:=BuildRawMem   (p,aout,fname)
    else                          result:=BuildDatMem   (p,aout,ABS(aver));

    DeleteNode(p);
  end;
end;

function CompileFile(ain:PByte; const fname:string; out aout:PByte; aver:integer):cardinal;
var
  p:pointer;
  ltype:integer;
begin
  result:=0;
  ltype:=PAKExtType(fname);
  if (ltype in setData) then
  begin
    p:=ParseTextMem(ain);
    if p=nil then
      exit;

    if      ltype=typeLayout then result:=BuildLayoutMem(p,aout,ABS(aver))
    else if ltype=typeRAW    then result:=BuildRawMem   (p,aout,fname)
    else                          result:=BuildDatMem   (p,aout,ABS(aver));

    DeleteNode(p);
  end;
end;


function FixFileExt(const srcname:string):string;
var
  lext:string;
  i:integer;
begin
  lext:=UpCase(ExtractFileExt(srcname));
  if lext<>'' then
    for i:=0 to High(RGExtExts) do
      if lext=RGExtExts[i] then
      begin
        result:=ChangeFileExt(srcname,'');
        exit;
      end;
  result:=srcname;
end;

initialization

end.
