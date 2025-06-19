{}

{$IFDEF Interface}

{$ELSE}

function WriteChunk(astream:TStream; achunk:integer; asize:integer=0):integer;
begin
  astream.WriteWord(achunk); // chunk code
  result:=astream.Position;  // position of chunk size
  astream.WriteDWord(asize+SizeOf(TOgreChunk)); // reserve for chunk size if needs
end;

procedure WriteMeshGeometry(astream:TStream; amesh:PRGSubMesh);
var
  p:PByte;
  ve:TVertexElement;
  lcnt,i,lp,lp1,lpos:integer;
begin
  lpos:=WriteChunk(astream,M_GEOMETRY);
  astream.WriteDWord(amesh^.FVertexCount);

  lp:=WriteChunk(astream,M_GEOMETRY_VERTEX_DECLARATION);
  lcnt:=0;
  for i:=0 to amesh^.FVEList.Count-1 do
  begin
    p:=amesh^.FVEList.Buffer[i];
    if p<>nil then
    begin
      WriteChunk(astream,M_GEOMETRY_VERTEX_ELEMENT,SizeOf(TVertexElement));
      ve:=amesh^.FVEList[i]^;
      ve.offset:=0;
      ve.source:=lcnt;
      ve.index :=0;
      astream.Write(ve,SizeOf(TVertexElement));
      inc(lcnt);
{
      with amesh^.FVEList[i] do
      begin
        // unsigned short source;   // buffer bind source
        // unsigned short type;     // VertexElementType
        // unsigned short semantic; // VertexElementSemantic
        // unsigned short offset;   // start offset in buffer in bytes
        // unsigned short index;    // index of the semantic (for colours and texture coords)
      end;
}
    end;
  end;
  astream.WriteDWordAt(astream.Position-lp+2,lp);
//  astream.WriteSizeAt(lp);

  lcnt:=0;
  for i:=0 to amesh^.FVEList.Count-1 do
  begin
    p:=amesh^.FVEList.Buffer[i];
    if p<>nil then
    begin
      lp:=WriteChunk(astream,M_GEOMETRY_VERTEX_BUFFER);
      astream.WriteWord(lcnt); // Index to bind this buffer to
      astream.WriteWord(amesh^.FVEList.Size[i]);     // Per-vertex size, must agree with declaration at this index
      lp1:=WriteChunk(astream,M_GEOMETRY_VERTEX_BUFFER_DATA);
      astream.Write(amesh^.FVEList.Buffer[i]^,
                    amesh^.FVEList.Size  [i]*amesh^.FVertexCount); // raw buffer data

      inc(lcnt);
      astream.WriteDWordAt(astream.Position-lp1+2,lp1);
//      astream.WriteSizeAt(lp1);
      astream.WriteDWordAt(astream.Position-lp+2,lp);
//      astream.WriteSizeAt(lp);
    end;
  end;

  astream.WriteDWordAt(astream.Position-lpos+2,lpos);
//  astream.WriteSizeAt(lpos);
end;

procedure TRGMesh.WriteMesh(astream:TStream; aver:integer);
var
  lsm:PRGSubMesh;
  i,j,lpos,lp:integer;
  b:boolean;
begin
  astream.WriteWord(M_HEADER);
  WriteText(astream,GetVersionText(aver));
  lpos:=WriteChunk(astream,M_MESH);
  astream.WriteByte(ORD(Skeleton<>''));

  if FSubMeshes[0]^.VertexCount>0 then
    WriteMeshGeometry(astream,FSubMeshes[0]);

  for i:=1 to SubMeshCount do
  begin
    lsm:=FSubMeshes[i];
    lp:=WriteChunk(astream,M_SUBMESH);
    WriteText(astream,FMaterials[lsm^.FMaterial].Name);
    astream.WriteByte(ORD(lsm^.FVertexCount=0));
    astream.WriteDWord(lsm^.FFaceCount*3);
    astream.WriteByte(ORD(lsm^.FFaceCount>=65526));
    if lsm^.FFaceCount>=65526 then // treat as is32bit
    begin
      for j:=0 to lsm^.FFaceCount-1 do
      begin
        with PIntVector3(lsm^.FFaces)[j] do
        begin
          astream.WriteDWord(X);
          astream.WriteDWord(Y);
          astream.WriteDWord(Z);
        end;
      end;
    end
    else
    begin
      for j:=0 to lsm^.FFaceCount-1 do
      begin
        with PIntVector3(lsm^.FFaces)[j] do
        begin
          astream.WriteWord(X);
          astream.WriteWord(Y);
          astream.WriteWord(Z);
        end;
      end;
    end;
    
    if lsm^.FVertexCount>0 then
    begin
      WriteMeshGeometry(astream,lsm);
    end;

    for j:=0 to lsm^.FBoneAssignCount-1 do
    begin
      WriteChunk(astream,M_SUBMESH_BONE_ASSIGNMENT,10);
      with lsm^.FBones[j] do
      begin
        astream.WriteDWord(vertexIndex);
        astream.WriteWord (boneIndex);
        astream.WriteFloat(weight);
      end;
    end;

    astream.WriteDWordAt(astream.Position-lp+2,lp);
//    astream.WriteSizeAt(lp);
  end;

  if Skeleton>'' then
  begin
    WriteChunk(astream,M_MESH_SKELETON_LINK,Length(Skeleton)+1);
    WriteText (astream,Skeleton);
  end;

  for i:=0 to FSubMeshes[0]^.FBoneAssignCount-1 do
  begin
    WriteChunk(astream,M_MESH_BONE_ASSIGNMENT,10);
    with FSubMeshes[0]^.FBones[i] do
    begin
      astream.WriteDWord(vertexIndex);
      astream.WriteWord (boneIndex);
      astream.WriteFloat(weight);
    end;
  end;

  lp:=WriteChunk(astream,M_MESH_BOUNDS,2*SizeOf(TVector3)+SizeOf(single));
  astream.Write(BoundMin,SizeOf(TVector3));
  astream.Write(BoundMax,SizeOf(TVector3));
  astream.WriteFloat(BoundRadius);

  b:=false;
  for i:=1 to SubMeshCount do
  begin
    if FSubMeshes[i]^.Name<>'' then
    begin
      b:=true;
      break;
    end;
  end;
  if b then
  begin
    lp:=WriteChunk(astream,M_SUBMESH_NAME_TABLE);

    for i:=1 to SubMeshCount do
    begin
      if FSubMeshes[i]^.Name<>'' then
      begin
        astream.WriteWord(i-1);
        WriteText(astream,FSubMeshes[i]^.Name);
      end;
    end;

    astream.WriteDWordAt(astream.Position-lp+2,lp);
//    astream.WriteSizeAt(lp);
  end;
  
  astream.WriteDWordAt(astream.Position-lpos+2,lpos);
//  astream.WriteSizeAt(lpos);
end;

{$ENDIF}
