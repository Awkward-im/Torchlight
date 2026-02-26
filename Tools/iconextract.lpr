program iconextract;

{$mode objfpc}{$H+}
(*
{$IFDEF Console}
uses
  rgglobal,
  rgimageset;

var
  rg:TRGImageSet;
  fname:string;
begin
  if ParamCount=0 then exit;
  fname:=ParamStr(1);
  Chdir(ExtractPath(fname));
  rg.Init;
  if rg.ParseFromFile(fname) then
  begin
    writeln(rg.Extract(),' file(s) extracted');
  end;
  rg.Free;
end.
{$ELSE}
*)
uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Controls,
  Forms, lazcontrols,
  fmimageset;

{$R *.res}

var
  i:integer;
begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TFormImageset, FormImageset);
  FormImageset.BorderStyle:=bsSizeable;
  for i:=1 to ParamCount do
    FormImageset.FillList(ParamStr(i));
  Application.Run;
end.
//{$ENDIF}
