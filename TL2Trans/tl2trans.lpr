program tl2trans;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols,
//  DefaultTranslator,
  tl2datamodule,TL2Unit
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TTL2DataModule, TL2DM);
  Application.CreateForm(TMainTL2TransForm, MainTL2TransForm);
  Application.Run;
end.

