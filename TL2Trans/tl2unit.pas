unit TL2Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  ShellCtrls, ExtCtrls, StdCtrls, Buttons, ActnList,
  LCLType,StdActns;

type

  { TMainTL2TransForm }

  TMainTL2TransForm = class(TForm)
    actShowLog: TAction;
    actModInfo: TAction;
    FileScan: TAction;
    FileBuild: TAction;
    HelpNotes: TAction;
    ClosePage: TAction;
    bbCloseTree: TBitBtn;
    cbScanCurDir: TCheckBox;
    FileExit: TAction;
    FileNew: TAction;
    FileOpen: TAction;
    FileSave: TAction;
    FileSaveAs: TAction;
    FontEdit: TFontEdit;
    gbScanObjects: TGroupBox;
    HelpAbout: TAction;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    miFileBuild: TMenuItem;
    miFileScanMod: TMenuItem;
    mnuClosePage: TMenuItem;
    rbScanKnown: TRadioButton;
    rbScanText: TRadioButton;
    TabPopup: TPopupMenu;
    TL2ActionList: TActionList;
    TL2Toolbar: TToolBar;
    tbFileNew: TToolButton;
    tbFileOpen: TToolButton;
    tbFileSave: TToolButton;
    tbSeparator1: TToolButton;
    tbModInfo: TToolButton;
    tbHelpAbout: TToolButton;
    tbFontEdit: TToolButton;
    tbSeparator2: TToolButton;
    lblTreeNotes: TLabel;
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
    TL2TreePanel: TPanel;
    TL2PageControl: TPageControl;
    TL2Splitter: TSplitter;
    TL2ShellTreeView: TShellTreeView;
    TL2StatusBar: TStatusBar;
    tbHelpNotes: TToolButton;
    tbBuild: TToolButton;
    tbScanMod: TToolButton;
    tbShowLog: TToolButton;
    procedure actModInfoExecute(Sender: TObject);
    procedure actShowLogExecute(Sender: TObject);
    procedure FileScanExecute(Sender: TObject);
    procedure HelpNotesExecute(Sender: TObject);
    procedure bbCloseTreeClick(Sender: TObject);
    procedure ClosePageExecute(Sender: TObject);
    procedure FileBuildExecute(Sender: TObject);
    procedure FileExitExecute(Sender: TObject);
    procedure FileNewExecute(Sender: TObject);
    procedure FileOpenExecute(Sender: TObject);
    procedure FileSaveAsExecute(Sender: TObject);
    procedure FileSaveExecute(Sender: TObject);
    procedure FontEditAccept(Sender: TObject);
    procedure FontEditBeforeExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HelpAboutExecute(Sender: TObject);
    procedure mnuClosePageClick(Sender: TObject);
    procedure TL2PageControlChange(Sender: TObject);
    procedure TL2PageControlCloseTabClicked(Sender: TObject);
    procedure TL2PageControlMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TL2ShellTreeViewDblClick(Sender: TObject);
    procedure TL2ShellTreeViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

  private
    function CanClosePage(idx: integer;out s:String): boolean;
    procedure CreateSettingsTab;
    procedure NewTab(const aname: AnsiString);
    procedure OpenProject(const fname:string; silent:boolean=false);

    procedure SetTabCaption(const anAction:AnsiString);
    procedure UpdateStatusBar(Sender:TObject; const SBText:AnsiString='');
  public

  end;

var
  MainTL2TransForm: TMainTL2TransForm;

implementation

{$R *.lfm}

uses
  rgglobal,
  fmmodinfo,
  unitLogForm,
  TL2DataModule,
  TL2ProjectForm,
  TL2SettingsForm,
  TL2NotesForm,
  TL2About;

{ TMainTL2TransForm }

resourcestring
  sDefaultCaption = 'Torchlight 2 Translation';
  sOpenProject    = 'Open project';
  sSaveProject    = 'Save project';
  sNotSaved       = 'Project modified. Do you want to save it?';
  sDoTheScan      = 'Do tree scan?';
  sDoProcessScan  = 'Do you want to scan this directory?';
  sScanning       = '(scanning)';
  sLoading        = '(loading)';
  sSaving         = '(saving)';
  sWrongDir       = 'Choosed directory don''t looks like mod directory (have no MEDIA folder)';


//----- Page control -----

function ActiveProject:TTL2Project;
begin
  if (MainTL2TransForm.TL2PageControl.PageIndex>0) and
     (MainTL2TransForm.TL2PageControl.ActivePage.Tag=0) then
    result:=MainTL2TransForm.TL2PageControl.ActivePage.Components[0] as TTL2Project
  else
    result:=nil;
end;

procedure TMainTL2TransForm.TL2PageControlChange(Sender: TObject);
var
  b:boolean;
begin
  b:=TL2PAgeControl.ActivePageIndex<>0;
  FileSave  .Enabled:=b;
  FileSaveAs.Enabled:=b;
  actModInfo.Enabled:=b;

  UpdateStatusBar(ActiveProject);
end;

procedure TMainTL2TransForm.TL2PageControlCloseTabClicked(Sender: TObject);
begin
  ClosePageExecute(Sender);
end;

procedure TMainTL2TransForm.mnuClosePageClick(Sender: TObject);
var
  ls:string;
begin
  CanClosePage(TabPopup.Tag,ls);
end;

procedure TMainTL2TransForm.TL2PageControlMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TPOINT;
  ls:string;
  ltab: Integer;
begin
  p.x := X;
  p.y := Y;
//    p:=TL2PageControl.ScreenToClient(p);
  ltab:=TL2PageControl.IndexOfPageAt(p);
  if ltab = -1 then exit;

  if Button = mbMiddle then
  begin
    CanClosePage(ltab,ls);
  end
  else if Button = mbRight then
  begin
    TabPopup.Tag:=ltab;
    TabPopup.PopUp;
  end;
end;

procedure TMainTL2TransForm.NewTab(const aname:AnsiString);
var
  ts:TTabSheet;
begin
  ts:=TL2PageControl.AddTabSheet;
  ts.ShowHint:=false;
  ts.Caption :=aname;

  with TTL2Project.Create(ts) do
  begin
    Parent :=ts;
    Align  :=alClient;
    Visible:=true;
    OnSBUpdate:=@UpdateStatusBar;

    ProjectName:=ExtractNameOnly(aname);
  end;

  TL2PageControl.ActivePage:=ts;
end;

procedure TMainTL2TransForm.CreateSettingsTab;
var
  ts:TTabSheet;
begin
  ts:=TL2PageControl.AddTabSheet;
  ts.ShowHint:=false;
  with TTL2Settings.Create(ts) do
  begin
    ts.Caption:=Caption;
    Parent :=ts;
    Align  :=alClient;
    Visible:=true;
  end;
  TL2PageControl.ActivePage:=ts;
end;

//----- Form -----

procedure TMainTL2TransForm.SetTabCaption(const anAction:AnsiString);
var
  ls:AnsiString;
  prj:TTL2Project;
begin
  prj:=ActiveProject;

  if prj=nil then exit;

  if (anAction='') and (prj.Modified) then ls:='*' else ls:=anAction;

  TL2PageControl.ActivePage.Caption:=ls+' '+prj.ProjectName;

  Application.ProcessMessages;
end;

procedure TMainTL2TransForm.UpdateStatusBar(Sender:TObject; const SBText:AnsiString='');
begin
  if Sender=nil then
  begin
    TL2StatusBar.SimpleText:='';
    Self.Caption:=sDefaultCaption;
  end
  else if SBText<>'' then
  begin
    TL2StatusBar.SimpleText:=SBText;
    Application.ProcessMessages;
  end
  else
  begin
    Self.Caption:=sDefaultCaption+' - '+TTL2Project(Sender).ProjectName;
    SetTabCaption('');
  end;
end;

procedure TMainTL2TransForm.FormCreate(Sender: TObject);
var
  lsl:TStringList;
  i:integer;
begin
  CreateSettingsTab;
  Self.Font.Assign(TL2DM.TL2Font);
  fmLogForm:=nil;

  if ParamCount()>0 then
  begin
    OpenProject(ParamStr(1),true);
    TL2Settings.cbReopenProjects.Checked:=false;
  end;

  if TL2Settings.cbReopenProjects.Checked then
  begin
    lsl:=TStringList.Create;
    TL2Settings.LoadTabs(lsl);
    for i:=0 to lsl.Count-1 do
      OpenProject(lsl[i],true);
    lsl.Free;
  end;
end;

procedure TMainTL2TransForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  lprj:TTL2Project;
  i:integer;
begin
  i:=-1;

  if Key=VK_ESCAPE then
  begin
    lprj:=ActiveProject;
    if lprj<>nil then
      lprj.actStopScanExecute(Sender);
  end;

  if (ssAlt in Shift) then
  begin
    case Key of
      VK_0: i:=0;
      VK_1: i:=1;
      VK_2: i:=2;
      VK_3: i:=3;
      VK_4: i:=4;
      VK_5: i:=5;
      VK_6: i:=6;
      VK_7: i:=7;
      VK_8: i:=8;
      VK_9: i:=9;
    end;
    if i>=0 then
    begin
      if i>=TL2PageControl.PageCount then i:=TL2PageControl.PageCount-1;
      TL2PageControl.ActivePageIndex:=i;
      Key:=0;
    end;
  end;

  if (Key=VK_TAB) and (ssCtrl in Shift) then
  begin
//    TL2PageControl.SelectNextPage(not (ssShift in Shift));

    if ssShift in Shift then
    begin
      i:=TL2PageControl.ActivePageIndex-1;
      if i<0 then i:=TL2PageControl.PageCount-1;
    end
    else
    begin
      i:=TL2PageControl.ActivePageIndex+1;
      if i=TL2PageControl.PageCount then i:=0;
    end;
    TL2PageControl.ActivePageIndex:=i;

    Key:=0;
  end;

  if i>0 then
  begin
    ActiveProject.TL2Grid.SetFocus;
  end;

  inherited;
end;

function TMainTL2TransForm.CanClosePage(idx:integer; out s:string):boolean;
var
  ltab:TTabSheet;
  lprj:TTL2Project;
begin
  result:=false;
  s:='';

  TL2PageControl.ActivePageIndex:=idx;
  lprj:=ActiveProject;
  if lprj<>nil then
  begin
    while lprj.Modified do
      case MessageDlg(sNotSaved,mtWarning,mbYesNoCancel,0,mbCancel) of
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
  end;
  result:=true;

  TL2PageControl.ActivePageIndex:=idx-1;
  ltab:=TL2PageControl.Pages[idx];
//  TL2PageControl.RemoveControl(TControl(TL2PageControl.Pages[idx]));// удаление таба
  ltab.Parent:=nil;
  ltab.Free;
end;

procedure TMainTL2TransForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  lsl:TStringList;
  ls:String;
  i:integer;
begin
  CanClose:=true;
  if TL2Settings.cbReopenProjects.Checked then
  begin
    lsl:=TStringList.Create;
    for i:=1 to TL2PageControl.PageCount-1 do
      lsl.Add('');
  end;

  for i:=TL2PageControl.PageCount-1 downto 1 do
  begin
    ls:='';
    CanClose:=CanClose and CanClosePage(i,ls);
    if TL2Settings.cbReopenProjects.Checked and
       (ls<>'') then lsl[i-1]:=ls;
  end;
  if TL2Settings.cbReopenProjects.Checked then
  begin
    if CanClose then TL2Settings.SaveTabs(lsl);
    lsl.Free;
  end;
end;

//----- Tree view -----

procedure TMainTL2TransForm.bbCloseTreeClick(Sender: TObject);
begin
  TL2TreePanel.Visible:=false;
end;

procedure TMainTL2TransForm.TL2ShellTreeViewDblClick(Sender: TObject);
var
  ls,lname:AnsiString;
begin
  if MessageDlg(sDoTheScan,sDoProcessScan,mtConfirmation,mbOkCancel,0)=mrOk then
  begin
    TL2TreePanel.Visible:=false;

    lname:=TL2ShellTreeView.Path;
    if lname[Length(lname)] in ['\','/'] then
      SetLength(lname,Length(lname)-1);
    lname:=ExtractName(lname);

    NewTab(lname);
    SetTABCaption(sScanning);
    if not ActiveProject.NewFromDir(TL2ShellTreeView.Path,
        rbScanText.Checked,not cbScanCurDir.Checked) then
    CanClosePage(TL2PageControl.ActivePageIndex,ls);
  end;
end;

procedure TMainTL2TransForm.TL2ShellTreeViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_RETURN then
    TL2ShellTreeViewDblClick(Sender);

  inherited;
end;

//----- Actions -----

procedure TMainTL2TransForm.ClosePageExecute(Sender: TObject);
var
  ls:string;
begin
  if TL2PageControl.PageIndex>0 then
    CanClosePage(TL2PageControl.PageIndex,ls);
end;

procedure TMainTL2TransForm.FileExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainTL2TransForm.FileBuildExecute(Sender: TObject);
begin
  NewTab('Build Translation');
  ActiveProject.Build;
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
      NewTab(OpenDialog.FileName);
      SetTABCaption(sScanning);
      if not ActiveProject.NewFromFile(OpenDialog.FileName) then
        CanClosePage(TL2PageControl.ActivePageIndex,ls);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TMainTL2TransForm.actModInfoExecute(Sender: TObject);
var
  prj:TTL2Project;
begin
  prj:=ActiveProject;
  if prj=nil then exit;

  with TMODInfoForm.Create(Self,nil,true) do
  begin
    Title :=prj.data.ModTitle;
    Author:=prj.data.ModAuthor;
    Descr :=prj.data.ModDescr;
    ID    :=prj.data.ModID;
    ShowModal;
    Free;
  end;
end;

procedure TMainTL2TransForm.actShowLogExecute(Sender: TObject);
begin
  if fmLogForm=nil then
  begin
    fmLogForm:=TfmLogForm.Create(Self);
    fmLogForm.memLog.Text:=RGLog.Text;
  end;
  fmLogForm.ShowOnTop;
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
        ShowMessage(sWrongDir);
        exit;
      end;

      NewTab(ls);
      SetTABCaption(sScanning);
      if not ActiveProject.NewFromDir(ls,false,true) then
        CanClosePage(TL2PageControl.ActivePageIndex,ls);
    end;
  finally
    ldlg.Free;
  end;
end;

procedure TMainTL2TransForm.OpenProject(const fname:string; silent:boolean=false);
var
  lname:string;
begin
  if not FileExists(fname) then exit;

  lname:=ExtractNameOnly(fname);

  NewTab(lname);
  SetTABCaption(sLoading);
  if not ActiveProject.Load(fname,silent) then
    CanClosePage(TL2PageControl.ActivePageIndex,lname);
end;

procedure TMainTL2TransForm.FileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  fcnt:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.InitialDir:=TL2Settings.edWorkDir.Text;
    OpenDialog.DefaultExt:=DefaultExt;
    OpenDialog.Filter    :=DefaultFilter;
    OpenDialog.Title     :=sOpenProject;
    OpenDialog.Options   :=[ofAllowMultiSelect];

    if OpenDialog.Execute then
    begin
      for fcnt:=0 to OpenDialog.Files.Count-1 do
      begin
        OpenProject(OpenDialog.Files[fcnt]);
      end;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TMainTL2TransForm.FileSaveAsExecute(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  prj:TTL2Project;
  ls:AnsiString;
begin
  SaveDialog:=TSaveDialog.Create(nil);
  try
    prj:=ActiveProject;
    SaveDialog.InitialDir:=TL2Settings.edWorkDir.Text;

    ls:=TL2Settings.edTransLang.Text;
    if (ls<>'') and (Pos('.'+ls,prj.ProjectName)=0) then
      ls:=prj.ProjectName+'.'+ls
    else
      ls:=prj.ProjectName;

    SaveDialog.FileName  :=ls;
    SaveDialog.DefaultExt:=DefaultExt;
    SaveDialog.Filter    :=DefaultFilter;
    SaveDialog.Title     :=sSaveProject;
    SaveDialog.Options   :=SaveDialog.Options+[ofOverwritePrompt,ofNoChangeDir];
    if (SaveDialog.Execute) then
    begin
      ls:=ExtractNameOnly(SaveDialog.Filename);
      if (ls<>'') then
      begin
        prj.FileName   :=SaveDialog.Filename;
        prj.ProjectName:=ls;

        FileSaveExecute(Sender);
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TMainTL2TransForm.FileSaveExecute(Sender: TObject);
var
  prj:TTL2Project;
begin
  prj:=ActiveProject;
  if prj.FileName='' then
  begin
    FileSaveAsExecute(Sender);
    exit;
  end;

  SetTABCaption(sSaving);
  prj.Save;
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


end.

