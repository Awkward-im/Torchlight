{TODO: PreviewSource: autoformat if no block spaces. Add to synedit with line by line}
{TODO: show layout game version at least for changed/added files}
{TODO: Save pak or file: check setData binary files version, repack if needs}
{TODO: add icon extract by imageset}
{TODO: add hash calc and brute form}
{TODO: 1-setting to save linked file on disk/mem; 2-ask every time/once}
{TODO: save as for editor}
{TODO: memory settings: max size to load PAK into memory}
{TODO: Add file search}
{TODO: Implement to open DIR (not PAK/MOD/MAN) = ctrl.AddDirectory}
{TODO: StatusBar: change statistic when add/delete dir/file}
{TODO: StatusBar: path changes on dir with files only}
{TODO: option: keep PAK open}
{TODO: option: ask unpack path}
{TODO: replace bitbutton by speed button (scale problem)}
{TODO: change grid/preview border moving}
unit formGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids, Menus,
  ActnList, ExtCtrls, StdCtrls, EditBtn, Buttons, TreeFilterEdit,
  SynEdit, SynHighlighterXML, SynHighlighterT, SynEditTypes, SynPopupMenu,
  rgglobal, rgpak, rgctrl, Types, fmLayoutEdit, SynHighlighterOgre;

type

  { TRGGUIForm }

  TRGGUIForm = class(TForm)
    bbPlay: TBitBtn;
    bbStop: TBitBtn;
    cbSaveTL1ADM: TCheckBox;
    pnlAudio: TPanel;
    Setings: TTabSheet;
    cbUnpackTree  : TCheckBox;
    cbMODDAT      : TCheckBox;
    cbSaveSettings: TCheckBox;
    cbSaveWidth   : TCheckBox;
    cbFastScan    : TCheckBox;
    cbTest        : TCheckBox;
    cbUseFName    : TCheckBox;
    lblOutDir     : TLabel;
    deOutDir      : TDirectoryEdit;

    gbDecoding: TGroupBox;
    rbGUTSStyle : TRadioButton;
    rbTextRename: TRadioButton;
    rbBinOnly   : TRadioButton;
    rbTextOnly  : TRadioButton;
    cbSaveUTF8  : TCheckBox;

    edGridFilter: TEdit;
    imgPreview: TImage;
    ilBookmarks: TImageList;
    ilMain     : TImageList;
    PageControl: TPageControl;

    pnlTree      : TPanel;
    pnlTreeFilter: TPanel;
    edTreeFilter : TTreeFilterEdit;
    bbCollapse   : TBitBtn;
    tbOpenDir: TToolButton;
    tvTree       : TTreeView;

    Grid   : TTabSheet;
    pnlAdd : TPanel;
    pnlInfo: TPanel;
    lblSize  : TLabel;  lblSizeVal  : TLabel;
    lblTime  : TLabel;  lblTimeVal  : TLabel;
    lblOffset: TLabel;  lblOffsetVal: TLabel;

    ReplaceDialog: TReplaceDialog;
    sgMain: TStringGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar: TStatusBar;
    SynEdit     : TSynEdit;
    SynPopupMenu: TSynPopupMenu;
    SynTSyn     : TSynTSyn;
    SynOgreSyn  : TSynOgreSyn;
    SynXMLSyn   : TSynXMLSyn;

    ToolBar: TToolBar;
    tbOpen     : TToolButton;
    tbSave     : TToolButton;
    tbSaveAs   : TToolButton;
    tbSep1     : TToolButton;
    tbInfo     : TToolButton;
    tbShowLog  : TToolButton;
    tbResetView: TToolButton;

    mnuGrid: TPopupMenu;
    miGridExport: TMenuItem;
    miGridNew   : TMenuItem;
    miImportDir : TMenuItem;
    miGridAdd   : TMenuItem;
    miGridRename: TMenuItem;
    miGridReset : TMenuItem;
    miGridDelete: TMenuItem;

    mnuTree: TPopupMenu;
    miTreeExtract       : TMenuItem;
    miTreeExtractDir    : TMenuItem;
    miTreeExtractVisible: TMenuItem;
    miTreeNew           : TMenuItem;
    miTreeAdd           : TMenuItem;
    miTreeDelete        : TMenuItem;
    miTreeRestore       : TMenuItem;

    MainMenu: TMainMenu;
    miFile: TMenuItem;
    miFileOpen   : TMenuItem;
    miFileSave   : TMenuItem;
    miFileSaveAs : TMenuItem;
    miFileClose  : TMenuItem;
    N1           : TMenuItem;
    miFileExit   : TMenuItem;
    miEdit: TMenuItem;
    miEditExtract: TMenuItem;
    miEditSearch : TMenuItem;
    miEditReplace: TMenuItem;
    miEditDelete : TMenuItem;
    N2           : TMenuItem;
    miChangeVersion: TMenuItem;
    miHelp: TMenuItem;
    miHelpAbout  : TMenuItem;
    miHelpShowLog: TMenuItem;

    ActionList: TActionList;
    actFileOpen   : TAction;
    actFileSave   : TAction;
    actFileSaveAs : TAction;
    actFileClose  : TAction;
    actFileExit   : TAction;
    actHelpAbout  : TAction;
    actShowInfo   : TAction;
    actShowLog    : TAction;

    actShowPreview: TAction;
    actScaleImage : TAction;
    actEdNew      : TAction;
    actEdDelete   : TAction;
    actEdReset    : TAction; // Reset content to container
    actEdUndo     : TAction; // Reset content to last
    actEdSave     : TAction; // Save for update
    actEdImport   : TAction; // Load (import) content
    actEdExport   : TAction; // Export content
    actEdSearch   : TAction; // Seacrh/replace
    actEdRename   : TAction;
    actEdImportDir: TAction;

    actChangeVersion: TAction;
    actOpenDir    : TAction;
    actShowFilter : TAction;
    actResetView  : TAction;

    tbGrid: TToolBar;
    tbEdPreview  : TToolButton;
    tbEdScale    : TToolButton; // Show when Image selected
    tbEdSep1: TToolButton;
    tbEdReset    : TToolButton; // Show wnen any file selected
    tbEdUndo     : TToolButton; // Show wnen any file selected
    tbEdSave     : TToolButton; // Show wnen any file selected
    tbEdSep2: TToolButton;
    tbEdSearch   : TToolButton; // Show wnen text file selected
    tbEdSep3: TToolButton;
    tbEdImport   : TToolButton;
    tbEdExport   : TToolButton; // Show wnen any file selected
    tbEdSep4: TToolButton;
    tbFilter     : TToolButton;
    tbColCategory: TToolButton;
    tbColDir     : TToolButton;
    tbColExt     : TToolButton;
    tbColPacked  : TToolButton;
    tbColSource  : TToolButton;
    tbColTime    : TToolButton;
    tbColUnpacked: TToolButton;

    procedure actChangeVersionExecute(Sender: TObject);
    procedure actEdDeleteExecute(Sender: TObject);
    procedure actEdExportExecute(Sender: TObject);
    procedure actEdImportDirExecute(Sender: TObject);
    procedure actEdImportExecute(Sender: TObject);
    procedure actEdNewExecute(Sender: TObject);
    procedure actEdRenameExecute(Sender: TObject);
    procedure actEdResetExecute(Sender: TObject);
    procedure actEdSaveExecute(Sender: TObject);
    procedure actEdSearchExecute(Sender: TObject);
    procedure actEdUndoExecute(Sender: TObject);
    procedure actFileCloseExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileSaveAsExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure actOpenDirExecute(Sender: TObject);
    procedure actShowInfoExecute(Sender: TObject);
    procedure actShowFilterExecute(Sender: TObject);
    procedure actShowLogExecute(Sender: TObject);
    procedure actScaleImageExecute(Sender: TObject);
    procedure actResetViewExecute(Sender: TObject);
    procedure actPreviewExecute(Sender: TObject);
    procedure bbCollapseClick(Sender: TObject);
    procedure bbPlayClick(Sender: TObject);
    procedure bbStopClick(Sender: TObject);
    procedure edGridFilterChange(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure miTreeDeleteClick(Sender: TObject);
    procedure miTreeNewClick(Sender: TObject);
    procedure miTreeRestoreClick(Sender: TObject);
    procedure ReplaceExecute(Sender: TObject);
    procedure SetupColumns(Sender: TObject);
    procedure DoExtractDir(Sender: TObject);
    procedure DoExtractGrid(Sender: TObject);
    procedure DoExtractTree(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sgMainCompareCells(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
    procedure sgMainContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure sgMainDblClick(Sender: TObject);
    procedure sgMainGetCellHint(Sender: TObject; ACol, ARow: Integer; var HintText: String);
    procedure sgMainHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure sgMainHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure sgMainKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgMainSelection(Sender: TObject; aCol, aRow: Integer);
    procedure SynEditStatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure tbColumnClick(Sender: TObject);
    procedure tvTreeContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure tvTreeSelectionChanged(Sender: TObject);
  private
    FUData:pointer;
    fmi:TForm;
    fmLEdit:TForm;
    ctrl:TRGController;
    LastExt:string;
    LastFilter:integer;
    FLastIndex:integer;
    FUSize:integer;
    sstream:THandle; // sound playing stream handle
    inProcess:boolean;
    sgSortColumn:integer;
    bShowDir     : Boolean;
    bShowExt     : Boolean;
    bShowCategory: Boolean;
    bShowTime    : Boolean;
    bShowPacked  : Boolean;
    bShowUnpacked: Boolean;
    bShowSource  : Boolean;
    PopupNode: TTreeNode;

    procedure AddNewDir(anode: TTreeNode; const apath: string);
    procedure ClearInfo();
    function FileClose: boolean;
    procedure FillGrid(idx:integer=-1);
    function  FillGridLine(arow: integer; const adir: string; afile: integer): boolean;
    procedure FillTree();
    procedure AddBranch(aroot: TTreeNode; const aname: string);
    function  GetPathFromNode(aNode: TTreeNode): string;
    procedure MarkTree(adir: integer; aEnable: boolean);
    procedure NewPAK;
    procedure OpenPAK(const aname: string);
    procedure PrepareSound;
    procedure PreviewSound;
    function  SaveFile(const adir, aname: string; adata: PByte; asize:integer): boolean;
    procedure PreviewImage(const aext: string);
    procedure PreviewSource();
    procedure PreviewLayout();
    procedure PreviewText();
    procedure LoadSettings;
    procedure SaveSettings;
    procedure SetupView;
    function  UnpackSingleFile(const adir, aname: string; var buf:PByte): boolean;
    procedure ExtractSingleDir(adir: integer; var buf:PByte);
    procedure UpdateStatistic;
    function  OnImportDouble(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction;

  public

  end;

var
  RGGUIForm: TRGGUIForm;

implementation

{$R *.lfm}
{$R ..\TL2Lib\dict.rc}
{$R bass64.rc}

uses
  LCLIntf,
  LCLType,
  IntfGraphics,
  inifiles,
  fpimage,
  fpwritebmp,
  lazTGA,
  berodds,
  fpc.Dynamic_Bass,

  unitLogForm,
  unitFilterForm,
  fmGameVersion,
  fmmodinfo,
  fmAsk,
  fmcombodiff,

  rgIO.Text,
  rgIO.Layout,

  rgfiletype,
  rgfile,
  rgmod,
  rgdict,
  rgdictlayout,
  rgstream;

{%REGION Constants}

const
  strParentDir = '. . /';
  strDir       = '< DIR >';
const
  stlblNew     = '+';
  stlblChanged = '*';
  stlblDelete  = 'X';
  stlblLinkNew = 'F+';
  stlblLinkEd  = 'F*';

const
  colState  = 0;
  colDir    = 1;
  colName   = 2;
  colExt    = 3;
  colType   = 4;
  colTime   = 5;
  colPack   = 6;
  colUnpack = 7;
  colSource = 8;

const
  INIFileName   = 'RGGUI.INI';
  sSectSettings = 'settings';
  sOutDir       = 'outdir';
  sSavePath     = 'savepath';
  sUseFName     = 'usefname';
  sSaveUTF8     = 'saveutf8';
  sFastScan     = 'fastscan';
  sDecoding     = 'decoding';
  sMODDAT       = 'moddat';
  sExt          = 'ext';
  sFilter       = 'filter';
  sSaveSettings = 'savesettings';
  sShowDir      = 'showdir';
  sShowExt      = 'showext';
  sShowCategory = 'showcategory';
  sShowTime     = 'showtime';
  sShoPacked    = 'shopacked';
  sShowUnpacked = 'showunpacked';
  sShowSource   = 'showsource';
  sShowPreview  = 'showpreview';
  sScaleImage   = 'scaleimage';
  sSaveWidth    = 'savewidth';
  sTreeWidth    = 'width_tree';
  sGridWidth    = 'width_grid';
  sDebugLevel   = 'debuglevel';
const
  sMedia       = 'MEDIA';
//  sDefDirName  = 'NEWDIR';
//  sDefFileName = 'NEWFILE.DAT';

const
  defTreeWidth = 256;
  defGridWidth = 360;

resourcestring
  rsWarning         = 'Warning!';
  rsUnsaved         = 'You have unsaved changes. Continue anyway?';
  rsReadPAK         = ' Read PAK. Parsing...';
  rsBuildTree       = ' Build tree';
  rsBuildGrid       = ' Build file list. Please, wait...';
  rsBuildPreview    = ' Build preview';
  rsUnpackSucc      = 'unpacked succesfully.';
  rsFilesUnpackSucc = ' files unpacked succesfully.';
//  rsTotal           = 'Total: ';
  rsFiles           = 'Files: ';
  rsDirs            = '; dirs: ';
  rsFilePath        = 'File path: ';
  rsSaved           = 'File saved';
  rsSavedAs         = 'File saved as';
  rsCantSave        = 'Can''t save file';
  rsExtractDir      = 'Extract directory ';
  rsCreateDir       = 'Create directory';
  rsSelectDir       = 'Select directory';
  rsDirName         = 'Enter dir name';
  rsCreateFile      = 'Create file';
  rsFileName        = 'Enter file name';
  rsReady           = 'Ready to work';
  rsRename          = 'Rename file/dir';
  rsImported        = ' files imported';
  rsLinkingNote     = 'These files still on disk and not built-in until PAK/MOD saved.';
  rsNothingImported = 'Nothing was imported.';
  rsUnknownEncoding = 'Unknown source encoding';
//  rsChooseVer       = 'Choose game';
//  rsGameVer         = 'Game';

{%ENDREGION Constants}

{ TRGGUIForm }

{%REGION Settings}

procedure TRGGUIForm.actResetViewExecute(Sender: TObject);
begin
  pnlTree.Width:=defTreeWidth;
  sgMain .Width:=defGridWidth;
  sgMain.Columns[colDir   ].Width:=256;
  sgMain.Columns[colName  ].Width:=144;
  sgMain.Columns[colExt   ].Width:=48;
  sgMain.Columns[colType  ].Width:=80;
  sgMain.Columns[colTime  ].Width:=110;
  sgMain.Columns[colPack  ].Width:=80;
  sgMain.Columns[colUnpack].Width:=80;
  sgMain.Columns[colSource].Width:=80;
end;

procedure TRGGUIForm.SetupColumns(Sender: TObject);
begin
  sgMain.Columns[colDir   ].Visible:=(bShowDir     );
  sgMain.Columns[colExt   ].Visible:=(bShowExt     );
  sgMain.Columns[colType  ].Visible:=(bShowCategory);
  sgMain.Columns[colTime  ].Visible:=(bShowTime    );
  sgMain.Columns[colPack  ].Visible:=(bShowPacked  );
  sgMain.Columns[colUnpack].Visible:=(bShowUnpacked);
  sgMain.Columns[colSource].Visible:=(bShowSource  );

  tbColDir     .Down:=(bShowDir     );
  tbColExt     .Down:=(bShowExt     );
  tbColCategory.Down:=(bShowCategory);
  tbColTime    .Down:=(bShowTime    );
  tbColPacked  .Down:=(bShowPacked  );
  tbColUnpacked.Down:=(bShowUnpacked);
  tbColSource  .Down:=(bShowSource  );
//  sgMainSelection(sgMain, sgMain.Col, sgMain.Row);
end;

procedure TRGGUIForm.tbColumnClick(Sender: TObject);
begin
  if      Sender=tbColDir      then bShowDir     :=not bShowDir
  else if Sender=tbColExt      then bShowExt     :=not bShowExt
  else if Sender=tbColCategory then bShowCategory:=not bShowCategory
  else if Sender=tbColTime     then bShowTime    :=not bShowTime
  else if Sender=tbColPacked   then bShowPacked  :=not bShowPacked
  else if Sender=tbColUnpacked then bShowUnpacked:=not bShowUnpacked
  else if Sender=tbColSource   then bShowSource  :=not bShowSource;
  SetupColumns(Sender);
end;

procedure TRGGUIForm.SaveSettings;
var
  config:TIniFile;
  i:integer;
begin
  if cbSaveSettings.Checked then
  begin
    config:=TMemIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

    config.WriteString (sSectSettings,sOutDir      ,deOutDir.Text);
    config.WriteString (sSectSettings,sExt         ,LastExt);
    config.WriteInteger(sSectSettings,sFilter      ,LastFilter);
    config.WriteBool   (sSectSettings,sSavePath    ,cbUnpackTree.Checked);
    config.WriteBool   (sSectSettings,sUseFName    ,cbUseFName.Checked);
    config.WriteBool   (sSectSettings,sMODDAT      ,cbMODDAT.Checked);
    config.WriteBool   (sSectSettings,sFastScan    ,cbFastScan.Checked);
    config.WriteBool   (sSectSettings,sSaveSettings,cbSaveSettings.Checked);

    config.WriteBool(sSectSettings,sShowDir     ,bShowDir     );
    config.WriteBool(sSectSettings,sShowExt     ,bShowExt     );
    config.WriteBool(sSectSettings,sShowCategory,bShowCategory);
    config.WriteBool(sSectSettings,sShowTime    ,bShowTime    );
    config.WriteBool(sSectSettings,sShoPacked   ,bShowPacked  );
    config.WriteBool(sSectSettings,sShowUnpacked,bShowUnpacked);
    config.WriteBool(sSectSettings,sShowSource  ,bShowSource  );

    config.WriteBool(sSectSettings,sShowPreview,actShowPreview.Checked);
    config.WriteBool(sSectSettings,sScaleImage ,actScaleImage .Checked);

    config.WriteBool(sSectSettings,sSaveWidth,cbSaveWidth.Checked);
    if cbSaveWidth.Checked then
    begin
      config.WriteInteger(sSectSettings,sTreeWidth,pnlTree.Width);
      // don't use sgMain.Width coz it can be wrong with no preview on
      config.WriteInteger(sSectSettings,sGridWidth,Splitter2.Left{Self.Width-pnlAdd.Width});
    end;

    if      rbBinOnly   .Checked then i:=1
    else if rbTextOnly  .Checked then i:=2
    else if rbTextRename.Checked then i:=3
    else if rbGUTSStyle .Checked then i:=4
    else i:=0;
    config.WriteInteger(sSectSettings,sDecoding,i);
    config.WriteBool   (sSectSettings,sSaveUTF8,cbSaveUTF8.Checked);

    fmFilterForm.SaveSettings(config);

    config.UpdateFile;
    config.Free;
  end;
end;

procedure TRGGUIForm.LoadSettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  LastExt               :=config.ReadString (sSectSettings,sExt         ,DefaultExt);
  LastFilter            :=config.ReadInteger(sSectSettings,sFilter      ,4);
  cbUnpackTree.Checked  :=config.ReadBool   (sSectSettings,sSavePath    ,true);
  cbUseFName.Checked    :=config.ReadBool   (sSectSettings,sUseFName    ,true);
  cbMODDAT.Checked      :=config.ReadBool   (sSectSettings,sMODDAT      ,true);
  cbFastScan.Checked    :=config.ReadBool   (sSectSettings,sFastScan    ,false);
  cbSaveSettings.Checked:=config.ReadBool   (sSectSettings,sSaveSettings,false);
  deOutDir.Text         :=config.ReadString (sSectSettings,sOutDir      ,'');
  if deOutDir.Text='' then deOutDir.Text:=ExtractFileDir(ParamStr(0));

  bShowDir     :=config.ReadBool(sSectSettings,sShowDir     ,true);
  bShowExt     :=config.ReadBool(sSectSettings,sShowExt     ,true);
  bShowCategory:=config.ReadBool(sSectSettings,sShowCategory,false);
  bShowTime    :=config.ReadBool(sSectSettings,sShowTime    ,false);
  bShowPacked  :=config.ReadBool(sSectSettings,sShoPacked   ,false);
  bShowUnpacked:=config.ReadBool(sSectSettings,sShowUnpacked,false);
  bShowSource  :=config.ReadBool(sSectSettings,sShowSource  ,false);

  actShowPreview.Checked:=config.ReadBool(sSectSettings,sShowPreview,false); actPreviewExecute(Self);
  actScaleImage .Checked:=config.ReadBool(sSectSettings,sScaleImage ,false);

  rgDebugLevel:=TRGDebugLevel(config.ReadInteger(sSectSettings,sDebugLevel,1));

  cbSaveWidth.Checked:=config.ReadBool(sSectSettings,sSaveWidth,true);

  if cbSaveWidth.Checked then
  begin
    pnlTree.Width:=config.ReadInteger(sSectSettings,sTreeWidth,defTreeWidth);
    Splitter2.Left{sgMain .Width}:=config.ReadInteger(sSectSettings,sGridWidth,defGridWidth);
  end
  else
  begin
    pnlTree.Width:=defTreeWidth;
    sgMain .Width:=defGridWidth;
  end;

  cbSaveUTF8.Checked:=config.ReadBool(sSectSettings,sSaveUTF8,false);
  case config.ReadInteger(sSectSettings,sDecoding,4) of
    1: rbBinOnly  .Checked:=true;
    2: rbTextOnly .Checked:=true;
    4: rbGUTSStyle.Checked:=true;
  else
    rbTextRename.Checked:=true;
  end;

  fmFilterForm.LoadSettings(config);
  config.Free;
end;

{%ENDREGION Settings}

{%REGION Filter}
{%ENDREGION Filter}

{%REGION Form}

procedure TRGGUIForm.UpdateStatistic;
begin
  StatusBar.Panels[0].Text:=rsFiles+IntToStr(ctrl.FileCount)+
                            rsDirs +IntToStr(ctrl.DirCount);
end;

procedure TRGGUIForm.SetupView;
begin
  actFileSave.Enabled:=(ctrl.DirCount>1) or (ctrl.FileCount>0);

  if ctrl.PAK.Name='' then
  begin
    Self.Caption:='RGGUI';
  end
  else
  begin
    Self.Caption:='RGGUI - ('+GetGameName(ctrl.PAK.Version)+') '+AnsiString(ctrl.PAK.Name);
  end;

  EdGridFilter.Text:='';

  SetupColumns(Self);
  UpdateStatistic();
  StatusBar.Panels[1].Text:=rsReady;
end;

procedure TRGGUIForm.NewPAK;
begin
  ctrl.Init;
  FillTree();
  SetupView();
end;

procedure TRGGUIForm.FormCreate(Sender: TObject);
begin
  FLastIndex:=-1;
  FUData    :=nil;
  sgSortColumn:=-1;

  fmLogForm:=nil;
  fmFilterForm:=TFilterForm.Create(Self);
  fmLEdit:=TFormLayoutEdit.Create(Self);
  fmLEdit.Parent:=pnlAdd;
  fmLEdit.Align:=alClient;

  SynTSyn:=TSynTSyn.Create(Self);
  SynOgreSyn:=TSynOgreSyn.Create(Self);

  LoadSettings();
  SetupColumns(Self);
  ClearInfo();

  RGTags.Import('RGDICT','TEXT');

  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  if ParamCount>0 then
    OpenPAK(ParamStr(1))
  else
    NewPAK();

  PageControl.ActivePageIndex:=1;
  inProcess:=false;
end;

procedure TRGGUIForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if actFileExit.Enabled then actFileExitExecute(Sender);
  if actFileExit.Enabled then
  begin
    CloseAction:=caNone;
    exit;
  end;

  Unload_BASSDLL;
  SaveSettings();
end;

function TRGGUIForm.FileClose:boolean;
begin
  if ctrl.UpdatesCount()>0 then
  begin
    if MessageDlg(rsWarning,rsUnsaved,mtWarning,
       [mbOK,mbCancel],0,mbCancel)<>mrOk then
    begin
      exit(false);
    end;
  end;

  ctrl.Free;

  sgMain.Clear;
  tvTree.Items.Clear;
  ClearInfo();
  FreeAndNil(fmi);

  result:=true;
end;

procedure TRGGUIForm.actFileCloseExecute(Sender: TObject);
begin
  if FileClose() then NewPAK();
end;

procedure TRGGUIForm.actFileExitExecute(Sender: TObject);
begin
  if FileClose() then
  begin
    actFileExit.Enabled:=false;
    Close;
  end;
end;

procedure TRGGUIForm.OpenPAK(const aname:string);
var
  lmode:integer;
begin
  ctrl.Init;

  if cbFastScan.Checked then
    lmode:=piParse
  else
    lmode:=piFullParse;

  StatusBar.Panels[1].Text:=rsReadPAK;
  Application.ProcessMessages;

  if ctrl.PAK.GetInfo(aname,lmode) then
    ctrl.Rebuild();
ctrl.Trace;
  FillTree();
  SetupView();
end;

procedure TRGGUIForm.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
//    OpenDialog.Title  :=rsFileOpen;
    OpenDialog.Options    :=[ofFileMustExist];
    OpenDialog.DefaultExt :=LastExt;
    OpenDialog.Filter     :=DefaultFilter;
    OpenDialog.FilterIndex:=LastFilter;

    if OpenDialog.Execute then
    begin
      LastExt   :=OpenDialog.DefaultExt;
      LastFilter:=OpenDialog.FilterIndex;

      FileClose();
      OpenPAK(OpenDialog.FileName);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TRGGUIForm.actFileSaveAsExecute(Sender: TObject);
var
  dlg:TSaveDialog;
  lver:integer;
//  wasnew:boolean;
begin
  dlg:=TSaveDialog.Create(nil);
  try
    case ctrl.PAK.Version of
      verTL2: dlg.FilterIndex:=2;
      verHob: dlg.FilterIndex:=3;
      verRG : dlg.FilterIndex:=4;
      verRGO: dlg.FilterIndex:=5;
    else
      dlg.FilterIndex:=1;
    end;
    dlg.InitialDir:=ctrl.PAK.Directory;
    dlg.FileName  :=ctrl.PAK.Name;
    dlg.DefaultExt:=DefaultExt;
    dlg.Filter    :=DefWriteFilter;
    dlg.Title     :='';
    dlg.Options   :=dlg.Options+[ofOverwritePrompt];

    if (dlg.Execute) then
    begin
      case dlg.FilterIndex of
        1: lver:=verTL2Mod;
        2: lver:=verTL2;
        3: lver:=verHob;
        4: lver:=verRG;
        5: lver:=verRGO;
      end;
//      wasnew:=ctrl.PAK.Name='';
      if ctrl.SaveAs(dlg.Filename,lver) then
      begin
        tvTreeSelectionChanged(self);
        SetupView();
        ShowMessage(rsSavedAs+' '+dlg.Filename)
      end
      else
        ShowMessage(rsCantSave+' '+dlg.Filename);
    end;
  finally
    dlg.Free;
  end;

end;

procedure TRGGUIForm.actFileSaveExecute(Sender: TObject);
begin
  if ctrl.Save() then
  begin
    FreeAndNil(fmi);
    // remove all possible marks, update "size" columns
//FillTree;
    tvTreeSelectionChanged(self);
    ShowMessage(rsSaved);
    // if not implemented in "Save" then
    // close existing
    // reopen
  end
  else
    ShowMessage(rsCantSave);
end;

procedure TRGGUIForm.actOpenDirExecute(Sender: TObject);
var
  loutdir:string;
begin
  if deOutDir.Text='' then deOutDir.Text:=ExtractFileDir(ParamStr(0));
  loutdir:=deOutDir.Text;
  if not (loutdir[Length(loutdir)] in ['\','/']) then loutdir:=loutdir+'\';
  if cbUseFName.Checked   then loutdir:=loutdir+ctrl.PAK.Name+'\';

  OpenDocument(loutdir);
end;

procedure TRGGUIForm.actShowInfoExecute(Sender: TObject);
begin
  if fmi=nil then
  begin
    fmi:=TMODInfoForm.Create(Self,@ctrl.PAK.modinfo,false);
//    TMODInfoForm(fmi).LoadFromInfo(ctrl.PAK.modinfo);
  end;
  fmi.ShowOnTop;
end;

procedure TRGGUIForm.actShowFilterExecute(Sender: TObject);
begin
  fmFilterForm.ShowOnTop;
end;

procedure TRGGUIForm.actShowLogExecute(Sender: TObject);
begin
  if fmLogForm=nil then
  begin
    fmLogForm:=TfmLogForm.Create(Self);
    fmLogForm.memLog.Text:=RGLog.Text;
  end;
  fmLogForm.ShowOnTop;
end;

procedure TRGGUIForm.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  lp:TPoint;
  lnode:TTreeNode;
  ls:string;
  pc:PWideChar;
  i:integer;
begin
  GetCursorPos(lp);
  lnode:=nil;
  // check Grid
  if sgMain.MouseToCell(sgMain.ScreenToClient(lp)).X>=0 then
  begin
    lnode:=tvTree.Selected;
  end
  // check Tree
  else
  begin
    lp:=tvTree.ScreenToClient(lp);
    lnode:=tvTree.GetNodeAt(lp.X, lp.Y);
  end;

  if lnode<>nil then
  begin
    ls:=GetPathFromNode(lnode);
    for i:=0 to High(FileNames) do
    begin
      if DirectoryExists(FileNames[i]) then
      begin
        ctrl.ImportDir(ls,FileNames[i]);
      end
      else if FileExists(FileNames[i]) then
      begin
        pc:=StrToWide(FileNames[i]);
        ctrl.AddFileData(pc, PUnicodeChar(UnicodeString(
            ls+
            FixFileExt(ExtractFileName(FileNames[i])))), true);
        FreeMem(pc);
      end;
    end;
    FillTree();
    exit;
  end;
end;

{%ENDREGION Form}

{%REGION Save}

function TRGGUIForm.SaveFile(const adir,aname:string; adata:PByte; asize:integer):boolean;
var
  f:file of byte;
  pc:PUnicodeChar;
  loutdir,lext:string;
  ltype,lsize:integer;
begin
  result:=false;

  if asize=0 then exit;

  if deOutDir.Text='' then deOutDir.Text:=ExtractFileDir(ParamStr(0));
  loutdir:=deOutDir.Text;
  if not (loutdir[Length(loutdir)] in ['\','/']) then loutdir:=loutdir+'\';

  if cbUseFName.Checked   then loutdir:=loutdir+ctrl.PAK.Name+'\';
  if cbUnpackTree.Checked then loutdir:=loutdir+adir;

  if not cbTest.Checked then
    if not ForceDirectories(loutdir) then exit;

//  ltype:=GetExtInfo(aname,rgpi.ver)^._type;
  ltype:=PAKExtType(aname);

  // save decoded file
  if (not rbBinOnly.Checked) and (ltype in setData) then
  begin
    RGLog.Reserve('Processing '+adir+aname);

    // was: just parse binary, now - convert to text too
    if DecompileFile(adata, asize, adir+aname, pc, cbSaveUTF8.Checked) then
    begin
      if not cbTest.Checked then
      begin
        if rbTextRename.Checked or (ltype=typeRAW) then
          lext:='.TXT'
        else
          lext:='';

        AssignFile(f,loutdir+aname+lext);
        Rewrite(f);
        if IOResult=0 then
        begin
          if cbSaveUTF8.Checked then
            lsize:=Length(PAnsiChar(pc))
          else
            lsize:=Length(pc)*SizeOf(WideChar);
          BlockWrite(f,pc^,lsize);
          CloseFile(f);
        end;
      end;
      FreeMem(pc);
    end;
  end;

  if not cbTest.Checked then
  begin
    // set decoding binary file extension
    lext:='';
    if (rbGUTSStyle.Checked) and (ltype in setData) then
    begin
      if ltype=typeLayout then
        lext:='.BINLAYOUT'
      else if ltype=typeRAW then
        lext:=''
      else
      begin
        if ctrl.PAK.Version=verTL1 then
          lext:='.ADM'
        else
          lext:='.BINDAT';
      end;
    end;

    // save binary file
    if not (rbTextOnly.Checked and (ltype in setData)) then
    begin
      AssignFile(f,loutdir+aname+lext);
      Rewrite(f);
      if IOResult=0 then
      begin
        BlockWrite(f,adata^,asize);
        CloseFile(f);
      end;
    end;
  end;

  result:=true;
end;

procedure TRGGUIForm.actEdExportExecute(Sender: TObject);
var
  ldir, lname:string;
  lptr:pointer;
  lsize,i,lcnt:integer;
begin
  lcnt:=0;
  lptr:=nil;
  for i:=1 to sgMain.RowCount-1 do
  begin
    if sgMain.IsCellSelected[colDir,i] then
    begin
      lsize:=IntPtr(sgMain.Objects[colName,i]);
      if lsize>=0 then
      begin
  //      lsize:=ctrl.GetBinary(ctrl.SearchFile(ldir+lname),lptr);
        lsize:=ctrl.GetBinary(lsize,lptr);
        if lsize>0 then
        begin
          ldir :=sgMain.Cells[colDir ,i];
          lname:=sgMain.Cells[colName,i]+sgMain.Cells[colExt,i];
          if SaveFile(ldir, lname, lptr, lsize) then
            inc(lcnt);
        end;
      end;
    end;
//    if (i mod 100)=0 then Application.ProcessMessages;
  end;
  FreeMem(lptr);

  if lcnt=1 then
    ShowMessage('File '+ldir+lname+#13#10+rsUnpackSucc)
  else if lcnt>1 then
    ShowMessage(IntToStr(lcnt)+rsFilesUnpackSucc);
end;

{%ENDREGION Save}

{%REGION Unpack}

function TRGGUIForm.UnpackSingleFile(const adir,aname:string; var buf:PByte):boolean;
var
  lsize:integer;
begin
  lsize:=ctrl.GetBinary(ctrl.SearchFile(adir+aname),buf);
  result:=SaveFile(adir,aname,buf,lsize);
end;

procedure TRGGUIForm.DoExtractGrid(Sender: TObject);
var
  ldata:PByte;
  i,lcnt:integer;
begin
  ldata:=nil;
  lcnt:=0;
  for i:=1 to sgMain.RowCount-1 do
  begin
    if UnpackSingleFile(
        sgMain.Cells[colDir ,i],
        sgMain.Cells[colName,i]+
        sgMain.Cells[colExt ,i],ldata) then inc(lcnt);
//    if (i mod 100)=0 then Application.ProcessMessages;
  end;
  FreeMem(ldata);
  if lcnt>0 then ShowMessage(IntToStr(lcnt)+rsFilesUnpackSucc);
end;

procedure TRGGUIForm.ExtractSingleDir(adir:integer; var buf:PByte);
var
  ldir,lname:PWideChar;
  lfile,ltype:integer;
begin
  if ctrl.GetFirstFile(lfile,adir) then
  begin
    ldir:=ctrl.Dirs[adir].Name;
    repeat
      lname:=ctrl.Files[lfile]^.Name;
      ltype:=PAKExtType(lname);
      if not (ltype in [typeDelete,typeDirectory]) then
        UnpackSingleFile(ldir,lname,buf);
    until not ctrl.GetNextFile(lfile);
  end;
//  Application.ProcessMessages;
end;

procedure TRGGUIForm.DoExtractDir(Sender: TObject);
var
  ldata:PByte;
begin
  ldata:=nil;
  ExtractSingleDir(IntPtr(PopupNode.Data),ldata);
  FreeMem(ldata);
end;

procedure TRGGUIForm.DoExtractTree(Sender: TObject);
var
  ls:PWideChar;
  ldata:PByte;
  i,idx,llen:integer;
  ldl:TRGDebugLevel;
begin
  ldl:=rgDebugLevel;

  idx:=IntPtr(PopupNode.Data);
  if idx>0 then
  begin
    ls:=ctrl.Dirs[idx].Name;
    llen:=Length(ls);
  end
  else
  begin
    ls:='';
    llen:=0;
  end;

  ldata:=nil;
  for i:=0 to ctrl.DirCount-1 do
  begin
    if not ctrl.IsDirDeleted(i) then
      if (idx=0) or (i=idx) or (CompareWide(ls,ctrl.Dirs[i].name,llen)=0) then
      begin
        StatusBar.Panels[1].Text:=rsExtractDir+WideToStr(ctrl.Dirs[i].name);
        StatusBar.Update;
        ExtractSingleDir(i,ldata);
      end;
  end;
  FreeMem(ldata);

  if (idx<0) and (cbMODDAT.Checked) and (ctrl.PAK.Version=verTL2Mod) then
  begin
    SaveModConfig(ctrl.PAK.modinfo,PChar(deOutDir.Text+'\'+'MOD.DAT'));
  end;
  StatusBar.Panels[1].Text:=rsFilePath+sgMain.Cells[colDir ,sgMain.Row];
  ShowMessage(GetPathFromNode(PopupNode)+#13#10+rsUnpackSucc);

  rgDebugLevel:=ldl;
end;

{%ENDREGION Unpack}

{%REGION Preview}

procedure TRGGUIForm.ClearInfo();
var
  bNoTree,bRoot,bEmpty,bParent:boolean;
begin
  lblSizeVal  .Caption:='';
  lblOffsetVal.Caption:='';
  lblTimeVal  .Caption:='';

  if sstream<>0 then bbStopClick(self);
  pnlAudio.Visible:=false;

  fmLEdit.Visible:=false;

  SynEdit.Clear;
  SynEdit.Visible:=false;

  imgPreview.Picture.Clear;
  imgPreview.Visible:=false;
  actScaleImage.Visible:=false;

  actEdSearch.Enabled:=false;

  FreeMem(FUData); FUData:=nil;

  bNoTree:=tvTree.Items.Count=0;
  bRoot  :=(not bNoTree) and (tvTree.Selected=tvTree.Items[0]);
  bEmpty :=(not bNoTree) and
          ((sgMain.RowCount=1) or
          ((sgMain.RowCount=2) and (IntPtr(UIntPtr(tvTree.Selected.Data))>0)));
//            (IntPtr(UIntPtr(sgMain.Objects[colName,1]))=-1);
  bParent:=(not bNoTree) and
          ((sgMain.Row     =1) and (IntPtr(UIntPtr(tvTree.Selected.Data))>0));

  // Single file actions
  actEdUndo  .Enabled:=not (bNoTree or bEmpty or bParent);
  actEdSave  .Enabled:=not (bNoTree or bEmpty or bParent);
  actEdRename.Enabled:=not (bNoTree or bEmpty or bParent);
  // Selected files actions
  actEdExport.Enabled:=not (bNoTree or bEmpty);
  actEdReset .Enabled:=not (bNoTree or bEmpty);
  actEdDelete.Enabled:=not (bNoTree or bEmpty);

  actEdNew   .Enabled:=not bNoTree;
  actEdImport.Enabled:=not bNoTree;
end;

procedure TRGGUIForm.PrepareSound;
var
//  f:File Of Byte;
//  res:TFPResourceHandle;
  res:TResourceStream;
  lHandle:THANDLE;
  lptr:PByte;
  lsize:integer;
begin
  if not Load_BASSDLL('bass.dll') then
  begin
    res:=TResourceStream.Create(hInstance,'BASS','RT_RCDATA');
    try
      res.SaveToFile('bass.dll');
    finally
      res.Free;
    end;
(*
    res:=FindResource(hInstance, 'BASS', 'TEXT');
    if res<>0 then
    begin
      lHandle:=LoadResource(hInstance,Res);
      if lHandle<>0 then
      begin
        lptr :=LockResource(lHandle);
        lsize:=SizeOfResource(hInstance,res);

        {$I-}
        AssignFile(f,'bass.dll');
        Rewrite(f);
        if IOResult=0 then
        begin
          BlockWrite(f,lptr^,lsize);
          CloseFile(f);
        end;

        UnlockResource(lHandle);
        FreeResource(lHandle);
      end;
    end;
*)
  end;
  if Load_BASSDLL('bass.dll') then
  begin
    BASS_Init(-1, 44100, 0, hInstance, nil);
  end;
  sstream:=0;
end;

procedure TRGGUIForm.bbPlayClick(Sender: TObject);
begin
  bbPlay.Visible:=false;
  bbStop.Visible:=true;
  sstream:=BASS_StreamCreateFile(true,FUData,0,FUSize,BASS_STREAM_AUTOFREE);
  BASS_ChannelPlay(sstream, false);
end;

procedure TRGGUIForm.bbStopClick(Sender: TObject);
begin
  BASS_ChannelStop(sstream);
  sstream:=0;
  bbPlay.Visible:=true;
  bbStop.Visible:=false;
end;

procedure TRGGUIForm.PreviewSound;
begin
  if BASS_Handle=0 then PrepareSound;
  bbPlay.Enabled:=BASS_Handle<>0;
  bbStop.Enabled:=BASS_Handle<>0;
  bbPlay.Visible:=true;
  bbStop.Visible:=false;

  pnlAudio.Visible:=true;
end;

procedure TRGGUIForm.actScaleImageExecute(Sender: TObject);
begin
  PreviewImage(sgMain.Cells[colExt,sgMain.Row]);
end;

procedure TRGGUIForm.PreviewImage(const aext:string);
var
//  limg: TLazIntfImage;
//  png: TCustomBitmap;
  limg:TFPMemoryImage;
  lstr:TMemoryStream;
  lwriter: TFPWriterBMP;
  lfpc:TFPColor;
  ldata:PByte;
//  lsize:integer;
  lidx,y,x,lheight,lwidth:integer;
begin
  if FUSize=0 then exit;

  if actScaleImage.Checked then
  begin
    imgPreview.Stretch:=true;
  end
  else
  begin
    imgPreview.Stretch:=false;
  end;

  if (aext='.DDS') or
    ((PByte(FUData)[0]=ORD('D')) and
     (PByte(FUData)[1]=ORD('D')) and
     (PByte(FUData)[2]=ORD('S'))) then
  begin
{
    LoadDDSImage(FUData, FUSize, ldata, lwidth, lheight);
    try
      png := TPortableNetworkgraphic.Create; // or TJpegImage.Create, or TBitmap.Create, or ...
      try
        png.SetSize(lWidth, lHeight);
        png.PixelFormat := pf32bit;
        limg := png.CreateIntfImage;
        try
          lidx:=0;
          for y := 0 to lheight-1 do
          begin
            for x := 0 to lwidth-1 do
            begin
              lfpc.Red   := ldata[lidx+0] shl 8;
              lfpc.Green := ldata[lidx+1] shl 8;
              lfpc.Blue  := ldata[lidx+2] shl 8;
              lfpc.Alpha := ldata[lidx+3] shl 8;
              limg.Colors[x, y] := lfpc;
              Inc(lidx, 4);
            end;
          end;
          png.LoadFromIntfImage(limg);
          imgPreview.Picture.Assign(png);
        finally
          limg.Free;
        end;
      finally
        png.Free;
      end;
    finally
      FreeMem(lData);
    end;
}
    if LoadDDSImage(FUData,FUSize,ldata,lwidth,lheight) then
    begin
      limg:=TFPMemoryImage.Create(lwidth,lheight);
      lidx:=0;
      for y:=0 to lheight-1 do
      begin
        for x:=0 to lwidth-1 do
        begin
          lfpc.Red  :=ldata[lidx+0] shl 8;
          lfpc.Green:=ldata[lidx+1] shl 8;
          lfpc.Blue :=ldata[lidx+2] shl 8;
          lfpc.Alpha:=ldata[lidx+3] shl 8;
          limg.Colors[x,y]:=lfpc;
          inc(lidx,4);
        end;
      end;
      FreeMem(ldata);

      lstr:=TMemoryStream.Create();
      try
        lwriter := TFPWriterBMP.Create;
        try
          limg.SaveToStream(lstr, lwriter);
          // or: lwriter.ImageWrite(lstr, limg);
        finally
          lwriter.Free;
        end;
        lstr.Position := 0;
        imgPreview.Picture.LoadFromStream(lstr);
      finally
        lstr.Free;
      end;
  //    imgPreview.Picture.Assign(limg);
      limg.Free;
    end;

  end
  else
  begin
    lstr:=TMemoryStream.Create();
    try
      // PUData cleared in ClearInfo() and/or FormClose;
      lstr.SetBuffer(FUData);
      imgPreview.Picture.LoadFromStream(lstr);
    finally
      lstr.Free;
    end;
  end;
  imgPreview.Visible:=true;
  imgPreview.Hint:='Size: '+
      IntToStr(imgPreview.Picture.Width)+' x '+
      IntToStr(imgPreview.Picture.Height);
  actScaleImage.Visible:=true;
end;

procedure TRGGUIForm.PreviewLayout();
begin
//  if FUData=nil then exit;

  TFormLayoutEdit(fmLEdit).BuildTree(FUData,ctrl.PAK.Version);
  fmLEdit.Visible:=true;
end;

procedure TRGGUIForm.PreviewSource();
var
  pc :PWideChar;
  lpc:PAnsiChar;
begin
  if FUData=nil then exit;

//!!    pnlEditButtons.Visible:=true;
  SynEdit.Highlighter:=SynTSyn;

  case GetSourceEncoding(FUData) of
    tofSrcUTF8: begin
      lpc:=PAnsiChar(FUData);
      if (PDword(FUData)^ and $00FFFFFF)=SIGN_UTF8 then inc(lpc,3);
      SynEdit.Text:=lpc;
    end;

    tofSrcWide: begin
      pc:=PWideChar(FUData);
      if ORD(pc^)=SIGN_UNICODE then inc(pc);
      SynEdit.Text:=WideToStr(pc);
    end;

  else
    ShowMessage(rsUnknownEncoding);
    exit;
  end;

  SynEdit.Modified:=false;
  SynEdit.Visible:=true;
  actEdSearch.Enabled:=true;
end;

procedure TRGGUIForm.PreviewText();
var
  ltext:string;
begin
  // Use LText coz FUData don't have #0 at the end
  if FUSize>0 then
    SetString(ltext,PChar(FUData),FUSize)
  else
    ltext:='';

  if SynOgreSyn.CheckType(sgMain.Cells[colExt,sgMain.Row]) then
    SynEdit.Highlighter:=SynOgreSyn
  else
    SynEdit.Highlighter:=SynXMLSyn;
  SynEdit.Text:=ltext;
  SynEdit.Visible:=true;
  actEdSearch.Enabled:=true;
end;

procedure TRGGUIForm.sgMainSelection(Sender: TObject; aCol, aRow: Integer);
var
  lrec:TRGFullInfo;
  ldir,lname,lext:string;
  lspec,ltype,lfile:integer;
begin
  ClearInfo();
  if (aCol<1) or (aRow<1) or
//    ((aRow=1) and (sgMain.Cells[colName,aRow]=strParentDir)) then
    ((aRow=1) and (IntPtr(UIntPtr(tvTree.Selected.Data))>1)) then
  begin
    Exit;
  end;

  StatusBar.Panels[1].Text:=rsBuildPreview;
  ldir :=sgMain.Cells[colDir ,aRow];
  lext :=sgMain.Cells[colExt ,aRow];
  lname:=sgMain.Cells[colName,aRow]+lext;

//  lfile:=ctrl.SearchFile(ldir+lname);
  lfile:=IntPtr(sgMain.Objects[colName,aRow]);

  if lfile>=0 then
  begin
    if ctrl.UpdateState(lfile)=stateDelete then Exit;

    RGLog.Reserve('Processing '+ldir+lname);

    ctrl.GetFullInfo(lfile,lrec);

    lblSizeVal  .Caption:=IntToStr(lrec.size_u);
    lblOffsetVal.Caption:='0x'+HexStr(lrec.offset,8);
    try
      lblTimeVal.Caption:=DateTimeToStr(FileTimeToDateTime(lrec.ftime));
    except
      lblTimeVal.Caption:='0x'+HexStr(lrec.ftime,16);
    end;

    ltype:=PAKExtType(lname{lext});
    if ltype in (setBinary+[typeDelete,typeDirectory]) then exit;

    if not actShowPreview.Checked then exit;

    if ltype=typeLayout then
    begin
      FUSize:=ctrl.GetBinary(lfile,FUData);
      if GetLayoutVersion(FUData)=verUnk then
        PreviewText()
      else
        PreviewLayout();
    end
    else
    begin
      FUSize:=ctrl.GetSource(lfile,FUData);

  //    if FUSize>0 then
      begin
        lspec:=0;
        if ltype=typeImageset then
        begin
          if (FUSize>4) then
            case GetSourceEncoding(FUData) of
              tofSrcUTF8: lspec:=1;
              tofSrcWide: lspec:=2;
            end;
        end;
  //!!      pnlEditButtons.Visible:=false;
        // Text
        if (ltype in setText) and (lspec in [0,1]) then PreviewText()

        // DAT, RAW, ANIMATION, TEMPLATE, LAYOUT
        else if (ltype in setData) and (lspec in [0,2]) then PreviewSource()

        // Image
        else if ltype in setImage then PreviewImage(lext)

        // Sound
        else if ltype=typeSound then PreviewSound

        else
        ;

      end;
    end;
    FillGridLine(sgMain.Row,ldir,lfile);
  end;
  StatusBar.Panels[1].Text:=rsFilePath+ldir;
end;

procedure TRGGUIForm.SynEditStatusChange(Sender: TObject; Changes: TSynStatusChanges);
begin
  if (scModified in Changes) and SynEdit.Modified then Grid.Caption:='[*] Grid';
end;

procedure TRGGUIForm.actPreviewExecute(Sender: TObject);
begin
  {TODO: Ask about changes (if any)}
  if actShowPreview.Checked then
  begin
    sgMain.Align:=alLeft;
    Splitter2.Visible:=true;
    pnlAdd.Visible:=true;
    if sgMain.RowCount>1 then
      sgMainSelection(sgMain, colName, sgMain.Row);
  end
  else
  begin
    ClearInfo();
    pnlAdd.Visible:=false;
    Splitter2.Visible:=false;
    sgMain.Align:=alClient;
  end;
end;

procedure TRGGUIForm.ReplaceExecute(Sender: TObject);
var
  lopt:TSynSearchOptions;
  lcnt:integer;
begin
  lcnt:=0;
  with Sender as TReplaceDialog do
  begin
    lopt := [];
    if frReplace    in Options then lopt := [ssoReplace];
    if frReplaceAll in Options then lopt := [ssoReplaceAll];
    lcnt := SynEdit.SearchReplace{Ex}( FindText, ReplaceText, lopt{, Position });
{
    if lcnt>=0 then
    begin
    //   if lcnt>1 then ShowMessage('Replaces = '+IntToStr(lcnt));
      SynEdit.SetFocus()
    end
    else
      Beep();
}
  end;
end;

procedure TRGGUIForm.actEdSearchExecute(Sender: TObject);
begin
  ReplaceDialog.Execute();
end;

{%ENDREGION Preview}

{%REGION Actions}
procedure TRGGUIForm.actEdDeleteExecute(Sender: TObject);
var
  i,lidx,lcnt,ldircnt:integer;
begin
  lcnt:=0;
  ldircnt:=0;
  for i:=1 to sgMain.RowCount-1 do
  begin
    if sgMain.IsCellSelected[colDir,i] then
    begin
      lidx:=IntPtr(sgMain.Objects[colName,i]);
      if lidx>=0 then
      begin
        ctrl.MarkToRemove(lidx);
        if PRGCtrlInfo(ctrl.Files[lidx])^.ftype=typeDirectory then
        begin
          MarkTree(ctrl.AsDir(lidx),false);
          inc(ldircnt);
        end;
        inc(lcnt);
      end;
    end;
  end;
//  if ldircnt>0 then FillTree();
  if lcnt>0 then FillGrid(IntPtr(tvTree.Selected.Data));
end;

procedure TRGGUIForm.actChangeVersionExecute(Sender: TObject);
var
  lf:TFmGameVer;
  idx: integer;
begin
{
  idx:=InputCombo(rsChooseVer, rsGameVer,
      ['Torchligh I', 'Torchlight II', 'Hob', 'Rebel Galaxy', 'Rebel Galaxy Outlaw']);
  case idx of
    0: idx:=verTL1;
    1: idx:=verTL2;
    2: idx:=verHob;
    3: idx:=verRG;
    4: idx:=verRGO;
  end;
}
  lf:=TFmGameVer.Create(Self);
  lf.Version:=ctrl.PAK.Version;
  if lf.ShowModal=mrOK then
  begin
    idx:=lf.Version;
    if ctrl.PAK.Version<>idx then
    begin
      ctrl.PAK.Version:=idx;
      SetupView();
    end;
  end;
  lf.Free;
end;

procedure TRGGUIForm.actEdUndoExecute(Sender: TObject);
begin
  sgMainSelection(sgMain, colName, sgMain.Row);
end;

procedure TRGGUIForm.actEdResetExecute(Sender: TObject);
var
  state,lfile,i,j:integer;
  ldir:integer;
begin
  {TODO: Ask about changes (if any)}
{
  lfile:=ctrl.SearchFile(
      sgMain.Cells[colDir ,sgMain.Row]+
      sgMain.Cells[colName,sgMain.Row]+
      sgMain.Cells[colExt ,sgMain.Row]);
}
  for i:=1 to sgMain.RowCount-1 do
  begin
    if sgMain.IsCellSelected[colDir,i] then
    begin
      lfile:=IntPtr(sgMain.Objects[colName,i]);
      if lfile<0 then continue;

//      lfile:=IntPtr(sgMain.Objects[colName,sgMain.Row]);
      state:=ctrl.UpdateState(lfile);
      if ctrl.IsDir(lfile) then
      begin
        ldir:=ctrl.AsDir(lfile);
        if state=stateDelete then
        begin
          MarkTree(ldir,true);
        end;
      end
      else
        ldir:=-1;
      lfile:=ctrl.RemoveUpdate(lfile);
      if (state=stateNew) or (lfile<0) then
      begin
        FillGrid(IntPtr(tvTree.Selected.Data));
        if ldir>=0 then
          for j:=0 to tvTree.Items.Count-1 do
            if IntPtr(UIntPtr(tvTree.Items[j].Data))=ldir then
            begin
              tvTree.Items[j].Delete;
              break;
            end;
      end
      else
      begin
        FillGridLine(sgMain.Row,sgMain.Cells[colDir ,sgMain.Row],lfile);
        sgMainSelection(sgMain, colName, sgMain.Row);
      end;

    end;
  end;
end;

procedure TRGGUIForm.actEdSaveExecute(Sender: TObject);
var
  ldir,lname:string;
  pc:PWideChar;
  lbuf:PByte;
  lsize,i:integer;
begin
  ldir :=sgMain.Cells[colDir ,sgMain.Row];
  lname:=sgMain.Cells[colName,sgMain.Row]+
         sgMain.Cells[colExt ,sgMain.Row];
//pc:=StrToWide(SynEdit.Text);
//  lsize:=CompileFile(PByte(pc),lname,lbuf,ctrl.PAK.Version);
  lsize:=0;
  lbuf:=nil;

  if fmLEdit.Visible then
    lsize:=TFormLayoutEdit(fmLEdit).GetFile(lbuf,ctrl.PAK.Version);

  if SynEdit.Visible then
    lsize:=CompileFile(PByte(PChar(SynEdit.Text)),lname,lbuf,ctrl.PAK.Version);

  if lsize>0 then
  begin
    pc:=StrToWide(ldir+lname);
    i:=ctrl.AddUpdate(lbuf,lsize,pc);
    PRGCtrlInfo(ctrl.Files[i])^.size_s:=Length(SynEdit.Text);
    FillGridLine(sgMain.Row,ldir,i);
    FreeMem(pc);
    FreeMem(lbuf);
  end;

end;

procedure TRGGUIForm.actEdImportExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  pc:PWideChar;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
//    OpenDialog.Title  :=rsFileOpen;
    OpenDialog.Options    :=[ofFileMustExist];
    OpenDialog.DefaultExt :='.*';
    OpenDialog.Filter     :='';//DefaultFilter;
    OpenDialog.FilterIndex:=0;//LastFilter;

    if OpenDialog.Execute then
    begin
      pc:=StrToWide(OpenDialog.FileName);
{
      // if file = source then compile it
      // 1 - read file into "li" buffer
      llen:=FileSize();
      lo:=nil;
      // 2 - compile if source
      if IsSource(li,pc) then
      begin
        lsize:=CompileFile(li, OpenDialog.FileName, lo, ctrl.PAK.Version);
        // 3 - use original if not compiled
        if lsize>0 then
        begin
          FreeMem(li);
          li  :=lo;
          llen:=lsize;
        end;
      end;
      UseData(li, llen, PUnicodeChar(UnicodeString(GetPathFromNode(tvTree.Selected));
}
      // add update as file content (as is)
      ctrl.AddFileData(pc, PUnicodeChar(UnicodeString(
          GetPathFromNode(tvTree.Selected)+
          FixFileExt(ExtractFileName(OpenDialog.FileName)))), true);
      FreeMem(pc);
      FillGrid(IntPtr(tvTree.Selected.Data));
    end;
  finally
    OpenDialog.Free;
  end;
end;

function TRGGUIForm.OnImportDouble(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction;
var
  ls:UnicodeString;
  f:file of byte;
  lold,lnew:PByte;
  loldsize,lnewsize:integer;
  istext:boolean;
begin
  lnew:=nil;
  lold:=nil;

  istext:=PAKExtType(ctrl.Files[idx]^.Name) in setData;

  // if size=0 then newdata is PUnicodeChar'ed filename
  lnewsize:=newsize;
  if newsize=0 then
  begin
    if istext then
    begin
      DecompileFile(PUnicodeChar(newdata),lnew,false);
      lnewsize:=Length(PUnicodeChar(lnew))*SizeOf(WideChar);
    end
    else
    begin
      {%I-}
      AssignFile(f,PUnicodeChar(newdata));
      Reset(f);
      if IOResult=0 then
      begin
        lnewsize:=Filesize(f);
        GetMem(lnew,lnewsize);
        BlockRead(f,lnew^,lnewsize);
        CloseFile(f);
      end;
    end;
  end;

  // Check for same file
  loldsize:=ctrl.GetSource(idx,lold);
  if loldsize=lnewsize then
  begin
    if CompareMem(lold,lnew,loldsize) then
    begin
      FreeMem(lold);
      FreeMem(lnew);
      exit(da_skip);
    end;
  end;

  if newsize=0 then
    ls:=PUnicodeChar(newdata)
  else
    ls:=UnicodeString(ctrl.PathOfFile(idx))+UnicodeString(ctrl.Files[idx]^.Name);
  with tAskForm.Create(string(ls), loldsize, lnewsize) do
  begin
    ShowModal();
    result:=TRGDoubleAction(MyResult);
    Free;
  end;
  
  case result of
    da_renameold: begin
      newdata:=PByte(StrToWide(
          InputBox('Rename existing file', 'Enter new name', ctrl.Files[idx]^.Name) ));
    end;

    da_saveas: begin
      newdata:=PByte(StrToWide(
          InputBox('Rename new file', 'Enter new name', ctrl.Files[idx]^.Name) ));
    end;

    da_compare: begin
      if istext then
      begin
        with TCompareForm.Create(lold,lnew) do
        begin
          if ShowModal()=mrOk then
          begin
            newdata:=PByte(UnicodeText());
            newsize:=(Length(PUnicodeChar(newdata))+1)*SizeOf(WideChar);
          end
          else
            result:=da_skip;

          Free;
        end;
      end;
    end;

  else
  end;

  FreeMem(lold);
  FreeMem(lnew);
end;

procedure TRGGUIForm.actEdImportDirExecute(Sender: TObject);
var
  ldir:string;
  lcnt:integer;
begin
  if SelectDirectory(rsSelectDir,'',ldir) then
  begin
    if (Sender as TAction).ActionComponent=miTreeAdd then
    begin
      AddNewDir(PopupNode,ExtractFileName(ldir));
    end;

    ctrl.OnDouble:=@OnImportDouble;
    lcnt:=ctrl.ImportDir(GetPathFromNode(tvTree.Selected),ldir);
    ctrl.OnDouble:=nil;
    FillTree();
    if lcnt>0 then
      ShowMessage(IntToStr(lcnt)+rsImported+#13#10+rsLinkingNote)
    else
      ShowMessage(rsNothingImported);
  end;
end;

procedure TRGGUIForm.actEdNewExecute(Sender: TObject);
var
  lNode:TTreeNode;
  lpath,lname:string;
  lcnt,lfile:integer;
begin
  lname:=UpCase(InputBox(rsCreateFile, rsFileName, ''{sDefFileName}));
  if lname='' then exit;
  if lname[Length(lname)]= '\' then lname[Length(lname)]:='/';

  if lname[Length(lname)]= '/' then
  begin
    if tvTree.Items.Count=0 then
      lNode:=nil
    else
      lNode:=tvTree.Selected;

    AddNewDir(lNode,lname);
  end
  else
  begin
    if tvTree.Items.Count=0 then
      lpath:=''
    else
      lpath:=GetPathFromNode(tvTree.Selected);

    lcnt:=ctrl.FileCount;
    lfile:=ctrl.UseData(nil,0,PUnicodeChar(UnicodeString(lpath+lname)));
    // condition just to avoid flicks in root tree list
    if ctrl.FileCount<>lcnt then
    begin
      FillGrid(IntPtr(tvTree.Selected.Data));
    end;
  end;
end;

procedure TRGGUIForm.actEdRenameExecute(Sender: TObject);
var
  lname:string;
  lidx,i:integer;
  isdir:boolean;
begin
  lname:=sgMain.Cells[colName,sgMain.Row]+
         sgMain.Cells[colExt ,sgMain.Row];
  lidx :=IntPtr(sgMain.Objects[colName,sgMain.Row]);
  isdir:=lname[Length(lname)]= '/';
  lname:=UpCase(InputBox(rsRename, rsFileName, lname));

  if isdir then
  begin
    if lname[Length(lname)]= '\' then lname[Length(lname)]:='/';
    if lname[Length(lname)]<>'/' then lname:=lname+'/';
  end
  else
  begin
    if lname[Length(lname)] in ['\','/'] then
      SetLength(lname,Length(lname)-1);
  end;
  ctrl.Rename(lidx,PUnicodeChar(UnicodeString(lname)));
  if isdir then
  begin
    lidx:=ctrl.AsDir(lidx);
    for i:=0 to tvTree.Items.Count-1 do
      if IntPtr(UIntPtr(tvTree.Items[i].Data))=lidx then
      begin
        tvTree.Items[i].Text:=lname;
        break;
      end;
  end;
  FillGrid(IntPtr(tvTree.Selected.Data));
end;
{%ENDREGION Actions}

{%REGION Grid}

procedure TRGGUIForm.sgMainContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
{
var
  isroot,isempty,isparent:boolean;
}
begin
(*
  // Get row not under cursor but focused
  isroot  :=tvTree.Selected=tvTree.Items[0];
  isparent:=(sgMain.Row=1) and (sgMain.Cells[colName,1]=strParentDir);
  isempty :=(sgMain.RowCount=1) or
           ((sgMain.RowCount=2) and (sgMain.Cells[colName,1]=strParentDir));
  // for selected rows
  miGridExport.Visible:=not isempty;
  miGridReset .Visible:=not isempty;
  miGridDelete.Visible:=not isempty;
{
  miGridNew
  miGridAdd
}
   miGridRename.Visible:=not (isempty or isparent);
*)
  mnuGrid.PopUp;
  Handled:=true;
end;

procedure TRGGUIForm.edGridFilterChange(Sender: TObject);
begin
  if (ctrl.FileCount>0) {edGridFilter.Enabled} {and Length(edGridFilter.Text>3)} then
    FillGrid(IntPtr(tvTree.Selected.Data));
end;

procedure TRGGUIForm.sgMainHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
var
  i,j:integer;
begin
  j:=0;

  for i:=0 to sgMain.ColCount-2 do
    inc(j,sgMain.ColWidths[i]);
  if sgMain.Width>(j+8) then sgMain.Width:=j+8;
end;

procedure TRGGUIForm.sgMainKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Shift=[ssCtrl]) then
  begin
    case Key of
      VK_A: begin
        sgMain.Selection:=TGridRect(Rect(colState,1,colSource,sgMain.RowCount));
        Key:=0;
      end;
    end;
  end;
end;

procedure TRGGUIForm.sgMainDblClick(Sender: TObject);
var
  lname:string;
  i,lidx:integer;
begin
  lname:=sgMain.Cells[colName,sgMain.Row];
  if lname[Length(lname)]='/' then
  begin
    if lname=strParentDir then
    begin
      tvTree.Selected:=tvTree.Selected.Parent;
    end
    else
    begin
      lidx:=IntPtr(UIntPtr(sgMain.Objects[colName,sgMain.Row]));
      if ctrl.UpdateState(lidx)<>stateDelete then
      begin
        lidx:=ctrl.AsDir(lidx);
        if lidx>=0 then
          for i:=0 to tvTree.Items.Count-1 do
            if IntPtr(UIntPtr(tvTree.Items[i].Data))=lidx then
            begin
              tvTree.Selected:=tvTree.Items[i];
              break;
            end;
      end;
    end;
  end;
end;

procedure TRGGUIForm.sgMainGetCellHint(Sender: TObject; ACol, ARow: Integer; var HintText: String);
var
  i:integer;
begin
  if (ACol=colName) and (ARow>0) and (ARow<=sgMain.RowCount) and
     (tvTree.Selected<>nil) and
     (IntPtr(UIntPtr(tvTree.Selected.Data))>=0) and
     (IntPtr(UIntPtr(sgMain.Objects[colName,ARow]))>=0) then
  begin
    i:=IntPtr(sgMain.Objects[colName,ARow]);
     HintText:=
         WideToStr(ctrl.PathOfFile(i))+
         WideToStr(ctrl.Files[i]^.Name);
  end;

{
    HintText:=
        WideToStr(ctrl.Dirs [IntPtr(tvTree.Selected.Data)].Name)+
        WideToStr(ctrl.Files[IntPtr(sgMain.Objects[colName,ARow])]^.Name);
}
end;

procedure TRGGUIForm.sgMainCompareCells(Sender: TObject; ACol, ARow, BCol,
  BRow: Integer; var Result: integer);
var
  s1,s2:string;
  dt1,dt2:TDateTime;
begin
{
  if ARow=1 then exit(-1);
  if BRow=1 then exit(1);
}
  s1:=(Sender as TStringGrid).Cells[ACol,ARow];
  s2:=(Sender as TStringGrid).Cells[BCol,BRow];

  if ACol in [colPack,colUnpack,colSource] then
  begin
    result:=StrToIntDef(s1,0)-
            StrToIntDef(s2,0);
  end
  else if ACol=colTime then
  begin
{
  variant - sort not by table but source timestamp
  TMANFileInfo link requires
}
    dt1:=StrToDateTimeDef(s1,0);
    dt2:=StrToDateTimeDef(s2,0);
    if dt1>dt2 then
      result:=1
    else if dt1<dt2 then
      result:=-1
    else
      result:=0;
  end
  else
    result:=CompareStr(s1,s2);

  if (Sender as TStringGrid).SortOrder=soDescending then
    result:=-result;
end;

procedure TRGGUIForm.sgMainHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
var
  linc:integer;
begin
  if IsColumn then
  begin
    // Determine the sort order.
    if index = sgSortColumn then
    begin
      case sgMain.SortOrder of        // Same column clicked again -> invert the order.
        soAscending:  sgMain.SortOrder:=soDescending;
        soDescending: sgMain.SortOrder:=soAscending;
      end;
    end
    else
      sgMain.SortOrder := soAscending;          // Ascending order to start with.

    sgSortColumn := index;
    if (tvTree.Items.Count>0) and (tvTree.Selected<>tvTree.Items[0]) then
      linc:=1
    else
      linc:=0;
    sgMain.SortColRow(True, index, sgMain.FixedRows+linc, sgMain.RowCount-1);
  end;
end;

function TRGGUIForm.FillGridLine(arow:integer; const adir:string; afile:integer):boolean;
var
  lrec:TRGFullInfo;
  lname,lext:string;
  i:integer;
  c:string[2];
begin
  result:=false;

  //--- Filter

//  if afile^.size_s=0 then exit;

  lname:=WideToStr(ctrl.Files[afile]^.Name);
   if Length(edGridFilter.Text)>0 then
    if Pos(edGridFilter.Text,lname)=0 then exit;

  lext:=ExtractFileExt(lname);
  if lext<>'' then
    for i:=0 to High(TableExt) do
    begin
      if lext=TableExt[i]._ext then
      begin
        if not fmFilterForm.exts[i] then exit;
        break;
      end;
    end;

  //--- Fill
  
  ctrl.GetFullInfo(afile,lrec);

  if lrec.ftype=typeDirectory then
  begin
    if fmFilterForm.DirIsOn then
    begin
      sgMain.Objects[colName,arow]:=TObject(IntPtr(afile));
      sgMain.Cells[colName  ,arow]:=lname;
      sgMain.Cells[colDir   ,arow]:=adir;
      sgMain.Cells[colType  ,arow]:=strDir{PAKCategoryName(PAKTypeToCategory(lrec.ftype))};
    end
    else
      exit;
  end
  else
  begin
    sgMain.Objects[colName,arow]:=TObject(IntPtr(afile));
    sgMain.Cells[colName  ,arow]:=ExtractFileNameOnly(lname);
    sgMain.Cells[colType  ,arow]:=PAKCategoryName(PAKTypeToCategory(lrec.ftype));
    sgMain.Cells[colDir   ,arow]:=adir;
    sgMain.Cells[colExt   ,arow]:=lext;

    sgMain.Cells[colPack  ,arow]:=IntToStr(lrec.size_c);
    sgMain.Cells[colUnpack,arow]:=IntToStr(lrec.size_u);
    sgMain.Cells[colSource,arow]:=IntToStr(lrec.size_s);
    if {sgMain.Columns[colTime].Visible and} (lrec.ftime<>0) then
    begin
      try
        sgMain.Cells[colTime,arow]:=DateTimeToStr(FileTimeToDateTime(lrec.ftime));
      except
        sgMain.Cells[colTime,arow]:='0x'+HexStr(lrec.ftime,16);
      end;
    end
    else
      sgMain.Cells[colTime,arow]:='';
  end;

  //--- Marks

  case lrec.state of
    stateNew    : c:=stlblNew;
    stateChanged: c:=stlblChanged;
    stateDelete : c:=stlblDelete;
    stateNew    +stateLink: c:=stlblLinkNew;
    stateChanged+stateLink: c:=stlblLinkEd;
  else
    c:=' ';
  end;
  sgMain.Cells[colState,arow]:=c;

  result:=true;
end;

procedure TRGGUIForm.FillGrid(idx:integer=-1);
var
  lname:string;
  i:integer;
  lfile,lcnt,lbase:integer;
begin
  if inProcess then exit;

  if idx>=ctrl.DirCount then exit;

  inProcess:=true;

  FLastIndex:=idx;
  sgMain.Clear;
  sgMain.BeginUpdate;
  lcnt:=1;
  lbase:=0;

  if idx<=0 then
  begin
    StatusBar.Panels[1].Text:=rsBuildGrid;
    Self.Caption:='RGGUI - '+AnsiString(ctrl.PAK.Name)+rsBuildGrid;

    sgMain.RowCount:=ctrl.total+1; // ctrl.FileCount
    for i:=0 to ctrl.DirCount-1 do
    begin
      if not ctrl.IsDirDeleted(i) then
      begin

        if ctrl.GetFirstFile(lfile,i) then
        begin
          lname:=ctrl.Dirs[i].Name;
          repeat
            if FillGridLine(lcnt, lname, lfile) then
              inc(lcnt);
          until not ctrl.GetNextFile(lfile);
        end;

//        if (lcnt mod 1000)=0 then Application.ProcessMessages;
      end;
    end;
    Self.Caption:='RGGUI - ('+GetGameName(ctrl.PAK.Version)+') '+AnsiString(ctrl.PAK.Name);
  end
  else
  begin
{    if idx=1 then
      sgMain.RowCount:=ctrl.Dirs[idx].count+1
    else
}    begin
      sgMain.RowCount:=ctrl.Dirs[idx].count+2;
      sgMain.Cells  [colName,lcnt]:=strParentDir;
      sgMain.Objects[colName,lcnt]:=TObject(-1);
      inc(lcnt);
    end;
    lbase:=lcnt;

    if ctrl.GetFirstFile(lfile,idx) then
    begin
      lname:=ctrl.Dirs[idx].Name;
      repeat
        if FillGridLine(lcnt, lname, lfile) then
          inc(lcnt);
      until not ctrl.GetNextFile(lfile);
    end;
  end;

  sgMain.RowCount:=lcnt;
  actEdExport.Enabled:=(lcnt-lbase)>0;

  if lcnt=1 then
    ClearInfo
  else
  begin
    sgMain.Row:=1;
    sgMainSelection(sgMain,1,1);
  end;

  sgMain.EndUpdate;

  inProcess:=false;
end;

{%ENDREGION Grid}

{%REGION Tree}

procedure TRGGUIForm.AddNewDir(anode:TTreeNode; const apath:string);
var
  lnode:TTreeNode;
  ls,lpath:string;
  ldir:integer;
begin
  lpath:={UpCase}(apath);

  if      lpath[Length(lpath)]= '\' then lpath[Length(lpath)]:='/'
  else if lpath[Length(lpath)]<>'/' then lpath:=lpath+'/';

  if anode=nil then
    ls:=lpath
  else
    ls:=GetPathFromNode(anode)+lpath;

  ldir:=ctrl.NewDir(PUnicodeChar(UnicodeString(ls)));
  if ldir>=0 then
  begin
    lnode:=tvTree.Items.AddChild(anode,lpath);
    lnode.Data:=pointer(IntPtr(ldir));
    tvTree.Selected:=lnode;
  end;

end;

procedure TRGGUIForm.tvTreeContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  PopupNode:=tvTree.GetNodeAt(MousePos.X, MousePos.Y);
  if PopupNode<>nil then
  begin
    miTreeExtract       .Visible:=PopupNode.Enabled;
    miTreeExtractDir    .Visible:=PopupNode.Enabled;
    miTreeExtractVisible.Visible:=PopupNode.Enabled;
    miTreeNew           .Visible:=PopupNode.Enabled;
    miTreeAdd           .Visible:=PopupNode.Enabled;
    miTreeDelete        .Visible:=PopupNode.Enabled and (PopupNode<>tvTree.Items[0]);
    miTreeRestore       .Visible:=not PopupNode.Enabled;
    mnuTree.PopUp;
  end;
  Handled:=true;
end;

procedure TRGGUIForm.miTreeDeleteClick(Sender: TObject);
var
  ldir:integer;
begin
  ldir:=IntPtr(UIntPtr(PopupNode.Data));
  ctrl.MarkToRemove(ctrl.AsFile(ldir));
  MarkTree(ldir,false);
end;

procedure TRGGUIForm.miTreeNewClick(Sender: TObject);
var
  ldirname:string;
begin
  if (PopupNode=tvTree.Items[0]) and (PopupNode.Count=0) then
    ldirname:=sMedia
  else
    ldirname:='';
  ldirname:=UpCase(InputBox(rsCreateDir, rsDirName, ldirname));
  if ldirname<>'' then
  begin
    AddNewDir(PopupNode,ldirname);
  end;
end;

procedure TRGGUIForm.miTreeRestoreClick(Sender: TObject);
var
  ldir:integer;
begin
  ldir:=IntPtr(UIntPtr(PopupNode.Data));
  ctrl.RemoveUpdate(ctrl.AsFile(ldir));
  MarkTree(ldir,true);
end;

procedure TRGGUIForm.bbCollapseClick(Sender: TObject);
//var i:integer;
begin
  tvTree.BeginUpdate;

  tvTree.FullCollapse;
{
  for i:=2 to tvTree.Items.Count-1 do
    tvTree.Items[i].Expanded:=false;
}
  tvTree.Items[1].Expanded:=true;
  tvTree.Items[0].Expanded:=true;
  tvTree.EndUpdate;
end;

function TRGGUIForm.GetPathFromNode(aNode:TTreeNode):string;
var
  ldir:integer;
begin
  ldir:=IntPtr(UIntPtr(aNode.Data));
  if ldir<0 then
    result:=''
  else
	  result:=ctrl.Dirs[ldir].Name;
{
  result:='';
  repeat
    result:=aNode.Text+cSep+result;
    aNode:=aNode.Parent;
  until aNode=nil;
}
end;

procedure TRGGUIForm.tvTreeSelectionChanged(Sender: TObject);
var
  idx:integer;
begin
  if tvTree.Selected<>nil then
  begin
    if tvTree.Selected<>tvTree.Items[0] then
    begin
      idx:=IntPtr(tvTree.Selected.Data);
    end
    else
      idx:=-1;
    FillGrid(idx);
    PageControl.PageIndex:=1;
  end;
end;

procedure TRGGUIForm.MarkTree(adir:integer; aEnable:boolean);
var
  i:integer;
begin
  for i:=0 to tvTree.Items.Count-1 do
    if IntPtr(UIntPtr(tvTree.Items[i].Data))=adir then
    begin
      tvTree.Items[i].Enabled:=aEnable;
      if not aEnable then
        tvTree.Items[i].Collapse(true);
      exit;
    end;
end;

procedure TRGGUIForm.AddBranch(aroot:TTreeNode; const aname:string);
var
  lnode:TTreeNode;
  ls:string;
  i,ldir:integer;
begin
  ldir:=ctrl.SearchPath(aname);
  aroot.Data:=pointer(IntPtr(ldir));
  if ctrl.GetFirstFile(i,ldir) then
    repeat
      if ctrl.IsDir(i) then
      begin
        ls:=WideToStr(ctrl.Files[i]^.Name);
        lnode:=tvTree.Items.AddChild(aroot,ls);
        AddBranch(lnode,aname+ls);
        if PRGCtrlInfo(ctrl.Files[i])^.action=act_delete then
          lnode.Enabled:=false;
      end;
    until not ctrl.GetNextFile(i);
end;

procedure TRGGUIForm.FillTree();
begin
  StatusBar.Panels[1].Text:=rsBuildTree;
  tvTree.Items.Clear;
  with tvTree do
  begin
    BeginUpdate;
    AddBranch(Items.AddChildObjectFirst(nil,'MOD',pointer(-1)),'');
    if tvTree.Items.Count>20 then
      bbCollapseClick(bbCollapse);
    EndUpdate;
  end;
  tvTree.AlphaSort;

  bbCollapse.Enabled:=tvTree.Items.Count>2;
  if bbCollapse.Enabled then
    tvTree.Items[1].Selected:=true
  else
    tvTree.Items[0].Selected:=true;
end;

{%ENDREGION Tree}

initialization
  LazTGA.Register;

finalization
  LazTGA.UnRegister;
end.
