unit RGMesh;

interface

uses
  typinfo,
  Classes;

{$I rg3d.Ogre.inc}

type
  TRGMesh = object
  public
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


procedure LogLn;
procedure Log(const astr:string; const aval:string);
procedure Log(const astr:string; aval:single);
procedure Log(const astr:string; aval:boolean);
procedure Log(const astr:string; aval:int64);

function TranslateVersion(const sign:AnsiString):integer;

function ReadText(astream:TStream):string;

function ReadChunk(astream:TStream; var achunk:TOgreChunk):word;
function GetChunkName(aid:word):string;


implementation

uses
  SysUtils,
  rgglobal,
  rgstream;


{%REGION Support}
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
var
  ls:string;
begin
  achunk._type:=astream.ReadWord ();
  achunk._len :=astream.ReadDWord();
  result:=achunk._type;

  ls:='Chunk type: 0x'+HexStr(achunk._type,4)+' '+GetChunkName(achunk._type)+
          '; length=0x'   +HexStr(achunk._len ,4)+' ('+IntToStr(achunk._len)+
          '); offset=0x'  +HexStr(astream.Position-SizeOf(achunk),8);

  if (achunk._type=M_MESH_BONE_ASSIGNMENT) or
     (achunk._type=M_SUBMESH_BONE_ASSIGNMENT) then
  begin
    if StrLComp(PAnsiChar(RGLog.Last),PAnsiChar(ls),18)<>0 then
      RGLog.Add(ls);
  end
  else if StrLComp(PAnsiChar(RGLog.Last),PAnsiChar(ls),Length(ls))<>0 then
    RGLog.Add(ls);
end;
{%ENDREGION Support}

procedure TRGMesh.ReadGeometryVertexElement;
var
  lvalue:integer;
begin
  Log('source'  ,FStream.ReadWord());
  lvalue:=FStream.ReadWord();
  Log('type'    ,{lvalue); //} GetEnumName(TypeInfo(TVertexElementType    ),lvalue));
  lvalue:=FStream.ReadWord();
  Log('semantic',{lvalue); //} GetEnumName(TypeInfo(TVertexElementSemantic),lvalue));
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
  FVertexCount:=FStream.ReadDWord();
  Log('vertexCount',FVertexCount);

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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
        i:=FStream.ReadWord();
//        Log('operationType',WriteStr(TOperationType(i)));
        Log('operationType',GetEnumName(TypeInfo(TOperationType),i));
      end;

      M_SUBMESH_BONE_ASSIGNMENT: begin
        FStream.Seek(10,soFromCurrent);
{
        Log('VertextIndex',FStream.ReadDword());
        Log('boneIndex'   ,FStream.ReadWord ());
        Log('weight'      ,FStream.ReadFloat());
}
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
      FStream.Position:=lpos+lchunk._len;
    end;
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
        FStream.Seek(10,soFromCurrent);
{
        Log('vertextIndex',FStream.ReadDword());
        Log('boneIndex'   ,FStream.ReadWord ());
        Log('weight'      ,FStream.ReadFloat());
}
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
    begin
      Log('!!!Warning',HexStr(FStream.Position,8)+' is not '+HexStr(lpos+lchunk._len,8));
//      FStream.Position:=lpos+lchunk._len;
    end;
  end;
end;

function TRGMesh.ReadMeshFile:boolean;
var
  lchunk:TOgreChunk;
  ls:AnsiString;
  i,lcnt,ltype:integer;
begin
  result:=false;

  // Header. No chunk size field
  lchunk._type:=FStream.ReadWord();
  if lchunk._type=M_HEADER then
  begin
    ls:=ReadText(FStream);
    FVersion:=TranslateVersion(ls);
    if (FVersion<40) or (FVersion=99) then
    begin
      Log('version',ls+' not supported');
      exit;
    end
    else
      Log('version',ls);
  end
  else
    exit;

  //===== Hob =====

  if FVersion in [90,91] then
  begin
//    if FStream.ReadWord()=0002 then
    Log('format version? w[0] (2) or 1',FStream.ReadWord());
    Log('w [1] (9)',FStream.ReadWord());
    Log('w [2] (1)',FStream.ReadWord());
    Log('b (0)'    ,FStream.ReadByte());

    Log('w (1)',FStream.ReadWord()); // 0001

    // base textures
    lcnt:=FStream.ReadWord();
    for i:=0 to lcnt-1 do
    begin
      ls:=ReadText(FStream);
      Log(ls,ReadText(FStream));
    end;

    Log('w (1)',FStream.ReadWord()); //0001
    Log('checksum?',HexStr(FStream.ReadDWord(),8));

    ls:=ReadText(FStream);
    Log(ls+' (size of next data, mat+consts)',HexStr(FStream.ReadDWord(),8));

    ls:=ReadText(FStream);       // material/pass name
    Log(ls,FStream.ReadDWord()); // number?

    lcnt:=FStream.ReadDWord();

    for i:=0 to lcnt-1 do
    begin
      ltype:=FStream.ReadDWord();
      case ltype of
        1: begin
          ls:=ReadText(FStream);
          Log('{'+IntToStr(i)+'} '+ls,FStream.ReadDWord());
        end;
        2: begin
          ls:=ReadText(FStream);
          Log('{'+IntToStr(i)+'} '+ls,FStream.ReadFloat());
        end;
        3: begin
          Log('{'+IntToStr(i)+'} '+ReadText(FStream),'4x float');
          Log('  [0]',FStream.ReadFloat());
          Log('  [1]',FStream.ReadFloat());
          Log('  [2]',FStream.ReadFloat());
          Log('  [3]',FStream.ReadFloat());
        end;
        4: Log('{'+IntToStr(i)+'} type',ltype);
      else
        Log('{'+IntToStr(i)+'} Unknown const type',ltype);
      end;
    end;
  end;

{
  Source gives cycle
  documentation gives single mesh
}
//  while not FStream.Eof() do
  begin

    // chunk size can be wrong
    case ReadChunk(FStream,lchunk) of
      M_MESH: ReadMesh;
    else
//      break;
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

end.
