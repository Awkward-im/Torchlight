unit formSaveGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  tl2save,
  formMovies,
  formRecipes,
  formKeyBinding,
  formStatistic;

type

  { TfmSaveFile }

  TfmSaveFile = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    keys: TButton;
    cbHardcore: TCheckBox;
    edClass: TEdit;
    edDifficulty: TEdit;
    edArea: TEdit;
    edNG: TEdit;
    edMap: TEdit;
    gbCharacter: TGroupBox;
    lblArea: TLabel;
    lblMap: TLabel;
    lblGameTime: TLabel;
    lblNG: TLabel;
    lblDifficulty: TLabel;
    lblClass: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure keysClick(Sender: TObject);
  private
    SGame:TTL2SaveFile;
  public

  end;

var
  fmSaveFile: TfmSaveFile;

implementation

{$R *.lfm}

uses
  tl2common,
  tl2db;

{ TfmSaveFile }


procedure TfmSaveFile.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SGame.Free;
end;

procedure TfmSaveFile.FormCreate(Sender: TObject);
begin
  LoadBases;
  SGame:=TTL2SaveFile.Create;
end;

procedure TfmSaveFile.Button2Click(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
//    OpenDialog.InitialDir:='';
//    OpenDialog.DefaultExt:='';
//    OpenDialog.Filter    :='';
    OpenDialog.Title     :='open savegame';
//    OpenDialog.Options   :=[];

    if OpenDialog.Execute then
    begin
      SGame.LoadFromFile(OpenDialog.FileName);
      SGame.Parse(ptstandard);

      edClass.Text:=SGame.ClassString;
      edDifficulty.Text:=GetDifficulty(ORD(SGame.Difficulty));
      cbHardcore.checked:=SGame.Hardcore;
      edNG.Text:=IntToStr(SGame.NewGameCycle);
      lblGameTime.Caption:=IntToStr(trunc(SGame.GameTime))+':'+
        IntToStr(Trunc(Frac(SGame.GameTime)*60));
      edMap .Text:=SGame.Map;
      edArea.Text:=SGame.Area;

    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfmSaveFile.Button1Click(Sender: TObject);
begin
  fmStatistic:=TfmStatistic.Create(nil);
  fmStatistic.FillStatistic(SGame);
  fmStatistic.Show;
end;

procedure TfmSaveFile.Button3Click(Sender: TObject);
begin
  fmMovies:=TfmMovies.Create(nil);
  fmMovies.FillGrid(SGame.Movies);
  fmMovies.Show;
end;

procedure TfmSaveFile.Button4Click(Sender: TObject);
begin
  fmRecipes:=TfmRecipes.Create(nil);
  fmRecipes.FillGrid(SGame);
  fmRecipes.Show;
end;

procedure TfmSaveFile.keysClick(Sender: TObject);
begin
  fmKeyBinding:=TfmKeyBinding.Create(nil);
  fmKeyBinding.FillGrid(SGame);
  fmKeyBinding.Show;
end;

end.

