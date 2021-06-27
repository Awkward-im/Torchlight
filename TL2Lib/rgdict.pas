{%TODO remove Classes (TStringList) dependences}
{%TODO remove RGNode dependences}
{%TODO keep text in TextCache object (but local can have long lines)}
{%TODO RG/Hob: no scene, no object, just params atm}
{%TODO Process short and full version of objects.dat}
{
  Layout Objects:
    1 - version
    2 - layout type (UI, Layout, Particle Creator
    3 - Object: search by name, by ID
    4 - Property: search by name, by ID (with Object reference)
    5 - Data: Name, ID, type (size)
}
unit RGDict;

interface

//--- Tags

type
  TRGDict = object
  private
    type
      TDict = record
        name:PWideChar;
        hash:dword;
      end;
  public
    type
      TRGOptions = set of (check_hash, check_text, update_text);
  private
    FDict    :array of TDict;
    NameIdxs :array of integer;
    FCapacity:cardinal;
    FCount   :cardinal;
    FOptions :TRGOptions;
    FSorted  :boolean;
    FTextSorted:boolean;

    function  GetHashIndex(akey:dword):integer;
    function  GetTextIndex(akey:PWideChar):integer;

    function  GetTextByHash(akey:dword    ):PWideChar;
    function  GetHashByText(akey:PWideChar):dword;
    function  GetTextByIdx (idx :cardinal ):PWideChar;
    function  GetHashByIdx (idx :cardinal ):dword;
    procedure LoadTagsFile  (const fname:AnsiString);
    procedure LoadDictionary(const fname:AnsiString);
    procedure LoadList      (const fname:AnsiString);
    procedure InitCapacity(aval:cardinal);
  public
    procedure Init;
    procedure Clear;
    procedure SortText;
    procedure Sort;
    function  Add(akey:dword; aval:PWideChar):dword;
    function  Add(akey:dword; const aval:AnsiString):dword;
    function  Import(const fname:AnsiString=''):integer;
    procedure Export(const fname:AnsiString; asdat:boolean=true; sortbyhash:boolean=true);

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
    function GetPropInfoById  (aid:dword; var aname:PWideChar):integer;
    function GetPropInfoByName(aname:PWideChar; atype:integer; var aid:dword):integer;

    property Version:integer read FVersion write SetVersion;
  end;

function LoadLayoutDict(const fname:AnsiString; aver:integer):boolean;


//===== Implementation =====

implementation

uses
  Classes,
  rgglobal,
  rglog,
  rgnode;

const
  FCapStep = 256;
const
  defdictname = 'dictionary.txt';
  deftagsname = 'tags.dat';
  defobjname  = 'objects.dat';

const
  SIGN_UNICODE = $FEFF;
  SIGN_UTF8    = $BFBBEF;

//===== DAT tags =====

procedure TRGDict.Init;
begin
  FCapacity:=0;
  FCount   :=0;
  FOptions :=[];
end;

procedure TRGDict.Clear;
var
  i:integer;
begin
  if FCapacity>0 then
  begin
    //!!
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
    FOptions:=[check_hash, update_text];
    if aval>FCapacity then
      aval:=aval div 2;
    FCapacity:=FCount+aval;
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
      while (j>=0) and (CompareWide(FDict[NameIdxs[j]].name,FDict[NameIdxs[j+gap]].name)>0) do
      begin
        ltmp:=NameIdxs[j+gap];
        NameIdxs[j+gap]:=NameIdxs[j];
        NameIdxs[j]:=ltmp;
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
        ltmp:=FDict[j+gap];
        FDict[j+gap]:=FDict[j];
        FDict[j]:=ltmp;
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

function TRGDict.GetTextByHash(akey:dword):PWideChar;
var
  i:integer;
begin
  i:=GetHashIndex(akey);
  if i<0 then
    result:=nil
  else
    result:=FDict[i].name;
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
      ltmp:=CompareWide(akey,FDict[NameIdxs[i]].name);
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
      if CompareWide(FDict[i].name,akey)=0 then
      begin
        result:=i;
        break;
      end;
    end;
  end;
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
  else result:=FDict[idx].name;
end;

function TRGDict.GetHashByIdx(idx:cardinal):dword;
begin
  if idx>=FCount then result:=dword(-1)
  else result:=FDict[idx].hash;
end;


function TRGDict.Add(akey:dword; aval:PWideChar):dword;
var
  i:integer;
begin
  if (akey=0) or (akey=dword(-1)) then akey:=RGHash(aval,Length(aval));

  if (check_hash in FOptions) then
  begin
    i:=GetHashIndex(akey);
    if i>=0 then
    begin
      if (update_text in FOptions) then
      begin
        if CompareWide(FDict[i].name,aval)<>0 then
        begin
          FreeMem (FDict[i].name);      //!!
          CopyWide(FDict[i].name,aval); //!!
        end;
      end;

      result:=akey;
      exit;
    end;
  end;

  if (check_text in FOptions) then
  begin
    for i:=0 to FCount-1 do
    begin
      if CompareWide(FDict[i].name,aval)=0 then
      begin
        result:=FDict[i].hash;
        exit;
      end;
    end;
  end;

  // Add new element
  //!!
  FSorted:=false;
  FTextSorted:=false;
  if FCount=FCapacity then
  begin
    FCapacity:=Align(FCapacity+FCapStep,FCapStep);
    SetLength(FDict,FCapacity);
  end;
  FDict[FCount].hash:=akey;
  CopyWide(FDict[FCount].name,aval); //!!
  inc(FCount);
  result:=akey;
end;

function TRGDict.Add(akey:dword; const aval:AnsiString):dword;
begin
  result:=Add(akey,pointer(UTF8Decode(aval)));
end;

//----- Load -----

//--- Tags.dat

procedure TRGDict.LoadTagsFile(const fname:AnsiString);
var
  lnode:pointer;
  pcw:PWideChar;
  lc,i:integer;
begin
  lnode:=ParseDatFile(pointer(fname));
  if lnode<>nil then
  begin
    i:=0;
    lc:=GetChildCount(lnode);
    InitCapacity(lc div 2);
    while i<lc do
    begin
      pcw:=asString(GetChild(lnode,i));
      if pcw<>nil then
        Add(AsUnsigned(GetChild(lnode,i+1)),pcw);
      inc(i,2);
    end;
    DeleteNode(lnode);
  end;
end;

//--- dictionary.txt

procedure TRGDict.LoadDictionary(const fname:AnsiString);
var
  sl:TStringList;
//  ls:UTF8String;
  ls:AnsiString;
  lns:String[31];
  lstart,tmpi,i,p:integer;
  lhash:dword;
begin
  sl:=TStringList.Create;

  try
    try
      sl.LoadFromFile(fname);
      InitCapacity(sl.Count);
      for i:=0 to sl.Count-1 do
      begin
        ls:=sl[i];
        if ls<>'' then
        begin
          if ls[1]='-' then
            lstart:=2
          else
            lstart:=1;

          for p:=lstart to Length(ls) do
          begin
            if (ls[p] in ['0'..'9']) then
              lns[p]:=ls[p]
            else
            begin
              SetLength(lns,p-1);
              if lstart=2 then
              begin
                val(lns,tmpi);
                lhash:=dword(-tmpi);
              end
              else
                val(lns,lhash);
              Add(lhash,Copy(ls,p+1)); //!!
              break;
            end;
          end;
        end;
      end;

    except
      RGLog.Add('Can''t load '+fname);
      if ls<>'' then RGLog.Add('Possible problem with '+ls);
      Clear;
    end;
  finally
    sl.Free;
  end;
end;

//--- raw text

procedure TRGDict.LoadList(const fname:AnsiString);
var
  sl:TStringList;
  ls:AnsiString;
  i:integer;
begin
  sl:=TStringList.Create;
  sl.LoadFromFile(fname{,TEncoding.UTF8});
  InitCapacity(sl.Count);
  for i:=0 to sl.Count-1 do
  begin
    ls:=sl[i];
    if ls<>'' then
      Add(RGHash(pointer(ls),Length(ls)),ls);
  end;
  sl.Free;
end;

function TRGDict.Import(const fname:AnsiString=''):integer;
var
  f:file of byte;
  buf:array [0..7] of byte;
  ls:AnsiString;
  loldcount:integer;
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
  BlockRead(f,buf,7);
  Close(f);
{$POP}

  // 2 - trying to recognize dic format: like "TAGS.DAT" or "dictionary.txt"
  if (pword(@buf)^=SIGN_UNICODE) and (buf[3]=ORD('[')) then
  begin
    LoadTagsFile(ls)
  end
  else if (CHAR(buf[0]) in ['-','0'..'9']) or
      (((pdword(@buf)^ and $FFFFFF)=SIGN_UTF8) and
       ((CHAR(buf[3]) in ['-','0'..'9']))) then
  begin
    LoadDictionary(ls);
  end
  else
    LoadList(ls);

  Sort;

  result:=FCount-loldcount;
end;

procedure TRGDict.Export(const fname:AnsiString; asdat:boolean=true; sortbyhash:boolean=true);
var
  sl:TStringList;
  lnode:pointer;
  lstr:UnicodeString;
  i:integer;
begin
  if asdat then
  begin
    lnode:=AddGroup(nil,'TAGS');

    if sortbyhash then
    begin
      for i:=0 to FCount-1 do
      begin
        AddString (lnode,nil,        FDict[i].name ); //!!
        AddInteger(lnode,nil,Integer(FDict[i].hash)); //!!
      end
    end
    else
    begin
      if not FTextSorted then SortText;
      for i:=0 to FCount-1 do
      begin
        AddString (lnode,nil,        FDict[NameIdxs[i]].name ); //!!
        AddInteger(lnode,nil,Integer(FDict[NameIdxs[i]].hash)); //!!
      end;
    end;
    
    WriteDatTree(lnode,PChar(fname));
    DeleteNode(lnode);
  end
  else
  begin
    sl:=TStringList.Create;

    if sortbyhash then
    begin
      for i:=0 to FCount-1 do
      begin
        Str(FDict[i].hash,lstr);                      //!!
        sl.Add(UTF8Encode(lstr+':'+(FDict[i].name))); //!!
      end;
    end
    else
    begin
      if not FTextSorted then SortText;
      for i:=0 to FCount-1 do
      begin
        Str(FDict[NameIdxs[i]].hash,lstr);                      //!!
        sl.Add(UTF8Encode(lstr+':'+(FDict[NameIdxs[i]].name))); //!!
      end;
    end;

    sl.SaveToFile(fname);
    sl.Free;
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

//----- Objects -----

procedure TRGObject.Init;
begin
  FVersion   :=verUnk;
  FDict      :=nil;
  FLastScene :=nil;
  FLastObject:=nil;
  FLastObjId :=dword(-1);
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
    verRGO: FDict:=@DictObjRG ;
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

function TRGObject.GetPropInfoById(aid:dword; var aname:PWideChar):integer;
var
  lprop:PPropInfo;
  ls:string;
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
              result:=atype;
              exit;
            end;
        end
        else
        begin
          if (lprop^.ptype=atype) and (CompareWide(aname,lprop^.name)=0) then
          begin
            aid:=lprop^.id;
            result:=atype;
            exit;
          end;
        end;

      end;
  end;

  result:=rgUnknown;
end;

//----- Processed -----
{$I-}
function LoadLayoutDict(const fname:AnsiString; aver:integer):boolean;
var
  f:file of byte;
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
    verRGO: layptr:=@DictObjRG;
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

  Assign(f,fname);
  Reset(f);
  if IOResult<>0 then exit;

  result:=true;
  
  i:=FileSize(f);
  GetMem(layptr^.buf,i+SizeOf(WideChar));
  BlockRead(f,layptr^.buf^,i);
  Close(f);
  layptr^.buf[i div SizeOf(WideChar)]:=#0;

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

  if lscene<=Length(layptr^.scenes) then layptr^.scenes[lscene].id:=dword(-1);
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

  RGTags.Init;

  InitLayoutDict(DictObjTL1);
  InitLayoutDict(DictObjTL2);
  InitLayoutDict(DictObjRG );
  InitLayoutDict(DictObjHob);

finalization

  RGTags.Clear;

  ClearLayoutDict(DictObjTL1);
  ClearLayoutDict(DictObjTL2);
  ClearLayoutDict(DictObjRG );
  ClearLayoutDict(DictObjHob);

end.
