uses
  rgglobal;

var
  ls:string;
  h:dword;
begin
  ls:=ParamStr(1);
  writeln(ls);
  h:=rghash(pointer(ls),Length(ls));
  writeln(h);
  writeln(integer(h));
end.
