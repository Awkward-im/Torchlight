uses
  rgio.raw,
  rgio.text;

begin
  BuildRawFile(ParseTextFile(Pchar(ParamStr(1))),'UNITDATA');  
end.
