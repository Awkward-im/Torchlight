{}
{
	<poses>
		<pose target="submesh" index="3" name="Expression_neutral">
			<poseoffset index="140" x="0.000158971" y="0.251799" z="-0.00430926" />

	<animations>
		<animation name="Speak" length="6.96552">
			<tracks>
				<track target="submesh" index="3" type="pose">
					<keyframes>
						<keyframe time="0">
							<poseref poseindex="3" influence="1" />  <!--repeated or absent-->
}
function FloatToStr(const aValue:single):UTF8String;
begin
  Str(aValue:0:6,result);
  FixFloatStr(AnsiString(result));
end;

procedure WriteLine(aStream:TStream; const aString:UTF8String);
begin
  if length(aString)>0 then
    aStream.WriteBuffer(aString[1],length(aString));

  aStream.WriteBuffer(#13#10,2);
end;

procedure SaveGeometryToXML(const asub:TRGSubMesh; aStream:TStream);
var
  lptr:PByte;
  lattrib,lnode:string;
  ltxt,i,j,lcnt:integer;
begin
  lcnt:=asub.VertexCount;
  ltxt:=0;

  for i:=0 to asub.FVEList.Count-1 do
  begin
    lptr:=asub.FVEList.Buffer[i];
    if lptr=nil then continue;

    case asub.FVEList.semantic[i] of
      VES_POSITION: begin
        lattrib:='positions';
        lnode  :='position';
      end;
      VES_NORMAL: begin
        lattrib:='normals';
        lnode  :='normal';
      end;
      VES_TANGENT: begin
        lattrib:='tangents';
        lnode  :='tangent';
      end;
      VES_BINORMAL: begin
        lattrib:='binormals';
        lnode  :='binormal';
      end;

      VES_DIFFUSE: begin
        lattrib:='colours_diffuse';
        lnode  :='colour_diffuse';

        continue;
      end;
      VES_SPECULAR: begin
        lattrib:='colours_specular';
        lnode  :='colour_specular';

        continue;
      end;
      VES_TEXTURE_COORDINATES: begin
        lattrib:='textcoords';
        lnode  :='textcoord';

{
  texture_coord_dimensions_#="2" for all
  texture_coords="amount"
}
        
        WriteLine(aStream,'    <vertexbuffer texture_coord_dimensions_0="2" texture_coords="1">');
//        WriteLine('    <vertexbuffer texture_coord_dimensions_'+IntToStr(ltxt)+
//                  '="2" texture_coords="1">');

        for j:=0 to lcnt-1 do
        begin
          WriteLine(aStream,'      <vertex>');

          // in cycle of TexCoordDimName for texture base element count
          with PVector2(lptr)[j] do
            WriteLine(aStream,'        <texcoord'+
                 ' u="'+FloatToStr(x)+
                '" v="'+FloatToStr(y)+'" />');

          WriteLine(aStream,'      </vertex>');
        end;

        WriteLine(aStream,'    </vertexbuffer>');
        inc(ltxt);

        continue;
      end;
    else
      RGLog.Add('Export to XML: Ignore geometry '+GetVESName(asub.FVEList.semantic[i]));
      continue;
    end;

    WriteLine(aStream,'    <vertexbuffer '+lattrib+'="true">');
    for j:=0 to lcnt-1 do
    begin
      WriteLine(aStream,'      <vertex>');

      if asub.FVEList.format[i]=VET_FLOAT4 then
      begin
        with PVector4(lptr)[j] do
          WriteLine(aStream,'        <'+lnode+
               ' x="'+FloatToStr(x)+
              '" y="'+FloatToStr(y)+
              '" z="'+FloatToStr(z)+
              '" w="'+FloatToStr(w)+'" />');
      end
      else
      begin
        with PVector3(lptr)[j] do
          WriteLine(aStream,'        <'+lnode+
               ' x="'+FloatToStr(x)+
              '" y="'+FloatToStr(y)+
              '" z="'+FloatToStr(z)+'" />');
      end;
      WriteLine(aStream,'      </vertex>');
    end;
    WriteLine(aStream,'    </vertexbuffer>');
  end;

end;

procedure TRGMesh.SaveToXML(aStream:TStream);
var
  lsm:PRGSubMesh;
  ls,ls1:string;
  i,j:integer;
  b:boolean;
begin
  WriteLine(aStream,'<mesh>');

  i:=SubMesh[0]^.VertexCount;

  if i>0 then
  begin
    WriteLine(aStream,'  <sharedgeometry vertexcount="'+IntToStr(i)+'">');
    SaveGeometryToXML(SubMesh[0]^, aStream);
    WriteLine(aStream,'  </sharedgeometry>');
  end;

  WriteLine(aStream,'  <submeshes>');
  for i:=1 to SubMeshCount do
  begin
    lsm:=SubMesh[i];
    if lsm^.FFaceCount=0 then continue;

    // type 20+ have 16 bit indexes
    if lsm^.FFaceCount>=65526 then ls :='true' else ls :='false';
    if lsm^.FVertexCount=0    then ls1:='true' else ls1:='false';

    WriteLine(aStream,'    <submesh material="'+FMaterials[lsm^.FMaterial].name+
        '" usesharedvertices="'+ls1+'" use32bitindexes="'+ls+'" operationtype="triangle_list">');

    // Faces

    WriteLine(aStream,'      <faces count="'+IntToStr(lsm^.FFaceCount)+'">');

    for j:=0 to lsm^.FFaceCount-1 do
    begin
      with PIntVector3(lsm^.FFaces)[j] do
        WriteLine(aStream,'        <face'+
           ' v1="'+(IntToStr(X))+
          '" v2="'+(IntToStr(Y))+
          '" v3="'+(IntToStr(Z))+'" />');
    end;
    
    WriteLine(aStream,'      </faces>');

    if lsm^.FVertexCount>0 then
    begin
      WriteLine(aStream,'      <geometry vertexcount="'+IntToStr(lsm^.FVertexCount)+'">');
      SaveGeometryToXML(lsm^, aStream);
      WriteLine(aStream,'      </geometry>');
    end;

    // submesh Bone assignment

    if lsm^.FBoneAssignCount>0 then
    begin
      WriteLine(aStream,'      <boneassignments>');
      for j:=0 to lsm^.FBoneAssignCount-1 do
      begin
        with lsm^.FBones[j] do
          WriteLine(aStream,'        <vertexboneassignment'+
             ' vertexindex="'+IntToStr  (vertexIndex)+
            '" boneindex="'  +IntToStr  (boneIndex  )+
            '" weight="'     +FloatToStr(weight)+'" />');
      end;
      WriteLine(aStream,'      </boneassignments>');
    end;

    WriteLine(aStream,'    </submesh>');
  end;
  WriteLine(aStream,'  </submeshes>');

  // Submesh name table

  b:=false;
  for i:=1 to SubMeshCount do
  begin
    if SubMesh[i]^.Name<>'' then
    begin
      b:=true;
      break;
    end;
  end;
  if b then
  begin
  	WriteLine(aStream,'  <submeshnames>');
    for i:=1 to SubMeshCount do
    begin
      if SubMesh[i]^.Name<>'' then
        WriteLine(aStream,'    <submeshname name="'+SubMesh[i]^.Name+'" index="'+IntToStr(i-1)+'" />');
    end;
  	WriteLine(aStream,'  </submeshnames>');
  end;

  // shared Bone assignment

  lsm:=SubMesh[0];
  if lsm^.FBoneAssignCount>0 then
  begin
    WriteLine(aStream,'  <boneassignments>');
    for i:=0 to lsm^.FBoneAssignCount-1 do
    begin
      with lsm^.FBones[i] do
        WriteLine(aStream,'    <vertexboneassignment'+
           ' vertexindex="'+IntToStr  (vertexIndex)+
          '" boneindex="'  +IntToStr  (boneIndex  )+
          '" weight="'     +FloatToStr(weight)+'" />');
    end;
    WriteLine(aStream,'  </boneassignments>');
  end;

  if Skeleton<>'' then
    WriteLine(aStream,'  <skeletonlink name="'+Skeleton+'" />');

  WriteLine(aStream,'</mesh>');
end;

procedure TRGMesh.SaveToXML(const aFileName:String);
var
  lStream:TFileStream;
begin
  lStream:=TFileStream.Create(aFileName,fmCreate);
  try
    SaveToXML(lStream);
  finally
    FreeAndNil(lStream);
  end;
end;
