unit formRecipes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls, Buttons,
  tl2save, rgglobal;

type

  { TfmRecipes }

  TfmRecipes = class(TForm)
    bbUpdate: TBitBtn;
    bbClear: TBitBtn;
    btnDeleteWrong: TButton;
    btnLearnAll   : TButton;
    cbJustActual: TCheckBox;
    cbHaveTitle: TCheckBox;
    sgRecipes: TStringGrid;
    procedure bbClearClick(Sender: TObject);
    procedure bbUpdateClick(Sender: TObject);
    procedure btnLearnAllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure sgRecipesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    SGame:TTL2SaveFile;
    OldActualState   :boolean;
    OldHaveTitleState:boolean;

    procedure FillInfoInt(alist: TL2IdList);

  public
    procedure FillInfo(aSGame:TTL2SaveFile);

  end;


implementation

{$R *.lfm}

uses
  LCLType,
  addons,
  formSettings,
  INIfiles,
  tl2db;

const
  sRecipes    = 'Recipes';
  sJustActual = 'actual';
  sHaveTitle  = 'havetitle';

const
  colTitle = 1;
  colMod   = 2;
  colId    = 3;

procedure TfmRecipes.FormCreate(Sender: TObject);
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  cbJustActual.Checked:=config.ReadBool(sRecipes,sJustActual,true);
  cbHaveTitle .Checked:=config.ReadBool(sRecipes,sHaveTitle ,true);
  OldActualState   :=cbJustActual.Checked;
  OldHaveTitleState:=cbHaveTitle .Checked;

  config.Free;
end;

procedure TfmRecipes.FormDestroy(Sender: TObject);
var
  config:TIniFile;
begin
  if (OldActualState   <>cbJustActual.Checked) or
     (OldHaveTitleState<>cbHaveTitle .Checked) then
  begin
    config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
    config.WriteBool(sRecipes,sJustActual,cbJustActual.Checked);
    config.WriteBool(sRecipes,sHaveTitle ,cbHaveTitle .Checked);

    config.UpdateFile;
    config.Free;
  end;
end;

procedure TfmRecipes.sgRecipesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key=VK_DELETE) then
  begin
    bbUpdate.Enabled:=DeleteSelectedRows(sgRecipes);
  end;
end;

procedure TfmRecipes.bbClearClick(Sender: TObject);
begin
  FillInfoInt(nil);
  bbUpdate.Enabled:=true;
end;

procedure TfmRecipes.btnLearnAllClick(Sender: TObject);
begin
  FillInfoInt(GetRecipesList(cbJustActual.Checked, cbHaveTitle.Checked));
  bbUpdate.Enabled:=true;
end;

procedure TfmRecipes.bbUpdateClick(Sender: TObject);
var
  lRecipes:TL2IdList;
  ls:string;
  i:integer;
begin
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;

  lRecipes:=SGame.Recipes;
  SetLength(lRecipes,sgRecipes.RowCount-1);
  for i:=1 to sgRecipes.RowCount-1 do
  begin
    lRecipes[i-1]:=StrToInt64(sgRecipes.Cells[colId,i]);
  end;
  SGame.Recipes:=lRecipes;
  bbUpdate.Enabled:=false;
end;

procedure TfmRecipes.FillInfoInt(alist:TL2IdList);
var
  lmod:string;
  i:integer;
begin
  sgRecipes.BeginUpdate;
  sgRecipes.Clear;
  sgRecipes.RowCount:=Length(alist)+1;

  for i:=0 to High(alist) do
  begin
    sgRecipes.Cells[colTitle,i+1]:=GetTL2Recipes(alist[i],lmod);
    sgRecipes.Cells[colMod  ,i+1]:=GetTL2Mod(lmod);
    sgRecipes.Cells[colId   ,i+1]:=TextId(alist[i]);
  end;

  sgRecipes.EndUpdate;
end;

procedure TfmRecipes.FillInfo(aSGame:TTL2SaveFile);
begin
  FillInfoInt(aSGame.Recipes);

  sgRecipes.Columns[colId-1].Visible:=fmSettings.cbShowTech.Checked;

  bbUpdate.Enabled:=false;
  SGame:=aSGame;
end;

end.
