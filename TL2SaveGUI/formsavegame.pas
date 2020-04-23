unit formSaveGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, ExtCtrls,
  Menus, ActnList, ComCtrls, tl2save, formMovies, formRecipes, formQuests,
  formKeyBinding, formStatistic, formCommon;

type

  { TfmSaveFile }

  TfmSaveFile = class(TForm)
    actFileExit: TAction;
    actFileOpen: TAction;
    actFileSave: TAction;
    actExport: TAction;
    actImport: TAction;
    ActionList: TActionList;
    btnExport: TButton;
    btnImport: TButton;
    ImageList: TImageList;
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuFileOpen: TMenuItem;
    mnuFileSave: TMenuItem;
    mnuFileSep1: TMenuItem;
    mnuFileExit: TMenuItem;
    MainPanel: TPanel;
    LeftPanel: TPanel;
    PageControl: TPageControl;
    pnlTop: TPanel;
    Splitter: TSplitter;
    tvSaveGame: TTreeView;
    procedure actExportExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure tvSaveGameSelectionChanged(Sender: TObject);
  private
    FCommon:TfmCommon;
    FMovies:TfmMovies;
    FRecipes:TfmRecipes;
    FKeyBinding:TfmKeyBinding;
    FQuests:TfmQuests;
    FStatistic:TfmStatistic;
    
    SGame:TTL2SaveFile;
    procedure ChangeTree;
    procedure CreateTree;
    function GetTVIndex: integer;
  public

  end;

var
  fmSaveFile: TfmSaveFile;

implementation

{$R *.lfm}

uses
  tl2db,
  tl2base;

resourcestring
  rsSaveGameOpen = 'Open Savegame';
  rsExportData   = 'Export data';

  rsSavegame   = 'Savegame';
  rsCommon     = 'Common';
  rsMovies     = 'Movies';
  rsModList    = 'Mod list';
  rsKeyMapping = 'KeyMapping';
  rsCharacter  = 'Character';
  rsPlayerStat = 'Player statistic';
  rsPets       = 'Pets and allies';
  rsMaps       = 'Maps';
  rsQuests     = 'Quests';
  rsRecipes    = 'Recipes';
  rsStatistic  = 'Global statistic';

const
  DefaultExt = '.dmp';

const
  idxCommon     =  0;
  idxMovies     =  1;
  idxModList    =  2;
  idxKeyMapping =  3;
  idxCharacter  =  4;
  idxPlayerStat =  5;
  idxPets       =  6;
  idxMaps       =  7;
  idxQuests     =  8;
  idxRecipes    =  9;
  idxStatistic  = 10;

  { TfmSaveFile }

//===== Tree =====

procedure TfmSaveFile.CreateTree;
var
  lroot:TTreeNode;
begin
  with tvSaveGame do
  begin
    Items.Clear;
    lroot:=Items.AddFirst(nil,rsSavegame);
    Items.AddChild(lroot,rsCommon);
    Items.AddChild(lroot,rsMovies);
    Items.AddChild(lroot,rsModList);
    Items.AddChild(lroot,rsKeyMapping);
    Items.AddChild(lroot,rsCharacter);
    Items.AddChild(lroot,rsPlayerStat);
    Items.AddChild(lroot,rsPets);       // ??
    Items.AddChild(lroot,rsMaps);       // ??
    Items.AddChild(lroot,rsQuests);
    Items.AddChild(lroot,rsRecipes);
    Items.AddChild(lroot,rsStatistic);  // fixed amount
    lroot.Expanded:=true;
  end;
end;

procedure TfmSaveFile.ChangeTree;
var
  lNode,lMapNode:TTreeNode;
  i,lcnt: integer;
begin
  lNode:=tvSaveGame.Items[0];
  lNode.Items[idxCharacter].Data:=pointer(SGame.CharInfo);
  lNode.Items[idxPets     ].Data:=pointer(SGame.PetInfo[0]);
  lNode.Items[idxMaps     ].Data:=pointer(SGame.Maps[0]);
  lNode.Items[idxQuests   ].Data:=pointer(SGame.Quests);
  lNode.Items[idxStatistic].Data:=pointer(SGame.Stats);


  lcnt:=SGame.PetCount;
  lNode:=tvSaveGame.Items[0].Items[idxPets];
  lNode.DeleteChildren;
  if lcnt>1 then
  begin
    for i:=0 to lcnt-1 do
    begin
      (tvSaveGame.Items.AddChild(lNode,'pet_'+IntToStr(i))).Data:=pointer(SGame.PetInfo[i]);
    end;
  end;

  lcnt:=SGame.MapCount;
  lNode:=tvSaveGame.Items[0].Items[idxMaps];
  lNode.DeleteChildren;
  if lcnt>1 then
  begin
    for i:=0 to lcnt-1 do
    begin
      lMapNode:=tvSaveGame.Items.AddChild(lNode,'map_'+IntToStr(i));
      lMapNode.Data:=pointer(SGame.Maps[i]);
      tvSaveGame.Items.AddChild(lMapNode,'units');
      tvSaveGame.Items.AddChild(lMapNode,'props');
    end;
  end;
  tvSaveGame.Enabled:=true;
  tvSaveGame.Select(tvSaveGame.Items[0]);
end;

//===== Form =====

procedure TfmSaveFile.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SGame.Free;
end;

procedure TfmSaveFile.FormCreate(Sender: TObject);
begin
  FCommon    :=TfmCommon    .Create(Self); FCommon    .Parent:=MainPanel;
  FMovies    :=TfmMovies    .Create(Self); FMovies    .Parent:=MainPanel;
  FRecipes   :=TfmRecipes   .Create(Self); FRecipes   .Parent:=MainPanel;
  FKeyBinding:=TfmKeyBinding.Create(Self); FKeyBinding.Parent:=MainPanel;
  FQuests    :=TfmQuests    .Create(Self); FQuests    .Parent:=MainPanel;
  FStatistic :=TfmStatistic .Create(Self); FStatistic .Parent:=MainPanel;
  
  CreateTree;
  LoadBases;
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
      SGame.Free;

      SGame:=TTL2SaveFile.Create;
      SGame.LoadFromFile(OpenDialog.FileName);
      SGame.Parse();
      ChangeTree;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfmSaveFile.actFileExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfmSaveFile.actExportExecute(Sender: TObject);
var
  ldlg:TSaveDialog;
  lclass:TL2BaseClass;
  ls:string;
  lidx:integer;
begin
  lidx:=GetTVIndex;
  ls:=tvSaveGame.Selected.Text;

  lclass:=TL2BaseClass(tvSaveGame.Selected.Data);

  ldlg:=TSaveDialog.Create(nil);
  try
    ldlg.FileName  :=ls;
    ldlg.DefaultExt:=DefaultExt;
    ldlg.Title     :=rsExportData;
    ldlg.Options   :=ldlg.Options+[ofOverwritePrompt];
    if ldlg.Execute then
      lclass.ToFile(ldlg.FileName);
  finally
    ldlg.Free;
  end;
end;

function TfmSaveFile.GetTVIndex:integer;
begin
  case tvSaveGame.Selected.level of
    0: result:=0;
    1: result:=tvSaveGame.Selected.Index;
    2: result:=tvSaveGame.Selected.Parent.Index;
    3: result:=idxMaps; // units and props are for maps now only
  else
  end;
end;

procedure TfmSaveFile.tvSaveGameSelectionChanged(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=GetTVIndex;

  actExport.Enabled:=tvSaveGame.Selected.Data<>nil;

  FCommon    .Visible:=false;
  FMovies    .Visible:=false;
  FRecipes   .Visible:=false;
  FKeyBinding.Visible:=false;
  FQuests    .Visible:=false;
  FStatistic .Visible:=false;

  case lidx of
    idxCommon: begin
      FCommon.FillInfo(SGame);
      FCommon.Visible:=true;
    end;

    idxMovies: begin
      FMovies.FillInfo(SGame);
      FMovies.Visible:=true;
    end;

    idxModList: begin
    end;

    idxKeyMapping: begin
      FKeyBinding.FillInfo(SGame);
      FKeyBinding.Visible:=true;
    end;

    idxCharacter: begin
//      FCharacter.FillInfo(SGame);
    end;

    idxPlayerStat: begin
      FStatistic.FillInfo(SGame);
      FStatistic.Visible:=true;
    end;

    idxPets: begin
//      .FillInfo(SGame);
    end;

    idxMaps: begin
//      .FillInfo(SGame);
    end;

    idxQuests: begin
      FQuests.FillInfo(SGame);
      FQuests.Visible:=true;
    end;

    idxRecipes: begin
      FRecipes.FillInfo(SGame);
      FRecipes.Visible:=true;
    end;

    idxStatistic: begin
//      FStats.FillInfo(SGame);
    end;
  end;
end;

end.

