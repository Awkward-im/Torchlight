unit RGPAK;

interface

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
  PPAKExtInfo = ^TPAKExtInfo;
  TPAKExtInfo = record
    _type   :byte;
    _pack   :bytebool;
    _compile:bytebool;
    _ext    :string;
  end;

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
    MaxUSize :dword;    // largest UNpacked file size??
  end;
type
  TPAKFileHeader = packed record
    size_u:UInt32;
    size_c:UInt32;      // 0 means "no compression
  end;
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
  PPAKManifest = ^TPAKManifest;
  TPAKManifest = record
    Entries:array of TMANDirEntry;
    // not necessary fields
    root :PWideChar; // same as first directory, MEDIA (usually)
    total:integer;   // total "file" elements. Can be calculated when needs
  end;


function ReadManifest(const fname:string; var aver:integer; deep:boolean=false):pointer;
procedure FreeManifest(var aptr:pointer);
procedure DumpManifest(aman:pointer);

function SearchFile(aman:pointer; const fname:string):PMANFileInfo;


implementation

uses
  classes,
  sysutils,
  rgglobal,
  rgstream,
  rgmemory,
  tl2mod,
  paszlib;

{
function FileTypeToText(atype:byte):PWideChar;
begin
end;

function NameToFileType(aname:PWideChar):byte;
begin
end;
}

//----- Manifest -----

function ParseManifest(aptr:PByte; aver:integer):pointer;
var
  lp:PPAKManifest;
//  dircode:integer;
  i,j:integer;
begin
  case aver of
    verTL2:begin
      lp:=AllocMem(SizeOf(TPAKManifest));
//      dircode:=ord(TTL2FileTypes.tl2Directory);
      memReadWord (aptr);                        // 0002 version/signature
      memReadDWord(aptr);                        // checksum?
      lp^.root :=memReadShortString(aptr);       // root directory !!
      lp^.total:=memReadDWord(aptr);             // total "child" records
      SetLength(lp^.Entries,memReadDWord(aptr)); // entries
    end;

    verHob,
    verRG :begin
      lp:=AllocMem(SizeOf(TPAKManifest));
//      dircode:=ord(THobFileTypes.hobDirectory);
      lp^.total:=memReadDWord(aptr);             // total "child" records
      SetLength(lp^.Entries,memReadDWord(aptr)); // entries
    end;
  else
    exit(nil);
  end;

  for i:=0 to High(lp^.Entries) do
  begin
    lp^.Entries[i].name:=memReadShortString(aptr);
    SetLength(lp^.Entries[i].Files,memReadDWord(aptr));
    for j:=0 to High(lp^.Entries[i].Files) do
    begin
      with lp^.Entries[i].Files[j] do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=memReadByte(aptr);
        name    :=memReadShortString(aptr);
        offset  :=memReadDWord(aptr);
        size_s  :=memReadDWord(aptr);
        if aver=verTL2 then
        begin
          ftime:=QWord(memReadInteger64(aptr));
        end;
      end;
    end;
  end;
  result:=lp;
end;

procedure FreeManifest(var aptr:pointer);
var
  lp:PPAKManifest absolute aptr;
  i,j:integer;
begin
  if aptr=nil then exit;

  FreeMem(lp^.root);
  for i:=0 to High(lp^.Entries) do
  begin
    FreeMem(lp^.Entries[i].name);
    for j:=0 to High(lp^.Entries[i].Files) do
    begin
      FreeMem(lp^.Entries[i].Files[j].name);
    end;
    SetLength(lp^.Entries[i].Files,0);
  end;
  SetLength(lp^.Entries,0);
  FreeMem(lp);

  aptr:=nil;
end;

{$PUSH}
{$I-}
function ReadManifest(const fname:string; var aver:integer; deep:boolean=false):pointer;
var
  f:file of byte;
  buf:array [0..SizeOf(TTL2ModTech)-1] of byte;
  lhdr:TPAKHeader absolute buf;
  lmi:TTL2ModTech absolute buf;
  lfhdr:TPAKFileHeader;
  ltmp:PByte;
  lofs,ldata:DWord;
  i,j,lsize:integer;
begin
  result:=nil;
  aver:=verUnk;

  Assign(f,fname);
  Reset(f);

  if IOResult<>0 then exit;

  BlockRead(f,buf,SizeOf(buf));

  ldata:=0;
  ltmp:=nil;

  // check PAK version
  if lhdr.Reserved=0 then
  begin
    if      lhdr.Version=1 then aver:=verRG
    else if lhdr.Version=5 then aver:=verHob;

    lofs:=lhdr.ManOffset;
  end
  else
  begin
    aver:=verTL2;
    if (lmi.version=4) and (lmi.gamever[0]=1) then
    begin
      lofs :=lmi.offMan;
      ldata:=lmi.offData;

      Seek(f,lofs);
      lsize:=FileSize(f)-lmi.offMan;
    end
    else
    begin
      Close(f);
      Assign(f,fname+'.MAN');
      Reset(f);
      if IOResult<>0 then exit;
      lofs:=0;

      lsize:=FileSize(f);
    end;
  end;

  lsize:=FileSize(f)-lofs;
  if lsize>0 then
  begin
    Seek(f,lofs);
    GetMem(ltmp,lsize);
    BlockRead(f,ltmp^,lsize);
    result:=ParseManifest(ltmp,aver);
    FreeMem(ltmp);
  end;

  //!!!!
  if (aver=verTL2) and (lofs<>0) then aver:=verTL2Mod;

  if deep then
  begin
    if aver=verTL2 then
    begin
      Close(f);
      Assign(f,fname);
      Reset(f);
    end;

    for i:=0 to High(PPAKManifest(result)^.Entries) do
    begin
      for j:=0 to High(PPAKManifest(result)^.Entries[i].Files) do
      begin
        with PPAKManifest(result)^.Entries[i].Files[j] do
          if offset<>0 then
          begin
            Seek(f,ldata+offset);
            BlockRead(f,lfhdr,SizeOf(lfhdr));
            size_u:=lfhdr.size_u;
            size_c:=lfhdr.size_c;
          end;
      end;
    end;
  end;
  
  Close(f);
end;
{$POP}

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

procedure DumpManifest(aman:pointer);
var
  pm:PPAKManifest absolute aman;
  i,j:integer;
begin
  if aman=nil then exit;

  writeln('Root: ',String(WideString(pm^.Root)));
  for i:=0 to High(pm^.Entries) do
  begin
    writeln('  Directory: ',string(WideString(pm^.Entries[i].name)));
    for j:=0 to High(pm^.Entries[i].Files) do
    begin
      with pm^.Entries[i].Files[j] do
      begin
        writeln('    File: ',string(widestring(name)),'; type:',ftype,'; source size:',size_s,
        '; compr:',size_c,'; unpacked:',size_u);
if size_s<>size_u then writeln('!!');
      end;
    end;
  end;
end;

//===== Files =====

//----- Search -----

function SearchFile(aman:pointer; const fname:string):PMANFileInfo;
var
  lman:PPAKManifest absolute aman;
  lentry:PMANDirEntry;
  lpath,lname:string;
  lwpath,lwname:PWideChar;
  i,j:integer;
begin
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

//----- types -----

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

end.
