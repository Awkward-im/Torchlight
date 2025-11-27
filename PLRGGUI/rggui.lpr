program rggui;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, lazopenglcontext,
  fmGUI in 'GUI.Default\fmGUI.pas',
  rggui.core
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;

  LoadCoreSettings;
//  if cfgGUIPlugin='' then
    Application.CreateForm(TRGGUIForm, RGGUIForm);

  Application.Run;
end.

