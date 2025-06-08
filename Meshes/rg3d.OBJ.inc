{}

procedure SaveSubMeshToObj(const asub:TRGSubMesh; aStream:TStream);
var
  lptr:PByte;
  ltype:string;
  i,j:integer;
begin
  for i:=0 to asub.FVEList.Count-1 do
  begin
    lptr:=asub.FVEList.Buffer[i];
    if lptr=nil then continue;

    WriteLine(aStream,'');

    case asub.FVEList.semantic[i] of
      VES_POSITION: begin ltype:='v ' ; {lptr:=asub.Vertex;} end;
      VES_NORMAL  : begin ltype:='vn '; {lptr:=asub.Normal;} end;

      VES_TEXTURE_COORDINATES: begin
//        lptr:=asub.Texture;
        for j:=0 to asub.FVertexCount-1 do
        begin
          with PVector2(lptr)[j] do
            WriteLine(aStream,'vt '+
              FloatToStr(x)+' '+
              FloatToStr(y));
        end;
        continue;
      end;

    else
      RGLog.Add('Export to OBJ: Ignore geometry '+GetVESName(asub.FVEList.semantic[i]));
      continue;
    end;

    for j:=0 to asub.FVertexCount-1 do
    begin
      with PVector3(lptr)[j] do
        WriteLine(aStream, ltype+
          FloatToStr(x)+' '+
          FloatToStr(y)+' '+
          FloatToStr(z));
    end;

  end;
end;

procedure TRGMesh.SaveToOBJ(aStream:TStream);
var
  lsm:PRGSubMesh;
  i,j:integer;
begin
{
  if Length(FTextures)>0 then
  begin
    WriteLine(aStream,'mtllib master.mtl');
    for i:=0 to High(FTextures) do
    begin
    end;
  end;
}
  WriteLine(aStream,'o Mesh');

  if SubMesh[0]^.VertexCount>0 then
    SaveSubMeshToObj(SubMesh[0]^, aStream);

  for i:=1 to SubMeshCount do
  begin
    lsm:=SubMesh[i];

    WriteLine(aStream,'');
    if lsm^.Name<>'' then
      WriteLine(aStream,'g '+lsm^.Name)
    else
      WriteLine(aStream,'g '+FMaterials[lsm^.FMaterial].name);

    if lsm^.FVertexCount>0 then
      SaveSubMeshToObj(lsm^, aStream);

    if lsm^.FFaceCount>0 then
    begin
      WriteLine(aStream,'usemtl '+FMaterials[lsm^.FMaterial].name);

      for j:=0 to lsm^.FFaceCount-1 do
      begin
        with PIntVector3(lsm^.FFaces)[j] do
          WriteLine(aStream,'f '+
            (IntToStr(X+1))+' '+
            (IntToStr(Y+1))+' '+
            (IntToStr(Z+1)));
      end;
    end;
  end;
  
end;

procedure TRGMesh.SaveToOBJ(const aFileName:String);
var
  lStream:TFileStream;
begin
  lStream:=TFileStream.Create(aFileName,fmCreate);
  try
    SaveToOBJ(lStream);
  finally
    FreeAndNil(lStream);
  end;
end;

