unit fmSQLCP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ComCtrls;

type

  { TFormSQLCP }

  TFormSQLCP = class(TForm)
    bbScanMod: TBitBtn;
    bbAddTrans: TBitBtn;
    bbSaveDB: TBitBtn;
    cbWithRef: TCheckBox;
    lblModInfo: TLabel;
    lblCurLang: TLabel;
    lbLanguages: TListBox;
    lbMods: TListBox;
    memModInfo: TMemo;
    StatusBar: TStatusBar;
    procedure bbAddTransClick(Sender: TObject);
    procedure bbSaveDBClick(Sender: TObject);
    procedure bbScanModClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbModsSelectionChange(Sender: TObject; User: boolean);
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
  tl2dataunit,
  tlscan,
  rgdb,
  sqlite3dyn,
  rgglobal;

resourcestring
  rsOpenTranslation = 'Open translation file';
  rsOpenMod         = 'Open mod (pak) file';
  rsChooseLang      = 'Choose translation language';
  rsUnknownLang     = 'Unknown language choosed';
  rsYourLang        = 'Your lang title';
  rsLanguage        = 'Language:';

  sUnrefLines = 'Unreferred lines';
  sTotalLines = 'Total lines';
  sDupes      = 'Duplicates';
  sUnical     = 'Unique lines';
  sLanguage   = 'Language';
  sTranslated = 'Translated lines';
  sPartial    = 'Partially translated';

{ TFormSQLCP }

procedure TFormSQLCP.bbAddTransClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  data:TTL2Translation;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Title      :=rsOpenTranslation;
    OpenDialog.Options    :=[ofFileMustExist];
    OpenDialog.Filter     :='Translation file|*.DAT';
//    OpenDialog.InitialDir :=FSettings.edSaveDir.Text;

    if OpenDialog.Execute then
    begin
      data.Init;
      data.LoadFromFile(OpenDialog.FileName);
      data.Lang:=iso639.GetLang(InputBox(rsChooseLang,rsLanguage,''));
      if data.lang='' then
        data.Lang:=InputBox(rsUnknownLang,rsYourLang,'unk');

      CopyToBase(data,cbWithRef.Checked);
      data.Free;
      ShowMessage('Done!');
      FillLangList();
    end;
  finally
    OpenDialog.Free;
  end;
end;

function TFormSQLCP.OnFileScan(const fname:AnsiString; idx, atotal:integer):integer;
begin
  result:=0;
end;

procedure TFormSQLCP.bbScanModClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Title      :=rsOpenMod;
    OpenDialog.Options    :=[ofFileMustExist];
    OpenDialog.Filter     :='Mod file|*.MOD;*.PAK';
//    OpenDialog.InitialDir :=FSettings.edSaveDir.Text;

    if OpenDialog.Execute then
    begin
      tlscan.OnFileScan:=@OnFileScan;
      PrepareScanSQL();
      tlscan.Scan(OpenDialog.FileName);
      RemakeFilter();
      ShowMessage('Done!');
      FillModList();
      UpdateStatus();
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TFormSQLCP.bbSaveDBClick(Sender: TObject);
begin
  TLSaveBase();
end;

procedure TFormSQLCP.FillModList();
var
  vm:pointer;
  ls:string;
begin
  ls:='SELECT title FROM dicmods';
  lbMods.Clear;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      ls:=sqlite3_column_text(vm,0);
      lbMods.Items.Add(ls);
    end;
    sqlite3_finalize(vm);
  end;
end;

procedure TFormSQLCP.FillLangList();
var
  vm:pointer;
  ls:string;
  lcnt:integer;
begin
  ls:='SELECT name FROM sqlite_master WHERE (type = ''table'') AND (name GLOB ''trans_*'')';

  lbLanguages.Clear;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      ls:=sqlite3_column_text(vm,0);
      lcnt:=ReturnInt(tldb,'SELECT count(1) FROM '+ls);
      ls:=Copy(ls,7);
      lbLanguages.Items.Add(ls+' ('+IntToStr(lcnt)+') - '+GetLangName(ls));
    end;
    sqlite3_finalize(vm);
  end;

end;

procedure TFormSQLCP.UpdateStatus();
begin
  StatusBar.SimpleText:=sTotalLines+': '+IntToStr(GetLineCount(0))+
  ' | '+sUnrefLines+': '+IntToStr(GetUnrefLines());
end;

procedure TFormSQLCP.FormCreate(Sender: TObject);
begin
  TLOpenBase();
  FillLangList();
  FillModList();
  UpdateStatus();
end;

procedure TFormSQLCP.FormDestroy(Sender: TObject);
begin
  TLCloseBase(false);
end;

procedure TFormSQLCP.lbModsSelectionChange(Sender: TObject; User: boolean);
var
  ls:string;
  lstat:TModStatistic;
  i:integer;
begin
  lstat.modid:=GetModByName(lbMods.Items[lbMods.ItemIndex]);
  GetModStatistic(lstat);
  ls:=sTotalLines+': '+IntToStr(lstat.total)+#13#10+
      sDupes     +': '+IntToStr(lstat.dupes)+#13#10+
      sUnical    +': '+IntToStr(lstat.total-lstat.dupes)+#13#10;
  for i:=0 to High(lstat.langs) do
    ls:=ls+sLanguage  +': '+GetLangName(lstat.langs[i].lang )+#13#10+
      '  '+sTranslated+': '+IntToStr   (lstat.langs[i].trans)+#13#10+
      '  '+sPartial   +': '+IntToStr   (lstat.langs[i].part )+#13#10;
  memModInfo.Text:=ls;
end;


end.

