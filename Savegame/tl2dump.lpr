program tl2dump;

{$mode objfpc}{$H+}

uses tl2save,tl2common,tl2db;

var
  tr:TTL2SaveFile;
begin
  LoadBases;
  tr:=TTL2SaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.Parse(ptstandard);
  tr.Free;
end.

