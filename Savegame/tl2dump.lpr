program tl2dump;

{$mode objfpc}{$H+}

uses tl2save,tl2common;

var
  tr:TTL2SaveFile;
begin
  tr:=TTL2SaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.Parse(ptlite);
  tr.Free;
end.

