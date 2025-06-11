{}
{$IFDEF Interface}

// not used in Type1
type
  TMDLOptions = record
    FUseOffset:boolean; // use offset for vertices
    FUseBones :boolean; // use Bone shaders. Usually mean what bone list presents (skinned in Hob)
    FUseBiTan :boolean; // have BiNormal/Tangent tables
    FScale    :single;  // Vertice/Pose scale
    FLODCount :integer;
    FUnknParts:integer; // number of similar to Pose elements
    FPoseParts:integer; // number of Pose elements
    FReserved :integer; // not used
  end;

    // *.MDL of RG/RGO
    function ReadMDLType0(var aptr:PByte; const opt:TMDLOptions; aver:integer):boolean;
    function ReadMDLType1(var aptr:PByte; const opt:TMDLOptions; aver:integer):boolean;

    function ReadMDL(var aptr:PByte):boolean;

{$ELSE}

{
  Don't worry about offsets and element types in Vertex Element List
  coz already have VET_FLOAT4 for Tangent in list but VET_FLOAT3 in reality
  and all offsets kept from MDLType1 block

  ** X and Z axis are negative
  lblock = LODs?
}
function TRGMesh.ReadMDLType0(var aptr:PByte; const opt:TMDLOptions; aver:integer):boolean;
var
  lsm:PRGSubMesh;
  ls:AnsiString;
  lidx:PDWord;
  lpbuf:PByte;
  ofs:TVector3;
  lv:PVector3;
  lvcnt, lblock,i,j,k,lcnt,lcnt1:integer;
  lbone:dword;
  lweight:single;
  ltmp:array [0..11] of single;
begin
  result:=false;

  lsm:=SubMesh[0];

  memReadWord(aptr); // unused, 0001

  for lblock:=0 to opt.FLODCount-1 do
  begin
    ofs.X:=memReadFloat(aptr)*opt.FScale;
    ofs.Y:=memReadFloat(aptr)*opt.FScale;
    ofs.Z:=memReadFloat(aptr)*opt.FScale;
    LogLn();
    Log('offset: x='+FloatToStr(ofs.X)+' y='+FloatToStr(ofs.Y)+' z='+FloatToStr(ofs.Z));
// Offset break skeleton position
//    if not opt.FUseOffset then
    begin
      ofs.X:=0.0;
      ofs.Y:=0.0;
      ofs.Z:=0.0;
    end;

    //===== Vertices =====

    lvcnt:=memReadDWord(aptr);
    lsm^.VertexCount:=lvcnt;
    LogLn();
    Log('vertexCount',lvcnt);

    Log(HexStr(aptr-FBuffer,8),'Vertex index');
    lidx:=PDWord(aptr);
    inc(aptr,lvcnt*4);

    lcnt:=memReadDWord(aptr);
    Log(HexStr(aptr-FBuffer,8),IntToStr(lcnt)+' unique vertices');

    j:=lsm^.FVEList.FindType(VES_POSITION);
    lpbuf:=GetMem(lvcnt*SizeOf(TVector3));
    lsm^.FVEList.Buffer[j]:=lpbuf;

    for i:=0 to lvcnt-1 do
    begin
      j:=lidx[i];
      lv:=@PVector3(aptr)[j];
      with PVector3(lpbuf)[i] do
      begin
        X:=-({PVector3(aptr)[j]}lv^.X+ofs.X)*opt.FScale;
        Y:= ({PVector3(aptr)[j]}lv^.Y+ofs.Y)*opt.FScale;
        Z:=-({PVector3(aptr)[j]}lv^.Z+ofs.Z)*opt.FScale;
      end;
    end;
    inc(aptr,lcnt*SizeOf(TVector3));
    
    //===== Tangent and Binormal =====

    if opt.FUseBiTan then
    begin
      // uses same with vertices indexes
      lcnt:=memReadDWord(aptr); // must be same with vertices
      Log(HexStr(aptr-FBuffer,8),IntToStr(lcnt)+' unique Tangents and Binormals');

      j:=lsm^.FVEList.FindType(VES_TANGENT);
      if j>=0 then
      begin
        lpbuf:=GetMem(lvcnt*SizeOf(TVector3));
        lsm^.FVEList.Buffer[j]:=lpbuf;
        lsm^.FVEList.format[j]:=VET_FLOAT3;  // coz VET_FLOAT4 declared

        for i:=0 to lvcnt-1 do
        begin
          j:=lidx[i];
          lv:=@PVector3(aptr)[j];
          with PVector3(lpbuf)[i] do
          begin
            X:={PVector3(aptr)[j]}lv^.X;
            Y:={PVector3(aptr)[j]}lv^.Y;
            Z:={PVector3(aptr)[j]}lv^.Z;
          end;
        end;
      end;
      inc(aptr,lcnt*SizeOf(TVector3));

      //----- BiNormal -----

      j:=lsm^.FVEList.FindType(VES_BINORMAL);
      if j>=0 then
      begin
        lpbuf:=GetMem(lvcnt*SizeOf(TVector3));
        lsm^.FVEList.Buffer[j]:=lpbuf;

        for i:=0 to lvcnt-1 do
        begin
          j:=lidx[i];
          lv:=@PVector3(aptr)[j];
          with PVector3(lpbuf)[i] do
          begin
            X:={PVector3(aptr)[j]}lv^.X;
            Y:={PVector3(aptr)[j]}lv^.Y;
            Z:={PVector3(aptr)[j]}lv^.Z;
          end;
        end;
      end;
      inc(aptr,lcnt*SizeOf(TVector3));
    end;

    //===== Texture =====

    if memReadWord(aptr)<>0 then
    begin
      // Texture block can repeats
      // in original: just check what FEListCount>5 mean 2 textures maximum
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
          k:=lidx[i];
          with PVector2(lpbuf)[i] do
          begin
            X:= PVector2(aptr)[k].X;
            Y:=-PVector2(aptr)[k].Y;
          end;
        end;
        
        inc(aptr,lcnt*SizeOf(TVector2));
      end;
    end;

    //===== Normals =====

    if memReadWord(aptr)<>0 then
    begin
      LogLn;
      Log(HexStr(aptr-FBuffer,8),'Normals index');
      lidx:=PDWord(aptr);
      inc(aptr,lvcnt*4);

      lcnt:=memReadDWord(aptr);
      Log(HexStr(aptr-FBuffer,8),IntToStr(lcnt)+' unique normals');

      j:=lsm^.FVEList.FindType(VES_NORMAL);
      if j>=0 then
      begin
        lpbuf:=GetMem(lvcnt*SizeOf(TVector3));
        lsm^.FVEList.Buffer[j]:=lpbuf;

        for i:=0 to lvcnt-1 do
        begin
          j:=lidx[i];
          lv:=@PVector3(aptr)[j];
          with PVector3(lpbuf)[i] do
          begin
            X:=-{PVector3(aptr)[j]}lv^.X;
            Y:= {PVector3(aptr)[j]}lv^.Y;
            Z:=-{PVector3(aptr)[j]}lv^.Z;
          end;
        end;
      end;
      inc(aptr,lcnt*SizeOf(TVector3));
    end;

    //===== Colors? =====

{
  Looks like VET_UBYTE4_NORM (but in shorts) color values of VES_DIFFUSE/VES_SPECULAR
  Not used in RGO
  can be just VES_DIFFUSE (VES_COLOUR) with VET_UBYTE4 elements (MDL keep as VET_USHORT4)
  but we don't have VEList for it (counter>0 too)
}
    lcnt:=memReadDWord(aptr);
    if lcnt>0 then
    begin
      LogLn();
      Log('Colours, unique elements',lcnt);
{
      j:=lsm^.FVEList.FindType(VES_COLOUR);
      // maybe if j<0 then j:=lsm^.FVEList.Add(0,VET_FLOAT4,VES_COLOUR,0,0);
      if j>=0 then
      begin
        lpbuf:=GetMem(lvcnt*SizeOf(TVector4));
        lsm^.FVEList.Buffer[j]:=lpbuf;

        for i:=0 to lvcnt-1 do
        begin
          if i<lcnt then
            memReadWord(aptr)/255.0;
            memReadWord(aptr)/255.0;
            memReadWord(aptr)/255.0;
            memReadWord(aptr)/255.0;
          else 4x1.0
        end;
      end;
}
      inc(aptr,lcnt*4*SizeOf(Word));
    end;

    //===== Skeleton =====

    lsm^.FBoneCount:=memReadDWord(aptr);
    if lsm^.FBoneCount>0 then
    begin
      Log('bones',lsm^.FBoneCount);
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
      Log('Bone Assign elements',lsm^.FBoneAssignCount);
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

          // !!! reversed order
          for j:=0 to FFaceCount-1 do
          begin
            with PIntVector3(FFaces)[j] do
            begin
              Z:=PDword(aptr)[0];
              Y:=PDword(aptr)[1];
              X:=PDword(aptr)[2];
            end;
            inc(aptr,3*SizeOf(DWord)); // SizeOf(TIntVector3)
          end;
        end;

      end;
    end;

  end;

  //===== Addition =====

  // looks similar to pose, unused in RGO
  if opt.FUnknParts>0 then
  begin
    LogLn;
    Log(IntToStr(opt.FUnknParts)+' Unknown parts at',HexStr(aptr-FBuffer,8));

    for i:=0 to opt.FUnknParts-1 do
    begin
      Log(memReadText(aptr));
      aptr:=aptr+2+16*SizeOf(single);
      memReadData(aptr,ltmp,12*4);
{
      memReadWord(aptr); // signed
      // Position
       memReadFloat(aptr)*opt.FScale;
       memReadFloat(aptr)*opt.FScale;
      -memReadFloat(aptr)*opt.FScale;
      // Matrix 3 x 3 rotation
      memReadFloat(aptr);
      memReadFloat(aptr);
      memReadFloat(aptr);

      memReadFloat(aptr);
      memReadFloat(aptr);
      memReadFloat(aptr);

      memReadFloat(aptr);
      memReadFloat(aptr);
      memReadFloat(aptr);
      // Color
      memReadFloat(aptr);
      memReadFloat(aptr);
      memReadFloat(aptr);

      memReadFloat(aptr)*FScale; // idk
}
      if memReadWord(aptr)<>0 then
        memReadText(aptr); // UserData
//       Ogre::DataPoint::DataPoint(1,...,Position,?,idk,color)
    end;
  end;

  if opt.FPoseParts>0 then
//  if (lsm^.FBoneCount>0) and ((aptr-FBuffer)<FDataSize) then
  begin
    LogLn;
    Log(IntToStr(opt.FPoseParts)+' Pose parts at',HexStr(aptr-FBuffer,8));

    for i:=0 to opt.FPoseParts-1 do
    begin
      Log(memReadText(aptr));
      memReadData(aptr,ltmp,12*SizeOf(single));
//      Log('offset: x='+FloatToStr(ltmp[0])+' y='+FloatToStr(ltmp[ 1])+' z='+FloatToStr(ltmp[ 2]));
      // RG
      ltmp[0]:= ltmp[0]*opt.FScale;
      ltmp[1]:= ltmp[1]*opt.FScale;
      ltmp[2]:=-ltmp[2]*opt.FScale;
{
      Log('|' +FloatToStr(ltmp[3])+' '+FloatToStr(ltmp[ 4])+' '+FloatToStr(ltmp[ 5])+' |');
      Log('|' +FloatToStr(ltmp[6])+' '+FloatToStr(ltmp[ 7])+' '+FloatToStr(ltmp[ 8])+' |');
      Log('|' +FloatToStr(ltmp[9])+' '+FloatToStr(ltmp[10])+' '+FloatToStr(ltmp[11])+' |');
}
      if memReadWord(aptr)<>0 then
        memReadText(aptr); // UserData
    end;
  end;

  result:=true;
end;

{
  Block size is 60 but lets think what we can have more than 1 texture block
}
function TRGMesh.ReadMDLType1(var aptr:PByte; const opt:TMDLOptions; aver:integer):boolean;
var
  lsm:PRGSubMesh;
  i,j,lcnt,lvcnt:integer;
begin
  result:=false;
  lsm:=SubMesh[0];

  // Fix FVEList
  for i:=0 to lsm^.FVEList.Count-1 do
  begin
    with lsm^.FVEList[i]^ do
    begin
      source:=0;
      index :=0;
    end;
  end;

  //===== M_GEOMETRY =====

  memReadWord(aptr); // unused, 0001

  lvcnt:=memReadDWord(aptr);
  lsm^.VertexCount:=lvcnt;

  LogLn();
  Log('Vertices',lvcnt);
  Log('Buffer'  ,HexStr(aptr-FBuffer,8));

  // Auto split all to separate buffers
  lsm^.FVEList.BindBuffer(aptr,0,lsm^.FVEList.GetSize(0),lvcnt);

  //===== M_SUBMESH =====

  lcnt :=memReadDWord(aptr);    // submeshes
  SubMeshCount:=lcnt;
  LogLn();
  Log('SubMeshes',lcnt);

  for i:=1 to lcnt do
  begin
    with SubMesh[i]^ do
    begin
      FFaceCount:=memReadDWord(aptr);
      FMaterial :=memReadDWord(aptr);

      Log('Submesh ' +IntToStr(i)+
        ', material '+FMaterials[FMaterial].name+
        ', faces '   +IntToStr(FFaceCount)+
         ' offset'   ,HexStr(aptr-FBuffer,8));

      GetMem(FFaces,FFaceCount*SizeOf(TIntVector3));

      if lvcnt>=65526 then
      begin
        // need to check, X and Z must be switched?
        move(aptr^,FFaces^,FFaceCount*SizeOf(TIntVector3));
        inc(aptr          ,FFaceCount*SizeOf(TIntVector3));
      end
      else
      begin
        // just expand Word to DWord
        for j:=0 to FFaceCount-1 do
        begin
          with PIntVector3(FFaces)[j] do
          begin
            X:=Pword(aptr)[0];
            Y:=Pword(aptr)[1];
            Z:=Pword(aptr)[2];
          end;
          inc(aptr,3*SizeOf(Word));
        end;
      end;
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
    lsm^.FBonesLen:=lsm^.FBoneAssignCount;
//    lsm^.SetBonesCapacity(lsm^.FBoneAssignCount); // plus reserve and set FBonesLen

    move(aptr^,lsm^.FBones^,lsm^.FBoneAssignCount*SizeOf(TBoneVertex));
{
    for i:=0 to lsm^.FBoneAssignCount-1 do
    begin
      lsm^.FBones[i].vertex:=memReadDword(aptr); // vertextIndex
      lsm^.FBones[i].bone  :=memReadDWord(aptr); // boneIndex
      lsm^.FBones[i].weight:=memReadFloat(aptr); // weight
      // AddBone uses FBoneAssignmentCount as incrementing index, so must use lcnt then
    end;
}
    inc(aptr,lsm^.FBoneAssignCount*SizeOf(TBoneVertex));
  end;
  result:=true;
end;

function TRGMesh.ReadMDL(var aptr:PByte):boolean;
var
  lDumpAddr:PByte;
  lver:integer;
  ltype0:boolean;
  opt:TMDLOptions;
begin
  result:=false;

  lver:=memReadWord(aptr);
  ltype0:=lver<20;
  lver:=lver mod 20;

  Log('type ',lver);

  opt.FUseOffset:=memReadWord(aptr)<>0;
  opt.FUseBones :=memReadWord(aptr)<>0;
  if lver>11 then
    opt.FUseBiTan:=memReadWord(aptr)<>0
  else
    opt.FUseBiTan:=false;

  Log('use offset',ORD(opt.FUseOffset));
  Log('use bones' ,ORD(opt.FUseBones));
  Log('use binormal and tangent',ORD(opt.FUseBiTan));

  SubMesh[0]^.FVEList.Read(aptr);

  opt.FScale:=memReadFloat(aptr);
  opt.FLodCount :=memReadDWord(aptr);
  opt.FUnknParts:=memReadDWord(aptr);
  opt.FPoseParts:=memReadDWord(aptr);
  opt.FReserved :=memReadDWord(aptr);
  LogLn;
  Log('Scale'        ,opt.FScale);
  Log('LOD count'    ,opt.FLodCount);
  Log('Unknown parts',opt.FUnknParts);
  Log('Pose parts'   ,opt.FPoseParts);
  Log('Reserved'     ,opt.FReserved);

  lDumpAddr:=aptr;
  if not ReadRGMaterial(aptr,lver) then
  begin
    Log('wrong material info','');
    exit;
  end;
  FDumpSize:=aptr-lDumpAddr;
  GetMem(FMaterialDump,FDumpSize);
  move(lDumpAddr^,FMaterialDump^,FDumpSize);

  if ltype0 then
    result:=ReadMDLType0(aptr,opt,lver)
  else
    result:=ReadMDLType1(aptr,opt,lver);
end;

{$ENDIF}
