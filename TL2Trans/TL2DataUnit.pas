unit TL2DataUnit;

interface

uses
  Classes,
  TL2RefUnit;

// filters
type
  tSearchFilter = (
    flNoSearch,  // do not search for doubles
    flNoFilter,  // search but 100% the same only
    flFiltered); // search the same and similar
  tTextMode     = (
    tmOriginal,  // process: Load/save project
    tmDefault,   // process: load default file / save all
    tmMod);      // Process: loading mods
  tTextStatus   = (
    stOriginal,  // not translated
    stPartial,   // translated just partially
    stReady,     // translated
    stDeleted);  // prepared to delete (don't save)

type
  tDATString = record
    origin: AnsiString;
    filter: AnsiString;
    transl: AnsiString;
    aref  : integer; // reference to original placement
    sample: integer;
    atype : tTextStatus;
  end;

type
{
  0 - OK
  1 - skip this file
  2 - abort
}
  TOnFileScan = function (const fname:AnsiString; idx, atotal:integer):integer of object;

type
  PTL2Translation = ^TTL2Translation;

  { TTL2Translation }

  TTL2Translation = object
  private
    FErrFile: AnsiString;
    FErrText: AnsiString;
    FErrCode: integer;
    FErrLine: integer;

    ref:TTL2Reference;
    
    arText  : array of tDATString;
    cntText : integer; // lines totally
    cntStart: integer; // start line of project

    noteIndex:integer;
    
    FDoubles  : integer;
    FFMode    : tTextMode;
    FFilter   : tSearchFilter;

    FOnFileScan:TOnFileScan;

    function GetFileLine(idx: integer): integer;

    procedure SetFilter(afilter:tSearchFilter);
    function  GetStatus(idx:integer):tTextStatus;
    procedure SetStatus(idx:integer; astat:tTextStatus);

    procedure Error(acode:integer; const afname:AnsiString; aline:integer);
    {
     >0 = idx+1
     =0 = not found
     <0 = partially
    }
    function SearchString(const atext,afilter:AnsiString):integer;
    {
      >0 =  (idx+1) (=current lines amount)
      <0 = -(idx+1) (found the same)
      =0 = not added (empty source)
    }
    function  AddString(const aorig,atrans:AnsiString):integer;
    procedure AddDouble(atext,aref:integer);

    function  GetRefAmount :integer;
    function  GetTagAmount :integer;
    function  GetFileAmount:integer;
    function  GetSimIndex(idx:integer):integer;
    function  GetTemplate(idx:integer):AnsiString;
    function  GetSample(idx:integer):AnsiString;
    function  GetFile  (idx:integer):AnsiString;
    function  GetAttrib(idx:integer):AnsiString;
    function  GetSource(idx:integer):AnsiString;
    procedure SetTrans (idx:integer; const translated: AnsiString);
    function  GetTrans (idx:integer):AnsiString;
    function  GetSrcDir:AnsiString;
    procedure SetSrcDir(const adir:AnsiString);

    procedure ReadSrcFile(const fname: AnsiString; atype: integer; arootlen:integer);
    procedure CycleDir     (sl:TStringList; const adir:AnsiString; allText:boolean; withChild:boolean);

  public
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
    procedure SaveToFile  (const fname:AnsiString; astat:tTextStatus; askip:boolean=false);
    procedure SaveInfo(const aname:AnsiString);
    procedure LoadInfo(const aname:AnsiString);

    function Scan(const adir:AnsiString; allText:boolean; withChild:boolean):boolean;

    function FirstNoticed(acheckonly:boolean=true):integer;
    function NextNoticed (acheckonly:boolean=true):integer;

    property OnFileScan:TOnFileScan read FOnFileScan write FOnFileScan;
    // statistic
    property Tags    :integer read GetTagAmount;
    property Files   :integer read GetFileAmount;
    property Referals:integer read GetRefAmount;
    property Lines   :integer read cntText;
    property Doubles :integer read FDoubles;

    // errors
    property ErrorCode:integer    read FErrCode;
    property ErrorText:AnsiString read FErrText;
    property ErrorFile:AnsiString read FErrFile;
    property ErrorLine:integer    read FErrLine;

    // global
    property Mode  :tTextMode     read FFMode  write FFMode;
    property Filter:tSearchFilter read FFilter write SetFilter;

    // reference
    property SrcDir:AnsiString read GetSrcDir write SetSrcDir;
    property FileLine[idx:integer]:integer     read GetFileLine;
    property _File   [idx:integer]:AnsiString  read GetFile;
    property Attrib  [idx:integer]:AnsiString  read GetAttrib;
    // lines
    property Template[idx:integer]:AnsiString  read GetTemplate;
    property SimIndex[idx:integer]:integer     read GetSimIndex;
    property Sample  [idx:integer]:AnsiString  read GetSample;
    property State   [idx:integer]:tTextStatus read GetStatus write SetStatus;

    property Line    [idx:integer]:AnsiString  read GetSource;
    property Trans   [idx:integer]:AnsiString  read GetTrans  write SetTrans;
  end;

//============================================

implementation

uses
  SysUtils,
  TL2Text;

// Open file error codes

resourcestring
  sNoFileStart  = 'No file starting tag';
  sNoBlockStart = 'No block start';
  sNoOrignText  = 'No original text';
  sNoTransText  = 'No translated text';
  sNoEndBlock   = 'No end of block';

const
  KnownGoodExt: array of string = (
    '.DAT',
    '.LAYOUT',
    '.TEMPLATE'
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
  increment = 8;

var
  TmpInfo:array of record
    _ref :integer;
    _part:boolean;
  end = nil;

//===== Support =====

function TTL2Translation.FirstNoticed(acheckonly:boolean=true):integer;
begin
  noteIndex:=-1;
  result:=NextNoticed(acheckonly);
end;

function TTL2Translation.NextNoticed(acheckonly:boolean=true):integer;
begin
  inc(noteIndex);
  if (noteIndex<cntStart) or (noteIndex>=cntText) then
    noteIndex:=cntStart;

  while noteIndex<cntText do
  begin
    if CheckPunctuation(arText[noteIndex].origin,arText[noteIndex].transl,acheckonly) then
    begin
      result:=noteIndex;
      exit;
    end;

    inc(noteIndex);
  end;

  result:=-1;
end;

procedure TTL2Translation.SetFilter(afilter:tSearchFilter);
begin
  FFilter:=afilter;
end;

procedure TTL2Translation.SetTrans(idx:integer; const translated: AnsiString);
begin
  if (idx>=0) and (idx<cntText) then
  begin
    arText[idx].transl:=translated;
    if translated<>'' then
      arText[idx].atype:=stReady
    else
      arText[idx].atype:=stOriginal;
  end;
end;

function TTL2Translation.GetTrans(idx:integer): AnsiString;
begin
  if (idx>=0) and (idx<cntText) then
  begin
    result:=arText[idx].transl;

    if arText[idx].atype=stPartial then
    begin
      if (result='') and (arText[idx].sample>=0) then
        result:=arText[arText[idx].sample].transl;
    end;
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
    arText[idx].atype:=astat;
{
    if astat=stPartial then
      arText[idx].atype:=stPartial
    else if arText[idx].transl<>'' then
      arText[idx].atype:=stReady
    else
      arText[idx].atype:=stOriginal;
}
  end;
end;

function TTL2Translation.GetStatus(idx:integer):tTextStatus;
begin
  if (idx>=0) and (idx<cntText) then
    result:=arText[idx].atype
  else
    result:=stOriginal;
end;

function TTL2Translation.GetSimIndex(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntText) then
    result:=arText[idx].sample
  else
    result:=-1;
end;

function TTL2Translation.GetSample(idx:integer):AnsiString;
begin
  result:='';
  if (idx>=0) and (idx<cntText) then
  begin
    idx:=arText[idx].sample;
    if idx>=0 then
      result:=arText[idx].origin;
  end;
end;

function TTL2Translation.GetTemplate(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntText) then
    result:=arText[idx].filter
  else
    result:='';
end;

//----- Referals -----

function TTL2Translation.GetSrcDir:AnsiString;
begin
  result:=ref.Root;
end;

procedure TTL2Translation.SetSrcDir(const adir:AnsiString);
begin
  if ref.Root<>adir then
    ref.Root:=adir;
end;

function TTL2Translation.GetRefAmount:integer;
begin
  result:=ref.RefCount;
end;

function TTL2Translation.GetTagAmount:integer;
begin
  result:=ref.TagCount;
end;

function TTL2Translation.GetFileAmount:integer;
begin
  result:=ref.FileCount;
end;

function TTL2Translation.GetFile(idx:integer):AnsiString;
begin
  result:='';

  if (idx>=0) and (idx<cntText) then
  begin
    if arText[idx].aref>=0 then
    begin
      result:=ref.GetFile(arText[idx].aref);
    end;
  end;
end;

function TTL2Translation.GetFileLine(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntText) then
    result:=ref.GetLine(arText[idx].aref)
  else
    result:=-1;
end;

function TTL2Translation.GetAttrib(idx:integer):AnsiString;
begin
  result:='';

  if (idx>=0) and (idx<cntText) then
  begin
    if arText[idx].aref>=0 then
    begin
      result:=ref.GetTag(arText[idx].aref);
    end;
  end;
end;

//----- unnecessary -----

// atext - old line index; aref - current line reference
procedure TTL2Translation.AddDouble(atext,aref:integer);
var
  oldref:integer;
begin
  // if line added
  if atext>=0 then
  begin
    if aref>=0 then
    begin
      oldref:=arText[atext].aref;
      // dupe in project files
      if oldref>=0 then
      begin
        ref.Dupe[oldref]:=ref.Dupe[oldref]-1;
        ref.Dupe[aref  ]:=oldref+1;
      end
      // dupe in preloads
      else
        ref.Dupe[aref]:=0;
    end;

    inc(FDoubles);
  end;
end;

//----- Search & Filter -----

function TTL2Translation.SearchString(const atext,afilter:AnsiString):integer;
var
  i,first,tries:integer;
begin
  result:=0;

  first:=-1;
  tries:=0;
  for i:=0 to cntText-1 do
  begin
    if (afilter=arText[i].filter) then
    begin
      // 100% the same
      if atext=arText[i].origin then
      begin
        result:=i+1;
        exit;
      end;
      // keep similar lines amount
      inc(tries);
      // save 1st case only
      if first<0 then
        first:=i
      else
      begin
        if (arText[first].transl= '') and
           (arText[i    ].transl<>'') then
          first:=i;
      end;
    end;
  end;
  if first>=0 then
  begin
    // no translation = not found
    if (arText[first].transl= '') then
      result:=0
    else
      result:=-first-1;
  end;
end;

function TTL2Translation.AddString(const aorig,atrans:AnsiString):integer;
var
  lorig,ltrans,lfilter:AnsiString;
  ltype:tTextStatus;
  i:integer;
begin
  result:=0;

  if aorig='' then exit;

  //--- Preprocess

  lorig:=aorig;

  //--- Search for doubles

  case filter of
    flNoSearch: i:=0;
    flNoFilter: begin
      for i:=0 to cntText-1 do
      begin
        if lorig=arText[i].origin then
        begin
          result:=-(i+1);
          exit;
        end;
      end;
      i:=0;
    end;
  end;

  lfilter:=FilteredString(lorig);
  //!!!
  if lfilter='' then exit;

  if filter=flFiltered then
  begin
    i:=SearchString(lorig,lfilter);
    if i>0 then
    begin
      result:=-i;
      exit;
    end;
  end;

  //--- Prepare translation

  if (atrans='') or (lorig=atrans) then
  begin
    ltrans:='';
    if i=0 then // "same" text without translation
      ltype:=stOriginal
    else
    begin
      ltype:=stPartial;

      ltrans:=ReplaceTranslation(arText[-i-1].transl,lorig);
    end;
  end
  else
  begin
    ltrans:=atrans;
    ltype:=stReady;
  end;

  //--- Fill

  if cntText>=Length(arText) then
  begin
    SetLength(arText,cntText+increment*100);
  end;

  arText[cntText].sample:=-i-1;
  arText[cntText].transl:=ltrans;
  arText[cntText].atype :=ltype;

  arText[cntText].origin:=lorig;
  arText[cntText].filter:=lfilter;

  inc(cntText);
  result:=cntText;
end;

//===== Read translation =====

procedure TTL2Translation.Error(acode:integer; const afname:AnsiString; aline:integer);
begin
  FErrFile:=afname;
  FErrCode:=acode;
  FErrLine:=aline+1;

  case acode of
    1: FErrText:=sNoFileStart;  // no file starting tag
    2: FErrText:=sNoBlockStart; // no block start
    3: FErrText:=sNoOrignText;  // no original text
    4: FErrText:=sNoTransText;  // no translated text
    5: FErrText:=sNoEndBlock;   // no end of block
  end;
end;

function TTL2Translation.LoadFromFile(const fname:AnsiString):integer;
var
  slin:TStringList;
  s,lsrc:AnsiString;
  lcnt,lline:integer;
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

  lline:=0;
  lcnt:=0;

  stage:=1;

  while lline<slin.Count do
  begin
    s:=slin[lline];
    if s<>'' then
    begin
      case stage of
        2: begin
          if      Pos(sBeginBlock,s)<>0 then stage:=3
          else if Pos(sEndFile   ,s)<>0 then break // end of file
          else
          begin
            Error(2,fname,lline); // no block start
            result:=-2;
            break;
          end;
        end;
        3: begin
          i:=Pos(sOriginal,s);
          if i<>0 then
          begin
            stage:=4;
            lsrc:=Copy(s,i+Length(sOriginal),Length(s));
          end
          else
          begin
            Error(3,fname,lline); // no original text
            result:=-3;
            break;
          end;
        end;
        4: begin
          if Pos(sTranslated,s)<>0 then
          begin
            stage:=5;
            i:=AddString(lsrc,Copy(s,i+Length(sTranslated)));
            if i>0 then
            begin
              if Length(TmpInfo)>0 then
              begin
                arText[i-1].aref:=TmpInfo[lcnt]._ref;
                if TmpInfo[lcnt]._part then
                  arText[i-1].atype:=stPartial;
              end
              else
              begin
                arText[i-1].aref:=-1;
              end;
              inc(result);
            end
            else
            begin
              if Length(TmpInfo)>0 then
                AddDouble(-i-1,TmpInfo[lcnt]._ref)
              else
                AddDouble(-i-1,-1);
            end;
            inc(lcnt);
          end
          else 
          begin
            Error(4,fname,lline); // no translated text
            result:=-4;
            break;
          end;
        end;
        5: begin
          if Pos(sEndBlock,s)<>0 then
            stage:=2
          else
          begin
            Error(5,fname,lline); // no end of block
            result:=-5;
            break;
          end;
        end;
        1: begin
          if Pos(sBeginFile,s)<>0 then
            stage:=2
          else
          begin
            Error(1,fname,lline); // no file starting tag
            result:=-1;
            break;
          end;
        end;
      end;
    end;
    inc(lline);
  end;
  // if it was preload, we points to project start
  if Mode in [tmDefault,tmMod] then
    cntStart:=cntText;
  slin.Free;

  SetLength(TmpInfo,0);
end;

//===== Export =====

procedure TTL2Translation.SaveToFile(const fname:AnsiString; astat:tTextStatus; askip:boolean=false);
var
  sl:TStringList;
  ls:AnsiString;
  l,i,lstart:integer;
  lst:tTextStatus;
begin
  FErrCode:=0;
  FErrLine:=0;
  FErrFile:='';
  FErrText:='';

  sl:=TStringList.Create;
  sl.WriteBOM:=true;

  sl.Add(sBeginFile);

  if Mode=tmDefault then
    lstart:=0
  else
    lstart:=cntStart;

  for i:=lstart to cntText-1 do
  begin
    lst:=arText[i].atype;
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

  if Mode=tmDefault then
  begin
    if fname<>'' then
      ls:=fname
    else
      ls:='EXPORT_FULL.DAT';
    sl.SaveToFile(ls,TEncoding.Unicode);
  end
  else
  begin
    if fname<>'' then
      ls:=fname
    else
      ls:='EXPORT.DAT';
    sl.SaveToFile(ls,TEncoding.Unicode);
  end;

  sl.Free;
end;

//===== Info =====

procedure TTL2Translation.SaveInfo(const aname:AnsiString);
var
  lstrm:tMemoryStream;
  i,lcnt,lpos:integer;
  lst:tTextStatus;
begin
  lstrm:=tMemoryStream.Create;
  try
    ref.SaveToStream(lstrm);
    lstrm.Position:=lstrm.Size;
    lpos:=lstrm.Size;
    lstrm.WriteDWord(0);
    lcnt:=0;
    for i:=cntStart to cntText-1 do
    begin
      lst:=arText[i].atype;
      if lst<>stDeleted then
      begin
        inc(lcnt);
        lstrm.WriteDWord(dword(arText[i].aref));
        if arText[i].atype=stPartial then
          lstrm.WriteByte(1)
        else
          lstrm.WriteByte(0);
      end;
    end;
    lstrm.Position:=lpos;
    lstrm.WriteDWord(lcnt);

    lstrm.SaveToFile(ChangeFileExt(aname,'.ref'));
  finally
    lstrm.Free;
  end;
end;

procedure TTL2Translation.LoadInfo(const aname:AnsiString);
var
  lstrm:tMemoryStream;
  i,lsize:integer;
begin
  lstrm:=tMemoryStream.Create;
  try
    lstrm.LoadFromFile(ChangeFileExt(aname,'.ref'));
    ref.LoadFromStream(lstrm);

    lsize:=lstrm.ReadDWord();
    SetLength(TmpInfo,lsize);

    for i:=0 to lsize-1 do
    begin
      TmpInfo[i]._ref :=integer(lstrm.ReadDWord());
      TmpInfo[i]._part:=lstrm.ReadByte ()<>0;
    end;
  except
  end;
  lstrm.Free;
end;

//===== Basic =====

procedure TTL2Translation.Free;
begin
  SetLength(arText  ,0);

  ref.Free;
end;

procedure TTL2Translation.Init;
begin
  cntText :=0; SetLength(arText,16000);
  cntStart:=0;

  noteIndex:=-1;

  ref.Init;
end;

//===== Read sources =====

procedure TTL2Translation.ReadSrcFile(const fname:AnsiString; atype:integer; arootlen:integer);
var
  slin:TStringList;
  s,ls,ltag,lfile:AnsiString;
  lref,lline:integer;
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
    end
    // <STRING> tag for some cases
    else
    begin
      j:=pos(sString,s);
      if j>0 then
      begin
        // <STRING>DESCRIPTION: case (old GUTS?)
        if pos(sString+sDescription+':',s)>0 then
        begin
          inc(j,Length(sString)); // points to tag for text
          i:=Pos(':',s);
          ltag:=Copy(s,j,i-j);
          inc(i);                 // points to text
        end
        else if atype=1 then
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
        lref:=ref.AddRef(lfile,ltag,lline+1);
        
        i:=AddString(ls,'');
        if i>0 then
          arText[i-1].aref:=lref
        else
          AddDouble(-i-1,lref);
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
  if UpCase(ExtractFileName(fname))='MOD.DAT' then exit;

  lext:=UpCase(ExtractFileExt(fname));

  for i:=0 to High(KnownGoodExt) do
    if lext=KnownGoodExt[i] then
    begin
      result:=i;
      exit;
    end;

  for i:=0 to High(KnownBadExt) do
    if lext=KnownBadExt[i] then exit;

  if allText then
  begin
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
  sl:TStringList;
  lRootScanDir:AnsiString;
  i,llen:integer;
begin
  result:=true;

  Filter:=flFiltered;

  if adir[Length(adir)]='\' then
    lRootScanDir:=Copy(adir,1,Length(adir)-1)
  else
    lRootScanDir:=adir;

  sl:=TStringList.Create();
  CycleDir(sl, lRootScanDir, allText, withChild);

  if sl.Count>0 then
  begin
    ref.Root:=lRootScanDir;
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

      ReadSrcFile(sl[i],IntPtr(sl.Objects[i]),llen);
    end;
  end;

  sl.Free;
end;


finalization
  SetLength(TmpInfo,0);

end.

