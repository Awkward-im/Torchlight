function taghash(instr:PChar; alen:integer):dword;
var
  i:dword;
begin
  result:=alen and $FFFFFFFF;
  for i:=0 to alen-1 do
    result:= (
       (
         ((result SHR 27) and $FFFFFFFF) xor
         ((result SHL  5) and $FFFFFFFF) and
         $FFFFFFFF
       ) xor  ORD(instr[i])
     ) and $FFFFFFFF;
end;

var
  ls:string;
  h:dword;
begin
  ls:=ParamStr(1);
  writeln(ls);
  h:=taghash(pointer(ls),Length(ls));
  writeln(h);
  writeln(integer(h));
end.
