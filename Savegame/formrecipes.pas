unit formRecipes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids,
  tl2save;

type

  { TfmRecipes }

  TfmRecipes = class(TForm)
    sgRecipes: TStringGrid;
  private
    sg:TTL2SaveFile;

  public
    procedure FillGrid(asg:TTL2SaveFile);
  end;

var
  fmRecipes: TfmRecipes;

implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

procedure TfmRecipes.FillGrid(asg:TTL2SaveFile);
var
  i:integer;
  lmod:TL2ID;
begin
 sgRecipes.BeginUpdate;
 sgRecipes.Clear;
 sgRecipes.RowCount:=Length(asg.Recipes);

 for i:=0 to High(asg.Recipes) do
 begin
   sgRecipes.Cells[1,i]:=GetTL2Recipes(asg.Recipes[i],lmod);
   sgRecipes.Cells[2,i]:=GetTL2Mod(lmod);
 end;

 sgRecipes.EndUpdate;

 sg:=asg;
end;

end.

