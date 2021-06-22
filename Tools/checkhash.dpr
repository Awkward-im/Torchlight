uses rgpak;
begin
  writeln(HexStr(CalcPAKHash(ParamStr(1)),8));
end.
