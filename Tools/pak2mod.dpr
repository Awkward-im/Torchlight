uses RGPAK;
begin
  if ParamCount<1 then
  begin
    writeln('Use: PAK2MOD <filename>'#13#10'without extension');
    exit;
  end;
  RGPAKCombine('',ParamStr(1));
end.