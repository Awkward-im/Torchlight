{TODO: calc stDelete. if exists, rebuild Templates, save them 1st, then idxs?}
{TODO: save translation language in info}
{TODO: DeleteString (mark for delete). Delete Refs or not?}
{TODO: ReadSrc, not StringList use but manual CRLF scan and "Copy" to string?}
{TODO: "Changed" flag (when to clear)}
{TODO: implement import from/export to file and text (as clipboard)}
{TODO: save templates by option}
{TODO: Search/Replace text}
{TODO: implement SOUNDEX or METAPHONE for wrong letters}
{TODO: statistic on changing: total, translated, partially}
unit TL2DataUnit;

interface

uses
  Classes,
  TL2Text,
  TL2RefUnit;

// filters
type
  tSearchFilter = (
    flNoSearch,  // do not search for doubles
    flNoFilter,  // search 100% the same only
    flFiltered); // search the same and similar
  tTextMode     = (
    tmOriginal,  // process: Load/save project
    tmDefault,   // process: load default file / save all
    tmMod);      // Process: loading mods
  tTextStatus   = (
    stOriginal,  // not translated
    stPartial,   // translated partially
    stReady,     // translated
    stDeleted);  // prepared to delete (don't save)
  tUpdatePart   = (
    upKeepOld,   // keep old partial translation if new is partial too
    upUpdate,    // update partial translation by new in any case
    upCombine    // keep old and new partial translations
  );

type
  PDATString = ^TDATString;
  TDATString = record
    origin: AnsiString;
    transl: AnsiString;
    tmpl  : integer;      // index in template list
    state : tTextStatus;
  end;

type
{
  0 - OK
  1 - skip this file
  2 - abort
}
  TOnFileScan = function (const fname:AnsiString; idx, atotal:integer):integer of object;

  TOnLineChanged = procedure (aline:integer) of object;

type
  PTL2Translation = ^TTL2Translation;

  { TTL2Translation }

  TTL2Translation = object
  private
    FErrFile: AnsiString;
    FErrText: AnsiString;
    FErrLine: integer;
    FErrCode: integer;

    FRefs: TTL2Reference;
    
    cntText : integer;              // lines totally
    cntTmpl : integer;              // max Template index
    arText  : array of TDATString;
    arTmpl  : array of AnsiString;  // Templates list
    FRefilter:boolean;

    FFMode    : tTextMode;
    FFilter   : tSearchFilter;
    FUpdPart  : tUpdatePart;
    FPackInfo : boolean;

    // events
    FOnFileScan   : TOnFileScan;    // File info while scanning
    FOnFileBuild  : TOnFileScan;    // File info while builds
    FOnLineAdd    : TOnLineChanged; // Line count on add
    FOnLineChanged: TOnLineChanged; // Line number (not count) when changed
    FOnProgress   : TOnLineChanged; // Line count total (negative value)/processing

    FOnFilterChange:TOnFilterChange;

    // single mod info
    FModTitle  : AnsiString;
    FModAuthor : AnsiString;
    FModDescr  : AnsiString;
    FModURL    : AnsiString;
    FModID     : Int64;
    FModVersion: word;
    
    FScanIdx :integer;              // MOD scan counter
    FScanLine:integer;              // line number for reference (scan mod mode)

    function  GetStatus(idx:integer):tTextStatus;
    procedure SetStatus(idx:integer; astat:tTextStatus);

    procedure Error(acode:integer; const afname:AnsiString; aline:integer);
    {
      >0 =  (idx+1) (=current lines amount)
      <0 = -(idx+1) (found the same)
      =0 = not added (empty source)
      -----
      ?? = found in base
    }
    function AddStringOnImport(const aorig,atrans,atmpl:AnsiString; apart:boolean):integer;
    function AddStringOnLoad  (const aorig,atrans:AnsiString):integer;
    function AddStringOnScan  (const aorig:AnsiString):integer;

    procedure FilterChange  (const anewfilter:AnsiString);
    function  SearchTemplate(const atmpl:AnsiString):integer;
    function  AddTemplate   (const atmpl:AnsiString):integer;
    function  GetTemplate (idx:integer):AnsiString;
    function  GetSource   (idx:integer):AnsiString;
    procedure SetTrans    (idx:integer; const translated: AnsiString);
    function  GetTrans    (idx:integer):AnsiString;
    function  GetRef      (idx:integer):integer;
    function  GetRef      (idx:integer; num:integer):integer;
    function  GetRefCount (idx:integer):integer;
    function  GetSkillFlag(idx:integer):boolean;
    function  HaveSimilars(idx:integer):boolean;

    procedure ReadSrcFile(const fname: AnsiString; atype: integer; arootlen:integer);
    procedure CycleDir   (sl:TStringList; const adir:AnsiString; allText:boolean; withChild:boolean);
    function  ProcessNode(anode:pointer; const afile:string; atype:integer):integer;

    procedure SaveInfo(const fname:AnsiString);
    procedure LoadInfo(const fname:AnsiString);

  public
    FModList: array of AnsiString;

    procedure Init;
    procedure Free;

    {
      -1 no file starting tag
      -2 no block start
      -3 no original text
      -4 no translated text
      -5 no end of block
    }
    function  LoadFromFile(const fname:AnsiString):integer;
    procedure SaveToFile  (const fname:AnsiString; astat:tTextStatus=stPartial; askip:boolean=false);
    procedure Build       (const adir:string; const abase:string='');
    function  LoadFromTranslation(const src:TTL2Translation):integer;
    // import from translation project file
    function  ImportFromFile(const fname:AnsiString):integer;
    // import from formatted text: original #9(tab) translation
    function  ImportFromText(const atext:AnsiString):integer;
    // unrealized
    function  ExportToFile  (const fname:AnsiString):boolean;
    function  ExportToText  ():AnsiString;

    // s`can a dir, known or all unicode text files (not UTF8 atm), with or without subdirs
    function  Scan(const adir:AnsiString; allText:boolean; withChild:boolean):boolean;
    // scan mod/pak file
    function  Scan(const afile:AnsiString):boolean;

    procedure RebuildTemplate(idx:integer=-1);

    function  NextNoticed(acheckonly:boolean; var idx:integer):integer;

    // find lines w/o translation with idx-ed template and fill them
    function CheckTheSame(idx:integer; markAsPart:boolean):integer;
    // replaced partial lines with ready, empty with filled template
    function CheckLine(const asrc,atrans:AnsiString;
         const atmpl:AnsiString=''; astate:tTextStatus=stReady):integer;

    // events
    property OnFileScan   :TOnFileScan    read FOnFileScan    write FOnFileScan;
    property OnFileBuild  :TOnFileScan    read FOnFileBuild   write FOnFileBuild;
    property OnLineAdd    :TOnLineChanged read FOnLineAdd     write FOnLineAdd;
    property OnLineChanged:TOnLineChanged read FOnLineChanged write FOnLineChanged;
    property OnProgress   :TOnLineChanged read FOnProgress    write FOnProgress;

    // statistic
    property LineCount:integer read cntText;

    // errors
    property ErrorCode:integer    read FErrCode;
    property ErrorText:AnsiString read FErrText;
    property ErrorFile:AnsiString read FErrFile;
    property ErrorLine:integer    read FErrLine;

    // global
    property Mode      :tTextMode     read FFMode    write FFMode;
    property Filter    :tSearchFilter read FFilter   write FFilter;
    property UpdatePart:tUpdatePart   read FUpdPart  write FUpdPart;

    // mod info
    property ModTitle  :AnsiString read FModTitle;
    property ModAuthor :AnsiString read FModAuthor;
    property ModDescr  :AnsiString read FModDescr;
    property ModURL    :AnsiString read FModURL;
    property ModID     :Int64      read FModID;
    property ModVersion:word       read FModVersion;

    property Refs:TTL2Reference read FRefs;

    // Return index of "num"-th double of idx'ed line
    property Ref     [idx:integer; num:integer]:integer read GetRef;
    property RefCount[idx:integer]:integer     read GetRefCount;
    property IsSkill [idx:integer]:boolean     read GetSkillFlag;

    property Line    [idx:integer]:AnsiString  read GetSource;
    property Trans   [idx:integer]:AnsiString  read GetTrans  write SetTrans;
    property Template[idx:integer]:AnsiString  read GetTemplate;
    property State   [idx:integer]:tTextStatus read GetStatus write SetStatus;
    property Similars[idx:integer]:boolean     read HaveSimilars;
  end;

var
  BaseTranslation:TTL2Translation;


//============================================

implementation

uses
  SysUtils,

  rgdict,
  rgdictlayout,

  rgglobal,
  rgstream,
  rgnode,
  rgio.dat,
  rgio.layout,
  rgscan,
  rgmod;

{$R ..\TL2Lib\dict.rc}

resourcestring
  // Open file error codes
  sNoFileStart  = 'No file starting tag';
  sNoBlockStart = 'No block start';
  sNoOrignText  = 'No original text';
  sNoTransText  = 'No translated text';
  sNoEndBlock   = 'No end of block';

  sWrongLineAmount = 'Wrong line amount in text and info files';

  sBaseTranslation = 'Base translation';

const
  dwPrefix    = $4B574100;
  infoVersion = 1;
const
  cnstInfoExt = '.ref';

const
  KnownGoodExt: array of string = (
    '.DAT',
    '.LAYOUT',
    '.TEMPLATE',
    '.WDAT'
  );

  KnownBadExt: array of string = (
    '.BIN',
    '.BINDAT',
    '.BINLAYOUT',
    '.DDS',
    '.MPP',
    '.RAW',
    '.ANIMATION',
    '.MATERIAL',
    '.MESH',
    '.SKELETON',
    '.OGG',
    '.WAV',
    '.FONT',
    '.TTF',
    '.PNG',
    '.BAK',
    '.DLL',
    '.EXE'
  );

const
  // TRANSLATION.DAT
  sBeginFile   = '[TRANSLATIONS]';
  sEndFile     = '[/TRANSLATIONS]';
  sBeginBlock  = '[TRANSLATION]';
  sEndBlock    = '[/TRANSLATION]';
  sOriginal    = '<STRING>ORIGINAL:';
  sTranslated  = '<STRING>TRANSLATION:';
  sFile        = '<STRING>FILE:';
  sProperty    = '<STRING>PROPERTY:';
  // Translation
  sTranslate   = '<TRANSLATE>';
  sDescription = 'DESCRIPTION';
  // Layouts
  sString      = '<STRING>';
  sText_       = 'TEXT ';
  sDialog_     = 'DIALOG ';
  sText        = 'TEXT';
  sToolTip     = 'TOOL TIP';
  sTitle       = 'TITLE';
  sGreet       = 'GREET';
  sFailed      = 'FAILED';
  sReturn      = 'RETURN';
  sComplete    = 'COMPLETE';
  sComplRet    = 'COMPLETE RETURN';

const
  increment = 800;

//===== Support =====

function TTL2Translation.NextNoticed(acheckonly:boolean; var idx:integer):integer;
begin
  result:=0;

  inc(idx);
  if idx>=cntText then idx:=0;

  while idx<cntText do
  begin
    result:=CheckPunctuation(arText[idx].origin,arText[idx].transl,acheckonly);
    if (result<>0) and (acheckonly or ((result and cpfNeedToFix)<>0)) then
      exit;

    inc(idx);
  end;

  idx:=-1;
end;

procedure TTL2Translation.SetTrans(idx:integer; const translated: AnsiString);
begin
  if (idx>=0) and (idx<cntText) then
  begin
    arText[idx].transl:=translated;
    if translated<>'' then
      arText[idx].state:=stReady
    else
      arText[idx].state:=stOriginal;
  end;
end;

function TTL2Translation.GetTrans(idx:integer): AnsiString;
begin
  if (idx>=0) and (idx<cntText) then
  begin
    result:=arText[idx].transl;
  end
  else
    result:='';
end;

function TTL2Translation.GetSource(idx:integer): AnsiString;
begin
  if (idx>=0) and (idx<cntText) then
    result:=arText[idx].origin
  else
    result:='';
end;

procedure TTL2Translation.SetStatus(idx:integer; astat:tTextStatus);
begin
  if (idx>=0) and (idx<cntText) then
  begin
    arText[idx].state:=astat;
{
    if astat=stPartial then
      arText[idx].state:=stPartial
    else if arText[idx].transl<>'' then
      arText[idx].state:=stReady
    else
      arText[idx].state:=stOriginal;
}
  end;
end;

function TTL2Translation.GetStatus(idx:integer):tTextStatus;
begin
  if (idx>=0) and (idx<cntText) then
    result:=arText[idx].state
  else
    result:=stOriginal;
end;

function TTL2Translation.HaveSimilars(idx:integer):boolean;
var
  i,ltmpl:integer;
begin
  if (idx>=0) and (idx<cntText) then
  begin
    ltmpl:=arText[idx].tmpl;
    for i:=0 to cntText-1 do
    begin
      if (ltmpl=arText[i].tmpl) and (i<>idx) then
        exit(true);
    end;
  end;
  result:=false;
end;

function TTL2Translation.GetTemplate(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntText) then
    result:=arTmpl[arText[idx].tmpl]
  else
    result:='';
end;

//----- Referals -----

function TTL2Translation.GetRefCount(idx:integer):integer;
var
  lref:integer;
begin
  result:=0;
  if (idx>=0) and (idx<cntText) then
  begin
    lref:=Refs[idx];
    while lref>=0 do
    begin
      inc(result);
      lref:=FRefs.Dupe[lref];
    end;
  end;
end;

function TTL2Translation.GetRef(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntText) then
    result:=Refs[idx]
  else
    result:=-1;
end;
function TTL2Translation.GetRef(idx:integer; num:integer):integer;
var
  lref:integer;
begin
  result:=-1;
  if (idx>=0) and (idx<cntText) then
  begin
    lref:=Refs[idx];
    while lref>=0 do
    begin
      result:=lref;
      dec(num);
      if num<0 then break;
      lref:=FRefs.Dupe[lref];
    end;
  end
  else
    result:=-1;
end;
{
function TTL2Translation.SetRef(aline:integer; const arefs:TRefArray; idx:integer):integer;
begin
  while idx>=0 do
  begin
    AddDouble(arText[aline],AddRef(arefs,idx));
    idx:=arefs[idx]._dupe;
  end;
end;
}
function TTL2Translation.GetSkillFlag(idx:integer):boolean;
var
  lref:integer;
begin
  if (idx>=0) and (idx<cntText) then
  begin
    lref:=Refs[idx];
    repeat
      if Refs.IsSkill[lref] then exit(true);
      lref:=FRefs.Dupe[lref];
    until lref=0;
  end;
  result:=false;
end;

procedure TTL2Translation.FilterChange(const anewfilter:AnsiString);
begin
  RebuildTemplate(-1);
  if OnFilterChange<>nil then OnFilterChange(anewfilter);
end;

function TTL2Translation.SearchTemplate(const atmpl:AnsiString):integer;
var
  i:integer;
begin
  result:=-1;
  for i:=0 to cntTmpl-1 do
    if atmpl=arTmpl[i] then exit(i);
end;

function TTL2Translation.AddTemplate(const atmpl:AnsiString):integer;
var
  i:integer;
begin
// use it's own cycle for "hole" filling
  result:=-1;
  for i:=0 to cntTmpl-1 do
  begin
    if (result<0) and (arTmpl[i]='') then result:=i;
    if arTmpl[i]=atmpl then exit(i);
  end;
  if result<0 then
  begin
    result:=cntTmpl;
    inc(cntTmpl);
    if result>High(arTmpl) then
      SetLength(arTmpl,cntTmpl+increment);
  end;
  arTmpl[result]:=atmpl;
  // or just add at the end
{
  result:=SearchTemplate(atmpl);
  if result<0 then
  begin
    result:=cntTmpl;
    inc(cntTmpl);
    if result>High(arTmpl) then
      SetLength(arTmpl,cntTmpl+increment);
    arTmpl[result]:=atmpl;
  end;
}
end;

procedure TTL2Translation.RebuildTemplate(idx:integer=-1);
var
  i:integer;
begin
  if (idx<0) or (idx>=cntText) then
  begin
    SetLength(arTmpl,0);
    cntTmpl:=0;
    SetLength(arTmpl,cntText);

    for i:=0 to cntText-1 do
      arText[i].tmpl:=AddTemplate(FilteredString(arText[i].origin))
  end
  else
    arText[idx].tmpl:=AddTemplate(FilteredString(arText[idx].origin))
end;

//----- Search & Filter -----

    {
     >0 = (idx+1)
     =0 = not found
     <0 = -(idx+1) partially
     -------
     but we need (Want)
     not found
     found partial
     <found in base>
     found
    }
function SearchString(var adict:TTL2Translation; const atext,atmpl:AnsiString):integer;
var
  i,first,ltmpl:integer;
begin
  result:=0;

  ltmpl:=adict.SearchTemplate(atmpl);
  if ltmpl<0 then exit;

  first:=-1;
  for i:=0 to adict.cntText-1 do
  begin
    if (ltmpl=adict.arText[i].tmpl) then
//    if (atmpl=adict.arText[i].tmpl) then
    begin
      // 100% the same
      if atext=adict.arText[i].origin then
      begin
        result:=i+1;
        exit;
      end;
      // save 1st case only
      if first<0 then
        first:=i
      else
      begin
        if (adict.arText[first].transl= '') and
           (adict.arText[i    ].transl<>'') then
          first:=i;
      end;
    end;
  end;
  if first>=0 then
  begin
    // no translation = not found
    if (adict.arText[first].transl<>'') then
      result:=-(first+1);
  end;
end;

function TTL2Translation.AddStringOnImport(const aorig,atrans,atmpl:AnsiString; apart:boolean):integer;
var
  ltrans,ltmpl:AnsiString;
  ltype:tTextStatus;
  i:integer;
begin
  result:=0;

  if aorig='' then exit;

  //--- Search for doubles

  if filter=flNoFilter then
  begin
    for i:=0 to cntText-1 do
    begin
      if aorig=arText[i].origin then
      begin
        result:=-(i+1);
        break;
      end;
    end;
  end;

  i:=0;
  if result=0 then
  begin
    if atmpl='' then
      ltmpl:=FilteredString(aorig)
    else
      ltmpl:=atmpl;

    //!!!
    if ltmpl='' then exit;

    if filter=flFiltered then
    begin
      i:=SearchString(self,aorig,ltmpl);

      if i>0 then
      begin
        result:=-i; // idx+1 already
      end;
    end;
  end;

  // we have a double
  if result<0 then
  begin
    i:=(-result)-1;
    // check for translation
    if arText[i].transl<>atrans then
    begin
      case arText[i].state of
        stOriginal: if (atrans<>'') and (aorig<>atrans) then
        begin
          arText[i].transl:=atrans;
          if apart then
            arText[i].state:=stPartial
          else
            arText[i].state:=stReady;
        end;

        stPartial: if (not apart) and (atrans<>'') and (aorig<>atrans) then
        begin
          arText[i].transl:=atrans;
          arText[i].state :=stReady;
        end;

        stDeleted,
        stReady: ;
      end;
    end;
    exit;
  end;

  //--- Prepare translation

  // i=0 - string was not found
  // i<0 - similar string was found, not the same

  // "empty" translation ignoring "partial" flag
  if (atrans='') or (aorig=atrans) then
  begin
    if i=0 then // "same" text without translation
    begin
      ltype :=stOriginal;
      ltrans:='';
    end
    else
    begin
      ltype :=stPartial;
      ltrans:=ReplaceTranslation(arText[-i-1].transl,aorig);
    end;
  end
  else
  begin
    ltrans:=atrans;
    if apart then
      ltype:=stPartial
    else
      ltype:=stReady;
  end;

  //--- Fill
  if cntText>=Length(arText) then
  begin
    if Length(arText)=0 then
      SetLength(arText,16000)
    else
      SetLength(arText,cntText+increment);
  end;

  arText[cntText].transl:=ltrans;
  arText[cntText].state :=ltype;
  arText[cntText].origin:=aorig;
  arText[cntText].tmpl  :=AddTemplate(ltmpl);

  inc(cntText);

  if Assigned(FOnLineAdd) then
    FOnLineAdd(cntText-1);

  result:=cntText;
end;

function TTL2Translation.AddStringOnScan(const aorig:AnsiString):integer;
var
  ltmpl:AnsiString;
  i:integer;
begin
  result:=0;

  if aorig='' then exit;

  //--- Search for doubles

  i:=0;
  if filter=flNoFilter then
  begin
    for i:=0 to cntText-1 do
    begin
      if aorig=arText[i].origin then
      begin
        result:=-(i+1);
        exit;
      end;
    end;
    i:=0;
  end;

  ltmpl:=FilteredString(aorig);

  //!!!
  if ltmpl='' then exit;

  if filter=flFiltered then
  begin
    i:=SearchString(self,aorig,ltmpl);
    // i=idx+1 already
    if i>0 then
    begin
      result:=-i;
      exit;
    end;
  end;

  //--- Fill
  if cntText>=Length(arText) then
  begin
    if Length(arText)=0 then
      SetLength(arText,16000)
    else
      SetLength(arText,cntText+increment);
  end;

  with arText[cntText] do
  begin
    transl:='';
    state :=stOriginal;
    origin:=aorig;
    tmpl  :=AddTemplate(ltmpl);
  end;

  inc(cntText);

  if Assigned(FOnLineAdd) then
    FOnLineAdd(cntText-1);

  result:=cntText;
end;

//===== Read translation =====

function TTL2Translation.LoadFromTranslation(const src:TTL2Translation):integer;
var
  sl:TStringList;
  i,j:integer;
begin
  result:=0;
  for i:=0 to src.cntText-1 do
  begin
    if src.State[i]<>stDeleted then
    begin
      j:=AddStringOnImport(src.Line[i],src.Trans[i],src.Template[i],src.State[i]=stPartial);
      if j>0 then inc(result);
      if j=0 then continue;
      Refs.CopyLink(ABS(j)-1,src.Refs,i);
    end;
  end;

  if result>0 then
  begin
    // Roots
    for i:=0 to src.Refs.RootCount-1 do
    begin
      Refs.AddRoot(src.Refs.Root[i]);
    end;

    sl:=TStringList.Create;
    sl.Sorted:=true;

    // MOD list
    i:=Length(FModList);
    if i=0 then
    begin
      if FModTitle<>'' then sl.Add(FModTitle)
    end
    else
      for j:=0 to i-1 do
        sl.Add(FModList[j]);

    i:=Length(src.FModList);
    if i=0 then
    begin
      if src.FModTitle<>'' then sl.Add(src.FModTitle)
    end
    else
      for j:=0 to i-1 do
        sl.Add(src.FModList[j]);

    SetLength(FModList,sl.Count);
    for i:=0 to sl.Count-1 do
      FModList[i]:=sl[i];

    sl.Free;
  end;

end;

procedure TTL2Translation.Error(acode:integer; const afname:AnsiString; aline:integer);
begin
  FErrFile:=afname;
  FErrCode:=ABS(acode);
  FErrLine:=aline+1;

  case FErrCode of
    1: FErrText:=sNoFileStart;     // no file starting tag
    2: FErrText:=sNoBlockStart;    // no block start
    3: FErrText:=sNoOrignText;     // no original text
    4: FErrText:=sNoTransText;     // no translated text
    5: FErrText:=sNoEndBlock;      // no end of block
    6: FErrText:=sWrongLineAmount; // different lines amount in text and info
  end;
  RGLog.Add(FErrFile,FErrLine,FErrText);
end;

function TTL2Translation.AddStringOnLoad(const aorig,atrans:AnsiString):integer;
begin
  //--- in case when no/wrong Info file
  if Length(arText)=0 then
    SetLength(arText,16000)
  else if cntText>=Length(arText) then
    SetLength(arText,cntText+increment);

  arText[cntText].transl:=atrans;
  arText[cntText].origin:=aorig;

  inc(cntText);

  if Assigned(FOnLineAdd) then
    FOnLineAdd(cntText-1);

  result:=cntText;
end;

function TTL2Translation.LoadFromFile(const fname:AnsiString):integer;
var
  slin:TStringList;
  s,lsrc,ldst:AnsiString;
  loldcnt,lcnt,lline:integer;
  i,stage:integer;
begin
  FErrCode:=0;
  FErrLine:=0;
  FErrFile:='';
  FErrText:='';

  result:=0;
  if fname='' then exit;

  slin:=TStringList.Create;
  try
    slin.LoadFromFile(fname,TEncoding.Unicode);
  except
    slin.Free;
    exit;
  end;

  LoadInfo(fname);

{
  Filter:=flNoSearch;
  Mode  :=tmOriginal;
}
  lline:=0;
  loldcnt:=Length(arText);
  lcnt:=0;
  lsrc:='';
  ldst:='';

  stage:=1;

  while lline<slin.Count do
  begin
    s:=slin[lline];
    if s<>'' then
    begin
      case stage of
        // <STRING>ORIGINAL:
        // <STRING>TRANSLATION:
        // [/TRANSLATION]
        3: begin
          i:=0;
          if (lsrc='') then
          begin
            i:=Pos(sOriginal,s);
            if i<>0 then lsrc:=Copy(s,i+Length(sOriginal));
          end;

          if (i=0) and (ldst='') then
          begin
            i:=Pos(sTranslated,s);
            if i<>0 then ldst:=Copy(s,i+Length(sTranslated));
            //!!!!
            if ldst=lsrc then ldst:='';
          end;

          if (i=0) then
          begin
            if Pos(sEndBlock,s)<>0 then
            begin
              stage:=2;

              if (lsrc<>'') {and (ldst<>'')} then
              begin
                if AddStringOnLoad(lsrc,ldst)>0 then
                  inc(lcnt);
              end
              else if lsrc='' then
              begin
                result:=-3;
                Error(result,fname,lline); // no original text
//!!                break;
{
              end
              else if ldst='' then
              begin
                result:=-4;
                Error(result,fname,lline); // no translated text
//!!                break;
}
              end;

            end
            else
            begin
              result:=-5;
              Error(result,fname,lline); // no end of block
//??            break;
            end;
          end;

        end;

        // [TRANSLATION] and [/TRANSLATIONS]
        2: begin
          if Pos(sBeginBlock,s)<>0 then
          begin
            stage:=3;
            lsrc:='';
            ldst:='';
          end
          else if Pos(sEndFile,s)<>0 then break // end of file
          else
          begin
            result:=-2;
            Error(result,fname,lline); // no block start
//??            break;
          end;
        end;

        // [TRANSLATIONS]
        1: begin
          if Pos(sBeginFile,s)<>0 then
            stage:=2
          else
          begin
            result:=-1;
            Error(result,fname,lline); // no file starting tag
            break;
          end;
        end;
      end;
    end;
    inc(lline);
  end;

  slin.Free;

  // fix state
  for i:=0 to High(arText) do
  begin
    with arText[i] do
    begin
      if (transl<>'') and (transl<>origin) then
        state:=stReady
      else
        state:=stOriginal;
    end;
  end;

  if (arTmpl=nil) or FRefilter then
    RebuildTemplate()
  else if lcnt<>loldcnt then
  begin
    // RebuildTemplate();
    for i:=0 to High(arText) do
    begin
      with arText[i] do
      begin
{
        if (transl<>'') and (transl<>origin) then
          state:=stReady
        else
          state:=stOriginal;
}
        tmpl:=AddTemplate(FilteredString(origin));
      end;
    end;
    if loldcnt>0 then
    begin
      result:=-6;
      Error(result,fname,loldcnt); // wrong line amount in text and info
    end;
  end;

  result:=lcnt;
end;

//===== Export =====

procedure TTL2Translation.SaveToFile(const fname:AnsiString; astat:tTextStatus=stPartial; askip:boolean=false);
var
  sl:TStringList;
  ls:AnsiString;
  l,i:integer;
  lst:tTextStatus;
begin
  FErrCode:=0;
  FErrLine:=0;
  FErrFile:='';
  FErrText:='';

  SaveInfo(fname);

  sl:=TStringList.Create;
  sl.WriteBOM:=true;

  sl.Add(sBeginFile);

  for i:=0 to cntText-1 do
  begin
    lst:=arText[i].state;
    if lst<>stDeleted then
    begin
      if (arText[i].transl<>'') and
        ((lst <>stPartial) or
         (astat=stPartial)) then
        l:=1
      else if not askip then
        l:=2
      else
        l:=0;

      if l<>0 then
      begin
        sl.Add(#9+sBeginBlock);
        sl.Add(#9#9+sOriginal+arText[i].origin);

        if l=1 then
          sl.Add(#9#9+sTranslated+arText[i].transl)
        else if not askip then
          sl.Add(#9#9+sTranslated+arText[i].origin);

        sl.Add(#9+sEndBlock);
      end;
    end;
  end;

  sl.Add(sEndFile);

  if      fname<>''      then ls:=fname
  else if Mode=tmDefault then ls:='EXPORT_FULL.DAT'
  else                        ls:='EXPORT.DAT';

  sl.SaveToFile(ls,TEncoding.Unicode);

  sl.Free;
end;

//===== Info =====

procedure TTL2Translation.LoadInfo(const fname:AnsiString);
var
  lstrm:tMemoryStream;
  ls:string;
  i,lver,lamount,lsize,ltype:integer;
  ltmp:dword;
begin
  ls:=ChangeFileExt(fname,cnstInfoExt);
  if FileExists(ls) then
  begin
    lstrm:=tMemoryStream.Create;
    try
      lstrm.LoadFromFile(ls);

      // info version
      ltmp:=lstrm.ReadDWord();
      if (ltmp and $FFFFFF00) = dwPrefix then
      begin
        lver:=ltmp and $7F;
        FPackInfo:=(ltmp and $80)<>0;
      end
      else
      begin
//        FPackInfo:=false; // always false for ver=0
        lver:=0;
        lstrm.Position:=0;
      end;

      // if packed, read unpacked size and unpack to stream
      
      // references
      FRefs.LoadFromStream(lstrm);

      // flags
      lamount:=lstrm.ReadDWord();
      SetLength(arText,lamount);

      for i:=0 to lamount-1 do
      begin
        // old version
        if lver=0 then
        begin
          lstrm.ReadDWord(); // ignore ref
          //!! will need to change to stReady if translation presents
          if lstrm.ReadByte()<>0 then arText[i].state:=stPartial else arText[i].state:=stOriginal;
        end
        else
        begin
          arText[i].state:=TTextStatus(lstrm.ReadByte());
        end;
      end;

      FRefilter:=true;
      while lstrm.Position<lstrm.Size do
      begin
        ltype:=lstrm.ReadByte();
        if lver>0 then
        begin
          lsize:=lstrm.ReadDWord();
          if (lstrm.Position+lsize)>lstrm.Size then break;
        end;

        case ltype of
          // Templates
          1: begin
            if FRefilter then
            begin
              if lver>0 then
                lstrm.Position:=lstrm.Position+lsize
              else
                break;
            end
            else
              for i:=0 to High(arText) do
              begin
                arText[i].tmpl:=AddTemplate(lstrm.ReadAnsiString());
              end;
          end;

          // Mod info
          2: begin
            FModVersion:=lstrm.ReadWord();
            FModID     :=Int64(lstrm.ReadQWord());
            FModTitle  :=lstrm.ReadAnsiString();
            FModAuthor :=lstrm.ReadAnsiString();
            FModDescr  :=lstrm.ReadAnsiString();
            FModURL    :=lstrm.ReadAnsiString();
          end;

          // mod names list
          3: begin
            lamount:=lstrm.ReadWord();
            SetLength(FModList,lamount);
            for i:=0 to lamount-1 do
              FModList[i]:=lstrm.ReadAnsiString();
          end;

          //!! good to read before template loads to check, need to set or rebuild
          4: begin
            ls:=lstrm.ReadAnsiString();
            FRefilter:=ls<>GetFilterWords();
          end;

        // unknown block
        else
          if lver>0 then
            lstrm.Position:=lstrm.Position+lsize
          else
            break;
        end;
      end;

    except
    end;
    lstrm.Free;
  end;
end;

procedure TTL2Translation.SaveInfo(const fname:AnsiString);
var
  lstrm:tMemoryStream;
  i,lcnt,lpos:integer;
  ladd:dword;
  lst:tTextStatus;
begin
  lstrm:=tMemoryStream.Create;
  try
    ladd:=dwPrefix+infoVersion;
    if FPackInfo then ladd:=ladd or $80;
    lstrm.WriteDWord(ladd);

    // references
    FRefs.SaveToStream(lstrm);

    // flags
    lstrm.Position:=lstrm.Size;
    lpos:=lstrm.Size;
    lstrm.WriteDWord(0);
    lcnt:=0;
    for i:=0 to cntText-1 do
    begin
      lst:=arText[i].state;
      if lst<>stDeleted then
      begin
        lstrm.WriteByte(ORD(lst));
        inc(lcnt);
      end;
    end;
    lstrm.WriteDWordAt(lcnt,lpos);

    // 4 - filter words. save before templates to be sure what need to read or rebuild on load
    lstrm.WriteByte(4);
    lpos:=lstrm.Position;
    lstrm.WriteAnsiString(GetFilterWords());
    lstrm.WriteDWordAt(lstrm.Position-lpos-SizeOf(DWord),lpos);

    // 1 - templates
    lstrm.WriteByte(1);
    lpos:=lstrm.Position;
    lstrm.WriteDWord(0);

    for i:=0 to cntText-1 do
    begin
      lst:=arText[i].state;
      if lst<>stDeleted then
      begin
        lstrm.WriteAnsiString(arTmpl[arText[i].tmpl]);
      end;
    end;
    lstrm.WriteDWordAt(lstrm.Position-lpos-SizeOf(DWord),lpos);

    if Length(FModList)=0 then
    begin
      if FModTitle<>'' then
      begin
        // 2 - mod info
        lstrm.WriteByte(2);
        lpos:=lstrm.Position;
        lstrm.WriteDWord(0);

        lstrm.WriteWord      (FModVersion);
        lstrm.WriteQWord     (QWord(FModID));
        lstrm.WriteAnsiString(FModTitle);
        lstrm.WriteAnsiString(FModAuthor);
        lstrm.WriteAnsiString(FModDescr);
        lstrm.WriteAnsiString(FModURL);
        lstrm.WriteDWordAt(lstrm.Position-lpos-SizeOf(DWord),lpos);
      end;
    end
    else
    begin
      // 3 - mod names list ??
      lstrm.WriteByte(3);
      lpos:=lstrm.Position;
      lstrm.WriteDWord(0);

      lstrm.WriteWord(Length(FModList));
      for i:=0 to High(FModList) do
        lstrm.WriteAnsiString(FModList[i]);

      lstrm.WriteDWordAt(lstrm.Position-lpos-SizeOf(DWord),lpos);
    end;

    if not FPackInfo then
      lstrm.SaveToFile(ChangeFileExt(fname,cnstInfoExt));
    // else pack with zlib and save to file
    // and don't forget to write unpacked size
  finally
    lstrm.Free;
  end;
end;

//===== Check =====

function TTL2Translation.CheckTheSame(idx:integer; markAsPart:boolean):integer;
var
  ltrans:AnsiString;
  litem:PDATString;
  i,ltmpl:integer;
begin
  result:=0;

  ltrans:=arText[idx].transl;
  if ltrans='' then exit;

  ltmpl:=arText[idx].tmpl;
  for i:=0 to cntText-1 do
  begin
    if i<>idx then
    begin
      litem:=@arText[i];

      if (litem^.transl=''   ) and   // litem^.state=stOriginal
         (litem^.tmpl  =ltmpl) then
      begin
        inc(result);
        litem^.transl:=ReplaceTranslation(ltrans,litem^.origin);
        if markAsPart then litem^.state:=stPartial;

        if Assigned(FOnLineChanged) then
          FOnLineChanged(i);
      end;
    end;
  end;
end;

function TTL2Translation.CheckLine(const asrc,atrans:AnsiString;
         const atmpl:AnsiString=''; astate:tTextStatus=stReady):integer;
var
  ls:AnsiString;
  litem:PDATString;
  i,oldcnt:integer;
  lstate:tTextStatus;
begin
  result:=0;
  if atrans='' then exit; // astate=stOriginal

  if atmpl='' then
    ls:=FilteredString(asrc)
  else
    ls:=atmpl;

  for i:=0 to cntText-1 do
  begin
    litem:=@arText[i];

    lstate:=litem^.state;
    if lstate<>stReady then
    begin
      oldcnt:=result;
      // similar or same
      if ls=arTmpl[litem^.tmpl] then
      begin
        // 100% same
        if asrc=litem^.origin then
        begin
          if (lstate=stOriginal) or (astate=stReady) then
          begin
            litem^.transl:=atrans;
            litem^.state :=astate;
            inc(result);
          end
          else if lstate=stPartial then
          begin
            if FUpdPart<>upKeepOld then
            begin
              if litem^.transl<>atrans then
              begin
                if FUpdPart=upUpdate then
                  litem^.transl:=atrans
                else
                  litem^.transl:=litem^.transl+'\nNew translation:\n'+atrans;
                inc(result);
              end;
            end;
{
            case FUpdPart of
              upKeepOld: ; // do nothing
              upUpdate: if litem^.transl<>atrans then
              begin
                litem^.transl:=atrans;
                inc(result);
              end;
              upCombine: if litem^.transl<>atrans then
              begin
                litem^.transl:=litem^.transl+'\nNew translation:\n'+atrans;
                inc(result);
              end;
            end;
}
          end;
        end
        // just similar
        else
        begin
          // no translation
          if lstate=stOriginal then
          begin
            litem^.transl:=ReplaceTranslation(atrans,litem^.origin);
            litem^.state:=stPartial;
            inc(result);
          end;
        end;

        if oldcnt<>result then
          if Assigned(FOnLineChanged) then
            FOnLineChanged(i);
      end;
    end;
  end;
end;

//===== Import =====

function TTL2Translation.ImportFromFile(const fname:AnsiString):integer;
var
  ldata:TTL2Translation;
  lcnt,i:integer;
begin
  ldata.Init;
  ldata.Filter:=flNoSearch;
  ldata.Mode  :=tmOriginal;

  lcnt:=0;
  if ldata.LoadFromFile(fname)>0 then
  begin
    //!! total counter
    if Assigned(FOnProgress) and (ldata.LineCount>100) then
      FOnProgress(-ldata.LineCount);

    for i:=0 to ldata.LineCount-1 do
    begin
      //!! runtime counter. Processed, not changed
      if Assigned(FOnProgress) and (i>0) {and ((i mod 100)=0)} then
        FOnProgress(i);
      
      inc(lcnt, CheckLine(
          ldata.arText[i].origin,
          ldata.arText[i].transl,
          ldata.arTmpl[ldata.arText[i].tmpl],
          ldata.arText[i].state)
         );
{
      inc(lcnt, CheckLine(ldata.Line[i],ldata.Trans[i],
          ldata.template[i],ldata.State[i]));
}
    end;
  end;

  ldata.Free;

  result:=lcnt;
end;

function TTL2Translation.ImportFromText(const atext:AnsiString):integer;
var
  s,lsrc,ltrans:AnsiString;
  sl:TStringList;
  p,lline:integer;
  lcnt{,i}:integer;
begin
  result:=0;

  if atext<>'' then
  begin
    sl:=TStringList.Create;
    try
      sl.Text:=atext;

      //!! how much on input
      if Assigned(FOnProgress) then
        FOnProgress(-sl.Count);

      lcnt:=0;

      for lline:=0 to sl.Count-1 do
      begin
        s:=sl[lline];
        // Split to parts
        p:=Pos(#9,s);
        if p>0 then
        begin
          lsrc  :=Copy(s,1,p-1);
          ltrans:=Copy(s,p+1);
          inc(lcnt, CheckLine(lsrc,ltrans));
        end
      end;

      //!! how much affected
      result:=lcnt;

    finally
      sl.Free;
    end;
  end;
end;

//===== Export =====
    
function TTL2Translation.ExportToFile(const fname:AnsiString):boolean;
begin
  result:=false;
end;

function TTL2Translation.ExportToText():AnsiString;
begin
  result:='';
end;

//===== Basic =====

procedure TTL2Translation.Free;
begin
  FErrFile  :='';
  FErrText  :='';
  FModTitle :='';
  FModAuthor:='';
  FModDescr :='';
  FModURL   :='';

  SetLength(arText,0);  cntText:=0;
  SetLength(arTmpl,0);  cntTmpl:=0;
  SetLength(FModList,0);

  FRefs.Free;
end;

procedure TTL2Translation.Init;
begin
  FillChar(self,SizeOf(TTL2Translation),#0);

  FModID:=-1;

  FPackInfo:=false;

  FRefs.Init;

  Filter:=flNoSearch;
  Mode  :=tmOriginal;
  FRefilter:=false;

  FOnFilterChange:=OnFilterChange;
  OnFilterChange :=@FilterChange;
end;

//===== Read sources =====

procedure TTL2Translation.ReadSrcFile(const fname:AnsiString; atype:integer; arootlen:integer);
var
  slin:TStringList;
  s,ls,ltag,lfile:AnsiString;
  lfline,lline:integer;
  i,j:integer;
begin
  FErrCode:=0;
  FErrLine:=0;
  FErrFile:='';
  FErrText:='';

  slin:=TStringList.Create;
  try
    slin.LoadFromFile(fname,TEncoding.Unicode);
  except
    slin.Free;
    exit;
  end;

  lfile:=Copy(fname,arootlen);

  for lline:=0 to slin.Count-1 do
  begin
    s:=slin[lline];

    i:=-1;
    // <TRANSLATE> tag for all file types
    j:=Pos(sTranslate,s);
    if j>0 then
    begin
      inc(j,Length(sTranslate));  // points to tag for text
      i:=Pos(':',s);
      if i>0 then
      begin
        ltag:=Copy(s,j,i-j);
        inc(i);                   // points to text
      end
      else
      begin
        ltag:='';
        i:=j;                     // 'no tag' version (really?)
      end;
      lfline:=-(lline+1);
    end
    // <STRING> tag for some cases
    else
    begin
      j:=pos(sString,s);
      if j>0 then
      begin
        lfline:=lline+1;
        // <STRING>DESCRIPTION: case (old GUTS?)
        if pos(sString+sDescription+':',s)>0 then
        begin
          inc(j,Length(sString)); // points to tag for text
          i:=Pos(':',s);
          ltag:=Copy(s,j,i-j);
          inc(i);                 // points to text
        end
        else if atype=1 then // layout
        begin
          if (pos(sString+sText_       ,s)>0) or
             (pos(sString+sDialog_     ,s)>0) or
             (pos(sString+sText    +':',s)>0) or
             (pos(sString+sToolTip +':',s)>0) or
             (pos(sString+sTitle   +':',s)>0) or
             (pos(sString+sGreet   +':',s)>0) or
             (pos(sString+sFailed  +':',s)>0) or
             (pos(sString+sReturn  +':',s)>0) or
             (pos(sString+sComplete+':',s)>0) or
             (pos(sString+sComplRet+':',s)>0) then
          begin
            inc(j,Length(sString)); // points to tag for text
            i:=Pos(':',s);
            ltag:=Copy(s,j,i-j);
            inc(i);                 // points to text
          end;
        end;
      end;
    end;

    if i>0 then
    begin
      ls:=Copy(s,i,Length(s));
      if (ls<>'') and (ls<>' ') then
      begin
        i:=AddStringOnScan(ls);
        if i<>0 then Refs.AddRef(ABS(i)-1,Refs.NewRef(lfile,ltag,lfline));
      end;
    end;

  end;

  slin.Free;
end;

{$I-}
function CheckSourceFile(const fname:AnsiString; allText:boolean):integer;
var
  f:file of byte;
  lext:AnsiString;
  i:integer;
  lsign:word;
begin
  result:=-1;
//  if UpCase(ExtractFileName(fname))='MOD.DAT' then exit;

  lext:=ExtractExt(fname);

  for i:=0 to High(KnownGoodExt) do
    if lext=KnownGoodExt[i] then
    begin
      result:=i;
      exit;
    end;

  if allText then
  begin
    for i:=0 to High(KnownBadExt) do
      if lext=KnownBadExt[i] then exit;

    AssignFile(f,fname);
    Reset(f);
    if IOResult=0 then
    begin
      i:=FileSize(f);
      if i>2 then
      begin
        BlockRead(f,lsign,2);
        if lsign=$FEFF then
          result:=1000;
      end;
      CloseFile(f);
    end;
  end;
end;

procedure TTL2Translation.CycleDir(sl:TStringList;
    const adir:AnsiString; allText:boolean; withChild:boolean);
var
  sr:TSearchRec;
  lname:AnsiString;
  i:integer;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if withChild and (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(sl, lname, allText, withChild);
      end
      else
      begin
        i:=CheckSourceFile(lname, allText);
        if i>=0 then
          sl.AddObject(lname,TObject(IntPtr(i)));
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

function TTL2Translation.Scan(const adir:AnsiString; allText:boolean; withChild:boolean):boolean;
var
  lmodinfo:TTL2ModInfo;
  sl:TStringList;
  lRootScanDir:AnsiString;
  i,llen:integer;
begin
  result:=true;

  Filter:=flFiltered;

  if adir[Length(adir)] in ['\','/'] then
    lRootScanDir:=Copy(adir,1,Length(adir)-1)
  else
    lRootScanDir:=adir;

  sl:=TStringList.Create();
  CycleDir(sl, lRootScanDir, allText, withChild);

  if sl.Count>0 then
  begin
    FRefs.AddRoot(lRootScanDir+'/');
    llen:=Length(lRootScanDir)+2; // to get relative filepath+name later
    for i:=0 to sl.Count-1 do
    begin
      if Assigned(FOnFileScan) then
        case FOnFileScan(sl[i],i+1,sl.Count) of
          0: ;
          1: continue;
          2: begin
            result:=false;
            break;
          end;
        end;

      if UpCase(ExtractName(sl[i]))=TL2ModData then
      begin
        MakeModInfo(lmodinfo);
        LoadModConfig(PChar(sl[i]),lmodinfo);
        FModTitle  :=WideToStr(lmodinfo.title);
        FModAuthor :=WideToStr(lmodinfo.author);
        FModDescr  :=WideToStr(lmodinfo.descr);
        FModURL    :=WideToStr(lmodinfo.download);
        FModVersion:=lmodinfo.modver;
        FModID     :=lmodinfo.modid;
        ClearModInfo(lmodinfo);
      end
      else
        ReadSrcFile(sl[i],IntPtr(sl.Objects[i]),llen);
    end;
  end;

  sl.Free;
end;

{%REGION Read Binary}

function TTL2Translation.ProcessNode(anode:pointer; const afile:string; atype:integer):integer;
var
  ltag,ls:AnsiString;
  i,lline:integer;
begin
  result:=0;
  ls:='';

  inc(FScanLine);
  case GetNodeType(anode) of
    rgGroup: begin
      for i:=0 to GetChildCount(anode)-1 do
      begin
        inc(result,ProcessNode(GetChild(anode,i),afile,atype));
      end;
      inc(FScanLine); // for "Group close" line

      exit;
    end;

    rgTranslate: begin
      ltag:=FastWideToStr(GetNodeName(anode));
      ls  :=WideToStr(AsTranslate(anode));
      lline:=-FScanLine;
    end;

    rgString: begin
      ltag:=FastWideToStr(GetNodeName(anode));

      if ltag=sDescription then
        ls:=WideToStr(AsString(anode))
      else if (atype=1) and (  // layout
         (pos(sText_  ,ltag)=1) or
         (pos(sDialog_,ltag)=1) or
         (ltag=sText    ) or
         (ltag=sToolTip ) or
         (ltag=sTitle   ) or
         (ltag=sGreet   ) or
         (ltag=sFailed  ) or
         (ltag=sReturn  ) or
         (ltag=sComplete) or
         (ltag=sComplRet)) then
        ls:=WideToStr(AsString(anode));

      lline:=FScanLine;
    end;
  else
    exit;
  end;

  if (ls<>'') and (ls<>' ') then
  begin
    result:=1;
    i:=AddStringOnScan(ls);
    if i<>0 then Refs.AddRef(ABS(i)-1,Refs.NewRef(afile,ltag,lline));
  end;
end;

function myactproc(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  lnode:pointer;
  ltype:integer;
begin
  result:=0;

  with PTL2Translation(aparam)^ do
  begin
    inc(FScanIdx);
    if Assigned(FOnFileScan) then
      case FOnFileScan(adir+'/'+aname,FScanIdx,0) of
        0: ;
        1: exit;
        2: exit(sres_fail);
      end;
  end;

  if Pos('TRANSLATIONS',UpCase(adir))>0 then exit;

  if ExtractExt(aname)='.LAYOUT' then
  begin
    lnode:=ParseLayoutMem(abuf,adir); // for checking, Particles, UI or Layout
    ltype:=1;
  end
  else
  begin
    lnode:=ParseDatMem(abuf);
    ltype:=0;
  end;
  if lnode=nil then exit;

  with PTL2Translation(aparam)^ do
  begin
    FScanLine:=0;
    if ProcessNode(lnode,adir+aname,ltype)>0 then result:=1;

  end;

  DeleteNode(lnode);
end;

function TTL2Translation.Scan(const afile:AnsiString):boolean;
var
  lmod:TTL2ModInfo;
begin

  RGTags.Import('RGDICT','TEXT');

  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  Filter:=flFiltered;

  FErrCode:=0;
  FErrLine:=0;
  FErrText:='';
  FErrFile:='';

  FScanIdx:=0;

  FRefs.AddRoot(afile);
  result:=MakeRGScan(afile,'',['.DAT','.LAYOUT','.TEMPLATE','.WDAT'],@myactproc,@self,nil)>0;
  if result then
  begin
    if ReadModInfo(PChar(afile), lmod) then
    begin
      FModTitle  :=WideToStr(lmod.title);
      FModAuthor :=WideToStr(lmod.author);
      FModDescr  :=WideToStr(lmod.descr);
      FModURL    :=WideToStr(lmod.download);
      FModVersion:=lmod.modver;
      FModID     :=lmod.modid;
      ClearModInfo(lmod);
    end;
  end;
end;

{%ENDREGION Read Binary}

procedure CycleDirBuild(sl:TStringList; const adir:AnsiString);
var
  sr:TSearchRec;
  lext,lname:AnsiString;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDirBuild(sl, lname);
      end
      else
      begin
        lext:=ExtractExt(lname);
        if lext='.DAT' then
          sl.Add(lname);
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

procedure TTL2Translation.Build(const adir:string; const abase:string='');
var
  sl:TStringList;
  i:integer;
  lt:TTL2Translation;
begin
//  don't need if we will use severa lcalls with dirs
//  Init;

  if {cntText=0} Mode=tmOriginal then
  begin
    Filter:=flNoSearch;

    if BaseTranslation.cntText>0 then
    begin
      if Assigned(FOnFileBuild) then
        FOnFileBuild(sBaseTranslation,0,0);

      LoadFromTranslation(BaseTranslation);
    end
    else if abase<>'' then
    begin
      if Assigned(FOnFileBuild) then
        FOnFileBuild(sBaseTranslation+'('+abase+')',0,0);

      LoadFromFile(abase);
    end;
  end;
  
  sl:=TStringList.Create();

  CycleDirBuild(sl, adir);
  
  Mode  :=tmMod;
  Filter:=flNoFilter;
  for i:=0 to sl.Count-1 do
  begin
    if sl[i]<>abase then
    begin
      if Assigned(FOnFileBuild) then FOnFileBuild(sl[i],i+1,sl.Count);

//      LoadFromFile(sl[i]);
      lt.Init;
      lt.LoadFromFile(sl[i]);
      LoadFromTranslation(lt);
      lt.Free;
    end;
  end;

  sl.Free;

  Mode:=tmDefault;
end;

initialization

//  FillChar(BaseTranslation, SizeOf(BaseTranslation), 0);
  BaseTranslation.Init;

finalization

//  if BaseTranslation.arText<>nil then
  BaseTranslation.Free;

end.

