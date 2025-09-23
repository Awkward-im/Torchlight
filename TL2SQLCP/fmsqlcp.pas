{TODO: Add existing mod check at Scan procedure}
unit fmSQLCP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ComCtrls, Grids, ExtCtrls, ListFilterEdit, unitlogform, rgglobal;

type

  { TFormSQLCP }

  TFormSQLCP = class(TForm)
    edModStat: TEdit;
    gdLanguages: TStringGrid;
    gdModStat: TStringGrid;
    ImageList: TImageList;
    lblCurLang: TLabel;
    lbMods: TListBox;
    lfeMods: TListFilterEdit;
    pnlRight: TPanel;
    pnlLeft: TPanel;
    pnlLower: TPanel;
    pnlUpper: TPanel;
    HSplitter: TSplitter;
    sbAdd: TSpeedButton;
    sbRemove: TSpeedButton;
    sbEdit: TSpeedButton;
    sbLoad: TSpeedButton;
    sbBuild: TSpeedButton;
    sbNew: TSpeedButton;
    sbSQL: TSpeedButton;
    sbLog: TSpeedButton;
    sbSave: TSpeedButton;
    sbSettings: TSpeedButton;
    sbDeleted: TSpeedButton;
    VSplitter: TSplitter;
    StatusBar: TStatusBar;
    procedure AddTrans(Sender: TObject);
    procedure Build(Sender: TObject);
    procedure sbDeletedClick(Sender: TObject);
    procedure sbSettingsClick(Sender: TObject);
    procedure ShowLog(Sender: TObject);
    procedure NewTrans(Sender: TObject);
    procedure SaveDB(Sender: TObject);
    procedure AddMod(Sender: TObject);
    procedure RemoveMod(Sender: TObject);
    procedure ShowSQLog(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DoStartEdit(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lbModsSelectionChange(Sender: TObject; User: boolean);
    procedure lfeModsAfterFilter(Sender: TObject);
  private
    FLogForm  :TfmLogForm;
    FSQLogForm:TfmLogForm;
    FModList:TDict64DynArray;
    doBreak:boolean;

    function AddLog(var adata: string): integer;
    function AddSQLog(var adata: string): integer;
    function OnFileScan(const fname: AnsiString; idx, atotal: integer): integer;
    procedure FillModList();
    procedure FillLangList();
    procedure UpdateStatus();

  public

  end;

var
  FormSQLCP: TFormSQLCP;

implementation

{$R *.lfm}

uses
  LCLType,
  TL2SettingsForm,
  TL2DelForm,
  sqlite3dyn,
  iso639,
  rgdb.text,
  tl2unit,
  tl2text,
  tlscan;

resourcestring
  rsOpenTranslation = 'Open translation file';
  rsOpenMod         = 'Open mod (pak) file';
  rsChooseLang      = 'Choose translation language';
//  rsUnknownLang     = 'Unknown language choosed';
//  rsYourLang        = 'Your lang title';
  rsLanguage        = 'Language:';
  rsStatus          = 'Total lines: %d | Unreferred lines: %d';
  rsStat            = 'Total lines: %d | Duplicates: %d | Different: %d | Unique: %d | Non-latin: %d'+
      ' | Files: %d | Tags: %d';
//  rsDblClick        = 'Double-Click to edit translation';
  rsStopScan        = 'Do you want to break scan?';
  rsSaveDone        = 'Database saved';
  rsCantSave        = 'Can''t save database';
  rsBuildDone       = 'Translation file generated';
  rsBuildFailed     = 'Translation file is NOT generated';
//  rsNothingToSave   = 'Nothing to save';
  rsTranslation     = 'Translation action';
  rsTransOp         = 'When translation exists';
  rsOverwrite       = 'Overwrite';
  rsPartial         = 'Overwrite partial';
  rsSkip            = 'Skip';
  rsHaveUnique      = 'Mod have %d unique strings.';
  rsDelete          = 'Are you sure to delete it?';


{ TFormSQLCP }

procedure TFormSQLCP.AddTrans(Sender: TObject);
var
  OpenDialog: TOpenDialog;
//  data:TTL2Translation;
  ls:AnsiString;
  i:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Title      :=rsOpenTranslation;
    OpenDialog.Options    :=[ofFileMustExist];
    OpenDialog.Filter     :='Translation file|*.DAT';
//    OpenDialog.InitialDir :=FSettings.edSaveDir.Text;

    if OpenDialog.Execute then
    begin
      if gdLanguages.RowCount<2 then
        ls:=InputBox(rsChooseLang,rsLanguage,'')
      else
        ls:=gdLanguages.Cells[1,gdLanguages.Row];

      if ls='' then exit;
      if PrepareLoadSQL(ls) then
      begin

        case QuestionDlg(rsTranslation,rsTransOp,mtConfirmation,
          [mrYesToAll,rsOverwrite,'IsDefault',
           mrYes     ,rsPartial,
           mrNo      ,rsSkip,
           mrCancel],0) of

           mrYesToAll: TransOp:=da_overwrite;
           mrYes     : TransOp:=da_compare;
           mrNo      : TransOp:=da_skip;
           mrCancel  : exit;
        end;
        Self.Caption:='Load translation';
        i:=tlscan.LoadAsText(OpenDialog.FileName);

        TransOp:=da_overwrite;
        RGLog.Add('Loaded '+IntToStr(i)+' lines');
        FillLangList();

        Self.Caption:='Check for similars';
        FillAllSimilars(ls);
        ShowMessage('Done!');

        Self.Caption:='';
        lbModsSelectionChange(Self,true);
      end;
{
      data.Init;
      data.LoadFromFile(OpenDialog.FileName);
      data.Lang:=iso639.GetLang(InputBox(rsChooseLang,rsLanguage,''));
      if data.lang='' then
        data.Lang:=InputBox(rsUnknownLang,rsYourLang,'unk');

      i:=CopyToBase(data,cbWithRef.Checked);
      RGLog.Add('Loaded '+IntToStr(i)+' lines');
      data.Free;
      ShowMessage('Done!');
      FillLangList();
}
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TFormSQLCP.Build(Sender: TObject);
begin
  if BuildTranslation('TRANSLATION.DAT','',true) then
    ShowMessage(rsBuildDone)
  else
    ShowMessage(rsBuildFailed);
  // maybe build from cache if curmod=modAll or just build mod, not all
  // well, it can be used in grid/editor, not CP
end;

procedure TFormSQLCP.sbDeletedClick(Sender: TObject);
begin
  with TDelForm.Create(Self) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TFormSQLCP.sbSettingsClick(Sender: TObject);
begin
//  TL2Settings.Visible:=not TL2Settings.Visible;
  TL2Settings.Parent     :=nil;
  TL2Settings.Align      :=alNone;
  TL2Settings.BorderStyle:=bsSizeable;
  TL2Settings.ShowModal;
end;

procedure TFormSQLCP.NewTrans(Sender: TObject);
begin
  CreateLangTable(InputBox(rsChooseLang,rsLanguage,''));
  FillLangList();
  lbModsSelectionChange(Self,true);
end;

procedure TFormSQLCP.RemoveMod(Sender: TObject);
var
  lmodid:Int64;
  lcnt:integer;
begin
  if lbMods.ItemIndex<2 then exit;

  lmodid:=GetModByName(lbMods.Items[lbMods.ItemIndex]);
  lcnt:=GetUniqueLineCount(lmodid);
  if lcnt>0 then
  begin
    if MessageDlg(Format(rsHaveUnique,[lcnt])+#13#10+rsDelete,
        mtWarning,[mbYes,mbNo],0)<>mrYes then exit;
  end
  else
    if MessageDlg(rsDelete,mtWarning,[mbYes,mbNo],0)<>mrYes then exit;
  lbMods.DeleteSelected;
end;

function TFormSQLCP.OnFileScan(const fname:AnsiString; idx, atotal:integer):integer;
begin
  if doBreak then
  begin
    if MessageDlg(rsStopScan,mtWarning,mbYesNo,0,mbNo)=mrYes then
      exit(2)
    else
      doBreak:=false;
  end;

  result:=0;
  if (idx mod 50)=0 then
  begin
    StatusBar.SimpleText:=IntToStr(idx)+' / '+IntToStr(atotal)+' | '+fname;
    Application.ProcessMessages;
  end;
end;

procedure TFormSQLCP.AddMod(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  lres,i:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Title      :=rsOpenMod;
    OpenDialog.Options    :=[ofAllowMultiSelect,ofFileMustExist];
    OpenDialog.Filter     :='Mod file|*.MOD;*.PAK';
//    OpenDialog.InitialDir :=FSettings.edSaveDir.Text;

    if OpenDialog.Execute then
    begin
      if PrepareScanSQL() then
      begin
        sbAdd .Enabled:=false;
        sbLoad.Enabled:=false;
        sbNew .Enabled:=false;
        sbSQL .Enabled:=false;
        sbSave.Enabled:=false;

        doBreak:=false;
        tlscan.OnFileScan:=@OnFileScan;
        for i:=0 to OpenDialog.Files.Count-1 do
        begin
          RGLog.Add('Scanning '+OpenDialog.Files[i]);
          Self.Caption:='Scanning ('+
             IntToStr(i+1)+'/'+IntToStr(OpenDialog.Files.Count)+') '+
             OpenDialog.Files[i];
          lres:=tlscan.Scan(OpenDialog.Files[i]);
          if lres<0 then
          begin
            RGLog.Add('Scan break');
            break;
          end;
          RGLog.Add('Checked '+IntToStr(lres)+' files');
        end;
        Self.Caption:='';
//        RGLog.Add('Remake Filter');
//        RemakeFilter();
        ShowMessage('Done!');
        FillModList();
        UpdateStatus();

        sbAdd .Enabled:=true;
        sbLoad.Enabled:=true;
        sbNew .Enabled:=true;
        sbSQL .Enabled:=true;
        sbSave.Enabled:=true;
      end;
    end;
  finally
    OpenDialog.Free;
  end;
end;

function TFormSQLCP.AddSQLog(var adata:string):integer;
begin
  FSQLogForm.memLog.Append(adata);
  adata:='';
  result:=0;
end;

function TFormSQLCP.AddLog(var adata:string):integer;
begin
  FLogForm.memLog.Append(adata);
  adata:='';
  result:=0;
end;

procedure TFormSQLCP.ShowSQLog(Sender: TObject);
begin
  if FSQLogForm=nil then
  begin
    FSQLogForm:=TfmLogForm.Create(Self);
    FSQLogForm.Caption:='SQL log';
    FSQLogForm.memLog.Text:=SQLog.Text;
    SQLog.OnAdd:=@AddSQLog;
  end;
  FSQLogForm.ShowOnTop;
end;

procedure TFormSQLCP.ShowLog(Sender: TObject);
begin
  if FLogForm=nil then
  begin
    FLogForm:=TfmLogForm.Create(Self);
    FLogForm.Caption:='Program log';
    FLogForm.memLog.Text:=RGLog.Text;
    RGLog.OnAdd:=@AddLog;
  end;
  FLogForm.ShowOnTop;
end;

procedure TFormSQLCP.SaveDB(Sender: TObject);
begin
  if TLSaveBase() then
    ShowMessage(rsSaveDone)
  else
    ShowMessage(rsCantSave);
end;

procedure TFormSQLCP.lbModsSelectionChange(Sender: TObject; User: boolean);
var
  lstat:TModStatistic;
  i:integer;
begin
  if lbMods.ItemIndex<0 then exit;

  lstat.modid:=FModList[IntPtr(lbMods.Items.Objects[lbMods.ItemIndex])].id;

  sbRemove.Enabled:=(lstat.modid<>modAll) and (lstat.modid<>modVanilla);

  GetModStatistic(lstat);
  edModSTat.Tag:=lstat.total;
  edModSTat.Text:=Format(rsStat,
    [lstat.total,lstat.dupes,lstat.total-lstat.dupes,lstat.unique,lstat.nation,
     lstat.files,lstat.tags]);
  gdModStat.BeginUpdate;
  gdModStat.Clear;
  gdModStat.RowCount:=1;
  for i:=0 to High(lstat.langs) do
  begin
    with lstat.langs[i] do
      gdModStat.InsertRowWithValues(i+1,
        [IntToStr(trans),IntToStr(part),lang,GetLangName(lang)]);
  end;
  gdModStat.EndUpdate();
  if Length(lstat.langs)>0 then
    gdModStat.Row:=1;
end;

procedure TFormSQLCP.lfeModsAfterFilter(Sender: TObject);
begin
  if lbMods.Items.Count>0 then lbMods.ItemIndex:=0;
end;

procedure TFormSQLCP.FillModList();
var
  i:integer;
begin
  lfeMods.FilteredListBox:=nil;
  lfeMods.Clear;

  GetModList(FModList,true);
  lbMods.Items.Clear;
  for i:=0 to High(FModList) do
    lbMods.Items.AddObject(FModList[i].value,TObject(IntPtr(i)));

  lfeMods.FilteredListBox:=lbMods;
  lfeMods.SortData:=true;
end;

procedure TFormSQLCP.FillLangList();
var
  llist:TDictDynArray;
  ls:string;
  i,lcnt:integer;
begin
  llist:=nil;

  gdLanguages.BeginUpdate;
  gdLanguages.Clear;
  lcnt:=GetLangList(llist);
  gdLanguages.RowCount:=1;
  for i:=0 to lcnt-1 do
  begin
    ls:=llist[i].value;
    gdLanguages.InsertRowWithValues(i+1,[IntToStr(llist[i].id),ls,GetLangName(ls)]);
  end;
  SetLength(llist,0);
  gdLanguages.EndUpdate();
  sbBuild.Enabled:=lcnt>0;
  if lcnt>0 then gdLanguages.Row:=1;
end;

procedure TFormSQLCP.UpdateStatus();
begin
  StatusBar.SimpleText:=Format(rsStatus,[GetLineCount(modAll),GetUnrefLineCount()]);
end;

procedure TFormSQLCP.FormCreate(Sender: TObject);
begin
  FLogForm  :=nil;
  FSQLogForm:=nil;

  TL2Settings:=TTL2Settings.Create(Self);

  SetProgramLanguage();
  TLOpenBase(true);
  FillLangList();
  FillModList();
  UpdateStatus();
end;

procedure TFormSQLCP.FormDestroy(Sender: TObject);
begin
  TLCloseBase(false);
  SetLength(FModList,0);
end;

procedure TFormSQLCP.DoStartEdit(Sender: TObject);
begin
  if (MainTL2TransForm=nil) and
     (lbMods.ItemIndex>=0) and
     (gdModStat.Row>0) and
     (edModSTat.Tag>0) then
  begin
    // to avoid multiply dblclicks
    MainTL2TransForm:=TMainTL2TransForm(1);

    CurMod:=FModList[IntPtr(lbMods.Items.Objects[lbMods.ItemIndex])].id;
    CurLang:=gdModStat.Cells[2,gdModStat.Row];

    MainTL2TransForm:=TMainTL2TransForm.Create(Self);
    MainTL2TransForm.ShowModal;
  end;
end;

procedure TFormSQLCP.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then
  begin
    doBreak:=true;
    Key:=0;
  end;
end;

end.

