{NOTE: Hash calculates now JUST in Add for 'name'}
{TODO: autorecognize type (hash or text) by index automatically. for SortBy for example}
{TODO: separate cache setting for Mask and text/translation}
{TODO: if mask the same as value, keep just it and check on clear}
{TODO: add external FilterString function support}
{TODO: add similar (less than 100% the same) search}
{TODO: Use UTF8 conversion to save space}
unit Dict;

interface

uses
  TextCache;

{$IF NOT DEFINED(TIntegerDynArray)} type TIntegerDynArray = array of Integer; {$ENDIF}

type
  TElement = record
    hash:dword;
    case boolean of
      false: (name:PWideChar);
      true : (idx :cardinal);
  end;
  TElementArray = array of TElement;

  { TDictionary }
type
  THashDict = object
  public
    type
      THashFunc  = function (instr:PWideChar; alen:integer=0):dword;
      THDOptions = set of (check_hash, check_text);
  private
    const
      FHashIndex = 0;
      FTagIndex  = 1;
    type
      TSortType  = (byhash,bytext);
  private
    FCache   :TTextCache;
    FTags    :TElementArray;

    FIndexes :array of TIntegerDynArray;
    FIndex   :integer;

    FHashFunc  :THashFunc;
    FCapacity  :cardinal;
    FCount     :cardinal;
    FTextCount :integer;    // text field count as Cache capacity multiplier
    FChanged   :integer;
    FOptions   :THDOptions;
    FUseCache  :boolean;

    // in : aidx - Index type (Hash, Tag, Value, Mask)
    // out: natural array index
    function  GetHashIndex(adata:TElementArray; akey:dword    ; aidx:integer):integer;
    function  GetTextIndex(adata:TElementArray; akey:PWideChar; aidx:integer):integer;

    function  GetText(const aval:TElementArray; idx:integer):PWideChar;

    function  GetTextByHash(akey:dword    ):PWideChar;
    function  GetHashByText(akey:PWideChar):dword;
    function  GetTextByIdx (idx :cardinal ):PWideChar;
    function  GetHashByIdx (idx :cardinal ):dword;

    function  TextCompare(const aval:TElementArray; l,r:integer):integer;
    function  HashCompare(const aval:TElementArray; l,r:integer):integer;
    // aval  = tags, values, masks
    // aidx  = hash, tag, value, mask
    // asort = hash, text
    procedure _Sort(const aval:TElementArray; aidx:integer; asort:TSortType);
    procedure SetUnsorted(aidx:integer);
    function  GetUnsorted(aidx:integer):boolean;
    
    procedure SetCapacity(aval:cardinal);
  public
    procedure Init(ahfn:THashFunc=nil; usecache:boolean=true);
    procedure Clear;
    procedure Sort;
    procedure SortBy(idx:integer);

    function  Exists(ahash:dword):boolean;
    // calculates Hash for key = -1
    function  Add(      aval:PWideChar ; akey:dword=dword(-1)):dword;
    function  Add(const aval:AnsiString; akey:dword=dword(-1)):dword;

    property Tag   [akey:dword    ]:PWideChar read GetTextByHash;
    property Hash  [akey:PWideChar]:dword     read GetHashByText;
    property Hashes[idx :cardinal ]:dword     read GetHashByIdx;
    property Tags  [idx :cardinal ]:PWideChar read GetTextByIdx;

    property Capacity:cardinal   read FCapacity write SetCapacity;
    property Count   :cardinal   read FCount;
    property Options :THDOptions read FOptions  write FOptions;
  end;

  { Dictionary with translation }

type
  TTransDict = object(THashDict)
  private
    FValues:TElementArray;
    FValIdx:TIntegerDynArray;

    FValHashIndex:integer;
    FValTagIndex :integer;
  private
    function  GetValueByHash(akey:dword   ):PWideChar;
    function  GetValueByIdx (idx :cardinal):PWideChar;

  public
    procedure Init(ahfn:THashFunc=nil; usecache:boolean=true);
    procedure Clear;
    procedure SortBy(idx:integer);
    function  Add(atext, aval:PWideChar; akey:dword=dword(-1)):dword;

    //!!WARNING akey is base (not value) hash
    property Value [akey:dword   ]:PWideChar read GetValueByHash;
    property Values[idx :cardinal]:PWideChar read GetValueByIdx;
  end;

  { Dictionary with translation and mask }

type
  TMaskDict = object(TTransDict)
  public
    type
      TMaskFunc = function(astr:PWideChar):UnicodeString;
  private
    FMasks   :TElementArray;
    FMaskIdx :TIntegerDynArray;
    FMaskFunc:TMaskFunc;

    FMaskHashIndex:integer;
    FMaskTagIndex :integer;
  private
    function GetMaskByIdx(idx:cardinal):PWideChar;

  public
    procedure Init(ahfn:THashFunc=nil; usecache:boolean=true; amaskfn:TMaskFunc=nil);
    procedure Clear;
    procedure SortBy(idx:integer);
    function  Add(atext, aval       :PWideChar; akey:dword=dword(-1)):dword;
    function  Add(atext, aval, amask:PWideChar; akey:dword=dword(-1)):dword;

    property Masks[idx:cardinal]:PWideChar read GetMaskByIdx;
  end;

//===== Implementation =====

implementation

const
  FCapStep  = 256;
  SortLimit = 50;

{%REGION Support}

function CalcHash(instr:PWideChar; alen:integer=0):dword;
var
  i:integer;
begin
  if alen=0 then alen:=Length(instr);
  result:=alen;
  for i:=0 to alen-1 do
    result:=(result SHR 27) xor (result SHL 5) xor ORD(instr[i]);
end;

function CopyWide(asrc:PWideChar; alen:integer=0):PWideChar;
begin
  if (asrc=nil) or (asrc^=#0) then exit(nil);

  if alen=0 then
    alen:=Length(asrc);
  GetMem(    result ,(alen+1)*SizeOf(WideChar));
  move(asrc^,result^, alen   *SizeOf(WideChar));
  result[alen]:=#0;
end;

procedure CopyWide(var adst:PWideChar; asrc:PWideChar; alen:integer=0);
begin
  adst:=CopyWide(asrc,alen);
end;

function CompareWide(s1,s2:PWideChar; alen:integer=0):integer;
begin
  if s1=s2  then exit(0);
  if s1=nil then if s2^=#0 then exit(0) else exit(-1);
  if s2=nil then if s1^=#0 then exit(0) else exit( 1);

  repeat
    if s1^>s2^ then exit( 1);
    if s1^<s2^ then exit(-1);
    if s1^=#0  then exit( 0);
    dec(alen);
    if alen=0  then exit( 0);
    inc(s1);
    inc(s2);
  until false;
end;

{%ENDREGION Support}

{%REGION Dictionary}

procedure THashDict.Init(ahfn:THashFunc=nil; usecache:boolean=true);
begin
  FCapacity:=0;
  FCount   :=0;
  FOptions :=[];
  if ahfn=nil then FHashFunc:=@CalcHash else FHashFunc:=ahfn;
  FUseCache:=usecache;
  if FUseCache then FCache.Init(false);

  FTextCount:=1;

  FIndex:=-1;
  Initialize(FIndexes);
  SetLength (FIndexes,2);
end;

procedure THashDict.Clear;
var
  i:integer;
begin
  if FUseCache then FCache.Clear;

  if FCapacity>0 then
  begin
    if not FUseCache then
      for i:=0 to FCount-1 do
        FreeMem(FTags[i].name);
    FCount:=0;

    SetLength(FTags,0);
    FCapacity:=0;

    FIndex:=-1;
    Finalize(FIndexes);
  end;
end;

procedure THashDict.SetCapacity(aval:cardinal);
begin
  if aval<=FCapacity then exit;

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

  SetLength(FTags,FCapacity);

  if FUseCache then
  begin
    FCache.Count   :=FCapacity*FTextCount;
    FCache.Capacity:=FCapacity*FTextCount*16;
  end;
end;

//----- Sort (Shell method) -----

type TCompareFunc = function (const aval:TElementArray; l,r:integer):integer of object;

function THashDict.TextCompare(const aval:TElementArray; l,r:integer):integer;
begin
  if FUseCache then
    result:=CompareWide(FCache[aval[l].idx],FCache[aval[r].idx])
  else
    result:=CompareWide(aval[l].name,aval[r].name);
end;

function THashDict.HashCompare(const aval:TElementArray; l,r:integer):integer;
begin
  if      aval[l].hash>aval[r].hash then result:=1
  else if aval[l].hash<aval[r].hash then result:=-1
  else result:=0;
//  result:=aval[l].hash-aval[r].hash;
end;

procedure THashDict._Sort(const aval:TElementArray; aidx:integer; asort:TSortType);
var
  fn:TCompareFunc;
  ltmp:integer;
  i,j,gap:longint;
begin
  if FCount=0 then exit;
 
  if asort=bytext then fn:=@TextCompare
                  else fn:=@HashCompare;
  
  if FCapacity>Length(FIndexes[aidx]) then
    SetLength(FIndexes[aidx],FCapacity);

  for i:=0 to FCount-1 do
    FIndexes[aidx][i]:=i;

  gap:=FCount shr 1;
  while gap>0 do
  begin
    for i:=gap to FCount-1 do
    begin
      j:=i-gap;
      while (j>=0) and (fn(aval, FIndexes[aidx][j], FIndexes[aidx][j+gap])>0) do
      begin
        ltmp                 :=FIndexes[aidx][j+gap];
        FIndexes[aidx][j+gap]:=FIndexes[aidx][j];
        FIndexes[aidx][j]    :=ltmp;
        dec(j,gap);
      end;
    end;
    gap:=gap shr 1;
  end;
end;

procedure THashDict.Sort;
begin
  if GetUnsorted(FTagIndex) then
    _Sort(FTags,FTagIndex,bytext);
end;

procedure THashDict.SortBy(idx:integer);
begin
  if (idx<0) or (idx>=Length(FIndexes)) then
    FIndex:=-1
  //!!!!
  else if idx=FHashIndex then
  begin
    FIndex:=idx;
    if GetUnsorted(FHashIndex) then
      _Sort(FTags,FHashIndex,byhash);
  end
  else if idx=FTagIndex then
  begin
    FIndex:=idx;
    if GetUnsorted(FTagIndex) then
      _Sort(FTags,FTagIndex,bytext);
  end;
end;

function THashDict.GetUnsorted(aidx:integer):boolean;
begin
  if (aidx>=0) and (aidx<Length(FIndexes)) then
    result:=(Length(FIndexes[aidx])=0) or (FIndexes[aidx][0]<0)
  else
    result:=true;
end;

procedure THashDict.SetUnsorted(aidx:integer);
begin
  if (aidx>=0) and (aidx<Length(FIndexes)) then
    if Length(FIndexes[aidx])>0 then FIndexes[aidx][0]:=-1;
end;

//--- Search ---

function THashDict.GetHashIndex(adata:TElementArray; akey:dword; aidx:integer):integer;
var
  L,R,i:integer;
begin
  result:=-1;

  if (FChanged>=0) and GetUnsorted(aidx) and (FCount>SortLimit) then
  begin
    _Sort(adata,aidx,byhash);
  end;

  if not GetUnsorted(aidx) then
  begin
    L:=0;
    R:=FCount-1;
    while (L<=R) do
    begin
      i:=L+(R-L) div 2;
      if akey>adata[FIndexes[aidx][i]].hash then
        L:=i+1
      else
      begin
        if akey=adata[FIndexes[aidx][i]].hash then
        begin
          result:=FIndexes[aidx][i];
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
      if adata[i].hash=akey then
      begin
        result:=i;
        break;
      end;
    end;
  end;
end;

function THashDict.GetText(const aval:TElementArray; idx:integer):PWideChar; inline;
begin
  if FUseCache then
    result:=FCache[aval[idx].idx]
  else
    result:=aval[idx].name;
end;

function THashDict.GetTextIndex(adata:TElementArray; akey:PWideChar; aidx:integer):integer;
var
  L,R,i,ltmp:integer;
begin
  result:=-1;

  if (FChanged>=0) and GetUnsorted(aidx) and (FCount>SortLimit) then
  begin
    _Sort(adata,aidx,bytext);
  end;

  if not GetUnsorted(aidx) then
  begin
    L:=0;
    R:=FCount-1;
    while (L<=R) do
    begin
      i:=L+(R-L) div 2;
      ltmp:=CompareWide(akey,GetText(adata,FIndexes[aidx][i]));
      if ltmp>0 then
        L:=i+1
      else
      begin
        if ltmp=0 then
        begin
          result:=FIndexes[aidx][i];
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
      if CompareWide(GetText(adata,i),akey)=0 then
      begin
        result:=i;
        break;
      end;
    end;
  end;
end;

//--- Getters ---

function THashDict.GetTextByHash(akey:dword):PWideChar;
var
  i:integer;
begin
  i:=GetHashIndex(FTags,akey,FHashIndex);
  if i<0 then
    result:=nil
  else
    result:=GetText(FTags,i);
end;

function THashDict.GetHashByText(akey:PWideChar):dword;
var
  i:integer;
begin
  i:=GetTextIndex(FTags,akey,FTagIndex);
  if i>=0 then
    result:=FTags[i].hash
  else
  begin
    Val(akey,result,i);
    if i>0 then
      result:=dword(-1);
  end;
end;

function THashDict.GetTextByIdx(idx:cardinal):PWideChar;
begin
  if idx>=FCount then result:=nil
  else
  begin
    if FIndex>=0 then idx:=FIndexes[FIndex][idx];

    result:=GetText(FTags,idx);
  end;
end;

function THashDict.GetHashByIdx(idx:cardinal):dword;
begin
  if idx>=FCount then result:=dword(-1)
  else
  begin
    if FIndex>=0 then idx:=FIndexes[FIndex][idx];
    result:=FTags[idx].hash;
  end;
end;


function THashDict.Exists(ahash:dword):boolean; inline;
begin
  result:=GetHashIndex(FTags,ahash,FHashIndex)>=0;
end;

function THashDict.Add(aval:PWideChar; akey:dword=dword(-1)):dword;
var
  i:integer;
begin
  FChanged:=-1;

  if (akey=dword(-1)) then akey:=FHashFunc(aval);// TTextCache.Hash[aval];

  if (check_hash in FOptions) then
  begin
    if GetHashIndex(FTags,akey,FHashIndex)>=0 then Exit(akey);
  end;

  if (check_text in FOptions) then
  begin
    i:=GetTextIndex(FTags,aval,FTagIndex);
    if i>=0 then Exit(FTags[i].hash);
  end;

  // Add new element
  SetUnsorted(FHashIndex);
  SetUnsorted(FTagIndex);

  if FCount=FCapacity then
  begin
    FCapacity:=Align(FCapacity+FCapStep,FCapStep);
    SetLength(FTags,FCapacity);
  end;

  FTags[FCount].hash :=akey;

  if FUseCache then
    FTags[FCount].idx:=FCache.Append(aval)
  else
    CopyWide(FTags[FCount].name,aval);

  FChanged:=FCount;

  inc(FCount);
  result:=akey;
end;

function THashDict.Add(const aval:AnsiString; akey:dword=dword(-1)):dword;
begin
  result:=Add(pointer(UTF8Decode(aval)), akey);
end;

{%ENDREGION Dictionary}

{%REGION Dictionary with translation}

procedure TTransDict.Init(ahfn:THashFunc=nil; usecache:boolean=true);
begin
  inherited Init(ahfn, usecache);

  inc(FTextCount);
  
  SetLength(FIndexes,Length(FIndexes)+2);
  FValHashIndex:=Length(FIndexes)-2;
  FValTagIndex :=Length(FIndexes)-1;
end;

procedure TTransDict.Clear;
var
  i:integer;
begin
  if FCapacity>0 then
  begin
    if not FUseCache then
      for i:=0 to FCount-1 do
        FreeMem(FValues[i].name);

    FCount:=0;
    SetLength(FValues,0);
    SetLength(FValIdx,0);
  end;

  inherited Clear;
end;

procedure TTransDict.SortBy(idx:integer);
begin
  if idx=FValHashIndex then
  begin
    FIndex:=idx;
    if GetUnsorted(FValHashIndex) then
      _Sort(FValues,FValHashIndex,byhash);
  end
  else if idx=FValTagIndex then
  begin
    FIndex:=idx;
    if GetUnsorted(FValTagIndex) then
      _Sort(FValues,FValTagIndex,bytext);
  end
  else
    inherited SortBy(idx);
end;

function TTransDict.GetValueByHash(akey:dword):PWideChar;
var
  i:integer;
begin
  i:=GetHashIndex(FTags,akey,FHashIndex);
  if i<0 then
    result:=nil
  else
    result:=Values[i];
end;

function TTransDict.GetValueByIdx(idx:cardinal):PWideChar;
begin
  if idx>=FCount then result:=nil
  else
  begin
    if FIndex>=0 then idx:=FIndexes[FIndex][idx];

    result:=GetText(FValues,idx);
  end;
end;

function TTransDict.Add(atext, aval:PWideChar; akey:dword=dword(-1)):dword;
begin
  result:=inherited Add(atext, akey);

  if FChanged>=0 then
  begin
    if Length(FValues)<FCapacity then
      SetLength(FValues,FCapacity);

    if FUseCache then
      FValues[FChanged].idx:=FCache.Append(aval)
    else
      CopyWide(FValues[FChanged].name,aval);

    SetUnsorted(FValHashIndex);
    SetUnsorted(FValTagIndex);
  end;
end;

{%ENDREGION Dictionary with translation}

{%REGION Dictionary with translation and mask}

procedure TMaskDict.Init(ahfn:THashFunc=nil; usecache:boolean=true; amaskfn:TMaskFunc=nil);
begin
  inherited Init(ahfn, usecache);

//  if amaskfn=nil then FMaskFunc:=@CalcMask else FMaskFunc:=amaskfn;
  FMaskFunc:=amaskfn;

  SetLength(FIndexes,Length(FIndexes)+2);
  FMaskHashIndex:=Length(FIndexes)-2;
  FMaskTagIndex :=Length(FIndexes)-1;
end;

procedure TMaskDict.Clear;
var
  i:integer;
begin
  if FCapacity>0 then
  begin
    if not FUseCache then
      for i:=0 to FCount-1 do
        FreeMem(FMasks[i].name);

    FCount:=0;
    SetLength(FMasks  ,0);
    SetLength(FMaskIdx,0);
  end;

  inherited Clear;
end;

procedure TMaskDict.SortBy(idx:integer);
begin
  if idx=FMaskHashIndex then
  begin
    FIndex:=idx;
    if GetUnsorted(FMaskHashIndex) then
      _Sort(FMasks,FMaskHashIndex,byhash);
  end
  else if idx=FMaskTagIndex then
  begin
    FIndex:=idx;
    if GetUnsorted(FMaskTagIndex) then
      _Sort(FMasks,FMaskTagIndex,bytext);
  end
  else
    inherited SortBy(idx);
end;

function TMaskDict.GetMaskByIdx(idx:cardinal):PWideChar;
begin
  if idx>=FCount then result:=nil
  else
  begin
    if FIndex>=0 then idx:=FIndexes[FIndex][idx];

    result:=GetText(FMasks,idx);
  end;
end;

function TMaskDict.Add(atext, aval, amask:PWideChar; akey:dword=dword(-1)):dword;
begin
  result:=inherited Add(atext, aval, akey);

  if FChanged>=0 then
  begin
    if Length(FMasks)<FCapacity then
      SetLength(FMasks,FCapacity);

    if FUseCache then
      FMasks[FChanged].idx:=FCache.Append(amask)
    else
      CopyWide(FMasks[FChanged].name,amask);

    SetUnsorted(FMaskHashIndex);
    SetUnsorted(FMaskTagIndex);
  end;
end;

function TMaskDict.Add(atext, aval:PWideChar; akey:dword=dword(-1)):dword;
begin
  if FMaskFunc=nil then
    result:=Add(atext, aval, atext, akey)
  else
    result:=Add(atext, aval, pointer(FMaskFunc(atext)), akey);
end;

{%ENDREGION Dictionary with translation and mask}

end.
