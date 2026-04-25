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
  DefaultTranslator,
//  fmGUI    in 'GUI.Default\fmGUI.pas',
  fmGUIM   in 'GUI.Modified\fmGUIM.pas',
  fmGUIAlt in 'GUI.Alt\fmGUIAlt.pas',
  RGGUI.Core
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
//  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;

  LoadCoreSettings;
{
  if cfgGUIPlugin='' then
    Application.CreateForm(TRGGUIForm , RGGUIForm)
  else 
}
  if (ParamCount=1) or (cfgGUIPlugin='1') then
    Application.CreateForm(TRGGUIMForm, RGGUIMForm)
  else //if cfgGUIPlugin='1' then
    Application.CreateForm(TRGGUI2Form, RGGUI2Form);
  Application.Run;
end.

