{}
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
    astream.WriteDWord(FBoneCount);
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
var
  ve:TVertexElement;
  i,lcnt,ltxt,loffset:integer;
begin
  astream.WriteWord($1000);
  WriteText(astream,GetVersionText(99));

  astream.WriteWord(aver);

  astream.WriteWord(0{ORD(opt.FUseOffset)});
  if FBoneCount>0 then
    astream.WriteWord(1{ORD(opt.FUseBones)})
  else
    astream.WriteWord(0);

  if (aver mod 20)>11 then
    astream.WriteWord({opt.FUseBiTan}0);

// Blocks must be as "all blocks have buffers. offset, index are 0, source is number"

//  SubMesh[0]^.FVEList.Write(astream);
  lcnt:=0;
  with SubMesh[0]^.FVEList do
    for i:=0 to Count-1 do
      if Buffer[i]<>nil then inc(lcnt);
  astream.WriteWord(lcnt);

  // save list as "One buffer with offsets. index and source are 0"
  if aver>20 then
  begin
    loffset:=0;
    with SubMesh[0]^.FVEList do
      for i:=0 to Count-1 do
      begin
        if Buffer[i]<>nil then
        begin
          ve:=FVEList[i];
          ve.offset:=loffset;
          ve.source:=0;
          inc(loffset,VETData[ve._type].size);

          astream.Write(ve,SizeOf(TVertexElement));
        end;
      end;
  end
  // "offset is 0, source is number"
  // "BiTan is one buffer, Textures are one
  // "BiNormal and Texture-1 have index"
  else
  begin
    ltxt:=0;
    lcnt:=0;
    with SubMesh[0]^.FVEList do
      for i:=0 to Count-1 do
      begin
        if Buffer[i]<>nil then
        begin
          ve:=FVEList[i];
          ve.source:=lcnt;

          if ve.semantic=VES_BINORMAL then
            ve.index:=1
          else if ve.semantic=VES_TEXTURE_COORDINATES then
          begin
            ve.index:=ltxt;
            inc(ltxt);
          end;

          inc(lcnt);
          astream.Write(ve,SizeOf(TVertexElement));
        end;
      end;
    //!! cheat, coz type0 accept second texture only for block count>5
    if (ltxt>=2) and (lcnt<6) then
    begin
      // just duplicate last block description
      for i:=0 to (5-lcnt) do
       astream.Write(ve,SizeOf(TVertexElement));
    end;
  end;

  astream.WriteFloat(1{opt.FScale});
  astream.WriteDWord(1{opt.FLodCount});
  astream.WriteDWord(0{opt.FUnknParts});
  astream.WriteDWord(0{opt.FPoseParts});
  astream.WriteDWord(0{opt.FReserved});

{
  if (FMaterialDump<>nil) and (FDumpSize>0) then
    astream.Write(FMaterialDump^,FDumpSize)
  else
}
  WriteRGMaterial(astream, aver mod 20);
  
  if aver>=20 then
    WriteMDLType1(astream)
  else
    WriteMDLType0(astream);
end;

procedure TRGMesh.WriteMDLType0(astream:TStream);
var
  lsm:PRGSubMesh;
  lv:PVector3;
  i,j,lcnt:integer;
//  lsize:integer;
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
  for i:=0 to lsm^.VertexCount-1 do astream.WriteDWord(i);
  // vertices
  astream.WriteDWord(lsm^.VertexCount);

  lv:=lsm^.Vertices[VES_POSITION];
  for i:=0 to lsm^.VertexCount-1 do
  begin
    astream.WriteFloat(-lv^.X);
    astream.WriteFloat( lv^.Y);
    astream.WriteFloat(-lv^.Z);
    inc(lv{,SizeOf(TVector3)});
  end;

  //===== Tangent and Binormal =====
(*
  // best way just to skip
  if opt.FUseBiTan then
  begin
    astream.WriteDWord(lsm^.VertexCount);

    //!! write Vector3 even if original is Vector4
    lcnt :=lsm^.FVEList.FindType(VES_TANGENT);
    lsize:=lsm^.FVEList.Size[lcnt];
    lv   :=PVector3(lsm^.FVEList.Buffer[lcnt]);
    for i:=0 to lsm^.VertexCount-1 do
    begin
      astream.WriteFloat(lv^.X);
      astream.WriteFloat(lv^.Y);
      astream.WriteFloat(lv^.Z);
      inc(PByte(lv),lsize);
    end;

    lv:=lsm^.BiNormal;
    for i:=0 to lsm^.VertexCount-1 do
    begin
      astream.WriteFloat(lv^.X);
      astream.WriteFloat(lv^.Y);
      astream.WriteFloat(lv^.Z);
      inc(lv{,SizeOf(TVector3)});
    end;
  end;
*)
  //===== Texture =====

  astream.WriteWord(1);

  // Texture block can repeats
  for i:=0 to lsm^.FVEList.FCount-1 do
  begin
    if lsm^.FVEList.GetSemantic(i)<>VES_TEXTURE_COORDINATES then
      Continue;

    // index
    for j:=0 to lsm^.VertexCount-1 do astream.WriteDWord(j);
    // vertices
    astream.WriteDWord(lsm^.VertexCount);
    lv:=PVector3(lsm^.FVEList.Buffer[i]);
    for j:=0 to lsm^.VertexCount-1 do
    begin
      astream.WriteFloat( lv^.X);
      astream.WriteFloat(-lv^.Y);
      inc(PByte(lv),SizeOf(TVector2));
    end;
  end;

  //===== Normals =====

  astream.WriteWord(1);
  // index
  for i:=0 to lsm^.VertexCount-1 do astream.WriteDWord(i);
  // vertices
  astream.WriteDWord(lsm^.VertexCount);

  lv:=lsm^.Vertices[VES_NORMAL];
  for i:=0 to lsm^.VertexCount-1 do
  begin
    astream.WriteFloat(-lv^.X);
    astream.WriteFloat( lv^.Y);
    astream.WriteFloat(-lv^.Z);
    inc(lv{,SizeOf(TVector3)});
  end;

  //===== Colors =====

  astream.WriteDWord(0);

  //===== Skeleton =====

//  astream.WriteDWord(0);

  astream.WriteDWord(FBoneCount);
  if FBoneCount>0 then
  begin
    for i:=0 to FBoneCount-1 do
      WriteText(astream,'');

    for i:=0 to lsm^.VertexCount-1 do
    begin
      lcnt:=0;
      for j:=0 to lsm^.FBoneAssignCount-1 do
        if lsm^.FBones[j].vertexIndex=i then inc(lcnt);
      astream.WriteWord(lcnt);

      if lcnt>0 then
        for j:=0 to lsm^.FBoneAssignCount-1 do
        begin
          with lsm^.FBones[j] do
            if vertexIndex=i then
            begin
              astream.WriteDWord(boneIndex);
              astream.WriteFloat(weight);
              dec(lcnt);
              if lcnt=0 then break;
            end;
        end;
    end;
  end;

  //===== Faces =====

  lcnt:=0;
  for i:=1 to SubMeshCount do
    inc(lcnt,SubMesh[i]^.FFaceCount);

  astream.WriteDWord(lcnt);
  astream.WriteDWord(SubMeshCount);

  for i:=1 to SubMeshCount do
  begin
    with SubMesh[i]^ do
    begin
      astream.WriteWord (FMaterial);
      astream.WriteDWord(FFaceCount);
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
  if (FBoneCount>0) then
  begin
    WriteText(astream,);
  end;
}
end;

{$ENDIF}
