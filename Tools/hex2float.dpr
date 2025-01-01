var
  tr:record
    case boolean of
      false: (h:dword);
      true:  (f:single);
  end;
begin
  tr.h:=$B81A3A0F;
  writeln(tr.f:0:4);
end.
