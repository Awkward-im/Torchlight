unit formSaveGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, ActnList, ComCtrls, tl2save, formMovies, formRecipes, formQuests,
  formKeyBinding, formStatistic;

type

  { TfmSaveFile }

  TfmSaveFile = class(TForm)
    actFileExit: TAction;
    actFileOpen: TAction;
    actFileSave: TAction;
    ActionList: TActionList;
    Button1: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    cbHardcore: TCheckBox;
    edArea: TEdit;
    edClass: TEdit;
    edDifficulty: TEdit;
    edMap: TEdit;
    edNG: TEdit;
    gbCharacter: TGroupBox;
    ImageList: TImageList;
    keys: TButton;
    lblArea: TLabel;
    lblClass: TLabel;
    lblDifficulty: TLabel;
    lblGameTime: TLabel;
    lblMap: TLabel;
    lblNG: TLabel;
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuFileOpen: TMenuItem;
    mnuFileSave: TMenuItem;
    mnuFileSep1: TMenuItem;
    mnuFileExit: TMenuItem;
    MainPanel: TPanel;
    LeftPanel: TPanel;
    Splitter: TSplitter;
    TreeView1: TTreeView;
    procedure actFileOpenExecute(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
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

//===== Actions =====

procedure TfmSaveFile.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  //!! check if savegame already opened and changed

  OpenDialog:=TOpenDialog.Create(nil);
  try
//    OpenDialog.InitialDir:='';
//    OpenDialog.DefaultExt:='';
//    OpenDialog.Filter    :='';
//    OpenDialog.Options   :=[];
    OpenDialog.Title:=rsSaveGameOpen;

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

procedure TfmSaveFile.Button5Click(Sender: TObject);
begin
  fmQuests:=TfmQuests.Create(nil);
  fmQuests.FillGrid(SGame);
  fmQuests.Show;
end;

procedure TfmSaveFile.keysClick(Sender: TObject);
begin
  fmKeyBinding:=TfmKeyBinding.Create(nil);
  fmKeyBinding.FillGrid(SGame);
  fmKeyBinding.Show;
end;

end.

