unit RGMesh;

interface

procedure Trace(const fname:AnsiString);


implementation

uses
  Classes,
  SysUtils,
  rgglobal,
  rgstream;

const
  M_HEADER = $1000;
  M_MESH   = $3000;
     // bool skeletallyAnimated   // important flag which affects h/w buffer policies
     // Optional M_GEOMETRY chunk
     M_SUBMESH = $4000;
         // char* materialName
         // bool useSharedVertices
         // unsigned int indexCount
         // bool indexes32Bit
         // unsigned int* faceVertexIndices (indexCount)
         // OR
         // unsigned short* faceVertexIndices (indexCount)
         // M_GEOMETRY chunk (Optional: present only if useSharedVertices = false)
         M_SUBMESH_OPERATION = $4010; // optional, trilist assumed if missing
             // unsigned short operationType
         M_SUBMESH_BONE_ASSIGNMENT = $4100;
             // Optional bone weights (repeating section)
             // unsigned int vertexIndex;
             // unsigned short boneIndex;
             // float weight;
         // Optional chunk that matches a texture name to an alias
         // a texture alias is sent to the submesh material to use this texture name
         // instead of the one in the texture unit with a matching alias name
         M_SUBMESH_TEXTURE_ALIAS = $4200; // Repeating section
             // char* aliasName;
             // char* textureName;

     M_GEOMETRY = $5000; // NB this chunk is embedded within M_MESH and M_SUBMESH
         // unsigned int vertexCount
         M_GEOMETRY_VERTEX_DECLARATION = $5100;
             M_GEOMETRY_VERTEX_ELEMENT = $5110; // Repeating section
                 // unsigned short source;   // buffer bind source
                 // unsigned short type;     // VertexElementType
                 // unsigned short semantic; // VertexElementSemantic
                 // unsigned short offset;   // start offset in buffer in bytes
                 // unsigned short index;    // index of the semantic (for colours and texture coords)
         M_GEOMETRY_VERTEX_BUFFER = $5200; // Repeating section
             // unsigned short bindIndex;    // Index to bind this buffer to
             // unsigned short vertexSize;   // Per-vertex size, must agree with declaration at this index
             M_GEOMETRY_VERTEX_BUFFER_DATA = $5210;
                 // raw buffer data
     M_MESH_SKELETON_LINK = $6000;
         // Optional link to skeleton
         // char* skeletonName           : name of .skeleton to use
     M_MESH_BONE_ASSIGNMENT = $7000;
         // Optional bone weights (repeating section)
         // unsigned int vertexIndex;
         // unsigned short boneIndex;
         // float weight;
     M_MESH_LOD_LEVEL = $8000;
         // Optional LOD information
         // string strategyName;
         // unsigned short numLevels;
         // bool manual;  (true for manual alternate meshes, false for generated)
         M_MESH_LOD_USAGE = $8100;
         // Repeating section, ordered in increasing depth
         // NB LOD 0 (full detail from 0 depth) is omitted
         // LOD value - this is a distance, a pixel count etc, based on strategy
         // float lodValue;
             M_MESH_LOD_MANUAL = $8110;
             // Required if M_MESH_LOD section manual = true
             // String manualMeshName;
             M_MESH_LOD_GENERATED = $8120;
             // Required if M_MESH_LOD section manual = false
             // Repeating section (1 per submesh)
             // unsigned int indexCount;
             // bool indexes32Bit
             // unsigned short* faceIndexes;  (indexCount)
             // OR
             // unsigned int* faceIndexes;  (indexCount)
     M_MESH_BOUNDS = $9000;
         // float minx, miny, minz
         // float maxx, maxy, maxz
         // float radius
             
     // Added By DrEvil
     // optional chunk that contains a table of submesh indexes and the names of
     // the sub-meshes.
     M_SUBMESH_NAME_TABLE = $A000;
         // Subchunks of the name table. Each chunk contains an index & string
         M_SUBMESH_NAME_TABLE_ELEMENT = $A100;
             // short index
             // char* name
     
     // Optional chunk which stores precomputed edge data                     
     M_EDGE_LISTS = $B000;
         // Each LOD has a separate edge list
         M_EDGE_LIST_LOD = $B100;
             // unsigned short lodIndex
             // bool isManual            // If manual, no edge data here, loaded from manual mesh
                 // bool isClosed
                 // unsigned long numTriangles
                 // unsigned long numEdgeGroups
                 // Triangle* triangleList
                     // unsigned long indexSet
                     // unsigned long vertexSet
                     // unsigned long vertIndex[3]
                     // unsigned long sharedVertIndex[3] 
                     // float normal[4] 

                 M_EDGE_GROUP = $B110;
                     // unsigned long vertexSet
                     // unsigned long triStart
                     // unsigned long triCount
                     // unsigned long numEdges
                     // Edge* edgeList
                         // unsigned long  triIndex[2]
                         // unsigned long  vertIndex[2]
                         // unsigned long  sharedVertIndex[2]
                         // bool degenerate

     // Optional poses section, referred to by pose keyframes
     M_POSES = $C000;
         M_POSE = $C100;
             // char* name (may be blank)
             // unsigned short target    // 0 for shared geometry, 
                                         // 1+ for submesh index + 1
             // bool includesNormals [1.8+]
             M_POSE_VERTEX = $C111;
                 // unsigned long vertexIndex
                 // float xoffset, yoffset, zoffset
                 // float xnormal, ynormal, znormal (optional, 1.8+)
     // Optional vertex animation chunk
     M_ANIMATIONS = $D000;
         M_ANIMATION = $D100;
         // char* name
         // float length
         M_ANIMATION_BASEINFO = $D105;
         // [Optional] base keyframe information (pose animation only)
         // char* baseAnimationName (blank for self)
         // float baseKeyFrameTime
 
         M_ANIMATION_TRACK = $D110;
             // unsigned short type          // 1 == morph, 2 == pose
             // unsigned short target        // 0 for shared geometry, 
                                             // 1+ for submesh index + 1
             M_ANIMATION_MORPH_KEYFRAME = $D111;
                 // float time
                 // bool includesNormals [1.8+]
                 // float x,y,z          // repeat by number of vertices in original geometry
             M_ANIMATION_POSE_KEYFRAME = $D112;
                 // float time
                 M_ANIMATION_POSE_REF = $D113; // repeat for number of referenced poses
                     // unsigned short poseIndex 
                     // float influence

     // Optional submesh extreme vertex list chink
     M_TABLE_EXTREMES = $E000;
     // unsigned short submesh_index;
     // float extremes [n_extremes][3];

const
  ChunkNames: array of record
    id  : word;
    name: string;
  end = (
    (id:$1000; name:'M_HEADER'),
    (id:$3000; name:'M_MESH'),
    (id:$4000; name:'M_SUBMESH'),
    (id:$4010; name:'M_SUBMESH_OPERATION'),
    (id:$4100; name:'M_SUBMESH_BONE_ASSIGNMENT'),
    (id:$4200; name:'M_SUBMESH_TEXTURE_ALIAS'),
    (id:$5000; name:'M_GEOMETRY'),
    (id:$5100; name:'M_GEOMETRY_VERTEX_DECLARATION'),
    (id:$5110; name:'M_GEOMETRY_VERTEX_ELEMENT'),
    (id:$5200; name:'M_GEOMETRY_VERTEX_BUFFER'),
    (id:$5210; name:'M_GEOMETRY_VERTEX_BUFFER_DATA'),
    (id:$6000; name:'M_MESH_SKELETON_LINK'),
    (id:$7000; name:'M_MESH_BONE_ASSIGNMENT'),
    (id:$8000; name:'M_MESH_LOD_LEVEL'),
    (id:$8100; name:'M_MESH_LOD_USAGE'),
    (id:$8110; name:'M_MESH_LOD_MANUAL'),
    (id:$8120; name:'M_MESH_LOD_GENERATED'),
    (id:$9000; name:'M_MESH_BOUNDS'),
    (id:$A000; name:'M_SUBMESH_NAME_TABLE'),
    (id:$A100; name:'M_SUBMESH_NAME_TABLE_ELEMENT'),
    (id:$B000; name:'M_EDGE_LISTS'),
    (id:$B100; name:'M_EDGE_LIST_LOD'),
    (id:$B110; name:'M_EDGE_GROUP'),
    (id:$C000; name:'M_POSES'),
    (id:$C100; name:'M_POSE'),
    (id:$C111; name:'M_POSE_VERTEX'),
    (id:$D000; name:'M_ANIMATIONS'),
    (id:$D100; name:'M_ANIMATION'),
    (id:$D105; name:'M_ANIMATION_BASEINFO'),
    (id:$D110; name:'M_ANIMATION_TRACK'),
    (id:$D111; name:'M_ANIMATION_MORPH_KEYFRAME'),
    (id:$D112; name:'M_ANIMATION_POSE_KEYFRAME'),
    (id:$D113; name:'M_ANIMATION_POSE_REF'),
    (id:$E000; name:'M_TABLE_EXTREMES')
  );

const
  FileVersions : array of record
    ver : integer;
    sign: string;
  end = (
    (ver: 10; sign:'[MeshSerializer_v1.10]' ), // deprecated
    (ver: 20; sign:'[MeshSerializer_v1.20]' ), // deprecated
    (ver: 30; sign:'[MeshSerializer_v1.30]' ),
    (ver: 40; sign:'[MeshSerializer_v1.40]' ), // TL1 / TL2
    (ver: 41; sign:'[MeshSerializer_v1.41]' ),
    (ver: 80; sign:'[MeshSerializer_v1.8]'  ),
    (ver: 91; sign:'[MeshSerializer_v1.9_o]'), // Hob
    (ver: 99; sign:'[MeshSerializer_Runic]' ), // RG/RGO
    (ver:100; sign:'[MeshSerializer_v1.100]')
  );

type
  TOgreChunk = packed record
    _type:word;
    _len :dword;
  end;

type
  TRGMesh = object
  private
    FStream:TStream;
    FVertexCount:integer;
    FVersion:integer;

    procedure ReadGeometryVertexElement;
    procedure ReadGeometryVertexDeclaration;
    procedure ReadGeometryVertexBuffer;
    procedure ReadGeometry;
    procedure ReadSubMesh;
    procedure ReadMeshLodLevel;
    procedure ReadSubmeshNameTable;
    procedure ReadEdgeGroup;
    procedure readEdgeListLodInfo;
    procedure ReadEdgeListLod;
    procedure ReadEdgeLists;
    procedure ReadPose;
    procedure ReadPoses;
    procedure ReadAnimationPoseKeyFrame;
    procedure ReadAnimationMorphKeyFrame;
    procedure ReadAnimationTrack;
    procedure ReadAnimation;
    procedure ReadAnimations;
    procedure ReadMesh;
    function  ReadMeshFile:boolean;

  public
    procedure Init;
    procedure Free;
    procedure Clear;
    procedure LoadFromFile(fname:PAnsiChar);
  end;

{%REGION Support}
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
  result:='- Unknown -';
end;

function TranslateVersion(const sign:AnsiString):integer;
var
  i:integer;
begin
  for i:=0 to High(FileVersions) do
    if FileVersions[i].sign=sign then exit(FileVersions[i].ver);

  result:=-1;
end;

function ReadText(astream:TStream):string;
var
  buf:array [0..511] of AnsiChar;
  i:integer;
begin
  i:=0;
  while astream.Position<=astream.Size do
  begin
    buf[i]:=CHR(astream.ReadByte());
    if buf[i]=#10 then break;
    inc(i);
  end;
  if buf[i]<>#10 then inc(i);
  buf[i]:=#0;

  result:=PAnsiChar(@buf[0]);
end;

function ReadChunk(astream:TStream; var achunk:TOgreChunk):word;
begin
  achunk._type:=astream.ReadWord ();
  achunk._len :=astream.ReadDWord();
  result:=achunk._type;

  RGLog.Add('Chunk type: 0x'+HexStr(achunk._type,4)+' '+GetChunkName(achunk._type)+
            '; length=0x'   +HexStr(achunk._len ,4)+' ('+IntToStr(achunk._len)+
            '); offset=0x'  +HexStr(astream.Position-SizeOf(achunk),8));
end;
{%ENDREGION Support}

procedure TRGMesh.ReadGeometryVertexElement;
begin
  Log('source'  ,FStream.ReadWord());
  Log('type'    ,FStream.ReadWord());
  Log('semantic',FStream.ReadWord());
  Log('offset'  ,FStream.ReadWord());
  Log('index'   ,FStream.ReadWord());
end;

procedure TRGMesh.ReadGeometryVertexDeclaration;
var
  lchunk:TOgreChunk;
  lpos:integer;
begin
  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    if ReadChunk(FStream,lchunk)=M_GEOMETRY_VERTEX_ELEMENT then
    begin
      ReadGeometryVertexElement();
    end
    else
    begin
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadGeometryVertexBuffer;
var
  lchunk:TOgreChunk;
  lsize:integer;
begin
  Log('bindIndex' ,FStream.ReadWord());
  lsize:=FStream.ReadWord();
  Log('vertexSize',lsize);

  if ReadChunk(FStream,lchunk)=M_GEOMETRY_VERTEX_BUFFER_DATA then
    FStream.Seek(FVertexCount*lsize,soFromCurrent);
  ;// skip VertexCount*VertexSize

end;

procedure TRGMesh.ReadGeometry;
var
  lchunk:TOgreChunk;
  lpos:int64;
  lcnt:integer;
begin
  lcnt:=FStream.ReadDWord();
  Log('vertextCount',lcnt);

  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    case ReadChunk(FStream,lchunk) of

      M_GEOMETRY_VERTEX_DECLARATION: begin
        ReadGeometryVertexDeclaration();
      end;

      M_GEOMETRY_VERTEX_BUFFER: begin
        ReadGeometryVertexBuffer();
      end;

    else
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadSubMesh;
var
  lchunk:TOgreChunk;
  lpos:int64;
  i,lcnt:integer;
  lindice:dword;
  lshared:boolean;
  l32bit:boolean;
begin
  Log('materialName',ReadText(FStream));
  lshared:=FStream.ReadByte()<>0;
  Log('useSharedVertices',lshared);
  lcnt:=FStream.ReadDWord();
  Log('indexCount',lcnt);
  l32bit:=FStream.ReadByte()<>0;
  Log('indexes32Bit',l32bit);
  for i:=0 to lcnt-1 do
  begin
    if l32bit then
      lindice:=FStream.ReadDWord()
    else
      lindice:=FStream.ReadWord();
//    Log('faceVertextIndices['+IntToStr(i)+']',lindice);
  end;

  if not lshared then
  begin
    lpos:=FStream.Position;

    if ReadChunk(FStream,lchunk)=M_GEOMETRY then
    begin
      ReadGeometry();
      FStream.Position:=lpos+lchunk._len;
    end
    else // exception in original sources
      FStream.Position:=lpos;
  end;

  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    case ReadChunk(FStream,lchunk) of

      M_SUBMESH_OPERATION: begin
        Log('operationType',FStream.ReadWord());
      end;

      M_SUBMESH_BONE_ASSIGNMENT: begin
        Log('VertextIndex',FStream.ReadDword());
        Log('boneIndex'   ,FStream.ReadWord ());
        Log('weight'      ,FStream.ReadFloat());
      end;

      M_SUBMESH_TEXTURE_ALIAS: begin
        Log('aliasName'  ,ReadText(FStream));
        Log('textureName',ReadText(FStream));
      end;

    else
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadMeshLodLevel;
var
  lchunk:TOgreChunk;
  i,j,lidx,lcnt:integer;
  l32,lmanual:boolean;
begin
  // NOT in 1.4
  if FVersion>=80 then
  begin
    Log('strategyName',ReadText(FStream)); //!!!! "string", not "* char"
  end;

  lcnt:=FStream.ReadWord();
  Log('numLevels',lcnt);

  // NOT in 1.9
  if FVersion<90 then
  begin
    lmanual:=FStream.ReadByte()<>0;
    Log('manual',lmanual);
  end;

  if FVersion>=100 then
  begin
    for i:=0 to lcnt-1 do
    begin
      Log('usageValue',FStream.ReadFloat());
      case ReadChunk(FStream,lchunk) of

        M_MESH_LOD_MANUAL: begin
          //readMeshLodUsageManual();
          Log('manualName',ReadText(FStream));
        end;

        M_MESH_LOD_GENERATED: begin
          //readMeshLodUsageGenerated();
//!!          for j:=0 to numSubs-1 do
          begin
            Log('numIndexes',FStream.ReadDWord());
            Log('offset'    ,FStream.ReadDWord());
            lidx:=integer(FStream.ReadDWord());
            Log('bufferIndex',lidx);
            if lidx=-1 then
            begin
              l32:=FStream.ReadByte()<>0;
              Log('idx32bit',l32);
              lidx:=FStream.ReadDWord();
              Log('buffIndexCount',lidx);

              if l32 then
                FStream.Seek(lidx*4,soFromCurrent)
              else
                FStream.Seek(lidx*2,soFromCurrent);
            end;
          end;
        end;

      else
        FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
        break;
      end;
    end;

    exit;
  end;
  
  for i:=0 to lcnt-1 do
  begin
    if ReadChunk(FStream,lchunk)=M_MESH_LOD_USAGE then
      break
    else
    begin
      Log('usageValue',FStream.ReadFloat());

      if lmanual then
      begin
        if ReadChunk(FStream,lchunk)<>M_MESH_LOD_MANUAL then
        begin
          FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
          break;
        end
        else
          Log('manualName',ReadText(FStream));
          //readMeshLodUsageManual();
      end
      else
      begin
        //readMeshLodUsageGenerated();

//!!        for j:=0 to numSubs-1 do
        begin
          if ReadChunk(FStream,lchunk)<>M_MESH_LOD_GENERATED then
          begin
            FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
            exit;
          end;

          lidx:=FStream.ReadDWord();
          Log('numIndexes',lidx);

          l32:=FStream.ReadByte()<>0;
          Log('idx32bit',l32);

          // unsigned short*/int* faceIndexes;  ((v1, v2, v3) * numFaces)
          if l32 then
            FStream.Seek(lidx*4,soFromCurrent)
          else
            FStream.Seek(lidx*2,soFromCurrent);
        end;
      end;
    end;
  end;
end;

procedure TRGMesh.ReadSubmeshNameTable;
var
  lchunk:TOgreChunk;
  lpos:integer;
begin
  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    if ReadChunk(FStream,lchunk)=M_SUBMESH_NAME_TABLE_ELEMENT then
    begin
      Log('index',FStream.ReadWord());
      Log('name' ,ReadText(FStream));
    end
    else
    begin
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadEdgeGroup;
var
  i,lnum:integer;
begin
  Log('vertexSet',FStream.ReadDword());
  // NOT 1.3 nvm, 1.3 is deprecated
  Log('triStart' ,FStream.ReadDword());
  // NOT 1.3 nvm, 1.3 is deprecated
  Log('triCount' ,FStream.ReadDword());

  lnum:=FStream.ReadDword();
  Log('numEdges' ,lnum);
  for i:=0 to lnum-1 do
  begin
    FStream.ReadDword(); // triIndex[2]
    FStream.ReadDword();
    FStream.ReadDword(); // vertIndex[2]
    FStream.ReadDword();
    FStream.ReadDword(); // shareVertIndex[2]
    FStream.ReadDword();
    FStream.ReadByte();  // degenerate
  end;
end;

procedure TRGMesh.readEdgeListLodInfo;
var
  lchunk:TOgreChunk;
  i,lnumt,lnume:integer;
begin
  // NOT 1.3 nvm, 1.3 is deprecated
  Log('isClosed',FStream.ReadByte()<>0);

  lnumt:=FStream.ReadDword();
  Log('numTriangles',lnumt);
  lnume:=FStream.ReadDword();
  Log('numEdgeGroups',lnume);

  for i:=0 to lnumt-1 do
  begin
    FStream.ReadDword(); // indexSet
    FStream.ReadDword(); // vertexSet
    FStream.ReadDword(); // vertIndex[3]
    FStream.ReadDword();
    FStream.ReadDword();
    FStream.ReadDword(); // sharedVertIndex[3]
    FStream.ReadDword();
    FStream.ReadDword();
    FStream.ReadFloat(); // normal[4]
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
  end;

  for i:=0 to lnume-1 do
  begin
    if ReadChunk(FStream,lchunk)=M_EDGE_GROUP then
    begin
      ReadEdgeGroup();
    end
    else
    begin
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;
  end;
end;

procedure TRGMesh.ReadEdgeListLod;
var
  lmanual:boolean;
begin
  Log('lodIndex',FStream.ReadWord());
  lmanual:=FStream.ReadByte()<>0;
  Log('isManual',lmanual);
  if not lmanual then
  begin
    readEdgeListLodInfo();
  end;
end;

procedure TRGMesh.ReadEdgeLists;
var
  lchunk:TOgreChunk;
  lpos:integer;
begin
  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    if ReadChunk(FStream,lchunk)=M_EDGE_LIST_LOD then
      ReadEdgeListLod()
    else
    begin
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadPose;
var
  lchunk:TOgreChunk;
  lpos:integer;
  lnormals:boolean;
begin
  Log('name'  ,ReadText(FStream));
  Log('target',FStream.ReadWord());

  if FVersion<80 then
    lnormals:=false
  else
  begin
    lnormals:=FStream.ReadByte()<>0;
    Writeln('includeNormals ',lnormals);
  end;

  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;
    
    if ReadChunk(FStream,lchunk)=M_POSE_VERTEX then
    begin
      Log('vertexIndex',FStream.ReadDWord());
      Log('xoffset'    ,FStream.ReadFloat());
      Log('yoffset'    ,FStream.ReadFloat());
      Log('zoffset'    ,FStream.ReadFloat());

      if lnormals then
      begin
        Log('xnormal',FStream.ReadFloat());
        Log('ynormal',FStream.ReadFloat());
        Log('znormal',FStream.ReadFloat());
      end;
    end
    else
    begin
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadPoses;
var
  lchunk:TOgreChunk;
  lpos:integer;
begin
  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    if ReadChunk(FStream,lchunk)=M_POSE then
    begin
      ReadPose();
    end
    else
    begin
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadAnimationPoseKeyFrame;
var
  lchunk:TOgreChunk;
  lpos:integer;
begin
  Log('time',FStream.ReadFloat());
  // repeat for number of referenced poses
  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    case ReadChunk(FStream,lchunk) of

       M_ANIMATION_POSE_REF: begin
         Log('poseIndex',FStream.ReadWord());
         Log('influence',FStream.ReadFloat());
       end;
    
    else
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadAnimationMorphKeyFrame;
var
  lnormals:boolean;
  i:integer;
begin
  Log('time',FStream.ReadFloat());

  if FVersion<80 then
    lnormals:=false
  else
  begin
    lnormals:=FStream.ReadByte()<>0;
    Log('includesNormals',lnormals);
  end;

  for i:=0 to FVertexCount-1 do
  begin
    Log('x',FStream.ReadFloat());
    Log('y',FStream.ReadFloat());
    Log('z',FStream.ReadFloat());
    if lnormals then
    begin
      Log('normalx',FStream.ReadFloat());
      Log('normaly',FStream.ReadFloat());
      Log('normalz',FStream.ReadFloat());
    end;
  end;

end;

procedure TRGMesh.ReadAnimationTrack;
var
  lchunk:TOgreChunk;
  lpos:integer;
begin
  Log('type'  ,FStream.ReadWord());
  Log('target',FStream.ReadWord());

  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    case ReadChunk(FStream,lchunk) of

      M_ANIMATION_MORPH_KEYFRAME:
        ReadAnimationMorphKeyFrame();
      
      M_ANIMATION_POSE_KEYFRAME:
        ReadAnimationPoseKeyFrame();
    
    else
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadAnimation;
var
  lchunk:TOgreChunk;
begin
  Log('name'  ,ReadText(FStream));
  Log('length',FStream.ReadFloat());

  if ReadChunk(FStream,lchunk)=M_ANIMATION_BASEINFO then
  begin
    Log('baseAnimationName',ReadText(FStream));
    Log('baseKeyFrameTime' ,FStream.ReadFloat());

    ReadChunk(FStream,lchunk);
  end;

  while not FStream.Eof() do
  begin
    if lchunk._type=M_ANIMATION_TRACK then
    begin
      ReadAnimationTrack();
    end
    else
    begin
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    ReadChunk(FStream,lchunk);
  end;

end;

procedure TRGMesh.ReadAnimations;
var
  lchunk:TOgreChunk;
  lpos:integer;
begin
  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    if ReadChunk(FStream,lchunk)=M_ANIMATION then
      ReadAnimation()
    else
    begin
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
    FStream.Position:=lpos+lchunk._len;
  end;
end;

procedure TRGMesh.ReadMesh;
var
  lchunk:TOgreChunk;
  lpos:int64;
  i,lcnt:integer;
begin
  Log('skeletallyAnimated',FStream.ReadByte()<>0);

  while not FStream.Eof() do
  begin
    lpos:=FStream.Position;

    case ReadChunk(FStream,lchunk) of

      M_GEOMETRY: begin
        ReadGeometry();
      end;

      M_SUBMESH: begin
        ReadSubMesh();
      end;

      M_MESH_SKELETON_LINK: begin
        Log('skeletonName',ReadText(FStream));
      end;

      M_MESH_BONE_ASSIGNMENT: begin
        Log('vertextIndex',FStream.ReadDword());
        Log('boneIndex'   ,FStream.ReadWord ());
        Log('weight'      ,FStream.ReadFloat());
      end;

      M_MESH_LOD_LEVEL: begin
        ReadMeshLodLevel();
      end;

      M_MESH_BOUNDS: begin
        Log('minx'  ,FStream.ReadFloat());
        Log('miny'  ,FStream.ReadFloat());
        Log('minz'  ,FStream.ReadFloat());
        Log('maxx'  ,FStream.ReadFloat());
        Log('maxy'  ,FStream.ReadFloat());
        Log('maxz'  ,FStream.ReadFloat());
        Log('radius',FStream.ReadFloat());
      end;

      M_SUBMESH_NAME_TABLE: begin
        ReadSubmeshNameTable();
      end;

      M_EDGE_LISTS: begin
        ReadEdgeLists();
      end;

      M_POSES: begin
        ReadPoses();
      end;

      M_ANIMATIONS: begin
        ReadAnimations();
      end;

      M_TABLE_EXTREMES: begin
        Log('submesh_index',FStream.ReadWord());

        lcnt:=(lchunk._len-SizeOf(lchunk)-SizeOf(word)) div (SizeOf(single)*3);
        for i:=0 to lcnt-1 do
        begin
          Log('extremes ['+IntToStr(i)+'][0]',FStream.ReadFloat());
          Log('extremes ['+IntToStr(i)+'][1]',FStream.ReadFloat());
          Log('extremes ['+IntToStr(i)+'][2]',FStream.ReadFloat());
        end;
      end;

    else
      FStream.Seek(-SizeOf(TOgreChunk),soFromCurrent);
      break;
    end;

    if (FStream.Position)<>(lpos+lchunk._len) then
       Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
//    FStream.Position:=lpos+lchunk._len;
  end;
end;

function TRGMesh.ReadMeshFile:boolean;
var
  lchunk:TOgreChunk;
  pc:AnsiString;
begin
  result:=false;

  // Header. No chunk size field
  lchunk._type:=FStream.ReadWord();
  if lchunk._type=M_HEADER then
  begin
    pc:=ReadText(FStream);
    FVersion:=TranslateVersion(pc);
    if FVersion<40 then
    begin
      Log('version',pc+' not supprted');
      exit;
    end
    else
      Log('version',pc);
  end
  else
    exit;

  while not FStream.Eof() do
  begin

    // chunk size can be wrong
    case ReadChunk(FStream,lchunk) of
      M_MESH: ReadMesh;
    else
      break;
    end;

  end;

  Log('offset',HexStr(FStream.Position,8));
  result:=true;
end;

procedure TRGMesh.LoadFromFile(fname:PAnsiChar);
begin
  if FStream<>nil then
  begin
    Clear;
    FStream.Free;
  end;

  FStream:=TMemoryStream.Create;
  TMemoryStream(FStream).LoadFromFile(fname);

  ReadMeshFile();

  FStream.Free;
  FStream:=nil;
end;


procedure TRGMesh.Init;
begin
  FStream:=nil;
end;

procedure TRGMesh.Free;
begin
  FStream.Free;
  FStream:=nil;

  Clear;
end;

procedure TRGMesh.Clear;
begin
end;


procedure Trace(const fname:AnsiString);
var
  lmesh:TRGMesh;
begin
  lmesh.Init;
  lmesh.LoadFromFile(PAnsiChar(fname));
  lmesh.Free;

  RGLog.SaveToFile(ParamStr(1)+'.log');
end;

end.
