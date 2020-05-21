unit formEffects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls;

type

  { TfmEffects }

  TfmEffects = class(TForm)
    lbAugments: TListBox;  lblAugments: TLabel;
    sgEffects : TStringGrid;
    sgStats   : TStringGrid;
  private

  public

  end;

var
  fmEffects: TfmEffects;

implementation

{$R *.lfm}

end.

