uses
  rgimageset;

var
  rg:TRGImageSet;
begin
  rg.Init;
  if rg.ParseFromFile(ParamStr(1)) then
  begin
    writeln(rg.Extract(),' file(s) extracted');
  end;
  rg.Free;
end.
