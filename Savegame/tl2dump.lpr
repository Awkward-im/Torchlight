program tl2dump;

{$mode objfpc}{$H+}

uses tl2save,tl2db;

var
  tr:TTL2SaveFile;
begin
  LoadBases;
  tr:=TTL2SaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.Parse();

//  tr.Prepare;
//  tr.SaveToFile(ParamStr(1)+'.bin');
  tr.Free;
end.

