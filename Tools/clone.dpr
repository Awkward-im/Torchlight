uses
  rgio.text,
  rgnode;
var
  p1,p2:pointer;
begin
  p1:=ParseTextFile(PChar(ParamStr(1)));
  p2:=CloneNode(p1);
  BuildTextFile(p2,'cloneout.txt');
  DeleteNode(p1);
  DeleteNode(p2);
end.

