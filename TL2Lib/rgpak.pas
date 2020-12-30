unit RGPAK;

interface

uses
  classes,
  tl2mod;

//===== Files =====

type
  PMANFileInfo = ^TMANFileInfo;
  TMANFileInfo = record // not real field order
    ftime   :UInt64;    // TL2 only
    name    :PWideChar; // name in MAN
    nametxt :PWideChar; // source (text format) name
    checksum:dword;     // CRC32
    size_s  :dword;     // looks like source,not compiled, size (unusable)
    size_c  :dword;     // from TPAKFileHeader
    size_u  :dword;     // from TPAKFileHeader
    offset  :dword;
    ftype   :byte;
  end;

function SearchFile(aptr:pointer; const fname:string):PMANFileInfo;
function UnpackAll (apak:pointer; const adir:string):boolean;
//function GetTextName(afile:PMANFileInfo):PWideChar;

//===== Container =====

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
    Deleted:array of TMANDirEntry;
    modinfo:TTL2ModInfo;
    fname  :string;
    fsize  :dword;
    data   :dword;
//    dsize:dword;
    man    :dword;
//    msize:dword;
    ver    :integer;
    pakver :integer;   // actual for TL2 Man (0 or 2 = with checksum)
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
procedure MANtoFile  (const fname:string; const ainfo:TPAKInfo);

type
  TPAKProgress = function(const ainfo:TPAKInfo; adir,afile:integer):integer;
var
  OnPAKProgress:TPAKProgress=nil;

//===== Types =====

const
  typeUnknown    = 00;
  typeMesh       = 01;
  typeSkeleton   = 02;
  typeMaterial   = 03;
  typeDDS        = 04;
  typeImage      = 05;
  typeSound      = 06;
  typeDirectory  = 07;
  typeRAW        = 08;
  typeImageSet   = 09;
  typeTTF        = 10;
  typeFont       = 11;
  typeAnimation  = 12;
  typeDAT        = 13;
  typeLayout     = 14;
  typeHIE        = 15;
  typeDelete     = 16;
  typeScheme     = 17;
  typeLookNFeel  = 18;
  typeMPP        = 19;
  typeBIK        = 20;
  typeJPG        = 21;
  typeProgram    = 22;
  typeCompositor = 23;
  typeShader     = 24;
  typePU         = 25;
  typeAnno       = 26;
  typeSBIN       = 27;
  typeWDAT       = 28;

//----- Category -----

const
  catUnknown = $00;
  catModel   = $01; // .MDL .MESH .SKELETON .MATERIAL
  catImage   = $02; // .DDS .BMP .PNG .TGA .IMAGESET .JPG .BIK
  catSound   = $03; // .OGG .WAV
  catFolder  = $04;
  catFont    = $05; // .TTF .FONT .FONTDEF
  catData    = $06; // .DAT .TEMPLATE .ANIMATION .HIE .WDAT .RAW
  catLayout  = $07; // .LAYOUT
  catShaders = $08; // .PROGRAM .COMPOSITOR .FRAG .FX .HLSL .VERT
  catOther   = $09; // .LOOKNFEEL .SCHEME .MPP .MPD .PU .ANNO .SBIN

const
  CategoryList:array of string = (
    'Unknown',
    'Model',
    'Image',
    'Sound',
    'Directory',
    'Font',
    'Data',
    'Layout',
    'Shaders',
    'Other'
  );

function PAKTypeToCategoryText(aver,atype:integer):string;
//function GetCategory(const aext:WideString):integer;


implementation

uses
  sysutils,
  bufstream,
  rgglobal,
  rgstream,
  rgnode,
  rgmemory,
  paszlib;

//===== types =====


//--- TL2 File Types
const
  tl2Dat       = $00; // .DAT .TEMPLATE
  tl2Layout    = $01; // .LAYOUT
  tl2Mesh      = $02; // .MESH
  tl2Skeleton  = $03; // .SKELETON
  tl2DDS       = $04; // .DDS
  tl2PNG       = $05; // .PNG
  tl2Sound     = $06; // .WAV .OGG
  tl2Directory = $07;
  tl2Material  = $08; // .MATERIAL
  tl2RAW       = $09; // .RAW
  tl2UILayout  = $0A; // .UILAYOUT
  tl2ImageSet  = $0B; // .IMAGESET
  tl2TTF       = $0C; // .TTF .TTC
  tl2Font      = $0D; // .FONT
//  tl2Reserved2 = $0E;  //?? .DAT
//  tl2Reserved3 = $0F;  //?? .LAYOUT
  tl2Animation = $10; // .ANIMATION
  tl2HIE       = $11; // .HIE
  tl2Other     = $12; // ('Removed' Directory)
  tl2Scheme    = $13; // .SCHEME
  tl2LookNFeel = $14; // .LOOKNFEEL ??
  tl2MPP       = $15; // .MPP [.MPD]
//  tl2Reserved4 = $16;  //?? .TEMPLATE
  tl2BIK       = $17; // .BIK
  tl2JPG       = $18; // .JPG
  tl2Unknown   = $FF;

//--- Hob File Types
const
  hobUnknown    = $00;
  hobModel      = $01; // .MDL .MESH
  hobSkeleton   = $02; // .SKELETON
  hobDDS        = $03; // .DDS
  hobImage      = $04; // .BMP .PNG .TGA
//  hobReserved1  = $05;
  hobSound      = $06; // .OGG .WAV
//  hobReserved2  = $07;
  hobDirectory  = $08;
  hobMaterial   = $09; // .MATERIAL
  hobRAW        = $0A; // .RAW
//  hobReserved3  = $0B;
  hobImageset   = $0C; // .IMAGESET
  hobTTF        = $0D; // .TTF
//  hobReserved4  = $0E;
  hobDAT        = $0F; // .DAT
  hobLayout     = $10; // .LAYOUT
  hobAnimation  = $11; // .ANIMATION
//  hobReserved5  = $12;
//  hobReserved6  = $13;
//  hobReserved7  = $14;
//  hobReserved8  = $15;
//  hobReserved9  = $16;
//  hobReserved10 = $17;
  hobProgram    = $18; // .PROGRAM
  hobFontDef    = $19; // .FONTDEF
  hobCompositor = $1A; // .COMPOSITOR
  hobShader     = $1B; // .FRAG .FX .HLSL .VERT
//  hobReserved11 = $1C;
  hobPU         = $1D; // .PU
  hobAnno       = $1E; // .ANNO
  hobSBIN       = $1F; // .SBIN
  //(not my comment) .sbin (31) is actually compiled from .pu (29) and .compositor (26)
  hobWDAT       = $20; // .WDAT

type
  PPAKExtInfo = ^TPAKExtInfo;
  TPAKExtInfo = record
    _int     :byte;
    _pack    :bytebool;
    _compile :bytebool;
  end;

type
  PTableExt = ^TTableExt;
  TTableExt = array of TPAKExtInfo;
const
  TableTL2Info:TTableExt = (
    (_int:typeDat      ; _pack:true ; _compile:true ),
    (_int:typeLayout   ; _pack:true ; _compile:true ),
    (_int:typeMesh     ; _pack:true ; _compile:false),
    (_int:typeSkeleton ; _pack:true ; _compile:false),
    (_int:typeDDS      ; _pack:true ; _compile:false),
    (_int:typeImage    ; _pack:false; _compile:false),
    (_int:typeSound    ; _pack:true ; _compile:false),
    (_int:typeDirectory; _pack:false; _compile:false),
    (_int:typeMaterial ; _pack:true ; _compile:false),
    (_int:typeRAW      ; _pack:true ; _compile:true ),
    (_int:typeUnknown  ; _pack:true ; _compile:false),
    (_int:typeImageset ; _pack:true ; _compile:false),
    (_int:typeTTF      ; _pack:true ; _compile:false),
    (_int:typeFont     ; _pack:true ; _compile:false),
    (_int:typeUnknown  ; _pack:true ; _compile:false),
    (_int:typeUnknown  ; _pack:true ; _compile:false),
    (_int:typeAnimation; _pack:true ; _compile:true ),
    (_int:typeHIE      ; _pack:true ; _compile:true ),
    (_int:typeDelete   ; _pack:false; _compile:false),
    (_int:typeScheme   ; _pack:true ; _compile:false),
    (_int:typeLookNFeel; _pack:true ; _compile:false),
    (_int:typeMPP      ; _pack:true ; _compile:false),
    (_int:typeUnknown  ; _pack:true ; _compile:false),
    (_int:typeBIK      ; _pack:false; _compile:false),
    (_int:typeJPG      ; _pack:false; _compile:false)
  );
  
  TableHobInfo:TTableExt = (
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeMesh      ; _pack:true ; _compile:false),
    (_int:typeSkeleton  ; _pack:true ; _compile:false),
    (_int:typeDDS       ; _pack:true ; _compile:false),
    (_int:typeImage     ; _pack:true ; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeSound     ; _pack:false; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeDirectory ; _pack:false; _compile:false),
    (_int:typeMaterial  ; _pack:true ; _compile:false),
    (_int:typeRAW       ; _pack:true ; _compile:true ),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeImageset  ; _pack:true ; _compile:true ),
    (_int:typeTTF       ; _pack:true ; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeDAT       ; _pack:true ; _compile:true ),
    (_int:typeLayout    ; _pack:true ; _compile:true ),
    (_int:typeAnimation ; _pack:true ; _compile:true ),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typeProgram   ; _pack:true ; _compile:false),
    (_int:typeFont      ; _pack:true ; _compile:false),
    (_int:typeCompositor; _pack:true ; _compile:false),
    (_int:typeShader    ; _pack:true ; _compile:false),
    (_int:typeUnknown   ; _pack:true ; _compile:false),
    (_int:typePU        ; _pack:true ; _compile:false),
    (_int:typeAnno      ; _pack:true ; _compile:false),
    (_int:typeSBIN      ; _pack:true ; _compile:false),
    (_int:typeWDAT      ; _pack:true ; _compile:true )
  );

const
  TableIntInfo: array of record
    _category: byte;
    _tl2     : byte;
    _hob     : byte;
  end = (
    (_category:catUnknown; _tl2:tl2Unknown  ; _hob:hobUnknown),
    (_category:catModel  ; _tl2:tl2Mesh     ; _hob:hobModel),
    (_category:catModel  ; _tl2:tl2Skeleton ; _hob:hobSkeleton),
    (_category:catModel  ; _tl2:tl2Material ; _hob:hobMaterial),
    (_category:catImage  ; _tl2:tl2DDS      ; _hob:hobDDS),
    (_category:catImage  ; _tl2:tl2PNG      ; _hob:hobImage),
    (_category:catSound  ; _tl2:tl2Sound    ; _hob:hobSound),
    (_category:catFolder ; _tl2:tl2Directory; _hob:hobDirectory),
    (_category:catData   ; _tl2:tl2RAW      ; _hob:hobRAW),
    (_category:catImage  ; _tl2:tl2ImageSet ; _hob:hobImageSet),
    (_category:catFont   ; _tl2:tl2TTF      ; _hob:hobTTF),
    (_category:catFont   ; _tl2:tl2Font     ; _hob:hobFontDef),
    (_category:catData   ; _tl2:tl2Animation; _hob:hobAnimation),
    (_category:catData   ; _tl2:tl2DAT      ; _hob:hobDAT),
    (_category:catLayout ; _tl2:tl2Layout   ; _hob:hobLayout),
    (_category:catData   ; _tl2:tl2HIE      ; _hob:hobUnknown),
    (_category:catFolder ; _tl2:tl2Other    ; _hob:hobUnknown),
    (_category:catOther  ; _tl2:tl2Scheme   ; _hob:hobUnknown),
    (_category:catOther  ; _tl2:tl2LookNFeel; _hob:hobUnknown),
    (_category:catOther  ; _tl2:tl2MPP      ; _hob:hobUnknown),
    (_category:catImage  ; _tl2:tl2BIK      ; _hob:hobUnknown),
    (_category:catImage  ; _tl2:tl2JPG      ; _hob:hobUnknown),
    (_category:catShaders; _tl2:tl2Unknown  ; _hob:hobProgram),
    (_category:catShaders; _tl2:tl2Unknown  ; _hob:hobCompositor),
    (_category:catShaders; _tl2:tl2Unknown  ; _hob:hobShader),
    (_category:catOther  ; _tl2:tl2Unknown  ; _hob:hobPU),
    (_category:catOther  ; _tl2:tl2Unknown  ; _hob:hobAnno),
    (_category:catOther  ; _tl2:tl2Unknown  ; _hob:hobSBIN),
    (_category:catData   ; _tl2:tl2Unknown  ; _hob:hobWDAT)
  );

const
  TableExt: array of record
     _type: byte;
     _ext : string;
  end = (
    (_type:typeDAT       ; _ext:'.DAT'),
    (_type:typeDAT       ; _ext:'.TEMPLATE'),
    (_type:typeLayout    ; _ext:'.LAYOUT'),
    (_type:typeUnknown   ; _ext:'.UILAYOUT'), //!!
    (_type:typeMesh      ; _ext:'.MESH'),
    (_type:typeSkeleton  ; _ext:'.SKELETON'),
    (_type:typeDDS       ; _ext:'.DDS'),
    (_type:typeImage     ; _ext:'.PNG'),
    (_type:typeSound     ; _ext:'.WAV'),
    (_type:typeSound     ; _ext:'.OGG'),
    (_type:typeMaterial  ; _ext:'.MATERIAL'),
    (_type:typeRAW       ; _ext:'.RAW'),
    (_type:typeImageSet  ; _ext:'.IMAGESET'),
    (_type:typeTTF       ; _ext:'.TTF'),
    (_type:typeTTF       ; _ext:'.TTC'),
    (_type:typeFont      ; _ext:'.FONT'),
    (_type:typeAnimation ; _ext:'.ANIMATION'),
    (_type:typeHIE       ; _ext:'.HIE'),
    (_type:typeScheme    ; _ext:'.SCHEME'),
    (_type:typeLookNFeel ; _ext:'.LOOKNFEEL'),
    (_type:typeMPP       ; _ext:'.MPP'),
    (_type:typeMPP       ; _ext:'.MPD'),
    (_type:typeBIK       ; _ext:'.BIK'),
    (_type:typeJPG       ; _ext:'.JPG'),
    (_type:typeImage     ; _ext:'.MDL'),
    (_type:typeImage     ; _ext:'.BMP'),
    (_type:typeImage     ; _ext:'.TGA'),
    (_type:typeProgram   ; _ext:'.PROGRAM'),
    (_type:typeFont      ; _ext:'.FONTDEF'),
    (_type:typeCompositor; _ext:'.COMPOSITOR'),
    (_type:typeShader    ; _ext:'.FRAG'),
    (_type:typeShader    ; _ext:'.FX'),
    (_type:typeShader    ; _ext:'.HLSL'),
    (_type:typeShader    ; _ext:'.VERT'),
    (_type:typePU        ; _ext:'.PU'),
    (_type:typeAnno      ; _ext:'.ANNO'),
    (_type:typeSBIN      ; _ext:'.SBIN'),
    (_type:typeWDAT      ; _ext:'.WDAT')
//    (_type:typeDelete    ; _ext:'<OTHER>'),
//    (_type:typeDirectory ; _ext:'<DIR>')
  );


function GetExtInfo(const fname:string; ver:integer):PPAKExtInfo;
var
  lext:string;
  lptr:PTableExt;
  i:integer;
begin
  lext:=UpCase(ExtractFileExt(fname));
  if ver=verTL2 then
    lptr:=@TableTL2Info
  else
    lptr:=@TableHobInfo;

  for i:=0 to High(lptr^) do
  begin
{!!
    if lext=lptr^[i]._ext then
      exit(@lptr^[i]);
}
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


function PAKTypeToCategoryText(aver,atype:integer):string;
var
  lt:TTableExt;
  i:integer;
begin
  if (atype>=Low(TableIntInfo)) and (atype<Length(TableIntInfo)) then
    result:=CategoryList[TableIntInfo[atype]._category]
  else
    result:=CategoryList[catUnknown];
{
  if ABS(aver)=verTL2 then lt:=TableExtTL2 else lt:=TableExtHob;
  for i:=0 to High(lt) do
  begin
    if lt[i]._type=atype then
    begin
      exit(CategoryList[lt[i]._category]);
    end;
  end;
  result:=CategoryList[catUnknown];
}
end;

function TypeToInt(aver,atype:integer):integer;
var
  lt:TTableExt;
begin
  case aver of
    verTL2Mod,
    verTL2: lt:=TableTL2Info;
    verHob,
    verRG : lt:=TableHobInfo;
  else
    exit(atype);
  end;
  if (atype>=Low(lt)) and (atype<Length(lt)) then
    result:=lt[atype]._int
  else
    result:=atype;
end;

function IntToType(aver,atype:integer):integer;
begin
  if (atype>=Low(TableIntInfo)) and (atype<Length(TableIntInfo)) then
  begin
    case aver of
      verTL2Mod,
      verTL2: result:=TableIntInfo[atype]._tl2;
      verHob,
      verRG : result:=TableIntInfo[atype]._hob;
    else
      result:=atype;
    end;
  end
  else
    result:=atype;
end;

//===== Container =====

const
  MaxSizeForMem   = 24*1024*1024;
  BufferStartSize = 64*1024;
  BufferPageSize  = 04*1024;

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

{
  Parse Manifest from memory block addressed by aptr
}
procedure ParseManifest(var ainfo:TPakInfo; aptr:PByte);
var
  i,j:integer;
  ltotal,lcnt:integer;
begin
  case ainfo.ver of
    verTL2Mod,
    verTL2:begin
      ainfo.pakver:=memReadWord(aptr);         // 0002 version/signature
      if ainfo.pakver>=2 then                  // 0000 - no "checksum" field??
        memReadDWord(aptr);                    // checksum?
      ainfo.root:=memReadShortString(aptr);    // root directory !!
    end;

    verHob,
    verRG :begin
    end;

  else
    exit;
  end;

  ainfo.total:=memReadDWord(aptr);             // total directory records
  SetLength(ainfo.Entries,memReadDWord(aptr)); // entries
  ltotal:=0;

  for i:=0 to High(ainfo.Entries) do
  begin
    ainfo.Entries[i].name:=memReadShortString(aptr);
    lcnt:=memReadDWord(aptr);
    SetLength(ainfo.Entries[i].Files,lcnt);
    inc(ltotal,lcnt);

    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      with ainfo.Entries[i].Files[j] do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=TypeToInt(ainfo.ver,memReadByte(aptr));
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

//  ainfo.total:=ltotal; //!!!! keep real children count
end;

{
  Build Manifest [and save it to file named ainfo.fname] [within stream]
}
{$PUSH}
{$I-}
function WriteManifest(var ainfo:TPAKInfo; const aname:string; aver:integer):integer;
var
  lst:TMemoryStream;
  i,j:integer;
begin
  result:=0;

  lst:=TMemoryStream.Create;

  try
    case aver of
      verTL2Mod,
      verTL2: begin
        lst.WriteWord(2);  // writing always "new" version
        lst.WriteDWord(0); //!! CRC
        lst.WriteShortString(ainfo.root);
      end;

      verHob,
      verRG: begin
      end;
    else
      lst.Free;
      exit;
    end;

    lst.WriteDWord(ainfo.total);
    lst.WriteDWord(Length(ainfo.Entries));

    for i:=0 to High(ainfo.Entries) do
    begin
      lst.WriteShortString(ainfo.fname);
      lst.WriteDWord(Length(ainfo.Entries[i].Files));

      for j:=0 to High(ainfo.Entries[i].Files) do
      begin
        with ainfo.Entries[i].Files[j] do
        begin
          lst.WriteDWord(checksum);
          lst.WriteByte(IntToType(ainfo.ver,ftype));
          lst.WriteShortString(name);
          lst.WriteDWord(offset);
          lst.WriteDWord(size_s);
          if (aver=verTL2) or (aver=verTL2Mod) then
            lst.WriteQWord(ftime);
        end;
      end;
    end;

    result:=ainfo.total;

  finally
    lst.Free;
  end;
end;
{$POP}

{
  Build files tree [from MEDIA folder] [from dir]
  excluding PNG if DDS presents
  [excluding data sources]
}
function BuildManifest(const adir:string; out ainfo:TPAKInfo):integer;
begin
  result:=0;
end;

procedure MANtoFile(const fname:string; const ainfo:TPAKInfo);
var
  lman,lp,lc:pointer;
  i,j:integer;
begin
  lman:=nil;

  lman:=AddGroup(nil,'MANIFEST');
  AddString (lman,'FILE' ,PWideChar(WideString(ainfo.fname)));
  AddInteger(lman,'TOTAL',ainfo.total);
  AddInteger(lman,'COUNT',Length(ainfo.Entries));
  for i:=0 to High(ainfo.Entries) do
  begin
    lp:=AddGroup(lman,'PARENT');
    AddString (lp,'NAME' ,ainfo.Entries[i].name);
    AddInteger(lp,'COUNT',Length(ainfo.Entries[i].Files));
    lp:=AddGroup(lp,'CHILDREN');
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      lc:=AddGroup(lp,'CHILD');
      with ainfo.Entries[i].Files[j] do
      begin
        AddUnsigned (lc,'CRC'   ,checksum);
        AddInteger  (lc,'TYPE'  ,ftype);
        AddString   (lc,'NAME'  ,name);
        AddInteger  (lc,'OFFSET',offset);
        AddInteger  (lc,'SIZE'  ,size_s);
        AddInteger64(lc,'TIME'  ,ftime);
      end;
    end;
  end;

  WriteDatTree(lman,PChar(fname));
  DeleteNode(lman);
end;

procedure FileToMAN(const fname:string; out ainfo:TPAKInfo);
var
  lman,lp,lc:pointer;
  i,j:integer;
begin
  lman:=ParseDatFile(PChar(fname));
  if lman<>nil then
  begin
    if CompareWide(GetNodeName(lman),'MANIFEST') then
    begin

      for i:=0 to GetChildCount(lman)-1 do
      begin
        lc:=GetChild(lman,i)
        case GetNodeType(lc) of
          rgString: begin
            if CompareWide(GetNodeName(lc),'FILE') then
            ;
          end;

          rgInteger: begin
            if CompareWide(GetNodeName(lc),'TOTAL') then
            ;
            if CompareWide(GetNodeName(lc),'COUNT') then
            ;
          end;

          rgGroup: begin
            if CompareWide(GetNodeName(lc),'PARENT') then
            begin
              for j:=0 to GetChildCount(lc)-1 do
              begin
                lp:=GetChild(lc,j);
                case GetNodeType(lp) of
                  rgString: begin
                    if CompareWide(GetNodeName(lc),'NAME') then
                    ;
                  end;

                  rgInteger: begin
                    if CompareWide(GetNodeName(lc),'COUNT') then
                    ;
                  end;

                  rgGroup: begin
                    if CompareWide(GetNodeName(lc),'CHILDREN') then
                    begin
                      for k:=0 to GetChildCount(lp)-1 do
                      begin
                        lg:=GetChild(lp,k);
                        if (GetNodeType(lg)=rgGroup) and
                           CompareWide(GetNodeName(lg),'CHILD') then
                        begin

                          // name for file
                          // type for dir
                          // size for "deleted"
{
                          case GetNodeType(lg) of
                            rgString: begin
                            end;

                            rgInteger: begin
                            end;
                            rgUnsigned: ;
                            rgInteger64:;
                          end;
}                        
                        end;
                      end;
                    end;
                  end;

                end;

              end;
            end;
          end;

        end;

      end;
    end;

    DeleteNode(lman);
  end;
end;

//----- PAK/MOD -----

{
  Parse PAK/MOD/MAN file named ainfo.fname
}
{$PUSH}
{$I-}
function GetPAKInfo(var ainfo:TPAKInfo; aparse:integer=piNoParse):boolean;
var
  f:file of byte;

  buf:array [0..SizeOf(TTL2ModTech)-1] of byte;
  lhdr :TPAKHeader    absolute buf;
  lhdr2:TTL2PAKHeader absolute buf;
  lmi  :TTL2ModTech   absolute buf;

  lfhdr:TPAKFileHeader;
  ls:string;
  ltmp:PByte;
  lst:TStream;
  i,j,lsize:integer;
begin
  result:=false;

  ls:=ainfo.fname;
  FreePAKInfo(ainfo);
  ainfo.fname:=ls;

  //--- Check by ext

  ls:=UpCase(ExtractFileExt(ainfo.fname));

  if ls='.MAN' then
  begin
    ainfo.ver:=verTL2;
    if aparse=piNoParse then
      exit;
  end;

  //--- Get data

  Assign(f,ainfo.fname);
  Reset(f);

  if IOResult<>0 then exit;

  result:=true;

  //--- Check by data

  // if not .MAN file selected
  if ainfo.ver<>verTL2 then
  begin
    buf[0]:=0;
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
      if ((lmi.version=4) and (lmi.gamever[0]=1)) or
         (ls='.MOD') then
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

    if ainfo.ver=verTL2 then
    begin
      Close(f);
      Assign(f,ainfo.fname+'.MAN');
      Reset(f);
      if IOResult<>0 then
        Exit(false);
    end;
  end;

  //--- Parse: TL2ModInfo

  if ainfo.ver=verTL2Mod then
  begin
    GetMem(ltmp,ainfo.data);
    Seek(f,0);
    BlockRead(f,ltmp^,ainfo.data);
    ReadModInfoBuf(ltmp,ainfo.modinfo);
    FreeMem(ltmp);
  end;

  //--- Parse: read manifest

  lsize:=FileSize(f)-ainfo.man;
  if lsize>0 then
  begin
    GetMem(ltmp,lsize);
    Seek(f,ainfo.man);
    BlockRead(f,ltmp^,lsize);
    ParseManifest(ainfo,ltmp);
    FreeMem(ltmp);
  end;

  // don't check packed/unpacked sizes or .MAN file processed
  if (aparse=piParse) or (ainfo.fsize=0) then
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
    Close(f);
  end
  else
  begin
    Close(f);
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
            lfhdr.size_u:=0;
            lfhdr.size_c:=0;
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
  
//  Close(f);
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

  for i:=0 to High(ainfo.Deleted) do
  begin
    FreeMem(ainfo.Deleted[i].name);
    for j:=0 to High(ainfo.Deleted[i].Files) do
    begin
      FreeMem(ainfo.Deleted[i].Files[j].name);
    end;
    SetLength(ainfo.Deleted[i].Files,0);
  end;
  SetLength(ainfo.Deleted,0);

  ClearModInfo(ainfo.modinfo);

  ainfo.fname:='';
  FillChar(ainfo,SizeOf(ainfo),0);
  ainfo.ver:=verUnk;
end;


procedure DumpPAKInfo(const ainfo:TPAKInfo);
var
  ls:string;
  i,j:integer;
  lpack,lfiles,lprocess,ldir:integer;
  ldat,llay:integer;
  lmaxp,lmaxu,lcnt:integer;
begin
  writeln('Root: ',String(WideString(ainfo.Root)));
  lfiles:=0;
  lprocess:=0;
  ldir:=0;
  lpack:=0;
  llay:=0;
  ldat:=0;
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
        if (ftype=typeDirectory) or (ftype=typeDelete) then
        begin
          inc(ldir);
          ls:='    Dir: ';
        end
        else
        begin
          inc(lfiles);
          ls:='    File: ';
          if size_s=0 then write('##');
        end;
        if size_c>0 then inc(lpack);
        if lmaxp<size_c then lmaxp:=size_c;
        if lmaxu<size_u then lmaxu:=size_u;
        if ftype in [typeWDat,typeDat,typeLayout,typeHie,typeAnimation] then inc(lprocess);
        if ftype=typedat then inc(ldat);
        if ftype=typelayout then inc(llay);

        if size_s<>size_u then write('!!');
        writeln(ls,string(widestring(name)),'; type:',PAKTypeToCategoryText(2,ftype),'; source size:',size_s,
        '; compr:',size_c,'; unpacked:',size_u);
      end;
    end;
  end;
  writeln('Total: '    ,ainfo.total,
          '; childs: ' ,Length(ainfo.Entries),
          '; rest: '   ,lcnt,
          '; process: ',lprocess);
  writeln('Max packed size: '  ,lmaxp,' (0x'+HexStr(lmaxp,8),')'#13#10,
          'Max unpacked size: ',lmaxu,' (0x'+HexStr(lmaxu,8),')'#13#10,
          'Packed '            ,lpack);
  writeln('Files ',lfiles,#13#10'Dirs ',ldir,#13#10'Total ',lfiles+ldir+lprocess);
  writeln('DAT: ',ldat,'; LAYOUT: ',llay);
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

  lname:=UpCase(fname);
  lpath:=ExtractFilePath(lname);
  lname:=ExtractFileName(lname);
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

//----- Unpack -----

{
  ZLIB uncompress file
  returns unpacked data (must be fried by FreeMem)
}
function Unpack(aptr:PByte; aunpacked:pointer):integer;
var
  strm:TZStream;
  usize,csize:dword;
begin
  result:=0;

  usize:=memReadDWord(aptr);
  csize:=memReadDWord(aptr);

  if csize>0 then
  begin
  	strm.avail_in:=0;
  	strm.next_in :=Z_NULL;
  	if inflateInit(strm)<>Z_OK then exit(0);
  end;

  GetMem(aunpacked,usize);

  if csize>0 then
  begin
  	strm.avail_in :=csize;
  	strm.next_in  :=aptr;
  	strm.avail_out:=usize;
  	strm.next_out :=aunpacked;

  	if inflate(strm, Z_FINISH)<>Z_OK then
  	begin
  	  FreeMem(aunpacked);
  	  aunpacked:=nil;
  	end;

  	inflateEnd(strm);
  end
  else
    memReadData(aptr,aunpacked^,usize);

  if aunpacked<>nil then
    result:=usize;
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
  lres:integer;
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

  lres:=0;
  for i:=0 to High(lpi^.Entries) do
  begin
    //!! dir filter here
    if OnPAKProgress<>nil then
    begin
      lres:=OnPAKProgress(lpi^,i,-1);
      if lres<>0 then break;
    end;

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
          if OnPAKProgress<>nil then
          begin
            lres:=OnPAKProgress(lpi^,i,j);
            if lres<>0 then break;
          end;

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
        end
        //!! size/offset = 0 means "delete file"
        else
        begin
          if OnPAKProgress<>nil then
          begin
            lres:=OnPAKProgress(lpi^,-i,-j);
            if lres<>0 then break;
          end;

          //!! if type = 'delete dir' then remove dir
        end;
      end;

    end;
    if lres<>0 then break;
  end;
  if lout<>nil then FreeMem(lout);
  if lin <>nil then FreeMem(lin);

  if lst<>nil then lst.Free
  else FreeMem(buf);

  result:=true;
end;
{$POP}

//----- Pack -----

{$PUSH}
{$I-}
procedure PackAll(var aPak:TPAKInfo; const aname:string; aver:integer);
var
  f,fpak,fman:file of byte;
  i,j:integer;
begin
  for i:=0 to High(aPak.Entries) do
  begin
    for j:=0 to High(aPak.Entries[i].Files) do
    begin
    end;
  end;

end;
{$POP}


function ConsoleProgress(const ainfo:TPAKInfo; adir,afile:integer):integer;
begin
  result:=0;
  if IsConsole then
  begin
    if afile>=0 then
    begin
    end;
  end;
end;


initialization
  OnPAKProgress:=@ConsoleProgress;
end.
