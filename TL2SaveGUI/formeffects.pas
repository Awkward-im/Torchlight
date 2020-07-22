unit formEffects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls;

type

  { TfmEffects }

  TfmEffects = class(TForm)
    lbAugments: TListBox;     lblAugments: TLabel;
    sgEffects : TStringGrid;  lblEffects : TLabel;
    sgStats   : TStringGrid;  lblStats   : TLabel;
  private

  public
    procedure UpdateWindow();

  end;

var
  fmEffects: TfmEffects;

implementation

{$R *.lfm}

procedure TfmEffects.UpdateWindow();
begin

end;

end.

