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
  PPAKFileHeader = ^TPAKFileHeader;
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
  PPAKInfo = ^TPAKInfo;
  TPAKInfo = record
    Entries:array of TMANDirEntry;
    fname:string;
    fsize:dword;
    data :dword;
//    dsize:dword;
    man  :dword;
//    msize:dword;
    ver  :integer;
    // not necessary fields
    root :PWideChar; // same as first directory, MEDIA (usually)
    total:integer;   // total "file" elements. Can be calculated when needs
  end;

//function  GetPAKInfo (astrm:TStream; out api:TPAKInfo):boolean;
function  GetPAKInfo (const fname:string; out api:TPAKInfo):boolean;
function  ReadPAKInfo(const fname:string; deep:boolean=false):pointer;
procedure FreePAKInfo(var aptr:pointer);
procedure DumpPAKInfo(aptr:pointer);

function SearchFile(aptr:pointer; const fname:string):PMANFileInfo;


implementation

uses
  sysutils,
  rgglobal,
//  rgstream,
  rgmemory,
  tl2mod,
  paszlib;

const
  MaxSizeForMem = 24*1024*1024;
{
function FileTypeToText(atype:byte):PWideChar;
begin
end;

function NameToFileType(aname:PWideChar):byte;
begin
end;
}

//----- Manifest -----

procedure ParseManifest(api:PPakInfo; aptr:PByte);
var
  i,j:integer;
begin
  case api^.ver of
    verTL2:begin
      memReadWord (aptr);                         // 0002 version/signature
      memReadDWord(aptr);                         // checksum?
      api^.root :=memReadShortString(aptr);       // root directory !!
      api^.total:=memReadDWord(aptr);             // total "child" records
      SetLength(api^.Entries,memReadDWord(aptr)); // entries
    end;

    verHob,
    verRG :begin
      api^.total:=memReadDWord(aptr);             // total "child" records
      SetLength(api^.Entries,memReadDWord(aptr)); // entries
    end;
  else
    exit;
  end;

  for i:=0 to High(api^.Entries) do
  begin
    api^.Entries[i].name:=memReadShortString(aptr);
    SetLength(api^.Entries[i].Files,memReadDWord(aptr));
    for j:=0 to High(api^.Entries[i].Files) do
    begin
      with api^.Entries[i].Files[j] do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=memReadByte (aptr);
        name    :=memReadShortString(aptr);
        offset  :=memReadDWord(aptr);
        size_s  :=memReadDWord(aptr);
        if api^.ver=verTL2 then
        begin
          ftime:=QWord(memReadInteger64(aptr));
        end;
      end;
    end;
  end;
end;

procedure FreePAKInfo(var aptr:pointer);
var
  lp:PPAKInfo absolute aptr;
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
function GetPAKInfo(const fname:string; out api:TPAKInfo):boolean;
var
  f:file of byte;
  buf:array [0..SizeOf(TTL2ModTech)-1] of byte;
  lhdr:TPAKHeader absolute buf;
  lmi:TTL2ModTech absolute buf;
begin
  result:=false;

  Assign(f,fname);
  Reset(f);

  if IOResult<>0 then exit;

  result:=true;

  BlockRead(f,buf,SizeOf(buf));

  FillChar(api,SizeOf(api),0);
  api.fsize:=FileSize(f);
  api.fname:=fname;

  // check PAK version
  if lhdr.Reserved=0 then
  begin
    if      lhdr.Version=1 then api.ver:=verRG
    else if lhdr.Version=5 then api.ver:=verHob;

    api.man:=lhdr.ManOffset;
  end
  else
  begin
    // if we have MOD header
    if (lmi.version=4) and (lmi.gamever[0]=1) then
    begin
      api.ver :=verTL2Mod;
      api.data:=lmi.offData;
      api.man :=lmi.offMan;
    end
    else
    begin
      api.ver:=verTL2;
    end;
  end;

  Close(f);
end;

function ReadPAKInfo(const fname:string; deep:boolean=false):pointer;
var
  f:file of byte;
  lfhdr:TPAKFileHeader;
  lpi:PPAKInfo;
  ltmp:PByte;
//  lst:TMemoryStream;
  i,j,lsize:integer;
begin
  result:=nil;

  lpi:=AllocMem(SizeOf(TPAKInfo));
  // Get common info
  if GetPAKInfo(fname, lpi^) then
  begin
    result:=lpi;

    // read manifest

    if lpi^.ver=verTL2 then
      Assign(f,lpi^.fname+'.MAN')
    else
      Assign(f,lpi^.fname);

    Reset(f);

    lsize:=FileSize(f)-lpi^.man;
    if lsize>0 then
    begin
      GetMem(ltmp,lsize);
      Seek(f,lpi^.man);
      BlockRead(f,ltmp^,lsize);
      ParseManifest(lpi,ltmp);
      FreeMem(ltmp);
    end;

    // fill filesize info

    if deep then
    begin
      if lpi^.ver=verTL2 then
      begin
        Close(f);
        Assign(f,lpi^.fname);
        Reset(f);
      end;

      lsize:=lpi^.fsize;
      if lsize<=MaxSizeForMem then
      begin
        GetMem(ltmp,lsize);
        Seek(f,0);
        BlockRead(f,ltmp^,lsize);
      end
      else
        ltmp:=nil;
{
      if lsize<=MaxSizeForMem then
      begin
        lst:=TMemoryStream.Create();
        lst.LoadFromFile(fname);
      end
      else
        lst:=nil;
}
      for i:=0 to High(lpi^.Entries) do
      begin
        for j:=0 to High(lpi^.Entries[i].Files) do
        begin
          with lpi^.Entries[i].Files[j] do
            if offset<>0 then
            begin
              if ltmp<>nil then
              begin
                size_u:=PPAKFileHeader(ltmp+lpi^.data+offset)^.size_u;
                size_c:=PPAKFileHeader(ltmp+lpi^.data+offset)^.size_c;
{
              if lst<>nil then
              begin
                size_u:=PPAKFileHeader(lst.Memory[lpi^.data+offset]).size_u;
                size_c:=PPAKFileHeader(lst.Memory[lpi^.data+offset]).size_c;
}
              end
              else
              begin
                Seek(f,lpi^.data+offset);
                BlockRead(f,lfhdr,SizeOf(lfhdr));
                size_u:=lfhdr.size_u;
                size_c:=lfhdr.size_c;
              end;
            end;
        end;
      end;
      if ltmp<>nil then FreeMem(ltmp);
//      if lst<>nil then lst.Free;
    end;
    
    Close(f);
  end
  else
    FreeMem(lpi);
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

procedure DumpPAKInfo(aptr:pointer);
var
  pm:PPAKInfo absolute aptr;
  i,j:integer;
begin
  if aptr=nil then exit;

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

//----- Unpack -----
{$PUSH}
{$I-}
procedure UnpackAll(apak:pointer; const adir:string);
var
  f,fo:file of byte;
  lpi:PPAKInfo absolute apak;
  ldir:String;
  lfhdr:TPAKFileHeader;
  lst:TMemoryStream;
  lptr,lin,lout:PByte;
  i,j:integer;
begin
  if lpi^.fsize<=MaxSizeForMem then
  begin
    lst:=TMemoryStream.Create();
    lst.LoadFromFile(lpi^.fname);
  end
  else
  begin
    lst:=nil;
    Assign(f,lpi^.fname);
    Reset(f);
    if IOResult<>0 then exit;
  end;

  if adir<>'' then
    ldir:=adir+'\'
  else
    ldir:='';

  CreateDir(ldir+'MEDIA');

  for i:=0 to High(lpi^.Entries) do
  begin
    ForceDirectories(ldir+lpi^.Entries[i].name);
    for j:=0 to High(lpi^.Entries[i].Files) do
    begin
      with lpi^.Entries[i].Files[j] do
      begin
        if offset<>0 then
        begin
          if lst<>nil then
          begin
            lst.Position:=lpi^.data+offset;
            lfhdr.size_u:=lst.ReadDword;
            lfhdr.size_c:=lst.ReadDword;

            if lfhdr.size_c=0 then
            begin
              lout:=nil;
              lptr:=lst.Memory+lst.Position;
            end
            else
            begin
              GetMem(lout,lfhdr.size_u);
              lptr:=lout;
              uncompress(PChar(lout),lfhdr.size_u, lst.Memory+lst.Position,lfhdr.size_c);
            end;
          end
          else
          begin
            Seek(f,lpi^.data+offset);
            BlockRead(f,lfhdr,SizeOf(TPAKFileHeader));
            GetMem(lout,lfhdr.size_u);
            lptr:=lout;
            if lfhdr.size_c=0 then
            begin
              BlockRead(f,lout^,lfhdr.size_u);
            end
            else
            begin
              GetMem(lin,lfhdr.size_c);
              BlockRead(f,lin^,lfhdr.size_c);
              uncompress(PChar(lout),lfhdr.size_u, PChar(lin),lfhdr.size_c);
              FreeMem(lin);
            end;
          end;
          //!!
          Assign(fo,WideString(lpi^.Entries[i].name)+WideString(lpi^.Entries[i].Files[j].name));
          Rewrite(f);
          if IOResult=0 then
          begin
            BlockWrite(f,lptr^,lfhdr.size_u);
            Close(f);
          end;
          if lout<>nil then FreeMem(lout);
        end;
      end;
    end;
  end;

  if lst<>nil then lst.Free
  else Close(f);

end;
{$POP}

end.
