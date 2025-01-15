{$R ..\TL2Lib\dict.rc}

uses
  rgglobal,
  rgdictlayout;

type
  tt = array of PWideChar;
var
  info:TRGObject;
  pp:tt;
  ls:UnicodeString;
  i:integer;
begin
  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  info.init;
  info.Version:=verHob;
  pp:=tt(info.GetFuncArray);
  for i:=0 to High(pp) do
  begin
    ls:=UnicodeString(pp[i]);
    Writeln(RGHash(PWidechar(ls)),':',ls);
    Writeln(RGHash(PWidechar(UpCase(ls))),':',ls);
  end;
  pp:=tt(info.GetEventArray);
  for i:=0 to High(pp) do
  begin
    ls:=UnicodeString(pp[i]);
    Writeln(RGHash(PWidechar(ls)),':',ls);
    Writeln(RGHash(PWidechar(UpCase(ls))),':',ls);
  end;
end.