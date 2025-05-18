unit tl2about;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    bbOK: TBitBtn;
    lblVersion: TLabel;
    lblInfo: TLabel;
    lblUsed: TLabel;
    lblIdea: TLabel;
    lblCompiled: TLabel;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.lfm}

uses
  LazVersion;

{ TAboutForm }

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  lblVersion.Caption:='v.2.0';
  lblCompiled.Caption:=
    'Compiled at '+{$I %DATE%}+' '+{$I %TIME%}+
    ' with FreePascal v.'+{$I %FPCVERSION%}+
    #13#10'Lazarus v.'+laz_version;
end;

end.

