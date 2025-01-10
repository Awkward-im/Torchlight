var
  tr:record
    case boolean of
      false: (h:dword);
      true:  (f:single);
  end;
begin
  Val('$'+ParamStr(1),tr.h);
  writeln(tr.f:0:4);
end.
