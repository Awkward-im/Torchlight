{TODO: GetSimilar as mod depended}
{TODO: variant CopyToBase just for translation (not src or refs)}
{TODO: AddTranslation: overwrite all, overwrite partial by full, skip. Or use SetTRanslation?}

{$DEFINE UseUniqueText}
unit TLTrSQL;

interface

uses
  logging,
  rgglobal,
  sqlite3dyn;

const
  TLTRBase = 'trans.db';

var
  tldb:pointer;
var
  // 0 = Vanilla + unreferred; -1 = all; -2 = unreferred; -3 = deleted
  CurMod :Int64;
  CurLang:AnsiString;
var
  SQLog:Logging.TLog;

type
  TTLCacheElement = record
    src  :string;   // src text
    dst  :string;   // current trans text
    id   :integer;  // src id
    flags:cardinal; // ref flags (combo from all)
    part :boolean;  // current trans state
  end;
  TTLCache = array of TTLCacheElement;
var
  TRCache:TTLCache;

function LoadModData():integer;
procedure LoadTranslation();
procedure SaveTranslation();

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
  rfIsReferred  = $8000;


function CheckForDirectory(const afilter:string):integer;
function GetModDirList (amodid:Int64; var alist:TStringDynArray):integer;
function GetSimilarCount(aid:integer):integer;
function GetSimilars    (aid:integer; var arr:TIntegerDynArray):integer;
function GetDoubles     (aid:integer; var arr:TIntegerDynArray):integer;
function RemakeFilter():boolean;

function CreateLangTable(const lng:AnsiString):boolean;
function TLOpenBase (inmemory:boolean=false):boolean;
function TLSaveBase ():integer;
function TLCloseBase(dosave:boolean):boolean;
{
function CopyToBase  (const data:TTL2Translation; withRef:boolean):integer;
function LoadFromBase(var   data:TTL2Translation;
    amod:Int64; const lang:AnsiString):integer;
}

function GetUnrefLineCount():integer;

// aid is source index
function DeleteOriginal(aid:integer):boolean;
function GetOriginal   (aid:integer):AnsiString;
function GetText       (aid:integer; const atable:AnsiString; var asrc,adst:AnsiString):boolean;
function GetTranslation(aid:integer; const atable:AnsiString; var      adst:Ansistring):boolean;
function SetTranslation(aid:integer; const atable:AnsiString;
   const adst:Ansistring; apart:boolean):integer;
function GetLineFlags  (aid:integer; const amodid:AnsiString):cardinal;

function GetLineRef     (aid:integer):integer;
function GetLineRefCount(aid:integer):integer;
// get reference info. aid is ref index, result is source index
function GetRef(aid:integer;
     var adir,afile,atag:AnsiString; var aline,aflags:integer):integer;

function PrepareScanSQL():boolean;
function PrepareLoadSQL(const alang:AnsiString):boolean;

type
  TModStatistic = record
    modid:int64;
    total:integer;
    dupes:integer;
    files:integer;
    tags :integer;
    langs:array of record
      lang :AnsiString;
      trans:integer;
      part :integer;
    end;
  end;

function GetModStatistic(var stat:TModStatistic):integer;

function AddToModList(aid:Int64; const atitle:AnsiString):integer;
function AddToModList(aid:Int64; atitle:PUnicodeChar):integer;
function GetModByName(const atitle:AnsiString):Int64;
function GetLineCount(amod:Int64):integer;


implementation

uses
  SysUtils,
  iso639,
  tl2text,
  tlscan,
  rgdb;

var
  BaseInMemory:boolean;

{%REGION Mod}
function AddToModList(aid:Int64; const atitle:AnsiString):integer;
var
  vm:pointer;
  ls:AnsiString;
  pc:PAnsiChar;
begin
  result:=-1;
  if (aid=-1) or (atitle='') then exit;

  Str(aid,ls);
  result:=ReturnInt(tldb,'SELECT 1 FROM dicmods WHERE id='+ls);

  if result<1 then
  begin
    ls:='INSERT INTO dicmods (id, title) VALUES ('+ls+', ?1)';

    if sqlite3_prepare_v2(tldb, PAnsiChar(ls), -1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_bind_text(vm,1,PAnsiChar(atitle),-1,SQLITE_STATIC)=SQLITE_OK then
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

function AddToModList(aid:Int64; atitle:PUnicodeChar):integer;
var
  vm:pointer;
  ls:AnsiString;
  pc:PAnsiChar;
begin
  if (aid=-1) or (atitle=nil) then exit(-1);

  Str(aid,ls);
  result:=ReturnInt(tldb,'SELECT 1 FROM dicmods WHERE id='+ls);

  if result<0 then
  begin
    ls:='INSERT INTO dicmods (id, title) VALUES ('+ls+', ?1)';

    if sqlite3_prepare_v2(tldb, PAnsiChar(ls), -1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_bind_text16(vm,1,atitle,-1,SQLITE_STATIC)=SQLITE_OK then
      begin
        if sqlite3_step(vm)=SQLITE_DONE then
        begin
          pc:=sqlite3_expanded_sql(vm);
          SQLog.Add(pc);
          sqlite3_free(pc);
        end;
      end;
      sqlite3_finalize(vm);
    end;
    
    result:=0;
  end;
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
    lSQL:='SELECT id FROM dicmods WHERE title LIKE ?1';
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

function GetUnrefLineCount():integer;
begin
  result:=ReturnInt(tldb,
//    'SELECT count(id) FROM strings WHERE NOT (id IN (SELECT DISTINCT srcid FROM ref))');
    'SELECT count(strings.id) FROM strings'+
          ' LEFT JOIN ref ON ref.srcid=strings.id WHERE ref.srcid IS NULL');

end;

function GetLineCount(amod:Int64):integer;
var
  lsrc:AnsiString;
begin
       if amod=-2 then result:=GetUnrefLineCount()
  else if amod=-3 then result:=ReturnInt(tldb,'SELECT count(1) FROM strings WHERE deleted=1')
  else if amod=-1 then result:=ReturnInt(tldb,'SELECT count(1) FROM strings')
  else
  begin
    Str(amod,lsrc);
    result:=ReturnInt(tldb,'SELECT count(DISTINCT srcid) FROM ref WHERE modid='+lsrc);
    if amod=0 then
      result:=result+GetUnrefLineCount();
  end;
end;

function GetModStatistic(var stat:TModStatistic):integer;
var
  vm,vml:pointer;
  lmod,ls,ltab:AnsiString;
  i:integer;
begin
  if stat.modid>=0 then
  begin
    Str(stat.modid,lmod);
    lmod:=' WHERE modid='+lmod;
  end
  else
    lmd:='';

  ls:='SELECT count(srcid), count(DISTINCT srcid), count(DISTINCT file), '+
      ' count(DISTINCT tag) FROM ref'+lmod;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      stat.total:=sqlite3_column_int(vm,0);
      stat.dupes:=stat.total-sqlite3_column_int(vm,1);
      stat.files:=sqlite3_column_int(vm,2);
      stat.tags :=sqlite3_column_int(vm,3);
    end;
    sqlite3_finalize(vm);
  end;

  result:=ReturnInt(tldb,'SELECT count(1) FROM sqlite_master'+
    ' WHERE (type = ''table'') AND (name GLOB ''trans_*'')');
  SetLength(stat.langs,result);
  if result=0 then exit;

  i:=0;
  ls:='SELECT name FROM sqlite_master'+
    ' WHERE (type = ''table'') AND (name GLOB ''trans_*'') ORDER BY name';
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      ltab:=sqlite3_column_text(vm,0);
      ls:='SELECT count(srcid), sum(part) FROM '+ltab+
        ' WHERE srcid IN (SELECT DISTINCT srcid FROM ref'+lmod+')';
      if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vml, nil)=SQLITE_OK then
      begin
        if sqlite3_step(vml)=SQLITE_ROW then
        begin
          stat.langs[i].lang :=Copy(ltab,7);
          stat.langs[i].trans:=sqlite3_column_int(vml,0);
          stat.langs[i].part :=sqlite3_column_int(vml,1);
        end;
        sqlite3_finalize(vml);
      end;

      inc(i);
    end;
    sqlite3_finalize(vm);
  end;

end;
{%ENDREGION Mod}

{%REGION Additional}
function RemakeFilter():boolean;
var
  vm: Pointer;
  lSQL,lsrc,lid,ls,lsold:AnsiString;
  ldate:double;
  i,flid,lsrcid:integer;
begin
  result:=true;
  ExecuteDirect(tldb,'DELETE FROM filter');
{
  ExecuteDirect(tldb,'DROP TABLE filter');
  result:=ExecuteDirect(tldb,
      'CREATE TABLE filter ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  value  TEXT UNIQUE);');
}

  lSQL:='SELECT id, src FROM strings';
  lsold:='';
  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    i:=1;
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      lsrcid:=sqlite3_column_int (vm,0);
      lsrc  :=sqlite3_column_text(vm,1);

      ls:=FilteredString(lsrc);
      if lsold<>ls then
      begin
        lsold:=ls;

        // variant without autoincrement key
        flid:=ReturnInt(tldb,'INSERT INTO filter (id,value) VALUES ('+
          IntToStr(i)+',?1) RETURNING id;',PAnsiChar(ls));
        if flid<0 then
          flid:=ReturnInt(tldb,'SELECT id FROM filter WHERE (value=?1)',PAnsiChar(ls))
        else
          inc(i);
        Str(flid,lid);

        // variant with autoincrement key
//        Str(AddToList('filter',ls),lid);
      end;

      ExecuteDirect(tldb,'UPDATE strings SET filter='+lid+
        ' WHERE id='+IntToStr(lsrcid));
    end;
    sqlite3_finalize(vm);
  end;

  ldate:=Now();
  lsold:=ReturnText(tldb,'SELECT value FROM settings WHERE setting=''filter''');
  ls   :=GetFilterWords();
  if ls<>lsold then
  begin
    ExecuteDirect(tldb,'UPDATE settings SET value=?1 WHERE setting=''filter'''      ,[ls]);
    ExecuteDirect(tldb,'UPDATE settings SET value=?1 WHERE setting=''filterchange''',[ldate]);
  end;
  ExecuteDirect(tldb,'UPDATE settings SET value=?1 WHERE setting=''filtertime'''  ,[ldate]);
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

// Mod limited must be
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
      SetLength(arr,result);
      lSQL:='SELECT id FROM strings WHERE filter='+lf+' AND id<>'+lid;
      if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          arr[i]:=sqlite3_column_int(vm,0);
          inc(i);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end;
end;

function GetDoubles(aid:integer; var arr:TIntegerDynArray):integer;
var
  vm:pointer;
  lSQL,lid,lmod:AnsiString;
  lcnt:integer;
begin
  result:=0;
  Str(aid,lid);
  if CurMod>=0 then
  begin
    Str(CurMod,lmod);
    lmod:=' AND modid='+lmod;
  end
  else
    lmod:='';

  lcnt:=ReturnInt(tldb,'SELECT count(*) FROM ref WHERE srcid='+lid+lmod);
  if lcnt>0 then
  begin
    SetLength(arr,lcnt);
    lSQL:='SELECT id FROM ref WHERE srcid='+lid+lmod;
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        arr[result]:=sqlite3_column_int(vm,0);
        inc(result);
      end;
      sqlite3_finalize(vm);
    end;
  end
  else
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

function AddOriginal(const asrc:AnsiString; withcheck:boolean=false):integer;
var
  vm:pointer;
  pc:PAnsiChar;
  lSQL:AnsiString;
begin
  result:=-1;
{$IFNDEF UseUniqueText}
  if withcheck then
    result:=FindOriginal(asrc);
//    result:=ReturnInt(tldb,'SELECT id FROM strings WHERE (src=?1)',asrc);

  if result<0 then
{$ENDIF}
  begin
    lSQL:='INSERT INTO strings (src) VALUES (?1) RETURNING id;';
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
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
  end;
end;

function DeleteOriginal(aid:integer):boolean;
var
  lSQL:AnsiString;
begin
  lSQL:='UPDATE strings SET deleted=1 WHERE id='+IntToStr(aid);
  result:=ExecuteDirect(tldb,lSQL);
  if result then
    SQLog.Add(lSQL);
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
    result:=atable
  else
    result:='trans_'+atable;
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

  if adst='' then
  begin
    lSQL:='DELETE FROM '+ltable+' WHERE srcid='+lsrc;
    ExecuteDirect(tldb,lSQL);
    SQLog.Add(lSQL);
    exit;
  end;

  lstat:=ReturnInt(tldb,'SELECT part FROM '+ltable+' WHERE srcid='+lsrc);
  if lstat<0 then
  begin
    lSQL:='INSERT INTO '+ltable+' (srcid, dst, part) VALUES ('+
           lsrc+', ?1, '+BoolNumber[apart]+');';
  end
  else
    lSQL:='UPDATE '+ltable+
          ' SET dst=?1, part='+BoolNumber[apart]+
          ' WHERE srcid='+lsrc;

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

function AddTranslation(aid:integer; const atable:AnsiString;
    const adst:Ansistring; apart:boolean):integer;
begin
  result:=aid;
  if adst='' then exit;

  result:=SetTranslation(aid, atable, adst, apart);
end;

function AddText(const asrc,alang,adst:AnsiString; apart:boolean):integer;
begin
  result:=AddOriginal(asrc);

  if alang='' then exit;

  if result<0 then
    result:=FindOriginal(asrc);

  if (result>0) and (adst<>'') then
    AddTranslation(result,alang, adst, apart);
end;

function GetText(aid:integer; const atable:AnsiString; var asrc,adst:AnsiString):boolean;
begin
  asrc:=GetOriginal(aid);
  if asrc<>'' then
    result:=GetTranslation(aid,atable,adst);
end;
{%ENDREGION Basic}

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

    Str(CurMod,lSQL);
         if afilter='MEDIA/'        then lcond:='=''MEDIA/'''
    else if afilter='MEDIA/SKILLS/' then lcond:='=''MEDIA/SKILLS/'''
    else                                 lcond:=' GLOB '''+afilter+'*''';

    lSQL:='SELECT DISTINCT srcid FROM ref WHERE modid='+lSQL+
          ' AND dir IN (SELECT id FROM dicdir WHERE value'+lcond+')';
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

function GetModDirList(amodid:Int64; var alist:TStringDynArray):integer;
var
  vm:pointer;
  ls,lmod:string;
  lcnt:integer;
begin
  result:=0;

  if amodid>=0 then
  begin
    Str(amodid,lmod);
    lmod:=' WHERE ref.modid='+lmod;
  end
  else
    lmod:='';

  lcnt:=ReturnInt(tldb,'SELECT count(DISTINCT dir) FROM ref'+lmod);
  if lcnt>0 then
  begin
    SetLength(alist,lcnt);

//    ls:='SELECT value FROM dicdir WHERE id IN (SELECT DISTINCT dir FROM ref WHERE modid='+ls+')';
//    ls:='SELECT DISTINCT value FROM dicdir WHERE id IN (SELECT dir FROM ref WHERE modid='+lmod+')';
    ls:='SELECT DISTINCT value FROM dicdir INNER JOIN ref ON ref.dir=dicdir.id'+lmod;
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

function GetLineRef(aid:integer):integer;
var
  lid,lmod:AnsiString;
begin
//  if (TRCache[aidx].flags and (rfIsManyRefs or rfIsNoRef))<>0 then exit(0);

  Str(aid,lid);
  if CurMod>=0 then
  begin
    Str(CurMod,lmod);
    lmod:=' AND modid='+lmod
  end
  else
    lmod:='';

  result:=ReturnInt(tldb,'SELECT id FROM ref WHERE srcid='+lid+lmod);
end;

function GetLineRefCount(aid:integer):integer;
var
  lid,lmod:AnsiString;
begin
//  if (TRCache[aidx].flags and (rfIsNoRef))<>0 then exit(0);

  Str(aid,lid);
  if CurMod>=0 then
  begin
    Str(CurMod,lmod);
    lmod:=' AND modid='+lmod;
  end
  else
    lmod:='';

  result:=ReturnInt(tldb,'SELECT count(1) FROM ref WHERE srcid='+lid+lmod);
end;

function GetRef(aid:integer;
    var adir,afile,atag:AnsiString; var aline,aflags:integer):integer;
var
  vm:pointer;
  lref,lSQL:AnsiString;
begin
  result:=-1;

  Str(aid,lref);

  lSQL:='SELECT r.srcid, d.value, f.value, t.value, r.line, r.flags'+
        ' FROM ref r'+
        ' INNER JOIN dicdir  d ON d.id=r.dir'+
        ' INNER JOIN dicfile f ON f.id=r.file'+
        ' INNER JOIN dictag  t ON t.id=r.tag'+
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

function AddRef(asrc:integer; amod:int64;
    const afile,atag:AnsiString; aline:integer):integer;
var
  lSQL,lline,lmod,lsrc,ldir,lfile,ltag:AnsiString;
  lflag:integer;
begin
  result:=0;

  lfile:=UpCase(afile);

  Str(asrc,lsrc);
  Str(AddToList('dicdir' ,ExtractPath(lfile)), ldir);
  Str(AddToList('dicfile',ExtractName(lfile)), lfile);
  Str(AddToList('dictag' ,atag              ), ltag);
  Str(amod,lmod);
  Str(ABS(aline),lline);

  if ReturnInt(tldb,
      'SELECT 1 FROM ref WHERE (srcid='+lsrc +') AND (modid='+lmod+
      ') AND (dir='+ldir+') AND (file='+lfile+') AND (tag='+ltag+
      ') AND (line='+lline+')')<>1 then
  begin
    lflag:=0;
    if Pos('MEDIA/SKILLS/'        ,lfile)=1 then lflag:=lflag or rfIsSkill;
    if Pos('MEDIA/UNITS/ITEMS/'   ,lfile)=1 then lflag:=lflag or rfIsItem;
    if Pos('MEDIA/UNITS/MONSTERS/',lfile)=1 then lflag:=lflag or rfIsMob;
    if Pos('MEDIA/UNITS/PLAYERS/' ,lfile)=1 then lflag:=lflag or rfIsPlayer;
    if Pos('MEDIA/UNITS/PROPS/'   ,lfile)=1 then lflag:=lflag or rfIsProp;
    if aline<0                              then lflag:=lflag or rfIsTranslate;

    lSQL:='INSERT INTO ref (srcid, modid, dir, file, tag, line, flags) VALUES ('+
        lsrc+', '+lmod+', '+ldir+', '+lfile+', '+ltag+', '+lline+', '+IntToStr(lflag)+');';
    if ExecuteDirect(tldb,lSQL) then
      SQLog.Add(lSQL);
  end;
end;

{
function CopyToBase(const data:TTL2Translation; withRef:boolean):integer;
var
  lsrc,i,j,lref,lline:integer;
  lmod:int64;
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
          lref:=data.Ref[i,j];
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
    amod:Int64; const lang:AnsiString):integer;
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
    lSQL:='SELECT srcid, dir+file, tag, line, flags FROM ref WHERE modid='+lsrc+' ORDER BY srcid';
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        // 1 - get ref info (with source id)
        lsrcid :=sqlite3_column_int (vm,0);
        lrfile :=sqlite3_column_text(vm,1);
        lrtag  :=sqlite3_column_text(vm,2);
        lrline :=sqlite3_column_int (vm,3);
        lrflags:=sqlite3_column_int (vm,4);
        // prepare ref
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

        // 3 - add ref (as double if needs)
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
      lSQL:='SELECT dir+file, tag, line, flags FROM ref WHERE srcid='+lsrc;
      if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vmref, nil)=SQLITE_OK then
      begin
        while sqlite3_step(vmref)=SQLITE_ROW do
        begin
          lrfile :=sqlite3_column_text(vm,0);
          lrtag  :=sqlite3_column_text(vm,1);
          lrline :=sqlite3_column_int (vm,2);
          lrflags:=sqlite3_column_int (vm,3);
          // prepare ref
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

{%REGION Admin}
function CreateLangTable(const lng:AnsiString):boolean;
var
  ls:AnsiString;
begin
  ls:=iso639.GetLang(lng);
  if ls='' then ls:=lng;

  if not IsTableExists(tldb,'trans_'+ls) then
  begin
    ls:='CREATE TABLE trans_'+lng+' ('+
        '  srcid  INTEGER PRIMARY KEY,'+
        '  dst    TEXT ,'+
        '  part   BOOLEAN );';

    result:=ExecuteDirect(tldb,ls);
    if result then
      SQLog.Add(ls);
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
  lang_*       text language full name
}
  result:=ExecuteDirect(tldb,
      'CREATE TABLE settings ('+
      '  setting TEXT,'+
      '  value   TEXT);');
  if result then
  begin
    ExecuteDirect(tldb,'insert into settings (setting,value) Values (''filter'',?1)',[GetFilterWords()]);
    ExecuteDirect(tldb,'insert into settings (setting) Values (''filterchange'',?1)',[Now()]);
    ExecuteDirect(tldb,'insert into settings (setting) Values (''filtertime'')');
  end;

  result:=ExecuteDirect(tldb,
      'CREATE TABLE strings ('+
      '  id      INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  filter  INTEGER,'+
      '  deleted BOOLEAN,'+
{$IFNDEF UseUniqueText}
      '  src     TEXT);');
{$ELSE}
      '  src     TEXT UNIQUE);');
{$ENDIF}

  result:=ExecuteDirect(tldb,
      'CREATE TABLE filter ('+
      '  id     INTEGER PRIMARY KEY,'+ // AUTOINCREMENT,'+
      '  value  TEXT UNIQUE);');

  result:=ExecuteDirect(tldb,
      'CREATE TABLE dictag ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
{$IFNDEF UseUniqueText}
      '  value  TEXT);');
{$ELSE}
      '  value  TEXT UNIQUE);');
{$ENDIF}

  result:=ExecuteDirect(tldb,
      'CREATE TABLE dicdir ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
{$IFNDEF UseUniqueText}
      '  value  TEXT);');
{$ELSE}
      '  value  TEXT UNIQUE);');
{$ENDIF}

  result:=ExecuteDirect(tldb,
      'CREATE TABLE dicfile ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
{$IFNDEF UseUniqueText}
      '  value  TEXT);');
{$ELSE}
      '  value  TEXT UNIQUE);');
{$ENDIF}

  result:=ExecuteDirect(tldb,
      'CREATE TABLE dicmods ('+
      '  id     INTEGER PRIMARY KEY,'+
      '  title  TEXT );');

  result:=ExecuteDirect(tldb,
      'CREATE TABLE ref ('+
      '  id     INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  srcid  INTEGER,'+
      '  modid  INTEGER,'+
      '  dir    INTEGER,'+
      '  file   INTEGER,'+
      '  tag    INTEGER,'+
      '  line   INTEGER,'+
      '  flags  INTEGER );');
  result:=ExecuteDirect(tldb,
      'CREATE INDEX refsrc ON ref (srcid, modid)');
end;

function TLOpenBase(inmemory:boolean=false):boolean;
begin
  if tldb<>nil then exit(true);

  result:=false;

  try
    InitializeSQLite();
  except
    exit;
  end;

  BaseInMemory:=false;
  if inmemory then
  begin
    result:=sqlite3_open(':memory:',@tldb)=SQLITE_OK;
    if result then
    begin
      if CopyFromFile(tldb,TLTRBase)<>SQLITE_OK then
        result:=CreateTables();
    end;
    if tldb<>nil then
      BaseInMemory:=true;
  end;
  if tldb=nil then
  begin
    result:=OpenDatabase(tldb,TLTRBase);
    if result then
      result:=CreateTables();
  end;
end;

function TLSaveBase():integer;
begin
  if BaseInMemory then
    result:=CopyToFile(tldb,TLTRBase)
  else
    result:=SQLITE_OK;
end;

function TLCloseBase(dosave:boolean):boolean;
begin
  if tldb=nil then exit(not dosave);

  if dosave then
    result:=TLSaveBase()=SQLITE_OK
  else
    result:=true;

  result:=result and (sqlite3_close(tldb)=SQLITE_OK);
  tldb:=nil;
  ReleaseSQLite();
end;
{%ENDREGION Admin}

{%REGION Scan and Load}
procedure AddScanMod(dummy:pointer; const mi:TTL2ModInfo);
begin
  CurMod:=mi.modid;
  AddToModList(mi.modid,WideToStr(mi.title));
end;

function AddScanString(dummy:pointer; const astr, afile, atag:AnsiString; aline:integer):integer;
begin
  result:=AddOriginal(astr);
  if result<0 then
    result:=FindOriginal(astr);
  if result>0 then
    AddRef(result, CurMod, afile, atag, aline);
end;

function PrepareScanSQL():boolean;
begin
  result:=true;
  CurMod:=0;
  TLScan.DoAddModInfo:=TDoAddModInfo(MakeMethod(nil,@AddScanMod));
  TLScan.DoAddString :=TDoAddString (MakeMethod(nil,@AddScanString));
end;

function AddLoadText(dummy:pointer; const astr,atrans:PAnsiChar):integer;
begin
  if AddText(astr,CurLang,atrans,false)>0 then
    result:=1
  else
    result:=0;
end;

function PrepareLoadSQL(const alang:AnsiString):boolean;
begin
  CurLang:=alang;
  result:=CurLang<>'';
  if result then
  begin
    CreateLangTable(CurLang);
    TLScan.DoAddText:=TDoAddText(MakeMethod(nil,@AddLoadText));
  end;
end;
{%ENDREGION Scan and Load}

function GetLineFlags(aid:integer; const amodid:AnsiString):cardinal;
var
  vm:pointer;
  lSQL:AnsiString;
  i:integer;
begin
  result:=0;
  if amodid<>'' then
    lSQL:=' AND modid='+amodid
  else
    lSQL:='';
  lSQL:='SELECT flags FROM ref WHERE srcid='+IntToStr(aid)+lSQL;

  if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    i:=0;
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      result:=result or rfIsReferred or sqlite3_column_int(vm,0);
      inc(i);
    end;
    if i>1 then result:=result or rfIsManyRefs;

    sqlite3_finalize(vm);
  end;
end;

function LoadModData():integer;
var
  vm:pointer;
  i,lcnt:integer;
  lmod,lSQL:AnsiString;
begin
  for i:=0 to High(TRCache) do
  begin
    with TRCache[i] do
    begin
      src:='';
      dst:='';
    end;
  end;
  SetLength(TRCache,0);
  lcnt:=GetLineCount(CurMod);
  SetLength(TRCache,lcnt);
  if CurMod>-2 then
  begin
    if CurMod=-1 then
      lSQL:='SELECT id, src FROM strings WHERE deleted<>1'
    else
    begin
      Str(CurMod,lmod);
//      lSQL:='SELECT id, src FROM strings WHERE '+
//            'id IN (SELECT DISTINCT srcid FROM ref WHERE modid='+lmod+')';
      lSQL:='SELECT DISTINCT strings.id, strings.src FROM strings'+
            ' INNER JOIN ref ON ref.srcid=strings.id'+
            ' WHERE strings.deleted<>1 AND ref.modid='+lmod;
    end;

    result:=0;
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        with TRCache[result] do
        begin
          id   :=sqlite3_column_int (vm,0);
          src  :=sqlite3_column_text(vm,1);
          flags:=GetLineFlags(id,lmod);
        end;
        inc(result);
      end;
    end;
  end;

  // Add unreferred to vanilla
  if (CurMod=0) or (CurMod=-2) then
  begin
//    lSQL:='SELECT id, src FROM strings WHERE '+
//          'NOT (id IN (SELECT DISTINCT srcid FROM ref))';
    lSQL:='SELECT strings.id, strings.src FROM strings'+
          ' LEFT JOIN ref ON ref.srcid=strings.id WHERE ref.srcid IS NULL';
    if sqlite3_prepare_v2(tldb, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        with TRCache[result] do
        begin
          id   :=sqlite3_column_int (vm,0);
          src  :=sqlite3_column_text(vm,1);
          flags:=rfIsNoRef;
        end;
        inc(result);
      end;
    end;
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
begin
  for i:=0 to High(TRCache) do
  begin
    with TRCache[i] do
    begin
           if (flags and rfIsDeleted )<>0 then DeleteOriginal(id)
      else if (flags and rfIsModified)<>0 then
      begin
        SetTranslation(id, CurLang, dst, part);
        flags:=flags and not rfIsModified;
      end;
    end;
  end;
end;


initialization

  SQLog.Init;

finalization

  SQLog.Free;
end.
