unit fmSQLCP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ComCtrls, Grids, ListFilterEdit, unitlogform;

type

  { TFormSQLCP }

  TFormSQLCP = class(TForm)
    bbScanMod: TBitBtn;
    bbAddTrans: TBitBtn;
    bbSaveDB: TBitBtn;
    bbLog: TBitBtn;
    bbSQLog: TBitBtn;
    bbNewTrans: TBitBtn;
    bbGenerate: TBitBtn;
    edModStat: TEdit;
    gdLanguages: TStringGrid;
    lblCurLang: TLabel;
    lbMods: TListBox;
    lfeMods: TListFilterEdit;
    gdModStat: TStringGrid;
    StatusBar: TStatusBar;
    procedure bbAddTransClick(Sender: TObject);
    procedure bbGenerateClick(Sender: TObject);
    procedure bbLogClick(Sender: TObject);
    procedure bbNewTransClick(Sender: TObject);
    procedure bbSaveDBClick(Sender: TObject);
    procedure bbScanModClick(Sender: TObject);
    procedure bbSQLogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DoStartEdit(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lbModsSelectionChange(Sender: TObject; User: boolean);
    procedure lfeModsAfterFilter(Sender: TObject);
  private
    FLogForm  :TfmLogForm;
    FSQLogForm:TfmLogForm;
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
  sqlite3dyn,
  iso639,
  rgglobal,
  rgdb.text,
  tl2unit,
  tlscan;

resourcestring
  rsOpenTranslation = 'Open translation file';
  rsOpenMod         = 'Open mod (pak) file';
  rsChooseLang      = 'Choose translation language';
//  rsUnknownLang     = 'Unknown language choosed';
//  rsYourLang        = 'Your lang title';
  rsLanguage        = 'Language:';
  rsStatus          = 'Total lines: %d | Unreferred lines: %d';
  rsStat            = 'Total lines: %d | Duplicates: %d | Unique: %d | Files: %d | Tags: %d';
//  rsDblClick        = 'Double-Click to edit translation';
  rsStopScan        = 'Do you want to break scan?';
  rsSaveDone        = 'Database saved';
  rsCantSave        = 'Can''t save database';
  rsBuildDone       = 'Translation file generated';
  rsBuildFailed     = 'Translation file is NOT generated';
//  rsNothingToSave   = 'Nothing to save';


{ TFormSQLCP }

procedure TFormSQLCP.bbAddTransClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
//  data:TTL2Translation;
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
      if PrepareLoadSQL(InputBox(rsChooseLang,rsLanguage,'')) then
      begin
{
        case QuestionDlg(rsTranslation,rsTransOp,mtConfirmation,
          [mrYesToAll,rsOverwriteAll,'IsDefault',
           mrYes     ,rsOverwrite,
           mrNo      ,rsFixAll,
           mrCancel],0) of
}
        i:=tlscan.LoadAsText(OpenDialog.FileName);
        RGLog.Add('Loaded '+IntToStr(i)+' lines');
        ShowMessage('Done!');
        FillLangList();
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

procedure TFormSQLCP.bbGenerateClick(Sender: TObject);
begin
  if BuildTranslation('TRANSLATION.DAT','',true) then
    ShowMessage(rsBuildDone)
  else
    ShowMessage(rsBuildFailed);
  // maybe build from cache if curmod=-1 or just build mod, not all
  // well, it can be used in grid/editor, not CP
end;

procedure TFormSQLCP.bbNewTransClick(Sender: TObject);
begin
  CreateLangTable(InputBox(rsChooseLang,rsLanguage,''));
  FillLangList();
  lbModsSelectionChange(Self,true);
end;

function TFormSQLCP.OnFileScan(const fname:AnsiString; idx, atotal:integer):integer;
begin
  if doBreak then
  begin
    if MessageDlg(rsStopScan,mtWarning,mbYesNo,0,mbNo)=mrYes then
      exit(-2)
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

procedure TFormSQLCP.bbScanModClick(Sender: TObject);
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
        bbScanMod .Enabled:=false;
        bbAddTrans.Enabled:=false;
        bbNewTrans.Enabled:=false;
        bbSQLog   .Enabled:=false;
        bbSaveDB  .Enabled:=false;

        doBreak:=false;
        tlscan.OnFileScan:=@OnFileScan;
        for i:=0 to OpenDialog.Files.Count-1 do
        begin
          RGLog.Add('Scanning '+OpenDialog.Files[i]);
          Self.Caption:='Scanning '+OpenDialog.Files[i];
          lres:=tlscan.Scan(OpenDialog.Files[i]);
          RGLog.Add('Checked '+IntToStr(lres)+' files');
        end;
        Self.Caption:='';
        RGLog.Add('Remake Filter');
        RemakeFilter();
        ShowMessage('Done!');
        FillModList();
        UpdateStatus();

        bbScanMod .Enabled:=true;
        bbAddTrans.Enabled:=true;
        bbNewTrans.Enabled:=true;
        bbSQLog   .Enabled:=true;
        bbSaveDB  .Enabled:=true;
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

procedure TFormSQLCP.bbSQLogClick(Sender: TObject);
{
var
  dlg:TSaveDialog;
begin
  if SQLog.Size=0 then
  begin
    ShowMessage(rsNothingToSave);
    exit;
  end;

  dlg:=TSaveDialog.Create(nil);
  try
    dlg.FileName  :=Self.Name+'.sql';
    dlg.DefaultExt:='.sql';
    dlg.Filter    :='';
    dlg.Title     :='';
    dlg.Options   :=dlg.Options+[ofOverwritePrompt];

    if (dlg.Execute) then
    begin
      SQLog.SaveToFile(dlg.Filename);
//      SQLog.Clear;
    end;
  finally
    dlg.Free;
  end;
}
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

procedure TFormSQLCP.bbLogClick(Sender: TObject);
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

procedure TFormSQLCP.bbSaveDBClick(Sender: TObject);
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
       if lbMods.ItemIndex=0 then lstat.modid:=-1
  else if lbMods.ItemIndex=1 then lstat.modid:=0
  else
    lstat.modid:=GetModByName(lbMods.Items[lbMods.ItemIndex]);

  GetModStatistic(lstat);
  edModSTat.Tag:=lstat.total;
  edModSTat.Text:=Format(rsStat,
    [lstat.total,lstat.dupes,lstat.total-lstat.dupes,lstat.files,lstat.tags]);
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
begin
  lfeMods.FilteredListBox:=nil;
  lfeMods.Clear;

  GetModList(lbMods.Items,true);

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
  bbGenerate.Enabled:=lcnt>0;
  if lcnt>0 then gdLanguages.Row:=1;
end;

procedure TFormSQLCP.UpdateStatus();
begin
  StatusBar.SimpleText:=Format(rsStatus,[GetLineCount(0),GetUnrefLineCount()]);
end;

procedure TFormSQLCP.FormCreate(Sender: TObject);
begin
  FLogForm  :=nil;
  FSQLogForm:=nil;

  SetProgramLanguage();
  TLOpenBase(true);
  FillLangList();
  FillModList();
  UpdateStatus();
end;

procedure TFormSQLCP.FormDestroy(Sender: TObject);
begin
  TLCloseBase(false);
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

         if lbMods.ItemIndex=0 then CurMod:=-1
    else if lbMods.ItemIndex=1 then CurMod:=0
    else
      CurMod:=GetModByName(lbMods.Items[lbMods.ItemIndex]);
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

