{
  private type to common type (ver)
  common type to private type (ver)
  common type to category
  category to text
}
unit RGFileType;

interface

const
  typeUnknown    = $0000; // all unknown files
  typeData       = $0001; // non-visual text data
  typeLayout     = $0101; //   special, TL1 UI Layouts are UI type
  typeRaw        = $0201; //   special
  typeImageSet   = $0301; //   special. format: migrate between Data (TL1,TL2) and UI (Hob,RGO)
  typeUI         = $0401; //   special
  typeModel      = $0002; // 3d-related
  typeImage      = $0003; // graphic
  typeMovie      = $0103; //   special
  typeSound      = $0004;
  typeFont       = $0005;
  typeFX         = $0006; // fx/particle related
  typeDirectory  = $0007;
  typeOther      = $0008;

  typeLast       = 8;

// get category from PAK type
function RGTypeOfType(atype:integer; aver:integer):integer;
// get category from extension
function RGTypeOfExt(const aext:string):integer;
function RGTypeOfExt(const aext:PUnicodeChar):integer;
// get PAK type from filename
function PAKTypeOfName(const fname:PWideChar; aver:integer):integer;

type
  PPAKExtInfo = ^TPAKExtInfo;
  TPAKExtInfo = record
    _type    :word;
    _pack    :bytebool;
    _compile :bytebool;
  end;
// get info about packing and compilation by extension
function RGTypeExtInfo(const fname:string   ; aver:integer):PPAKExtInfo;
function RGTypeExtInfo(const fname:PWideChar; aver:integer):PPAKExtInfo;
function RGTypeExtIsText(const aext:string):boolean;

function RGTypeExtCount:integer;
function RGTypeExtFromList(idx:integer):string;
function RGTypeFromList   (idx:integer):integer;

function RGTypeGroup(atype:integer):integer;
function RGTypeGroupName(atype:integer):string; inline;

//========================================================

implementation

uses
  rgglobal;


//--- TL2 File Types
const
  tl2Dat         = $00; // .DAT .TEMPLATE
  tl2Layout      = $01; // .LAYOUT
  tl2Mesh        = $02; // .MESH
  tl2Skeleton    = $03; // .SKELETON
  tl2DDS         = $04; // .DDS
  tl2PNG         = $05; // .PNG
  tl2Sound       = $06; // .WAV .OGG
  tl2Directory   = $07;
  tl2Material    = $08; // .MATERIAL
  tl2Raw         = $09; // .RAW
  tl2UILayout    = $0A; // .UILAYOUT
  tl2ImageSet    = $0B; // .IMAGESET
  tl2TTF         = $0C; // .TTF .TTC
  tl2Font        = $0D; // .FONT
  tl2SrcDat      = $0E; // source .DAT
  tl2SrcLayout   = $0F; // source .LAYOUT
  tl2Animation   = $10; // .ANIMATION (what about source?)
  tl2Hie         = $11; // .HIE       (what about source?)
  tl2Unknown     = $12; // ('Removed' Directory)
  tl2Scheme      = $13; // .SCHEME
  tl2LookNFeel   = $14; // .LOOKNFEEL ??
  tl2MPP         = $15; // .MPP [.MPD]
  tl2SrcTemplate = $16; // source .TEMPLATE
  tl2BIK         = $17; // .BIK
  tl2JPG         = $18; // .JPG

  tl2Last         = $18;

//--- Hob File Types
const                  // hob flags: 1 - Add to pak?; 2 - binary reader?compile?; 3 - pack?
  hobText       = $00; //  0 111(TEXT)              .TXT
  hobModel      = $01; //  1 111(MESH)              .MDL .MESH
  hobSkeleton   = $02; //  2 111(SKELETON)          .SKELETON
  hobDDS        = $03; //  3 111(TEXTURE)           .DDS .GNF (RGO) .XTX (RGO)
  hobImage      = $04; //  4 111(TEXTURE)           .BMP .PNG .TGA .JPG (RGO)
  hobPicture    = $05; //  5 100(TEXTURE)           .JPG (HOB)
  hobSound      = $06; //  6 111(SOUND)             .OGG .WAV
  hobMusic      = $07; //  7 000(MUSIC)             .MP3
  hobDirectory  = $08; //  8 111(DIRECTORY)
  hobMaterial   = $09; //  9 111(MATERIAL)          .MATERIAL
  hobRaw        = $0A; // 10 111(RAW)               .RAW
  hobUILayout   = $0B; // 11 111(UI LAYOUT)         .UILAYOUT
  hobImageset   = $0C; // 12 111(UI IMAGESET)       .IMAGESET
  hobTTF        = $0D; // 13 111(FONT)              .TTF .TTC .OTF (RGO)
  hobFONT       = $0E; // 14 111(FONT DEF)          .FONT
  hobDat        = $0F; // 15 111(DAT)               .DAT
  hobLayout     = $10; // 16 111(LAYOUT)            .LAYOUT
  hobAnimation  = $11; // 17 111(ANIMATION)         .ANIMATION
  hobHie        = $12; // 18 111(HIERARCHY)         .HIE
  hobUnknown    = $13; // 19 100(UNKNOWN)           unknown/no ext?
  hobScheme     = $14; // 20 111(UI SCHEME)         .SCHEME
  hobLookNFeel  = $15; // 21 111(UI LOOKNFEEL)      .LOOKNFEEL
  hobMPP        = $16; // 22 111(PATH MAP)          .MPP
  hobTemplate   = $17; // 23 111(TEMPLATE)          .TEMPLATE
  hobProgram    = $18; // 24 111(PROGRAM)           .PROGRAM
  hobFontDef    = $19; // 25 111(FONDDEF)           .FONTDEF
  hobCompositor = $1A; // 26 111(COMPOSITOR)        .COMPOSITOR
  hobShader     = $1B; // 27 110(FX)                .FX .HLSL .FRAG .VERT .GLSLC
  hobBIK        = $1C; // 28 000(MOVIE)             .BIK
  hobPU         = $1D; // 29 111(PARTICLE UNIVERSE) .PU .PUA
  hobAnno       = $1E; // 30 111(LIP SYNC)          .ANNO
  hobSBIN       = $1F; // 31 101(SB)                .SB (HOB) .SBIN (RGO)
  //.sbin (31) is actually compiled from .pu (29), .material (9) and .compositor (26)
  hobHeightBin  = $20; // 32 111(HEIGHT BIN)        .HEIGHTBIN (HOB)
  hobWDat       = $20; //                           .WDAT (RGO)
  // Hob only
  hobCol        = $21; // 33 111(COLLISION)         .COL
  HobRedirect   = $22; // 34 111(REDIRECT)
  hobBank       = $23; // 35 111(FMOD BANK)         .BANK
  hobCache      = $24; // 36 000(CACHE)             .CACHE

  hobLast        = $24;

//    (_type:typeData    ; _tl2:tl2Unknown  ; _hob:hobUnknown   ; _ext:'.ADM'),        // TL1 binary DAT/Layout
//    (_type:typeLayout  ; _tl2:tl2Unknown  ; _hob:hobUnknown   ; _ext:'.CMP'),        // TL1 binary LAYOUT

{TODO: ?? put all exts into one string, separated by #0 and add field with offset}
{TODO: add field for category}
const
  TableExt: array of record
     _ext : string;
     _type: word;
     _tl2 : byte;
     _hob : byte;
  end = (
    (_ext:'.DAT'       ; _type:typeData    ; _tl2:tl2Dat      ; _hob:hobDat       ),
    (_ext:'.TEMPLATE'  ; _type:typeData    ; _tl2:tl2Dat      ; _hob:hobTemplate  ),
    (_ext:'.ANIMATION' ; _type:typeData    ; _tl2:tl2Animation; _hob:hobAnimation ),
    (_ext:'.HIE'       ; _type:typeData    ; _tl2:tl2Hie      ; _hob:hobHie       ),
    (_ext:'.WDAT'      ; _type:typeData    ; _tl2:tl2Unknown  ; _hob:hobWDat      ),

    // TL1 "UI" directory - XML format (typeUI = UILayout) 
    (_ext:'.LAYOUT'    ; _type:typeLayout  ; _tl2:tl2Layout   ; _hob:hobLayout    ),

    // TL1, TL2 - XML; Hob, RG and RG - DAT file format
    (_ext:'.IMAGESET'  ; _type:typeImageSet; _tl2:tl2Imageset ; _hob:hobImageset  ),
                                           
    (_ext:'.RAW'       ; _type:typeRaw     ; _tl2:tl2Raw      ; _hob:hobRaw       ),
                                                                                  
    (_ext:'.UILAYOUT'  ; _type:typeUI      ; _tl2:tl2UILayout ; _hob:hobUILayout  ),
    (_ext:'.SCHEME'    ; _type:typeUI      ; _tl2:tl2Scheme   ; _hob:hobScheme    ),
    (_ext:'.LOOKNFEEL' ; _type:typeUI      ; _tl2:tl2LookNFeel; _hob:hobLookNFeel ),
                                                                                  
    (_ext:'.MESH'      ; _type:typeModel   ; _tl2:tl2Mesh     ; _hob:hobModel     ),
    (_ext:'.MDL'       ; _type:typeModel   ; _tl2:tl2Unknown  ; _hob:hobModel     ),
    (_ext:'.SKELETON'  ; _type:typeModel   ; _tl2:tl2Skeleton ; _hob:hobSkeleton  ),
                                                                                  
    (_ext:'.DDS'       ; _type:typeImage   ; _tl2:tl2DDS      ; _hob:hobDDS       ),
    (_ext:'.PNG'       ; _type:typeImage   ; _tl2:tl2PNG      ; _hob:hobImage     ),
    (_ext:'.JPG'       ; _type:typeImage   ; _tl2:tl2JPG      ; _hob:hobPicture   ),  // hobImage for RGO
    (_ext:'.TGA'       ; _type:typeImage   ; _tl2:tl2Unknown  ; _hob:hobImage     ),
    (_ext:'.BMP'       ; _type:typeImage   ; _tl2:tl2Unknown  ; _hob:hobImage     ),
    (_ext:'.GNF'       ; _type:typeImage   ; _tl2:tl2Unknown  ; _hob:hobDDS       ),  // RGO only
    (_ext:'.XTX'       ; _type:typeImage   ; _tl2:tl2Unknown  ; _hob:hobDDS       ),  // RGO only
                                                                                  
    (_ext:'.BIK'       ; _type:typeMovie   ; _tl2:tl2BIK      ; _hob:hobBIK       ),
                                                                                  
    (_ext:'.WAV'       ; _type:typeSound   ; _tl2:tl2Sound    ; _hob:hobSound     ),
    (_ext:'.OGG'       ; _type:typeSound   ; _tl2:tl2Sound    ; _hob:hobSound     ),
    (_ext:'.MP3'       ; _type:typeSound   ; _tl2:tl2Unknown  ; _hob:hobMusic     ),
    (_ext:'.BANK'      ; _type:typeSound   ; _tl2:tl2Unknown  ; _hob:hobBank      ),  // Hob only
                                                                                  
    (_ext:'.TTF'       ; _type:typeFont    ; _tl2:tl2TTF      ; _hob:hobTTF       ),
    (_ext:'.TTC'       ; _type:typeFont    ; _tl2:tl2TTF      ; _hob:hobTTF       ),
    (_ext:'.OTF'       ; _type:typeFont    ; _tl2:tl2Unknown  ; _hob:hobTTF       ),  // RGO only
    (_ext:'.FONT'      ; _type:typeFont    ; _tl2:tl2Font     ; _hob:hobFont      ),  // Text
    (_ext:'.FONTDEF'   ; _type:typeFont    ; _tl2:tl2Unknown  ; _hob:hobFontDef   ),  // Text
                                                                                  
    (_ext:'.MATERIAL'  ; _type:typeFX      ; _tl2:tl2Material ; _hob:hobMaterial  ),
    (_ext:'.PROGRAM'   ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobProgram   ),
    (_ext:'.COMPOSITOR'; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobCompositor),
    (_ext:'.PU'        ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobPU        ),
    (_ext:'.FX'        ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobShader    ),
    (_ext:'.HLSL'      ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobShader    ),
    (_ext:'.FRAG'      ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobShader    ),
    (_ext:'.VERT'      ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobShader    ),
    (_ext:'.GLSLC'     ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobShader    ),
    // Binary form of PU, Compositor and Material
    (_ext:'.SBIN'      ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobSBIN      ),
    (_ext:'.SB'        ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobSBIN      ),  // Hob only
    (_ext:'.PUA'       ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobPU        ),
    (_ext:'.TXT'       ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobText      ),  // Text
    (_ext:'.ANNO'      ; _type:typeFX      ; _tl2:tl2Unknown  ; _hob:hobAnno      ),  // Text
                                                                                  
    (_ext:'.MPP'       ; _type:typeOther   ; _tl2:tl2MPP      ; _hob:hobMPP       ),
    (_ext:'.MPD'       ; _type:typeOther   ; _tl2:tl2MPP      ; _hob:hobUnknown   ), 
    (_ext:'.HEIGHTBIN' ; _type:typeOther   ; _tl2:tl2Unknown  ; _hob:hobHeightBin ),
    (_ext:'.COL'       ; _type:typeOther   ; _tl2:tl2Unknown  ; _hob:hobCol       ),  // Hob only
    (_ext:'.CACHE'     ; _type:typeOther   ; _tl2:tl2Unknown  ; _hob:hobCache     )   // Hob only

//    (_type:typeDirectory ; _ext:'<DIR>')
  );

type
  PTableExt = ^TTableExt;
  TTableExt = array of TPAKExtInfo;
const
  TableTL2Info:TTableExt = (
    (_type:typeData       ; _pack:true ; _compile:true ),  // tl2Dat        
    (_type:typeLayout     ; _pack:true ; _compile:true ),  // tl2Layout     
    (_type:typeModel      ; _pack:true ; _compile:false),  // tl2Mesh       
    (_type:typeModel      ; _pack:true ; _compile:false),  // tl2Skeleton   
    (_type:typeImage      ; _pack:true ; _compile:false),  // tl2DDS        
    (_type:typeImage      ; _pack:false; _compile:false),  // tl2PNG        
    (_type:typeSound      ; _pack:true ; _compile:false),  // tl2Sound      
    (_type:typeDirectory  ; _pack:false; _compile:false),  // tl2Directory  
    (_type:typeFX         ; _pack:true ; _compile:false),  // tl2Material   
    (_type:typeRAW        ; _pack:true ; _compile:true ),  // tl2Raw        
    (_type:typeUI         ; _pack:true ; _compile:false),  // tl2UILayout   
    (_type:typeImageset   ; _pack:true ; _compile:false),  // tl2ImageSet   
    (_type:typeFont       ; _pack:true ; _compile:false),  // tl2TTF        
    (_type:typeFont       ; _pack:true ; _compile:false),  // tl2Font       
    (_type:typeUnknown    ; _pack:true ; _compile:false),  // tl2SrcDat     
    (_type:typeUnknown    ; _pack:true ; _compile:false),  // tl2SrcLayout  
    (_type:typeData       ; _pack:true ; _compile:true ),  // tl2Animation  
    (_type:typeData       ; _pack:true ; _compile:true ),  // tl2Hie        
    (_type:typeUnknown    ; _pack:false; _compile:false),  // tl2Other      
    (_type:typeUI         ; _pack:true ; _compile:false),  // tl2Scheme     
    (_type:typeUI         ; _pack:true ; _compile:false),  // tl2LookNFeel  
    (_type:typeOther      ; _pack:true ; _compile:false),  // tl2MPP        
    (_type:typeUnknown    ; _pack:true ; _compile:false),  // tl2SrcTemplate
    (_type:typeMovie      ; _pack:false; _compile:false),  // tl2BIK        
    (_type:typeImage      ; _pack:false; _compile:false)   // tl2JPG        
  );
  
  TableHobInfo:TTableExt = (
    (_type:typeOther       ; _pack:true ; _compile:false),  // hobText
    (_type:typeModel       ; _pack:true ; _compile:false),  // hobModel
    (_type:typeModel       ; _pack:true ; _compile:false),  // hobSkeleton
    (_type:typeImage       ; _pack:true ; _compile:false),  // hobDDS
    (_type:typeImage       ; _pack:true ; _compile:false),  // hobImage
    (_type:typeImage       ; _pack:true ; _compile:false),  // hobPicture
    (_type:typeSound       ; _pack:false; _compile:false),  // hobSound
    (_type:typeSound       ; _pack:false; _compile:false),  // hobMusic
    (_type:typeDirectory   ; _pack:false; _compile:false),  // hobDirectory
    (_type:typeFX          ; _pack:true ; _compile:false),  // hobMaterial
    (_type:typeRAW         ; _pack:true ; _compile:true ),  // hobRaw
    (_type:typeUI          ; _pack:true ; _compile:false),  // hobUILayout
    (_type:typeImageset    ; _pack:true ; _compile:true ),  // hobImageset
    (_type:typeFont        ; _pack:true ; _compile:false),  // hobTTF
    (_type:typeFont        ; _pack:true ; _compile:false),  // hobFONT
    (_type:typeData        ; _pack:true ; _compile:true ),  // hobDat
    (_type:typeLayout      ; _pack:true ; _compile:true ),  // hobLayout
    (_type:typeData        ; _pack:true ; _compile:true ),  // hobAnimation
    (_type:typeData        ; _pack:true ; _compile:true ),  // hobHie
    (_type:typeUnknown     ; _pack:true ; _compile:false),  // hobUnknown
    (_type:typeUI          ; _pack:true ; _compile:false),  // hobScheme
    (_type:typeUI          ; _pack:true ; _compile:false),  // hobLookNFeel
    (_type:typeOther       ; _pack:true ; _compile:false),  // hobMPP
    (_type:typeData        ; _pack:true ; _compile:true ),  // hobTemplate
    (_type:typeFX          ; _pack:true ; _compile:false),  // hobProgram
    (_type:typeFont        ; _pack:true ; _compile:false),  // hobFontDef
    (_type:typeFX          ; _pack:true ; _compile:false),  // hobCompositor
    (_type:typeFX          ; _pack:true ; _compile:false),  // hobShader
    (_type:typeMovie       ; _pack:false; _compile:false),  // hobBIK
    (_type:typeFX          ; _pack:true ; _compile:false),  // hobPU
    (_type:typeOther       ; _pack:true ; _compile:false),  // hobAnno
    (_type:typeFX          ; _pack:true ; _compile:false),  // hobSBin
    (_type:typeOther       ; _pack:true ; _compile:false),  // hobHeightBin
    (_type:typeOther       ; _pack:true ; _compile:false)   // hobCol
  );

function RGTypeExtIsText(const aext:string):boolean;
var
  lext:string;
begin
  result:=false;
  lext:=UpCase(aext);
  case RGTypeOfExt(aext) of
    typeUI   : result:=true;
    typeFX   : if (lext<>'.SB'  ) and (lext<>'.SBIN'   ) then result:=true;
    typeOther: if (lext ='.TXT' ) or  (lext ='.ANNO'   ) then result:=true;
    typeFont : if (lext ='.FONT') or  (lext ='.FONTDEF') then result:=true;
  end;
end;

function RGTypeExtCount:integer; inline;
begin
  result:=Length(TableExt);
end;

function RGTypeExtFromList(idx:integer):string;
begin
  if (idx>=0) and (idx<Length(TableExt)) then
    result:=TableExt[idx]._ext
  else
    result:='';
end;

function RGTypeFromList(idx:integer):integer;
begin
  if (idx>=0) and (idx<Length(TableExt)) then
    result:=TableExt[idx]._type
  else
    result:=typeUnknown;
end;

function RGTypeOfType(atype:integer; aver:integer):integer;
var
  lt:PTableExt;
begin
  case ABS(aver) of
    verTL2: lt:=@TableTL2Info;
    verHob,
    verRGO,
    verRG : lt:=@TableHobInfo; 
  else
    exit(typeUnknown);
  end;

  if (atype>=Low(lt^)) and (atype<Length(lt^)) then
  begin
    //!! same code for WDAT (RGO) and HEIGHTBIN (Hob)
    if (atype=hobWDat) then
    begin
      if (aver=verHob) then
        result:=typeOther  // default
      else // RG, RGO
        result:=typeData;
    end
    else
      result:=lt^[atype]._type
  end
  else
    result:=typeUnknown;
end;

function RGTypeOfExt(const aext:string):integer;
var
  lext:string;
  i:integer;
begin
  if aext<>'' then
  begin
    if aext[Length(aext)] in ['\','/'] then
      exit(typeDirectory);

    lext:=FixFileExt(aext);

    if (lext[1]<>'.') or (lext[2] in ['.','/','\']) then
      lext:=ExtractExt(lext);

    lext:=UpCase(lext);

    for i:=0 to High(TableExt) do
    begin
      if TableExt[i]._ext=lext then
        exit(TableExt[i]._type);
    end;
  end;

  result:=typeUnknown;
end;

function RGTypeOfExt(const aext:PUnicodeChar):integer;
begin
  if (aext<>nil) and (aext[0]<>#0) then
    result:=RGTypeOfExt(FastWideToStr(aext))
  else
    result:=typeUnknown;
end;

function PAKTypeOfName(const fname:PWideChar; aver:integer):integer;
var
  lext:string;
  i:integer;
begin
  if ABS(aver)=verTL2 then
    result:=tl2Unknown
  else
    result:=hobUnknown;

  i:=Length(fname);
  if i=0 then exit;

  if fname[i-1]='/' then
  begin
    if ABS(aver)=verTL2 then exit(tl2Directory) else exit(hobDirectory);
  end;

  lext:=ExtractExt(FastWideToStr(fname));

  if lext<>'' then
    for i:=0 to High(TableExt) do
      if lext=TableExt[i]._ext then
      begin
        if ABS(aver)=verTL2 then
          exit(TableExt[i]._tl2)
        else
        begin
          //!! cheat: Hob saves JPG as hobPicture, RGO saves as hobImage
          if (lext='.JPG') then
          begin
            if aver=verHob then
              exit(hobPicture) // default
            else
              exit(hobImage);
          end
          else
            exit(TableExt[i]._hob)
        end;
      end;

end;

function RGTypeExtInfo(const fname:string; aver:integer):PPAKExtInfo;
var
  lext:string;
  i:integer;
  wastxt:boolean;
begin
  if (fname='') or (fname[Length(fname)]='/') then exit(nil);

  lext:=ExtractExt(fname); // upcased into extraction
  wastxt:=(lext='.TXT');

  if (lext='.ADM') or
     (lext='.CMP') or
     (lext='.BINDAT') or
     (lext='.BINLAYOUT') or
     wastxt then
  begin
    lext:=ExtractExt(Copy(fname,1,Length(fname)-4));
  end;

  if (lext='') then
  begin
    if not wastxt then exit(nil);
    lext:='.TXT';
  end;

  for i:=0 to High(TableExt) do
    if lext=TableExt[i]._ext then
    begin
      if ABS(aver)=verTL2 then
        exit(@(TableTL2Info[TableExt[i]._tl2]))
      else
        exit(@(TableHobInfo[TableExt[i]._hob]))
    end;

  result:=nil;
end;

function RGTypeExtInfo(const fname:PWideChar; aver:integer):PPAKExtInfo;
begin
  result:=RGTypeExtInfo(FastWideToStr(fname),aver);
end;


const
  catFolder  = $00;
  catData    = $01;
  catModel   = $02;
  catImage   = $03;
  catSound   = $04;
  catShaders = $05;
  catFont    = $06;
  catOther   = $07;
  catUnknown = $08;

const
  CategoryList:array [0..8] of string = (
    'Directory',
    'Data',
    'Model',
    'Image',
    'Sound',
    'Shaders',
    'Font',
    'Other',
    'Unknown'
  );

function RGTypeGroup(atype:integer):integer;
begin
  case (atype and $FF) of
    typeDirectory: result:=catFolder;
    typeData     : result:=catData;
    typeModel    : result:=catModel;
    typeImage    : result:=catImage;
    typeSound    : result:=catSound;
    typeFX       : result:=catShaders;
    typeFont     : result:=catFont;
    typeOther    : result:=catOther;
  else
    result:=catUnknown;
  end;
end;

function RGTypeGroupName(atype:integer):string; inline;
begin
  result:=CategoryList[RGTypeGroup(atype)];
end;

end.
