uses
  rgio.raw,
  rgio.text;

begin
  BuildTextFile(ParseRAWFile(ParamStr(1)),'out.txt');
end.