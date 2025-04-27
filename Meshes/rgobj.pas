unit RGObj;

interface

uses
  classes,
  rgglobal;

{$DEFINE Interface}

{$I rg3d.ogre.inc}

type
  PIntVector3 = ^TIntVector3;
  TIntVector3 = packed record
    X: Int32;
    Y: Int32;
    Z: Int32;
  end;

type
  TRGB = packed record // byte used, word is in file
    R:Word;
    G:Word;
    B:Word;
  end;
  PMaterial = ^TMaterial;
  TMaterial = record
    name   :string;
    ambient :TRGB;
    diffuse :TRGB;
    specular:TRGB;
    emissive:TRGB;
    add     :TRGB;
    textures:array [0..16] of integer;
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

    FFaces      :PIntVector3;
    FFaceCount  :integer;
    FMaterial   :integer;

    FBoneCount      :integer;      // count of bones, idk for what
    FBoneAssignCount:integer;      // count of assignments, count of used FBones elements
    FBonesLen       :integer;      // count of FBones elements
    FBones          :PBoneVertex;

//    function GetBlockElementType(atype:integer; aidx:integer=0):integer;
    function GetVertexCount:integer;

    procedure SetIndex(atype:integer; aptr:pointer);
    procedure SetIndex(atype:integer; aidx:integer; aptr:pointer);
    function  GetIndex(atype:integer):pointer;
    function  GetIndex(atype:integer; aidx:integer):Pointer;

    function GetData(atype:integer; idx:integer):TVector4;
    function GetUV(idx:integer; num:integer):TVector2;
    function GetUV(idx:integer             ):TVector2;

    function GetFace(idx:integer):TIntVector3;
    function GetFace():pointer;

    function GetBonePoint(idx:integer):PBoneVertex;
    function GetBonePoint:pointer;
  public
    Is32bit    :boolean;

    procedure Init;
    procedure Free;

    function IndexedToDirect():boolean;
    procedure AddBone(avertexIndex, aboneIndex:integer; aweight:single);

    property VertexCount:integer read GetVertexCount write FVertexCount;
 
    property Buffer[atype:integer; idx:integer]:pointer read GetIndex write SetIndex;

    property Vertex  [idx:integer]:TVector4 index VES_POSITION read GetData;
    property Normal  [idx:integer]:TVector4 index VES_NORMAL   read GetData;
    property BiNormal[idx:integer]:TVector4 index VES_BINORMAL read GetData;
    property Tangent [idx:integer]:TVector4 index VES_TANGENT  read GetData;

    property Texture [idx:integer; num:integer]:TVector2 read GetUV;
    property Face    [idx:integer]:TIntVector3 read GetFace;

    property BonePoints[idx:integer]:PBoneVertex read GetBonePoint;
  end;

  TRGMesh = object
  private
    // index 0 for shared (global)
    FSubMeshes:array of PRGSubMesh;
    FSubMeshCount:integer;

    // source (Mesh/MDL) file buffer. used just while import
    FBuffer  :PByte;
    FDataSize:integer;

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

    function ReadMDLType0(var aptr:PByte; aver:integer):boolean;
    function ReadMDLType1(var aptr:PByte; aver:integer):boolean;

    procedure ReadVertexDeclaration(asub:PRGSubMesh; var aptr:PByte);
    procedure ReadGeometry         (asub:PRGSubMesh; var aptr:PByte);
    procedure ReadSubMesh          (asub:PRGSubMesh; var aptr:PByte);

    
    function ReadMDL (var aptr:PByte):boolean;
    function ReadHob (var aptr:PByte; asMesh:boolean):boolean;
    function ReadMesh(var aptr:PByte):boolean;
  
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

    function  GetMaterial ():string;
    procedure SaveMaterial(const aFileName:String);
    
    function ImportFromMemory(aptr:PByte; asize:integer):boolean;
    function ImportFromFile  (const aFileName:string):boolean;
    procedure SaveToXML(aStream:TStream);
    procedure SaveToXML(const aFileName:String);

    property SubMeshCount:integer read GetSubMeshCount write SetSubMeshCount;
    property SubMesh[idx:integer]:PRGSubMesh read GetSubMesh write SetSubMesh;
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

procedure Log(const astr:string; const aval:string);
begin
  RGLog.Add(astr+': '+aval);
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
{.$I rg3d.OBJ.inc}
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
    SetLength(FSubMeshes,Align(llen+7,8));
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

procedure TRGSubMesh.SetIndex(atype:integer; aptr:pointer);
begin
  SetIndex(atype, 0, aptr);
end;

procedure TRGSubMesh.SetIndex(atype:integer; aidx:integer; aptr:pointer);
var
  i:integer;
begin
  // ignoring indexes if shared data using
  if FUseSharedVertices then exit;

  i:=FVEList.FindType(atype,aidx);
  if i>=0 then
    FVEList.FBuffers[i]:=aptr;
end;

function TRGSubMesh.GetIndex(atype:integer):pointer;
begin
  result:=GetIndex(atype, 0);
end;

function TRGSubMesh.GetIndex(atype:integer; aidx:integer):pointer;
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
      result:=GetIndex(VES_POSITION,0);
  end
  else
    result:=nil;
end;

function TRGSubMesh.GetData(atype:integer; idx:integer):TVector4;
var
  lsm:PRGSubMesh;
  pb:PByte;
  ltmp:integer;
begin
  FillChar(result,SizeOf(result),0);

  if FUseSharedVertices then
    lsm:=FMesh^.SubMesh[0]
  else
    lsm:=@self;

  ltmp:=lsm^.FVEList.FindType(atype,0);
  if ltmp>=0 then
  begin
    pb  :=lsm^.FVEList.FBuffers[ltmp];
    ltmp:=lsm^.FVEList.FVEList [ltmp]._type;
    // required element address: buffer+offset+idx*blocksize
    
    if      ltmp=VET_FLOAT3 then move(pb^,result,SizeOf(TVector3))
    else if ltmp=VET_FLOAT4 then move(pb^,result,SizeOf(TVector4));
  end;
end;

function TRGSubMesh.GetUV(idx,num:integer):TVector2;
begin
  FillChar(result,sizeOf(result),0);
end;

function TRGSubMesh.GetUV(idx:integer):TVector2;
begin
  result:=GetUV(idx,0);
end;

function TRGSubMesh.GetFace(idx:integer):TIntVector3;
begin
  FillChar(result,sizeOf(result),0);
end;

function TRGSubMesh.GetFace():pointer;
begin
  result:=nil;
end;

function TRGSubMesh.GetBonePoint(idx:integer):PBoneVertex;
begin
  result:=nil;
end;

function TRGSubMesh.GetBonePoint:pointer;
begin
  result:=nil;
end;

procedure TRGSubMesh.AddBone(avertexIndex, aboneIndex:integer; aweight:single);
begin
  if FBoneAssignCount=FBonesLen then
  begin
    FBonesLen:=Align(FBonesLen+63,64);
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

function TRGSubMesh.IndexedToDirect():boolean;
begin
  result:=false;
end;

{%ENDREGION RGSubMesh}

end.
