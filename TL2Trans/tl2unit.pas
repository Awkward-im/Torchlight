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
    FileBuild: TAction;
    HelpNotes: TAction;
    ClosePage: TAction;
    bbCloseTree: TBitBtn;
    cbScanCurDir: TCheckBox;
    FileExit: TAction;
    FileExport: TAction;
    FileNew: TAction;
    FileOpen: TAction;
    FileSave: TAction;
    FileSaveAs: TAction;
    FontEdit: TFontEdit;
    gbScanObjects: TGroupBox;
    HelpAbout: TAction;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    rbScanKnown: TRadioButton;
    rbScanText: TRadioButton;
    TL2ActionList: TActionList;
    TL2Toolbar: TToolBar;
    tbFileNew: TToolButton;
    tbFileOpen: TToolButton;
    tbFileSave: TToolButton;
    tbSeparator1: TToolButton;
    tbFileExport: TToolButton;
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
    miFileExport: TMenuItem;
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
    procedure HelpNotesExecute(Sender: TObject);
    procedure bbCloseTreeClick(Sender: TObject);
    procedure ClosePageExecute(Sender: TObject);
    procedure FileBuildExecute(Sender: TObject);
    procedure FileExitExecute(Sender: TObject);
    procedure FileExportExecute(Sender: TObject);
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
    procedure TL2PageControlChange(Sender: TObject);
    procedure TL2PageControlMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TL2ShellTreeViewDblClick(Sender: TObject);
    procedure TL2ShellTreeViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

  private
    function CanClosePage(idx: integer): boolean;
    procedure CreateSettingsTab;
    procedure NewTab(const aname: AnsiString);

    procedure SetTabCaption(const anAction:AnsiString);
    procedure UpdateStatusBar(Sender:TObject; const SBText:AnsiString='');
  public

  end;

var
  MainTL2TransForm: TMainTL2TransForm;

implementation

{$R *.lfm}

uses
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
  sExporting      = '(exporting)';

function ExtractJustName(const fname:AnsiString):AnsiString;
var
  i:integer;
begin
  i:=Length(fname);
  while (i>1) and (fname[i]<>'.') do dec(i);
  if i>1 then result:=Copy(fname,1,i-1)
  else result:=fname;
end;

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
  fileExport.Enabled:=b;

  UpdateStatusBar(ActiveProject);
end;

procedure TMainTL2TransForm.TL2PageControlMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TPOINT;
  i: Integer;
begin
  if Button = mbMiddle then
  begin
    p.x := X;
    p.y := Y;
//    p:=TL2PageControl.ScreenToClient(p);
    i:=TL2PageControl.IndexOfPageAt(p);
    if i = -1 then exit;
    CanClosePage(i);
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

    ProjectName:=aname;
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

  if anAction='' then
  begin
    if prj.Modified then ls:='* '+prj.ProjectName
    else ls:=prj.ProjectName
  end
  else ls:=anAction+' '+prj.ProjectName;

  TL2PageControl.ActivePage.Caption:=ls;

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
    TL2StatusBar.SimpleText:=TTL2Project(Sender).StatusBarText;
    SetTabCaption('');
  end;
end;

procedure TMainTL2TransForm.FormCreate(Sender: TObject);
begin
  CreateSettingsTab;
  Self.Font.Assign(TL2DM.TL2Font);
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
    ActiveProject.TL2ProjectGrid.SetFocus;
  end;

  inherited;
end;

function TMainTL2TransForm.CanClosePage(idx:integer):boolean;
var
  ltab:TTabSheet;
  lprj:TTL2Project;
begin
  result:=false;

  TL2PageControl.ActivePageIndex:=idx;
  lprj:=ActiveProject;
  if lprj<>nil then
    while lprj.Modified do
      case MessageDlg(sNotSaved,mtWarning,[mbCancel,mbNo,mbOk],0,mbCancel) of
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
  result:=true;

  TL2PageControl.ActivePageIndex:=idx-1;
  ltab:=TL2PageControl.Pages[idx];
  ltab.Parent:=nil;
  ltab.Free;
end;

procedure TMainTL2TransForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  i:integer;
begin
  CanClose:=true;
  for i:=TL2PageControl.PageCount-1 downto 1 do
    CanClose:=CanClose and CanClosePage(i);
end;

//----- Tree view -----

procedure TMainTL2TransForm.bbCloseTreeClick(Sender: TObject);
begin
  TL2TreePanel.Visible:=false;
end;

procedure TMainTL2TransForm.HelpNotesExecute(Sender: TObject);
begin
  if TL2Notes=nil then
    TL2Notes:=TTL2Notes.Create(Self);
  TL2Notes.Show;
end;

procedure TMainTL2TransForm.TL2ShellTreeViewDblClick(Sender: TObject);
var
  lname:AnsiString;
begin
  if MessageDlg(sDoTheScan,sDoProcessScan,mtConfirmation,[mbOk,mbCancel],0)=mrOk then
  begin
    TL2TreePanel.Visible:=false;

    lname:=TL2ShellTreeView.Path;
    if lname[Length(lname)]='\' then
      SetLength(lname,Length(lname)-1);
    lname:=ExtractFileName(lname);

    NewTab(lname);
    SetTABCaption(sScanning);
    if not ActiveProject.New(TL2ShellTreeView.Path,
        rbScanText.Checked,not cbScanCurDir.Checked) then
    CanClosePage(TL2PageControl.ActivePageIndex);
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
begin
  if TL2PageControl.PageIndex>0 then
    CanClosePage(TL2PageControl.PageIndex);
end;

procedure TMainTL2TransForm.FileBuildExecute(Sender: TObject);
begin
  Build(@UpdateStatusBar);
end;

procedure TMainTL2TransForm.FileNewExecute(Sender: TObject);
begin
  try
    TL2ShellTreeView.Root:=TL2Settings.edRootDir.Text;
  except
    TL2ShellTreeView.Root:='';
  end;
  TL2ShellTreeView.Refresh(nil);
  TL2TreePanel.Visible:=true;
  TL2ShellTreeView.SetFocus;
end;

procedure TMainTL2TransForm.FileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  lname:AnsiString;
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
        lname:=ExtractJustName(ExtractFileName(OpenDialog.Files[fcnt]));

        NewTab(lname);
        SetTABCaption(sLoading);
        ActiveProject.Load(OpenDialog.Files[fcnt]);
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
      ls:=ExtractFileName(SaveDialog.Filename);
      if (ls<>'') then
      begin
        prj.FileName   :=SaveDialog.Filename;
        prj.ProjectName:=ExtractJustName(ls);

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

procedure TMainTL2TransForm.FileExportExecute(Sender: TObject);
begin
  SetTABCaption(sExporting);
  ActiveProject.DoExport();
  SetTABCaption('');
end;

procedure TMainTL2TransForm.FileExitExecute(Sender: TObject);
begin
  Close;
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

procedure TMainTL2TransForm.HelpAboutExecute(Sender: TObject);
begin
  with TAboutForm.Create(Self) do ShowModal;
end;


end.

