{
  This object don't have any text info.
  It saves just text reference info like: file-line-tag
  and reference to base placement for doubles
}
{NOTES:
    Dupes stores as index of next double, less than 0 means end of link
    LoadedRefs is buffer to reserve unreaded yet dats (dupes) and
      keep indexes between text and refs coz refs loading before text

    Use Index array (like text lines), element - index of ref chain start
    no need IDs then (and REF field in text array too)
    if we have Text without ref, then add double, delete doubles. How to recognize,
    delete or not text after all refs deleting? Flag in index?
    if only keep flag in Index
}
{TODO: Separate text cache to dir, files, tags.}
{TODO: OnDeleteRefGroup event for DeleteDir/File/Tag}
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
      tRefTextArr = array of tRefText;
      PRefData = ^tRefData;
      tRefData = packed record
        // constant part (fills on scan)
        _dir : integer;
        _file: integer;
        _tag : integer;
        _line: integer;
        // runtime part
        _root: integer;
        _flag: integer;
        _dup : integer; // index of next ref.
                        // positive - index of next ref element, negative (-1) is the end
      end;

  private
    arRefs  : array of tRefData;
    arIndex : array of integer; // variant: "empty"=-1; else 1byte for "noref", 3 byte for index
    arDirs  : tRefTextArr;
    arFiles : tRefTextArr;
    arTags  : tRefTextArr;
    names   : tTextCache;
    arRoots : array of AnsiString;

    // last used
    lastDir : AnsiString;
    lastFile: AnsiString;
    lastTag : AnsiString;
    lastTagIdx:integer;
    lastRoot: integer;

    cntRefs : integer; // referals
    cntIndex: integer; // same as text lines
    cntDirs : integer; // dirs
    cntFiles: integer; // filenames
    cntTags : integer; // tags
    cntRoots: integer;

    procedure IntDeleteRef(aidx:integer);
    procedure DeleteRef   (aid :integer);

    procedure DeleteDir (const fdir :AnsiString);
    procedure DeleteFile(const fname:AnsiString);
    procedure DeleteTag (const atag :AnsiString);
    function  AddDir    (const fdir :AnsiString):integer;
    function  AddFile   (const fname:AnsiString):integer;
    function  AddTag    (const atag :AnsiString):integer;
    function  AddWithCheck(const atxt:AnsiString; var alast:AnsiString;
        var arr:tRefTextArr; var acnt:integer; aincr:integer):integer;
    function NewRefInt(adir,afile,atag,aline,aflag:integer):integer;

    function  GetOpt (aidx,aflag:integer):boolean;
    procedure SetOpt (aidx,aflag:integer; aval:boolean);
    function  GetFlag(aidx:integer):integer;
    procedure SetFlag(aidx:integer; aval:integer);
    function  GetDup (aidx:integer):integer;
    procedure SetDup (aidx:integer; aval:integer);

    function GetRootByIdx(aidx:integer):AnsiString;
    function GetDirByIdx (aidx:integer):AnsiString;
    function GetFileByIdx(aidx:integer):AnsiString;
    function GetTagByIdx (aidx:integer):AnsiString;

    function  GetRef  (idx:integer):integer;
    function  GetNoRef(idx:integer):boolean;
    procedure SetNoRef(idx:integer; aval:boolean);

  public
    procedure Init;
    procedure Free;

    // add ref from another reference class
    function CopyLink(dst:integer; const aref:TTL2Reference; aidx:integer):integer;

    function NewRef(const afile,atag:AnsiString; aline:integer):integer;
    function AddRef(idx:integer; aref:integer):integer;

    function GetPlace(aidx:integer; var afile,atag:AnsiString):integer;  // unised atm
    function GetLine (aidx:integer):integer;
    function GetDir  (aidx:integer):AnsiString;
    function GetFName(aidx:integer):AnsiString;
    function GetFile (aidx:integer):AnsiString;   // Dir+FName
    function GetTag  (aidx:integer):AnsiString;
    function GetRoot (aidx:integer):AnsiString;
    // moved to public coz used for scan
    function AddRoot(const aroot:AnsiString):integer;

    procedure SaveToStream  (astrm:TStream);
    procedure LoadFromStream(astrm:TStream);

    // idx physical index of array
    property  RefCount :integer read cntRefs;
    property  DirCount :integer read cntDirs;
    property  FileCount:integer read cntFiles;
    property  TagCount :integer read cntTags;
    property  RootCount:integer read cntRoots;
    property  Dirs [aidx:integer]:AnsiString read GetDirByIdx;
    property  Files[aidx:integer]:AnsiString read GetFileByIdx;
    property  Tags [aidx:integer]:AnsiString read GetTagByIdx;
    property  Root [aidx:integer]:AnsiString read GetRootByIdx;

    // index of next place of line
    property  Dupe       [aidx:integer]:integer         read GetDup  write SetDup;
    property  Flag       [aidx:integer]:integer         read GetFlag write SetFlag;
    property  IsSkill    [aidx:integer]:boolean index 1 read GetOpt  write SetOpt;
    property  IsTranslate[aidx:integer]:boolean index 2 read GetOpt  write SetOpt;

    // idx is text line index
    property  Ref  [idx:integer]:integer read GetRef; default;
    property  NoRef[idx:integer]:boolean read GetNoRef write SetNoRef;
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
  rfNoRef   = 1 shl 24; // used as Index flag
  rfNoChain = 1 shl 23; // $800000 "no ref" and no others
  rfNoFlags = $7FFFFF;

  rfIsNewChain  = $80;  // used for save/load only
  rfIsNoRef     = $40;  // used for save/load only
  rfIsSkill     = 1;
  rfIsTranslate = 2;
  rfIsDeleted   = 4;
  rfIsDummy     = 8;

const
  increment = 50;

procedure TTL2Reference.SetNoRef(idx:integer; aval:boolean); inline;
begin
  if arIndex=nil then exit;

  if arIndex[idx]=-1 then
    arIndex[idx]:=rfNoChain    or rfNoRef
  else
    arIndex[idx]:=arIndex[idx] or rfNoRef;
end;

function TTL2Reference.GetNoRef(idx:integer):boolean; inline;
begin
  if arIndex=nil then exit(true);
  result:=((arIndex[idx] and rfNoRef)<>0) and (arIndex[idx]<>-1);
end;

function TTL2Reference.GetRef(idx:integer):integer;
begin
  if arIndex=nil then exit(-1);
  result:=arIndex[idx];
  if result<>-1 then
  begin
    if (result and rfNoChain)<>0 then exit(-1);
    result:=result and rfNoFlags;
  end;
end;

procedure TTL2Reference.IntDeleteRef(aidx:integer);
begin
  dec(arDirs [arRefs[aidx]._dir ].cnt);
  dec(arFiles[arRefs[aidx]._file].cnt);
  dec(arTags [arRefs[aidx]._tag ].cnt);
  arRefs[aidx]._flag:=arRefs[aidx]._flag or rfIsDeleted;
  //!! check if it was a chain start
end;

procedure TTL2Reference.DeleteRef(aid:integer);
begin
  while aid>=0 do
  begin
    IntDeleteRef(aid);
    aid:=arRefs[aid]._dup;
  end;
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
{
  if same as last - increase count
  save names count. Add
  if names count the same, exists. Search, increase count.
  else check array size, add
}

function TTL2Reference.AddWithCheck(const atxt:AnsiString; var alast:AnsiString;
    var arr:tRefTextArr; var acnt:integer; aincr:integer):integer;
var
  i,lcnt,lidx:integer;
begin
  if atxt='' then exit(-1);

  if (acnt>0) and (atxt=alast) then
  begin
    inc(arr[acnt-1].cnt);
    exit(acnt-1);
  end;

  alast:=atxt;

  lcnt:=names.Count;
  lidx:=names.Add(PAnsiChar(atxt));
  // new dir record
  if lcnt<names.Count then
  begin
    if acnt>=Length(arr) then
      SetLength(arr,acnt+aincr);

    arr[acnt].txt:=lidx;
    arr[acnt].cnt:=1;

    result:=acnt;
    inc(acnt);
  end
  else // search for old
  begin
    for i:=0 to acnt-1 do
    begin
      if arr[i].txt=lidx then
      begin
        inc(arr[i].cnt);
        exit(i);
      end;
    end;
    // must not happen but...
    result:=-1;
  end;
end;

function TTL2Reference.AddDir(const fdir:AnsiString):integer;
begin
  result:=AddWithCheck(fdir,lastDir,arDirs,cntDirs,increment);
end;

function TTL2Reference.AddFile(const fname:AnsiString):integer;
begin
  result:=AddWithCheck(fname,lastFile,arFiles,cntFiles,increment*10);
end;

function TTL2Reference.AddTag(const atag:AnsiString):integer;
begin
  if atag='' then exit(0);

  // can be several times. So, save idx too.
  if (lastTagIdx>=0) and (atag=lastTag) then
  begin
    inc(arTags[lastTagIdx].cnt);
    exit(lastTagIdx);
  end;

  result:=AddWithCheck(atag,lastTag,arTags,cntTags,increment);

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

// dst and aidx - line index
function TTL2Reference.CopyLink(dst:integer; const aref:TTL2Reference; aidx:integer):integer;
var
  lfcnt,lfile:integer;
  ldcnt,ldir :integer;
  lidx,ltag:integer;
  lnoref, lfound:boolean;
begin
  result:=-1;
  if {(aref=nil) or }(aref.cntIndex=0) then exit;

  lnoref:=aref.NoRef[aidx];

  aidx:=aref.Ref[aidx]; // line index to ref index
  while aidx>=0 do
  begin
    lfound:=false;
    
    lfcnt:=cntFiles;
    ldcnt:=cntDirs;
    ldir :=AddDir (aref.GetDir  (aidx));
    lfile:=AddFile(aref.GetFName(aidx));
    ltag :=AddTag (aref.GetTag  (aidx));

    // if BOTH File and Dir exists already
    if (lfcnt=cntFiles) and (ldcnt=cntDirs) then
    begin
      lidx:=Ref[dst];
      while lidx>=0 do
      begin
        if (arRefs[lidx]._file=lfile) and
           (arRefs[lidx]._dir =ldir ) and
           (arRefs[lidx]._tag =ltag ) then
        begin
          lfound:=true;
          break;
        end;
        lidx:=arRefs[lidx]._dup;
      end;
    end;

    if not lfound then
    begin
      AddRef(dst,NewRefInt(ldir,lfile,ltag,aref.GetLine(aidx),aref.GetFlag(aidx)));
    end;

    aidx:=aref.Dupe[aidx];
  end;

  NoRef[dst]:=lnoref;
end;

function TTL2Reference.NewRefInt(adir,afile,atag,aline,aflag:integer):integer;
begin
  if cntRefs>=Length(arRefs) then
    SetLength(arRefs,Length(arRefs)+increment*20);

  with arRefs[cntRefs] do
  begin
    _dir :=adir;
    _file:=afile;
    _tag :=atag;
    _line:=ABS(aline);
    _dup :=-1;
    _root:=lastRoot;
    _flag:=aflag;
  end;
  result:=cntRefs;
  inc(cntRefs);
end;

function TTL2Reference.NewRef(const afile,atag:AnsiString; aline:integer):integer;
var
  lflag,ldir,lfile,ltag:integer;
begin
  if afile<>'' then
  begin
    if cntRefs>=Length(arRefs) then
      SetLength(arRefs,Length(arRefs)+increment*20);

    ldir :=AddDir (ExtractPath(afile));
    lfile:=AddFile(ExtractName(afile));
    ltag :=AddTag (atag);

    lflag:=0;
    if Pos('/SKILLS/',afile)=7 then
      lflag:=lflag or rfIsSkill;

    if aline<0 then
      lflag:=lflag or rfIsTranslate;

    result:=NewRefInt(ldir,lfile,ltag,aline,lflag);
  end
  else
    result:=rfNoRef or rfNoChain; // "no ref" without ref index
end;

function TTL2Reference.AddRef(idx:integer; aref:integer):integer;
var
  i:integer;
begin
  if idx>cntIndex then exit(-1); // it WRONG if will happen

  if idx=cntIndex then
  begin
    i:=0;
    if arIndex=nil then
      i:=16000
    else if cntIndex>=Length(arIndex) then
      i:=Length(arIndex)+increment*10;
    if i>0 then
    begin
      SetLength(arIndex,i);
      for i:=cntIndex to High(arIndex) do
        arIndex[i]:=-1;
    end;

    inc(cntIndex);
  end;

  // has no old ref, use new
  if arIndex[idx]=-1 then
     arIndex[idx]:=aref
  else // have old
  begin
    // "no ref" new - keep as flag
    if (aref and rfNoRef)<>0 then
      arIndex[idx]:=arIndex[idx] or rfNoRef
    else // aref as pure index
    begin
      // if real old, save flag + old as dup
      if (arIndex[idx] and rfNoChain)=0 then
      begin
        arRefs[aref]._dup:=arIndex[idx] and rfNoFlags;
        arIndex[idx]:=aref or (arIndex[idx] and rfNoRef);
      end
      else // old was just flag
        arIndex[idx]:=aref or rfNoRef;
    end;
  end;

  result:=0;
end;

{%REGION Ref info /fold}
function TTL2Reference.GetPlace(aidx:integer; var afile,atag:AnsiString):integer;
begin
  if (aidx>=0) and (aidx<cntRefs) then
  begin
    with arRefs[aidx] do
    begin
      afile :=names.str[arDirs[_dir].txt] + names.str[arFiles[_file].txt];
      atag  :=names.str[arTags[_tag].txt];
      result:=_line;
    end;
  end
  else
    result:=-1;
end;

function TTL2Reference.GetLine(aidx:integer):integer;
begin
  if (aidx>=0) and (aidx<cntRefs) then
    result:=arRefs[aidx]._line
  else
    result:=-1;
end;

function TTL2Reference.GetRoot(aidx:integer):AnsiString;
begin
  if (aidx>=0) and (aidx<cntRefs) then
    result:=GetRootByIdx(arRefs[aidx]._root)
  else
    result:='';
end;

function TTL2Reference.GetDir(aidx:integer):AnsiString;
begin
  if (aidx>=0) and (aidx<cntRefs) then
    result:=names.str[arDirs[arRefs[aidx]._dir].txt]
  else
    result:='';
end;

function TTL2Reference.GetFName(aidx:integer):AnsiString;
begin
  if (aidx>=0) and (aidx<cntRefs) then
    result:=names.str[arFiles[arRefs[aidx]._file].txt]
  else
    result:='';
end;

function TTL2Reference.GetFile(aidx:integer):AnsiString;
begin
  if (aidx>=0) and (aidx<cntRefs) then
  begin
    result:=
      names.str[arDirs [arRefs[aidx]._dir ].txt] +
      names.str[arFiles[arRefs[aidx]._file].txt]
  end
  else
    result:='';
end;

function TTL2Reference.GetTag(aidx:integer):AnsiString;
begin
  if (aidx>=0) and (aidx<cntRefs) then
    result:=names.str[arTags[arRefs[aidx]._tag].txt]
  else
    result:='';
end;

//--- Duplicates ---

function TTL2Reference.GetDup(aidx:integer):integer;
begin
  if (aidx>=0) and (aidx<cntRefs) then
    result:=arRefs[aidx]._dup
  else
    result:=-1;
end;

procedure TTL2Reference.SetDup(aidx:integer; aval:integer);
begin
  if (aidx>=0) and (aidx<cntRefs) {and
     (aval>=0) and (aval<cntRefs)} then
    arRefs[aidx]._dup:=aval;
end;

//--- Option flag ---

function TTL2Reference.GetFlag(aidx:integer):integer;
begin
  if (aidx>=0) and (aidx<cntRefs) then
    result:=arRefs[aidx]._flag
  else
    result:=0;
end;

procedure TTL2Reference.SetFlag(aidx:integer; aval:integer);
begin
  if (aidx>=0) and (aidx<cntRefs) then
    arRefs[aidx]._flag:=aval;
end;

//--- Separate option ---

function TTL2Reference.GetOpt(aidx,aflag:integer):boolean;
begin
  if (aidx>=0) and (aidx<cntRefs) then
    result:=(arRefs[aidx]._flag and aflag)<>0
  else
    result:=false;
end;

procedure TTL2Reference.SetOpt(aidx,aflag:integer; aval:boolean);
var
  f:integer;
begin
  if (aidx>=0) and (aidx<cntRefs) then
  begin
    f:=(arRefs[aidx]._flag and not aflag);
    if aval then
      f:=f or aflag;
    arRefs[aidx]._flag:=f;
  end;
end;

{%ENDREGION Ref info}

{%REGION Arrays getters}
function TTL2Reference.GetRootByIdx(aidx:integer):AnsiString;
begin
  if (aidx>0) and (aidx<=cntRoots) then
    result:=arRoots[aidx-1]
  else if cntRoots=1 then
    result:=arRoots[0]
  else
    result:='';
end;

function TTL2Reference.GetDirByIdx(aidx:integer):AnsiString;
begin
  if (aidx>=0) and (aidx<cntDirs) then
    result:=names.str[arDirs[aidx].txt]
  else
    result:='';
end;

function TTL2Reference.GetFileByIdx(aidx:integer):AnsiString;
begin
  if (aidx>=0) and (aidx<cntFiles) then
    result:=names.str[arFiles[aidx].txt]
  else
    result:='';
end;

function TTL2Reference.GetTagByIdx(aidx:integer):AnsiString;
begin
  if (aidx>=0) and (aidx<cntTags) then
    result:=names.str[arTags[aidx].txt]
  else
    result:='';
end;
{%ENDREGION Arrays getters}


//-----  -----

{
  ld,lf and lt arrays used for case when some elements can be deleted.
  but if we have deleted REFs then we must use IDs (not indexes) for dupes here
  and for refs in line infos
}
procedure TTL2Reference.SaveToStream(astrm:TStream);
var
  ld,lf,lt:array of integer;
  ldup, i,lidx,lcnt,lrefpos,lpos:integer;
  lflag:dword;

  // local to avoid ld, lf and lt arrays passing
  // if "no ref" only, write flag only
  function WriteOneElement(aref:PRefData; aflag:dword):boolean;
  begin
    if aref=nil then
    begin
      astrm.WriteDWord(rfIsNoRef{aflag});
      exit(true);
    end;

    result:=(aref^._flag and rfIsDeleted)=0;
    if result then
    begin
      astrm.WriteDWord((aref^._flag or aflag) or
                       (aref^._root shl 16));
      astrm.WriteDWord(ld[aref^._dir ]);
      astrm.WriteDWord(lf[aref^._file]);
      astrm.WriteDWord(lt[aref^._tag ]);
      astrm.WriteDWord(aref^._line    );
    end;
  end;

begin
  try
    lrefpos:=astrm.Position;
    astrm.WriteDWord(0);

    // roots
    astrm.WriteDWord(cntRoots);
    for i:=0 to cntRoots-1 do
      astrm.WriteAnsiString(arRoots[i]);
    
    // dirs without empty (deleted)
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

    // files without empty (deleted)
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
    
    // tags without empty (deleted)
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

    // refs chain by chain
    lcnt:=0;
    lidx:=0;
    lpos:=astrm.Position;
    astrm.WriteDWord(0);
    astrm.WriteDWord(0);

    {
      First chain element will have rfIsNewChain flag.
      "no ref" element writes flag only.
      end of chain is last or before IsNewChain-flagged element
    }
    for i:=0 to cntIndex-1 do
    begin
      ldup:=arIndex[i];
      if ldup<>-1 then // -1, ref, "noref" or ref+"noref"
      begin
        if (ldup and rfNoRef)<>0 then lflag:=rfIsNoRef else lflag:=0;
        ldup:=ldup and rfNoFlags; // real ref index
        // normal ref exists
        if (ldup and rfNoChain)=0 then
        begin
          inc(lidx);
          if WriteOneElement(@arRefs[ldup],rfIsNewChain+lflag) then
          begin
            inc(lcnt);
            ldup:=arRefs[ldup]._dup;
            while ldup>=0 do
            begin
              if WriteOneElement(@arRefs[ldup],0) then inc(lcnt);
              ldup:=arRefs[ldup]._dup;
            end;
          end;
        end
        // "no ref" only
        else if lflag=rfIsNoRef then
        begin
          inc(lidx);
          WriteOneElement(nil,lflag);
        end;
      end
    end;
    astrm.WriteDWordAt(lidx,lpos);    // length of Index array
    astrm.WriteDWordAt(lcnt,lpos+4);  // count of real refs

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
  lidx,lref:integer;
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

      // dirs (directly to existing)
      lsize:=astrm.ReadDWord();
      if arDirs=nil then SetLength(arDirs,lsize);
      SetLength(laiDirs,lsize);
      for i:=0 to lsize-1 do
        laiDirs[i]:=AddDir(astrm.ReadAnsiString());

      // files (directly to existing)
      lsize:=astrm.ReadDWord();
      if arFiles=nil then SetLength(arFiles,lsize);
      SetLength(laiFiles,lsize);
      for i:=0 to lsize-1 do
        laiFiles[i]:=AddFile(astrm.ReadAnsiString());

      // tags (directly to existing)
      lsize:=astrm.ReadDWord();
      if arTags=nil then SetLength(arTags,lsize);
      SetLength(laiTags,lsize);
      for i:=0 to lsize-1 do
        laiTags[i]:=AddTag(astrm.ReadAnsiString());

      // refs
      cntIndex:=astrm.ReadDword();
      SetLength(arIndex,cntIndex);
      cntRefs:=astrm.ReadDword();
      SetLength(arRefs,cntRefs);
      i:=0;
      lidx:=0;

      while i<cntRefs do
      begin
        lflag:=astrm.ReadDword();
        if lflag=rfIsNoRef then
        begin
          arIndex[lidx]:=rfNoRef;
          inc(lidx);
        end
        else
        begin
          if (lflag and rfIsNewChain)<>0 then
          begin
            arIndex[lidx]:=i;
            if (lflag and rfIsNoRef)<>0 then arIndex[lidx]:=arIndex[lidx] or rfNoRef;
            inc(lidx);
          end
          else
          begin
            arRefs[i-1]._dup:=i;
          end;

          with arRefs[i] do
          begin
            _root:=(lflag shr 16);
            if _root>0 then _root:=laiRoots[_root-1];
            _flag:=(lflag and $FFFF) and (not rfIsNewChain or rfIsNoRef);

            _dir :=laiDirs [astrm.ReadDWord()];
            _file:=laiFiles[astrm.ReadDWord()];
            _tag :=laiTags [astrm.ReadDWord()];
            _line:=astrm.ReadDWord();
            _dup:=-1;
          end;
          inc(i);
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
      cntRefs:=astrm.ReadDWord();
      cntIndex:=cntRefs;
      SetLength(arIndex,cntIndex);
      SetLength(arRefs,cntRefs);
      linfosize:=astrm.ReadWord();

      FillChar(oldref,SizeOf(oldref),0);
      for i:=0 to cntRefs-1 do
      begin
        arIndex[i]:=i;
        astrm.ReadBuffer(oldref,linfosize);
        ls:=larFiles[oldref._file];
        with arRefs[i] do
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
          arRefs[i]._flag:=lflag;
        end;
      end;

      SetLength(larFiles,0);
      SetLength(larTags ,0);
      
      if astrm.Position<(lpos+lrefsize) then
      begin
        lref:=AddRoot(astrm.ReadAnsiString());
        for i:=0 to lsize-1 do
          arRefs[i]._root:=lref;
      end;

    end;

  except
  end;

  astrm.Position:=lpos+lrefsize;
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
  lastDir :='';
  lastFile:='';
  lastTag :='';

  SetLength(arIndex,0); cntIndex:=0;
  SetLength(arRoots,0); cntRoots:=0;
  SetLength(arRefs ,0); cntRefs :=0;
  SetLength(arFiles,0); cntFiles:=0;
  SetLength(arDirs ,0); cntDirs :=0;
  SetLength(arTags ,0); cntTags :=0;
end;

end.
