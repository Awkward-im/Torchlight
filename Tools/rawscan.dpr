uses
  rgio.text,
  rgscan.raw;

begin
  BuildTextFile(ScanRaw('G:\Games\Torchlight 2\mods\Timewarpers\','UNITDATA'),'out.txt');
end.