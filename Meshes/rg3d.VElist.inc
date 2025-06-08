{}
{TODO: Write Elements: keep 0 for separate buffers, summarize in RGType1}
{$DEFINE KeepAllBlocks} // Keep Binormal, Tangent and color blocks or skip them

{$IFDEF Interface}
type
  PVertexElement = ^TVertexElement;
  TVertexElement = packed record
    source  :Word; // "source" 0 - shared buffer
    _type   :Word; // VET_* const: Vertex Element Type
    semantic:Word; // VES_* const: Vertex Element Semantic
    offset  :Word; // buffer offset
    index   :Word; // block number (for colours and texture coords)
  end;

type
  TVertexElementList = object
  private
    const MaxBlockCount = 16;
  private
    FCount  :integer;
    FVEList :array [0..MaxBlockCount-1] of TVertexElement;
    FBuffers:array [0..MaxBlockCount-1] of PByte;

    function  GetCount:integer;
    function  GetItemSize(idx:integer):integer;                // size of element/block in bytes
    function  GetSemantic(idx:integer):integer;
    function  GetOffset  (idx:integer):integer;
    function  GetType    (idx:integer):integer;
    procedure SetType    (idx:integer; atype:integer);

    function  GetBuffer  (idx:integer):PByte;
    procedure SetBuffer  (idx:integer; abuf:PByte);

    function  GetVEList  (idx:integer):PVertexElement;

  public
    function  FindType(atype:integer; aidx:integer=0):integer; // index of element by type (aidx for multi)
    function  GetSize(idx:integer):integer;                    // get blocks size with source like in this

    procedure Write(astream:TStream);
    procedure Write(astream:TStream; idx:integer);
    
    procedure Delete(idx:integer);
    function  Read(var aptr:PByte):integer;                    // read count + block of descriptions
    // used by Read
    function  Add (var aptr:PByte):integer;                    // read single description
    // used by MESH reading
    function  Add (asource,atype,asemantic,aoffset,aindex:Word):integer;
    // index = source; asize - size of buffer block=GetSize(0); acount - VertexCount
    procedure BindBuffer(var aptr:PByte; aindex,asize,acount:integer);

    property Count: integer read GetCount;
    property VEList  [idx:integer]:PVertexElement read GetVEList; default;
    property Semantic[idx:integer]:integer read GetSemantic;
    property Format  [idx:integer]:integer read GetType   write SetType;
    property Offset  [idx:integer]:integer read GetOffset;
    property Size    [idx:integer]:integer read GetItemSize;
    property Buffer  [idx:integer]:PByte   read GetBuffer write SetBuffer;
  end;

{$ELSE}

procedure LogVE(num:integer; const VE:TVertexElement);
begin
  Log('Vertex Element',num);
  Log('  source  ',VE.source);
  Log('  type    ',GetVETName(VE._type));
  Log('  semantic',GetVESName(VE.semantic));
  Log('  offset  ',VE.offset);
  Log('  index   ',VE.index);
end;

procedure TVertexElementList.Delete(idx:integer);
var
  i:integer;
begin
  if idx=(FCount-1) then
    dec(FCount)
  else if idx<FCount then
  begin
    FreeMem(FBuffers[idx]);
    move(FBuffers[idx+1],FBuffers[idx],(FCount-idx-1)*SizeOf(PByte));
    move(FVEList [idx+1],FVEList [idx],(FCount-idx-1)*SizeOf(TVertexElement));
    dec(FCount);

    for i:=0 to FCount-1 do
      FVEList[i].source:=i;
  end;
end;

function TVertexElementList.Add(asource,atype,asemantic,aoffset,aindex:Word):integer;
begin
  if FCount<MaxBlockCount then
  begin
    {$IFNDEF KeepAllBlocks}
    if not (asemantic in [VES_POSITION, VES_NORMAL, VES_TEXTURE_COORDINATES]) then exit(-1);
    {$ENDIF}
    with FVEList[FCount] do
    begin
      source  :=asource;
      _type   :=atype;
      semantic:=asemantic;
      offset  :=aoffset;
      index   :=aindex;
    end;
    result:=FCount;
    inc(FCount);
  end
  else
    result:=-1;
end;

function TVertexElementList.Add(var aptr:PByte):integer;
begin
  if FCount<MaxBlockCount then
  begin
    memRead(aptr,FVEList[FCount],SizeOf(TVertexElement));
    {$IFNDEF KeepAllBlocks}
    if not (FVEList[FCount].semantic in [VES_POSITION, VES_NORMAL, VES_TEXTURE_COORDINATES]) then exit(-1);
    {$ENDIF}
    FBuffers[FCount]:=nil;
    result:=FCount;
    if rgDebugLevel=dlDetailed then LogVE(FCount,FVEList[FCount]);
    inc(FCount);
  end
  else
  begin
    inc(aptr,SizeOf(TVertexElement));
    result:=-1;
  end;
end;

function TVertexElementList.Read(var aptr:PByte):integer;
var
  i:integer;
begin
  FillChar(self,SizeOf(TVertexElementList),0);

  result:=memReadWord(aptr);

  LogLn();
  Log('>VertexElementList',result);

  for i:=0 to result-1 do Add(aptr);
{
  if result>MaxBlockCount then // low change but
    FCount:=MaxBlockCount
  else
    FCount:=result;

  // read all 
  memRead(aptr,FVEList[0],FCount*SizeOf(TVertexElement));
  if result<>FCount then
    inc(aptr,(result-FCount)*(SizeOf(TVertexElement)));

  if rgDebugLevel=dlDetailed then
    for i:=0 to FCount-1 do
      LogVE(i,FVEList[i]);
}
end;

function TVertexElementList.GetCount:integer;
begin
  result:=FCount;
end;

function TVertexElementList.GetSize(idx:integer):integer;
var
  i:integer;
begin
  result:=0;
  if idx in [0..FCount-1] then
  begin
    idx:=FVEList[idx].source;
    for i:=0 to FCount-1 do
      if FVEList[i].source=idx then
        inc(result,VETData[FVEList[i]._type].size);
  end;
end;

function TVertexElementList.GetItemSize(idx:integer):integer;
begin
  if (idx>=0) and (idx<FCount) then
  begin
    result:=VETData[FVEList[idx]._type].size
  end
  else
    result:=0;
end;

function TVertexElementList.FindType(atype:integer; aidx:integer=0):integer;
var
  i:integer;
begin
  {$IFNDEF KeepAllBlocks}
  if (aidx>0) and not
     (atype in [VES_POSITION, VES_NORMAL, VES_TEXTURE_COORDINATES]) then
    exit(-1);
  {$ENDIF}
  for i:=0 to FCount-1 do
  begin
    if FVEList[i].semantic=atype then
    begin
      if aidx=0 then exit(i);
      dec(aidx);
    end;
  end;
  result:=-1;
end;

function TVertexElementList.GetVEList(idx:integer):PVertexElement;
begin
  if (idx>=0) and (idx<FCount) then
    result:=@FVEList[idx]
  else
    result:=nil;
end;

function TVertexElementList.GetSemantic(idx:integer):integer;
begin
  if (idx>=0) and (idx<FCount) then
    exit(FVEList[idx].semantic);
  result:=0;
end;

function TVertexElementList.GetOffset(idx:integer):integer;
begin
  if (idx>=0) and (idx<FCount) then
    exit(FVEList[idx].offset);
  result:=0;
end;

function TVertexElementList.GetType(idx:integer):integer;
begin
  if (idx>=0) and (idx<FCount) then
    exit(FVEList[idx]._type);
  result:=0;
end;

procedure TVertexElementList.SetType(idx:integer; atype:integer);
begin
  if (idx>=0) and (idx<FCount) then
    FVEList[idx]._type:=atype;
end;

function TVertexElementList.GetBuffer(idx:integer):PByte;
begin
  if (idx>=0) and (idx<FCount) then
    result:=FBuffers[idx]
  else
    result:=nil;
end;

procedure TVertexElementList.SetBuffer(idx:integer; abuf:PByte);
begin
  if (idx>=0) and (idx<FCount) then
  begin
//    FVEList [idx].source:=idx;
//    FVEList [idx].offset:=0;
//    FVEList [idx].index :=0;
    FBuffers[idx]:=abuf;
  end;
end;

procedure TVertexElementList.BindBuffer(var aptr:PByte; aindex,asize,acount:integer);
var
  lptr,lptr1:PByte;
  i,j,llsize:integer;
begin
  for i:=0 to FCount-1 do
  begin
    {$IFNDEF KeepAllBlocks}
    if not (FVEList[i].semantic in [VES_POSITION, VES_NORMAL, VES_TEXTURE_COORDINATES]) then continue;
    {$ENDIF}

    if FVEList[i].source=aindex then
    begin
      llsize:=Size[i];
      GetMem(lptr,acount*llsize);

      lptr1:=aptr;
      for j:=0 to acount-1 do
      begin
        move((lptr1+FVEList [i].offset)^,
             PByte(lptr+j*llsize)^,
             llsize);
        inc(lptr1,asize);
      end;
      Buffer[i]:=lptr;
    end;
  end;
  inc(aptr,acount*asize); // if one texture block only
end;

procedure TVertexElementList.Write(astream:TStream);
var
  i,lcnt,loffset,lsrc:integer;
begin
  lcnt   :=0;
  loffset:=0;
  lsrc   :=0;
  for i:=0 to FCount-1 do
  begin
    if Buffer[i]<>nil then
    begin
      inc(lcnt);
      with FVEList[i] do
      begin
        //!!!!
        offset:=loffset;
        source:=lsrc;
      end;
      inc(loffset,VETData[FVEList[i]._type].size);
      inc(lsrc);
    end;
  end;

  astream.WriteWord(lcnt);

  for i:=0 to FCount-1 do
  begin
    if Buffer[i]<>nil then Write(astream,i);
  end;
end;

procedure TVertexElementList.Write(astream:TStream; idx:integer);
begin
  astream.Write(FVEList[idx],SizeOf(TVertexElement));
end;

{$ENDIF}
