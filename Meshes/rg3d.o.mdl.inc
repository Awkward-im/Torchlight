{}
{TODO: combine submesh geometries to global one}
{TODO: options:compact (no binormal and tangent)/generic (as read)}
{$IFDEF Interface}

  procedure WriteMDLType0(astream:TStream);
  procedure WriteMDLType1(astream:TStream);
//  procedure WriteMDL     (astream:TStream; aver:integer);

{$ELSE}

procedure TRGMesh.WriteMDLType1(astream:TStream);
var
  p:pointer;
  lsm:PRGSubMesh;
  i,j:integer;
begin
  lsm:=SubMesh[0];

  //===== M_GEOMETRY =====

  astream.WriteWord(1);
  astream.WriteDWord(lsm^.VertexCount);

  // means, every block have it's own buffer with offset=0 and index=0
  for i:=0 to lsm^.VertexCount-1 do
  begin
    for j:=0 to lsm^.FVEList.Count-1 do
    begin
      p:=lsm^.FVEList.Buffer[j];
      if p<>nil then
        case lsm^.FVEList.Format[j] of
          VET_FLOAT2: astream.Write(PVector2(p)[i],SizeOf(TVector2));
          VET_FLOAT3: astream.Write(PVector3(p)[i],SizeOf(TVector3));
          VET_FLOAT4: astream.Write(PVector4(p)[i],SizeOf(TVector4));
        end;
    end;
  end;

  //===== M_SUBMESH =====

  astream.WriteDWord(SubMeshCount);
  for i:=1 to SubMeshCount do
  begin
    with SubMesh[i]^ do
    begin
      astream.WriteDWord(FFaceCount);
      astream.WriteDWord(FMaterial);
      if FFaceCount>=65526 then // treat as is32bit
      begin
        for j:=0 to FFaceCount-1 do
        begin
          with PIntVector3(FFaces)[j] do
          begin
            astream.WriteDWord(X);
            astream.WriteDWord(Y);
            astream.WriteDWord(Z);
          end;
        end;
      end
      else
      begin
        for j:=0 to FFaceCount-1 do
        begin
          with PIntVector3(FFaces)[j] do
          begin
            astream.WriteWord(X);
            astream.WriteWord(Y);
            astream.WriteWord(Z);
          end;
        end;
      end;
    end;
  end;
  
  //===== M_MESH_BOUNDS =====

  astream.Write(BoundMin,SizeOf(TVector3));
  astream.Write(BoundMax,SizeOf(TVector3));

  //===== M_MESH_SKELETON_LINK =====

  WriteText(astream, Skeleton);

  //===== M_MESH_BONE_ASSIGNMENT =====

  astream.WriteDWord(lsm^.FBoneAssignCount);
  if lsm^.FBoneAssignCount>0 then
  begin
    astream.WriteDWord(lsm^.FBoneCount);
    astream.Write(lsm^.FBones^,lsm^.FBoneAssignCount*SizeOf(TBoneVertex));
{
    for i:=0 to lsm^.FBoneAssignCount-1 do
    begin
      astream.WriteDWord(lsm^.FBones[i].vertex);
      astream.WriteDWord(lsm^.FBones[i].bone  );
      astream.WriteFloat(lsm^.FBones[i].weight);
    end;
}
  end;

end;

procedure TRGMesh.WriteMDL(astream:TStream; aver:integer);
begin
  astream.WriteWord($1000);
  WriteText(astream,GetVersionText(99));

  astream.WriteWord(aver);

  astream.WriteWord(0{ORD(opt.FUseOffset)});
  if SubMesh[0]^.FBoneCount>0 then
    astream.WriteWord(1{ORD(opt.FUseBones)})
  else
    astream.WriteWord(0);

  if (aver mod 20)>11 then
    astream.WriteWord({opt.FUseBiTan}0);

  SubMesh[0]^.FVEList.Write(astream);

  astream.WriteFloat(1{opt.FScale});
  astream.WriteDWord(1{opt.FLodCount});
  astream.WriteDWord(0{opt.FUnknParts});
  astream.WriteDWord(0{opt.FPoseParts});
  astream.WriteDWord(0{opt.FReserved});

  if (FMaterialDump<>nil) and (FDumpSize>0) then
    astream.Write(FMaterialDump^,FDumpSize)
  else
    WriteRGMaterial(astream, aver mod 20);
  
  if aver>=20 then
    WriteMDLType1(astream)
  else
    WriteMDLType0(astream)
end;

procedure TRGMesh.WriteMDLType0(astream:TStream);
var
  lsm:PRGSubMesh;
  i,j,lcnt:integer;
begin
  lsm:=SubMesh[0];

  astream.WriteWord(1);

  // offset
  astream.WriteFloat(0);
  astream.WriteFloat(0);
  astream.WriteFloat(0);

  //===== Vertices =====

  astream.WriteDWord(lsm^.VertexCount);

  // index
  // vertices

  //===== Tangent and Binormal =====

  // best way just to skip

  //===== Texture =====

  astream.WriteWord(1);

  // Texture block can repeats
  for i:=0 to lsm^.FVEList.FCount-1 do
  begin
    if lsm^.FVEList.GetSemantic(i)<>VES_TEXTURE_COORDINATES then
      Continue;

  // index
  // vertices

  end;

  //===== Normals =====

  // index
  // vertices

  //===== Colors =====

  astream.WriteDWord(0);

  //===== Skeleton =====

  astream.WriteDWord(lsm^.FBoneCount);
  if lsm^.FBoneCount>0 then
  begin
    for i:=0 to lsm^.FBoneCount-1 do
//      WriteText(astream,);
  end;

  //===== Faces =====

  lcnt:=0;
  for i:=1 to FSubMeshCount do
    inc(lcnt,SubMesh[i]^.FFaceCount);

  astream.WriteDWord(lcnt);
  astream.WriteDWord(FSubMeshCount);

  for i:=1 to FSubMeshCount do
  begin
    with SubMesh[i]^ do
    begin
      for j:=0 to FFaceCount-1 do
      begin
        with PIntVector3(FFaces)[j] do
        begin
          astream.WriteDWord(Z);
          astream.WriteDWord(Y);
          astream.WriteDWord(X);
        end;
      end;
    end;
  end;

  //===== Addition =====
{
  if (lsm^.FBoneCount>0) then
  begin
    WriteText(astream,);
  end;
}
end;

{$ENDIF}
