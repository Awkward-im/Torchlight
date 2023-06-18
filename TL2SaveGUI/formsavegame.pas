unit formSaveGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, ExtCtrls, Menus,
  ActnList, ComCtrls, tl2save, formMovies, formRecipes, formQuests,
  formButtons, formKeyBinding, formStatistic, formSettings, formModList,
  formChar, formStat, formMap, formUnits, formSkills, formItems;

type

  { TfmSaveFile }

  TfmSaveFile = class(TForm)
    ActionList: TActionList;
    actFileExit     : TAction;
    actFileOpen     : TAction;
    actFileSave     : TAction;
    actFileReload   : TAction;
    actFileCheat    : TAction;
    actFileFixModded: TAction;
    ImageList: TImageList;
    imgIcons: TImageList;
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuFileOpen     : TMenuItem;
    mnuFileSave     : TMenuItem;
    mnuFileReload   : TMenuItem;
    mnuFileSep1     : TMenuItem;
    mnuFileCheat    : TMenuItem;
    mnuFileFixModded: TMenuItem;
    mnuFileSep2     : TMenuItem;
    mnuFileExit     : TMenuItem;
    MainPanel: TPanel;
    LeftPanel: TPanel;
    Splitter: TSplitter;
    tvSaveGame: TTreeView;

    procedure actFileFixModdedExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileReloadExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure actFileCheatExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure tvSaveGameSelectionChanged(Sender: TObject);
  private
    FFileName:string;
    SGEPage:TForm;

    FSettings  :TfmSettings;
    FMovies    :TfmMovies;
    FModList   :TfmModList;
    FRecipes   :TfmRecipes;
    FKeyBinding:TfmKeyBinding;
    FQuests    :TfmQuests;
    FStatistic :TfmStatistic;
    FMaps      :TfmMap;
    FChar      :TfmChar;
    FPet       :TfmChar;
    FStats     :TfmStat;
    FUnits     :TfmUnits;
    FSkills    :TfmSkills;
    FItems     :TfmItems;
    
    SGame:TTL2SaveFile;

    procedure ChangeTree(aselect:boolean);
    procedure CloseSaveGame;
    procedure CreateTree;
    function GetTVIndex: integer;
    procedure MakeBackup(const fname: string);
    procedure SettingsChanged;
  public

  end;

var
  fmSaveFile: TfmSaveFile;

implementation

{$R *.lfm}

uses
  LCLIntf,
  tl2db,
  unitGlobal,
  tl2base;

resourcestring
  rsSaveGameOpen = 'Open Savegame';
  rsSaveGameSave = 'Save Savegame';

  rsSettings   = 'Settings';
  rsSavegame   = 'Savegame';
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

  rsNoSaveGame = 'Can''t load savegame file';
//  rsNoBase = 'Can''t load database';
  rsPetNotFound   = 'Your pet type was not found in current mod list and was replaced by default one.';
  rsSorry         = 'Sorry, your character class ';
  rsClassNotFound = ' was not found for current mod list.'#13#10'Change it manually.';

const
  DefaultExt = '.dmp';

const
  idxSettings   =  0;
  idxSavegame   =  1;

  idxMovies     =  0;
  idxModList    =  1;
  idxKeyMapping =  2;
  idxCharacter  =  3;
  idxPlayerStat =  4;
  idxPets       =  5;
  idxMaps       =  6;
  idxQuests     =  7;
  idxRecipes    =  8;
  idxStatistic  =  9;

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
    Items.AddChild(lroot,rsMovies);
    Items.AddChild(lroot,rsModList);
    Items.AddChild(lroot,rsKeyMapping);
    lNode:=Items.AddChild(lroot,rsCharacter);
    Items.AddChild(lNode,rsSkills);
    Items.AddChild(lNode,rsItems);
    Items.AddChild(lroot,rsPlayerStat);
    Items.AddChild(lroot,rsPets);
    Items.AddChild(lroot,rsMaps);
    Items.AddChild(lroot,rsQuests);
    Items.AddChild(lroot,rsRecipes);
    Items.AddChild(lroot,rsStatistic);
    lroot.Expanded:=true;
  end;
end;

procedure TfmSaveFile.ChangeTree(aselect:boolean);
var
  lNode,lSubNode:TTreeNode;
  ls:string;
  i,lcnt: integer;
  lshowall:boolean;
begin
  lNode:=tvSaveGame.Items[idxSavegame];
  lNode.Visible:=true;
  lNode.Items[idxCharacter].Data:=pointer(SGame.CharInfo);
  lNode.Items[idxPets     ].Data:=pointer(SGame.PetInfo[0]);
  lNode.Items[idxMaps     ].Data:=pointer(SGame.Maps[0]);
  lNode.Items[idxQuests   ].Data:=pointer(SGame.Quests);
  lNode.Items[idxStatistic].Data:=pointer(SGame.Stats);

  lshowall:=fmSettings.cbShowAll.Checked;
  lNode.Items[idxCharacter ].Items[1].Visible:=lshowall;
  lNode.Items[idxKeyMapping].Visible:=lshowall;
  lNode.Items[idxMovies    ].Visible:=lshowall;
//  lNode.Items[idxModList   ].Visible:=lshowall;
  lNode.Items[idxQuests    ].Visible:=lshowall;
  lNode.Items[idxRecipes   ].Visible:=lshowall;
  lNode.Items[idxMaps      ].Visible:=lshowall;
  lNode.Items[idxStatistic ].Visible:=lshowall;

  lcnt:=SGame.PetCount;
  lNode:=tvSaveGame.Items[idxSavegame].Items[idxPets];
  lNode.DeleteChildren;
  for i:=0 to lcnt-1 do
  begin
    lSubNode:=tvSaveGame.Items.AddChild(lNode,SGame.PetInfo[i].Name);
    lSubNode.Data:=pointer(SGame.PetInfo[i]);
    if lshowall then
      tvSaveGame.Items.AddChild(lSubNode,rsItems);
  end;

  lcnt:=SGame.MapCount;
  lNode:=tvSaveGame.Items[idxSavegame].Items[idxMaps];
  lNode.DeleteChildren;
  for i:=0 to lcnt-1 do
  begin
    ls:=SGame.Maps[i].Name;
    if SGame.Maps[i].Number>0 then
      ls:=ls+' ['+IntToStr(SGame.Maps[i].Number)+']';
    lSubNode:=tvSaveGame.Items.AddChild(lNode,ls);
    lSubNode.Data:=pointer(SGame.Maps[i]);
    if lshowall then
    begin
      tvSaveGame.Items.AddChild(lSubNode,rsUnits);
      tvSaveGame.Items.AddChild(lSubNode,rsProps);
      if Length(SGame.Maps[i].QuestItems)>0 then
        tvSaveGame.Items.AddChild(lSubNode,rsQItem);
    end;
  end;

  tvSaveGame.Items[idxSavegame].Visible:=true;
  if aselect then
    tvSaveGame.Select(tvSaveGame.Items[idxSavegame].Items[idxCharacter]);

end;

//===== Form =====

procedure TfmSaveFile.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
//  if FSettings.DBState=SQLITE_OK then FreeBases;
  ClearGameGlobals;
  SGame.Free;
end;

procedure TfmSaveFile.SettingsChanged;
begin
  ChangeTree(false);
end;

procedure TfmSaveFile.FormCreate(Sender: TObject);
{
var
  i:integer;
}
begin
  fmButtons:=TfmButtons.Create(Self);
  fmButtons.Parent:=MainPanel;
  fmButtons.Align :=alTop;

  FSettings:=TfmSettings.Create(Self);
  FSettings.Parent:=MainPanel;
  FSettings.Align :=alClient;
  FSettings.OnSettingsChanged:=@SettingsChanged;

//  {i:=}LoadBases(FSettings.edDBFile.Text);
//  if i<>0 then ShowMessage(rsNoBase+' '+IntToStr(i));

  FItems :=TfmItems .Create(Self); FItems .Parent:=MainPanel; FItems .Align:=alClient;
  FSkills:=TfmSkills.Create(Self); FSkills.Parent:=MainPanel; FSkills.Align:=alClient;
  FChar  :=TfmChar.Create(Self,ciPlayer); FChar.Parent:=MainPanel; FChar.Align:=alClient; FChar.SkillForm:=FSkills;
  FPet   :=TfmChar.Create(Self,ciPet   ); FPet .Parent:=MainPanel; FPet .Align:=alClient;

  fmButtons.Visible:=true;

  CreateTree;

  if ParamCount()>0 then
  begin
    FFileName:=ParamStr(1);
    actFileReloadExecute(Sender);
  end;
end;

procedure TfmSaveFile.CloseSaveGame;
begin
  if SGEPage<>nil then SGEPage.Visible:=false;
  SGEPage:=nil;

  FreeAndNil(FMovies);
  FreeAndNil(FModList);
  FreeAndNil(FRecipes);
  FreeAndNil(FKeyBinding);
  FreeAndNil(FQuests);
  FreeAndNil(FStatistic);
  FreeAndNil(FMaps);
  FreeAndNil(FStats);
  FreeAndNil(FUnits);

  SGame.Free;
end;

//===== Actions =====

procedure TfmSaveFile.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  //!! check if savegame already opened and changed

  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Title  :=rsSaveGameOpen;
    OpenDialog.Options:=[ofFileMustExist];
    OpenDialog.InitialDir:=FSettings.edSaveDir.Text;

    if OpenDialog.Execute then
    begin
      FFileName:=OpenDialog.FileName;
      actFileReloadExecute(Sender);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfmSaveFile.actFileReloadExecute(Sender: TObject);
{
var
  i:integer;
}
begin
  if FSettings.cbReloadDB.Checked then
  begin
    if FSettings.DBState=0 then FreeBases;
    FSettings.DBState:=LoadBases(FSettings.edDBFile.Text);
  end
  else if FSettings.DBState<>0 then
    FSettings.DBState:=LoadBases(FSettings.edDBFile.Text);

  try
    ClearGameGlobals;
    CloseSaveGame;

    SGame:=TTL2SaveFile.Create;
    SGame.LoadFromFile(FFileName);
    SGame.Parse();
    SetFilter(SGame.BoundMods);
    LoadGameGlobals;
{
    for i:=0 to MainPanel.ControlCount-1 do
    begin
      if MainPanel.Controls[i] is TForm then
        PostMessage(TForm(MainPanel.Controls[i]).Handle,LM_TL2_COMMAND,TL2_INIT,0);
    end;
}
    FChar.Configured:=false;

    Caption:='  '+FFileName;

    ChangeTree(true);

    actFileReload   .Enabled:=true;
    actFileSave     .Enabled:=true;
    actFileCheat    .Enabled:=true;
    actFileFixModded.Enabled:=true;
  except
    ShowMessage(rsNoSaveGame+' '+FFileName);
  end;
end;

procedure TfmSaveFile.MakeBackup(const fname:string);
var
  ldir,ls:string;
begin
  ldir:=ExtractFilePath(fname)+'\Backup';
  if not DirectoryExists(ldir) then
    MkDir(ldir);
  ls:=StringReplace(TimeToStr(Time()),':','-',[rfReplaceAll]);
  RenameFile(fname,ldir+'\'+ExtractFileName(fname)+'.'+ls);
end;

procedure TfmSaveFile.actFileSaveExecute(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog:=TSaveDialog.Create(nil);
  try
    SaveDialog.Title     :=rsSaveGameSave;
    SaveDialog.Options   :=SaveDialog.Options+[ofOverwritePrompt];
    SaveDialog.DefaultExt:='.SVB';
    SaveDialog.InitialDir:=FSettings.edSaveDir.Text;
    if SaveDialog.Execute then
    begin
      if (FileExists(SaveDialog.FileName)) and fmSettings.cbBackup.Checked then
        MakeBackup(SaveDialog.FileName);

      SGame.Prepare;
      SGame.SaveToFile(SaveDialog.FileName);

      Caption:='  '+FFileName;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TfmSaveFile.actFileCheatExecute(Sender: TObject);
begin
  if SGame<>nil then
  begin
    if SGame.ClearCheat then
      Caption:='* '+FFileName;
    tvSaveGameSelectionChanged(Sender);
  end;
end;

procedure TfmSaveFile.actFileFixModdedExecute(Sender: TObject);
var
  i:integer;
begin
  if SGame<>nil then
  begin
    if not SGame.CharInfo.CheckForMods(SGame.BoundMods) then
    begin
      ShowMessage(rsSorry+GetTL2Class(SGame.CharInfo.ID)+rsClassNotFound);
      exit;
    end;
    for i:=0 to SGame.PetCount-1 do
      if not SGame.PetInfo[i].CheckForMods(SGame.BoundMods) then
      begin
        ShowMessage(rsPetNotFound);
      end;

    SGame.FixModdedItems;

    Caption:='* '+FFileName;

    tvSaveGameSelectionChanged(Sender);
  end;
end;

procedure TfmSaveFile.actFileExitExecute(Sender: TObject);
begin
  Close;
end;

function TfmSaveFile.GetTVIndex:integer;
begin
  result:=-1;

  if tvSaveGame.Selected=nil then
    exit;

  case tvSaveGame.Selected.level of
    0: if tvSaveGame.Selected.Index<>idxSettings then
      result:=idxCharacter;
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

  //--- Buttons
  fmButtons.btnExport.Enabled:=(tvSaveGame.Selected<>nil) and (tvSaveGame.Selected.Data<>nil);
  fmButtons.btnImport.Enabled:=false;
  fmButtons.Offset:=-1;
  fmButtons.Ext   :=DefaultExt;
  if (tvSaveGame.Selected<>nil) then
  begin
    fmButtons.Name  :=tvSaveGame.Selected.Text;
    fmButtons.SClass:=TL2BaseClass(tvSaveGame.Selected.Data);
  end
  else
  begin
    fmButtons.Name  :='';
    fmButtons.SClass:=nil;
  end;

  if SGEPage<>nil then
    SGEPage.Visible:=false;

  case lidx of
    -1: begin
      SGEPage:=FSettings;
    end;

    // single, have editable data (manual)
    idxMovies: begin
      if FMovies=nil then
      begin
        FMovies:=TfmMovies.Create(Self);
        FMovies.Parent:=MainPanel;
        FMovies.Align :=alClient;
        FMovies.FillInfo(SGame);
      end;
      SGEPage:=FMovies;
    end;

    // single, have editable data
    idxModList: begin
      if FModList=nil then
      begin
        FModList:=TfmModList.Create(Self);
        FModList.Parent:=MainPanel;
        FModList.Align :=alClient;
        FModList.FillInfo(SGame);
      end;
      SGEPage:=FModList;
    end;

    // single
    idxKeyMapping: begin
      if FKeyBinding=nil then
      begin
        FKeyBinding:=TfmKeyBinding.Create(Self);
        FKeyBinding.Parent:=MainPanel;
        FKeyBinding.Align :=alClient;
        FKeyBinding.FillInfo(SGame);
      end;
      SGEPage:=FKeyBinding;
    end;

    // single, have editable data (manual)
    idxPlayerStat: begin
      if FStatistic=nil then
      begin
        FStatistic:=TfmStatistic.Create(Self);
        FStatistic.Parent:=MainPanel;
        FStatistic.Align :=alClient;
        FStatistic.FillInfo(SGame);
      end;
      SGEPage:=FStatistic;
    end;

    // single, have editable data (manual)
    idxCharacter: begin
      case tvSaveGame.Selected.level of
        2: lidx:=tvSaveGame.Selected.Index;
        3: lidx:=tvSaveGame.Selected.Parent.Index;
      else
        lidx:=0;
      end;
      case tvSaveGame.Selected.level of
        1: begin
          fmButtons.Offset:=SGame.CharInfo.DataOffset;
          FChar.FillInfo(SGame.CharInfo, SGame);
          SGEPage:=FChar;
        end;

        2: begin
          case lidx of
            0: begin
              FSkills.RefreshInfo();
              SGEPage:=FSkills;
            end;

            1: begin
              FItems.FillInfo(SGame.CharInfo.Items, SGame.CharInfo);
              SGEPage:=FItems;
            end;
          end;
        end;
      end;
    end;

    // have editable data (manual)
    idxPets: begin
      fmButtons.btnImport.Enabled:=true;
      case tvSaveGame.Selected.level of
        2: lidx:=tvSaveGame.Selected.Index;
        3: lidx:=tvSaveGame.Selected.Parent.Index;
      else
        lidx:=0;
      end;
      case tvSaveGame.Selected.level of
        1,2: begin
          fmButtons.Offset:=SGame.PetInfo[lidx].DataOffset;
          FPet.FillInfo(SGame.PetInfo[lidx]);
          SGEPage:=FPet;
        end;
        3: begin
          FItems.FillInfo(SGame.PetInfo[lidx].Items, SGame.PetInfo[lidx]);
          SGEPage:=FItems;
        end;
      end;
    end;

    idxMaps: begin
      case tvSaveGame.Selected.level of
        2: lidx:=tvSaveGame.Selected.Index;
        3: lidx:=tvSaveGame.Selected.Parent.Index;
      else
        lidx:=0;
      end;
      case tvSaveGame.Selected.level of
        1,2: begin
          if FMaps=nil then
          begin
            FMaps:=TfmMap.Create(Self);
            FMaps.Parent:=MainPanel;
            FMaps.Align :=alClient;
          end;
          FMaps.FillInfo(SGame,lidx);
          fmButtons.Offset:=SGame.Maps[lidx].DataOffset;
          SGEPage:=FMaps;
        end;
        3: begin
          case tvSaveGame.Selected.Index of
            0: begin
              if FUnits=nil then
              begin
                FUnits:=TfmUnits.Create(Self);
                FUnits.Parent:=MainPanel;
                FUnits.Align :=alClient;
              end;
              FUnits.FillInfo(SGame,lidx);
              SGEPage:=FUnits;
            end;
            1: begin
              FItems.FillInfo(SGame.Maps[lidx].PropList);
              SGEPage:=FItems;
            end;
            2: begin
              FItems.FillInfo(SGame.Maps[lidx].QuestItems);
              SGEPage:=FItems;
            end;
          end;
        end;
      end;
    end;

    // single, have editable data
    idxQuests: begin
      if FQuests=nil then
      begin
        fmButtons.Offset:=SGame.Quests.DataOffset; //!!
        FQuests:=TfmQuests.Create(Self);
        FQuests.Parent:=MainPanel;
        FQuests.Align :=alClient;
        FQuests.FillInfo(SGame);
      end;
      SGEPage:=FQuests;
    end;

    // single, have editable data
    idxRecipes: begin
      if FRecipes=nil then
      begin
        FRecipes:=TfmRecipes.Create(Self);
        FRecipes.Parent:=MainPanel;
        FRecipes.Align :=alClient;
        FRecipes.FillInfo(SGame);
      end;
      SGEPage:=FRecipes;
    end;

    // single, have editable data
    idxStatistic: begin
      if FStats=nil then
      begin
        fmButtons.Offset:=SGame.Stats.DataOffset; //!!
        FStats:=TfmStat.Create(Self);
        FStats.Parent:=MainPanel;
        FStats.Align :=alClient;
        FStats.FillInfo(SGame);
      end;
      SGEPage:=FStats;
    end;
  end;
  if SGEPage<>nil then
    SGEPage.Visible:=true;
end;

end.
