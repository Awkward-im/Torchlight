unit RGPAK;

interface

uses
  classes;

//--- TL2 File Types
const
    tl2Dat       = $00; // .DAT
    tl2Layout    = $01; // .LAYOUT
    tl2Mesh      = $02; // .MESH
    tl2Skeleton  = $03; // .SKELETON
    tl2Dds       = $04; // .DDS
    tl2Png       = $05; // .PNG
    tl2Sound     = $06; // .WAV .OGG
    tl2Directory = $07;
    tl2Material  = $08; // .MATERIAL
    tl2Raw       = $09; // .RAW
    tl2Reserved1 = $0A;
    tl2ImageSet  = $0B; // .IMAGESET
    tl2Ttf       = $0C; // .TTF
    tl2Font      = $0D; // .FONT
    tl2Reserved2 = $0E;
    tl2Reserved3 = $0F;
    tl2Animation = $10; // .ANIMATION
    tl2Hie       = $11; // .HIE
    tl2Other     = $12; // ('Removed' Directory)
    tl2Scheme    = $13; // .SCHEME
    tl2LookNFeel = $14; // .LOOKNFEEL ??
    tl2Mpd       = $15; // .MPP .MPD
    tl2Reserved4 = $16;
    tl2Bik       = $17; // .BIK ?? (unpacked)
    tl2Jpg       = $18; // .JPG

//--- Hob File Types
const
    hobUnknown    = $00;
    hobModel      = $01; // .MDL .MESH
    hobSkeleton   = $02; // .SKELETON
    hobDds        = $03; // .DDS
    hobImage      = $04; // .BMP .PNG .TGA
    hobReserved1  = $05;
    hobSound      = $06; // .OGG .WAV
    hobReserved2  = $07;
    hobDirectory  = $08;
    hobMaterial   = $09; // .MATERIAL
    hobRaw        = $0A; // .RAW
    hobReserved3  = $0B;
    hobImageset   = $0C; // .IMAGESET
    hobTtf        = $0D; // .TTF
    hobReserved4  = $0E;
    hobDat        = $0F; // .DAT
    hobLayout     = $10; // .LAYOUT
    hobAnimation  = $11; // .ANIMATION
    hobReserved5  = $12;
    hobReserved6  = $13;
    hobReserved7  = $14;
    hobReserved8  = $15;
    hobReserved9  = $16;
    hobReserved10 = $17;
    hobProgram    = $18; // .PROGRAM
    hobFontDef    = $19; // .FONTDEF
    hobCompositor = $1A; // .COMPOSITOR
    hobShader     = $1B; // .FRAG .FX .HLSL .VERT
    hobReserved11 = $1C;
    hobPu         = $1D; // .PU
    hobAnno       = $1E; // .ANNO
    hobSBin       = $1F; // .SBIN
    hobWDat       = $20; // .WDAT

type
  PMANFileInfo = ^TMANFileInfo;
  TMANFileInfo = record // not real field order
    ftime   :UInt64;    // TL2 only
    name    :PWideChar;
    checksum:dword;     // CRC32
    size_s  :dword;     // looks like source,not compiled, size (unusable)
    size_c  :dword;     // from TPAKFileHeader
    size_u  :dword;     // from TPAKFileHeader
    offset  :dword;
    ftype   :byte;
  end;
type
  PMANDirEntry = ^TMANDirEntry;
  TMANDirEntry = record
    name:PWideChar;
    Files:array of TMANFileInfo;
  end;
type
  PPAKInfo = ^TPAKInfo;
  TPAKInfo = record
    Entries:array of TMANDirEntry;
    fname  :string;
    fsize  :dword;
    data   :dword;
//    dsize:dword;
    man    :dword;
//    msize:dword;
    ver    :integer;
    // not necessary fields
    root   :PWideChar; // same as first directory, MEDIA (usually)
    total  :integer;   // total "file" elements. Can be calculated when needs
    maxsize:integer;   // max [unpacked] file size
  end;

const
  piNoParse   = 0;
  piParse     = 1;
  piFullParse = 2;

function  GetPAKInfo (var   ainfo:TPAKInfo; aparse:integer=piNoParse):boolean;
procedure FreePAKInfo(var   ainfo:TPAKInfo);
procedure DumpPAKInfo(const ainfo:TPAKInfo);

function SearchFile(aptr:pointer; const fname:string):PMANFileInfo;
function UnpackAll (apak:pointer; const adir:string):boolean;


implementation

uses
  sysutils,
  bufstream,
  rgglobal,
//  rgstream,
  rgmemory,
  tl2mod,
  paszlib;

const
  MaxSizeForMem   = 24*1024*1024;
  BufferStartSize = 64*1024;
  BufferPageSize  = 04*1024;
{
function FileTypeToText(atype:byte):PWideChar;
begin
end;

function NameToFileType(aname:PWideChar):byte;
begin
end;
}

type
  TTL2PAKHeader = packed record
    MaxCSize:dword;     // maximal packed file size in PAK
    CheckSum:dword;     // at least, it looks like
  end;
type
  TPAKHeader = packed record
    Version  :word;
    Reserved :dword;
    ManOffset:dword;
    MaxUSize :dword;    // largest UNpacked file size
  end;
type
  PPAKFileHeader = ^TPAKFileHeader;
  TPAKFileHeader = packed record
    size_u:UInt32;
    size_c:UInt32;      // 0 means "no compression
  end;

//----- Manifest -----

procedure ParseManifest(var ainfo:TPakInfo; aptr:PByte);
var
  i,j:integer;
{$IFDEF DEBUG}
  lcnt:integer;
{$ENDIF}
begin
  case ainfo.ver of
    verTL2Mod,
    verTL2:begin
      memReadWord (aptr);                          // 0002 version/signature
      memReadDWord(aptr);                          // checksum?
      ainfo.root :=memReadShortString(aptr);       // root directory !!
      ainfo.total:=memReadDWord(aptr);             // total "child" records
      SetLength(ainfo.Entries,memReadDWord(aptr)); // entries
    end;

    verHob,
    verRG :begin
      ainfo.total:=memReadDWord(aptr);             // total "child" records
      SetLength(ainfo.Entries,memReadDWord(aptr)); // entries
    end;
  else
    exit;
  end;

{$IFDEF DEBUG}
  lcnt:=ainfo.total;
{$ENDIF}
  for i:=0 to High(ainfo.Entries) do
  begin
    ainfo.Entries[i].name:=memReadShortString(aptr);
    SetLength(ainfo.Entries[i].Files,memReadDWord(aptr));
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
{$IFDEF DEBUG}
      dec(lcnt);
{$ENDIF}
      with ainfo.Entries[i].Files[j] do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=memReadByte (aptr);
        name    :=memReadShortString(aptr);
        offset  :=memReadDWord(aptr);
        size_s  :=memReadDWord(aptr);
        if (ainfo.ver=verTL2) or (ainfo.ver=verTL2Mod) then
        begin
          ftime:=QWord(memReadInteger64(aptr));
        end;
      end;
    end;
  end;
{$IFDEF DEBUG}
  if IsConsole then
    writeln('Total: ',ainfo.total,'; childs: ',Length(ainfo.Entries),'; rest: ',lcnt);
{$ENDIF}
end;

{$PUSH}
{$I-}
function GetPAKInfo(var ainfo:TPAKInfo; aparse:integer=piNoParse):boolean;
var
  f:file of byte;
  buf:array [0..SizeOf(TTL2ModTech)-1] of byte;
  lhdr:TPAKHeader absolute buf;
  lmi:TTL2ModTech absolute buf;
  ls:string;

  lfhdr:TPAKFileHeader;
  ltmp:PByte;
  lst:TStream;
  i,j,lsize:integer;
begin
  result:=false;

  ls:=ainfo.fname;
  FreePAKInfo(ainfo);
  ainfo.fname:=ls;

  Assign(f,ainfo.fname);
  Reset(f);

  if IOResult<>0 then exit;

  result:=true;

  BlockRead(f,buf,SizeOf(buf));

  ainfo.fsize:=FileSize(f);

  // check PAK version
  if lhdr.Reserved=0 then
  begin
    if      lhdr.Version=1 then ainfo.ver:=verRG
    else if lhdr.Version=5 then ainfo.ver:=verHob;

    ainfo.man:=lhdr.ManOffset;
  end
  else
  begin
    // if we have MOD header
    if (lmi.version=4) and (lmi.gamever[0]=1) then
    begin
      ainfo.ver :=verTL2Mod;
      ainfo.data:=lmi.offData;
      ainfo.man :=lmi.offMan;
    end
    else
    begin
      ainfo.ver :=verTL2;
    end;
  end;

  if aparse=piNoParse then
  begin
    Close(f);
    Exit;
  end;

  //--- Parse: read manifest

  if ainfo.ver=verTL2 then
  begin
    Close(f);
    Assign(f,ainfo.fname+'.MAN');
    Reset(f);
    if IOResult<>0 then
      Exit(false);
  end;

  lsize:=FileSize(f)-ainfo.man;
  if lsize>0 then
  begin
    GetMem(ltmp,lsize);
    Seek(f,ainfo.man);
    BlockRead(f,ltmp^,lsize);
    ParseManifest(ainfo,ltmp);
    FreeMem(ltmp);
  end;

  if aparse=piParse then
  begin
    Close(f);
    Exit;
  end;

  //--- Full Parse: fill filesize info

  if ainfo.fsize<=MaxSizeForMem then
  begin
    if ainfo.ver=verTL2 then
    begin
      Close(f);
      Assign(f,ainfo.fname);
      Reset(f);
    end;

    GetMem(ltmp,ainfo.fsize);
    Seek(f,0);
    BlockRead(f,ltmp^,ainfo.fsize);
  end
  else
  begin
    lst:=TBufferedFileStream.Create(ainfo.fname,fmOpenRead);

    ltmp:=nil;
  end;

  for i:=0 to High(ainfo.Entries) do
  begin
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      with ainfo.Entries[i].Files[j] do
        if offset<>0 then
        begin
          if ltmp<>nil then
          begin
            size_u:=PPAKFileHeader(ltmp+ainfo.data+offset)^.size_u;
            size_c:=PPAKFileHeader(ltmp+ainfo.data+offset)^.size_c;
          end
          else
          begin
            lst.Seek(ainfo.data+offset,soBeginning);
            lst.ReadBuffer(lfhdr,SizeOf(lfhdr));
{
            Seek(f,ainfo.data+offset);
            BlockRead(f,lfhdr,SizeOf(lfhdr));
}
            size_u:=lfhdr.size_u;
            size_c:=lfhdr.size_c;
          end;
        end;
    end;
  end;

  if ltmp<>nil then
    FreeMem(ltmp)
  else
    lst.Free;
  
  Close(f);
end;
{$POP}


procedure FreePAKInfo(var ainfo:TPAKInfo);
var
  i,j:integer;
begin
  FreeMem(ainfo.root);
  for i:=0 to High(ainfo.Entries) do
  begin
    FreeMem(ainfo.Entries[i].name);
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      FreeMem(ainfo.Entries[i].Files[j].name);
    end;
    SetLength(ainfo.Entries[i].Files,0);
  end;
  SetLength(ainfo.Entries,0);
  ainfo.fname:='';
  FillChar(ainfo,SizeOf(ainfo),0);
  ainfo.ver:=verUnk;
end;


procedure DumpPAKInfo(const ainfo:TPAKInfo);
var
  ls:string;
  i,j:integer;
  lpack,lfiles,lprocess,ldir:integer;
  lmaxp,lmaxu,lcnt:integer;
begin
  writeln('Root: ',String(WideString(ainfo.Root)));
  lfiles:=0;
  lprocess:=0;
  ldir:=0;
  lpack:=0;
  lcnt:=ainfo.total;
  lmaxp:=0;
  lmaxu:=0;
  for i:=0 to High(ainfo.Entries) do
  begin
    writeln(IntToStr(i+1),'  Directory: ',string(WideString(ainfo.Entries[i].name)));
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      dec(lcnt);
      with ainfo.Entries[i].Files[j] do
      begin
if ABS(ainfo.ver)=verTL2 then
begin
  if ftype=tl2Directory then
  begin
    inc(ldir);
    ls:='    Dir: ';
  end
  else
  begin
    inc(lfiles);
    ls:='    File: ';
if size_s=0       then write('##');
  end;
  if ftype in [tl2Dat,tl2Layout,tl2Animation] then inc(lprocess);
end
else
begin
  if ftype=hobDirectory then
  begin
    inc(ldir);
    ls:='    Dir: ';
  end
  else
  begin
    inc(lfiles);
    ls:='    File: ';
if size_s=0       then write('##');
  end;
  if ftype in [hobWDat,hobDat,hobLayout,hobAnimation] then inc(lprocess);
end;
if size_c>0 then inc(lpack);
if lmaxp<size_c then lmaxp:=size_c;
if lmaxu<size_u then lmaxu:=size_u;

if size_s<>size_u then write('!!');
        writeln(ls,string(widestring(name)),'; type:',ftype,'; source size:',size_s,
        '; compr:',size_c,'; unpacked:',size_u);
      end;
    end;
  end;
  writeln('Total: ',ainfo.total,'; childs: ',Length(ainfo.Entries),'; rest: ',lcnt);
  writeln('Max packed size: '  ,lmaxp,' (0x'+HexStr(lmaxp,8),')');
  writeln('Max unpacked size: ',lmaxu,' (0x'+HexStr(lmaxu,8),')');
  writeln('Packed ',lpack,#13#10'Files ',lfiles,#13#10'Process ',
          lprocess,#13#10'Dirs ',ldir,#13#10'Total ',lfiles+ldir+lprocess);
end;

//===== Files =====

//----- Search -----

function SearchFile(aptr:pointer; const fname:string):PMANFileInfo;
var
  lman:PPAKInfo absolute aptr;
  lentry:PMANDirEntry;
  lpath,lname:string;
  lwpath,lwname:PWideChar;
  i,j:integer;
begin
  if aptr=nil then exit(nil);

  lpath:=ExtractFilePath(fname);
  lname:=ExtractFileName(fname);
  lwpath:=pointer(lpath);
  lwname:=pointer(lname);

  for i:=0 to High(lman^.Entries) do
  begin
    lentry:=@lman^.Entries[i];
    //!! char case
    if CompareWide(lentry^.name,lwpath) then
    begin
      for j:=0 to High(lentry^.Files) do
      begin
        if CompareWide(lentry^.Files[j].name,lwname) then
        begin
          exit(@lentry^.Files[j]);
        end;
      end;

      break;
    end;
  end;

  result:=nil;
end;

procedure GetMaxSizes(const api:TPAKInfo; out acmax,aumax:integer);
begin
  if ABS(api.ver)=verTL2 then
  begin
    aumax:=0;
    acmax:=api.maxsize;
  end
  else
  begin
    acmax:=0;
    aumax:=api.maxsize;
  end;
end;

//----- types -----

type
  PPAKExtInfo = ^TPAKExtInfo;
  TPAKExtInfo = record
    _type   :byte;
    _pack   :bytebool;
    _compile:bytebool;
    _ext    :string;
  end;

type
  PTableExt = ^TTableExt;
  TTableExt = array of TPAKExtInfo;
const
  TableExtTL2:TTableExt = (
    (_type:tl2Dat      ; _pack:true ; _compile:true ; _ext:'.DAT'),
    (_type:tl2Layout   ; _pack:true ; _compile:true ; _ext:'.LAYOUT'),
    (_type:tl2Mesh     ; _pack:true ; _compile:false; _ext:'.MESH'),
    (_type:tl2Skeleton ; _pack:true ; _compile:false; _ext:'.SKELETON'),
    (_type:tl2Dds      ; _pack:true ; _compile:false; _ext:'.DDS'),
    (_type:tl2Png      ; _pack:false; _compile:false; _ext:'.PNG'),
    (_type:tl2Sound    ; _pack:true ; _compile:false; _ext:'.WAV'),
    (_type:tl2Sound    ; _pack:false; _compile:false; _ext:'.OGG'),
    (_type:tl2Material ; _pack:true ; _compile:false; _ext:'.MATERIAL'),
    (_type:tl2Raw      ; _pack:true ; _compile:true ; _ext:'.RAW'),
    (_type:tl2Imageset ; _pack:true ; _compile:false; _ext:'.IMAGESET'),
    (_type:tl2Ttf      ; _pack:true ; _compile:false; _ext:'.TTF'),
    (_type:tl2Font     ; _pack:true ; _compile:false; _ext:'.FONT'),
    (_type:tl2Animation; _pack:true ; _compile:true ; _ext:'.ANIMATION'),
    (_type:tl2Hie      ; _pack:true ; _compile:true ; _ext:'.HIE'),
    (_type:tl2Scheme   ; _pack:true ; _compile:false; _ext:'.SCHEME'),
    (_type:tl2LookNFeel; _pack:true ; _compile:false; _ext:'.LOOKNFEEL'),
    (_type:tl2Mpd      ; _pack:true ; _compile:false; _ext:'.MPP'),
    (_type:tl2Mpd      ; _pack:true ; _compile:false; _ext:'.MPD'),
    (_type:tl2Bik      ; _pack:false; _compile:false; _ext:'.BIK'),
    (_type:tl2Jpg      ; _pack:false; _compile:false; _ext:'.JPG'),
    (_type:tl2Directory; _pack:false; _compile:false; _ext:'')
  );
  
  TableExtHob:TTableExt = (
    (_type:hobModel     ; _pack:true ; _compile:false; _ext:'.MDL'),
    (_type:hobModel     ; _pack:true ; _compile:false; _ext:'.MESH'),
    (_type:hobSkeleton  ; _pack:true ; _compile:false; _ext:'.SKELETON'),
    (_type:hobDds       ; _pack:true ; _compile:false; _ext:'.DDS'),
    (_type:hobImage     ; _pack:true ; _compile:false; _ext:'.BMP'),
    (_type:hobImage     ; _pack:false; _compile:false; _ext:'.PNG'),
    (_type:hobImage     ; _pack:true ; _compile:false; _ext:'.TGA'),
    (_type:hobSound     ; _pack:false; _compile:false; _ext:'.OGG'),
    (_type:hobSound     ; _pack:true ; _compile:false; _ext:'.WAV'),
    (_type:hobMaterial  ; _pack:true ; _compile:false; _ext:'.MATERIAL'),
    (_type:hobRaw       ; _pack:true ; _compile:true ; _ext:'.RAW'),
    (_type:hobImageset  ; _pack:true ; _compile:true ; _ext:'.IMAGESET'),
    (_type:hobTtf       ; _pack:true ; _compile:false; _ext:'.TTF'),
    (_type:hobDat       ; _pack:true ; _compile:true ; _ext:'.DAT'),
    (_type:hobLayout    ; _pack:true ; _compile:true ; _ext:'.LAYOUT'),
    (_type:hobAnimation ; _pack:true ; _compile:true ; _ext:'.ANIMATION'),
    (_type:hobProgram   ; _pack:true ; _compile:false; _ext:'.PROGRAM'),
    (_type:hobFontDef   ; _pack:true ; _compile:false; _ext:'.FONTDEF'),
    (_type:hobCompositor; _pack:true ; _compile:false; _ext:'.COMPOSITOR'),
    (_type:hobShader    ; _pack:true ; _compile:false; _ext:'.FRAG'),
    (_type:hobShader    ; _pack:true ; _compile:false; _ext:'.FX'),
    (_type:hobShader    ; _pack:true ; _compile:false; _ext:'.HLSL'),
    (_type:hobShader    ; _pack:true ; _compile:false; _ext:'.VERT'),
    (_type:hobPu        ; _pack:true ; _compile:false; _ext:'.PU'),
    (_type:hobAnno      ; _pack:true ; _compile:false; _ext:'.ANNO'),
    (_type:hobSBin      ; _pack:true ; _compile:false; _ext:'.SBIN'),
    (_type:hobWDat      ; _pack:true ; _compile:true ; _ext:'.WDAT'),
    (_type:hobDirectory ; _pack:false; _compile:false; _ext:'')
  );

function GetExtInfo(const fname:string; ver:integer):PPAKExtInfo;
var
  lext:string;
  lptr:PTableExt;
  i:integer;
begin
  lext:=UpCase(ExtractFileExt(fname));
  if ver=verTL2 then
    lptr:=@TableExtTL2
  else
    lptr:=@TableExtHob;

  for i:=0 to High(lptr^) do
  begin
    if lext=lptr^[i]._ext then
      exit(@lptr^[i]);
  end;
  //!! Check for text form
  if lext='.TXT' then
  begin
    // RAW.TXT
    // IMAGESET.TXT
    // DAT.TXT
    // LAYOUT.TXT
    // ANIMATION.TXT
    // HIE.TXT
    // WDAT.TXT
  end;
  //!! Check for directory

  result:=nil;
end;

//----- Unpack -----

function Unpack(aptr:PByte):pointer;
var
  strm:TZStream;
  usize,csize:dword;
begin
  usize:=memReadDWord(aptr);
  csize:=memReadDWord(aptr);

  if csize>0 then
  begin
  	strm.avail_in:=0;
  	strm.next_in :=Z_NULL;
  	if inflateInit(strm)<>Z_OK then exit(nil);
  end;

  GetMem(result,usize);

  if csize>0 then
  begin
  	strm.avail_in :=csize;
  	strm.next_in  :=aptr;
  	strm.avail_out:=usize;
  	strm.next_out :=result;

  	if inflate(strm, Z_FINISH)<>Z_OK then; //!!

  	inflateEnd(strm);
  end
  else
    memReadData(aptr,result^,usize);
end;

{$PUSH}
{$I-}
//!! filter needs
function UnpackAll(apak:pointer; const adir:string):boolean;
var
  f:file of byte;
  lpi:PPAKInfo absolute apak;
  ldir,lcurdir:WideString;
  lfhdr:TPAKFileHeader;
  lst:TBufferedFileStream;
  buf,lptr,lin,lout:PByte;
  lcsize,lusize,i,j:integer;
begin
  if lpi^.fsize<=MaxSizeForMem then
  begin
    lst:=nil;

    Assign(f,lpi^.fname);
    Reset(f);
    if IOResult<>0 then exit(false);

    GetMem   (  buf ,lpi^.fsize);
    BlockRead(f,buf^,lpi^.fsize);

    Close(f);
  end
  else
  begin
    try
      lst:=TBufferedFileStream.Create(lpi^.fname,fmOpenRead);
    except
      exit(false);
    end;
    buf:=nil;
  end;

  if adir<>'' then
    ldir:=WideString(adir)+'\'
  else
    ldir:='';

  lcsize:=0;
  lusize:=0;
  lout:=nil;
  lin :=nil;

  CreateDir(ldir+'MEDIA'); //!! ainfo.root

  for i:=0 to High(lpi^.Entries) do
  begin
    //!! dir filter here
    lcurdir:=ldir+WideString(lpi^.Entries[i].name);
    if lcurdir<>'' then
      ForceDirectories(lcurdir);

    for j:=0 to High(lpi^.Entries[i].Files) do
    begin
      with lpi^.Entries[i].Files[j] do
      begin
        if (offset>0) and (size_s>0) then
        begin
          //!! file fileter here
          // Memory
          if buf<>nil then
          begin
            lptr:=buf+lpi^.data+offset;
            lfhdr.size_u:=PPAKFileHeader(lptr)^.size_u;
            lfhdr.size_c:=PPAKFileHeader(lptr)^.size_c;
            inc(lptr,SizeOf(TPAKFileHeader));

            if lfhdr.size_c>0 then
            begin
              if lusize<lfhdr.size_u then
              begin
                lusize:=Align(lfhdr.size_u,BufferPageSize);
                if lusize<BufferStartSize then lusize:=BufferStartSize;
                ReallocMem(lout,lusize);
              end;
              uncompress(
                  PChar(lout),lfhdr.size_u,
                  PChar(lptr),lfhdr.size_c);
              lptr:=lout;
            end;
          end
          // File
          else
          begin
            lst.Seek(lpi^.data+offset,soBeginning);
            lst.ReadBuffer(lfhdr,SizeOf(lfhdr));

            if lusize<lfhdr.size_u then
            begin
              lusize:=Align(lfhdr.size_u,BufferPageSize);
              if lusize<BufferStartSize then lusize:=BufferStartSize;
              ReallocMem(lout,lusize);
            end;
            lptr:=lout;

            if lfhdr.size_c=0 then
            begin
              lst.ReadBuffer(lout^,lfhdr.size_u);
            end
            else
            begin
              if lcsize<lfhdr.size_c then
              begin
                lcsize:=Align(lfhdr.size_c,BufferPageSize);
                if lcsize<BufferStartSize then lcsize:=BufferStartSize;
                ReallocMem(lin,lcsize);
              end;
              lst.Readbuffer(lin^,lfhdr.size_c);
              uncompress(
                  PChar(lout),lfhdr.size_u,
                  PChar(lin ),lfhdr.size_c);
            end;
          end;

          //!!
          Assign (f,lcurdir+WideString(lpi^.Entries[i].Files[j].name));
          Rewrite(f);
          if IOResult=0 then
          begin
            BlockWrite(f,lptr^,lfhdr.size_u);
            Close(f);
          end;
        end;
      end;
    end;
  end;
  if lout<>nil then FreeMem(lout);
  if lin <>nil then FreeMem(lin);

  if lst<>nil then lst.Free
  else FreeMem(buf);

  result:=true;
end;
{$POP}

end.
