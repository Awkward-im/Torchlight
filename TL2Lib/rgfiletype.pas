{
  private type to common type
  common type to private type
  common type to category
  category to text
}
unit RGFileType;

interface

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

function PAKTypeRealToCommon(atype,aver:integer):integer;
function PAKTypeCommonToReal(atype,aver:integer):integer;
function PAKTypeToCategory  (atype:integer):integer;
function PAKCategoryName(acategory:integer):string;

type
  PPAKExtInfo = ^TPAKExtInfo;
  TPAKExtInfo = record
    _type    :byte;
    _pack    :bytebool;
    _compile :bytebool;
  end;

function GetExtInfo(const fname:string; aver:integer):PPAKExtInfo;

//========================================================

implementation

uses
  sysutils,
  rgglobal;

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
//  tl2Reserved2 = $0E;  //source .DAT
//  tl2Reserved3 = $0F;  //source .LAYOUT
  tl2Animation = $10; // .ANIMATION
  tl2HIE       = $11; // .HIE
  tl2Other     = $12; // ('Removed' Directory)
  tl2Scheme    = $13; // .SCHEME
  tl2LookNFeel = $14; // .LOOKNFEEL ??
  tl2MPP       = $15; // .MPP [.MPD]
//  tl2Reserved4 = $16;  //source .TEMPLATE
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
  PTableExt = ^TTableExt;
  TTableExt = array of TPAKExtInfo;
const
  TableTL2Info:TTableExt = (
    (_type:typeDat      ; _pack:true ; _compile:true ),
    (_type:typeLayout   ; _pack:true ; _compile:true ),
    (_type:typeMesh     ; _pack:true ; _compile:false),
    (_type:typeSkeleton ; _pack:true ; _compile:false),
    (_type:typeDDS      ; _pack:true ; _compile:false),
    (_type:typeImage    ; _pack:false; _compile:false),
    (_type:typeSound    ; _pack:true ; _compile:false),
    (_type:typeDirectory; _pack:false; _compile:false),
    (_type:typeMaterial ; _pack:true ; _compile:false),
    (_type:typeRAW      ; _pack:true ; _compile:true ),
    (_type:typeUnknown  ; _pack:true ; _compile:false),
    (_type:typeImageset ; _pack:true ; _compile:false),
    (_type:typeTTF      ; _pack:true ; _compile:false),
    (_type:typeFont     ; _pack:true ; _compile:false),
    (_type:typeUnknown  ; _pack:true ; _compile:false),
    (_type:typeUnknown  ; _pack:true ; _compile:false),
    (_type:typeAnimation; _pack:true ; _compile:true ),
    (_type:typeHIE      ; _pack:true ; _compile:true ),
    (_type:typeDelete   ; _pack:false; _compile:false),
    (_type:typeScheme   ; _pack:true ; _compile:false),
    (_type:typeLookNFeel; _pack:true ; _compile:false),
    (_type:typeMPP      ; _pack:true ; _compile:false),
    (_type:typeUnknown  ; _pack:true ; _compile:false),
    (_type:typeBIK      ; _pack:false; _compile:false),
    (_type:typeJPG      ; _pack:false; _compile:false)
  );
  
  TableHobInfo:TTableExt = (
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeMesh      ; _pack:true ; _compile:false),
    (_type:typeSkeleton  ; _pack:true ; _compile:false),
    (_type:typeDDS       ; _pack:true ; _compile:false),
    (_type:typeImage     ; _pack:true ; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeSound     ; _pack:false; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeDirectory ; _pack:false; _compile:false),
    (_type:typeMaterial  ; _pack:true ; _compile:false),
    (_type:typeRAW       ; _pack:true ; _compile:true ),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeImageset  ; _pack:true ; _compile:true ),
    (_type:typeTTF       ; _pack:true ; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeDAT       ; _pack:true ; _compile:true ),
    (_type:typeLayout    ; _pack:true ; _compile:true ),
    (_type:typeAnimation ; _pack:true ; _compile:true ),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typeProgram   ; _pack:true ; _compile:false),
    (_type:typeFont      ; _pack:true ; _compile:false),
    (_type:typeCompositor; _pack:true ; _compile:false),
    (_type:typeShader    ; _pack:true ; _compile:false),
    (_type:typeUnknown   ; _pack:true ; _compile:false),
    (_type:typePU        ; _pack:true ; _compile:false),
    (_type:typeAnno      ; _pack:true ; _compile:false),
    (_type:typeSBIN      ; _pack:true ; _compile:false),
    (_type:typeWDAT      ; _pack:true ; _compile:true )
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


function GetExtInfo(const fname:string; aver:integer):PPAKExtInfo;
var
  lext:string;
  lptr:PTableExt;
  i,j:integer;
begin
  if fname[Length(fname)]='/' then exit(nil);

  lext:=UpCase(ExtractFileExt(fname));

  if lext='.TXT' then
  begin
    // RAW.TXT
    // IMAGESET.TXT
    // DAT.TXT
    // LAYOUT.TXT
    // ANIMATION.TXT
    // HIE.TXT
    // WDAT.TXT
    lext:=UpCase(ExtractFileExt(Copy(fname,1,Length(fname)-4)));
  end;

  if lext='' then exit(nil);

  for i:=0 to High(TableExt) do
    if lext=TableExt[i]._ext then
    begin
      if ABS(aver)=verTL2 then
        lptr:=@TableTL2Info
      else
        lptr:=@TableHobInfo;

      for j:=0 to High(lptr^) do
        if TableExt[i]._type=lptr^[j]._type then
          exit(@lptr^[j]);
    end;

  result:=nil;
end;


function PAKCategoryName(acategory:integer):string;
begin
  if (acategory>=Low(CategoryList)) and (acategory<Length(CategoryList)) then
    result:=CategoryList[acategory]
  else
    result:=CategoryList[catUnknown];
end;

function PAKTypeToCategory(atype:integer):integer;
begin
  if (atype>=Low(TableIntInfo)) and (atype<Length(TableIntInfo)) then
    result:=TableIntInfo[atype]._category
  else
    result:=catUnknown;
end;

function PAKTypeRealToCommon(atype,aver:integer):integer;
var
  lt:TTableExt;
begin
  case aver of
    verTL2Mod,
    verTL2: lt:=TableTL2Info;
    verHob,
    verRGO,
    verRG : lt:=TableHobInfo;
  else
    exit(atype);
  end;
  if (atype>=Low(lt)) and (atype<Length(lt)) then
    result:=lt[atype]._type
  else
    result:=atype;
end;

function PAKTypeCommonToReal(atype,aver:integer):integer;
begin
  if (atype>=Low(TableIntInfo)) and (atype<Length(TableIntInfo)) then
  begin
    case aver of
      verTL2Mod,
      verTL2: result:=TableIntInfo[atype]._tl2;
      verHob,
      verRGO,
      verRG : result:=TableIntInfo[atype]._hob;
    else
      result:=atype;
    end;
  end
  else
    result:=atype;
end;

end.
