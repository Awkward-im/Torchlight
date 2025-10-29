{TODO: RemoveOriginal: delete all translations too}
{TODO: SetModStatistic on RestoreOriginal}
{TODO: add function to delete "dead" (no source) translation lines}
{TODO: Keep filter param replace option in base}
{TODO: GetModStatistic: add NoRef translations of every lang for count}
{TODO: AddOriginal: check for case when string is presents but deleted. Must not be added back?}
{TODO: GetSimilar as mod depended}
{TODO: variant CopyToBase just for translation (not src or refs)}

{$DEFINE UseUniqueText} // fast fill, increase size
{.$DEFINE USeRefLine}    // Unused. keep line number in refs (check for double too)
unit rgdb.text;

interface

uses
//uni_profiler,
  Classes,
  logging,
  rgglobal;

const
  modVanilla =  0;
  modAll     = -1;
  modUnref   = -2;
  modList    = -3; // special. for translation build from list of mods
var
  CurMod :Int64;
  CurLang:AnsiString;
  TransOp:TRGDoubleAction;
var
  SQLog:Logging.TLog;
var
  tldb:pointer;

type
  PTLCacheElement = ^TTLCacheElement;
  TTLCacheElement = record
    src  :string;   // src text
    dst  :string;   // current trans text
    id   :integer;  // src id
    tmpl :integer;  // filter
    flags:cardinal; // refs flags (combo from all)
    part :boolean;  // current trans state
  end;
  TTLCache = array of TTLCacheElement;
var
  TRCache:TTLCache;

function  LoadModData():integer;
procedure LoadTranslation();
procedure SaveTranslation();
function BuildTranslation(const afname:AnsiString; const alang:AnsiString='';
    apart:boolean=true; aall:boolean=false; const amodid:Int64=modAll):boolean;
function LoadTranslationToBase(const fname,alang:AnsiString):integer;

function RemakeFilter():boolean;
function PrepareScanSQL():boolean;

function CreateLangTable(const lng:AnsiString):boolean;
function TLOpenBase (inmemory:boolean=false):boolean;
function TLSaveBase (const fname:AnsiString=''):boolean;
function TLCloseBase(dosave:boolean):boolean;
{
function CopyToBase  (const data:TTL2Translation; withRef:boolean):integer;
function LoadFromBase(var   data:TTL2Translation;
    const amod:Int64; const lang:AnsiString):integer;
}

const
  rfIsSkill     = $0001;
  rfIsTranslate = $0002;
  rfIsDeleted   = $0004;
  rfIsItem      = $0008;
  rfIsMob       = $0010;
  rfIsProp      = $0020;
  rfIsPlayer    = $0040;

  rfIsFiltered  = $0100; // runtime, folder filter flag
  rfIsManyRefs  = $0200; // runtime, mod-limited flag
  rfIsNoRef     = $0400; // runtime, no refs for line
  rfIsModified  = $0800; // runtime, dst or part changed

  rfIsUnique    = $2000; // runtime, line is unique for mod
  rfIsAutofill  = $1000; // runtime, autofilled or filter used by similar search
  rfIsReferred  = $8000;
//  rfRuntime     = rfIsFiltered or rfIsManyRefs or rfIsNoRef or rfIsModified or rfIsAutofill;
  rfRuntime     = rfIsModified or rfIsAutofill;


{set rfIsFiltered flag for cached elements placed in "afilter" and child directory}
function CheckForDirectory(const afilter:string):integer;                

function FillAllSimilars(const alang:AnsiString):integer;
function FillSimilars   (const adst, alang:AnsiString; fltid:integer):integer;
function GetSimilarCount(aid:integer):integer;
// refs ids of similar text
function GetSimilars    (aid:integer; var arr:TIntegerDynArray):integer;
// refs ids with same text
function GetDoubles     (aid:integer; var arr:TIntegerDynArray):integer;
// refs ids with same dir/file/tag
function GetAlts        (aid:integer; var arr:TIntegerDynArray):integer;
function GetUnrefLineCount(adeleted:boolean=false):integer;

// aid is source index
function FindOriginal(const asrc:AnsiString):integer;
function AddOriginal (const asrc:AnsiString; afilter:Pinteger=nil):integer;
function GetOriginal    (aid:integer):AnsiString;
function ChangeOriginal (const asrc,anew:AnsiString):boolean;
function ChangeOriginal (aid:integer; const anew:AnsiString):boolean;
function DeleteOriginal (aid:integer):boolean; // mark as deleted, remove translation
function RemoveOriginal (aid:integer):boolean; // remove from base
function RestoreOriginal(aid:integer; unique:boolean=false):boolean;

function AddText(const asrc,alang,adst:AnsiString; apart:boolean):integer;
function GetText        (aid:integer; const atable:AnsiString; var asrc,adst:AnsiString):boolean;
function GetTranslation (aid:integer; const atable:AnsiString; var      adst:Ansistring):boolean;
function SetTranslation (aid:integer; const atable:AnsiString;
   const adst:Ansistring; apart:boolean):integer;
function GetLineFlags   (aid:integer; const amodid:AnsiString):cardinal;
function IsLineUnique   (aid:integer):boolean;
function GetLineRef     (aid:integer):integer;
function GetLineRefCount(aid:integer):integer;

const
  lrMod  = 1;
  lrDir  = 2;
  lrFile = 3;
  lrTag  = 4;

function GetLineRefList (aid:integer; var arr:array of AnsiString; atype:integer):integer;
// get reference info. aid is refs index, result is source index
function GetRef   (arefid:integer; out adir,afile,atag:AnsiString; out aline,aflags:integer):integer;
function GetRefMod(arefid:integer):Int64;
function GetRefSrc(arefid:integer):integer;
function GetRefPlaceCount(arefid:integer; const amodid:Int64=modAll):integer;

type
  TModStatistic = record
    modid  :Int64;
    total  :integer;
    dupes  :integer;
    unique :integer;
    nation :integer;
    deleted:integer;
    files  :integer;
    tags   :integer;
    langs:array of record
      lang :AnsiString;
      trans:integer;
      part :integer;
    end;
  end;

//modid field must be set before call
function  GetModStatistic(var stat:TModStatistic):integer;
function  SetModStatistic(const amodid:Int64):integer;
procedure GetModList    (    asl:TStrings       ; all:boolean=true);
procedure GetModList    (var asl:TDict64DynArray; all:boolean=true);
function  GetLangList   (var asl:TDictDynArray):integer;
function  GetDeletedList(var arr:TDictDynArray; unique:boolean=false):integer;


{get mod's directory list}
function GetModDirList(const amodid:Int64; var alist:TStringDynArray):integer;
function AddMod       (const amodid:Int64; const atitle:AnsiString  ):integer;
function AddMod       (const amodid:Int64;       atitle:PUnicodeChar):integer;
function DeleteMod    (const amodid:Int64):boolean;
function GetModName   (const amodid:Int64):AnsiString;
function GetModByName (const atitle:AnsiString):Int64;
function GetLineCount      (const amodid:Int64; withdeleted:boolean=false):integer;
function GetUniqueLineCount(const amodid:Int64):integer;
function GetNationLineCount(const amodid:Int64):integer;

procedure CacheSrcId(const amodid:Int64);


implementation

uses
  SysUtils,
  iso639,
  sqlite3dyn,
  sqlitedb,
  tl2text,
  rgtrans,
  tlscan;

// same as tlscan
const
  sBeginFile   = '[TRANSLATIONS]';
  sEndFile     = '[/TRANSLATIONS]';
  sBeginBlock  = '[TRANSLATION]';
  sEndBlock    = '[/TRANSLATION]';
  sOriginal    = '<STRING>ORIGINAL:';
  sTranslated  = '<STRING>TRANSLATION:';

var
  lastmodid:Int64;

resourcestring
  rsAllStrings   = '- All strings -';
  rsOriginalGame = '-- Original game --';
  rsNoRef        = '-- No refs --';


procedure CacheSrcId(const amodid:Int64);
var
  lmod:AnsiString;
begin
  if (lastmodid<>amodid) or (lastmodid=modList) then
  begin
    lastmodid:=amodid;

    ExecuteDirect(tldb,'DROP TABLE tmpref');
    ExecuteDirect(tldb,'CREATE TEMP TABLE tmpref (srcid INTEGER PRIMARY KEY)');

    if amodid=modUnref then
    begin
      ExecuteDirect(tldb,
        'INSERT INTO tmpref '+
        ' SELECT strings.id FROM strings'+
        ' LEFT JOIN refs ON refs.srcid=strings.id'+
        ' WHERE refs.srcid IS NULL AND strings.deleted=0');
    end
    else
    begin
      if amodid=modAll then
        lmod:=''
      else if amodid=modList then
        lmod:=' AND refs.modid IN tmpmods' //!! AND
      else
      begin
        Str(amodid,lmod);
        lmod:=' WHERE refs.modid='+lmod; //!! AND
      end;
      ExecuteDirect(tldb,
        'INSERT INTO tmpref SELECT distinct strings.id FROM strings'+
        ' INNER JOIN refs ON strings.id=refs.srcid AND strings.deleted=0'+lmod);
//        'INSERT INTO tmpref SELECT distinct refs.srcid FROM refs'+
//        ' JOIN strings ON strings.id=refs.srcid AND strings.deleted=0'+lmod);
    end;
  end;
end;

function CheckName(const atable:AnsiString):AnsiString;
begin
  if (Length(atable)>6) and (
     (atable[1] in ['T','t']) and
     (atable[2] in ['R','r']) and
     (atable[3] in ['A','a']) and
     (atable[4] in ['N','n']) and
     (atable[5] in ['S','s']) and
     (atable[6] = '_') ) then
    result:='['+atable+']'
  else
    result:='[trans_'+atable+']';
end;

function AddToList(const atable,avalue:AnsiString):integer;
var
  vm:pointer;
  pc:PAnsiChar;
  lSQL:AnsiString;
begin
  // not sure about root dir
  if avalue='' then exit(0);
{$IFNDEF UseUniqueText}
  result:=ReturnInt(tldb,'SELECT id FROM '+atable+' WHERE (value=?1)',PAnsiChar(avalue));
  if result<0 then
{$ENDIF}
  begin
    result:=-1;
    lSQL:='INSERT INTO '+atable+' (value) VALUES (?1) RETURNING id;';
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL), -1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_bind_text(vm,1,PAnsiChar(avalue),-1,SQLITE_STATIC)=SQLITE_OK then
      begin
        if sqlite3_step(vm)=SQLITE_ROW then
        begin
          result:=sqlite3_column_int(vm,0);

          pc:=sqlite3_expanded_sql(vm);
          SQLog.Add(pc);
          sqlite3_free(pc);
        end;
      end;
      sqlite3_finalize(vm);
    end;
  end;
{$IFDEF UseUniqueText}
  if result<0 then
    result:=ReturnInt(tldb,'SELECT id FROM '+atable+' WHERE (value=?1)',PAnsiChar(avalue));
{$ENDIF}
end;

{%REGION Mod}
function DeleteMod(const amodid:Int64):boolean;
var
  ls,lmod:AnsiString;
begin
  str(amodid,lmod);

  // delete mod record
  ls:='DELETE FROM dicmods WHERE id='+lmod;
  result:=ExecuteDirect(tldb,ls);
  if not result then exit;
  SQLog.Add(ls);

  // delete unique strings
  //!!!! think about translations!!!
  ls:=
    'UPDATE strings SET deleted=2'+
//    'DELETE FROM strings'+
    ' WHERE (deleted=0) AND id IN'+
    ' (SELECT DISTINCT r.srcid FROM refs r'+
    '   LEFT JOIN (SELECT DISTINCT r.srcid FROM refs r WHERE r.modid<>'+lmod+') r1'+
    '   ON r.srcid=r1.srcid'+
    '   WHERE r.modid='+lmod+' AND r1.srcid IS NULL)';

  result:=ExecuteDirect(tldb,ls);
  if result then SQLog.Add(ls);

  // remove references
  ls:='DELETE FROM refs WHERE modid='+lmod;
  result:=ExecuteDirect(tldb,ls);
  if result then SQLog.Add(ls);

  // remove mod statistic
  ls:='DELETE FROM statistic WHERE modid='+lmod;
  result:=ExecuteDirect(tldb,ls);
  if result then SQLog.Add(ls);
end;

function AddModInternal(const amodid:Int64; atitle:PAnsiChar):integer;
var
  vm:pointer;
  ls:AnsiString;
  pc:PAnsiChar;
begin
  result:=-1;
  if (amodid=modAll) or (atitle=nil) or (atitle^=#0) then exit;

  Str(amodid,ls);
  result:=ReturnInt(tldb,'SELECT 1 FROM dicmods WHERE id='+ls);

  if result<1 then
  begin
    ls:='INSERT INTO dicmods (id, value) VALUES ('+ls+', ?1)';

    if sqlite3_prepare_v2(tldb, PAnsiChar(ls), -1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_bind_text(vm,1,atitle,-1,SQLITE_STATIC)=SQLITE_OK then
      begin
        if sqlite3_step(vm)=SQLITE_DONE then
        begin
          pc:=sqlite3_expanded_sql(vm);
          SQLog.Add(pc);
          sqlite3_free(pc);
         result:=0;
        end;
      end;
      sqlite3_finalize(vm);
    end;

    result:=0;
  end;
end;

function AddMod(const amodid:Int64; const atitle:AnsiString):integer;
begin
  result:=AddModInternal(amodid,PAnsiChar(atitle));
end;

function AddMod(const amodid:Int64; atitle:PUnicodeChar):integer;
begin
  result:=AddModInternal(amodid,PAnsiChar(WideToStr(atitle)));
end;

function GetModName(const amodid:Int64):AnsiString;
var
  ls:string;
begin
  Str(amodid,ls);
  result:=ReturnText(tldb,'SELECT value FROM dicmods WHERE id='+ls);
end;

function GetModByName(const atitle:AnsiString):Int64;
var
  lSQL:AnsiString;
  vm:pointer;
begin
  if atitle='' then exit(0);

  result:=-1;
  if tldb<>nil then
  begin
    lSQL:='SELECT id FROM dicmods WHERE value LIKE ?1';
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_bind_text(vm,1,PAnsiChar(atitle),-1,SQLITE_STATIC)=SQLITE_OK then
      begin
        if sqlite3_step(vm)=SQLITE_ROW then
          result:=sqlite3_column_int64(vm,0);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure GetModList(asl:TStrings; all:boolean=true);
var
  vm:pointer;
  i:integer;
begin
  asl.Clear;
  if ReturnInt(tldb,'SELECT count(1) FROM strings')>0 then
  begin
    if all then
    begin
      asl.Add(rsAllStrings);
      asl.Add(rsOriginalGame);
      asl.Add(rsNoRef);
    end;

    i:=ReturnInt(tldb,'SELECT count(1) FROM dicmods');
    if i>0 then
    begin
      if sqlite3_prepare_v2(tldb,'SELECT id, value FROM dicmods',-1, @vm, nil)=SQLITE_OK then
      begin
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          if all and (sqlite3_column_int64(vm,0)=0) then continue;
          asl.Add(sqlite3_column_text(vm,1));
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end;
end;

procedure GetModList(var asl:TDict64DynArray; all:boolean=true);
var
  lid:Int64;
  vm:pointer;
  i:integer;
begin
  //!! return i=1 (modid=0) if DB is busy
  i:=ReturnInt(tldb,'SELECT count(1) FROM dicmods');
  if i>0 then
  begin
    if all then
    begin
      SetLength(asl,i+2);
      i:=3;
      asl[0].id   :=modAll;
      asl[0].value:=rsAllStrings;
      asl[1].id   :=modVanilla;
      asl[1].value:=rsOriginalGame;
      asl[2].id   :=modUnRef;
      asl[2].value:=rsNoRef;
    end
    else
    begin
      if i<2 then exit;
      SetLength(asl,i);
      i:=0;
    end;

    if sqlite3_prepare_v2(tldb,'SELECT id,value FROM dicmods',-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        lid:=sqlite3_column_int64(vm,0);
        if all and (lid=0) then continue;
        asl[i].id   :=lid;
        asl[i].value:=sqlite3_column_text (vm,1);
        inc(i);
      end;
      sqlite3_finalize(vm);
    end;
  end
  else
    SetLength(asl,0);
end;

function GetLangList(var asl:TDictDynArray):integer;
var
  vm:pointer;
  ls:string;
  i:integer;
begin
  asl:=nil;
  result:=ReturnInt(tldb,'SELECT count(1) FROM sqlite_master'+
      ' WHERE (type = ''table'') AND (name GLOB ''trans_*'')');
  if result>0 then
  begin
    ls:='SELECT name FROM sqlite_master'+
        ' WHERE (type = ''table'') AND (name GLOB ''trans_*'')'+
        ' ORDER BY name';

    if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
    begin
      SetLength(asl,result);
      i:=0;
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        ls:=sqlite3_column_text(vm,0);
        asl[i].id   :=ReturnInt(tldb,'SELECT count(1) FROM ['+ls+']');
        asl[i].value:=Copy(ls,7);
        inc(i);
      end;
      sqlite3_finalize(vm);
      exit;
    end;
  end;
  SetLength(asl,0);
end;

function GetDeletedList(var arr:TDictDynArray; unique:boolean=false):integer;
var
  vm:pointer;
  lSQL:AnsiString;
  i:integer;
begin
  if unique then
    result:=ReturnInt(tldb,'SELECT count(id) FROM strings WHERE deleted=2')
  else
    result:=ReturnInt(tldb,'SELECT count(id) FROM strings WHERE deleted=1');
  if result>0 then
  begin
    if unique then
      lSQL:='SELECT id, src FROM strings WHERE deleted=2'
    else
      lSQL:='SELECT id, src FROM strings WHERE deleted=1';
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      SetLength(arr,result);
      i:=0;
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        arr[i].id   :=sqlite3_column_int (vm,0);
        arr[i].value:=sqlite3_column_text(vm,1);
        inc(i);
      end;
      sqlite3_finalize(vm);
      exit;
    end;
  end;
  SetLength(arr,0);
end;

function GetUnrefLineCount(adeleted:boolean=false):integer;
begin
  result:=ReturnInt(tldb,
//    'SELECT count(id) FROM strings WHERE NOT (id IN (SELECT DISTINCT srcid FROM refs))');
    'SELECT count(strings.id) FROM strings'+
    ' LEFT JOIN refs ON refs.srcid=strings.id'+
    ' WHERE refs.srcid IS NULL AND strings.deleted='+BoolNumber[adeleted]);
end;

function GetDeletedLineCount(const amodid:Int64):integer;
var
  ls,lmod:AnsiString;
begin
  if amodid=modAll then
    ls:='SELECT count(1) FROM strings WHERE deleted=1'
  else if amodid=modUnref then
    exit(GetUnrefLineCount(true))
  else
  begin
    Str(amodid,lmod);
    ls:='SELECT count(distinct s.id) FROM strings s'+
        ' WHERE s.deleted=1 AND'+
        '   EXISTS (SELECT 1 FROM refs WHERE s.id=refs.srcid and refs.modid='+lmod+')';
  end;
  result:=ReturnInt(tldb,ls);
end;

function GetLineCount(const amodid:Int64; withdeleted:boolean=false):integer;
var
  lmod:AnsiString;
begin
       if amodid=modUnref   then result:=GetUnrefLineCount()
  else if amodid=modAll     then
  begin
    if withdeleted then result:=ReturnInt(tldb,'SELECT count(1) FROM strings')
    else                result:=ReturnInt(tldb,'SELECT count(1) FROM strings WHERE deleted=0');
  end
  else
  begin
    if amodid=modList then
      lmod:=' IN tmpmods'
    else
    begin
      Str(amodid,lmod);
      lmod:='='+lmod;
    end;

    if withdeleted then
      result:=ReturnInt(tldb,'SELECT count(DISTINCT srcid) FROM refs WHERE modid'+lmod)
    else
    begin
      result:=ReturnInt(tldb,
        'SELECT count(1) FROM strings s'+
        ' WHERE s.deleted=0 AND'+
        ' EXISTS (SELECT 1 FROM refs WHERE refs.modid'+lmod+' AND s.id=refs.srcid)');
    end;
  end;
end;

function GetNationLineCount(const amodid:Int64):integer;
var
  ls,lwhere:AnsiString;
begin
  if amodid=modAll then
  begin
    ls    :='';
    lwhere:='';
  end
  else if amodid=modUnref then
  begin
    ls    :=' LEFT JOIN refs ON refs.srcid=s.id';
    lwhere:='AND refs.srcid IS NULL';
  end
  else
  begin
    Str(amodid,ls);
    ls    :=' INNER JOIN refs ON refs.modid='+ls+' AND refs.srcid=s.id';
    lwhere:='';
  end;
  ls:='SELECT count(DISTINCT s.id) FROM strings s'+ls+
      ' WHERE s.deleted=0'+lwhere+
      ' AND s.src GLOB concat(''*['',char(128),''-'',char(65535),'']*'')';
  result:=ReturnInt(tldb,ls);
end;

function IsLineUnique(aid:integer):boolean;
var
  ls:AnsiString;
begin
  if CurMod=modAll then exit(false);

  Str(CurMod,ls);
  result:=ReturnInt(tldb,
    'SELECT count(DISTINCT srcid) FROM refs'+
    ' WHERE modid<>'+ls+' AND srcid='+IntToStr(aid))=0;
end;

function GetUniqueLineCount(const amodid:Int64):integer;
var
  ls:AnsiString;
begin
  if amodid=modAll   then exit(0);
  if amodid=modUnref then exit(GetUnrefLineCount());

  Str(amodid,ls);

  ls:='WITH UniRefs AS (SELECT DISTINCT srcid,modid FROM refs)'+
      'SELECT count(r1.srcid) FROM UniRefs r1 WHERE r1.modid='+ls+
      ' AND NOT EXISTS (SELECT 1 FROM Refs r2 WHERE r1.srcid=r2.srcid AND r2.modid<>'+ls+')';
{
  ls:='SELECT COUNT(distinct r.srcid) FROM refs r'+
      ' WHERE r.modid='+ls+' AND NOT EXISTS ('+
      '  SELECT 1 FROM refs r2 WHERE r2.srcid=r.srcid AND r2.modid<>'+ls+')';
}
{
  ls:='SELECT count(distinct r.srcid) AS cnt'+
      ' FROM (SELECT t.srcid'+
      '   FROM (SELECT DISTINCT srcid, modid FROM refs) t'+
      ' GROUP BY t.srcid HAVING count(1) = 1) s'+
      ' JOIN refs r ON r.srcid = s.srcid'+
      ' WHERE r.modid='+ls;
}  
  result:=ReturnInt(tldb,ls);
end;

function GetUniqueLineCountCached(const amodid:Int64):integer;
var
  ls:AnsiString;
begin
  if amodid=modAll   then exit(0);
  if amodid=modUnref then ls:='SELECT count(1) FROM tmpref'
  else
  begin
    Str(amodid,ls);
    ls:='SELECT count(r1.srcid) FROM tmpref r1'+
        ' WHERE NOT EXISTS (SELECT 1 FROM Refs r2 WHERE r1.srcid=r2.srcid AND r2.modid<>'+ls+')';
  end;
  result:=ReturnInt(tldb,ls);
end;

function SetModStatistic(const amodid:Int64):integer;
var
  vm:pointer;
  ls,lmod:AnsiString;
begin
  result:=0;
  if amodid=modUnref then exit;

  if amodid<>modAll then
  begin
    Str(amodid,lmod);
    ls:=' WHERE modid='+lmod;
  end
  else
    ls:='';

  ls:='SELECT count(srcid), count(DISTINCT srcid), count(DISTINCT file), '+
      ' count(DISTINCT tag) FROM refs'+ls;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      if amodid=modAll then lmod:='-1';
      result:=sqlite3_column_int(vm,1);
      ls:='REPLACE INTO statistic (modid, lines, differs, files, tags, nation)'+
        ' VALUES ('+lmod+
        ','+IntToStr(sqlite3_column_int(vm,0))+
        ','+IntToStr(result)+
        ','+IntToStr(sqlite3_column_int(vm,2))+
        ','+IntToStr(sqlite3_column_int(vm,3))+
        ','+IntToStr(GetNationLineCount(amodid))+
        ');';
      ExecuteDirect(tldb,ls);
    end;
    sqlite3_finalize(vm);
  end;
end;

function GetModStatistic(var stat:TModStatistic):integer;
var
  lmodid:Int64;
  vm,vml:pointer;
  llist:TDictDynArray;
  lmod,ls:AnsiString;
  i:integer;
begin
  result:=0;

  lmodid:=stat.modid;

  SetLength(stat.langs,0);
  FillChar(stat,SizeOf(stat),0);
  stat.modid:=lmodid;

//uprof.Start('Cache');
  CacheSrcId(lmodid);
//uprof.Stop;

//uprof.Start('Stat');
  Str(lmodid,lmod);
  ls:='SELECT lines, differs, files, tags, nation FROM statistic'+
      ' WHERE modid='+lmod;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      stat.total :=sqlite3_column_int(vm,0);
      stat.dupes :=stat.total-sqlite3_column_int(vm,1);
      stat.files :=sqlite3_column_int(vm,2);
      stat.tags  :=sqlite3_column_int(vm,3);
      stat.nation:=sqlite3_column_int(vm,4);
    end
    else
    begin
      sqlite3_finalize(vm);

      SetModStatistic(lmodid);
      GetModStatistic(stat);
      exit;
    end;

    sqlite3_finalize(vm);
  end;
  stat.unique:=GetUniqueLineCountCached(stat.modid);

  if lmodid=modUnref then
    stat.total:=stat.unique;

  stat.deleted:=GetDeletedLineCount(stat.modid);
//uprof.Stop;

  result:=GetLangList(llist);
  if result=0 then exit;

  SetLength(stat.langs,result);
//uprof.Start('Langs');
  for i:=0 to result-1 do
  begin
    ls:='SELECT count(t.srcid), sum(t.part) FROM [trans_'+llist[i].value+
        '] t INNER JOIN tmpref ON t.srcid=tmpref.srcid';
    if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vml, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vml)=SQLITE_ROW then
      begin
        stat.langs[i].lang :=llist[i].value;
        stat.langs[i].trans:=sqlite3_column_int(vml,0);
        stat.langs[i].part :=sqlite3_column_int(vml,1);
      end;
      sqlite3_finalize(vml);
    end;
  end;
//uprof.Stop;
  SetLength(llist,0);
end;
{%ENDREGION Mod}

{%REGION Additional}
function RemakeFilter():boolean;
var
  vm: Pointer;
  lSQL,lsrc,lid,ls,lsold:AnsiString;
//  i,flid:integer;
  lsrcid:integer;
begin
  result:=true;

  ExecuteDirect(tldb,'DROP TABLE filter');
  result:=ExecuteDirect(tldb,
      'CREATE TABLE filter ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  value  TEXT UNIQUE);');

  lSQL:='SELECT id, src FROM strings';
  lsold:='';
  lid  :='0';
  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
//    i:=1;
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      lsrcid:=sqlite3_column_int (vm,0);
      lsrc  :=sqlite3_column_text(vm,1);

      ls:=FilteredString(lsrc);
      if lsold<>ls then
      begin
        lsold:=ls;
{
        // variant without autoincrement key
        flid:=ReturnInt(tldb,'INSERT INTO filter (id,value) VALUES ('+
          IntToStr(i)+',?1) RETURNING id;',PAnsiChar(ls));
        if flid<0 then
          flid:=ReturnInt(tldb,'SELECT id FROM filter WHERE (value=?1)',PAnsiChar(ls))
        else
          inc(i);
        Str(flid,lid);
}
        // variant with autoincrement key
        Str(AddToList('filter',ls),lid);
      end;

      ExecuteDirect(tldb,'UPDATE strings SET filter='+lid+
        ' WHERE id='+IntToStr(lsrcid));
    end;
    sqlite3_finalize(vm);
  end;

  lsold:=ReturnText(tldb,'SELECT value FROM settings WHERE setting=''filter''');
  ls   :=GetFilterWords();
  if ls<>lsold then
  begin
    ExecuteDirect(tldb,'UPDATE settings SET value=?1 WHERE setting=''filter''',PAnsiChar(ls));
    ExecuteDirect(tldb,'UPDATE settings SET value=unixepoch() WHERE setting=''filterchange''');
  end;
  ExecuteDirect(tldb,'UPDATE settings SET value=unixepoch() WHERE setting=''filtertime''');
end;

function GetFilterId(aid:integer):integer;
var
  vm:pointer;
  lSQL,lid:AnsiString;
begin
  result:=0;
  Str(aid,lid);

  lSQL:='SELECT filter FROM strings WHERE id='+lid;
  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      result:=sqlite3_column_int(vm,0)
    else
    begin
      RemakeFilter();
      sqlite3_reset(vm);
      if sqlite3_step(vm)=SQLITE_ROW then
        result:=sqlite3_column_int(vm,0);
    end;
    sqlite3_finalize(vm);
  end;
{
  result:=ReturnInt(tldb,'SELECT filter FROM strings WHERE id='+lid);
  if result<0 then
  begin
    RemakeFilter();
    result:=ReturnInt(tldb,'SELECT filter FROM strings WHERE id='+lid);
  end;
}
end;

function FillAllSimilars(const alang:AnsiString):integer;
var
  vm:pointer;
  llang,ls:AnsiString;
begin
  result:=0;
  if alang='' then llang:=CurLang else llang:=alang;

  ls:=CheckName(CurLang);
  ls:='SELECT s.id, s.src, tmp.dst FROM strings s,'+
      ' (SELECT s.filter, t1.dst FROM strings s'+
      '  JOIN '+ls+' t1 ON s.id=t1.srcid GROUP BY s.filter) tmp'+
      ' LEFT JOIN '+ls+' t ON s.id=t.srcid'+
      ' WHERE t.srcid IS NULL AND s.filter=tmp.filter';
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      ls:=ReplaceTranslation(
          sqlite3_column_text(vm,2),
          sqlite3_column_text(vm,1));
      SetTranslation(sqlite3_column_int(vm,0),llang,ls,true);
      inc(result);
    end;
    sqlite3_finalize(vm);
  end;
end;

function FillSimilars(const adst, alang:AnsiString; fltid:integer):integer;
var
  vm:pointer;
  llang,ls:AnsiString;
  lid,i:integer;
begin
  result:=0;
  if adst='' then exit;
  if alang='' then llang:=CurLang else llang:=alang;

  ls:='SELECT s.id, s.src FROM strings s'+
      ' LEFT JOIN '+CheckName(CurLang)+' t ON s.id=t.srcid'+
      ' WHERE t.srcid IS NULL AND s.filter='+IntToStr(fltid);
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      lid :=sqlite3_column_int (vm,0);
      // avoid check cached (what if we want to keep empty or manual?)
      for i:=0 to High(TRCache) do
      begin
        if TRCache[i].id=lid then
        begin
          lid:=-1;
          break;
        end;
      end;
      if lid<0 then continue;

      ls:=ReplaceTranslation(PAnsiChar(adst),sqlite3_column_text(vm,1));
      SetTranslation(lid,llang,ls,true);
      inc(result);
    end;
    sqlite3_finalize(vm);
  end;
end;

// Mod limited must be
function GetSimilarCount(aid:integer):integer;
var
  lf:AnsiString;
begin
  result:=GetFilterId(aid);

  if result>0 then
  begin
    Str(result,lf);
    result:=ReturnInt(tldb,'SELECT count(id) FROM strings WHERE filter='+lf)-1;
  end;

  if result<0 then
    result:=0
end;

function GetSimilars(aid:integer; var arr:TIntegerDynArray):integer;
var
  vm:pointer;
  lSQL,lid,lf:AnsiString;
  i:integer;
begin
  result:=GetFilterId(aid);
  if result>0 then
  begin
    Str(result,lf);
    result:=ReturnInt(tldb,'SELECT count(id) FROM strings WHERE filter='+lf)-1;
    if result>0 then
    begin
      Str(aid,lid);
      lSQL:='SELECT id FROM strings WHERE filter='+lf+' AND id<>'+lid;
      if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        SetLength(arr,result);
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          arr[i]:=sqlite3_column_int(vm,0);
          inc(i);
        end;
        sqlite3_finalize(vm);
        exit;
      end;
    end;
  end;
  SetLength(arr,0);
end;

function GetDoubles(aid:integer; var arr:TIntegerDynArray):integer;
var
  vm:pointer;
  lSQL,lid,lmod:AnsiString;
  lcnt:integer;
begin
  result:=0;

  Str(aid,lid);
  if CurMod<>modAll then
  begin
    Str(CurMod,lmod);
    lmod:=' AND modid='+lmod;
  end
  else
    lmod:='';

  lcnt:=ReturnInt(tldb,'SELECT count(DISTINCT id) FROM refs WHERE srcid='+lid+lmod);
  if lcnt>0 then
  begin
    lSQL:='SELECT DISTINCT id FROM refs WHERE srcid='+lid+lmod;
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      SetLength(arr,lcnt);
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        arr[result]:=sqlite3_column_int(vm,0);
        inc(result);
      end;
      sqlite3_finalize(vm);
      exit;
    end;
  end;
  SetLength(arr,0);
end;

function GetRefPlaceCount(arefid:integer; const amodid:Int64=modAll):integer;
var
  vm:pointer;
  ls,lmod:AnsiString;
  ldir,lfile,ltag:integer;
begin
  if amodid<>modAll then
  begin
    Str(amodid,lmod);
    lmod:=' AND modid='+lmod;
  end
  else
    lmod:='';

  ls:='SELECT dir, file, tag FROM refs WHERE id='+IntToStr(arefid)+lmod;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      ldir :=sqlite3_column_int(vm,0);
      lfile:=sqlite3_column_int(vm,1);
      ltag :=sqlite3_column_int(vm,2);
    end;
    sqlite3_finalize(vm);
  end;
  
  result:=ReturnInt(tldb,
      'SELECT count(1) FROM refs'+
      ' WHERE dir ='+IntToStr(ldir )+
      '   AND file='+IntToStr(lfile)+
      '   AND tag ='+IntToStr(ltag )+
      lmod);
end;

function GetAlts(aid:integer; var arr:TIntegerDynArray):integer;
var
  vm:pointer;
  ls:AnsiString;
  lcnt:integer;
  lid,ldir,lfile,ltag:integer;
begin
  result:=0;
  Str(aid,ls);

  lid  :=0;
  ldir :=0;
  lfile:=0;
  ltag :=0;
  ls:='SELECT id, dir, file, tag FROM refs WHERE srcid='+ls;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      lid  :=sqlite3_column_int(vm,0);
      ldir :=sqlite3_column_int(vm,1);
      lfile:=sqlite3_column_int(vm,2);
      ltag :=sqlite3_column_int(vm,3);
    end;
    sqlite3_finalize(vm);
  end;

  if lid<>0 then
  begin
    ls:=' dir='+IntToStr(ldir)+' AND file='+IntToStr(lfile)+' AND tag='+IntToStr(ltag)+
        ' AND id<>'+IntToStr(lid);
    lcnt:=ReturnInt(tldb,'SELECT count(*) FROM refs WHERE'+ls);
    if lcnt>0 then
    begin
      ls:='SELECT id FROM refs WHERE'+ls;
      if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
      begin
        SetLength(arr,lcnt);
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          arr[result]:=sqlite3_column_int(vm,0);
          inc(result);
        end;
        sqlite3_finalize(vm);
        exit;
      end;
    end;
  end;
  SetLength(arr,0);
end;
{%ENDREGION Additional}

{%REGION Basic}
function GetOriginal(aid:integer):AnsiString;
begin
  result:=ReturnText(tldb,'SELECT src FROM strings WHERE id='+IntToStr(aid));
end;

function FindOriginal(const asrc:AnsiString):integer;
begin
  result:=ReturnInt(tldb,'SELECT id FROM strings WHERE (src=?1)',PAnsiChar(asrc));
end;

function AddOriginal(const asrc:AnsiString; afilter:Pinteger=nil):integer;
var
  vm:pointer;
  pc:PAnsiChar;
  ls:AnsiString;
  lfilter:integer;
begin
  result:=-1;

  ls:=FilteredString(asrc);
  if ls='' then exit;
  
{$IFNDEF UseUniqueText}
  result:=FindOriginal(asrc);
//    result:=ReturnInt(tldb,'SELECT id FROM strings WHERE (src=?1)',asrc);

  if result<0 then
{$ENDIF}
  begin
    lfilter:=AddToList('filter',ls);
    Str(lfilter,ls);
    if afilter<>nil then afilter^:=lfilter;

    ls:='INSERT INTO strings (src,filter) VALUES (?1,'+ls+') RETURNING id;';
    if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_bind_text(vm,1,PAnsiChar(asrc),-1,SQLITE_STATIC)=SQLITE_OK then
      begin
        if sqlite3_step(vm)=SQLITE_ROW then
        begin
          result:=sqlite3_column_int(vm,0);

          pc:=sqlite3_expanded_sql(vm);
          SQLog.Add(pc);
          sqlite3_free(pc);
        end;
      end;
      sqlite3_finalize(vm);
    end;

{$IFDEF UseUniqueText}
    if result<0 then
      result:=FindOriginal(asrc);
{$ENDIF}
  end;
  // to restore Unique strings from lost mods
  RestoreOriginal(result,true);
end;

function DeleteOriginal(aid:integer):boolean;
var
  lSQL,lid:AnsiString;
  llist:TDictDynArray;
  i,lcnt:integer;
begin
  Str(aid,lid);
  lSQL:='UPDATE strings SET deleted=1 WHERE id='+lid;
  result:=ExecuteDirect(tldb,lSQL);
  if result then
  begin
    SQLog.Add(lSQL);

    // Delete translation from all language files
    llist:=nil;
    lcnt:=GetLangList(llist);
    for i:=0 to pred(lcnt) do
    begin
      lSQL:='DELETE FROM ['+llist[i].value+'] WHERE srcid='+lid;
      result:=ExecuteDirect(tldb,lSQL);
      if result then
        SQLog.Add(lSQL);
    end;
    SetLength(llist,0);
  end;
end;

function RestoreOriginal(aid:integer; unique:boolean=false):boolean;
var
  lSQL:AnsiString;
begin
  if unique then
    lSQL:=' AND deleted=2'
  else
    lSQL:=' AND deleted=1';
  lSQL:='UPDATE strings SET deleted=0 WHERE id='+IntToStr(aid)+lSQL;
  result:=ExecuteDirect(tldb,lSQL);
  if result then
    SQLog.Add(lSQL);
end;

function RemoveOriginal(aid:integer):boolean;
var
  llist:TDictDynArray;
  lSQL, lstrid:AnsiString;
  i,lcnt:integer;
begin
  Str(aid,lstrid);
  // remove text
  lSQL:='DELETE FROM strings WHERE id='+lstrid;
  result:=ExecuteDirect(tldb,lSQL);
  if result then
  begin
    SQLog.Add(lSQL);

{
  !! Here must be: change ALL mods (what used that string) statistic
     fill modlist by
    'SELECT distinct modid FROM refs WHERE refs.srcid='+lstrid
}

    // remove references
    lSQL:='DELETE FROM refs WHERE srcid='+lstrid;
    result:=ExecuteDirect(tldb,lSQL);
    if result then
      SQLog.Add(lSQL);
{
    for i:=0 to cnt do
      SetModStatistic(modlist[i].id);
}
    // remove translations
    lcnt:=GetLangList(llist);
    if lcnt=0 then exit;

    for i:=0 to lcnt-1 do
    begin
      ExecuteDirect(tldb,'DELETE FROM [trans_'+llist[i].value+'] WHERE srcid='+lstrid);
    end;
    SetLength(llist,0);

  end;
end;

function ChangeOriginal(const asrc,anew:AnsiString):boolean;
begin
  result:=ChangeOriginal(FindOriginal(asrc),anew);
end;

function ChangeOriginal(aid:integer; const anew:AnsiString):boolean;
begin
  if (aid>0) and (anew<>'') then
  begin
    result:=ExecuteDirect(tldb,'UPDATE strings SET src=?1 WHERE id='+IntToStr(aid),
        PAnsiChar(anew));
  end
  else
    result:=false;
end;

function GetTranslation(aid:integer; const atable:AnsiString; var adst:Ansistring):boolean;
var
  vm:pointer;
  lSQL,lsrc:AnsiString;
begin
  adst:='';
  result:=false;

  Str(aid,lsrc);
  lSQL:='SELECT dst, part FROM '+CheckName(atable)+' WHERE srcid='+lsrc;
  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      adst  :=sqlite3_column_text(vm,0);
      result:=sqlite3_column_int (vm,1)<>0;
    end;
    sqlite3_finalize(vm);
  end;

end;

function SetTranslation(aid:integer; const atable:AnsiString;
    const adst:Ansistring; apart:boolean):integer;
var
  vm: Pointer;
  lSQL,lsrc,ltable:AnsiString;
  pc:PAnsiChar;
  lstat:integer;
begin
  result:=aid;

  Str(aid,lsrc);
  ltable:=CheckName(atable);

  lstat:=ReturnInt(tldb,'SELECT part FROM '+ltable+' WHERE srcid='+lsrc);
  if lstat>=0 then
  begin
    if TransOp=da_skip then exit;
    if (lstat=0) and (TransOp=da_compare) then exit;

    if adst='' then
    begin
      lSQL:='DELETE FROM '+ltable+' WHERE srcid='+lsrc;
      ExecuteDirect(tldb,lSQL);
      SQLog.Add(lSQL);
      exit;
    end;

    lSQL:='UPDATE '+ltable+
          ' SET dst=?1, part='+BoolNumber[apart]+', changed=unixepoch()'+
          ' WHERE srcid='+lsrc;
  end
  else
  begin
    lSQL:='INSERT INTO '+ltable+' (srcid, dst, part, changed) VALUES ('+
           lsrc+', ?1, '+BoolNumber[apart]+', unixepoch());';
  end;

  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL), -1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_bind_text(vm,1,PAnsiChar(adst),-1,SQLITE_STATIC)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_DONE then
      begin
        pc:=sqlite3_expanded_sql(vm);
        SQLog.Add(pc);
        sqlite3_free(pc);
      end
      else
        result:=-1;
    end;
    sqlite3_finalize(vm);
  end;

end;

function AddText(const asrc,alang,adst:AnsiString; apart:boolean):integer;
var
  lfilter:integer;
begin
  result:=AddOriginal(asrc,@lfilter);

  if alang='' then exit;

  if (result>0) and (adst<>'') and (adst<>asrc) then
  begin
    SetTranslation(result, alang, adst, apart);
  end;
end;

function GetText(aid:integer; const atable:AnsiString; var asrc,adst:AnsiString):boolean;
begin
  asrc:=GetOriginal(aid);
  if asrc<>'' then
    result:=GetTranslation(aid,atable,adst)
  else
    result:=false;
end;
{%ENDREGION Basic}

function CheckForDirectory(const afilter:string):integer;
var
  vm:pointer;
  lSQL,lcond:string;
  i,lid:integer;
begin
  if afilter='' then
  begin
    result:=Length(TRCache);
    for i:=0 to High(TRCache) do
      TRCache[i].flags:=TRCache[i].flags or rfIsFiltered;
  end
  else
  begin
    result:=0;
    for i:=0 to High(TRCache) do
      TRCache[i].flags:=TRCache[i].flags and not rfIsFiltered;

         if afilter='MEDIA/'             then lcond:='=''MEDIA/'''
    else if afilter='MEDIA/SKILLS/'      then lcond:='=''MEDIA/SKILLS/'''
    else if afilter='MEDIA/UNITS/ITEMS/' then lcond:='=''MEDIA/UNITS/ITEMS/'''
    else                                      lcond:=' GLOB '''+afilter+'*''';
//    else                                 lcond:=' LIKE '''+afilter+'%''';

    if CurMod<>modAll then
    begin
      Str(CurMod,lSQL);
      lSQL:=' modid='+lSQL+' AND';
    end
    else
      lSQL:='';

    lSQL:='SELECT DISTINCT srcid FROM refs WHERE'+lSQL+
          ' dir IN (SELECT id FROM dicdirs WHERE value'+lcond+')';

    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        lid:=sqlite3_column_int(vm,0);
        for i:=0 to High(TRCache) do
        begin
          if TRCache[i].id=lid then
          begin
            TRCache[i].flags:=TRCache[i].flags or rfIsFiltered;
            break;
          end;
        end;
        inc(result);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function GetModDirList(const amodid:Int64; var alist:TStringDynArray):integer;
var
  vm:pointer;
  ls,lmod:string;
  lcnt:integer;
begin
  result:=0;

  if amodid<>modAll then
  begin
    Str(amodid,lmod);
    lmod:=' WHERE refs.modid='+lmod;
  end
  else
    lmod:='';

  lcnt:=ReturnInt(tldb,'SELECT count(DISTINCT dir) FROM refs'+lmod);
  if lcnt>0 then
  begin
    SetLength(alist,lcnt);

    ls:='SELECT value FROM dicdirs'+
        ' WHERE id IN (SELECT DISTINCT dir FROM refs'+lmod+')';
//        ' INNER JOIN (SELECT DISTINCT dir FROM refs'+lmod+') r ON r.dir=dicdirs.id';
    if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        alist[result]:=sqlite3_column_text(vm,0);
        inc(result);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function GetListInternal(aid:integer; var arr:array of AnsiString; adict,afield:AnsiString):integer;
var
  vm:pointer;
  ls:AnsiString;
  i:integer;
begin
  Str(aid,ls);
  ls:=' FROM refs r'+
      ' INNER JOIN '+adict+' d ON d.id=r.'+afield+
      ' WHERE r.srcid='+ls;

  result:=ReturnInt(tldb,'SELECT COUNT(DISTINCT d.value)'+ls);
  if result<4 then
  begin
    if result>0 then
    begin
      ls:='SELECT DISTINCT d.value'+ls+' LIMIT 3';
      if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          arr[i]:=sqlite3_column_text(vm,0);
          inc(i);
        end;
        sqlite3_finalize(vm);
        exit;
      end;
    end
    else
      result:=0;
  end;
end;

function GetLineRefList(aid:integer; var arr:array of AnsiString; atype:integer):integer;
begin
       if atype=lrMod  then result:=GetListInternal(aid,arr,'dicmods' ,'modid')
  else if atype=lrDir  then result:=GetListInternal(aid,arr,'dicdirs' ,'dir'  )
  else if atype=lrFile then result:=GetListInternal(aid,arr,'dicfiles','file' )
  else if atype=lrTag  then result:=GetListInternal(aid,arr,'dictags' ,'tag'  )
  else result:=0;
end;

function GetLineRef(aid:integer):integer;
var
  lid,lmod:AnsiString;
begin
//  if (TRCache[aidx].flags and (rfIsManyRefs or rfIsNoRef))<>0 then exit(0);

  Str(aid,lid);
  if CurMod<>modAll then
  begin
    Str(CurMod,lmod);
    lmod:=' AND modid='+lmod
  end
  else
    lmod:='';

  result:=ReturnInt(tldb,'SELECT id FROM refs WHERE srcid='+lid+lmod+' LIMIT 1');
end;

function GetLineRefCount(aid:integer):integer;
var
  vm:pointer;
  lid,lmod:AnsiString;
begin
//  if (TRCache[aidx].flags and (rfIsNoRef))<>0 then exit(0);

  Str(aid,lid);
  if CurMod<>modAll then
  begin
    Str(CurMod,lmod);
    lmod:=' AND modid='+lmod;
  end
  else
    lmod:='';

//  result:=ReturnInt(tldb,'SELECT count(1) FROM refs WHERE srcid='+lid+lmod);
  result:=0;
  lid:='SELECT count(id), count(distinct dir)=1 and count(distinct file)=1 FROM refs'+
      ' WHERE srcid='+lid+lmod;
  if sqlite3_prepare_v2(tldb, PAnsiChar(lid),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      result:=sqlite3_column_int(vm,0);
      if (result>1) and (sqlite3_column_int(vm,1)=1) then result:=-result;
    end;
    sqlite3_finalize(vm);
  end;

end;

function GetRefSrc(arefid:integer):integer;
begin
  result:=ReturnInt(tldb,'SELECT srcid FROM refs WHERE id='+IntToStr(arefid));
end;

function GetRefMod(arefid:integer):Int64;
var
  vm:pointer;
  ls:string;
begin
  result:=modAll;
  Str(arefid,ls);
  ls:='SELECT modid FROM refs WHERE id='+ls;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      result :=sqlite3_column_int64(vm,0);
    sqlite3_finalize(vm);
  end;
end;

function GetRef(arefid:integer;
    out adir,afile,atag:AnsiString; out aline,aflags:integer):integer;
var
  vm:pointer;
  lref,lSQL:AnsiString;
begin
  result:=-1;

  Str(arefid,lref);

  lSQL:='SELECT r.srcid, d.value, f.value, t.value, r.line, r.flags'+
        ' FROM refs r'+
        ' INNER JOIN dicdirs  d ON d.id=r.dir'+
        ' INNER JOIN dicfiles f ON f.id=r.file'+
        ' INNER JOIN dictags  t ON t.id=r.tag'+
        ' WHERE r.id='+lref;

  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      result :=sqlite3_column_int (vm,0);
      adir   :=sqlite3_column_text(vm,1);
      afile  :=sqlite3_column_text(vm,2);
      atag   :=sqlite3_column_text(vm,3);
      aline  :=sqlite3_column_int (vm,4);
      aflags :=sqlite3_column_int (vm,5);
    end;
    sqlite3_finalize(vm);
  end;

end;

function AddRef(asrc:integer; const amod:Int64;
    const afile,atag:AnsiString; aline:integer):integer;
var
  lsource,lSQL,lline,lmod,lsrc,ldir,lfile,ltag:AnsiString;
  lflag:integer;
begin
  result:=0;

  if afile='' then exit;

  lsource:=UpCase(afile);

  Str(asrc,lsrc);
  Str(AddToList('dicdirs' ,ExtractPath(lsource)), ldir);
  Str(AddToList('dicfiles',ExtractName(lsource)), lfile);
  Str(AddToList('dictags' ,atag                ), ltag);
  Str(amod,lmod);
  Str(ABS(aline),lline);

  if ReturnInt(tldb,
      'SELECT 1 FROM refs WHERE (srcid='+lsrc +') AND (modid='+lmod+
      ') AND (dir='+ldir+') AND (file='+lfile+') AND (tag='+ltag+
//      ')')<>1 then
      ') AND (line='+lline+')')<>1 then
  begin
    lflag:=0;
    if Pos('MEDIA/SKILLS/'        ,lsource)=1 then lflag:=lflag or rfIsSkill;
    if Pos('MEDIA/UNITS/ITEMS/'   ,lsource)=1 then lflag:=lflag or rfIsItem;
    if Pos('MEDIA/UNITS/MONSTERS/',lsource)=1 then lflag:=lflag or rfIsMob;
    if Pos('MEDIA/UNITS/PLAYERS/' ,lsource)=1 then lflag:=lflag or rfIsPlayer;
    if Pos('MEDIA/UNITS/PROPS/'   ,lsource)=1 then lflag:=lflag or rfIsProp;
    if aline<0                                then lflag:=lflag or rfIsTranslate;

    lSQL:='INSERT INTO refs (srcid, modid, dir, file, tag, line, flags) VALUES ('+
        lsrc+', '+lmod+', '+ldir+', '+lfile+', '+ltag+', '+lline+', '+IntToStr(lflag)+');';
    if ExecuteDirect(tldb,lSQL) then
      SQLog.Add(lSQL);
  end;
end;

{
function CopyToBase(const data:TTL2Translation; withRef:boolean):integer;
var
  lsrc,i,j,lref,lline:integer;
  lmod:Int64;
begin
  result:=0;
  if data.lang='' then exit;

  CreateLangTable(data.lang);
  if (data.ModID<>0) and (data.ModID<>-1) then
  begin
    AddToModList(data.ModID, data.ModTitle);
    lmod:=data.ModID;
  end
  else
  begin
    lmod:=GetModByName(data.ModTitle);
  end;

  for i:=0 to data.LineCount-1 do
  begin
    lsrc:=AddText(data.Line[i], data.lang,
      data.Trans[i],data.State[i]=stPartial);
    if lsrc>0 then
    begin
      inc(result);

      if withRef then
        for j:=0 to data.RefCount[i]-1 do
        begin
          lref:=data.refs[i,j];
          lline:=data.Refs.GetLine(lref);
          if (data.Refs.Flags[lref] and rfIsTranslate)<>0 then
            lline:=-lline;
          AddRef(lsrc, lmod,
          data.Refs.GetFile(lref),
          data.Refs.GetTag (lref),
          lline);
        end;
    end;
  end;
end;

function LoadFromBase(var data:TTL2Translation;
    const amod:Int64; const lang:AnsiString):integer;
var
  vm,vmref:pointer;
  lrfile,lrtag:AnsiString;
  ltable,lSQL,lsrc,ldst:AnsiString;
  lrflags,lrline,lref:integer;
  oldid,lsrcid,lid:integer;
  lpart:boolean;
begin
  result:=0;
  data.lang:=GetLang(lang);
  ltable:='trans_'+data.lang; // 'cache' translation table name

  // if Vanilla or mod only
  if amod<>-1 then
  begin
    oldid:=0;
    Str(amod,lsrc);
    lSQL:='SELECT srcid, dir+file, tag, line, flags FROM refs WHERE modid='+lsrc+' ORDER BY srcid';
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        // 1 - get refs info (with source id)
        lsrcid :=sqlite3_column_int (vm,0);
        lrfile :=sqlite3_column_text(vm,1);
        lrtag  :=sqlite3_column_text(vm,2);
        lrline :=sqlite3_column_int (vm,3);
        lrflags:=sqlite3_column_int (vm,4);
        // prepare refs
        lref:=data.Refs.NewRef(lrfile,lrtag,lrline);
        data.Refs.Flags[lref]:=lrflags;

        // 2 - process source just once
        if lsrcid<>oldid then
        begin
          oldid:=lsrcid;
          lsrc :=GetOriginal   (lsrcid);
          lpart:=GetTranslation(lsrcid,ltable,ldst);
          lid:=data.AddString(lsrc,ldst,'',lpart);
        end;

        // 3 - add refs (as double if needs)
        data.Refs.AddRef(lid,lref);
      end;
      sqlite3_finalize(vm);
    end;
  end
  // if want to get all
  else
  begin
    // 1 - going through full list
    lSQL:='SELECT id, src FROM strings';
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        lsrcid:=sqlite3_column_int (vm,0);
        lsrc  :=sqlite3_column_text(vm,1);
      end;
      // 2 - get line translation and add to our translation collection
      lpart:=GetTranslation(lsrcid,ltable,ldst);
      lid:=data.AddString(lsrc,ldst,'',lpart);
      // 3 - get refs for every line [if needs] (lazy to read all and search then)
      Str(lsrcid,lsrc);
      lSQL:='SELECT dir+file, tag, line, flags FROM refs WHERE srcid='+lsrc;
      if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vmref, nil)=SQLITE_OK then
      begin
        while sqlite3_step(vmref)=SQLITE_ROW do
        begin
          lrfile :=sqlite3_column_text(vm,0);
          lrtag  :=sqlite3_column_text(vm,1);
          lrline :=sqlite3_column_int (vm,2);
          lrflags:=sqlite3_column_int (vm,3);
          // prepare refs
          lref:=data.Refs.NewRef(lrfile,lrtag,lrline);
          data.Refs.Flags[lref]:=lrflags;

          data.Refs.AddRef(lid,lref);
        end;
        sqlite3_finalize(vmref);
      end;

      sqlite3_finalize(vm);
    end;
  end;
end;
}

{%REGION Scan and Load}
procedure AddScanMod(dummy:pointer; const mi:TTL2ModInfo);
begin
  CurMod:=mi.modid;
  AddMod(mi.modid,WideToStr(mi.title));
end;

function AddScanString(dummy:pointer; const astr, afile, atag:AnsiString; aline:integer):integer;
begin
  if Length(astr)<2 then exit(-1);

  result:=AddOriginal(astr);
  if result>0 then
    AddRef(result, CurMod, afile, atag, aline);
end;

function PrepareScanSQL():boolean;
begin
  result:=true;
  CurMod:=modVanilla;
  TLScan.DoAddModInfo:=TDoAddModInfo(MakeMethod(nil,@AddScanMod));
  TLScan.DoAddString :=TDoAddString (MakeMethod(nil,@AddScanString));
end;

function AddLoadString(const astr,afile,atag:pointer; isutf8:Boolean; aparam:pointer):integer;
var
  lstr,lfile,ltag:UTF8String;
begin
  result:=0;
  if isutf8 then
  begin
    lstr :=PUTF8Char(astr);
    lfile:=PUTF8Char(afile);
    ltag :=PUTF8Char(atag);
  end
  else
  begin
    lstr :=WideToStr(astr);
    lfile:=WideToStr(afile);
    ltag :=WideToStr(atag);
  end;

  if Length(lstr)<2 then exit(-1);

  result:=AddOriginal(lstr);
  if result>0 then
    AddRef(result, CurMod, lfile, ltag, 0);
end;

function AddLoadText(const astr,atrans:pointer; isutf8:Boolean; aparam:pointer):integer;
var
  lsrc,ldst:UTF8String;
begin
  result:=0;
  if isutf8 then
  begin
    lsrc:=PUTF8Char(astr);
    ldst:=PUTF8Char(atrans);
  end
  else
  begin
    lsrc:=WideToStr(astr);
    ldst:=WideToStr(atrans);
  end;

  if Length(lsrc)<2 then exit(-1);

  if AddText(lsrc,CurLang,ldst,false)>0 then
    result:=1
  else
    result:=0;
end;

function LoadTranslationToBase(const fname,alang:AnsiString):integer;
begin
  result:=0;
  CurLang:=alang;
  if CurLang<>'' then
  begin
    CreateLangTable(CurLang);
    result:=rgtrans.Load(fname,@AddLoadText,@AddLoadString);
  end;
end;

{%ENDREGION Scan and Load}

const
{
  lflags:='CASE WHEN r.flags IS NULL THEN '+IntToStr(rfIsNoRef)+' ELSE '+
          'max(r.flags&01)|max(r.flags&02)|max(r.flags&04)|max(r.flags&08)|'+
          'max(r.flags&10)|max(r.flags&20)|max(r.flags&40)|max(r.flags&80) END';
}
  LineFlags = 'COALESCE(max(r.flags&01)|max(r.flags&02)|max(r.flags&04)|max(r.flags&08)|'+
                       'max(r.flags&10)|max(r.flags&20)|max(r.flags&40)|max(r.flags&80),'+
                       {IntToStr(rfIsNoRef)+}'0x400)';

function GetLineFlags(aid:integer; const amodid:AnsiString):cardinal;
var
  vm:pointer;
  lSQL:AnsiString;
  lcnt:integer;
begin
//  if amodid='-2' then exit(rfIsNoRef);

  result:=0;
  if amodid<>'' then
    lSQL:=' AND modid='+amodid
  else
    lSQL:='';
  lSQL:='SELECT '+LineFlags+', count(1) FROM refs r WHERE srcid='+IntToStr(aid)+lSQL;

  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    result:=sqlite3_column_int(vm,0);
    if result<>rfIsNoRef then
    begin
      lcnt:=sqlite3_column_int(vm,1);
           if lcnt=1 then result:=result or rfIsReferred
      else if lcnt>1 then result:=result or rfIsManyRefs;
    end;

    sqlite3_finalize(vm);
  end;
end;

function LoadModData():integer;
var
  vm:pointer;
  i,lcnt:integer;
  lSQL,lmod:AnsiString;
begin
  result:=0;

  for i:=0 to High(TRCache) do
  begin
    with TRCache[i] do
    begin
      src:='';
      dst:='';
    end;
  end;
  SetLength(TRCache,0);

  lcnt:=GetLineCount(CurMod,false);
  SetLength(TRCache,lcnt);

  if CurMod=modAll then
  begin
    lmod:='';
  end
  else if CurMod=modUnref then
  begin
    lmod:=' AND r.modid IS NULL';
  end
  else
  begin
    Str(CurMod,lmod);
    lmod:=' AND r.modid='+lmod;
  end;

  lSQL:='SELECT s.id, s.src, s.filter, '+LineFlags+',count(1)'+
        ' FROM strings s'+
        ' LEFT JOIN refs r ON r.srcid=s.id'+
        ' WHERE s.deleted=0'+lmod+
        ' GROUP BY s.id';

//    CacheSrcId(CurMod);
  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      with TRCache[result] do
      begin
        id   :=sqlite3_column_int (vm,0);
        src  :=sqlite3_column_text(vm,1);
        tmpl :=sqlite3_column_int (vm,2);
        flags:=sqlite3_column_int (vm,3);
        if flags<>rfIsNoRef then
        begin
          lcnt:=sqlite3_column_int(vm,4);
               if lcnt=1 then flags:=flags or rfIsReferred
          else if lcnt>1 then flags:=flags or rfIsManyRefs;
        end;
      end;
      inc(result);
    end;
    sqlite3_finalize(vm);
  end;
end;

procedure LoadTranslation();
var
  vm:pointer;
  lSQL:AnsiString;
  i:integer;
begin
{
  for i:=0 to High(TRCache) do
    TRCache[i].part:=GetTRanslation(TRCache[i].id,CurLang,TRCache[i].dst);
}
  lSQL:='SELECT dst, part FROM '+CheckName(CurLang)+' WHERE srcid=?1';
  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    for i:=0 to High(TRCache) do
    begin
      sqlite3_reset(vm);
      if sqlite3_bind_int(vm,1,TRCache[i].id)=SQLITE_OK then
      begin
        if sqlite3_step(vm)=SQLITE_ROW then
        begin
          TRCache[i].dst :=sqlite3_column_text(vm,0);
          TRCache[i].part:=sqlite3_column_int (vm,1)<>0;
        end
        else
        begin
          TRCache[i].dst :='';
          TRCache[i].part:=false;
        end;
      end;
    end;
    sqlite3_finalize(vm);
  end;

end;

procedure SaveTranslation();
var
  i:integer;
  b:boolean;
begin
  b:=false;
  for i:=0 to High(TRCache) do
  begin
    with TRCache[i] do
    begin
           if (flags and rfIsDeleted )<>0 then begin b:=true; DeleteOriginal(id) end
      else if (flags and rfIsModified)<>0 then
      begin
        if (dst<>'') or (CurMod=modAll) then
        begin
          SetTranslation(id, CurLang, dst, part);
        // delete empty translation to avoid using as template for autofill
          flags:=flags and not rfRuntime;
        end;
      end;
    end;
  end;
  if CurMod<>modAll then
  begin
    FillAllSimilars(CurLang);
    // trying to delete translation again for case when they was autofilled
    for i:=0 to High(TRCache) do
    begin
      with TRCache[i] do
      begin
        if (flags and rfIsModified)<>0 then
          SetTranslation(id, CurLang, dst, part);
        flags:=flags and not rfRuntime;
      end;
    end;
  end;

  if b then
  begin
    SetModStatistic(CurMod);
    if CurMod<>modAll then SetModStatistic(modAll);
  end;
end;

function BuildTranslation(const afname:AnsiString; const alang:AnsiString='';
    apart:boolean=true; aall:boolean=false; const amodid:Int64=modAll):boolean;
var
  vm:pointer;
  sl:TStringList;
  ls,lt:AnsiString;
begin
  result:=false;
  if alang='' then ls:=CurLang else ls:=alang;
  if ls='' then exit;

  if aall then lt:=' LEFT JOIN ' else lt:=' INNER JOIN ';
  lt:=lt+CheckName(ls)+' t ON strings.id=t.srcid';
  if not apart then lt:=lt + ' AND t.part=0';

  // All mean 'with unref too'. "distinct" not necessary, strings.id are unique already
  if amodid=modAll then
  begin
    ls:='SELECT strings.src, t.dst FROM strings'+
        lt+' WHERE strings.deleted=0';
  end
  // Vanilla mean 'with unref too' // by request'
  else if amodid=modVanilla then
  begin
//    if aunref then
      ls:='SELECT distinct strings.src, t.dst FROM strings'+
          ' LEFT JOIN refs ON refs.srcid=strings.id'+lt+
          ' WHERE strings.deleted=0 AND (refs.modid=0 OR refs.srcid IS NULL)'
{
    else
      ls:='SELECT distinct strings.src, t.dst FROM strings'+
          ' INNER JOIN refs ON refs.srcid=strings.id'+lt+
          ' WHERE strings.deleted=0 AND refs.modid=0';
}
  end
  // List mean 'without unref'
  else if amodid=modList then
  begin
      ls:='SELECT distinct strings.src, t.dst FROM strings'+lt+
          ' INNER JOIN refs    ON refs.srcid=strings.id'+
          ' INNER JOIN tmpmods ON refs.modid=tmpmods.id'+
          ' WHERE strings.deleted=0';
  end
  // Single mod mean 'mod ONLY'. distinct = GROUP BY strings.id
  else
  begin
//      ls:='SELECT id, src, dst FROM strings WHERE '+
//          'id IN (SELECT DISTINCT srcid FROM refs WHERE modid='+lmod+')';

    Str(amodid,ls);
    ls:='SELECT distinct strings.src, t.dst FROM strings'+lt+
        ' INNER JOIN refs ON refs.srcid=strings.id AND refs.modid='+ls+
        ' WHERE strings.deleted=0';
{
    CacheSrcId(amodid);
    ls:='SELECT distinct strings.src, t.dst FROM strings'+lt+
        ' INNER JOIN tmpref ON tmpref.srcid=strings.id'+
        ' WHERE strings.deleted=0';
}
  end;
  sl:=nil;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    result:=true;

    sl:=TStringList.Create;
    sl.WriteBOM:=true;

    sl.Add(sBeginFile);

    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      ls:=sqlite3_column_text(vm,0);
      lt:=sqlite3_column_text(vm,1);

      sl.Add(#9+sBeginBlock);
      sl.Add(#9#9+sOriginal+ls);
      if lt<>'' then
        sl.Add(#9#9+sTranslated+lt)
      else
        sl.Add(#9#9+sTranslated+ls);
      sl.Add(#9+sEndBlock);
    end;

    sqlite3_finalize(vm);
  end;

  if (sl<>nil) and (sl.Count>1) then
  begin
    sl.Add(sEndFile);

    sl.SaveToFile(afname{'TRANSLATION.DAT'},TEncoding.Unicode);
    sl.Free;
  end;
end;

{%REGION Admin}
function CreateLangTable(const lng:AnsiString):boolean;
var
  ls,lSQL:AnsiString;
begin
  ls:=iso639.GetLang(lng);
  if ls='' then ls:=lng;

  if not IsTableExists(tldb,'[trans_'+ls+']') then
  begin
    lSQL:='CREATE  TABLE [trans_'+ls+'] ('+
        '  srcid   INTEGER PRIMARY KEY,'+
        '  dst     TEXT,'+
        '  changed INTEGER,'+
        '  part    BOOLEAN);';

    result:=ExecuteDirect(tldb,lSQL);
    if result then
    begin
      SQLog.Add(lSQL);
//      ExecuteDirect(tldb,'insert into settings (setting,value) Values (''trans_'''+ls+',?1)',[lng]);
    end;
  end
  else
    result:=false;
end;

function CreateTables():boolean;
begin
{
  filter       text
  filtertime   date of last recalc
  filterchange date of text change
//  trans_*      text language full name
}
  result:=ExecuteDirect(tldb,
      'CREATE TABLE settings ('+
      '  setting TEXT,'+
      '  value   TEXT);');
  if result then
  begin
    ExecuteDirect(tldb,'insert into settings (setting,value) Values (''filter'',?1)',[GetFilterWords()]);
    ExecuteDirect(tldb,'insert into settings (setting,value) Values (''filterchange'',unixepoch())');
    ExecuteDirect(tldb,'insert into settings (setting) Values (''filtertime'')');
  end;

  result:=ExecuteDirect(tldb,
      'CREATE TABLE strings ('+
      '  id      INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  filter  INTEGER,'+
      '  deleted BOOLEAN DEFAULT (0),'+
{$IFNDEF UseUniqueText}
      '  src     TEXT);');
{$ELSE}
      '  src     TEXT UNIQUE);');
{$ENDIF}

  result:=ExecuteDirect(tldb,
      'CREATE TABLE filter ('+
      '  id     INTEGER PRIMARY KEY, AUTOINCREMENT,'+
      '  value  TEXT UNIQUE);');

  result:=ExecuteDirect(tldb,
      'CREATE TABLE dictags ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
{$IFNDEF UseUniqueText}
      '  value  TEXT);');
{$ELSE}
      '  value  TEXT UNIQUE);');
{$ENDIF}

  result:=ExecuteDirect(tldb,
      'CREATE TABLE dicdirs ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
{$IFNDEF UseUniqueText}
      '  value  TEXT);');
{$ELSE}
      '  value  TEXT UNIQUE);');
{$ENDIF}

  result:=ExecuteDirect(tldb,
      'CREATE TABLE dicfiles ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
{$IFNDEF UseUniqueText}
      '  value  TEXT);');
{$ELSE}
      '  value  TEXT UNIQUE);');
{$ENDIF}

  // theorectically, can use data db for this but this way much simpler
  result:=ExecuteDirect(tldb,
      'CREATE TABLE dicmods ('+
      '  id     INTEGER PRIMARY KEY,'+
      '  value  TEXT);');

  result:=ExecuteDirect(tldb,
    'INSERT INTO dicmods (id,value) VALUES (0, ''Torchlight II'');');

  result:=ExecuteDirect(tldb,
      'CREATE TABLE refs ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  srcid  INTEGER,'+
      '  modid  INTEGER,'+
      '  dir    INTEGER,'+
      '  file   INTEGER,'+
      '  tag    INTEGER,'+
      '  line   INTEGER,'+
      '  flags  INTEGER);');
  result:=ExecuteDirect(tldb,
      'CREATE INDEX refsrc ON refs (srcid, modid)');

  result:=ExecuteDirect(tldb,
      'CREATE TABLE statistic ('+
      '  modid   INTEGER PRIMARY KEY,'+
      '  lines   INTEGER,'+
      '  differs INTEGER,'+
      '  files   INTEGER,'+
      '  tags    INTEGER,'+
      '  nation  INTEGER);'); // warning for ChangeOriginal

end;

function TLOpenBase(inmemory:boolean=false):boolean;
begin
  if tldb<>nil then exit(true);

  result:=LoadBase(tldb,TL2TextBase,inmemory)=SQLITE_OK;

  if (not result) and (tldb<>nil) then
    result:=CreateTables();

  lastmodid:=modUnref;
end;

function TLSaveBase(const fname:AnsiString=''):boolean;
begin
  if tldb=nil then exit(false);

  if fname='' then
    result:=SaveBase(tldb,TL2TextBase)=SQLITE_OK
  else
    result:=SaveBase(tldb,fname)=SQLITE_OK
end;

function TLCloseBase(dosave:boolean):boolean;
begin
  if tldb=nil then exit(not dosave);

  if dosave then
    result:=SaveBase(tldb,TL2TextBase)=SQLITE_OK
  else
    result:=true;

  if result then
    FreeBase(tldb);
end;
{%ENDREGION Admin}

initialization

  SQLog.Init;

finalization

  SQLog.Free;
end.
