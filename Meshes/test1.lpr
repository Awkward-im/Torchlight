uses
  classes,
  rgglobal,
  rgobj;

var
  mesh:TRGMesh;
  ls:string;
  st:TMemoryStream;
begin
  if ParamCount()>0 then
  begin
    ls:=ParamStr(1);
    mesh.Init;
rgDebugLevel:=dlDetailed;
    if mesh.ImportFromFile(ls) then
    begin
//      mesh.SaveToOBJ   (ExtractNameOnly(ls)+'.mesh.obj');
//      mesh.SaveToXML   (ExtractNameOnly(ls)+'.mesh.xml');

//      mesh.SaveMaterial(ExtractNameOnly(ls)+'.material');
      st:=TMemoryStream.Create();
      mesh.WriteMdl(st,14);
      st.SaveToFile('output.mdl');
      st.Clear;
      mesh.WriteMesh(st,40);
      st.SaveToFile('output.mesh');
      st.Free;

    end;
    mesh.Free;
  end;
  RGLog.SaveToFile(ParamStr(1)+'.log');
end.
