program scanall;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, formscanall, RGDict, RGGlobal, RGIO.DAT, RGIO.Text, RGNode, RGPAK,
  RGScan, TL2Mod, textcache
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfmScan, fmScan);
  Application.Run;
end.

