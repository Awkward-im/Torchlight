uses rgglobal,rgmdl,rgmesh;

var
  lmesh:TRGMesh;
  lmdl :TRGMDL;
  ls:string;
begin
  ls:=ParamStr(1);
  if ExtractExt(ls)='.MESH' then
  begin
    lmesh.Init;
    lmesh.LoadFromFile(PAnsiChar(ls));
    lmesh.Free;
  end
  // RG / RGO
  else if ExtractExt(ls)='.MDL' then
  begin
    lmdl.Init;
    if lmdl.LoadFromFile(PAnsiChar(ls)) then
    begin
      lmdl.SaveToXML(ExtractNameOnly(ls)+'.mesh.xml');
      lmdl.SaveMaterial(ExtractNameOnly(ls)+'.material');
      lmdl.Free;
    end
    // trying Hob
    else
    begin
      lmesh.Init;
      lmesh.LoadFromFile(PAnsiChar(ls));
      lmesh.Free;
    end
  end;

  RGLog.SaveToFile(ParamStr(1)+'.log');
end.
