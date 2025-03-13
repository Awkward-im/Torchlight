unit formRecipes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls, Buttons,
  tlsave, rgglobal, Types;

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

    procedure bbClearClick    (Sender: TObject);
    procedure bbUpdateClick   (Sender: TObject);
    procedure btnLearnAllClick(Sender: TObject);
    procedure FormCreate (Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure sgRecipesDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure sgRecipesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

  private
    FSGame:TTLSaveFile;
    OldActualState   :boolean;
    OldHaveTitleState:boolean;
    FIcons :array of TPicture;

    procedure CreateIconList(alist: TL2IdList);
    procedure FillInfoInt(alist: TL2IdList);

  public
    procedure FillInfo(aSGame:TTLSaveFile);

  end;


implementation

{$R *.lfm}

uses
  LCLType,
  addons,
  formSettings,
  INIfiles,
  rgtrans,
  rgdb;

const
  sRecipes    = 'Recipes';
  sJustActual = 'actual';
  sHaveTitle  = 'havetitle';

const
  colIcon  = 0;
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

  FIcons:=nil;
end;

procedure TfmRecipes.FormDestroy(Sender: TObject);
var
  config:TIniFile;
  i:integer;
begin
  for i:=0 to High(FIcons) do FIcons[i].Free;
  SetLength(FIcons,0);

  if (OldActualState   <>cbJustActual.Checked) or
     (OldHaveTitleState<>cbHaveTitle .Checked) then
  begin
    config:=TMemIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
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

procedure TfmRecipes.bbUpdateClick(Sender: TObject);
var
  lRecipes:TL2IdList;
//  ls:string;
  i:integer;
begin
{
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;
}
  lRecipes:=FSGame.Recipes;
  SetLength(lRecipes,sgRecipes.RowCount-1);
  for i:=1 to sgRecipes.RowCount-1 do
  begin
    lRecipes[i-1]:=StrToInt64(sgRecipes.Cells[colId,i]);
  end;
  FSGame.Recipes:=lRecipes;
  FSGame.Modified:=true;
  bbUpdate.Enabled:=false;
end;

procedure TfmRecipes.btnLearnAllClick(Sender: TObject);
begin
  FillInfoInt(RGDBGetRecipesList(cbJustActual.Checked, cbHaveTitle.Checked));
  bbUpdate.Enabled:=true;
end;

procedure TfmRecipes.sgRecipesDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  lRect:TRect;
  bmp:TBitmap;
  idx:integer;
begin
  if (FIcons<>nil) and (aCol=colIcon) and (aRow>0) then
  begin
    idx:=IntPtr(sgRecipes.Objects[0,aRow]);
    if FIcons[idx]<>nil then
    begin
      bmp:=FIcons[idx].Bitmap;
      if bmp<>nil then
      begin
        lRect:=aRect;
        InflateRect(lRect,-1,-1);
        sgRecipes.Canvas.StretchDraw(lRect,bmp);
      end;
    end;
  end;
end;

procedure TfmRecipes.CreateIconList(alist:TL2IdList);
var
  ls,ls1:string;
  i:integer;
begin
  for i:=0 to High(FIcons) do FIcons[i].Free;

  if FSGame.GameVersion=verTL1 then
  begin
    SetLength(FIcons,0);
    exit;
  end;

  SetLength(FIcons,Length(alist));

  ls:=fmSettings.IconDir;
  for i:=0 to High(FIcons) do
  begin
    ls1:=RGDBGetRecipeIcon(alist[i]);
    if ls1='' then
      FIcons[i]:=nil
    else
    begin
      FIcons[i]:=TPicture.Create;
      try
        FIcons[i].LoadFromFile(SearchForFileName(ls,UpCase(ls1)));
      except
      end;
    end;
  end;
end;

procedure TfmRecipes.FillInfoInt(alist:TL2IdList);
var
  lmod:string;
  i:integer;
begin
  CreateIconList(alist);

  sgRecipes.BeginUpdate;
  sgRecipes.Clear;
  sgRecipes.RowCount:=Length(alist)+1;

  for i:=0 to High(alist) do
  begin
    sgRecipes.Objects[0,i+1]:=TObject(IntPtr(i));
    sgRecipes.Cells[colTitle,i+1]:=GetTranslation(fmSettings.Translation,RGDBGetRecipes(alist[i],lmod));
    sgRecipes.Cells[colMod  ,i+1]:=RGDBGetMod(lmod);
    sgRecipes.Cells[colId   ,i+1]:=TextId(alist[i]);
  end;

  sgRecipes.EndUpdate;
end;

procedure TfmRecipes.FillInfo(aSGame:TTLSaveFile);
begin
  FSGame:=aSGame;
  if FSGame.GameVersion=verTL1 then sgRecipes.Columns[colIcon].Visible:=false;
  FillInfoInt(aSGame.Recipes);

  sgRecipes.Columns[colId-1].Visible:=fmSettings.cbShowTech.Checked;

  bbUpdate.Enabled:=false;
end;

end.
