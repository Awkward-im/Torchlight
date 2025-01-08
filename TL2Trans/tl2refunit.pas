{
  This object don't have any text info.
  It saves just text reference info like: file-line-tag
  and reference to base placement for doubles
}
{NOTES:
    Dupes stores as index of next double, less than 0 means end of link
    LoadedRefs is buffer to reserve unreaded yet dats (dupes) and
      keep indexes between text and refs coz refs loading before text
}
{TODO: Separate text cache to dir, files, tags.}
unit TL2RefUnit;

interface

uses
  Classes,
  textcache;

type
  TTL2Reference = object
  private
    type
      tRefText = packed record
        txt: integer;  // index of text in array
        cnt: integer;  // count of referals
      end;
      tRefData = packed record
        // constant part (fills on scan)
        _dir : integer;
        _file: integer;
        _tag : integer;
        _line: integer;
        // runtime part
        _root: integer;
        _flag: integer;
        _dup : integer; // index of next ref
      end;

  private
    arRefs  : array of tRefData;
    arDirs  : array of tRefText;
    arFiles : array of tRefText;
    arTags  : array of tRefText;
    names   : tTextCache;

    LoadedRefs: array of tRefData;

//    fRoot   : AnsiString;
    arRoots  : array of AnsiString;

    // last used
    lastDir : AnsiString;
    lastFile: AnsiString;
    lastTag : AnsiString;
    lastTagIdx:integer;
    lastRoot: integer;

    cntRefs : integer; // referals (lines)
    cntDirs : integer; // dirs
    cntFiles: integer; // filenames
    cntTags : integer; // tags
    cntRoots: integer;

    procedure IntDeleteRef(aidx:integer);
    procedure DeleteRef(aid:integer);

    procedure DeleteDir (const fdir :AnsiString);
    procedure DeleteFile(const fname:AnsiString);
    procedure DeleteTag (const atag :AnsiString);
    function  AddDir    (const fdir :AnsiString):integer;
    function  AddFile   (const fname:AnsiString):integer;
    function  AddTag    (const atag :AnsiString):integer;

    function  GetOpt(idx,aflag:integer):boolean;
    procedure SetOpt(idx,aflag:integer; aval:boolean);
    function  GetFlag(idx:integer):integer;
    procedure SetFlag(idx:integer; aval:integer);
    function  GetDup (idx:integer):integer;
    procedure SetDup (idx:integer; aval:integer);

    function GetRootByIdx(idx:integer):AnsiString;
    function GetDirByIdx (idx:integer):AnsiString;
    function GetFileByIdx(idx:integer):AnsiString;
    function GetTagByIdx (idx:integer):AnsiString;

  public
    procedure Init;
    procedure Free;

    // add loaded ref link to existing line (with refs check)
    function AddLinkChecked(aref,aload:integer):integer;
    // add loaded ref link to new string
    function AddLoadedLink(aload:integer):integer;
    // add ref from another reference class
    function CopyLink(const aref:TTL2Reference; aidx:integer):integer;
    // add single ref (adupe) to existing (aref) as double
    function AddDouble(aref,adupe:integer):integer;
    function AddLoadedRef(idx:integer):integer;  // idx is index of LoadedRefs array
    function AddRef(const afile,atag:AnsiString; aline:integer):integer;
    // unised atm
    function GetRef(idx:integer; var afile,atag:AnsiString):integer;

    // idx - reference
    function GetLine (idx:integer):integer;
    function GetDir  (idx:integer):AnsiString;
    function GetFName(idx:integer):AnsiString;
    function GetFile (idx:integer):AnsiString;   // Dir+FName
    function GetTag  (idx:integer):AnsiString;
    function GetRoot (idx:integer):AnsiString;
    // moved to public coz used for scan
    function AddRoot(const aroot:AnsiString):integer;

    procedure SaveToStream  (astrm:TStream);
    procedure LoadFromStream(astrm:TStream);
    procedure DoneLoading;                       // just clear loaded refs array

    // idx physical index of array
    property  RefCount :integer read cntRefs;
    property  DirCount :integer read cntDirs;
    property  FileCount:integer read cntFiles;
    property  TagCount :integer read cntTags;
    property  RootCount:integer read cntRoots;
    property  Dirs [idx:integer]:AnsiString read GetDirByIdx;
    property  Files[idx:integer]:AnsiString read GetFileByIdx;
    property  Tags [idx:integer]:AnsiString read GetTagByIdx;
    property  Root [idx:integer]:AnsiString read GetRootByIdx;

    // index of next place of line
    property  Dupe       [idx:integer]:integer         read GetDup  write SetDup;
    property  Flag       [idx:integer]:integer         read GetFlag write SetFlag;
    property  IsSkill    [idx:integer]:boolean index 1 read GetOpt  write SetOpt;
    property  IsTranslate[idx:integer]:boolean index 2 read GetOpt  write SetOpt;
  end;


implementation

uses
  SysUtils,
  rgglobal,
  rgstream;

const
  RefVersion = 1;
  RefSizeV1 = SizeOf(Integer)*4;

const
  rfIsSkill     = 1;
  rfIsTranslate = 2;

const
  increment = 50;

procedure TTL2Reference.IntDeleteRef(aidx:integer);
begin
  dec(arDirs [arRefs[aidx]._dir ].cnt);
  dec(arFiles[arRefs[aidx]._file].cnt);
  dec(arTags [arRefs[aidx]._tag ].cnt);
  arRefs[aidx]._line:=0; // arRefs[aidx]._line:=-arRefs[aidx]._line; // in case to check/restore
end;

procedure TTL2Reference.DeleteRef(aid:integer);
begin
  IntDeleteRef(aid);
  // Text line must be deleted outside
end;

{%REGION Deletion /fold}
procedure TTL2Reference.DeleteDir(const fdir:AnsiString);
var
  i,j:integer;
begin
  j:=names.IndexOf(PAnsiChar(fdir));
  if j<0 then exit;

  for i:=0 to cntDirs-1 do
  begin
    if arDirs[i].txt=j then
    begin
      for j:=0 to cntRefs-1 do
      begin
        if arRefs[j]._dir=i then IntDeleteRef(j);
      end;
      arDirs[i].cnt:=0;
      // Delete text lines
      break;
    end;
  end;

end;

procedure TTL2Reference.DeleteFile(const fname:AnsiString);
var
  i,j:integer;
begin
  j:=names.IndexOf(PAnsiChar(fname)); // !!! mean filename only, no path
  if j<0 then exit;

  for i:=0 to cntFiles-1 do
  begin
    if arFiles[i].txt=j then
    begin
      for j:=0 to cntRefs-1 do
      begin
        if arRefs[j]._file=i then IntDeleteRef(j);
      end;
      arFiles[i].cnt:=0;
      // Delete text lines
      break;
    end;
  end;

end;

procedure TTL2Reference.DeleteTag(const atag:AnsiString);
var
  i,j:integer;
begin
  j:=names.IndexOf(PAnsiChar(atag));
  if j<0 then exit;

  for i:=0 to cntTags-1 do
  begin
    if arTags[i].txt=j then
    begin
      for j:=0 to cntRefs-1 do
      begin
        if arRefs[j]._tag=i then IntDeleteRef(j);
      end;
      arTags[i].cnt:=0;
      // Delete text lines
      break;
    end;
  end;

end;
{%ENDREGION Deletion}

{%REGION Addition /fold}
function TTL2Reference.AddDir(const fdir:AnsiString):integer;
begin
  // 1 times per dir (else - delete this check!)
  if (cntDirs>0) and (fdir=lastDir) then
  begin
    inc(arDirs[cntDirs-1].cnt);
    exit(cntDirs-1);
  end;

  lastDir:=fdir;
  if cntDirs>=Length(arDirs) then
  begin
    SetLength(arDirs,cntDirs+increment);
  end;
  arDirs[cntDirs].txt:=names.Add(PAnsiChar(fdir));
  arDirs[cntDirs].cnt:=1;

  result:=cntDirs;
  inc(cntDirs);
end;

function TTL2Reference.AddFile(const fname:AnsiString):integer;
begin
  // 1 times per file (else - delete this check!)
  if (cntFiles>0) and (fname=lastFile) then
  begin
    inc(arFiles[cntFiles-1].cnt);
    exit(cntFiles-1);
  end;

  lastFile:=fname;
  if cntFiles>=Length(arFiles) then
  begin
    SetLength(arFiles,cntFiles+increment*10);
  end;
  arFiles[cntFiles].txt:=names.Add(PAnsiChar(fname));
  arFiles[cntFiles].cnt:=1;

  result:=cntFiles;
  inc(cntFiles);
end;

function TTL2Reference.AddTag(const atag:AnsiString):integer;
var
  lcnt,lidx,i:integer;
begin
  if atag='' then exit(0);

  // can be several times. So, save idx too.
  // or delete for full Tag names check
  if (lastTagIdx>=0) and (atag=lastTag) then
  begin
    inc(arTags[lastTagIdx].cnt);
    exit(lastTagIdx);
  end;

  lcnt:=names.count;
  lidx:=names.Add(PAnsiChar(atag));
  if lcnt<names.count then
  begin
    if cntTags>=Length(arTags) then
    begin
      SetLength(arTags,cntTags+increment);
    end;
    arTags[cntTags].txt:=lidx;
    arTags[cntTags].cnt:=1;

    result:=cntTags;
    inc(cntTags);
  end
  else
  begin
    result:=-1; // must not be but...
    for i:=0 to cntTags-1 do
    begin
      if arTags[i].txt=lidx then
      begin
        inc(arTags[i].cnt);
        result:=i;
        break;
      end;
    end;
  end;
  lastTag   :=atag;
  lastTagIdx:=result;
end;

function TTL2Reference.AddRoot(const aroot:AnsiString):integer;
var
  i:integer;
begin
  if aroot='' then exit(0);

  for i:=0 to cntRoots-1 do
  begin
    if arRoots[i]=aroot then
    begin
      lastRoot:=i+1;
      exit(lastRoot);
    end;
  end;
  if cntRoots=Length(arRoots) then
    SetLength(arRoots,Length(arRoots)+16);
  arRoots[cntRoots]:=aroot;
  inc(cntRoots);

  lastRoot:=cntRoots;
  result:=lastRoot;
end;

{%ENDREGION Addition}

function TTL2Reference.AddLoadedRef(idx:integer):integer;
begin
  if (idx<0) or (Length(LoadedRefs)=0) then exit(-1);

  if cntRefs>=Length(arRefs) then
    SetLength(arRefs,Length(arRefs)+increment*20);

  move(LoadedRefs[idx],arRefs[cntRefs],SizeOf(tRefData));
{
  with arRefs[cntRefs] do
  begin
//    id   :=MaxID; inc(MaxID);
    _dir :=LoadedRefs[idx]._dir;
    _file:=LoadedRefs[idx]._file;
    _tag :=LoadedRefs[idx]._tag;
    _line:=LoadedRefs[idx]._line;
    _dup :=LoadedReds[idx]._dup;
    _flag:=LoadedRefs[idx]._flag;
//    result:=id;
  end;
}
  result:=cntRefs;

  inc(cntRefs);
end;

function TTL2Reference.AddLinkChecked(aref,aload:integer):integer;
var
  oidx:integer;
  found:boolean;
begin
  if aref<0 then exit(AddLoadedLink(aload));

  result:=aref;
  if (aload<0) or (Length(LoadedRefs)=0) then exit;

  while aload>=0 do
  begin
    // search new ref in chain of old
    found:=false;
    oidx:=aref;
    while oidx>=0 do
    begin
      // not sure what we need to check for same line number
      if (arRefs[oidx]._dir =LoadedRefs[aload]._dir ) and 
         (arRefs[oidx]._file=LoadedRefs[aload]._file) and
         (arRefs[oidx]._tag =LoadedRefs[aload]._tag ) {and
         (arRefs[oidx]._line=LoadedRefs[aload]._line)} then
      begin
        found:=true;
        break;
      end;

      oidx:=arRefs[oidx]._dup;
    end;

    // add link as first to not break checking cycle
    if not found then
    begin
      oidx:=result;
      result:=AddLoadedRef(aload);
      arRefs[result]._dup:=oidx;
    end;

    aload:=LoadedRefs[aload]._dup;
  end;
end;

// This will add link to existing ref array and return 1st index
function TTL2Reference.AddLoadedLink(aload:integer):integer;
var
  lidx:integer;
begin
  result:=AddLoadedRef(aload);
  if result<0 then exit;
  // add link to the end
  lidx:=result;
  aload:=LoadedRefs[aload]._dup;
  while aload>=0 do
  begin
    arRefs[lidx]._dup:=AddLoadedRef(aload);  // add loaded dup as new dup
    lidx:=arRefs[lidx]._dup;                 // next dup will be added to new
    aload:=LoadedRefs[aload]._dup;           // next loaded dup
  end;
end;

function TTL2Reference.CopyLink(const aref:TTL2Reference; aidx:integer):integer;
begin
  result:=-1;
  while aidx>0 do
  begin
    result:=AddDouble(result,AddRef(aref.GetFile(aidx),aref.GetTag(aidx),aref.GetLine(aidx)));
    aidx  :=aref.Dupe[aidx];
  end;
end;

function TTL2Reference.AddDouble(aref,adupe:integer):integer;
var
  oldref:integer;
begin
  result:=aref;
  if adupe>=0 then
  begin
    if aref<0 then
      result:=adupe
    else
    begin
      oldref:=arRefs[aref]._dup;
      arRefs[aref ]._dup:=adupe;
      arRefs[adupe]._dup:=oldref;
    end;
  end;
end;

function TTL2Reference.AddRef(const afile,atag:AnsiString; aline:integer):integer;
var
  ldir,lfile:AnsiString;
begin
  if cntRefs>=Length(arRefs) then
    SetLength(arRefs,Length(arRefs)+increment*20);

  ldir :=ExtractPath(afile);
  lfile:=ExtractName(afile);
  with arRefs[cntRefs] do
  begin
    _dir :=AddDir (ldir);
    _file:=AddFile(lfile);
    _tag :=AddTag (atag);
    _line:=ABS(aline);
    _dup :=-1;
    _root:=lastRoot;
    _flag:=0;
//!!
    if Pos('/SKILLS/',afile)=7 then
      _flag:=_flag or rfIsSkill;

    if aline<0 then
      _flag:=_flag or rfIsTranslate;
  end;
  result:=cntRefs;
  inc(cntRefs);
end;

function TTL2Reference.GetRef(idx:integer; var afile,atag:AnsiString):integer;
begin
  if (idx>=0) and (idx<cntRefs) then
  begin
    with arRefs[idx] do
    begin
      afile :=names.str[arDirs[_dir].txt] + names.str[arFiles[_file].txt];
      atag  :=names.str[arTags[_tag].txt];
      result:=_line;
    end;
  end
  else
    result:=-1;
end;

{%REGION Getters /fold}

function TTL2Reference.GetLine(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntRefs) then
    result:=arRefs[idx]._line
  else
    result:=-1;
end;

function TTL2Reference.GetRoot(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRefs) then
    result:=GetRootByIdx(arRefs[idx]._root)
  else
    result:='';
end;

function TTL2Reference.GetDir(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRefs) then
    result:=names.str[arDirs[arRefs[idx]._dir].txt]
  else
    result:='';
end;

function TTL2Reference.GetFName(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRefs) then
    result:=names.str[arFiles[arRefs[idx]._file].txt]
  else
    result:='';
end;

function TTL2Reference.GetFile(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRefs) then
  begin
    result:=
      names.str[arDirs [arRefs[idx]._dir ].txt] +
      names.str[arFiles[arRefs[idx]._file].txt]
  end
  else
    result:='';
end;

function TTL2Reference.GetTag(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRefs) then
    result:=names.str[arTags[arRefs[idx]._tag].txt]
  else
    result:='';
end;

function TTL2Reference.GetRootByIdx(idx:integer):AnsiString;
begin
  if (idx>0) and (idx<=cntRoots) then
    result:=arRoots[idx-1]
  else if cntRoots=1 then
    result:=arRoots[0]
  else
    result:='';
end;

function TTL2Reference.GetDirByIdx(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntDirs) then
    result:=names.str[arDirs[idx].txt]
  else
    result:='';
end;

function TTL2Reference.GetFileByIdx(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntFiles) then
    result:=names.str[arFiles[idx].txt]
  else
    result:='';
end;

function TTL2Reference.GetTagByIdx(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntTags) then
    result:=names.str[arTags[idx].txt]
  else
    result:='';
end;
{%ENDREGION Getters}


//--- Duplicates ---

function TTL2Reference.GetDup(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntRefs) then
    result:=arRefs[idx]._dup
  else
    result:=-1;
end;

procedure TTL2Reference.SetDup(idx:integer; aval:integer);
begin
  // theoretically can be less than zero if reference to base
  if (idx>=0) and (idx<cntRefs) {and
     (aval>=0) and (aval<cntRefs)} then
    arRefs[idx]._dup:=aval;
end;

//--- Option flag ---

function TTL2Reference.GetFlag(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntRefs) then
    result:=arRefs[idx]._flag
  else
    result:=0;
end;

procedure TTL2Reference.SetFlag(idx:integer; aval:integer);
begin
  if (idx>=0) and (idx<cntRefs) then
    arRefs[idx]._flag:=aval;
end;

//--- Separate option ---

function TTL2Reference.GetOpt(idx,aflag:integer):boolean;
begin
  if (idx>=0) and (idx<cntRefs) then
    result:=(arRefs[idx]._flag and aflag)<>0
  else
    result:=false;
end;

procedure TTL2Reference.SetOpt(idx,aflag:integer; aval:boolean);
var
  f:integer;
begin
  if (idx>=0) and (idx<cntRefs) then
  begin
    f:=(arRefs[idx]._flag and not aflag);
    if aval then
      f:=f or aflag;
    arRefs[idx]._flag:=f;
  end;
end;

//-----  -----
{
  ld,lf and lt arrays used for case when some elements can be deleted.
  but if we have deleted REFs then we must use IDs (not indexes) for dupes here
  and for refs in line infos
}
procedure TTL2Reference.SaveToStream(astrm:TStream);
var
  ld,lf,lt:array of integer;
  i,lidx,lrefpos,lpos:integer;
begin
  try
    lrefpos:=astrm.Position;
    astrm.WriteDWord(0);

    // roots
    astrm.WriteDWord(cntRoots);
    for i:=0 to cntRoots-1 do
      astrm.WriteAnsiString(arRoots[i]);
    
    // dirs
    SetLength(ld,cntDirs);
    lidx:=0;
    lpos:=astrm.Position;
    astrm.WriteDWord(0);
    for i:=0 to cntDirs-1 do
    begin
      if arDirs[i].cnt>0 then
      begin
        astrm.WriteAnsiString(names.str[arDirs[i].txt]);
        ld[i]:=lidx;
        inc(lidx);
      end
      // debug
      else ld[i]:=-1;
    end;
    astrm.WriteDWordAt(lidx,lpos);

    // files
    SetLength(lf,cntFiles);
    lidx:=0;
    lpos:=astrm.Position;
    astrm.WriteDWord(0);
    for i:=0 to cntFiles-1 do
    begin
      if arFiles[i].cnt>0 then
      begin
        astrm.WriteAnsiString(names.str[arFiles[i].txt]);
        lf[i]:=lidx;
        inc(lidx);
      end
      // debug
      else lf[i]:=-1;
    end;
    astrm.WriteDWordAt(lidx,lpos);
    
    // tags
    SetLength(lt,cntTags);
    lidx:=0;
    lpos:=astrm.Position;
    astrm.WriteDWord(0);
    for i:=0 to cntTags-1 do
    begin
      if arTags[i].cnt>0 then
      begin
        astrm.WriteAnsiString(names.str[arTags[i].txt]);
        lt[i]:=lidx;
        inc(lidx);
      end
      // debug
      else lt[i]:=-1;
    end;
    astrm.WriteDWordAt(lidx,lpos);

    // refs
    lidx:=0;
    lpos:=astrm.Position;
    astrm.WriteDWord(0);
    for i:=0 to cntRefs-1 do
    begin
      with arRefs[i] do
        if _line>0 then
        begin
          astrm.WriteDWord(ld[_dir ]  );
          astrm.WriteDWord(lf[_file]  );
          astrm.WriteDWord(lt[_tag ]  );
          astrm.WriteDWord(_line      );
          astrm.WriteDWord(_root      );
          astrm.WriteDWord(_flag      ); // skills, translate etc
          astrm.WriteDWord(DWord(_dup));
          inc(lidx);
        end
    end;
    astrm.WriteDWordAt(lidx,lpos);

    astrm.WriteDWordAt((astrm.Position-lrefpos-SizeOf(DWord)) or
        (RefVersion shl 24),lrefpos);
  except
  end;
  SetLength(ld,0);
  SetLength(lf,0);
  SetLength(lt,0);
end;

//-----  -----

procedure TTL2Reference.LoadFromStream(astrm:TStream);
type
  tOldRefData = packed record
    // constant part (fills on scan)
    _file: integer;
    _tag : integer;
    _line: integer;
    // runtime part
    _dup : integer; // =0 = dupe in preloads
                    // >0 = ref # +1
                    // <0 - base, count of doubles
    _flag: integer;
  end;

var
  oldref:tOldRefData;
  // old saves arrays to skip useless (lost from dupes) refs
  larFiles,larTags:array of AnsiString;
  // reindexig arrays
  laiRoots, laiDirs,laiFiles,laiTags:array of integer;
  ls:AnsiString;
  lflag,lpos,i,lrefsize,lsize,linfosize:integer;
  ltmp:integer;
begin
  lpos    :=astrm.Position;
  lrefsize:=0;
  try
    lrefsize:=astrm.ReadDWord();
    lflag   :=lrefsize shr 24; // RefVersion
    lrefsize:=(lrefsize and $00FFFFFF)+SizeOf(DWord);

    if lflag<>0 then
    begin
      laiDirs :=nil;
      laiFiles:=nil;
      laiTags :=nil;

      // roots
      lsize:=astrm.ReadDWord();
      if arRoots=nil then SetLength(arRoots,lsize);
      SetLength(laiRoots,lsize);
      for i:=0 to lsize-1 do
        laiRoots[i]:=AddRoot(astrm.ReadAnsiString());

      // dirs
      lsize:=astrm.ReadDWord();
      if arDirs=nil then SetLength(arDirs,lsize);
      SetLength(laiDirs,lsize);
      for i:=0 to lsize-1 do
        laiDirs[i]:=AddDir(astrm.ReadAnsiString());

      // files
      lsize:=astrm.ReadDWord();
      if arFiles=nil then SetLength(arFiles,lsize);
      SetLength(laiFiles,lsize);
      for i:=0 to lsize-1 do
        laiFiles[i]:=AddFile(astrm.ReadAnsiString());

      // tags
      lsize:=astrm.ReadDWord();
      if arTags=nil then SetLength(arTags,lsize);
      SetLength(laiTags,lsize);
      for i:=0 to lsize-1 do
        laiTags[i]:=AddTag(astrm.ReadAnsiString());

      // refs
      lsize:=astrm.ReadDWord();
      SetLength(LoadedRefs,lsize);
      for i:=0 to lsize-1 do
      begin
        with LoadedRefs[i] do
        begin
          _dir :=laiDirs [astrm.ReadDWord()];
          _file:=laiFiles[astrm.ReadDWord()];
          _tag :=laiTags [astrm.ReadDWord()];
          _line:=astrm.ReadDWord();

          _root:=astrm.ReadDWord();
          if _root>0 then
            _root:=laiRoots[_root];

          _flag:=astrm.ReadDWord();   // skills, translate etc
          _dup :=Integer(astrm.ReadDWord());
        end;
      end;

      SetLength(laiRoots,0);
      SetLength(laiDirs ,0);
      SetLength(laiFiles,0);
      SetLength(laiTags ,0);

    end
    // Old format (no dupe links but refs saved)
    else
    begin
      larFiles:=nil;
      larTags :=nil;

      // files
      lsize:=astrm.ReadDWord();
      if arFiles=nil then SetLength(arFiles,lsize);
      SetLength(larFiles,lsize);
      for i:=0 to lsize-1 do
        larFiles[i]:=astrm.ReadAnsiString();

      // tags
      lsize:=astrm.ReadDWord();
      if arTags=nil then SetLength(arTags,lsize);
      SetLength(larTags,lsize);
      for i:=0 to lsize-1 do
        larTags[i]:=astrm.ReadAnsiString();

      // refs
      lsize:=astrm.ReadDWord();
      SetLength(LoadedRefs,lsize);
      linfosize:=astrm.ReadWord();

      FillChar(oldref,SizeOf(oldref),0);
      for i:=0 to lsize-1 do
      begin
        astrm.ReadBuffer(oldref,linfosize);
        ls:=larFiles[oldref._file];
        with LoadedRefs[i] do
        begin
          _dir :=AddDir (ExtractPath(ls));
          _file:=AddFile(ExtractName(ls));
          _tag :=AddTag (larTags[oldref._tag]);
          _line:=oldref._line;
          _root:=0;
          _flag:=oldref._flag;
          _dup :=-1;
        end;
        // pre-old saves, didn't has flag field
        // "Translate" flag can't be detected
        if linfosize=RefSizeV1 then
        begin
          lflag:=0;
          if Pos('SKILLS',ls)=7 then lflag:=lflag or rfIsSkill;
          LoadedRefs[i]._flag:=lflag;
        end;
      end;

      SetLength(larFiles,0);
      SetLength(larTags ,0);
      
      if astrm.Position<(lpos+lrefsize) then
      begin
        ltmp:=AddRoot(astrm.ReadAnsiString());
        for i:=0 to lsize-1 do
          LoadedRefs[i]._root:=ltmp;
      end;

    end;

  except
  end;

  astrm.Position:=lpos+lrefsize;
end;

procedure TTL2Reference.DoneLoading;
begin
  SetLength(LoadedRefs,0);
end;

//-----  -----

procedure TTL2Reference.Init;
begin
  FillChar(self,SizeOf(TTL2Reference),#0);

  names.Init(true);

  lastTagIdx:=-1;
end;

procedure TTL2Reference.Free;
begin
  names.Clear;
//  SetLength(LoadedRefs,0);

  SetLength(arRoots,0); cntRoots:=0;
  SetLength(arRefs ,0); cntRefs :=0;
  SetLength(arFiles,0); cntFiles:=0;
  SetLength(arDirs ,0); cntDirs :=0;
  SetLength(arTags ,0); cntTags :=0;
end;

end.
