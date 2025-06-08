uses
  rgglobal,
  rgobj;

var
  mesh:TRGMesh;
  ls:string;
begin
  if ParamCount()>0 then
  begin
    ls:=ParamStr(1);
    mesh.Init;
    if mesh.ImportFromFile(ls) then
    begin
//      mesh.SaveToOBJ   (ExtractNameOnly(ls)+'.mesh.obj');
      mesh.SaveToXML   (ExtractNameOnly(ls)+'.mesh.xml');
      mesh.SaveMaterial(ExtractNameOnly(ls)+'.material');
    end;
    mesh.Free;
  end;
  RGLog.SaveToFile(ParamStr(1)+'.log');
end.
