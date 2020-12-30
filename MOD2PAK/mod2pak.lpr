program mod2pak;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Dialogs, Forms, SysUtils,formmod2pak
  { you can add units after this };

{$R *.res}

procedure convert;
var
  lsi,lso:string;
begin
  lsi:=ParamStr(1);
  if ParamCount()=1 then
      lso:=ChangeFileExt(lsi,'.PAK')
    else
      lso:=ParamStr(2);
  if Split(lsi,lso) then
    ShowMessage('File '+lsi+' converted to '+lso);
end;

begin
{
  if ParamCount()>0 then
  begin
    convert;
    Halt;
  end;
}
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfmMod2Pak, fmMod2Pak);
  Application.Run;
end.

