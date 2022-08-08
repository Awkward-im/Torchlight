{TODO: export as UTF8 binary (UCS16LE right now) - add sign for type: UCS16, UTF8, w/zero}
unit RGDict;

interface

uses
  TextCache;

//--- Tags

type
  TExportDictType = (asTags, asText, asBin, asZBin{, asBin8, asZBin8});

type

  { TRGDict }

  TRGDict = object
  private
    type
      TDict = record
        hash:dword;
        case boolean of
          false: (name:PWideChar);
          true : (idx :cardinal);
      end;
  public
    type
      TRGOptions = set of (check_hash, check_text);
  private
    FCache   :TTextCache;
    FDict    :array of TDict;
    NameIdxs :array of integer;
    FCapacity:cardinal;
    FCount   :cardinal;
    FOptions :TRGOptions;
    FSorted  :boolean;
    FUseCache  :boolean;
    FTextSorted:boolean;

    function  GetHashIndex(akey:dword):integer;
    function  GetTextIndex(akey:PWideChar):integer;

    function  GetTextByHash(akey:dword    ):PWideChar;
    function  GetHashByText(akey:PWideChar):dword;
    function  GetTextByIdx (idx :cardinal ):PWideChar;
    function  GetHashByIdx (idx :cardinal ):dword;
    function  LoadBinary    (aptr:PByte):integer;
    function  LoadTagsFile  (aptr:PByte):integer;
    function  LoadDictionary(aptr:PByte):integer;
    function  LoadList      (aptr:PByte):integer;
    procedure InitCapacity(aval:cardinal);
  public
    procedure Init(usecache:boolean=true);
    procedure Clear;
    procedure SortText;
    procedure Sort;
    function  Exists(ahash:dword):boolean;
    // calculates Hash for key = -1
    function  Add(akey:dword; aval:PWideChar):dword;
    function  Add(akey:dword; const aval:AnsiString):dword;
    function  Import(aptr: PByte): integer;
    function  Import(const fname:AnsiString=''):integer;
    function  Import(const resname:string; restype:PChar):integer;
    procedure Export(const fname:AnsiString; afmt:TExportDictType=asTags; sortbyhash:boolean=true);

    property Tag    [akey:dword    ]:PWideChar read GetTextByHash;
    property Hash   [akey:PWideChar]:dword     read GetHashByText;
    property IdxHash[idx :cardinal ]:dword     read GetHashByIdx;
    property IdxTag [idx :cardinal ]:PWideChar read GetTextByIdx;

    property Capacity:cardinal   read FCapacity write InitCapacity;
    property Count   :cardinal   read FCount;
    property Options :TRGOptions read FOptions  write FOptions;
  end;

var
  RGTags:TRGDict;

//--- Objects

type
  TRGObject = object
  private
    FLastObject:pointer;
    FLastScene :pointer;
    FDict      :pointer;

    FLastSceneName:PWideChar;
    FLastObjId:dword;
    FVersion:integer;

    procedure SetVersion(aver:integer);
  public
    procedure Init;
    procedure Clear;

    function SelectScene(aname:PWideChar):pointer;
    function GetObjectById  (aid:dword):pointer;
    function GetObjectByName(aname:PWideChar):pointer;

    function GetObjectName():PWideChar;
    function GetObjectName(aid:dword):PWideChar;

    function GetObjectId(aname:PWideChar):dword;

    function GetPropsCount:integer;

    function GetProperty(aid:dword):pointer;
    function GetPropInfoByIdx (idx:integer; var aid:dword; var aname:PWideChar):integer;
    function GetPropInfoById  (aid:dword; var aname:PWideChar):integer;
    function GetPropInfoByName(aname:PWideChar; var aid:dword):integer;
    function GetPropInfoByName(aname:PWideChar; atype:integer; var aid:dword):integer;

    property Version:integer read FVersion write SetVersion;
  end;

function LoadLayoutDict(abuf:PWideChar; aver:integer; aUseThis:boolean=false):boolean;
function LoadLayoutDict(const resname:string; restype:PChar; aver:integer):boolean;
function LoadLayoutDict(const fname:AnsiString; aver:integer):boolean;


//===== Implementation =====

implementation

uses
  rgglobal,
  rglogging,
  rgmemory,
  RGIO.Text,
  rgnode;

const
  FCapStep = 256;
const
  defdictname = 'dictionary.txt';
  deftagsname = 'tags.dat';

const
  SIGN_UNICODE = $FEFF;
  SIGN_UTF8    = $BFBBEF;

//===== DAT tags =====

procedure TRGDict.Init(usecache:boolean=true);
begin
  FCapacity:=0;
  FCount   :=0;
  FOptions :=[];
  FUseCache:=usecache;
  if usecache then FCache.Init(false);
end;

procedure TRGDict.Clear;
var
  i:integer;
begin
  if FUseCache then FCache.Clear;

  if FCapacity>0 then
  begin
    if not FUseCache then
      for i:=0 to FCount-1 do
        FreeMem(FDict[i].name);
    FCount:=0;

    SetLength(FDict,0);
    SetLength(NameIdxs,0);
    FCapacity:=0;
  end;
end;

procedure TRGDict.InitCapacity(aval:cardinal);
begin
  if FCapacity=0 then
  begin
    FCapacity:=aval;
  end
  else
  begin
    FOptions:=[check_hash];
    if aval>FCapacity then
      aval:=aval div 2;
    FCapacity:=FCount+aval;
  end;

  if FUseCache then
  begin
    FCache.Count   :=FCapacity;
    FCache.Capacity:=FCapacity*16;
  end;

  SetLength(FDict,FCapacity);
//  SetLength(NameIdxs,FCapacity);
end;

//----- Sort -----
// Shell sort

procedure TRGDict.SortText;
var
  ltmp:integer;
  i,j,gap:longint;
begin
  if FTextSorted then exit;

  if FCapacity>Length(NameIdxs) then
    SetLength(NameIdxs,FCapacity);

  for i:=0 to FCount-1 do
    NameIdxs[i]:=i;

  gap:=FCount shr 1;
  while gap>0 do
  begin
    for i:=gap to FCount-1 do
    begin
      j:=i-gap;
      while (j>=0) and (CompareWide(IdxTag[NameIdxs[j]],IdxTag[NameIdxs[j+gap]])>0) do
      begin
        ltmp           :=NameIdxs[j+gap];
        NameIdxs[j+gap]:=NameIdxs[j];
        NameIdxs[j]    :=ltmp;
        dec(j,gap);
      end;
    end;
    gap:=gap shr 1;
  end;
  FTextSorted:=true;
end;

procedure TRGDict.Sort;
var
  ltmp:TDict;
  i,j,gap:longint;
begin
  if FSorted then exit;

  gap:=FCount shr 1;
  while gap>0 do
  begin
    for i:=gap to FCount-1 do
    begin
      j:=i-gap;
      while (j>=0) and (FDict[j].hash>FDict[j+gap].hash) do
      begin
        ltmp        :=FDict[j+gap];
        FDict[j+gap]:=FDict[j];
        FDict[j]    :=ltmp;
        dec(j,gap);
      end;
    end;
    gap:=gap shr 1;
  end;
  FSorted:=true;
  FTextSorted:=false;
end;

//--- Getters ---

function TRGDict.GetHashIndex(akey:dword):integer;
var
  L,R,i:integer;
begin
  result:=-1;

  // Binary Search

  if FSorted then
  begin
    L:=0;
    R:=FCount-1;
    while (L<=R) do
    begin
      i:=L+(R-L) div 2;
      if akey>FDict[i].hash then
        L:=i+1
      else
      begin
        if akey=FDict[i].hash then
        begin
          result:=i;
          break;
        end
        else
          R:=i-1;
      end;
    end;
  end
  else
  begin
    for i:=0 to FCount-1 do
    begin
      if FDict[i].hash=akey then
      begin
        result:=i;
        break;
      end;
    end;
  end;
end;

function TRGDict.GetTextIndex(akey:PWideChar):integer;
var
  L,R,i,ltmp:integer;
begin
  result:=-1;

  // Binary Search

  if FTextSorted then
  begin
    L:=0;
    R:=FCount-1;
    while (L<=R) do
    begin
      i:=L+(R-L) div 2;
      ltmp:=CompareWide(akey,IdxTag[NameIdxs[i]]);
      if ltmp>0 then
        L:=i+1
      else
      begin
        if ltmp=0 then
        begin
          result:=i;
          break;
        end
        else
          R:=i-1;
      end;
    end;
  end
  else
  begin
    for i:=0 to FCount-1 do
    begin
      if CompareWide(IdxTag[i],akey)=0 then
      begin
        result:=i;
        break;
      end;
    end;
  end;
end;

function TRGDict.GetTextByHash(akey:dword):PWideChar;
var
  i:integer;
begin
  i:=GetHashIndex(akey);
  if i<0 then
    result:=nil
  else
    result:=IdxTag[i];
end;

function TRGDict.GetHashByText(akey:PWideChar):dword;
var
  i:integer;
begin
  i:=GetTextIndex(akey);
  if i>=0 then
    result:=FDict[i].hash
  else
  begin
    Val(akey,result,i);
    if i>0 then
      result:=dword(-1);
  end;
end;

function TRGDict.GetTextByIdx(idx:cardinal):PWideChar;
begin
  if idx>=FCount then result:=nil
  else
   if FUseCache then
     result:=FCache[FDict[idx].idx]
   else
     result:=FDict[idx].name;
end;

function TRGDict.GetHashByIdx(idx:cardinal):dword;
begin
  if idx>=FCount then result:=dword(-1)
  else result:=FDict[idx].hash;
end;


function TRGDict.Exists(ahash:dword):boolean; inline;
begin
  result:=GetHashIndex(ahash)>=0;
end;

function TRGDict.Add(akey:dword; aval:PWideChar):dword;
var
  i:integer;
begin
  if {(akey=0) or} (akey=dword(-1)) then akey:=RGHash(aval,Length(aval));

  if (check_hash in FOptions) then
  begin
    if GetHashIndex(akey)>=0 then Exit(akey);
  end;

  if (check_text in FOptions) then
  begin
    i:=GetTextIndex(aval);
    if i>=0 then Exit(FDict[i].hash);
  end;

  // Add new element
  FSorted:=false;
  FTextSorted:=false;
  if FCount=FCapacity then
  begin
    FCapacity:=Align(FCapacity+FCapStep,FCapStep);
    SetLength(FDict,FCapacity);
  end;
  FDict[FCount].hash:=akey;

  if FUseCache then
    FDict[FCount].idx:=FCache.Append(aval)
  else
    CopyWide(FDict[FCount].name,aval);

  inc(FCount);
  result:=akey;
end;

function TRGDict.Add(akey:dword; const aval:AnsiString):dword;
begin
  result:=Add(akey,pointer(UTF8Decode(aval)));
end;

//----- Load -----

//--- binary

function TRGDict.LoadBinary(aptr:PByte):integer;
var
  pcw:PWideChar;
  i,llen:integer;
  lhash:dword;
begin
  result:=memReadInteger(aptr);
  InitCapacity(result);
  for i:=0 to result-1 do
  begin
    lhash:=memReadInteger(aptr);

    llen:=PWord(aptr)^;
    if llen=0 then
    begin
      inc(aptr,2);
      Add(lhash,nil);
    end
    else if PWideChar(aptr)[llen]=#0 then
    begin
      pcw:=PWideChar(aptr+2);
      Add(lhash,pcw);
      inc(aptr,2+llen*2);
    end
    else
    begin
      pcw:=memReadShortString(aptr);
      Add(lhash,pcw);
      FreeMem(pcw);
    end;
  end;
end;

//--- Tags.dat

function TRGDict.LoadTagsFile(aptr:PByte):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  lc,i:integer;
begin
  result:=0;

  WideToNode(aptr,0,lnode);
  if lnode<>nil then
  begin
    i:=0;
    lc:=GetChildCount(lnode);
    InitCapacity(lc div 2);
    while i<lc do
    begin
      pcw:=asString(GetChild(lnode,i));
//      if pcw<>nil then
      begin
        Add(AsUnsigned(GetChild(lnode,i+1)),pcw);
        inc(result);
      end;
      inc(i,2);
    end;
    DeleteNode(lnode);
  end;
end;

//--- dictionary.txt

function TRGDict.LoadDictionary(aptr:PByte):integer;
var
  lptr,lend:PAnsiChar;
  lcnt,lstart,i,p:integer;
  ltmp:cardinal;
  lhash:dword;
begin
  result:=0;

  lcnt:=0;
  lptr:=PAnsiChar(aptr);
  while lptr^<>#0 do
  begin
    if lptr^=#13 then inc(lcnt);
    inc(lptr);
  end;
  InitCapacity(lcnt);
  
  lend:=PAnsiChar(aptr);
  try
    for i:=0 to lcnt-1 do
    begin
      lptr:=lend;
      while not (lend^ in [#0,#13]) do inc(lend);
      lcnt:=lend-lptr;
      while lend^ in [#1..#32] do inc(lend);

      if lcnt>0 then
      begin
        if lptr^='-' then
          lstart:=1
        else
          lstart:=0;

        ltmp:=0;
        for p:=lstart to lcnt-1 do
        begin
          if (lptr[p] in ['0'..'9']) then
            ltmp:=(ltmp)*10+ORD(lptr[p])-ORD('0')
          else
          begin
            if lstart>0 then
              lhash:=dword(-integer(ltmp))
            else
              lhash:=ltmp;
            Add(lhash,Copy(lptr,p+1+1,lcnt-p-1)); //!!
            inc(result);
            break;
          end;
        end;
      end;

      if lend^=#0 then break;
    end;

  except
    if lcnt>0 then RGLog.Add('Possible problem with '+copy(lptr,1,lcnt));
    Clear;
  end;
end;

//--- raw text

function TRGDict.LoadList(aptr:PByte):integer;
var
  ls:AnsiString;
  lptr,lend:PByte;
  lcnt,i:integer;
begin
  result:=0;

  lcnt:=0;
  lptr:=aptr;
  while lptr^<>0 do
  begin
    if lptr^=13 then inc(lcnt);
    inc(lptr);
  end;
  InitCapacity(lcnt);
  
  lend:=aptr;
  for i:=0 to lcnt-1 do
  begin
    lptr:=lend;
    while not lend^ in [0,13] do inc(lend);
    SetString(ls, PansiChar(lptr), lend-lptr);
    while lend^ in [1..32] do inc(lend);

    if ls<>'' then
    begin
      Add(RGHashB(pointer(ls),Length(ls)),ls);
      inc(result);
    end;

    if lend^=0 then break;
  end;
end;

function TRGDict.Import(aptr:PByte):integer;
begin
  if (pword(aptr)^=SIGN_UNICODE) and (aptr[2]=ORD('[')) then
  begin
    result:=LoadTagsFile(aptr)
  end

  else if aptr[3]=0 then
  begin
    result:=LoadBinary(aptr)
  end

  else if (CHAR(aptr[0]) in ['-','0'..'9']) or
      (((pdword(aptr)^ and $FFFFFF)=SIGN_UTF8) and
       ((CHAR(aptr[3]) in ['-','0'..'9']))) then
  begin
    result:=LoadDictionary(aptr);
  end

  else
  begin
    result:=LoadList(aptr);
  end;

  if result>0 then
    Sort;
end;

function TRGDict.Import(const resname:string; restype:PChar):integer;
var
  res:TFPResourceHandle;
  Handle:THANDLE;
//  lstrm: TResourceStream;
  lptr,buf:PByte;
  lsize,loldcount:integer;
begin
  result:=0;
  loldcount:=FCount;

  res:=FindResource(hInstance, PChar(resname), restype);
  if res<>0 then
  begin
    Handle:=LoadResource(hInstance,Res);
    if Handle<>0 then
    begin
      lptr :=LockResource(Handle);
      lsize:=SizeOfResource(hInstance,res);

      GetMem(buf,lsize+2);
      move(lptr^,buf^,lsize);

      UnlockResource(Handle);
      FreeResource(Handle);

      buf[lsize  ]:=0;
      buf[lsize+1]:=0;

      result:=Import(buf);

      FreeMem(buf);
    end;
  end;
{
  lstrm:=TResourceStream.Create(HINSTANCE,resname, restype);
  try
    result:=Import(lstrm.Memory);
  finally
    lstrm.Free;
  end;
}
  if result=0 then
    RGLog.Add('Can''t load '+resname);

  result:=FCount-loldcount;
end;

function TRGDict.Import(const fname:AnsiString=''):integer;
var
  f:file of byte;
  buf:PByte;
  ls:AnsiString;
  i,loldcount:integer;
begin
  loldcount:=FCount;
  result:=0;
  
  // 1 - trying to open dict file (empty name = load defaults)
  if fname<>'' then
    ls:=fname
  else
    ls:=defdictname;

{$PUSH}
{$I-}
  Assign(f,ls);
  Reset(f);
  if IOResult<>0 then
  begin
    if fname='' then
    begin
      ls:=deftagsname;
      Assign(f,ls);
      Reset(f);
      if IOResult<>0 then
      begin
        if fname='' then
          ls:='default tags file'
        else
          ls:='tag info file "'+fname+'"';
        RGLog.Add('Can''t open '+ls);
        exit;
      end;
    end
    else
    begin
      RGLog.Add('Can''t open '+ls);
      exit;
    end;
  end;
  i:=FileSize(f);
  GetMem(buf,i+2);
  BlockRead(f,buf^,i);
  Close(f);
{$POP}

  buf[i  ]:=0;
  buf[i+1]:=0;

  result:=Import(buf);

  FreeMem(buf);

  if result=0 then
    RGLog.Add('Can''t load '+fname);

  result:=FCount-loldcount;
end;

procedure TRGDict.Export(const fname:AnsiString; afmt:TExportDictType=asTags; sortbyhash:boolean=true);
var
  sl:TRGLog;
  lnode:pointer;
  lstr:UnicodeString;
  i,j,ldelta,llen:integer;
begin
  case afmt of
    asTags: begin
      lnode:=AddGroup(nil,'TAGS');

      if sortbyhash then
      begin
        for i:=0 to FCount-1 do
        begin
          AddString (lnode,nil,IdxTag[i]);
          AddInteger(lnode,nil,Integer(FDict[i].hash));
        end
      end
      else
      begin
        if not FTextSorted then SortText;
        for i:=0 to FCount-1 do
        begin
          j:=NameIdxs[i];
          AddString (lnode,nil,IdxTag[j]);
          AddInteger(lnode,nil,Integer(FDict[j].hash));
        end;
      end;
      
      BuildTextFile(lnode,PChar(fname));
      DeleteNode(lnode);
    end;

    asText: begin
      sl.Init;

      if sortbyhash then
      begin
        for i:=0 to FCount-1 do
        begin
          Str(FDict[i].hash,lstr);
          sl.Add(UTF8Encode(lstr+':'+(IdxTag[i])));
        end;
      end
      else
      begin
        if not FTextSorted then SortText;
        for i:=0 to FCount-1 do
        begin
          j:=NameIdxs[i];
          Str(FDict[j].hash,lstr);
          sl.Add(UTF8Encode(lstr+':'+(IdxTag[j])));
        end;
      end;

      sl.SaveToFile(fname);
      sl.Free;
    end;

    asBin, asZBin: begin
      sl.Init;

      if afmt=asZBin then ldelta:=1 else ldelta:=0;

      sl.Add(FCount,4);
      if sortbyhash then
      begin
        for i:=0 to FCount-1 do
        begin
          sl.Add(FDict[i].hash,4);
          if IdxTag[i]=nil then
            sl.Add(0,2)
          else
          begin
            llen:=Length(IdxTag[i])+ldelta;
            sl.Add(llen,2);
            sl.Add(IdxTag[i],llen*SizeOf(WideChar));
          end;
        end;
      end
      else
      begin
        if not FTextSorted then SortText;
        for i:=0 to FCount-1 do
        begin
          j:=NameIdxs[i];
          sl.Add(FDict[j].hash,4);
          if IdxTag[i]=nil then
            sl.Add(0,2)
          else
          begin
            llen:=Length(IdxTag[j])+ldelta;
            sl.Add(llen,2);
            sl.Add(IdxTag[j],llen*SizeOf(WideChar));
          end;
        end;
      end;

      sl.SaveToFile(fname);
      sl.Free;
    end;
  end;
end;

//===== Layout =====

type
  PPropInfo = ^TPropInfo;
  TPropInfo = record
    name   :PWideChar;
    id     :dword;
    ptype  :integer;
  end;
type
  PObjInfo = ^TObjInfo;
  TObjInfo = record
    name   :PWideChar;
    start  :integer;
    count  :integer;
    id     :dword;
  end;
type
  PSceneInfo = ^TSceneInfo;
  TSceneInfo = record
    name   :PWideChar;
    start  :integer;
    count  :integer;
    id     :dword;
  end;
type
  PLayoutInfo = ^TLayoutInfo;
  TLayoutInfo = record
    scenes :array [0..3] of TSceneInfo;
    objects:array of TObjInfo;
    props  :array of TPropInfo;
    buf    :PWideChar;
  end;

var
  DictObjTL1:TLayoutInfo;
  DictObjTL2:TLayoutInfo;
  DictObjHob:TLayoutInfo;
  DictObjRG :TLayoutInfo;
  DictObjRGO:TLayoutInfo;

//----- Objects -----

procedure TRGObject.Init;
begin
  FVersion   :=verUnk;
  FDict      :=nil;
  FLastObject:=nil;
  FLastObjId :=dword(-1);

  FLastScene :=nil;
  FLastSceneName:=nil;
end;

procedure TRGObject.Clear;
begin
  Init;
end;

procedure TRGObject.SetVersion(aver:integer);
begin
  Init;
  case ABS(aver) of
    verTL1: FDict:=@DictObjTL1;
    verTL2: FDict:=@DictObjTL2;
    verRG : FDict:=@DictObjRG ;
    verRGO: FDict:=@DictObjRGO;
    verHob: FDict:=@DictObjHob;
  else
    exit;
  end;
  FVersion:=aver;
end;

function TRGObject.SelectScene(aname:PWideChar):pointer;
var
  i:integer;
begin
  // Get Default (if one scene only)
  if (aname=nil) or (aname^=#0) or
     (PLayoutInfo(FDict)^.scenes[1].id=dword(-1)) then
  begin
    FLastScene:=@(PLayoutInfo(FDict)^.scenes[0]);
    FLastSceneName:=PSceneInfo(FLastScene)^.name;
    exit(FLastScene);
  end;

  if CompareWide(FLastSceneName,aname)=0 then
    exit(FLastScene);

  FLastObject:=nil;
  FLastObjId :=dword(-1);

  i:=0;
  repeat
    FLastScene:=@(PLayoutInfo(FDict)^.scenes[i]);
    FLastSceneName:=PSceneInfo(FLastScene)^.name;
    if  CompareWide(PSceneInfo(FLastScene)^.name,aname)=0 then
      exit(FLastScene);
    inc(i);
  until (i=Length(PLayoutInfo(FDict)^.scenes)) or
                 (PLayoutInfo(FDict)^.scenes[i].id=dword(-1));

  FLastScene    :=nil;
  FLastSceneName:=nil;
  result        :=nil;
end;

function TRGObject.GetObjectByName(aname:PWideChar):pointer;
var
  i:integer;
begin
  if FLastScene<>nil then
    for i:=0 to PSceneInfo(FLastScene)^.count-1 do
    begin
      FLastObject:=@(PLayoutInfo(FDict)^.Objects[PSceneInfo(FLastScene)^.start+i]);
      if CompareWide(PObjInfo(FLastObject)^.name,aname)=0 then
        exit(FLastObject);
    end;

  FLastObject:=nil;
  FLastObjId :=dword(-1);
  result     :=nil;
end;

function TRGObject.GetObjectById(aid:dword):pointer;
var
  i:integer;
begin
  if FLastObjId=aid then
    exit(FLastObject);

  if FLastScene<>nil then
    for i:=0 to PSceneInfo(FLastScene)^.count-1 do
    begin
      FLastObject:=@(PLayoutInfo(FDict)^.Objects[PSceneInfo(FLastScene)^.start+i]);
      if PObjInfo(FLastObject)^.id=aid then
      begin
        FLastObjId:=aid;
        exit(FLastObject);
      end;
    end;

  if RGTags.Tag[aid]<>nil then
    RGLog.Add('!!!!! Got it '+HexStr(aid,8));
  
  
  FLastObject:=nil;
  FLastObjId :=dword(-1);
  result     :=nil;
  RGLog.Add('Object with id=0x'+HexStr(aid,8)+' was not found');
end;

function TRGObject.GetObjectId(aname:PWideChar):dword;
begin
  if GetObjectByName(aname)<>nil then
    result:=PObjInfo(FLastObject)^.id
  else
    result:=dword(-1);
end;

function TRGObject.GetObjectName():PWideChar;
begin
  if FLastObject<>nil then
    result:=PObjInfo(FLastObject)^.name
  else
    result:=nil;
end;

function TRGObject.GetObjectName(aid:dword):PWideChar;
begin
  if GetObjectById(aid)<>nil then
    result:=GetObjectName()
  else
    result:=nil;
end;

function TRGObject.GetPropsCount:integer;
begin
  if FLastObject<>nil then
    result:=PObjInfo(FLastObject)^.count
  else
    result:=0;
end;

function TRGObject.GetProperty(aid:dword):pointer;
var
  lprop:PPropInfo;
  i:integer;
begin
  if FLastObject<>nil then
    for i:=0 to PObjInfo(FLastObject)^.count-1 do
    begin
      lprop:=@(PLayoutInfo(FDict)^.Props[PObjInfo(FLastObject)^.start+i]);
      if lprop^.id=aid then
        exit(lprop);
    end;

  result:=nil;
end;

function TRGObject.GetPropInfoByIdx(idx:integer; var aid:dword; var aname:PWideChar):integer;
begin
  if FLastObject<>nil then
  begin
    if (idx>=0) and (idx<PObjInfo(FLastObject)^.count) then
    begin
      with PLayoutInfo(FDict)^.Props[PObjInfo(FLastObject)^.start+idx] do
      begin
        aid  :=id;
        aname:=name;
        exit(ptype);
      end;
    end;
  end;

  aid   :=dword(-1);
  aname :=nil;
  result:=rgUnknown;
end;

function TRGObject.GetPropInfoById(aid:dword; var aname:PWideChar):integer;
var
  lprop:PPropInfo;
//  ls:string;
begin
  lprop:=GetProperty(aid);
  if lprop<>nil then
  begin
    aname :=lprop^.name;
    result:=lprop^.ptype;
  end
  else
  begin
    aname :=nil;
    result:=rgUnknown;
  end;
{
  if result<=0 then
  begin
    Str(aid,ls);
    RGLog.Add('Unknown PROPERTY type '+HexStr(aid,8)+' '+ls);
  end;
}
end;

function TRGObject.GetPropInfoByName(aname:PWideChar; var aid:dword):integer;
var
  lprop:PPropInfo;
  i,l:integer;
begin
  if FLastObject<>nil then
  begin
    l:=Length(aname)-1;
    if l>=0 then
      for i:=0 to PObjInfo(FLastObject)^.count-1 do
      begin
        lprop:=@(PLayoutInfo(FDict)^.Props[PObjInfo(FLastObject)^.start+i]);

        if lprop^.ptype in [rgVector2, rgVector3, rgVector4] then
        begin
          if ((lprop^.ptype=rgVector2) and (aname[l] in ['X','x','Y','y'])) or
             ((lprop^.ptype=rgVector3) and (aname[l] in ['X','x','Y','y','Z','z'])) or
             ((lprop^.ptype=rgVector4) and (aname[l] in ['X','x','Y','y','Z','z','W','w'])) then
    
            if (CompareWide(aname,lprop^.name,l)=0) then
            begin
              aid:=lprop^.id;
              result:=lprop^.ptype;//rgFloat;
              exit;
            end;
        end
        else
        begin
          if CompareWide(aname,lprop^.name)=0 then
          begin
            aid:=lprop^.id;
            result:=lprop^.ptype;
            exit;
          end;
        end;

      end;
  end;

  result:=rgUnknown;
end;

function TRGObject.GetPropInfoByName(aname:PWideChar; atype:integer; var aid:dword):integer;
var
  lprop:PPropInfo;
  i,l:integer;
begin
  if FLastObject<>nil then
  begin
    l:=Length(aname)-1;
    if l>=0 then
      for i:=0 to PObjInfo(FLastObject)^.count-1 do
      begin
        lprop:=@(PLayoutInfo(FDict)^.Props[PObjInfo(FLastObject)^.start+i]);

        if (atype=rgFloat) and (lprop^.ptype in [rgVector2, rgVector3, rgVector4]) then
        begin
          if ((lprop^.ptype=rgVector2) and (aname[l] in ['X','x','Y','y'])) or
             ((lprop^.ptype=rgVector3) and (aname[l] in ['X','x','Y','y','Z','z'])) or
             ((lprop^.ptype=rgVector4) and (aname[l] in ['X','x','Y','y','Z','z','W','w'])) then
    
            if (CompareWide(aname,lprop^.name,l)=0) then
            begin
              aid:=lprop^.id;
              result:=lprop^.ptype;//atype;
              exit;
            end;
        end
        else
        begin
          if (lprop^.ptype=atype) and (CompareWide(aname,lprop^.name)=0) then
          begin
            aid:=lprop^.id;
            result:=lprop^.ptype;//atype;
            exit;
          end;
        end;

      end;
  end;

  result:=rgUnknown;
end;

//----- Processed -----
{$I-}
function LoadLayoutDict(abuf:PWideChar; aver:integer; aUseThis:boolean=false):boolean;
var
  ltype:array [0..31] of WideChar;
  pc,lname:PWideChar;
  layptr:PLayoutInfo;
  pscene:PSceneInfo;
  pobj  :PObjInfo;
  pprop :PPropInfo;
  lid:dword;
  lobj,lprop,lscene,i:integer;
begin
  result:=false;

  case ABS(aver) of
    verTL1: layptr:=@DictObjTL1;
    verTL2: layptr:=@DictObjTL2;
    verRG : layptr:=@DictObjRG;
    verRGO: layptr:=@DictObjRGO;
    verHob: layptr:=@DictObjHob;
  else
    RGLog.Add('Wrong layout dictionary version '+HexStr(aver,8));
    exit;
  end;

  if layptr^.buf<>nil then
  begin
    RGLog.Add('Trying to reload layout dictionary for v.'+HexStr(aver,8));
    exit;
  end;

  //-----------------------------

  result:=true;

  if aUseThis then
    layptr^.buf:=abuf
  else
    layptr^.buf:=CopyWide(abuf);

  //-----------------------------

  SetLength(layptr^.objects,1024);
  SetLength(layptr^.props  ,8192);

  lscene:=0;
  lobj  :=0;
  lprop :=0;

  pc:=layptr^.buf;
  if ORD(pc^)=SIGN_UNICODE then inc(pc);
  repeat
    while pc^ in [#9,' ',#13,#10] do inc(pc);

    case pc^ of
      // scene
      '>': begin
        inc(pc);

        lid:=0;
        // ID
        while pc^ in ['0'..'9'] do
        begin
          lid:=lid*10+ORD(pc^)-ORD('0');
          inc(pc);
        end;
        // separator
        inc(pc);
        // name
        lname:=pc;
        while not (pc^ in [#10,#13]) do inc(pc);
        pc^:=#0;
        inc(pc);

        pscene:=@(layptr^.scenes[lscene]);
        inc(lscene);
        pscene^.id     :=lid;
        pscene^.name   :=lname;
        pscene^.start  :=lobj;
        pscene^.count  :=0;
      end;

      // object
      '*': begin
        inc(pc);
        lid:=0;
        // ID
        while pc^ in ['0'..'9'] do
        begin
          lid:=lid*10+ORD(pc^)-ORD('0');
          inc(pc);
        end;
        // separator
        inc(pc);
        // name
        lname:=pc;
        while not (pc^ in [#10,#13,':']) do inc(pc);
        pc^:=#0;
        inc(pc);
        // skip the rest: original ID or property name if presents
        while not (pc^ in [#0,#10,#13]) do inc(pc);

        pobj:=@(layptr^.objects[lobj]);
        inc(pscene^.count);
        inc(lobj);
        pobj^.id     :=lid;
        pobj^.name   :=lname;
        pobj^.start  :=lprop;
        pobj^.count  :=0;
      end;

      // property
      '0'..'9': begin
        lid:=0;
        // ID
        while pc^ in ['0'..'9'] do
        begin
          lid:=lid*10+ORD(pc^)-ORD('0');
          inc(pc);
        end;
        // separator
        inc(pc);
        // type
        i:=0;
        while not (pc^ in [#10,#13,':']) do
        begin
          ltype[i]:=pc^;
          inc(i);
          inc(pc);
        end;
        ltype[i]:=#0;
        inc(pc);
        // name
        lname:=pc;
        while not (pc^ in [#10,#13,':']) do inc(pc);
        pc^:=#0;
        inc(pc);
        // skip the rest: original ID or property name if presents
        while not (pc^ in [#0,#10,#13]) do inc(pc);

        pprop:=@(layptr^.props[lprop]);
        inc(pobj^.count);
        inc(lprop);
        pprop^.id   :=lid;
        pprop^.name :=lname;
        pprop^.ptype:=TextToType(ltype);
      end;

      #0: break;
    else
      while not (pc^ in [#0,#10,#13]) do inc(pc);
    end;

  until false;

  if lscene<Length(layptr^.scenes) then layptr^.scenes[lscene].id:=dword(-1);
end;

function LoadLayoutDict(const resname:string; restype:PChar; aver:integer):boolean;
var
  res:TFPResourceHandle;
  Handle:THANDLE;
  buf:PWideChar;
  lptr:PByte;
  lsize:integer;
begin
  result:=false;

  res:=FindResource(hInstance, PChar(resname), restype);
  if res<>0 then
  begin
    Handle:=LoadResource(hInstance,Res);
    if Handle<>0 then
    begin
      lptr :=LockResource(Handle);
      lsize:=SizeOfResource(hInstance,res);

      GetMem(buf,lsize+SizeOf(WideChar));

      move(lptr^,buf^,lsize);

      UnlockResource(Handle);
      FreeResource(Handle);

      buf[lsize div SizeOf(WideChar)]:=#0;

      result:=LoadLayoutDict(buf,aver,true);

      if not result then FreeMem(buf);
    end;
  end;

end;

function LoadLayoutDict(const fname:AnsiString; aver:integer):boolean;
var
  f:file of byte;
  buf:PWideChar;
  i:integer;
begin
  result:=false;
  
  Assign(f,fname);
  Reset(f);
  if IOResult<>0 then exit;

  i:=FileSize(f);
  GetMem(buf,i+SizeOf(WideChar));
  BlockRead(f,buf^,i);
  Close(f);
  buf[i div SizeOf(WideChar)]:=#0;

  result:=LoadLayoutDict(buf,aver,true);

  if not result then FreeMem(buf);
end;

procedure InitLayoutDict(var alay:TLayoutInfo);
begin
  alay.scenes[0].id:=dword(-1);
  alay.objects:=nil;
  alay.props  :=nil;
  alay.buf    :=nil;
end;

procedure ClearLayoutDict(var alay:TLayoutInfo);
begin
  SetLength(alay.objects,0);
  SetLength(alay.props  ,0);
  FreeMem  (alay.buf);
end;


initialization

  RGTags.Init();

  InitLayoutDict(DictObjTL1);
  InitLayoutDict(DictObjTL2);
  InitLayoutDict(DictObjRG );
  InitLayoutDict(DictObjRGO);
  InitLayoutDict(DictObjHob);

finalization

  RGTags.Clear;

  ClearLayoutDict(DictObjTL1);
  ClearLayoutDict(DictObjTL2);
  ClearLayoutDict(DictObjRG );
  ClearLayoutDict(DictObjRGO);
  ClearLayoutDict(DictObjHob);

end.
