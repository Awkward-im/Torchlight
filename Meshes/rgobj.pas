unit RGObj;

interface

uses
  classes,
  rgglobal;

{$DEFINE Interface}

{$I rg3d.ogre.inc}
{$I rg3d.material.inc}
type
  PIntVector3 = ^TIntVector3;
  TIntVector3 = packed record
    X: Int32;
    Y: Int32;
    Z: Int32;
  end;

type
  PVertexBoneAssignment = ^TVertexBoneAssignment;
  TVertexBoneAssignment = packed record
    vertexIndex:DWord;
    boneIndex  :Word;  // Ogre
    weight     :single;
  end;

  PBoneVertex = ^TBoneVertex;
  TBoneVertex = packed record
    vertexIndex:DWord;
    boneIndex  :DWord; // Runic
    weight     :single;
  end;

{$I rg3d.VElist.inc}

type
  PRGMesh = ^TRGMesh;

  PRGSubMesh = ^TRGSubMesh;
  TRGSubMesh = object
  private
    FMesh:PRGMesh;
    FUseSharedVertices:boolean;
    FOperationType:integer;

    //=== Geometry, can be shared ===
    FVertexCount:integer;
    FVEList:TVertexElementList;

    FVertex  :PVector3;
    FNormal  :PVector3;
    FBiNormal:PVector3;
// not used, coz pointer getter is fast, and indexed value can be different size
//    FTangent :pointer;

    FFaces      :PIntVector3;
    FFaceCount  :integer;
    FMaterial   :integer;

    FBoneCount      :integer;      // count of bones, idk for what
    FBoneAssignCount:integer;      // count of assignments, count of used FBones elements
    FBonesLen       :integer;      // count of FBones elements
    FBones          :PBoneVertex;

//    function GetBlockElementType(atype:integer; aidx:integer=0):integer;
    function GetVertexCount:integer;

    procedure SetBuffer(atype:integer; aptr:pointer);
    procedure SetBuffer(atype:integer; aidx:integer; aptr:pointer);
    function  GetBuffer(atype:integer):pointer;
    function  GetBuffer(atype:integer; aidx:integer):Pointer;

    procedure GetVector(aidx:integer; num:integer; atype:integer; var aresult:TVector4);
//    function  GetData  (aidx:integer; num:integer; atype:integer):TVector4;
    function  GetData  (aidx:integer;              atype:integer):TVector4;
    function  GetData  (                           atype:integer):pointer;

    function GetTexture(     num:integer):pointer;
    function GetTexture(aidx,num:integer):TVector4;
    function GetTextureCount:integer;
    
    function GetFace(idx:integer):TIntVector3;
    function GetFace():pointer;
{
    function GetBonePoint(idx:integer):PBoneVertex;
    function GetBonePoint:pointer;
}
  public
    Is32bit    :boolean;

    procedure Init;
    procedure Free;

//    function IndexedToDirect():boolean;
    procedure SetBonesCapacity(avalue:integer);
    procedure AddBone(avertexIndex, aboneIndex:integer; aweight:single);

    property VertexCount:integer read GetVertexCount write FVertexCount;
 
    property Buffer[atype:integer; idx:integer]:pointer read GetBuffer write SetBuffer;
{
  Vertex   - geometry, single  , Vector3
  Normal   - geometry, single  , Vector3
  Binormal - geometry, single  , Vector3
  Tangent  - geometry, single  , Vector3 OR Vector4
  Texture  - geometry, multiply, Vector2 (Vector3, Vector4)
  Face     - submesh , single  , Vector3 (check OT_*)
}
{
    property Vertex  [i:integer]:TVector4 index VES_POSITION read GetData;
    property Normal  [i:integer]:TVector4 index VES_NORMAL   read GetData;
    property BiNormal[i:integer]:TVector4 index VES_BINORMAL read GetData;
}
    property Vertex  :PVector3 read FVertex;
    property Normal  :PVector3 read FNormal;
    property BiNormal:PVector3 read FBiNormal;
    property Tangent [i:integer]:TVector4 index VES_TANGENT  read GetData;

    property Texture [idx:integer; num:integer]:TVector4 read GetTexture;
    property TextureCount:integer read GetTextureCount;

    property Face    [idx:integer]:TIntVector3 read GetFace;
    property FaceCount:integer read FFaceCount;

    property BoneCount:integer read FBoneCount;
//    property BonePoints[idx:integer]:PBoneVertex read GetBonePoint;
  end;

  TRGMesh = object
  private
    // index 0 for shared (global)
    FSubMeshes:array of PRGSubMesh;
    FSubMeshCount:integer;

    // Mesh version and source (Mesh/MDL) file buffer. used just while import
    FBuffer  :PByte;
    FDataSize:integer;
    FVersion :integer;

    FTextures : array of string;
    FMaterials: array of TMaterial;

    function  GetSubMesh(idx:integer):PRGSubMesh;
    procedure SetSubMesh(idx:integer; amesh:PRGSubMesh);
    function  GetSubMeshCount:integer; inline;
    procedure SetSubMeshCount(aval:integer);

    procedure ReadTextures   (var aptr:PByte);
    function  ReadHobMaterial(var aptr:PByte; aver:integer):boolean;
    function  ReadRGMaterial (var aptr:PByte; aver:integer):boolean;
    function  AddMaterial(const aname:string):integer;

    // *.MDL of RG/RGO
    function ReadMDLType0(var aptr:PByte; aver:integer):boolean;
    function ReadMDLType1(var aptr:PByte; aver:integer):boolean;

    // *.MESH
    procedure ReadMeshLodLevel     (var aptr:PByte);
    procedure ReadEdgeListLod      (var aptr:PByte);
    procedure ReadEdgeLists        (var aptr:PByte);
    procedure ReadPoses            (var aptr:PByte);
    procedure ReadAnimationTrack   (var aptr:PByte);
    procedure ReadAnimation        (var aptr:PByte);
    procedure ReadAnimations       (var aptr:PByte);
    procedure ReadSubmeshNameTable (var aptr:PByte);
    procedure ReadVertexDeclaration(asub:PRGSubMesh; var aptr:PByte);
    procedure ReadGeometry         (asub:PRGSubMesh; var aptr:PByte);
    procedure ReadSubMesh          (asub:PRGSubMesh; var aptr:PByte);

    //set direct pointers to Vertex etc after import;
    procedure FixPointers;

    function ReadMDL (var aptr:PByte):boolean;
    function ReadHob (var aptr:PByte; asMesh:boolean):boolean;
    function ReadMesh(var aptr:PByte):boolean;

    procedure CalcBounds;
  
  public
    Skeleton : string;
    // Bounds
    BoundMin   :TVector3;
    BoundMax   :TVector3;
    BoundRadius:single;   // not in Runic MDL

    procedure Init;
    procedure Free;

    function AddSubMesh():PRGSubMesh;
    function AddSubMesh(amesh:PRGSubMesh):integer;

    function  GetMTL():string;
    function  GetMaterial ():string;
    procedure SaveMaterial(const aFileName:String);
    
    function ImportFromMemory(aptr:PByte; asize:integer):boolean;
    function ImportFromFile  (const aFileName:string):boolean;
    procedure SaveToXML(aStream:TStream);
    procedure SaveToXML(const aFileName:String);
    procedure SaveToOBJ(aStream:TStream);
    procedure SaveToOBJ(const aFileName:String);

    property SubMeshCount:integer read GetSubMeshCount write SetSubMeshCount;
    property SubMesh[idx:integer]:PRGSubMesh read GetSubMesh write SetSubMesh;

    property MeshVersion:integer read FVersion;
  end;


implementation

uses
  sysutils,
  rwmemory;

{$UNDEF Interface}

{%REGION Support}

function GetVESName(asemantic:integer):string;
begin
  if asemantic in [1..VES_COUNT] then
    result:=VESData[asemantic].name
  else
    result:='Unknown '+IntToStr(asemantic)+' semantic';
end;

function GetVETName(atype:integer):string;
begin
  if atype in [0..39] then
    result:=VETData[atype].name
  else
    result:='Unknown '+IntToStr(atype)+' type';
end;

procedure LogLn;
begin
  RGLog.Add('');
end;

procedure Log(const astr:string; const aval:string='');
begin
  if aval<>'' then RGLog.Add(astr+': '+aval) else RGLog.Add(astr);
end;

procedure Log(const astr:string; aval:single);
var
  ls:string;
begin
  Str(aval:0:4,ls);
  RGLog.Add(astr+': '+ls);
end;

procedure Log(const astr:string; aval:boolean);
var
  ls:string;
begin
  if aval then ls:='true' else ls:='false';
  RGLog.Add(astr+': '+ls);
end;

procedure Log(const astr:string; aval:int64);
var
  ls:string;
begin
  Str(aval,ls);
  RGLog.Add(astr+': '+ls);
end;

function GetChunkName(aid:word):string;
var
  i:integer;
begin
  for i:=0 to High(ChunkNames) do
    if ChunkNames[i].id=aid then exit(ChunkNames[i].name);

  result:='';
end;

{%ENDREGION Support}

{$I rg3d.VElist.inc}

{$I rg3d.XML.inc}
{$I rg3d.OBJ.inc}
{$I rg3d.import.inc}
{$I rg3d.Material.inc}

{%REGION RGMesh}
 
procedure TRGMesh.Init;
begin
//  FillChar(self,SizeOf(TRGMesh),0);
  
  SetLength(FSubMeshes,16);
  FSubMeshCount:=0;
  
  AddSubMesh();

  FBuffer:=nil;

  Skeleton:='';
end;

procedure TRGMesh.Free;
var
  i:integer;
begin
  for i:=0 to FSubMeshCount-1 do
  begin
    FSubMeshes[i]^.Free;
    FreeMem(FSubMeshes[i]);
  end;

  SetLength(FSubMeshes,0);
end;

function TRGMesh.GetSubMeshCount():integer;
begin
  result:=FSubMeshCount-1;
end;

procedure TRGMesh.SetSubMeshCount(aval:integer);
var
  i,llen:integer;
begin
  llen:=Length(FSubMeshes);
  if aval>=llen then
  begin
    SetLength(FSubMeshes,Align(aval+7,8));
    for i:=llen to High(FSubMeshes) do
      FSubMeshes[i]:=nil;
  end;
  if aval>=FSubMeshCount then
  begin
    for i:=FSubMeshCount to aval do
    begin
      GetMem(FSubMeshes[i],SizeOf(TRGSubMesh));
      FSubMeshes[i]^.Init;
      FSubMeshes[i]^.FMesh:=@self;
    end;
    FSubMeshCount:=aval+1;
  end;
end;

function TRGMesh.AddSubMesh():PRGSubMesh;
begin
  GetMem(result,SizeOf(TRGSubMesh));
  result^.Init;
  AddSubMesh(result);
end;

function TRGMesh.AddSubMesh(amesh:PRGSubMesh):integer;
begin
  if FSubMeshCount=Length(FSubMeshes) then
    SetLength(FSubMeshes,Align(FSubMeshCount+7,8));

  FSubMeshes[FSubMeshCount]:=amesh;
  amesh^.FMesh:=@self;
  result:=FSubMeshCount;
  inc(FSubMeshCount);
end;

function TRGMesh.GetSubMesh(idx:integer):PRGSubMesh;
begin
  if idx>FSubMeshCount then exit(nil);
  result:=FSubMeshes[idx];
end;

procedure TRGMesh.SetSubMesh(idx:integer; amesh:PRGSubMesh);
begin
  if idx>FSubMeshCount then exit;
  if FSubMeshes[idx]<>nil then FSubMeshes[idx]^.Free;
  FSubMeshes[idx]:=amesh;
end;

procedure TRGMesh.CalcBounds;
var
  lsm:PRGSubMesh;
  i,j:integer;
begin
  if (BoundMin.X=0) and (BoundMax.X=0) then
  begin
    Log('Calculate bounds');

    BoundMin.X:=+10000;
    BoundMin.Y:=+10000;
    BoundMin.Z:=+10000;
    BoundMax.X:=-10000;
    BoundMax.Y:=-10000;
    BoundMax.Z:=-10000;

    for j:=0 to FSubMeshCount-1 do
    begin
      lsm:=FSubMeshes[j];
  //    if lsm^.FVertexCount>0 then
      for i:=0 to lsm^.FVertexCount-1 do
      begin
        if lsm^.Vertex[i].X>BoundMax.X then BoundMax.X:=lsm^.Vertex[i].X;
        if lsm^.Vertex[i].Y>BoundMax.Y then BoundMax.Y:=lsm^.Vertex[i].Y;
        if lsm^.Vertex[i].Z>BoundMax.Z then BoundMax.Z:=lsm^.Vertex[i].Z;
        if lsm^.Vertex[i].X<BoundMin.X then BoundMin.X:=lsm^.Vertex[i].X;
        if lsm^.Vertex[i].Y<BoundMin.Y then BoundMin.Y:=lsm^.Vertex[i].Y;
        if lsm^.Vertex[i].Z<BoundMin.Z then BoundMin.Z:=lsm^.Vertex[i].Z;
      end;
    end;
  end;
end;

{%ENDREGION RGMesh}

{%REGION RGSubMesh}

procedure TRGSubMesh.Init;
begin
  FillChar(self,SizeOf(TRGSubMesh),0);

  FOperationType:=OT_TRIANGLE_LIST;
end;

procedure TRGSubMesh.Free;
var
  i:integer;
begin
  FreeMem(FFaces);
  FreeMem(FBones);

  for i:=0 to FVEList.Count-1 do
    FreeMem(FVEList.Buffer[i]);
end;

function TRGSubMesh.GetVertexCount:integer;
var
  lsm:PRGSubMesh;
begin
  // Use actual submesh
  if FUseSharedVertices then
    lsm:=FMesh^.SubMesh[0]
  else
    lsm:=@self;

  result:=lsm^.FVertexCount;
end;

procedure TRGSubMesh.SetBuffer(atype:integer; aptr:pointer);
begin
  SetBuffer(atype, 0, aptr);
end;

procedure TRGSubMesh.SetBuffer(atype:integer; aidx:integer; aptr:pointer);
var
  i:integer;
begin
  // ignoring indexes if shared data using
  if FUseSharedVertices then exit;

  i:=FVEList.FindType(atype,aidx);
  if i>=0 then
    FVEList.FBuffers[i]:=aptr;
end;

function TRGSubMesh.GetBuffer(atype:integer):pointer;
begin
  result:=GetBuffer(atype, 0);
end;

function TRGSubMesh.GetBuffer(atype:integer; aidx:integer):pointer;
var
  lsm:PRGSubMesh;
  i:integer;
begin
  if FUseSharedVertices then
    lsm:=FMesh^.SubMesh[0]
  else
    lsm:=@self;

  i:=lsm^.FVEList.FindType(atype,aidx);
  if i>=0 then
  begin
    result:=lsm^.FVEList.FBuffers[i];

    if (result=nil) and (atype<>VES_POSITION) then
      result:=GetBuffer(VES_POSITION,0);
  end
  else
    result:=nil;
end;

procedure TRGSubMesh.GetVector(aidx:integer; num:integer; atype:integer; var aresult:TVector4);
var
  lsm:PRGSubMesh;
  pb:PByte;
  ltmp:integer;
begin
  FillChar(aresult,SizeOf(aresult),0);

  if FUseSharedVertices then
    lsm:=FMesh^.SubMesh[0]
  else
    lsm:=@self;

  ltmp:=lsm^.FVEList.FindType(atype,num);
  if ltmp>=0 then
  begin
    pb  :=lsm^.FVEList.FBuffers[ltmp];
    ltmp:=lsm^.FVEList.FVEList [ltmp]._type;
    
    if      ltmp=VET_FLOAT3 then move(PVector3(pb)[aidx],aresult,SizeOf(TVector3))
    else if ltmp=VET_FLOAT2 then move(PVector2(pb)[aidx],aresult,SizeOf(TVector2))
    else if ltmp=VET_FLOAT4 then move(PVector4(pb)[aidx],aresult,SizeOf(TVector4));
  end;
end;

function TRGSubMesh.GetData(aidx:integer; atype:integer):TVector4;
begin
  GetVector(aidx, 0, atype, result);
end;
{
function TRGSubMesh.GetData(aidx:integer; num:integer; atype:integer):TVector4;
begin
  GetVector(aidx, num, atype, result);
end;
}
function TRGSubMesh.GetData(atype:integer):pointer;
begin
  result:=GetBuffer(atype,0);
end;

function TRGSubMesh.GetTexture(num:integer):pointer;
begin
  result:=GetBuffer(VES_TEXTURE_COORDINATES,num);
end;

function TRGSubMesh.GetTexture(aidx,num:integer):TVector4;
begin
  GetVector(aidx,num,VES_TEXTURE_COORDINATES,result);
end;

function TRGSubMesh.GetTextureCount():integer;
var
  lsm:PRGSubMesh;
  i:integer;
begin
  if FUseSharedVertices then
    lsm:=FMesh^.SubMesh[0]
  else
    lsm:=@self;

  result:=0;
  for i:=0 to lsm^.FVEList.Count-1 do
    if lsm^.FVEList.semantic[i]=VES_TEXTURE_COORDINATES then inc(result);
end;

function TRGSubMesh.GetFace(idx:integer):TIntVector3;
begin
  FillChar(result,sizeOf(result),0);
  if (idx>=0) and (idx<FFaceCount) then
    result:=FFaces[idx]
  else
    FillChar(result,sizeOf(result),0);
end;

function TRGSubMesh.GetFace():pointer;
begin
  result:=FFaces;
end;
{
function TRGSubMesh.GetBonePoint(idx:integer):PBoneVertex;
begin
  result:=nil;
end;

function TRGSubMesh.GetBonePoint:pointer;
begin
  result:=nil;
end;
}
procedure TRGSubMesh.SetBonesCapacity(avalue:integer);
begin
  if FBonesLen<avalue then
  begin
    FBonesLen:=Align(avalue+63,64);
    ReallocMem(FBones,FBonesLen*SizeOf(TBoneVertex));
  end;
end;

procedure TRGSubMesh.AddBone(avertexIndex, aboneIndex:integer; aweight:single);
begin
  if FBoneAssignCount=FBonesLen then
  begin
    // let's minimum 2.5 vertex per bone
    if FBonesLen=0 then FBonesLen:=FVertexCount*2+(FVertexCount div 2);
    FBonesLen:=Align(FBonesLen+(FVertexCount div 2),64);
    ReallocMem(FBones,FBonesLen*SizeOf(TBoneVertex));
  end;

  with FBones[FBoneAssignCount] do
  begin
    vertexIndex:=avertexIndex;
    boneIndex  :=aboneIndex;
    weight     :=aweight;
  end;
  
  inc(FBoneAssignCount);
end;
{
function TRGSubMesh.IndexedToDirect():boolean;
begin
  result:=false;
end;
}
{%ENDREGION RGSubMesh}

end.
