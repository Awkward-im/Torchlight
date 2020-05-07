unit formSaveGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, ExtCtrls,
  Menus, ActnList, ComCtrls, tl2save, formMovies, formRecipes, formQuests,
  formKeyBinding, formStatistic, formCommon, formSettings,
  formPet, formChar, formStat, formMap;

type

  { TfmSaveFile }

  TfmSaveFile = class(TForm)
    actFileExit: TAction;
    actFileOpen: TAction;
    actFileSave: TAction;
    actExport  : TAction;
    actImport  : TAction;
    ActionList: TActionList;
    btnExport: TButton;
    btnImport: TButton;
    ImageList: TImageList;
    lblOffset: TLabel;
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuFileOpen: TMenuItem;
    mnuFileSave: TMenuItem;
    mnuFileSep1: TMenuItem;
    mnuFileExit: TMenuItem;
    MainPanel: TPanel;
    LeftPanel: TPanel;
    pnlTop: TPanel;
    Splitter: TSplitter;
    tvSaveGame: TTreeView;
    procedure actExportExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure actImportExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure tvSaveGameSelectionChanged(Sender: TObject);
  private
    FSettings  :TfmSettings;
    FCommon    :TfmCommon;
    FMovies    :TfmMovies;
    FRecipes   :TfmRecipes;
    FKeyBinding:TfmKeyBinding;
    FQuests    :TfmQuests;
    FStatistic :TfmStatistic;
    FPets      :TfmPet;
    FMaps      :TfmMap;
    FChar      :TfmChar;
    FStats     :TfmStat;
    
    SGame:TTL2SaveFile;
    procedure ChangeTree;
    procedure CreateTree;
    function GetTVIndex: integer;
    procedure SetOffset(aofs: integer);
  public

  end;

var
  fmSaveFile: TfmSaveFile;

implementation

{$R *.lfm}

uses
  tl2db,
  tl2stream,
  tl2base;

resourcestring
  rsSaveGameOpen = 'Open Savegame';
  rsSaveGameSave = 'Save Savegame';
  rsExportData   = 'Export data';
  rsImportData   = 'Import data';

  rsSettings   = 'Settings';
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

  rsSkills = 'Skills';
  rsItems  = 'Items';
  rsUnits  = 'Units';
  rsProps  = 'Props';
  rsQItem  = 'Quest items';

const
  DefaultExt = '.dmp';

const
  idxSettings   =  0;
  idxSavegame   =  1;

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
  lroot,lNode:TTreeNode;
begin
  with tvSaveGame do
  begin
    Items.Clear;
    Items.AddFirst(nil,rsSettings);
    lroot:=Items.AddChild(nil,rsSavegame);
    lroot.Visible:=false;
    Items.AddChild(lroot,rsCommon);
    Items.AddChild(lroot,rsMovies);
    Items.AddChild(lroot,rsModList);
    Items.AddChild(lroot,rsKeyMapping);
    lNode:=Items.AddChild(lroot,rsCharacter);
    Items.AddChild(lNode,rsSkills);
    Items.AddChild(lNode,rsItems);
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
  lNode,lSubNode:TTreeNode;
  i,lcnt: integer;
begin
  lNode:=tvSaveGame.Items[idxSavegame];
  lNode.Visible:=true;
  lNode.Items[idxCharacter].Data:=pointer(SGame.CharInfo);
  lNode.Items[idxPets     ].Data:=pointer(SGame.PetInfo[0]);
  lNode.Items[idxMaps     ].Data:=pointer(SGame.Maps[0]);
  lNode.Items[idxQuests   ].Data:=pointer(SGame.Quests);
  lNode.Items[idxStatistic].Data:=pointer(SGame.Stats);

  lcnt:=SGame.PetCount;
  lNode:=tvSaveGame.Items[idxSavegame].Items[idxPets];
  lNode.DeleteChildren;
//  if lcnt>1 then
  begin
    for i:=0 to lcnt-1 do
    begin
      lSubNode:=tvSaveGame.Items.AddChild(lNode,'pet_'+IntToStr(i));
      lSubNode.Data:=pointer(SGame.PetInfo[i]);
      tvSaveGame.Items.AddChild(lSubNode,rsItems);
    end;
  end;

  lcnt:=SGame.MapCount;
  lNode:=tvSaveGame.Items[idxSavegame].Items[idxMaps];
  lNode.DeleteChildren;
//  if lcnt>1 then
  begin
    for i:=0 to lcnt-1 do
    begin
      lSubNode:=tvSaveGame.Items.AddChild(lNode,'map_'+IntToStr(i));
      lSubNode.Data:=pointer(SGame.Maps[i]);
      tvSaveGame.Items.AddChild(lSubNode,rsUnits);
      tvSaveGame.Items.AddChild(lSubNode,rsProps);
      if Length(SGame.Maps[i].QuestItems)>0 then
        tvSaveGame.Items.AddChild(lSubNode,rsQItem);
    end;
  end;
  tvSaveGame.Items[idxSavegame].Visible:=true;
  tvSaveGame.Select(tvSaveGame.Items[idxSavegame]);
end;

//===== Form =====

procedure TfmSaveFile.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SGame.Free;
end;

procedure TfmSaveFile.FormCreate(Sender: TObject);
begin
  FSettings  :=TfmSettings  .Create(Self); FSettings  .Parent:=MainPanel;
  FCommon    :=TfmCommon    .Create(Self); FCommon    .Parent:=MainPanel;
  FMovies    :=TfmMovies    .Create(Self); FMovies    .Parent:=MainPanel;
  FRecipes   :=TfmRecipes   .Create(Self); FRecipes   .Parent:=MainPanel;
  FKeyBinding:=TfmKeyBinding.Create(Self); FKeyBinding.Parent:=MainPanel;
  FQuests    :=TfmQuests    .Create(Self); FQuests    .Parent:=MainPanel;
  FStatistic :=TfmStatistic .Create(Self); FStatistic .Parent:=MainPanel;
  FPets      :=TfmPet       .Create(Self); FPets      .Parent:=MainPanel;
  FMaps      :=TfmMap       .Create(Self); FMaps      .Parent:=MainPanel;
  FChar      :=TfmChar      .Create(Self); FChar      .Parent:=MainPanel;
  FStats     :=TfmStat      .Create(Self); FStats     .Parent:=MainPanel;

  CreateTree;
  LoadBases;
end;

procedure TfmSaveFile.SetOffset(aofs:integer);
begin
  if aofs<0 then
    lblOffset.Caption:=''
  else
    lblOffset.Caption:='0x'+HexStr(aofs,8);
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

procedure TfmSaveFile.actFileSaveExecute(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog:=TSaveDialog.Create(nil);
  try
    SaveDialog.Title:=rsSaveGameSave;
    SaveDialog.DefaultExt:='.SVB';
    if SaveDialog.Execute then
    begin
      SGame.Prepare;
      SGame.SaveToFile(SaveDialog.FileName);
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TfmSaveFile.actFileExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfmSaveFile.actImportExecute(Sender: TObject);
var
  ldlg:TOpenDialog;
  lclass:TL2BaseClass;
  lstrm:TTL2Stream;
  ls:string;
  lidx:integer;
begin
  lidx:=GetTVIndex;

  lclass:=TL2BaseClass(tvSaveGame.Selected.Data);

  ldlg:=TOpenDialog.Create(nil);
  try
    ldlg.FileName  :='';
    ldlg.DefaultExt:=DefaultExt;
    ldlg.Title     :=rsImportData;
    ldlg.Options   :=ldlg.Options;
    if ldlg.Execute then
    begin
      lstrm:=TTL2Stream.Create;
      lstrm.LoadFromFile(ldlg.FileName);
      lstrm.Position:=0;
      lclass.Clear;
      lclass.LoadFromStream(lstrm);
      lstrm.Free;
      tvSaveGameSelectionChanged(Self);
    end;
  finally
    ldlg.Free;
  end;
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
      lclass.SaveToFile(ldlg.FileName);
  finally
    ldlg.Free;
  end;
end;

function TfmSaveFile.GetTVIndex:integer;
begin
  if tvSaveGame.Selected=nil then
  begin
    result:=-1;
    exit;
  end;

  case tvSaveGame.Selected.level of
    0: if tvSaveGame.Selected.Index=idxSettings then
      result:=-1
    else
      result:=idxCommon;
    1: result:=tvSaveGame.Selected.Index;
    2: result:=tvSaveGame.Selected.Parent.Index;
    3: result:=tvSaveGame.Selected.Parent.Parent.Index;
  else
  end;
end;

procedure TfmSaveFile.tvSaveGameSelectionChanged(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=GetTVIndex;

  actExport.Enabled:=(tvSaveGame.Selected<>nil) and (tvSaveGame.Selected.Data<>nil);
  actImport.Enabled:=(tvSaveGame.Selected<>nil) and (tvSaveGame.Selected.Data<>nil);

  FSettings  .Visible:=false;
  FCommon    .Visible:=false;
  FMovies    .Visible:=false;
  FPets      .Visible:=false;
  FMaps      .Visible:=false;
  FRecipes   .Visible:=false;
  FKeyBinding.Visible:=false;
  FQuests    .Visible:=false;
  FStatistic .Visible:=false;
  FChar      .Visible:=false;
  FStats     .Visible:=false;
  SetOffset(-1);

  case lidx of
    -1: begin
      FSettings.Visible:=true;
    end;

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
      FChar.FillInfo(SGame);
      FChar.Visible:=true;
    end;

    idxPlayerStat: begin
      FStatistic.FillInfo(SGame);
      FStatistic.Visible:=true;
    end;

    idxPets: begin
      case tvSaveGame.Selected.level of
        2: lidx:=tvSaveGame.Selected.Index;
        3: lidx:=tvSaveGame.Selected.Parent.Index;
      else
        lidx:=0;
      end;
      FPets.FillInfo(SGame,lidx);
      actImport.Enabled:=FPets.IsMainPet;
      FPets.Visible:=true;
    end;

    idxMaps: begin
      case tvSaveGame.Selected.level of
        2: lidx:=tvSaveGame.Selected.Index;
        3: lidx:=tvSaveGame.Selected.Parent.Index;
      else
        lidx:=0;
      end;
      FMaps.FillInfo(SGame,lidx);
      FMaps.Visible:=true;
    end;

    idxQuests: begin
      SetOffset(SGame.Quests.DataOffset);
      FQuests.FillInfo(SGame);
      FQuests.Visible:=true;
    end;

    idxRecipes: begin
      FRecipes.FillInfo(SGame);
      FRecipes.Visible:=true;
    end;

    idxStatistic: begin
      FStats.FillInfo(SGame);
      FStats.Visible:=true;
    end;
  end;
end;

end.
