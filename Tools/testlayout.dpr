uses
  rgglobal,
  rgdict,
  rgio.layout;

var
//  rgl:TRGLayoutFile;
  info:TRGObject;
  lptr:pointer;
  lid:dword;
begin
  LoadLayoutDict('compact-tl2.txt',verTL2);
  info.Init;
  info.Version:=verTL2;
  if info.SelectScene('')=nil then writeln('scene not found');
  lptr:=info.GetObjectByName('Sound');
  if lptr<>nil then
  begin
    writeln(info.GetPropsCount());
    if info.GetPropInfoByName('RADIUS',rgFloat,lid)<>rgUnknown then
      writeln('Prop id is ',lid)
    else writeln('Prop is unknown');
  end
  else writeln('Obj is nil');
  info.Clear;
{
  rgl.Init;
  rgl.FVer:=verTL2;
  rgl.Free;
}
end.
