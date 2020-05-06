unit formRecipes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  tl2save;

type

  { TfmRecipes }

  TfmRecipes = class(TForm)
    btnDeleteWrong: TButton;
    btnLearnAll: TButton;
    btnLearnAvail: TButton;
    sgRecipes: TStringGrid;
  private
    SGame:TTL2SaveFile;

  public
    procedure FillInfo(aSGame:TTL2SaveFile);

  end;


implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

procedure TfmRecipes.FillInfo(aSGame:TTL2SaveFile);
var
  i:integer;
  lmod:string;
begin
  sgRecipes.BeginUpdate;
  sgRecipes.Clear;
  sgRecipes.RowCount:=Length(aSGame.Recipes);

  for i:=0 to High(aSGame.Recipes) do
  begin
    sgRecipes.Cells[1,i]:=GetTL2Recipes(aSGame.Recipes[i],lmod);
    sgRecipes.Cells[2,i]:=GetTL2Mod(lmod);
  end;

  sgRecipes.EndUpdate;

  SGame:=aSGame;
end;

end.
