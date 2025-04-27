{}
procedure SaveToOBJ(const amesh:TRGMesh; const aStream:TStream);

  procedure WriteLine(const aString:UTF8String);
  const
    NewLine:array[0..1] of AnsiChar=(#13,#10);
  begin
    if length(aString)>0 then
      aStream.WriteBuffer(aString[1],length(aString));

    aStream.WriteBuffer(NewLine[0],SizeOf(NewLine));
  end;

  function FloatToStr(const aValue:single):UTF8String;
  begin
    Str(aValue:0:12,result);
  end;

var
  i,j,lofs:integer;
begin
  if Length(FTextures)>0 then
  begin
    WriteLine('mtllib '+FName+'.mtl');
    for i:=0 to High(FTextures) do
    begin
    end;
  end;

  WriteLine('o Mesh');
  for i:=0 to FVertexCount-1 do
  begin
    WriteLine('v '+
      FloatToStr(FVertices[i].x)+' '+
      FloatToStr(FVertices[i].y)+' '+
      FloatToStr(FVertices[i].z));
  end;

  WriteLine('');

  for i:=0 to FVertexCount-1 do
  begin
    WriteLine('vn '+
      FloatToStr(FNormals[i].x)+' '+
      FloatToStr(FNormals[i].y)+' '+
      FloatToStr(FNormals[i].z));
  end;

  WriteLine('');

  for i:=0 to FVertexCount-1 do
  begin
    WriteLine('vt '+
      FloatToStr(FUVs[i].x)+' '+
      FloatToStr(FUVs[i].y));
  end;

  for i:=0 to High(FSubMeshes) do
  begin
    WriteLine('');
    WriteLine('g '+FMaterials[FSubMeshes[i].material].name);

    if FSubMeshes[i].numface>0 then
    begin
      WriteLine('usemtl '+FMaterials[FSubMeshes[i].material].name);

      lofs:=FSubMeshes[i].ofsface;
      for j:=0 to FSubMeshes[i].numface-1 do
      begin
      WriteLine('f '+
        (IntToStr(FFaces[lofs+j].X+1))+' '+
        (IntToStr(FFaces[lofs+j].Y+1))+' '+
        (IntToStr(FFaces[lofs+j].Z+1)));
      end;
    end;
  end;
  
end;

procedure SaveToOBJ(const amesh:TRGMesh; const aFileName:String);
var
  lStream:TFileStream;
begin
  lStream:=TFileStream.Create(aFileName,fmCreate);
  try
    SaveToOBJ(amesh, lStream);
  finally
    FreeAndNil(lStream);
  end;
end;

