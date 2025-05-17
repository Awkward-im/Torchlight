unit TL2Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  ShellCtrls, ExtCtrls, StdCtrls, Buttons, ActnList,
  LCLType,StdActns, Grids, Types, rgglobal;

type

  { TMainTL2TransForm }

  TMainTL2TransForm = class(TForm)
    actCheckTranslation: TAction;
    actExportClipBrd: TAction;
    actExportFile: TAction;
    actFilter: TAction;
    actFindNext: TAction;
    actHideReady: TAction;
    actImportClipBrd: TAction;
    actImportFile: TAction;
    actSettings: TAction;
    actOpenSource: TAction;
    actPartAsReady: TAction;
    actReplace: TAction;
    actShowDoubles: TAction;
    actShowLog: TAction;
    actModInfo: TAction;
    actShowSimilar: TAction;
    actStopScan: TAction;
    actTranslate: TAction;
    FileScan: TAction;
    FileBuild: TAction;
    HelpNotes: TAction;
    FileExit: TAction;
    FileNew: TAction;
    FileOpen: TAction;
    FileSave: TAction;
    FileSaveAs: TAction;
    HelpAbout: TAction;

    FontEdit: TFontEdit;
    memEdit: TMemo;
    cbFolder: TComboBox;
    cbSkills: TComboBox;
    cbLanguage: TComboBox;
    cbDisplayMode: TComboBox;
    edProjectFilter: TEdit;

    miViewSimilar: TMenuItem;
    miViewDoubles: TMenuItem;
    miViewNotes: TMenuItem;
    miViewLog: TMenuItem;
    miView: TMenuItem;
    miEditTranslate: TMenuItem;
    miEditReplace: TMenuItem;
    miEditCheckTranslation: TMenuItem;
    miEditSettings: TMenuItem;
    miEdit: TMenuItem;
    miFileBuild: TMenuItem;
    miFileScanMod: TMenuItem;

    pnlFolders: TPanel;
    pnlSkills: TPanel;
    pnlTop: TPanel;
    sbFindNext: TSpeedButton;
    sbProjectFilter: TSpeedButton;
    sbChooseMod: TSpeedButton;
    Separator1: TMenuItem;
    splFolder: TSplitter;
    splSkills: TSplitter;
    TL2ActionList: TActionList;
    TL2Grid: TStringGrid;
    TL2ProjectFilterPanel: TPanel;
    TL2Toolbar: TToolBar;
    tbFileNew: TToolButton;
    tbFileSave: TToolButton;
    tbSeparator1: TToolButton;
    tbModInfo: TToolButton;
    tbHelpAbout: TToolButton;
    tbFontEdit: TToolButton;
    tbSeparator2: TToolButton;
    miHelpAbout: TMenuItem;
    miFile: TMenuItem;
    miHelp: TMenuItem;
    miFileExit: TMenuItem;
    miFileNew: TMenuItem;
    miFileOpen: TMenuItem;
    miFileSave: TMenuItem;
    miFileSaveAs: TMenuItem;
    miFileSep1: TMenuItem;
    miFileSep2: TMenuItem;
    miClosePage: TMenuItem;
    TL2MainMenu: TMainMenu;
    TL2StatusBar: TStatusBar;
    tbHelpNotes: TToolButton;
    tbBuild: TToolButton;
    tbScanMod: TToolButton;
    tbShowLog: TToolButton;
    tbSeparator3: TToolButton;
    tbSettings: TToolButton;
    tbCheckTranslation: TToolButton;
    tbTranslate: TToolButton;
    tbReplace: TToolButton;
    tbSimilar: TToolButton;
    tbDouble: TToolButton;
    tbSeparator4: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    procedure actCheckTranslationExecute(Sender: TObject);
    procedure actFindNextExecute(Sender: TObject);
    procedure actModInfoExecute(Sender: TObject);
    procedure actReplaceExecute(Sender: TObject);
    procedure actSettingsExecute(Sender: TObject);
    procedure actShowDoublesExecute(Sender: TObject);
    procedure actShowLogExecute(Sender: TObject);
    procedure actShowSimilarExecute(Sender: TObject);
    procedure actTranslateExecute(Sender: TObject);
    procedure cbFolderChange(Sender: TObject);
    procedure cbSkillsChange(Sender: TObject);
    procedure edProjectFilterChange(Sender: TObject);
    procedure FileScanExecute(Sender: TObject);
    procedure HelpNotesExecute(Sender: TObject);
    procedure FileBuildExecute(Sender: TObject);
    procedure FileExitExecute(Sender: TObject);
    procedure FileNewExecute(Sender: TObject);
    procedure FileSaveAsExecute(Sender: TObject);
    procedure FileSaveExecute(Sender: TObject);
    procedure FontEditAccept(Sender: TObject);
    procedure FontEditBeforeExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HelpAboutExecute(Sender: TObject);
    procedure memEditExit(Sender: TObject);
    procedure memEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TL2GridClick(Sender: TObject);
    procedure TL2GridDblClick(Sender: TObject);
    procedure TL2GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure TL2GridGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
    procedure TL2GridHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure TL2GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TL2GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure TL2GridSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure TL2GridSetCheckboxState(Sender: TObject; ACol, ARow: Integer; const Value: TCheckboxState);

  private
    FModName:String;
    FTable:string;

    function  CanClosePage(idx: integer;out s:String): boolean;
    procedure dlgOnReplace(Sender: TObject);
    procedure FillFoldersCombo(asetidx: boolean);
    procedure FillProjectGrid(const afilter: AnsiString);
    function  FillProjectSGRow(aRow, idx: integer; const afilter: AnsiString): boolean;
    function  MoveToIndex(idx: integer):integer;
    procedure ReBoundEditor;
    procedure Search(const atext: AnsiString; aRow: integer);
    procedure UpdateGrid(idx: integer);
    procedure UpdateStatusBar(Sender:TObject; const SBText:AnsiString='');
    function  UpdateCache(arow:integer; const astr:AnsiString):boolean;
  public

  end;

var
  MainTL2TransForm: TMainTL2TransForm;

implementation

{$R *.lfm}

uses
  fmmodinfo,
  unitLogForm,
  TL2DataModule,
  TL2SettingsForm,
  TL2NotesForm,
  TL2SimForm,
  TL2About,
  tltrsql,
  TL2Text;

{ TMainTL2TransForm }

resourcestring
  rsDefaultCaption = 'Torchlight 2 Translation';
  rsSaveProject    = 'Save project';
  rsNotSaved       = 'Project modified. Do you want to save it?';
  rsWrongDir       = 'Choosed directory don''t looks like mod directory (have no MEDIA folder)';

  rsReplaces       = 'Total replaces';
  rsDoDelete       = 'Are you sure to delete selected line(s)?'#13#10+
                     'This text will be just hidden until you save and reload project.';

  rsNoDoubles      = 'No doubles for this text';
  rsDupes          = 'Check doubles info.';

  // punctuation check
  rsNoWarnings     = 'No any warnings';
  rsNotes          = 'Punctuation note';
  rsNext           = 'Next note';
  rsFixOne         = 'Fix this';
  rsFixAll         = 'Fix all';
  rsAffected       = ' line(s) affected';

  // folder combobox
  rsFolderAll      = '- All -';    // minus+space to be first
  rsRoot           = '-- Root --'; // minus+minus+space to be second

  // show mode combobox
  rsModeAll        = 'All';
  rsModeReady      = 'Ready';
  rsReadyPlus      = 'Translated';
  rsModePartial    = 'Partial';
  rsModeOriginal   = 'Original';
  rsNotReady       = 'Not translated';

const
  colOrigin  = 1;
  colPartial = 2;
  colTrans   = 3;

//----- Form -----

procedure TMainTL2TransForm.UpdateStatusBar(Sender:TObject; const SBText:AnsiString='');
begin
  if Sender=nil then
  begin
    TL2StatusBar.SimpleText:='';
    Self.Caption:=rsDefaultCaption;
  end
  else if SBText<>'' then
  begin
    TL2StatusBar.SimpleText:=SBText;
    Application.ProcessMessages;
  end
  else
  begin
    Self.Caption:=FModName;
  end;
end;

procedure TMainTL2TransForm.FormCreate(Sender: TObject);
var
  lsl:TStringList;
  i:integer;
begin
  fmLogForm:=nil;

  TL2Settings:=TTL2Settings.Create(Self);
  TL2Settings.Parent:=Self;
  TL2Settings.Align :=alClient;

  Self.Font.Assign(TL2DM.TL2Font);

  cbDisplayMode.AddItem(rsModeAll     ,TObject(0));
  cbDisplayMode.AddItem(rsModeReady   ,TObject(1));
  cbDisplayMode.AddItem(rsReadyPlus   ,TObject(2));
  cbDisplayMode.AddItem(rsModePartial ,TObject(3));
  cbDisplayMode.AddItem(rsModeOriginal,TObject(4));
  cbDisplayMode.AddItem(rsNotReady    ,TObject(5));
  cbDisplayMode.ItemIndex:=0;

  TLOpenBase();
  CurMod:=2110504075;
  CurLang:='ru';
  LoadModData();
  LoadTranslation();
  FillFoldersCombo(true);
  FillProjectGrid('');
end;

procedure TMainTL2TransForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
//  lprj:TTL2Project;
  i:integer;
begin
  i:=-1;

  if Key=VK_ESCAPE then
  begin
//    lprj:=ActiveProject;
//    if lprj<>nil then
//      lprj.actStopScanExecute(Sender);
  end;

  inherited;
end;

function TMainTL2TransForm.CanClosePage(idx:integer; out s:string):boolean;
var
  ltab:TTabSheet;
//  lprj:TTL2Project;
begin
  result:=false;
  s:='';

//  lprj:=ActiveProject;
//  if lprj<>nil then
  begin
{
    while lprj.Modified do
      case MessageDlg(rsNotSaved,mtWarning,mbYesNoCancel,0,mbCancel) of
        mrOk: begin
          if lprj.FileName='' then
            FileSaveAsExecute(self)
          else
            FileSaveExecute(self);
        end;
        mrCancel: exit;
      else
        break;
      end;
    s:=lprj.FileName;
}
  end;
  result:=true;

end;

procedure TMainTL2TransForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  lsl:TStringList;
  ls:String;
  i:integer;
begin
//  CanClose:=CanClosePage(i,ls);
end;

{%REGION File Operations}
procedure TMainTL2TransForm.FileExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainTL2TransForm.FileBuildExecute(Sender: TObject);
begin
//  ActiveProject.Build;
end;

procedure TMainTL2TransForm.FileScanExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  ls:AnsiString;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.DefaultExt:='.MOD';
    OpenDialog.Filter    :='MOD files|*.MOD|PAK files|*.PAK|All supported|*.MOD;*.PAK|All files|*.*';
    OpenDialog.Options   :=[ofEnableSizing,ofFileMustExist];
    if OpenDialog.Execute then
    begin
//      if not ActiveProject.NewFromFile(OpenDialog.FileName) then
//        CanClosePage(TL2PageControl.ActivePageIndex,ls);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TMainTL2TransForm.FileNewExecute(Sender: TObject);
var
  ldlg:TSelectDirectoryDialog;
  ls:AnsiString;
begin
{
  try
    TL2ShellTreeView.Root:=TL2Settings.edRootDir.Text;
  except
    TL2ShellTreeView.Root:='';
  end;
  TL2ShellTreeView.Refresh(nil);
  TL2TreePanel.Visible:=true;
  TL2ShellTreeView.SetFocus;
}
  ldlg:=TSelectDirectoryDialog.Create(nil);
  try
    ldlg.InitialDir:=TL2Settings.edRootDir.Text;
    ldlg.FileName  :='';
    ldlg.Options   :=[ofEnableSizing,ofPathMustExist];
    if ldlg.Execute then
    begin
      if Pos('\MEDIA',UpCase(ldlg.FileName))=(Length(ldlg.FileName)-6+1) then
        ls:=Copy(ldlg.FileName,Length(ldlg.FileName)-6)
      else if DirectoryExists(ldlg.FileName+'\MEDIA') then
        ls:=ldlg.FileName
      else
      begin
        ShowMessage(rsWrongDir);
        exit;
      end;

//      if not ActiveProject.NewFromDir(ls,false,true) then
//        CanClosePage(TL2PageControl.ActivePageIndex,ls);
    end;
  finally
    ldlg.Free;
  end;
end;

procedure TMainTL2TransForm.FileSaveAsExecute(Sender: TObject);
var
  SaveDialog: TSaveDialog;
//  prj:TTL2Project;
  ls:AnsiString;
begin
  SaveDialog:=TSaveDialog.Create(nil);
  try
//    prj:=ActiveProject;
    SaveDialog.InitialDir:=TL2Settings.edWorkDir.Text;

    ls:=TL2Settings.edTransLang.Text;
{
    if (ls<>'') and (Pos('.'+ls,prj.ProjectName)=0) then
      ls:=prj.ProjectName+'.'+ls
    else
      ls:=prj.ProjectName;
}
    SaveDialog.FileName  :=ls;
    SaveDialog.DefaultExt:=DefaultExt;
    SaveDialog.Filter    :=DefaultFilter;
    SaveDialog.Title     :=rsSaveProject;
    SaveDialog.Options   :=SaveDialog.Options+[ofOverwritePrompt,ofNoChangeDir];
    if (SaveDialog.Execute) then
    begin
      ls:=ExtractNameOnly(SaveDialog.Filename);
      if (ls<>'') then
      begin
//        prj.FileName   :=SaveDialog.Filename;
//        prj.ProjectName:=ls;

        FileSaveExecute(Sender);
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TMainTL2TransForm.FileSaveExecute(Sender: TObject);
begin
  SaveTranslation();
  FileSave.Enabled:=false;
end;
{%ENDREGION File Operations}

function TMainTL2TransForm.UpdateCache(arow:integer; const astr:AnsiString):boolean;
var
  lidx:integer;
begin
  lidx:=IntPtr(TL2Grid.Objects[0,arow]);
  result:=TRCache[lidx].dst<>astr;
  if result then
  begin
    TRCache[lidx].dst  :=astr;
    TRCache[lidx].part :=astr<>'';
    TRCache[lidx].flags:=TRCache[lidx].flags or rfIsModified;
    FileSave.Enabled:=true;

    TL2Grid.Cells[colTrans  ,arow]:=astr;
    TL2Grid.Cells[colPartial,arow]:=BoolNumber[astr<>''];

    if not TL2Grid.IsCellVisible(0,arow) then
      TL2Grid.TopRow:=arow;
  end;
end;

procedure TMainTL2TransForm.actTranslateExecute(Sender: TObject);
var
  ls:AnsiString;
  idx:integer;
begin
  if memEdit.Visible and (memEdit.Text<>'') then
  begin
    if memEdit.SelLength>0 then
    begin
      memEdit.SelText:=Translate(memEdit.SelText);
      ls:=memEdit.Text;
    end
    else
      ls:=Translate(memEdit.Text);
  end
  else
  begin
    ls:=Translate(TL2Grid.Cells[colOrigin,TL2Grid.Row]);
  end;

  UpdateCache(TL2Grid.Row,ls);

//  Modified:=true;
  UpdateStatusBar(Self);
end;

procedure TMainTL2TransForm.dlgOnReplace(Sender: TObject);
var
  ls,lsrc,lr:AnsiString;
  idx,lcnt,i,p:integer;
begin
  lcnt:=0;
  lsrc:=(Sender as TReplaceDialog).FindText;
  lr  :=(Sender as TReplaceDialog).ReplaceText;
  for i:=TL2Grid.Row to TL2Grid.RowCount-1 do
  begin
    idx:=IntPtr(TL2Grid.Objects[0,i]);
    ls:=TL2Grid.Cells[colTrans,i];
    p:=Pos((Sender as TReplaceDialog).FindText,ls);
    if p>0 then
    begin
      inc(lcnt);
      ls:=StringReplace(ls,lsrc,lr,[rfReplaceAll]);

      UpdateCache(i,ls);
    end;
  end;
  ShowMessage(rsReplaces+' = '+IntToStr(lcnt));
end;

procedure TMainTL2TransForm.actReplaceExecute(Sender: TObject);
var
  dlg:TReplaceDialog;
begin
  dlg:=TReplaceDialog.Create(Self);
  dlg.Options:=[frHideMatchCase,frHideWholeWord,frHideUpDown,frHideEntireScope,frHidePromptOnReplace];
  dlg.OnReplace:=@dlgOnReplace;
  dlg.Execute;
//  dlg.Free;
end;

procedure TMainTL2TransForm.Search(const atext:AnsiString; aRow:integer);
var
  ltext:AnsiString;
  i:integer;
begin
  ltext:=atext; // already locase
  for i:=aRow to TL2Grid.RowCount-1 do
  begin
    if (Pos(ltext,AnsiLowerCase(TL2Grid.Cells[colOrigin,i]))>0) or
       (Pos(ltext,AnsiLowerCase(TL2Grid.Cells[colTrans ,i]))>0) then
    begin
      TL2Grid.Row   :=i;
      TL2Grid.TopRow:=i;
      ReBoundEditor;
      exit;
    end;
  end;
end;

procedure TMainTL2TransForm.actFindNextExecute(Sender: TObject);
begin
  Search(edProjectFilter.Text,TL2Grid.Row+1);
end;

procedure TMainTL2TransForm.actCheckTranslationExecute(Sender: TObject);
var
  idx,lcnt:integer;
  lres:dword;
  lask:boolean;
begin
  lask:=true;
  lcnt:=0;
{
  idx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
  lres:=data.NextNoticed(true,idx);
  if idx<0 then
  begin
    idx:=-1;
    lres:=data.NextNoticed(true,idx);
  end;
}
  while idx>=0 do
  begin

    if lask and (lres<>0) then
    begin
      MoveToIndex(idx);
      case QuestionDlg(rsNotes,CheckDescription(lres),mtConfirmation,
        [mrContinue,rsNext,'IsDefault',mrYes,rsFixOne,mrYesToAll,rsFixAll,mrCancel],'') of

        mrContinue: begin
          lres:=0;
        end;

        mrYes: begin
        end;

        mrYesToAll: begin
          lask:=false;
        end;

        mrCancel: break;
      end;
    end;
{
    if (lres and cpfNeedToFix)<>0 then
    begin
      dec(idx);
      data.NextNoticed(false,idx); // yes, yes, check it again but with fix at same time
      inc(lcnt);
      if TL2Settings.cbAutoAsPartial.Checked then
        data.State[idx]:=stPartial;

      //!!!! Like UpdateCache but with index, not row
      UpdateGrid(idx);
    end;

    lres:=data.NextNoticed(true,idx);
}
  end;

  if lcnt>0 then
  begin
//    Modified:=true;
    UpdateStatusBar(Self);
    ShowMessage(IntToStr(lcnt)+rsAffected);
  end
  else
    ShowMessage(rsNoWarnings);
end;

procedure TMainTL2TransForm.actShowDoublesExecute(Sender: TObject);
var
  lline:integer;
begin
  lline:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
{
  if data.RefCount[lline]=1 then
    ShowMessage(sNoDoubles)
  else
    with TDupeForm.Create(Self,data,lline) do
    begin
      ShowModal;
      Free;
    end;
}
end;

procedure TMainTL2TransForm.actShowSimilarExecute(Sender: TObject);
begin
  with TSimilarForm.Create(Self,IntPtr(TL2Grid.Objects[0,TL2Grid.Row])) do
  begin
    ShowModal;
    Free;
  end;

end;

procedure TMainTL2TransForm.actModInfoExecute(Sender: TObject);
begin
  with TMODInfoForm.Create(Self,nil,true) do
  begin
{
    Title :=prj.data.ModTitle;
    Author:=prj.data.ModAuthor;
    Descr :=prj.data.ModDescr;
    ID    :=CurMod;
}
    ShowModal;
    Free;
  end;
end;

procedure TMainTL2TransForm.actSettingsExecute(Sender: TObject);
begin
  TL2Settings.Visible:=actSettings.Checked;
end;

{%REGION GUI}
procedure TMainTL2TransForm.actShowLogExecute(Sender: TObject);
begin
  if fmLogForm=nil then
  begin
    fmLogForm:=TfmLogForm.Create(Self);
    fmLogForm.memLog.Text:=RGLog.Text;
  end;
  fmLogForm.ShowOnTop;
end;

procedure TMainTL2TransForm.FontEditAccept(Sender: TObject);
begin
  TL2DM.TL2Font.Assign((Sender as TFontEdit).Dialog.Font);
  Self.Font.Assign(TL2DM.TL2Font);
end;

procedure TMainTL2TransForm.FontEditBeforeExecute(Sender: TObject);
begin
  (Sender as TFontEdit).Dialog.Font.Assign(TL2DM.TL2Font);
end;

procedure TMainTL2TransForm.HelpNotesExecute(Sender: TObject);
begin
  if TL2Notes=nil then
    TL2Notes:=TTL2Notes.Create(Self);
  TL2Notes.Show;
end;

procedure TMainTL2TransForm.HelpAboutExecute(Sender: TObject);
begin
  with TAboutForm.Create(Self) do
  begin
    ShowModal;
    Free;
  end;
end;
{%ENDREGION GUI}

{%REGION MemEdit}
procedure TMainTL2TransForm.ReBoundEditor;
var
  r:TRect;
begin
  r:=TL2Grid.CellRect(colTrans,TL2Grid.Row);
  InflateRect(r,-1,-1);
  memEdit.Tag:=0;
  memEdit.BoundsRect:=r;
end;

procedure TMainTL2TransForm.memEditExit(Sender: TObject);
var
  lr,lidx:integer;
begin
  memEdit.Visible:=false;
  lr:=TL2Grid.Row;
  lidx:=IntPtr(TL2Grid.Objects[0,lr]);

  if (memEdit.Tag=0) and (TL2Grid.Cells[colTrans,lr]<>memEdit.Text) then
  begin
    TL2Grid.Cells[colTrans,lr]:=memEdit.Text;
    if memEdit.Text='' then
    begin
      TL2Grid.Cells[colPartial,lr]:='0';
    end
    else
    begin
      if TL2Grid.Cells[colPartial,lr]='1' then

//      data.CheckTheSame(lidx,TL2Settings.cbAutoAsPartial.Checked);

      TL2Grid.Row:=lr;
      TL2Grid.Col:=colTrans;
    end;
//    Modified:=true;
    UpdateStatusBar(Self);
  end;

  // when we close/change tab with active editor
  if Parent.Visible then
    TL2Grid.SetFocus;
end;

procedure TMainTL2TransForm.memEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ls:AnsiString;
begin
  if (Key=VK_U) and (Shift=[ssAlt]) then
  begin
    memEdit.SelText:='|u';
    Key:=0;
  end;

  if (Key=VK_N) and (Shift=[ssAlt]) then
  begin
    memEdit.SelText:='\n';
    Key:=0;
  end;

  if (Key=VK_DELETE) and (Shift=[ssAlt]) then
  begin
    if RemoveColor(memEdit.Text,ls) then
    begin
      memEdit.Text:=ls;
      Key:=0;
    end;
  end;

  if (Key=VK_C) and (Shift=[ssAlt]) then
  begin
    ls:=TL2Grid.Cells[colOrigin,TL2Grid.Row];
    if FillColorPopup(memEdit,ls) then
    begin
      Key:=0;
    end;
  end;

  if (Key=VK_V) and (Shift=[ssAlt]) then
  begin
    ls:=TL2Grid.Cells[colOrigin,TL2Grid.Row];
    if FillParamPopup(memEdit,ls) then
    begin
      Key:=0;
    end;
  end;

  if Key=VK_RETURN then
  begin
    memEdit.Tag:=0;
    Key:=VK_TAB;
    TL2Grid.EditingDone;
  end
  else if Key=VK_ESCAPE then
  begin
    memEdit.Tag:=1;
    Key:=VK_TAB;
    memEdit.ExecuteCancelAction;
  end;

  inherited;
end;
{%ENDREGION MemEdit}

{%REGION Grid}
procedure TMainTL2TransForm.TL2GridClick(Sender: TObject);
var
  ls,lfile,ltag:AnsiString;
  lcnt,idx,lline:integer;
  p:pointer;
begin
  idx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
//  lcnt:=RGIterator.GetRefCount(idx);
  if lcnt=0 then // if (TRCache[idx].flags and rfIsNotReferred)<>0
    ls:=rsNoRef
  else if lcnt=1 then // if (TRCache[idx].flags and rfIsManyRefs)=0
  begin
//    RGIterator.GetRefInfo(idx,0,lfile,ltag,lline);
    ls:=ltag+' | '+lfile;
  end
  else
    ls:=StringReplace(rsSeveralRefs,'%d',IntToStr(lcnt),[])+' '+rsDupes;
  UpdateStatusBar(Self,ls);
end;

procedure TMainTL2TransForm.TL2GridDblClick(Sender: TObject);
//var  lrow:integer;
var
  i:integer;
begin
(*
  with TEditTextForm.Create(Self) do
  begin
    i:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);
    SelectLine(i);
    if ShowModal=mrOk then
    begin
      data.CheckTheSame(i,TL2Settings.cbAutoAsPartial.Checked);

      Modified:=true;
      UpdateStatusBar(Self);
{
      lrow:=TL2Grid.Row;
      FillProjectGrid('');
      TL2Grid.Row:=lrow;
}
    end;
    Free;
  end;
*)
end;

function GetTextLines(const atext:AnsiString; aCanvas:TCanvas; aRect:TRect):integer;
var
  lwidth:integer;
  // complex
  Sentence,CurWord:AnsiString;
  SpacePos,CurX:integer;
  EndOfSentence:Boolean;
begin
  // simple way
(*
  lwidth:=aCanvas.TextWidth(atext);
  result:=round(lwidth/((aRect.Right-aRect.Left{-2*constCellPadding})*0.8)+0.5);

  exit;
*)
  // complex but more accurate way

  result:=1;
  CurX:=aRect.Left+constCellPadding;

  { Here we get the contents of the cell }
  Sentence:=atext;

  { for each word in the cell }
  EndOfSentence:=FALSE;
  while (not EndOfSentence) do
  begin
    { to get the next word, we search for a space }
    SpacePos:=Pos(' ', Sentence);
    if SpacePos>0 then
    begin
      { get the current word plus the space }
      CurWord:=Copy(Sentence,0,SpacePos);

      { get the rest of the sentence }
      Sentence:=Copy(Sentence, SpacePos + 1, Length(Sentence) - SpacePos);
    end
    else
    begin
      { this is the last word in the sentence }
      EndOfSentence:=TRUE;
      CurWord:=Sentence;
    end;

    with aCanvas do
    begin
      { if the text goes outside the boundary of the cell }
      lwidth:=TextWidth(CurWord);
      if (lwidth+CurX)>(aRect.Right-constCellPadding) then
      begin
        { wrap to the next line }
        inc(result);
        CurX:=aRect.Left+constCellPadding;
      end;

      { increment the x position of the cursor }
      CurX:=CurX+lwidth;
    end;
  end;
end;

procedure TMainTL2TransForm.TL2GridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  ls:String;
  ts:TTextStyle;
  count1, count2: integer;
  lidx:integer;
begin
  if not (gdFixed in astate) then
  begin
    with TL2Grid do
    begin
      if (aCol in [colOrigin,colTrans]) then
      begin
        // calculate cell/row height (maybe better to move it to onHeaderSized
        // and re-call after translation text /font changed

        ts:=Canvas.TextStyle;
        ts.SingleLine:=false;
        ts.WordBreak :=true;
        Canvas.TextStyle:=ts;

        lidx:=IntPtr(Objects[0,aRow]);

        count1:=GetTextLines(Cells[colOrigin,aRow],Canvas,CellRect(colOrigin,aRow));
        count2:=GetTextLines(Cells[colTrans ,aRow],Canvas,CellRect(colTrans ,aRow));
        if count2>count1 then count1:=count2;

        if count1>1 then
        begin
          RowHeights[aRow]:=(Canvas.TextHeight('Wg'))*count1+2*constCellPadding;
        end
        else
          RowHeights[aRow]:=DefaultRowHeight;

        if gdSelected in astate then
          Canvas.Brush.Color:=clHighlight
        else
          Canvas.Brush.Color:=clWindow;
        Canvas.Brush.Style:= bsSolid;
        Canvas.FillRect(aRect);

        ls:=Cells[aCol,aRow];
        if (ACol=colOrigin) and (ls[Length(ls)]=' ') then
          ls[Length(ls)]:='~';
        Canvas.TextRect(aRect,
          aRect.Left+constCellPadding,aRect.Top+constCellPadding,ls);

        if gdFocused in astate then
          Canvas.DrawFocusRect(aRect);
        exit;
      end;
    end;
  end;

//  (Sender as TStringGrid).DefaultDrawCell(aCol,aRow,aRect,astate);
end;

procedure TMainTL2TransForm.TL2GridGetEditText(Sender: TObject; ACol,
  ARow: Integer; var Value: string);
begin
  memEdit.Text:=Value;
end;

procedure TMainTL2TransForm.TL2GridHeaderSized(Sender: TObject;
  IsColumn: Boolean; Index: Integer);
begin
  if IsColumn then
    ReBoundEditor;
end;

procedure TMainTL2TransForm.TL2GridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  ls:AnsiString;
  i,idx:integer;
begin
  if (Key=VK_SPACE) then
  begin
    for i:=1 to TL2Grid.RowCount-1 do
    begin
      if TL2Grid.IsCellSelected[TL2Grid.Col,i] then
      begin
        idx:=IntPtr(TL2Grid.Objects[0,i]);
{
        if data.State[idx]=stPartial then
        begin
          if data.Trans[idx]='' then
            data.State[idx]:=stOriginal
          else
            data.State[idx]:=stReady;
          TL2Grid.Cells[colPartial,i]:='0';
        end
        else
        begin
          data.State[idx]:=stPartial;
          TL2Grid.Cells[colPartial,i]:='1';
        end;
}
      end;
    end;
//    Modified:=true;
    UpdateStatusBar(Self);
    Key:=0;
  end;

  if (Key=VK_DELETE) then
  begin
    if TL2Grid.Col=colTrans then
    begin
      // remove color tags
      if Shift=[ssAlt] then
      begin
        i:=TL2Grid.Row;
        idx:=IntPtr(TL2Grid.Objects[0,i]);

        ls:=TL2Grid.Cells[colTrans,i];
        if ls='' then ls:=TL2Grid.Cells[colOrigin,i];

        if RemoveColor(ls,ls) then
        begin
//*          data.Trans[idx]:=ls;
//*          data.State[idx]:=stPartial;
          TL2Grid.Cells[colPartial,i]:='1';
          TL2Grid.Cells[colTrans  ,i]:=ls;
//          Modified:=true;
          UpdateStatusBar(Self);
        end;
      end
      else
      // clear selected translations
      begin
        for i:=1 to TL2Grid.RowCount-1 do
        begin
          if TL2Grid.IsCellSelected[colTrans,i] then
          begin
            if TL2Grid.Cells[colTrans,i]<>'' then
            begin
              idx:=IntPtr(TL2Grid.Objects[0,i]);
//*              data.Trans[idx]:='';
//*              data.State[idx]:=stOriginal;
              TL2Grid.Cells[colPartial,i]:='0';
              TL2Grid.Cells[colTrans  ,i]:='';
//              Modified:=true;
            end;
          end;
        end;
        UpdateStatusBar(Self);
      end;
    end
    else
    begin
      // mark lines as deleted
      if MessageDlg(rsDoDelete,mtConfirmation,mbOkCancel,0)=mrOk then
      begin
        for i:=TL2Grid.RowCount-1 downto 1 do
        begin
          if TL2Grid.IsCellSelected[TL2Grid.Col,i] then
          begin
            TL2Grid.Objects[1,i]:=TObject(1);
          end;
        end;
        for i:=TL2Grid.RowCount-1 downto 1 do
        begin
          if TL2Grid.Objects[1,i]<>nil then
          begin
            idx:=IntPtr(TL2Grid.Objects[0,i]);
//            data.State[idx]:=stDeleted;
            TL2Grid.DeleteRow(i);
          end;
        end;

//        Modified:=true;
        UpdateStatusBar(Self);
      end;
    end;
    Key:=0;
  end;

  if (Key=VK_RETURN) and (Shift=[ssCtrl]) then
  begin
//    actOpenSourceExecute(Sender);
    Key:=0;
  end;

  if (Key=VK_RETURN) and
     (TL2Grid.Col=colTrans) then
    TL2Grid.EditorMode:=true;

  if (Shift=[ssCtrl,ssShift]) and (Key=VK_C) then
  begin
//    ExportClipBrdClick(self);
    Key:=0;
  end;

  if (Shift=[ssCtrl]) then
  begin
    case Key of
      VK_A: begin
        TL2Grid.Selection:=
            TGridRect(Rect(colOrigin,1,colOrigin,TL2Grid.RowCount));
        Key:=0;
      end;

      VK_C: begin
//        ExportClipBrdClick(self);
        Key:=0;
      end;

      VK_V: begin
        if TL2Grid.Col=colTrans then
//          PasteFromClipBrd();
        Key:=0;
      end;
    end;
  end;

  inherited;

end;

procedure TMainTL2TransForm.TL2GridSelectCell(Sender: TObject; aCol,
  aRow: Integer; var CanSelect: Boolean);
begin
  if (aRow>0) then TL2GridClick(self);
end;

procedure TMainTL2TransForm.TL2GridSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
   ReBoundEditor;
  Editor:=memEdit;
end;

procedure TMainTL2TransForm.TL2GridSetCheckboxState(Sender: TObject; ACol,
  ARow: Integer; const Value: TCheckboxState);
var
  lidx:integer;
begin
  lidx:=IntPtr(TL2Grid.Objects[0,aRow]);
(*
  if Value=cbChecked then
  begin
    TL2Grid.Cells[colPartial,aRow]:='1';
    data.State[lidx]:=stPartial;
  end
  else
  begin
    TL2Grid.Cells[colPartial,aRow]:='0';
    if data.Trans[lidx]<>'' then
      data.State[lidx]:=stReady
    else
      data.State[lidx]:=stOriginal;
  end;
*)
//  Modified:=true;
  UpdateStatusBar(Self);
end;

function TMainTL2TransForm.MoveToIndex(idx:integer):integer;
var
  lrow:integer;
begin
  lrow:=TL2Grid.Row;
  if (lrow<(TL2Grid.RowCount-1)) and (idx=IntPtr(TL2Grid.Objects[0,lrow+1])) then TL2Grid.Row:=lrow+1
  else if (lrow>1)               and (idx=IntPtr(TL2Grid.Objects[0,lrow-1])) then TL2Grid.Row:=lrow-1
  else if (idx<>IntPtr(TL2Grid.Objects[0,lrow])) then
    for lrow:=1 to TL2Grid.RowCount-1 do
    begin
      if idx=IntPtr(TL2Grid.Objects[0,lrow]) then
      begin
        TL2Grid.Row:=lrow;
        if not TL2Grid.IsCellVisible(0,lrow) then
          TL2Grid.TopRow:=lrow;
        break;
      end;
    end;

  result:=lrow;
end;

procedure TMainTL2TransForm.UpdateGrid(idx:integer);
var
  lrow:integer;
begin
  lrow:=MoveToIndex(idx);

  TL2Grid.Cells[colTrans  ,lrow]:=TRCache[idx].dst;
  TL2Grid.Cells[colPartial,lrow]:=BoolNumber[TRCache[idx].part];
end;

function TMainTL2TransForm.FillProjectSGRow(aRow, idx:integer;
          const afilter:AnsiString):boolean;
var
  i,lcnt:integer;
  lflag:cardinal;
begin
  result:=false;

  if (TRCache[idx].flags and rfIsFiltered)=0 then exit;

  // Display Mode
  case UIntPtr(cbDisplayMode.Items.Objects[cbDisplayMode.ItemIndex]) of
    0: ;
    1: if (TRCache[idx].dst ='') or (TRCache[idx].part) then exit;
    2: if (TRCache[idx].dst ='') then exit;
    3: if not TRCache[idx].part  then exit;
    4: if (TRCache[idx].dst<>'') then exit;
    5: if (TRCache[idx].dst<>'') and (not TRCache[idx].part) then exit;
  end;

  // Filter
  if (afilter<>'') then
  begin
    if (pos(afilter,AnsiLowerCase(TRCache[idx].src))=0) and
      ((TRCache[idx].dst='') or
       (pos(afilter,AnsiLowerCase(TRCache[idx].dst))=0)) then exit;
  end;

  result:=true;

  TL2Grid.Cells[colOrigin ,aRow]:=TRCache[idx].src;
  TL2Grid.Cells[colPartial,aRow]:=BoolNumber[TRCache[idx].part];
  TL2Grid.Cells[colTrans  ,aRow]:=TRCache[idx].dst;

  TL2Grid.Objects[0,aRow]:=TObject(IntPtr(idx));
end;

procedure TMainTL2TransForm.FillProjectGrid(const afilter:AnsiString);
var
  i,lline:integer;
  lSavedRow,lSavedIdx:integer;
begin
  lSavedRow:=0;
  if TL2Grid.Row<1 then
    lSavedIdx:=0
  else
    lSavedIdx:=IntPtr(TL2Grid.Objects[0,TL2Grid.Row]);

  TL2Grid.Clear;
  TL2Grid.BeginUpdate;
  lline := 1;

  TL2Grid.RowCount:=Length(TRCache)+1;
  for i:=0 to High(TRCache) do
  begin
    if FillProjectSGRow(lline,i,afilter) then
    begin
      if (lSavedRow=0) and (lSavedIdx>=i) then lSavedRow:=lline;
      inc(lline);
    end;
  end;

  TL2Grid.RowCount:=lline;
  TL2Grid.Cells[0,0]:=IntToStr(lline-1);

  TL2Grid.EndUpdate;

  if (lSavedRow=0) and (lline>1) then lSavedRow:=1;
  TL2Grid.Row:=lSavedRow;

  if (afilter='') and Self.Active then
  begin
    TL2Grid.SetFocus;
  end;
  TL2Grid.TopRow:=TL2Grid.Row;

end;
{%ENDREGION Grid}

{%REGION Filter}
procedure TMainTL2TransForm.FillFoldersCombo(asetidx:boolean);
var
  ls:string;
  i,j,lcnt:integer;
  lskill,lroot,litems,lmonsters,lplayers,lprops:boolean;
  lfolders:TDictDynArray;
begin
  lroot    :=false;
  litems   :=false;
  lmonsters:=false;
  lplayers :=false;
  lprops   :=false;
  lskill   :=false;

  cbSkills.Clear;
  cbSkills.Sorted:=true;
  cbSkills.Items.BeginUpdate;
  cbSkills.Items.Add(rsFolderAll);

  cbFolder.Clear;
  cbFolder.Sorted:=true;
  cbFolder.Items.BeginUpdate;
  cbFolder.Items.Add(rsFolderAll);

  SetLength(lfolders,0);
  lcnt:=GetModDirList(CurMod,lfolders);

  for i:=0 to lcnt-1 do
  begin
    ls:=lfolders[i].value;
    for j:=1 to Length(ls) do
      if ls[j]='\' then ls[j]:='/'
      else ls[j]:=UpCase(ls[j]);

    if (not lroot) and (ls='MEDIA/') then
    begin
      lroot:=true;
      cbFolder.Items.Add(rsRoot);
    end
    else if Pos('SKILLS',ls)=7 then
    begin
      if not lskill then
      begin
        lskill:=true;
        cbFolder.Items.AddObject('SKILLS',TObject(rfIsSkill));
      end;
      if Length(ls)=13 then           // if we has MEDIA/SKILLS/ files
        cbSkills.Items.Add(rsRoot)
      else                            // Add subdirs (if not added yet)
      begin
        // Use just 1-st level subdirs
        for j:=14 to Length(ls) do
        begin
          if ls[j]='/' then
          begin
            ls:=Copy(ls,14,j-14);
            break;
          end;
        end;
        j:=1;
        while j<cbSkills.Items.Count do
        begin
          if ls=cbSkills.Items[j] then break;
          inc(j);
        end;
        if j=cbSkills.Items.Count then
          cbSkills.Items.Add(ls);
      end;

    end
    else if (Pos('UNITS',ls)=7) then
    begin
      // second letter of folder
      case ls[14] of
        'T': if (not litems) then
        begin
          litems:=true;
          cbFolder.Items.AddObject('ITEMS',TObject(rfIsItem));
        end;

        'O': if (not lmonsters) then
        begin
          lmonsters:=true;
          cbFolder.Items.AddObject('MONSTERS',TObject(rfIsMob));
        end;

        'L': if (not lplayers) then
        begin
          lplayers:=true;
          cbFolder.Items.AddObject('PLAYERS',TObject(rfIsPlayer));
        end;

        'R': if (not lprops) then
        begin
          lprops:=true;
          cbFolder.Items.AddObject('PROPS',TObject(rfIsProp));
        end;
      end;
    end
    else
    begin
      j:=7;
      while j<=Length(ls) do
      begin
        if ls[j]='/' then
        begin
          ls:=Copy(ls,7,j-7);
          cbFolder.Items.Add(ls);
          break;
        end;
        inc(j);
      end;
    end;
  end;

  cbSkills.Items.EndUpdate;
  cbSkills.ItemIndex:=0;

  cbFolder.Items.EndUpdate;
  if asetidx then
  begin
    cbFolder.ItemIndex:=0;
    cbFolderChange(Self);
  end;
end;

procedure TMainTL2TransForm.cbFolderChange(Sender: TObject);
var
  lfolder:string;
  i,lflag:integer;
begin
  if cbFolder.ItemIndex<0 then
     cbFolder.ItemIndex:=0;

  if cbFolder.ItemIndex=0 then
  begin
    for i:=0 to High(TRCache) do
      TRCache[i].flags:=TRCache[i].flags or rfIsFiltered;
  end
  else
  begin
    if (cbFolder.ItemIndex=1) and (cbFolder.Items[1][1]='-') then
      lfolder:=''
    else
    begin
      lfolder:=cbFolder.Items[cbFolder.ItemIndex];

      if lfolder='SKILLS' then
      begin
        pnlSkills.Visible:=true;
        splSkills.Visible:=true;

        cbSkillsChange(Sender);
        exit;
      end;
    end;

    lflag:=IntPtr(cbFolder.Items.Objects[cbFolder.ItemIndex]);
    if (lflag<>0) then
    begin
      for i:=0 to High(TRCache) do
        if ((TRCache[i].flags and rfIsReferred) =0) or
           ((TRCache[i].flags and lflag       )<>0) then
          TRCache[i].flags:=TRCache[i].flags or rfIsFiltered
        else
          TRCache[i].flags:=TRCache[i].flags and not rfIsFiltered;
    end
    else
      CheckForDirectory('MEDIA/'+lfolder);

  end;

  pnlSkills.Visible:=false;
  splSkills.Visible:=false;

  edProjectFilterChange(Sender);
end;

procedure TMainTL2TransForm.cbSkillsChange(Sender: TObject);
var
  i:integer;
begin
  if cbSkills.ItemIndex<0 then
     cbSkills.ItemIndex:=0;

  if cbSkills.ItemIndex=0 then
  begin
    for i:=0 to High(TRCache) do
      if ((TRCache[i].flags and rfIsReferred) =0) or
         ((TRCache[i].flags and rfIsSkill   )<>0) then
        TRCache[i].flags:=TRCache[i].flags or rfIsFiltered
      else
        TRCache[i].flags:=TRCache[i].flags and not rfIsFiltered;
  end
  else if (cbSkills.ItemIndex=1) and (cbSkills.Items[1][1]='-') then
    CheckForDirectory('MEDIA/SKILLS/')
  else// if cbSkills.ItemIndex<>0 then
    CheckForDirectory('MEDIA/SKILLS/'+cbSkills.Items[cbSkills.ItemIndex]+'/');

  edProjectFilterChange(Sender);
end;

procedure TMainTL2TransForm.edProjectFilterChange(Sender: TObject);
var
  ls:AnsiString;
begin
  if Length(edProjectFilter.Text)<4 then
    ls:=''
  else
    ls:=AnsiLowerCase(edProjectFilter.Text);

  // crazy logic
  if actFilter.Checked then
  begin
    if ls='' then
    begin
      if TL2Grid.RowCount<>(Length(TRCache)+1) then
        FillProjectGrid('')
      else if (Sender=cbDisplayMode) then
        FillProjectGrid('')
      else
        exit;
    end
    else
    begin
      FillProjectGrid(ls)
    end
  end
  else
  begin
    if Sender<>edProjectFilter then
      FillProjectGrid('');
    if ls<>'' then
      Search(ls,TL2Grid.Row);
  end;
end;
{%ENDREGION Filter}

end.

