{}

procedure TRGMesh.ReadVertexDeclaration(asub:PRGSubMesh; var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
  i:integer;
begin
  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    if ReadChunk(aptr,lchunk)=M_GEOMETRY_VERTEX_ELEMENT then
    begin
      i:=asub^.FVEList.Add(aptr);
      if i>=0 then
      begin
        if rgDebugLevel=dlDetailed then LogVE(i,asub^.FVEList[i]^);
{
        with asub^.FVEList[i]^ do
        begin
          Log('source  ',source);
          Log('type    ',GetVETName(_type));
          Log('semantic',GetVESName(semantic));
          Log('offset  ',offset);
          Log('index   ',index);
        end;
}
      end;
    end
    else
    begin
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;

procedure TRGMesh.ReadGeometry(asub:PRGSubMesh; var aptr:PByte);
var
  lchunk,lchunk1:TOgreChunk;
  lpos{,lbufpos}:PByte;
  lsize,lindex:integer;
begin
  asub^.VertexCount:=memReadDWord(aptr);
  Log('vertexCount',asub^.VertexCount);

  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    case ReadChunk(aptr,lchunk) of

      M_GEOMETRY_VERTEX_DECLARATION: begin
        ReadVertexDeclaration(asub, aptr);
      end;

      M_GEOMETRY_VERTEX_BUFFER: begin
        lindex:=memReadWord(aptr);
        lsize :=memReadWord(aptr);
        Log('bindIndex' ,lindex);
        Log('vertexSize',lsize);

        if ReadChunk(aptr,lchunk1)=M_GEOMETRY_VERTEX_BUFFER_DATA then
        begin
//          lbufpos:=aptr;
          asub^.FVEList.BindBuffer(aptr,lindex,lsize,asub^.FVertexCount);
//          aptr:=lbufpos+asub^.FVertexCount*lsize;
        end;// skip VertexCount*VertexSize
      end;

    else
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;

procedure TRGMesh.ReadSubMesh(asub:PRGSubMesh; var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos,lFacePtr:PByte;
  ls:string;
  i,lcnt:integer;
  lbone,lvertex:integer;
  lweight:single;
begin
  ls:=memReadText(aptr);
  asub^.FMaterial:=AddMaterial(ls);
  Log('materialName',ls);

  asub^.FUseSharedVertices:=memReadByte(aptr)<>0;
  Log('useSharedVertices',asub^.FUseSharedVertices);

  lcnt:=memReadDWord(aptr);
  asub^.FFaceCount:=lcnt;
  asub^.Is32bit   :=memReadByte(aptr)<>0;
  Log('indexCount'  ,lcnt);
  Log('indexes32Bit',asub^.Is32bit);

  // Faces
  lFacePtr:=aptr;
  if asub^.Is32bit then
    inc(aptr,lcnt*4)
  else
    inc(aptr,lcnt*2);

  // process later

  if not asub^.FUseSharedVertices then
  begin
    lpos:=aptr;

    if ReadChunk(aptr,lchunk)=M_GEOMETRY then
    begin
      ReadGeometry(asub,aptr);
      aptr:=lpos+lchunk._len;
    end
    else // exception in original sources
      aptr:=lpos;
  end;

  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    case ReadChunk(aptr,lchunk) of

      M_SUBMESH_OPERATION: begin
        asub^.FOperationType:=memReadWord(aptr);
        Log('operationType',OTData[asub^.FOperationType].name);
      end;

      M_SUBMESH_BONE_ASSIGNMENT: begin
        lvertex:=memReadDWord(aptr);
        lbone  :=memReadWord (aptr);
        lweight:=memReadFloat(aptr);
        {
        Log('vertextIndex',lvertex);
        Log('boneIndex'   ,lbone);
        Log('weight'      ,lweight);
        }
        asub^.AddBone(lvertex, lbone, lweight);
      end;

      M_SUBMESH_TEXTURE_ALIAS: begin
        Log('aliasName'  ,memReadText(aptr));
        Log('textureName',memReadText(aptr));
      end;

    else
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;

  // Process Faces here

  if asub^.FOperationType=OT_TRIANGLE_LIST then
  begin
    asub^.FFaceCount:=asub^.FFaceCount div 3;

    GetMem(asub^.FFaces,asub^.FFaceCount*SizeOf(TIntVector3));

    if asub^.Is32bit then
    begin
      for i:=0 to asub^.FFaceCount-1 do
      begin
        // reverse order
        with PIntVector3(asub^.FFaces)[i] do
        begin
          Z:=PDword(lFacePtr)[i*3  ]; // PIntVector3(aptr)[j].Z;
          Y:=PDword(lFacePtr)[i*3+1]; // PIntVector3(aptr)[j].Y;
          X:=PDword(lFacePtr)[i*3+2]; // PIntVector3(aptr)[j].X;
        end;
      end;
    end
    else
    begin
      for i:=0 to asub^.FFaceCount-1 do
      begin
        with PIntVector3(asub^.FFaces)[i] do
        begin
          X:=Pword(lFacePtr)[i*3  ]; // PIntVector3(aptr)[j].X;
          Y:=Pword(lFacePtr)[i*3+1]; // PIntVector3(aptr)[j].Y;
          Z:=Pword(lFacePtr)[i*3+2]; // PIntVector3(aptr)[j].Z;
        end;
      end;
    end;
  end;
  
end;

procedure TRGMesh.ReadMeshLodLevel(var aptr:PByte);
var
  lchunk:TOgreChunk;
  i{,j},lidx,lcnt:integer;
  l32,lmanual:boolean;
begin
  // NOT in 1.4
  if FVersion>=80 then
  begin
    Log('strategyName',memReadText(aptr)); //!!!! "string", not "* char"
  end;

  lcnt:=memReadWord(aptr);
  Log('numLevels',lcnt);

  // NOT in 1.9
  if FVersion<90 then
  begin
    lmanual:=memReadByte(aptr)<>0;
    Log('manual',lmanual);
  end;

  if FVersion>=100 then
  begin
    for i:=0 to lcnt-1 do
    begin
      Log('usageValue',memReadFloat(aptr));
      case ReadChunk(aptr,lchunk) of

        M_MESH_LOD_MANUAL: begin
          //readMeshLodUsageManual();
          Log('manualName',memReadText(aptr));
        end;

        M_MESH_LOD_GENERATED: begin
          //readMeshLodUsageGenerated();
//!!          for j:=0 to numSubs-1 do
          begin
            Log('numIndexes',memReadDWord(aptr));
            Log('offset'    ,memReadDWord(aptr));
            lidx:=integer(memReadDWord(aptr));
            Log('bufferIndex',lidx);
            if lidx=-1 then
            begin
              l32:=memReadByte(aptr)<>0;
              Log('idx32bit',l32);
              lidx:=memReadDWord(aptr);
              Log('buffIndexCount',lidx);

              if l32 then
                inc(aptr,lidx*4)
              else
                inc(aptr,lidx*2);
            end;
          end;
        end;

      else
        dec(aptr,SizeOf(TOgreChunk));
        break;
      end;
    end;

    exit;
  end;
  
  for i:=0 to lcnt-1 do
  begin
    if ReadChunk(aptr,lchunk)=M_MESH_LOD_USAGE then
      break
    else
    begin
      Log('usageValue',memReadFloat(aptr));

      if lmanual then
      begin
        if ReadChunk(aptr,lchunk)<>M_MESH_LOD_MANUAL then
        begin
          dec(aptr,SizeOf(TOgreChunk));
          break;
        end
        else
          Log('manualName',memReadText(aptr));
          //readMeshLodUsageManual();
      end
      else
      begin
        //readMeshLodUsageGenerated();

//!!        for j:=0 to numSubs-1 do
        begin
          if ReadChunk(aptr,lchunk)<>M_MESH_LOD_GENERATED then
          begin
            dec(aptr,SizeOf(TOgreChunk));
            exit;
          end;

          lidx:=memReadDWord(aptr);
          Log('numIndexes',lidx);

          l32:=memReadByte(aptr)<>0;
          Log('idx32bit',l32);

          // unsigned short*/int* faceIndexes;  ((v1, v2, v3) * numFaces)
          if l32 then
            inc(aptr,lidx*4)
          else
            inc(aptr,lidx*2);
        end;
      end;
    end;
  end;
end;
(*
procedure TRGMesh.ReadEdgeListLodInfo(var aptr:PByte);
var
  lchunk:TOgreChunk;
  i,j,lnumt,lnumeg,lnume:integer;
begin
  // NOT 1.3 nvm, 1.3 is deprecated
  Log('isClosed',memReadByte(aptr)<>0);

  lnumt :=memReadDWord(aptr);
  lnumeg:=memReadDWord(aptr);
  Log('numTriangles' ,lnumt);
  Log('numEdgeGroups',lnumeg);

  inc(aptr,lnumt*12*4);
{
  for i:=0 to lnumt-1 do
  begin
    memReadDWord(aptr); // indexSet
    memReadDWord(aptr); // vertexSet
    memReadDWord(aptr); // vertIndex[3]
    memReadDWord(aptr);
    memReadDWord(aptr);
    memReadDWord(aptr); // sharedVertIndex[3]
    memReadDWord(aptr);
    memReadDWord(aptr);
    memReadFloat(aptr); // normal[4]
    memReadFloat(aptr);
    memReadFloat(aptr);
    memReadFloat(aptr);
  end;
}
  for i:=0 to lnumeg-1 do
  begin
    if ReadChunk(aptr,lchunk)=M_EDGE_GROUP then
    begin
      Log('vertexSet',memReadDWord(aptr));
      // NOT 1.3 nvm, 1.3 is deprecated
      Log('triStart' ,memReadDWord(aptr));
      // NOT 1.3 nvm, 1.3 is deprecated
      Log('triCount' ,memReadDWord(aptr));

      lnume:=memReadDWord(aptr);
      Log('numEdges' ,lnume);
      inc(aptr,lnume*(6*4+1));
    {
      for i:=0 to lnume-1 do
      begin
        memReadDWord(aptr); // triIndex[2]
        memReadDWord(aptr);
        memReadDWord(aptr); // vertIndex[2]
        memReadDWord(aptr);
        memReadDWord(aptr); // shareVertIndex[2]
        memReadDWord(aptr);
        memReadByte (aptr); // degenerate
      end;
    }
    end
    else
    begin
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;
  end;
end;
*)
procedure TRGMesh.ReadEdgeListLod(var aptr:PByte);
var
  lmanual:boolean;
begin
  Log('lodIndex',memReadWord(aptr));
  lmanual:=memReadByte(aptr)<>0;
  Log('isManual',lmanual);
  if not lmanual then
  begin
//    readEdgeListLodInfo(aptr);
  end;
end;

procedure TRGMesh.ReadEdgeLists(var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
begin
  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    if ReadChunk(aptr,lchunk)=M_EDGE_LIST_LOD then
      ReadEdgeListLod(aptr)
    else
    begin
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;
(*
procedure TRGMesh.ReadPose(var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
  lnormals:boolean;
begin
  Log('name'  ,memReadText(aptr));
  Log('target',memReadWord(aptr));

  if FVersion<80 then
    lnormals:=false
  else
  begin
    lnormals:=memReadByte(aptr)<>0;
    Writeln('includeNormals ',lnormals);
  end;

  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;
    
    if ReadChunk(aptr,lchunk)=M_POSE_VERTEX then
    begin
      Log('vertexIndex',memReadDWord(aptr));
      Log('xoffset'    ,memReadFloat(aptr));
      Log('yoffset'    ,memReadFloat(aptr));
      Log('zoffset'    ,memReadFloat(aptr));

      if lnormals then
      begin
        Log('xnormal',memReadFloat(aptr));
        Log('ynormal',memReadFloat(aptr));
        Log('znormal',memReadFloat(aptr));
      end;
    end
    else
    begin
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;
*)
procedure TRGMesh.ReadPoses(var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
begin
  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    if ReadChunk(aptr,lchunk)=M_POSE then
    begin
//      ReadPose(aptr);
    end
    else
    begin
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;

(*
procedure TRGMesh.ReadAnimationPoseKeyFrame(var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
begin
  Log('time',memReadFloat(aptr));
  // repeat for number of referenced poses
  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    case ReadChunk(aptr,lchunk) of

       M_ANIMATION_POSE_REF: begin
         Log('poseIndex',memReadWord(aptr));
         Log('influence',memReadFloat(aptr));
       end;
    
    else
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;
*)
(*
procedure TRGMesh.ReadAnimationMorphKeyFrame(var aptr:PByte);
var
  lnormals:boolean;
  i:integer;
begin
  Log('time',memReadFloat(aptr));

  if FVersion<80 then
    lnormals:=false
  else
  begin
    lnormals:=memReadByte(aptr)<>0;
    Log('includesNormals',lnormals);
  end;

  for i:=0 to FVertexCount-1 do
  begin
    Log('x',memReadFloat(aptr));
    Log('y',memReadFloat(aptr));
    Log('z',memReadFloat(aptr));
    if lnormals then
    begin
      Log('normalx',memReadFloat(aptr));
      Log('normaly',memReadFloat(aptr));
      Log('normalz',memReadFloat(aptr));
    end;
  end;

end;
*)

procedure TRGMesh.ReadAnimationTrack(var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
begin
  Log('type'  ,memReadWord(aptr));
  Log('target',memReadWord(aptr));

  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    case ReadChunk(aptr,lchunk) of

      M_ANIMATION_MORPH_KEYFRAME:
;//        ReadAnimationMorphKeyFrame(aptr);
      
      M_ANIMATION_POSE_KEYFRAME:
;//        ReadAnimationPoseKeyFrame(aptr);
    
    else
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;

procedure TRGMesh.ReadAnimation(var aptr:PByte);
var
  lchunk:TOgreChunk;
begin
  Log('name'  ,memReadText(aptr));
  Log('length',memReadFloat(aptr));

  if ReadChunk(aptr,lchunk)=M_ANIMATION_BASEINFO then
  begin
    Log('baseAnimationName',memReadText(aptr));
    Log('baseKeyFrameTime' ,memReadFloat(aptr));

    ReadChunk(aptr,lchunk);
  end;

  while aptr<(FBuffer+FDataSize) do
  begin
    if lchunk._type=M_ANIMATION_TRACK then
    begin
      ReadAnimationTrack(aptr);
    end
    else
    begin
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    ReadChunk(aptr,lchunk);
  end;

end;

procedure TRGMesh.ReadAnimations(var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
begin
  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    if ReadChunk(aptr,lchunk)=M_ANIMATION then
      ReadAnimation(aptr)
    else
    begin
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;

procedure TRGMesh.ReadSubmeshNameTable(var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
begin
  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    if ReadChunk(aptr,lchunk)=M_SUBMESH_NAME_TABLE_ELEMENT then
    begin
      Log('index',memReadWord(aptr));
      Log('name' ,memReadText(aptr));
    end
    else
    begin
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
      aptr:=lpos+lchunk._len;
    end;
  end;
end;

function TRGMesh.ReadMesh(var aptr:PByte):boolean;
var
  lchunk:TOgreChunk;
  lpos:PByte;
  i,lcnt:integer;
  lbone,lvertex:integer;
  lweight:single;
begin
  result:=false;

//  if ReadChunk(aptr,lchunk)<>M_MESH then exit;

  Log('skeletallyAnimated',memReadByte(aptr)<>0);

  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    case ReadChunk(aptr,lchunk) of

      M_GEOMETRY: begin
        ReadGeometry(SubMesh[0],aptr);
      end;

      M_SUBMESH: begin
        ReadSubMesh(AddSubMesh(),aptr);
      end;

      M_MESH_SKELETON_LINK: begin
        Skeleton:=memReadText(aptr);
        Log('skeletonName',Skeleton);
      end;

      M_MESH_BONE_ASSIGNMENT: begin
        lvertex:=memReadDWord(aptr);
        lbone  :=memReadWord (aptr);
        lweight:=memReadFloat(aptr);
        {
        Log('vertextIndex',lvertex);
        Log('boneIndex'   ,lbone);  
        Log('weight'      ,lweight);
        }

        SubMesh[0]^.AddBone(lvertex, lbone, lweight);
      end;

      M_MESH_BOUNDS: begin
        memRead(aptr,BoundMin,SizeOf(TVector3));
        memRead(aptr,BoundMax,SizeOf(TVector3));
        BoundRadius:=memReadFloat(aptr);
      end;

      M_MESH_LOD_LEVEL: begin
        ReadMeshLodLevel(aptr);
      end;

      M_SUBMESH_NAME_TABLE: begin
        ReadSubmeshNameTable(aptr);
      end;

      M_EDGE_LISTS: begin
        ReadEdgeLists(aptr);
      end;

      M_POSES: begin
        ReadPoses(aptr);
      end;

      M_ANIMATIONS: begin
        ReadAnimations(aptr);
      end;

      M_TABLE_EXTREMES: begin
        Log('submesh_index',memReadWord(aptr));

        lcnt:=(lchunk._len-SizeOf(lchunk)-SizeOf(word)) div (SizeOf(single)*3);
        for i:=0 to lcnt-1 do
        begin
          Log('extremes ['+IntToStr(i)+'][0]',memReadFloat(aptr));
          Log('extremes ['+IntToStr(i)+'][1]',memReadFloat(aptr));
          Log('extremes ['+IntToStr(i)+'][2]',memReadFloat(aptr));
        end;
      end;

    else
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;

    if aptr<>(lpos+lchunk._len) then
    begin
      Log('!!!Warning',HexStr(aptr-FBuffer,8)+' is not '+HexStr((lpos-FBuffer)+lchunk._len,8));
//      aptr:=lpos+lchunk._len;
    end;
  end;
  result:=true;
end;
