{TODO: save all materials as is for export/import}
{TODO: keep name to use in save files and skeleton}
{TODO: differentiate skeleton name with and without path}
{NOTE: RG's/RGO's <name>_compiled.skeleton is ver 1/8}
{NOTE: RGO don't have skeleton name.}
{NOTE: RGO's skeleton have wrong control points}
unit RGObj;

interface

uses
  classes,
  rgglobal;

{$DEFINE Interface}

{$I rg3d.ogre.inc}
{$I rg3d.material.inc}

type
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
    Name:string;

    //=== Geometry, can be shared ===
    FVertexCount:integer;
    FVEList:TVertexElementList;

    FVertex  :PVector3;
    FNormal  :PVector3;
    FBiNormal:PVector3; // not necessary, can be ignored
// not used, coz pointer getter is fast, and indexed value can be different size
//    FTangent :pointer;

    FFaces      :PIntVector3;
    FFaceCount  :integer;
    FMaterial   :integer;

    FBoneAssignCount:integer;      // count of assignments, count of used FBones elements
    FBonesLen       :integer;      // count of FBones elements
    FBones          :PBoneVertex;

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
    procedure Init;
    procedure Free;

//    function IndexedToDirect():boolean;
    procedure SetBonesCapacity(avalue:integer);
    procedure AddBone(avertexIndex, aboneIndex:integer; aweight:single);

    property VertexCount:integer read GetVertexCount write FVertexCount;
 
    property Vertices[atype:integer; idx:integer]:pointer read GetBuffer write SetBuffer;
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
//    property Vertex  :PVector3 read FVertex;
//    property Normal  :PVector3 read FNormal;
    // next two are not necessary
//    property BiNormal:PVector3 read FBiNormal;
    property Tangent [i:integer]:TVector4 index VES_TANGENT  read GetData;

    property Texture [idx:integer; num:integer]:TVector4 read GetTexture;
    property TextureCount:integer read GetTextureCount;

    property Face    [idx:integer]:TIntVector3 read GetFace;
    property FaceCount:integer read FFaceCount;

    property Material:integer read FMaterial;
//    property BonePoints[idx:integer]:PBoneVertex read GetBonePoint;
  end;

  TRGMesh = object
  private
    // index 0 for shared (global)
    FSubMeshes:array of PRGSubMesh;
    FSubMeshCount:integer;

    Name:string;
    FBoneCount:integer; // count of skeleton bones
    // Mesh version and source (Mesh/MDL) file buffer. used just while import
    FBuffer  :PByte;
    FDataSize:integer;
    FVersion :integer;

    FMaterialDump:PByte;
    FDumpSize:integer;

    function  GetSubMesh(idx:integer):PRGSubMesh;
    procedure SetSubMesh(idx:integer; amesh:PRGSubMesh);
    function  GetSubMeshCount:integer; inline;
    procedure SetSubMeshCount(aval:integer);

{$I rg3d.import.inc}
{$I rg3d.export.inc}

    procedure ReadTextures    (var aptr:PByte);
    function  ReadRGMaterial  (var aptr:PByte; aver:integer):boolean;
    function  ReadHobMaterials(var aptr:PByte; aver:integer):boolean;

    function  AddMaterial(const aname:string):integer;
    function  GetMaterial(aid:integer):PMaterial;

    procedure WriteRGMaterial (astream:TStream; aver:integer);
    procedure WriteHobMaterial(astream:TStream);

    function CalcBounds(force:boolean=false):boolean;
    procedure ConvertToShared();
  
  public
    FTextures : array of string;
    FMaterials: array of TMaterial;
    Skeleton : string;
    // Bounds
    BoundMin   :TVector3;
    BoundMax   :TVector3;
    BoundRadius:single;   // not in Runic MDL

    procedure Init;
    procedure Free;

    function  AddSubMesh():PRGSubMesh;
    function  AddSubMesh(amesh:PRGSubMesh):integer;
    procedure DeleteSubMesh(idx:integer);

    function  GetMTL():string;
    function  GetMaterial ():string;
    procedure SaveMaterial(const aFileName:String);
    
    procedure ReadMaterialSimple(abuf:PByte; asize:integer);
    function  ImportFromMemory  (aptr:PByte; asize:integer):boolean;
    function  ImportFromFile  (const aFileName:string):boolean;
    procedure SaveToXML(aStream:TStream);
    procedure SaveToXML(const aFileName:String);
    procedure SaveToOBJ(aStream:TStream);
    procedure SaveToOBJ(const aFileName:String);
    procedure WriteMDL (astream:TStream; aver:integer);
    procedure WriteMesh(astream:TStream; aver:integer);

    property SubMeshCount:integer read GetSubMeshCount write SetSubMeshCount;
    property SubMesh[idx:integer]:PRGSubMesh read GetSubMesh write SetSubMesh;

    property MeshVersion:integer read FVersion;
    property BoneCount  :integer read FBoneCount;
  end;


implementation

uses
  sysutils,
  rgstream,
  rwmemory;

{$UNDEF Interface}

{%REGION Support}

procedure WriteText(astream:TStream; const atext:AnsiString);
begin
  if atext<>'' then astream.Write(atext[1],Length(atext));
  astream.WriteByte($0A);
end;

function memReadText(var abuf:PByte):string;
var
  lptr:PByte;
  lsize:integer;
begin
  lptr:=abuf;
  while abuf^<>10 do inc(abuf);

  lsize:=abuf-lptr;
  if lsize=0 then
    result:=''
  else
    SetString(result,PAnsiChar(lptr),lsize);
  inc(abuf);
end;

function GetVersionText(aver:integer):AnsiString;
var
  i:integer;
begin
  for i:=0 to High(FileVersions) do
    if FileVersions[i].ver=aver then exit(FileVersions[i].sign);

  result:='';
end;

function TranslateVersion(const sign:AnsiString):integer;
var
  i:integer;
begin
  for i:=0 to High(FileVersions) do
    if FileVersions[i].sign=sign then exit(FileVersions[i].ver);

  result:=-1;
end;

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
{$I rg3d.export.inc}
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
  FreeMem(FMaterialDump);

  for i:=0 to FSubMeshCount-1 do
  begin
    FSubMeshes[i]^.Free;
    FreeMem(FSubMeshes[i]);
  end;

  SetLength(FSubMeshes,0);
  SetLength(FTextures,0);
  SetLength(FMaterials,0);
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

procedure TRGMesh.DeleteSubMesh(idx:integer);
var
  i:integer;
begin
  if (idx<0) or (idx>=FSubMeshCount) then exit;

  FSubMeshes[idx]^.Free;
  FreeMem(FSubMeshes[idx]);
  dec(FSubMeshCount);
  if idx<>FSubMeshCount then
    for i:=idx to FSubMeshCount-1 do FSubMeshes[i]:=FSubMeshes[i+1];
//    move(FSubMeshes[idx+1],FSubMeshes[idx],(FSubMeshCount-idx)*SizeOf(PRGSubMesh));

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

function TRGMesh.CalcBounds(force:boolean=false):boolean;
var
  lsm:PRGSubMesh;
  vp:PVector3;
  i,j:integer;
begin
  if (not force) and (BoundMin.X<>0) and (BoundMax.X<>0) and (BoundRadius<>0) then exit(false);

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
    if lsm^.FVertexCount>0 then
    begin
      vp:=lsm^.Vertices[VES_POSITION];
      for i:=0 to lsm^.FVertexCount-1 do
      begin
        with vp[i] do
        begin
          if X>BoundMax.X then BoundMax.X:=X;
          if Y>BoundMax.Y then BoundMax.Y:=Y;
          if Z>BoundMax.Z then BoundMax.Z:=Z;
          if X<BoundMin.X then BoundMin.X:=X;
          if Y<BoundMin.Y then BoundMin.Y:=Y;
          if Z<BoundMin.Z then BoundMin.Z:=Z;
        end;
      end;
    end;
  end;

  BoundRadius:=ABS(BoundMin.Y);
  if BoundRadius<BoundMax.Y then BoundRadius:=BoundMax.Y;

  result:=true;
end;

procedure TRGMesh.ConvertToShared();
var
  lshared,lsm:PRGSubMesh;
  lptr:PByte;
  lvoffset,lvcnt,lcnt:integer;
  lsize,i,j,k:integer;
begin
  //--- Get amount of adding vertices
  lvcnt:=0;
  lcnt:=0;
  for i:=1 to FSubMeshCount-1 do
  begin
    inc(lvcnt,FSubMeshes[i]^.FVertexCount);
    inc(lcnt ,FSubMeshes[i]^.FBoneAssignCount);
  end;
  if lvcnt=0 then exit;

  //--- expand shared buffers
  lshared:=FSubMeshes[0];

  if lcnt>0 then
    lshared^.SetBonesCapacity(lshared^.FBoneAssignCount+lcnt);

  for i:=0 to lshared^.FVEList.Count-1 do
  begin
    // best way is delete/don't assign unused blocks
    lptr:=lshared^.FVEList.Buffer[i];
    ReallocMem(lptr,
              (lshared^.FVertexCount+lvcnt)*
               lshared^.FVEList.Size[i]);
    lshared^.FVEList.Buffer[i]:=lptr;
  end;

  //-- every submesh
  lvoffset:=lshared^.FVertexCount;
  for i:=1 to FSubMeshCount-1 do
  begin
    lsm:=SubMesh[i];
    if lsm^.FVertexCount=0 then continue;

    lcnt:=-1; // texture block counter
    //--- every block
    for j:=0 to lsm^.FVEList.Count-1 do
    begin
      if lsm^.FVEList.Buffer[j]=nil then continue;

      //--- Check for multiply texture blocks (ignore multiply colors atm)
      if lsm^.FVEList.FVEList[j].semantic=VES_TEXTURE_COORDINATES then
      begin
        inc(lcnt);
        k:=lshared^.FVEList.FindType(lsm^.FVEList.FVEList[j].semantic,lcnt);
      end
      else
        k:=lshared^.FVEList.FindType(lsm^.FVEList.FVEList[j].semantic);

      //--- No shared block for this type, need to add
      if k<0 then
      begin
        // Add block
        k:=lshared^.FVEList.Add(
           lshared^.FVEList.Count,
           lsm^.FVEList.FVEList[j]._type,
           lsm^.FVEList.FVEList[j].semantic,
           0,0);
        // Allocate buffer
        GetMem(lptr,
           (lshared^.FVertexCount+lvcnt)*
            lshared^.FVEList.Size[j]);
        lshared^.FVEList.Buffer[k]:=lptr;
        // Set pointers
        case lshared^.FVElist[k]^.semantic of
          VES_POSITION: lshared^.FVertex  :=PVector3(lshared^.FVElist.Buffer[k]);
          VES_NORMAL  : lshared^.FNormal  :=PVector3(lshared^.FVElist.Buffer[k]);
          VES_BINORMAL: lshared^.FBiNormal:=PVector3(lshared^.FVElist.Buffer[k]);
        end;
      end;

      //--- Copy submesh data to shared (if data type the same)
      if k>=0 then
      begin
        lsize  :=    lsm^.FVEList.Size[j];
        if lsize>lshared^.FVEList.Size[k] then
          lsize:=lshared^.FVEList.Size[k];

        move( lsm^.FVEList.Buffer[j]^,
          lshared^.FVEList.Buffer[k][
          lvoffset*lshared^.FVEList.Size[k]],
              lsm^.FVertexCount*lsize);
      end;
    end;

    //--- move bones to shared
    for j:=0 to lsm^.FBoneAssignCount-1 do
    begin
      // let's think what vertexIndex is submesh local
      with lsm^.FBones[j] do
        lshared^.AddBone(vertexIndex+lvoffset,boneIndex,weight);
    end;
    FreeMem(lsm^.FBones);
    lsm^.FBonesLen:=0;
    lsm^.FBones:=nil;
    lsm^.FBoneAssignCount:=0;

    //--- Set new faces vertex index (add offset in shared buffer)
    for k:=0 to lsm^.FaceCount-1 do
    begin
      with lsm^.FFaces[k] do
      begin
        inc(X,lvoffset);
        inc(Y,lvoffset);
        inc(Z,lvoffset);
      end;
    end;

    inc(lvoffset,lsm^.FVertexCount);

    //--- Delete unused blocks
    for j:=lsm^.FVEList.Count-1 downto 0 do
      lsm^.FVEList.Delete(j);
    lsm^.FVertexCount:=0;
  end;
  inc(lshared^.FVertexCount,lvcnt);
end;
{%ENDREGION RGMesh}

{%REGION RGSubMesh}

procedure TRGSubMesh.Init;
begin
  FillChar(self,SizeOf(TRGSubMesh),0);
end;

procedure TRGSubMesh.Free;
var
  i:integer;
begin
  Name:='';

  FreeMem(FFaces);
  FreeMem(FBones);

  for i:=0 to FVEList.Count-1 do
    FreeMem(FVEList.Buffer[i]);
end;

function TRGSubMesh.GetVertexCount:integer;
begin
  result:=FVertexCount;
//  if result=0 then result:=FMesh^.SubMesh[0]^.FVertexCount;
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
  if FVertexCount=0 then exit;

  i:=FVEList.FindType(atype,aidx);
  if i>=0 then
  begin
    FreeMem(FVEList.FBuffers[i]);
    FVEList.FBuffers[i]:=aptr;
  end;
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
  if FVertexCount=0 then
    lsm:=FMesh^.SubMesh[0]
  else
    lsm:=@self;

  i:=lsm^.FVEList.FindType(atype,aidx);
  if i>=0 then
  begin
    result:=lsm^.FVEList.FBuffers[i];
//    if (result=nil) and (atype<>VES_POSITION) then result:=GetBuffer(VES_POSITION,0);
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

  if FVertexCount=0 then
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
  if FVertexCount=0 then
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
function TRGSubMesh.GetBonePoint(idx:integer):PBoneVertex;
begin
  result:=nil;
end;

function TRGSubMesh.GetBonePoint:pointer;
begin
  result:=nil;
end;
}
{
function TRGSubMesh.IndexedToDirect():boolean;
begin
  result:=false;
end;
}
{%ENDREGION RGSubMesh}

end.
