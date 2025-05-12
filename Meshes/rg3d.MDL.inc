{}

{
  Don't worry about offsets and element types in Vertex Element List
  coz already have VET_FLOAT4 for Tangent in list but VET_FLOAT3 in reality
  and all offsets kept from MDLType1 block
}
function TRGMesh.ReadMDLType0(var aptr:PByte; aver:integer):boolean;
var
  lsm:PRGSubMesh;
  ls:AnsiString;
  lidx:PDWord;
  lpbuf:PByte;
  lvcnt, lblocks,lblock,i,j,lcnt,lcnt1:integer;
  lbone:dword;
  lweight:single;
begin
  result:=false;

  lsm:=SubMesh[0];

  lblocks:=memReadWord(aptr);  // 0001
  if lblocks<>1 then Log('!!!Before vertices is not 1',lblocks);

  for lblock:=0 to lblocks-1 do
  begin
    LogLn();
    Log('float x',memReadFloat(aptr));
    Log('float y',memReadFloat(aptr));
    Log('float z',memReadFloat(aptr));

    //===== Vertices =====

    lvcnt:=memReadDWord(aptr);
    lsm^.VertexCount:=lvcnt;
    LogLn();
    Log('vertexCount',lvcnt);

    j:=lsm^.FVEList.FindType(VES_POSITION); // 0

    Log(HexStr(aptr-FBuffer,8),'Vertex index');
    lidx:=PDWord(aptr);
    inc(aptr,lvcnt*4);

    lcnt:=memReadDWord(aptr);
    Log(HexStr(aptr-FBuffer,8),IntToStr(lcnt)+' unique vertices');

    lpbuf:=GetMem(lvcnt*SizeOf(TVector3));
    lsm^.FVEList.Buffer[j]:=lpbuf;

    for i:=0 to lvcnt-1 do
    begin
      with PVector3(lpbuf)[i] do
      begin
        X:=PVector3(aptr)[lidx[i]].X;
        Y:=PVector3(aptr)[lidx[i]].Y;
        Z:=PVector3(aptr)[lidx[i]].Z;
      end;
    end;
    inc(aptr,lcnt*SizeOf(TVector3));
    
    //===== Tangent and Binormal =====

    if aver in [$0D,$0E] then
    begin
      j:=memReadDWord(aptr);
      if j<>lcnt then Log('!!! Count of 6x floats is not the same as vertices', j);

      Log(HexStr(aptr-FBuffer,8),IntToStr(j)+' (unique) 6x floats');

      j:=lsm^.FVEList.FindType(VES_TANGENT); // 1
      lsm^.FVEList.format[j]:=VET_FLOAT3;  // coz VET_FLOAT4 declared
{
      lpbuf:=GetMem(lvcnt*SizeOf(TVector3));
      lsm^.FVEList.Buffer[j]:=lpbuf;

      for i:=0 to lvcnt-1 do
      begin
        with PVector3(lpbuf)[i] do
        begin
          X:=PVector3(aptr)[lidx[i]*2].X;
          Y:=PVector3(aptr)[lidx[i]*2].Y;
          Z:=PVector3(aptr)[lidx[i]*2].Z;
        end;
      end;

      j:=lsm^.FVEList.FindType(VES_BINORMAL); // 2
      lpbuf:=GetMem(lvcnt*SizeOf(TVector3));
      lsm^.FVEList.Buffer[j]:=lpbuf;

      // offset=TVector3 (VETData[VET_FLOAT3].size)
      for i:=0 to lvcnt-1 do
      begin
        with PVector3(lpbuf)[i] do
        begin
          X:=PVector3(aptr)[lidx[i]*2+SizeOf(TVector3)].X;
          Y:=PVector3(aptr)[lidx[i]*2+SizeOf(TVector3)].Y;
          Z:=PVector3(aptr)[lidx[i]*2+SizeOf(TVector3)].Z;
        end;
      end;
}      
      inc(aptr,lcnt*2*SizeOf(TVector3));
    end;

  end;

  //===== Texture =====

  lblocks:=memReadWord(aptr);  // 0001
  if lblocks<>1 then Log('!!!Before UVs is not 1',lblocks);

  for lblock:=0 to lblocks-1 do
  begin
    // Texture block can repeats
    for j:=0 to lsm^.FVEList.FCount-1 do
    begin
      if lsm^.FVEList.GetSemantic(j)<>VES_TEXTURE_COORDINATES then
        Continue;

      LogLn();
      Log(HexStr(aptr-FBuffer,8),IntToStr(j+1)+' UV index');
      lidx:=PDWord(aptr);
      inc(aptr,lvcnt*4);
      
      lcnt:=memReadDWord(aptr);
      Log(HexStr(aptr-FBuffer,8),IntToStr(lcnt)+' unique UVs');

      lpbuf:=GetMem(lvcnt*SizeOf(TVector2));
      lsm^.FVEList.Buffer[j]:=lpbuf;

      for i:=0 to lvcnt-1 do
      begin
        with PVector2(lpbuf)[i] do
        begin
          X:=PVector2(aptr)[lidx[i]].X;
          Y:=PVector2(aptr)[lidx[i]].Y;
        end;
      end;
      
      inc(aptr,lcnt*SizeOf(TVector2)); // VET_FLOAT2=8 VETData[vettype].size
    end;
  end;

  //===== Normals =====

  lblocks:=memReadWord(aptr);  // 0001
  if lblocks<>1 then Log('!!!Before normals is not 1',lblocks);

  for lblock:=0 to lblocks-1 do
  begin
    LogLn;
    Log(HexStr(aptr-FBuffer,8),'Normals index');
    lidx:=PDWord(aptr);
    inc(aptr,lvcnt*4);

    lcnt:=memReadDWord(aptr);
    Log(HexStr(aptr-FBuffer,8),IntToStr(lcnt)+' unique normals');

    j:=lsm^.FVEList.FindType(VES_NORMAL); // 3
    lpbuf:=GetMem(lvcnt*SizeOf(TVector3));
    lsm^.FVEList.Buffer[j]:=lpbuf;

    for i:=0 to lvcnt-1 do
    begin
      with PVector3(lpbuf)[i] do
      begin
        X:=PVector3(aptr)[lidx[i]].X;
        Y:=PVector3(aptr)[lidx[i]].Y;
        Z:=PVector3(aptr)[lidx[i]].Z;
      end;
    end;
    inc(aptr,lcnt*SizeOf(TVector3));
  end;

  //=====  Unknown =====

  LogLn();
  j:=memReadDWord(aptr);
  Log('dword (0)',j);

  //===== Skeleton =====

  lsm^.FBoneCount:=memReadDWord(aptr);
  Log('bones? (0)',lsm^.FBoneCount);
  if lsm^.FBoneCount>0 then
  begin
    // names
    for i:=0 to lsm^.FBoneCount-1 do
    begin
      ls:=memReadText(aptr);
      if rgDebugLevel=dlDetailed then
        Log('Bone '+IntToStr(i),ls);
    end;

    lsm^.SetBonesCapacity(lvcnt*2);    // reserve initially
    // for all vertices
    for i:=0 to lvcnt-1 do
    begin
      lcnt1:=memReadWord(aptr);        // bones per vertex
      for j:=0 to lcnt1-1 do
      begin
        lbone  :=memReadDWord(aptr);   // boneIndex
        lweight:=memReadFloat(aptr);   // weight
        lsm^.AddBone(i,lbone,lweight); // expand array if needs
      end;
    end;
  end;

  //===== Faces =====

  i   :=memReadDWord(aptr);     // total faces
  lcnt:=memReadDWord(aptr);     // Submeshes
  SubMeshCount:=lcnt;
  LogLn();
  Log('Total '+IntToStr(i)+' faces in '+IntToStr(lcnt)+' submesh[es]','');

  for i:=1 to lcnt do
  begin
    with SubMesh[i]^ do
    begin
      FUseSharedVertices:=true;
      Is32bit   :=true;
      FMaterial :=memReadWord (aptr);
      FFaceCount:=memReadDWord(aptr);
      if FFaceCount=0 then
      begin
        FFaces:=nil;
        Log('Submesh ' +IntToStr(i)+' is empty');
      end
      else
      begin
        GetMem(FFaces,FFaceCount*SizeOf(TIntVector3)); // VETData[VET_UINT3].size

        Log('Submesh ' +IntToStr(i)+
          ', material '+FMaterials[FMaterial].name+
          ', faces '   +IntToStr(FFaceCount)+
           ' offset'   ,HexStr(aptr-FBuffer,8));

  //      move(aptr^,FFaces^,FFaceCount*SizeOf(TIntVector3));
        // !!! reversed order
        for j:=0 to FFaceCount-1 do
        begin
          with PIntVector3(FFaces)[j] do
          begin
            Z:=PDword(aptr)[j*3  ]; // PIntVector3(aptr)[j].Z;
            Y:=PDword(aptr)[j*3+1]; // PIntVector3(aptr)[j].Y;
            X:=PDword(aptr)[j*3+2]; // PIntVector3(aptr)[j].X;
          end;
        end;

        inc(aptr,FFaceCount*3*SizeOf(DWord)); // SizeOf(TIntVector3)
      end;

    end;
  end;

  //===== Addition =====

  if (aptr-FBuffer)<FDataSize then
  begin
    LogLn;
    Log('>Pose? at',HexStr(aptr-FBuffer,8));
    // was 7 times, from Root to zz_attach_free
    while (aptr-FBuffer)<FDataSize do
    begin
      Log(memReadText(aptr));
      inc(aptr,12*4);         // floats
      memReadWord(aptr);      // 00 00
    end;
  end;

  result:=true;
end;

{
  Block size is 60 but lets think what we can have more than 1 texture block
  Bone Assignment is 12 byte format: dword, dword, float
}
function TRGMesh.ReadMDLType1(var aptr:PByte; aver:integer):boolean;
var
  lsm:PRGSubMesh;
//  lptr:PByte;
//  lsize,llsize:integer;
  i,j,lcnt,lvcnt:integer;
begin
  result:=false;
  lsm:=SubMesh[0];

  //===== M_GEOMETRY =====

  lcnt:=memReadWord(aptr); // count of geometries?
  if lcnt<>1 then Log('!!!Before vertices is not 1',lcnt);

  lvcnt:=memReadDWord(aptr); // Vertices, x*60 bytes (15 FLoat)
  lsm^.VertexCount:=lvcnt;

  LogLn();
  Log('Vertices',lvcnt);
  Log('Buffer'              ,HexStr(aptr-FBuffer   ,8));
  Log('  normals from (+40)',HexStr(aptr-FBuffer+40,8));
  Log('  texture from (+52)',HexStr(aptr-FBuffer+52,8));

  lsm^.FVEList.BindBuffer(aptr,0,lsm^.FVEList.GetSize(0),lvcnt);
{
  lsize:=lsm^.FVEList.GetSize(0);
  for j:=0 to lsm^.FVEList.Count-1 do
  begin
    // just skip unneded atm block
    if not (lsm^.FVEList.Semantic[j] in [VES_POSITION, VES_NORMAL, VES_TEXTURE_COORDINATES]) then continue;

    llsize:=lsm^.FVEList.Size[j];
    GetMem(lptr,lvcnt*llsize);
    lsm^.FVEList.Buffer[j]:=lptr;

    lptr:=aptr;
    for i:=0 to lvcnt-1 do
    begin
      move((lptr+lsm^.FVEList.Offset[j])^,
           PByte(lsm^.FVElist.Buffer[j]+i*llsize)^,
           llsize);
      inc(lptr,lsize);
    end;
  end;
  inc(aptr,lvcnt*lsize); // 60, if one texture block only
}
  //===== M_SUBMESH =====

  lcnt :=memReadDWord(aptr);    // submeshes
  SubMeshCount:=lcnt;
  LogLn();
  Log('SubMeshes',lcnt);

  for i:=1 to lcnt do
  begin
    with SubMesh[i]^ do
    begin
      FUseSharedVertices:=true;
      Is32bit   :=false;
      FFaceCount:=memReadDWord(aptr);
      FMaterial :=memReadDWord(aptr);

      Log('Submesh ' +IntToStr(i)+
        ', material '+FMaterials[FMaterial].name+
        ', faces '   +IntToStr(FFaceCount)+
         ' offset'   ,HexStr(aptr-FBuffer,8));

      GetMem(FFaces,FFaceCount*SizeOf(TIntVector3)); // VETData[VET_UINT3].size

      for j:=0 to FFaceCount-1 do
      begin
        with PIntVector3(FFaces)[j] do
        begin
          X:=Pword(aptr)[j*3  ]; // PIntVector3(aptr)[j].X;
          Y:=Pword(aptr)[j*3+1]; // PIntVector3(aptr)[j].Y;
          Z:=Pword(aptr)[j*3+2]; // PIntVector3(aptr)[j].Z;
        end;
      end;

      inc(aptr,FFaceCount*3*SizeOf(Word));

    end;
  end;

  //===== M_MESH_BOUNDS =====

  memRead(aptr,BoundMin,SizeOf(TVector3));
  memRead(aptr,BoundMax,SizeOf(TVector3));
  BoundRadius:=0;

  //===== M_MESH_SKELETON_LINK =====

  Skeleton:=memReadText(aptr);
  if Skeleton<>'' then
  begin
    LogLn();
    Log('skeletonName',Skeleton);
  end;

  //===== M_MESH_BONE_ASSIGNMENT =====

  lsm^.FBoneAssignCount:=memReadDWord(aptr);
  if lsm^.FBoneAssignCount>0 then
  begin
    Log(IntToStr(lsm^.FBoneAssignCount)+' Bones vertices, offset',HexStr(aptr-FBuffer,8));

    lsm^.FBoneCount:=memReadDWord(aptr);
    Log('bones count',lsm^.FBoneCount); //?? Bones? (limit for boneIndex)

    GetMem(lsm^.FBones,lsm^.FBoneAssignCount*SizeOf(TBoneVertex));
//    lsm^.SetBonesCapacity(lsm^.FBoneAssignCount); // plus reserve and set FBonesLen

    move(aptr^,lsm^.FBones^,lsm^.FBoneAssignCount*SizeOf(TBoneVertex));
{
    for i:=0 to lsm^.FBoneAssignCount-1 do
    begin
      lsm^.FBones[i].vertex:=memReadDword(aptr); // vertextIndex
      lsm^.FBones[i].bone  :=memReadDWord(aptr); // boneIndex
      lsm^.FBones[i].weight:=memReadFloat(aptr); // weight
      // AddBone uses FBoneAssignmentCount as incrementing index
    end;
}
    inc(aptr,lsm^.FBoneAssignCount*SizeOf(TBoneVertex));
  end;
  result:=true;
end;

function TRGMesh.ReadMDL(var aptr:PByte):boolean;
var
  lver:integer;
begin
  result:=false;

  lver:=memReadWord(aptr);
  if not ((lver mod 20) in [$01,$02,$03, $07,$08,$09, $0D,$0E]) then
  begin
    Log('!!!unknown type',lver);
    exit;
  end
  else
    Log('type ',lver);

  Log('first  (1)',memReadWord(aptr));
  Log('second [have bone info?] (0)',memReadWord(aptr));
  if lver in [13,14] then // type=$0D/$0E - RGO
    Log('add (1)' ,memReadWord(aptr)); // tangent and binormal block? but we have VE list

  SubMesh[0]^.FVEList.Read(aptr);

  LogLn;
  Log('scale?',memReadFloat(aptr));
  Log('dd (1)',memReadDWord(aptr));
  Log('dd (0)',memReadDWord(aptr));
  Log('dd (0)',memReadDWord(aptr)); // 4 for VIRAX 
  Log('dd (0)',memReadDWord(aptr));

  if not ReadRGMaterial(aptr,lver mod 20) then
  begin
    Log('wrong material info','');
    exit;
  end;

  if lver>20 then
    result:=ReadMDLType1(aptr,lver)
  else
    result:=ReadMDLType0(aptr,lver);
end;

