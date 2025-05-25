unit fmSQLCP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ComCtrls, Grids, ListFilterEdit;

type

  { TFormSQLCP }

  TFormSQLCP = class(TForm)
    bbScanMod: TBitBtn;
    bbAddTrans: TBitBtn;
    bbSaveDB: TBitBtn;
    bbLog: TBitBtn;
    bbSQLog: TBitBtn;
    cbWithRef: TCheckBox;
    edModStat: TEdit;
    gdLanguages: TStringGrid;
    lblCurLang: TLabel;
    lbMods: TListBox;
    lfeMods: TListFilterEdit;
    gdModStat: TStringGrid;
    StatusBar: TStatusBar;
    procedure bbAddTransClick(Sender: TObject);
    procedure bbLogClick(Sender: TObject);
    procedure bbSaveDBClick(Sender: TObject);
    procedure bbScanModClick(Sender: TObject);
    procedure bbSQLogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DoStartEdit(Sender: TObject);
    procedure lbModsSelectionChange(Sender: TObject; User: boolean);
    procedure lfeModsAfterFilter(Sender: TObject);
  private
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
  tltrsql,
  iso639,
  unitlogform,
  tl2unit,
  tlscan,
  rgdb,
  sqlite3dyn,
  rgglobal;

resourcestring
  rsOpenTranslation = 'Open translation file';
  rsOpenMod         = 'Open mod (pak) file';
  rsChooseLang      = 'Choose translation language';
//  rsUnknownLang     = 'Unknown language choosed';
//  rsYourLang        = 'Your lang title';
  rsLanguage        = 'Language:';
  rsStatus          = 'Total lines: %d | Unreferred lines: %d';
  rsStat            = 'Total lines: %d | Duplicates: %d | Unique: %d | Files: %d | Tags: %d';
  rsDblClick        = 'Double-Click to edit translation';

const
  sOriginalGame = '- Original game -';

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

function TFormSQLCP.OnFileScan(const fname:AnsiString; idx, atotal:integer):integer;
begin
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
      end;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TFormSQLCP.bbSQLogClick(Sender: TObject);
var
  dlg:TSaveDialog;
begin
  if SQLog.Size=0 then exit;

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
end;

procedure TFormSQLCP.bbLogClick(Sender: TObject);
begin
  if fmLogForm=nil then
  begin
    fmLogForm:=TfmLogForm.Create(Self);
    fmLogForm.memLog.Text:=RGLog.Text;
  end;
  fmLogForm.ShowOnTop;
end;

procedure TFormSQLCP.bbSaveDBClick(Sender: TObject);
begin
  TLSaveBase();
end;

procedure TFormSQLCP.lbModsSelectionChange(Sender: TObject; User: boolean);
var
  lstat:TModStatistic;
  i:integer;
begin
  if lbMods.ItemIndex<0 then exit;
  if lbMods.ItemIndex=0 then
    lstat.modid:=0
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
var
  vm:pointer;
  ls:string;
begin
  ls:='SELECT title FROM dicmods';
  lfeMods.FilteredListBox:=nil;
  lfeMods.Clear;
  lbMods.Clear;
  lbMods.Items.Add(sOriginalGame);
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      ls:=sqlite3_column_text(vm,0);
      lbMods.Items.Add(ls);
//      lfeMods.AddItem(ls);
    end;
    sqlite3_finalize(vm);
  end;
  lfeMods.FilteredListBox:=lbMods;
  lfeMods.SortData:=true;
end;

procedure TFormSQLCP.FillLangList();
var
  vm:pointer;
  ls:string;
  i,lcnt:integer;
begin
  ls:='SELECT name FROM sqlite_master'+
      ' WHERE (type = ''table'') AND (name GLOB ''trans_*'')'+
      ' ORDER BY name';

  gdLanguages.BeginUpdate;
  gdLanguages.Clear;
  gdLanguages.RowCount:=1;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    i:=1;
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      ls:=sqlite3_column_text(vm,0);
      lcnt:=ReturnInt(tldb,'SELECT count(1) FROM '+ls);
      ls:=Copy(ls,7);
      gdLanguages.InsertRowWithValues(i,[IntToStr(lcnt),ls,GetLangName(ls)]);
      inc(i);
//      gdLanguages.Items.Add(ls+' ('+IntToStr(lcnt)+') - '+GetLangName(ls));
    end;
    sqlite3_finalize(vm);
  end;
  gdLanguages.EndUpdate();

end;

procedure TFormSQLCP.UpdateStatus();
begin
  StatusBar.SimpleText:=Format(rsStatus,[GetLineCount(0),GetUnrefLines()]);
end;

procedure TFormSQLCP.FormCreate(Sender: TObject);
begin
  fmLogForm:=nil;
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

    if lbMods.ItemIndex=0 then
      CurMod:=0
    else
      CurMod:=GetModByName(lbMods.Items[lbMods.ItemIndex]);
    CurLang:=gdModStat.Cells[2,gdModStat.Row];

    MainTL2TransForm:=TMainTL2TransForm.Create(Self);
    MainTL2TransForm.ShowModal;
  end;
end;

end.

