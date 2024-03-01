uses
  rgglobal;

var
  ls:string;
  h:dword;
begin
  ls:=ParamStr(1);
  writeln(ls);
  h:=rghashb(pointer(ls),Length(ls));
  writeln(h,':',ls);
  writeln(integer(h));
end.
