{TODO: (Check!) Delete several files = set right selection (clear+set on current)}
{TODO: Soundpreview: replace Start and Stop buttons by one (move caption text to resourcestrings}
{TODO: imageset, info panel, checkbox to show as picture or as text. but format? DAT or XML?}
{TODO: 3d view, change texture by choosing file}
{TODO: preview bytes values as different types}
{TODO: make dump text/bytes search}
{TODO: change dump text area encoding}
{TODO: preview as dump by choice?}
{TODO: PreviewSource: autoformat if no block spaces. Add to synedit with line by line}
{TODO: show layout game version at least for changed/added files}
{TODO: Save pak or file: check setData binary files version, repack if needs}
{TODO: add hash brute form}
{TODO: 1-setting to save linked file on disk/mem; 2-ask every time/once}
{TODO: save as for editor}
{TODO: Add file search}
{TODO: StatusBar: change statistic when add/delete dir/file}
{TODO: StatusBar: path changes on dir with files only}
{TODO: option: ask unpack path}
{TODO: replace bitbutton by speed button (scale problem)}
unit formGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids, Menus,
  ActnList, ExtCtrls, StdCtrls, EditBtn, Buttons, TreeFilterEdit,
//  SynEdit, SynHighlighterXML, SynHighlighterT, SynEditTypes, SynPopupMenu,
  rgglobal, rgpak, rgctrl, Types;

type

  { TRGGUIForm }

   TRGGUIForm = class(TForm)
    cbSaveTL1ADM  : TCheckBox;
    cbSaveDateTime: TCheckBox;
    cbPreview: TCheckBox;
    pnlGrid: TPanel;
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
    ilMain     : TImageList;
    PageControl: TPageControl;

    pnlTree      : TPanel;
    pnlTreeFilter: TPanel;
    edTreeFilter : TTreeFilterEdit;
    bbCollapse   : TBitBtn;
//    SynEdit: TSynEdit;
    tbOpenDir    : TToolButton;
    ToolButton1  : TToolButton;
    tvTree       : TTreeView;

    Grid   : TTabSheet;
    pnlAdd : TPanel;

    sgMain: TStringGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar: TStatusBar;

    ToolBar: TToolBar;
    tbOpen     : TToolButton;
    tbSave     : TToolButton;
    tbSaveAs   : TToolButton;
    tbSep1     : TToolButton;
    tbInfo     : TToolButton;
    tbShowLog  : TToolButton;
    tbResetView: TToolButton;
    bbFontEdit: TBitBtn;

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
    miTreeList          : TMenuItem;

    MainMenu: TMainMenu;
    miFile: TMenuItem;
    miFilePatch  : TMenuItem;
    miFileOpen   : TMenuItem;
    miFileSave   : TMenuItem;
    miFileSaveAs : TMenuItem;
    miFileClose  : TMenuItem;
    N1           : TMenuItem;
    miFileExit   : TMenuItem;
    miEdit: TMenuItem;
    miEditExtract: TMenuItem;
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
    actEdNew      : TAction;
    actEdDelete   : TAction;
    actEdReset    : TAction; // Reset content to container
    actEdImport   : TAction; // Load (import) content
    actEdExport   : TAction; // Export content
    actEdRename   : TAction;
    actEdImportDir: TAction;
    actFileSavePatch: TAction;
    actEdFontEdit : TAction;

    actChangeVersion: TAction;
    actOpenDir    : TAction;
    actShowFilter : TAction;
    actResetView  : TAction;

    tbGrid: TToolBar;
    tbEdPreview  : TToolButton;
    tbEdSep1: TToolButton;
    tbEdReset    : TToolButton; // Show wnen any file selected
    tbEdSep2: TToolButton;
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
    procedure actFileCloseExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileSaveAsExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure actFileSavePatchExecute(Sender: TObject);
    procedure actEdFontEditExecute(Sender: TObject);
    procedure actOpenDirExecute(Sender: TObject);
    procedure actShowInfoExecute(Sender: TObject);
    procedure actShowFilterExecute(Sender: TObject);
    procedure actShowLogExecute(Sender: TObject);
    procedure actResetViewExecute(Sender: TObject);
    procedure actPreviewExecute(Sender: TObject);
    procedure bbCollapseClick(Sender: TObject);
    procedure cbPreviewChange(Sender: TObject);
    procedure edGridFilterChange(Sender: TObject);
    procedure miTreeDeleteClick(Sender: TObject);
    procedure miTreeListClick(Sender: TObject);
    procedure miTreeNewClick(Sender: TObject);
    procedure miTreeRestoreClick(Sender: TObject);
    procedure SetupColumns(Sender: TObject);
    procedure DoExtractDir(Sender: TObject);
    procedure DoExtractGrid(Sender: TObject);
    procedure DoExtractTree(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure sgMainCompareCells(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
    procedure sgMainContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure sgMainDblClick(Sender: TObject);
    procedure sgMainGetCellHint(Sender: TObject; ACol, ARow: Integer; var HintText: String);
    procedure sgMainHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure sgMainHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure sgMainKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgMainSelection(Sender: TObject; aCol, aRow: Integer);
    procedure tbColumnClick(Sender: TObject);
    procedure tvTreeContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure tvTreeSelectionChanged(Sender: TObject);
  private
    fmPreview:TForm;
    fmi:TForm;
    ctrl:TRGController;

    LastExt:string;
    LastFilter:integer;
    FLastIndex:integer;
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
    function  FileClose: boolean;
    procedure FillGrid(idx:integer=-1);
    function  FillGridLine(arow: integer; const adir: string; afile: integer): boolean;
    procedure FillTree();
    procedure AddBranch(aroot: TTreeNode; const aname: string);
    function  GetPathFromNode(aNode: TTreeNode): string;
    procedure MarkTree(adir: integer; aEnable: boolean);
    procedure NewPAK;
    procedure OpenPAK(const aname: string);
    procedure LoadSettings;
    procedure SaveSettings;
    procedure SetupView;
    function  SaveFile        (const adir, aname:string; adata:PByte; asize:integer; idx:integer):boolean;
    function  UnpackSingleFile(const adir, aname:string; var buf:PByte): boolean;
    procedure ExtractSingleDir(adir:integer; var buf:PByte);
    procedure UpdateStatistic;
    function  OnImportDouble(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction;

    function  GUIOnChange(idx:integer; atype:integer):integer;
  public
    SrcFont: TFont;
  end;

var
  RGGUIForm: TRGGUIForm;

implementation

{$R *.lfm}
{$IFDEF Windows}
  {.$R bass64.rc}
{$ENDIF}

uses
  LCLIntf,
  LCLType,
  inifiles,
  clipbrd,

  unitLogForm,
  unitFilterForm,
  fmGameVersion,
  fmmodinfo,
  fmAsk,
  fmcombodiff,

  rgpreview,
  
  rgfiletype,
  rgfile,
  rgprepare,
  rgmod
  ;

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
  sSaveDateTime = 'savedatetime';
  sShowDir      = 'showdir';
  sShowExt      = 'showext';
  sShowCategory = 'showcategory';
  sShowTime     = 'showtime';
  sShoPacked    = 'shopacked';
  sShowUnpacked = 'showunpacked';
  sShowSource   = 'showsource';
  sPreview      = 'preview';
  sShowPreview  = 'showpreview';
  sSaveWidth    = 'savewidth';
  sTreeWidth    = 'width_tree';
  sGridWidth    = 'width_grid';
  sDebugLevel   = 'debuglevel';
  sSectSrcFont  = 'srcfont';
  sFontName     = 'Name';
  sFontCharset  = 'Charset';
  sFontSize     = 'Size';
  sFontStyle    = 'Style';
  sFontColor    = 'Color';

const
  sMedia       = 'MEDIA';
//  sDefDirName  = 'NEWDIR';
//  sDefFileName = 'NEWFILE.DAT';

const
  defTreeWidth = 256;
  defGridWidth = 360;

//----- default settings -----

const
  defFontName    = 'Arial Unicode MS'; // 'MS Sans Serif'
  defFontCharset = DEFAULT_CHARSET;
  defFontSize    = 10;
  defFontStyle   = '';
  defFontColor   = clWindowText;

resourcestring
  rsWarning         = 'Warning!';
  rsUnsaved         = 'You have unsaved changes. Continue anyway?';
  rsReadPAK         = ' Read PAK. Parsing...';
  rsBuildTree       = ' Build tree';
  rsBuildGrid       = ' Build file list. Please, wait...';
//  rsBuildPreview    = ' Build preview';
  rsNothingToShow   = 'Nothing to show with current filter';
  rsUnpackSucc      = 'unpacked succesfully.';
  rsFilesUnpackSucc = ' files unpacked succesfully.';
//  rsTotal           = 'Total: ';
  rsFiles           = 'Files: ';
  rsDirs            = '; dirs: ';
  rsFilePath        = 'File path: ';
  rsSaved           = 'File saved';
  rsSavedAs         = 'File saved as';
  rsSavedPatch      = 'Patch saved as';
  rsCantSave        = 'Can''t save file';
  rsExtractDir      = 'Extract directory ';
  rsCreateDir       = 'Create directory';
  rsSelectDir       = 'Select directory';
  rsDirName         = 'Enter dir name';
  rsCreateFile      = 'Create file';
  rsFileName        = 'Enter file name';
  rsFileDirName        = 'Enter name (with / at the end for dir)';
  rsReady           = 'Ready to work';
  rsRename          = 'Rename file/dir';
  rsImported        = ' files imported';
  rsLinkingNote     = 'These files still on disk and not built-in until PAK/MOD saved.';
  rsNothingImported = 'Nothing was imported.';
//  rsChooseVer       = 'Choose game';
//  rsGameVer         = 'Game';

  rsNewFile         = 'New file';
  rsChangedFile     = 'Changed file';
  rsDeleteFile      = 'Deleted file';
  rsLinkNewFile     = 'Link to new file';
  rsLinkChangedFile = 'Link to changed file';

{%ENDREGION Constants}

{ TRGGUIForm }

{%REGION Settings}

procedure TRGGUIForm.actResetViewExecute(Sender: TObject);
begin
  pnlTree.Width:=defTreeWidth;
  pnlGrid.Width:=defGridWidth;
  //  sgMain .Width:=defGridWidth;
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
  ls:AnsiString;
  lstyle:TFontStyles;
  i:integer;
begin
  if cbSaveSettings.Checked then
  begin
    config:=TMemIniFile.Create(ExtractPath(ParamStr(0))+INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

    config.WriteString (sSectSettings,sOutDir      ,deOutDir.Text);
    config.WriteString (sSectSettings,sExt         ,LastExt);
    config.WriteInteger(sSectSettings,sFilter      ,LastFilter);
    config.WriteBool   (sSectSettings,sSavePath    ,cbUnpackTree.Checked);
    config.WriteBool   (sSectSettings,sUseFName    ,cbUseFName.Checked);
    config.WriteBool   (sSectSettings,sMODDAT      ,cbMODDAT.Checked);
    config.WriteBool   (sSectSettings,sFastScan    ,cbFastScan.Checked);
    config.WriteBool   (sSectSettings,sSaveSettings,cbSaveSettings.Checked);
    config.WriteBool   (sSectSettings,sSaveDateTime,cbSaveDateTime.Checked);

    config.WriteBool(sSectSettings,sShowDir     ,bShowDir     );
    config.WriteBool(sSectSettings,sShowExt     ,bShowExt     );
    config.WriteBool(sSectSettings,sShowCategory,bShowCategory);
    config.WriteBool(sSectSettings,sShowTime    ,bShowTime    );
    config.WriteBool(sSectSettings,sShoPacked   ,bShowPacked  );
    config.WriteBool(sSectSettings,sShowUnpacked,bShowUnpacked);
    config.WriteBool(sSectSettings,sShowSource  ,bShowSource  );

    config.WriteBool(sSectSettings,sShowPreview,actShowPreview.Checked);
    config.WriteBool(sSectSettings,sPreview    ,cbPreview     .Checked);

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

    //--- Font
    config.WriteString (sSectSrcFont,sFontName   ,SrcFont.Name);
    config.WriteInteger(sSectSrcFont,sFontCharset,SrcFont.Charset);
    config.WriteInteger(sSectSrcFont,sFontSize   ,SrcFont.Size);
    config.WriteString (sSectSrcFont,sFontColor  ,ColorToString(SrcFont.Color));

    lstyle:=SrcFont.Style;
    ls:='';
    if fsBold      in lstyle then ls:='bold ';
    if fsItalic    in lstyle then ls:=ls+'italic ';
    if fsUnderline in lstyle then ls:=ls+'underline ';
    if fsStrikeOut in lstyle then ls:=ls+'strikeout ';
    config.WriteString(sSectSrcFont,sFontStyle,ls);

    fmFilterForm.SaveSettings(config);

    config.UpdateFile;
    config.Free;
  end;
end;

procedure TRGGUIForm.LoadSettings;
var
  config:TIniFile;
  ls:AnsiString;
  lstyle:TFontStyles;
begin
  config:=TIniFile.Create(ExtractPath(ParamStr(0))+INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  LastExt               :=config.ReadString (sSectSettings,sExt         ,RGDefaultExt);
  LastFilter            :=config.ReadInteger(sSectSettings,sFilter      ,4);
  cbUnpackTree.Checked  :=config.ReadBool   (sSectSettings,sSavePath    ,true);
  cbUseFName.Checked    :=config.ReadBool   (sSectSettings,sUseFName    ,true);
  cbMODDAT.Checked      :=config.ReadBool   (sSectSettings,sMODDAT      ,true);
  cbFastScan.Checked    :=config.ReadBool   (sSectSettings,sFastScan    ,false);
  cbSaveSettings.Checked:=config.ReadBool   (sSectSettings,sSaveSettings,false);
  cbSaveDateTime.Checked:=config.ReadBool   (sSectSettings,sSaveDateTime,true);
  deOutDir.Text         :=config.ReadString (sSectSettings,sOutDir      ,'');
  if deOutDir.Text='' then deOutDir.Text:=ExtractFileDir(ParamStr(0));

  bShowDir     :=config.ReadBool(sSectSettings,sShowDir     ,true);
  bShowExt     :=config.ReadBool(sSectSettings,sShowExt     ,true);
  bShowCategory:=config.ReadBool(sSectSettings,sShowCategory,false);
  bShowTime    :=config.ReadBool(sSectSettings,sShowTime    ,false);
  bShowPacked  :=config.ReadBool(sSectSettings,sShoPacked   ,false);
  bShowUnpacked:=config.ReadBool(sSectSettings,sShowUnpacked,false);
  bShowSource  :=config.ReadBool(sSectSettings,sShowSource  ,false);

  if cbPreview.Checked then
    actShowPreview.Checked:=config.ReadBool(sSectSettings,sShowPreview,false)
  else
    actShowPreview.Checked:=False;
  cbPreview.Checked:=config.ReadBool(sSectSettings,sPreview,true);
  if not cbPreview.Checked then actPreviewExecute(Self); // call automatically if Checked

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

//--- Font
  SrcFont.Name   :=config.ReadString (sSectSrcFont,sFontName   ,defFontName);
  SrcFont.Charset:=config.ReadInteger(sSectSrcFont,sFontCharset,defFontCharset);
  SrcFont.Size   :=config.ReadInteger(sSectSrcFont,sFontSize   ,defFontSize);
  SrcFont.Color  :=StringToColor(
      config.ReadString(sSectSrcFont,sFontColor,ColorToString(defFontColor)));

  ls:=config.ReadString(sSectSrcFont,sFontStyle,defFontStyle);
  lstyle:=[];
  if Pos('bold'     ,ls)<>0 then lstyle:=lstyle+[fsBold];
  if Pos('italic'   ,ls)<>0 then lstyle:=lstyle+[fsItalic];
  if Pos('underline',ls)<>0 then lstyle:=lstyle+[fsUnderline];
  if Pos('strikeout',ls)<>0 then lstyle:=lstyle+[fsStrikeOut];
  SrcFont.Style:=lstyle;
  PreviewFont(SrcFont);

  fmFilterForm.LoadSettings(config);
  config.Free;
end;

{%ENDREGION Settings}

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
  ctrl.NewDir('MEDIA/');
  FillTree();
  SetupView();

  ctrl.OnChange:=@GUIOnChange;
end;

procedure TRGGUIForm.FormCreate(Sender: TObject);
begin
  FLastIndex:=-1;
  sgSortColumn:=colName;
  SrcFont:=TFont.Create;

  fmLogForm:=nil;
  fmFilterForm:=TFilterForm.Create(Self);
  LoadSettings();
  SetupColumns(Self);
  ClearInfo();

  if ParamCount>0 then
    OpenPAK(ParamStr(1))
  else
    NewPAK();

  PageControl.ActivePageIndex:=1;
  inProcess:=false;
end;

procedure TRGGUIForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //  if actFileExit.Enabled then actFileExitExecute(Sender);
//  if actFileExit.Enabled then
  if not FileClose then
  begin
    CloseAction:=caNone;
    exit;
  end;

  SaveSettings();
  SrcFont.Free;
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

  ClosePreviews;
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
//  if FileClose() then
  begin
//    actFileExit.Enabled:=false;
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
//ctrl.Trace;
  FillTree();
  SetupView();

  ctrl.OnChange:=@GUIOnChange;
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
    OpenDialog.Filter     :=RGDefReadFilter;
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
      verTL2: dlg.FilterIndex:=1;
      verHob: dlg.FilterIndex:=3;
      verRG : dlg.FilterIndex:=4;
      verRGO: dlg.FilterIndex:=5;
      verTL1: dlg.FilterIndex:=6;
    else
      dlg.FilterIndex:=1;
    end;
    dlg.InitialDir:=ctrl.PAK.Directory;
    dlg.FileName  :=ctrl.PAK.Name;
    dlg.DefaultExt:=RGDefaultExt;
    dlg.Filter    :=RGDefWriteFilter;
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
        6: lver:=verTL1;
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

procedure TRGGUIForm.actFileSavePatchExecute(Sender: TObject);
var
  dlg:TSaveDialog;
  lver:integer;
begin
  dlg:=TSaveDialog.Create(nil);
  try
    case ctrl.PAK.Version of
      verTL2: dlg.FilterIndex:=1;
      verHob: dlg.FilterIndex:=3;
      verRG : dlg.FilterIndex:=4;
      verRGO: dlg.FilterIndex:=5;
      verTL1: dlg.FilterIndex:=6;
    else
      dlg.FilterIndex:=1;
    end;
    dlg.InitialDir:=ctrl.PAK.Directory;
    dlg.FileName  :=ctrl.PAK.Name;
    dlg.DefaultExt:=RGDefaultExt;
    dlg.Filter    :=RGDefWriteFilter;
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
        6: lver:=verTL1;
      end;
//      wasnew:=ctrl.PAK.Name='';
      if ctrl.SavePatch(dlg.Filename,lver) then
      begin
        ShowMessage(rsSavedPatch+' '+dlg.Filename)
      end
      else
        ShowMessage(rsCantSave+' '+dlg.Filename);
    end;
  finally
    dlg.Free;
  end;

end;

procedure TRGGUIForm.actEdFontEditExecute(Sender: TObject);
var
  FontDialog:TFontDialog;
begin
  FontDialog:=TFontDialog.Create(nil);
  try
    FontDialog.Font.Assign(SrcFont);
    if FontDialog.Execute then
    begin
      SrcFont.Assign(FontDialog.Font);
      PreviewFont(SrcFont);
    end;
  finally
    FontDialog.Free;
  end;
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
            FixFileExt(ExtractName(FileNames[i])))), true);
        FreeMem(pc);
      end;
    end;
    FillTree();
    exit;
  end;
end;

function TRGGUIForm.GUIOnChange(idx:integer; atype:integer):integer;
var
  ldir,lname:AnsiString;
  i:integer;
begin
  result:=1;
  case atype of
    faStart : inProcess:=true;
    faFinish: inProcess:=false;
  else
    if not inProcess then
    begin
      ldir :=WideToStr(ctrl.PathOfFile(idx));
      lname:=WideToStr(ctrl.Files[idx]^.Name);
      if rgDebugLevel=dlDetailed then
        RGLog.Add('File affected ('+GetChangesName(atype)+'): '+ldir+lname);
      // 1 - check grid for file
      // can't use sgMain.Row directly coz it can be not from Preview only
      for i:=1 to sgMain.RowCount-1 do
      begin
        if IntPtr(sgMain.Objects[colName,i])=idx then
        begin
          FillGridLine(i,ldir,idx);
          break;
        end;
      end;
      // 2 - check for feature tags
      if atype<>faInfo then
        if ((ldir=strRootDir) and (lname='FEATURETAGS.HIE')) or
            (ldir='MEDIA/FEATURETAGS/') then
        begin
          PrepareFeatureTags(@ctrl);
        end;
    end;
  end;
end;

{%ENDREGION Form}

{%REGION Save}

function TRGGUIForm.SaveFile(const adir,aname:string;
      adata:PByte; asize:integer; idx:integer):boolean;
var
  f:file of byte;
  pc:PUnicodeChar;
  ls,loutdir,lext:string;
  lfi:TRGFullInfo;
  ltime:TDateTime;
  ltype,lsize:integer;
  ldecompiled:boolean;
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
  ltype:=RGTypeOfExt(aname);

  if cbSaveDateTime.Checked then
  begin
    if idx<=0 then idx:=ctrl.SearchFile(adir+aname);
    ctrl.GetFullInfo(idx,lfi);
    ltime:=FileTimeToDateTime(lfi.ftime);
  end
  else
    ltime:=0;

  ldecompiled:=false;
  // save decoded file
  if (not rbBinOnly.Checked) and ((ltype and $FF)=typeData) then
  begin
    RGLog.Reserve('Processing '+adir+aname);

    // was: just parse binary, now - convert to text too
    if DecompileFile(adata, asize, adir+aname, pc, cbSaveUTF8.Checked) then
    begin
      ldecompiled:=true;
      if not cbTest.Checked then
      begin
        if rbTextRename.Checked or (ltype=typeRaw) then
          lext:='.TXT'
        else
          lext:='';

        ls:=loutdir+aname+lext;
        AssignFile(f,ls);
        Rewrite(f);
        if IOResult=0 then
        begin
          if cbSaveUTF8.Checked then
            lsize:=Length(PAnsiChar(pc))
          else
            lsize:=Length(pc)*SizeOf(WideChar);
          BlockWrite(f,pc^,lsize);
          CloseFile(f);
          if ltime>0 then FileSetDate(ls,ltime);
        end;
      end;
      FreeMem(pc);
    end;
  end;

  if not cbTest.Checked then
  begin
    // set decoding binary file extension
    lext:='';
    if (rbGUTSStyle.Checked) and ((ltype and $FF)=typeData) then
    begin
      if ltype=typeLayout then
      begin
        if ctrl.PAK.Version=verTL1 then
        begin
          // TL1 have different LAYOUT format for UI dir
          if (not ldecompiled) and
             (Pos('MEDIA/UI/',UpCase(StringReplace(adir,'\','/',[rfReplaceAll])))=1) then
            lext:=''
          else
            lext:='.CMP'
        end
        else
          lext:='.BINLAYOUT'
      end
      else if ltype=typeRaw then
        lext:=''
      else
      begin
        // TL1 and TL2 have XML form of Imageset
        if (ltype=typeImageset) and (not ldecompiled) and
           (ABS(ctrl.PAK.Version) in [verTL1,verTL2]) then
          lext:=''
        else if ctrl.PAK.Version=verTL1 then
          lext:='.ADM'
        else
          lext:='.BINDAT';
      end;
    end;

    // save binary file
    if not (rbTextOnly.Checked and ((ltype and $FF)=typeData)) or
       ((ltype=typeImageset) and (not ldecompiled)) then
    begin
      ls:=loutdir+aname+lext;
      AssignFile(f,ls);
      Rewrite(f);
      if IOResult=0 then
      begin
        BlockWrite(f,adata^,asize);
        CloseFile(f);
        if ltime>0 then FileSetDate(ls,ltime);
      end;
    end;
  end;

  result:=true;
end;

procedure TRGGUIForm.actEdExportExecute(Sender: TObject);
var
  ldir, lname:string;
  lptr:pointer;
  lidx,lsize,i,lcnt:integer;
begin
  lcnt:=0;
  lptr:=nil;

  for i:=1 to sgMain.RowCount-1 do
  begin
    if sgMain.IsCellSelected[colDir,i] then
    begin
      lidx:=IntPtr(sgMain.Objects[colName,i]);
      if lidx>=0 then
      begin
  //      lsize:=ctrl.GetBinary(ctrl.SearchFile(ldir+lname),lptr);
        lsize:=ctrl.GetBinary(lidx,lptr);
        if lsize>0 then
        begin
          ldir :=sgMain.Cells[colDir ,i];
          lname:=sgMain.Cells[colName,i]+sgMain.Cells[colExt,i];
          if SaveFile(ldir, lname, lptr, lsize, lidx) then
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
  lsize,lidx:integer;
begin
  lidx:=ctrl.SearchFile(adir+aname);
  lsize:=ctrl.GetBinary(lidx,buf);
  result:=SaveFile(adir,aname,buf,lsize,lidx);
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
      ltype:=RGTypeOfExt(lname);
      if (ltype<>typeDirectory) then
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
  {bRoot,}bNoTree,bEmpty,bParent:boolean;
begin
  if fmPreview<>nil then
  begin
    fmPreview.Free;
    fmPreview:=nil;
  end;

  if PageControl.ActivePage=Grid then Self.ActiveControl:=SGMain;

  bNoTree:=tvTree.Items.Count=0;
//  bRoot  :=(not bNoTree) and (tvTree.Selected=tvTree.Items[0]);
  bEmpty :=(not bNoTree) and
          ((sgMain.RowCount=1) or
          ((sgMain.RowCount=2) and (IntPtr(UIntPtr(tvTree.Selected.Data))>0)));
//            (IntPtr(UIntPtr(sgMain.Objects[colName,1]))=-1);
  bParent:=(not bNoTree) and
          ((sgMain.Row     =1) and (IntPtr(UIntPtr(tvTree.Selected.Data))>0));

  // Single file actions
  actEdRename.Enabled:=not (bNoTree or bEmpty or bParent);
  // Selected files actions
  actEdExport.Enabled:=not (bNoTree or bEmpty);
  actEdReset .Enabled:=not (bNoTree or bEmpty);
  actEdDelete.Enabled:=not (bNoTree or bEmpty);

  actEdNew   .Enabled:=not bNoTree;
  actEdImport.Enabled:=not bNoTree;
end;

procedure TRGGUIForm.sgMainSelection(Sender: TObject; aCol, aRow: Integer);
var
  lrec:TRGFullInfo;
  ldir:string;
  lfile:integer;
begin
  ClearInfo();

  if cbPreview.Checked and actShowPreview.Checked then
  begin
    if (aCol<1) or (aRow<1) or
  //    ((aRow=1) and (sgMain.Cells[colName,aRow]=strParentDir)) then
      ((aRow=1) and (IntPtr(UIntPtr(tvTree.Selected.Data))>1)) then
    begin
      Exit;
    end;

    lfile:=IntPtr(sgMain.Objects[colName,aRow]);
    ldir :=sgMain.Cells[colDir,aRow];

    if lfile>=0 then
    begin
      fmPreview:=MakePreview(ctrl,lfile);
      if fmPreview<>nil then
      begin
        fmPreview.BorderStyle:=bsNone;
        fmPreview.Align:=alClient;
        fmPreview.Parent:=pnlAdd;
        fmPreview.Visible:=true;
      end;
    end;
    StatusBar.Panels[1].Text:=rsFilePath+ldir;
  end;
end;

procedure TRGGUIForm.actPreviewExecute(Sender: TObject);
var
  lform:TForm;
  ldir:AnsiString;
  lfile:integer;
begin
  if cbPreview.Checked then
  begin
    actShowPreview.Checked:=not actShowPreview.Checked;
    if actShowPreview.Checked then
    begin
      pnlGrid.Align:=alLeft;
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
      pnlGrid.Align:=alClient;
    end;
  end
  else
  begin
    actShowPreview.Checked:=false;
    if pnlAdd.Visible then
    begin
      ClearInfo();
      pnlAdd.Visible:=false;
      Splitter2.Visible:=false;
      pnlGrid.Align:=alClient;
      exit;
    end;

    if {(sgMain.Col<1) or} (sgMain.Row<1) or
  //    ((aRow=1) and (sgMain.Cells[colName,aRow]=strParentDir)) then
      ((sgMain.Row=1) and (IntPtr(UIntPtr(tvTree.Selected.Data))>1)) then
    begin
      Exit;
    end;

    lfile:=IntPtr(sgMain.Objects[colName,sgMain.Row]);
    ldir :=sgMain.Cells[colDir,sgMain.Row];

    if lfile>=0 then
    begin
      lform:=MakePreview(ctrl,lfile);
      if lform<>nil then lform.Show;
//      FillGridLine(sgMain.Row,ldir,lfile); //?? remove after trigger implementation
    end;
  end;
end;

procedure TRGGUIForm.cbPreviewChange(Sender: TObject);
begin
  if cbPreview.Checked then
  begin
    ClosePreviews();
  end;
  actShowPreview.Checked:=true; // will be inverted
  actPreviewExecute(Sender);
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

procedure TRGGUIForm.actEdImportExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  pc:PWideChar;
  ldir:string;
  i:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
//    OpenDialog.Title  :=rsFileOpen;
    OpenDialog.Options    :=[ofFileMustExist,ofAllowMultiSelect,ofEnableSizing];
    OpenDialog.DefaultExt :='.*';
    OpenDialog.Filter     :='';
    OpenDialog.FilterIndex:=0;

    if OpenDialog.Execute then
    begin
      ldir:=GetPathFromNode(tvTree.Selected);
      for i:=0 to OpenDialog.Files.Count-1 do
      begin
        pc:=StrToWide(OpenDialog.Files[i]);
        // add update as file content (as is)
        ctrl.AddFileData(pc, PUnicodeChar(UnicodeString(
            ldir+FixFileExt(ExtractName(OpenDialog.Files[i])))), true);
        FreeMem(pc);
      end;
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

  istext:=(RGTypeOfExt(ctrl.Files[idx]^.Name) and $FF)=typeData;

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
      {$I-}
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
//      AddNewDir(PopupNode,ExtractName(ldir));
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
  lcnt{,lfile}:integer;
begin
  lname:=UpCase(InputBox(rsCreateFile, rsFileDirName, ''{sDefFileName}));
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
    {lfile:=}ctrl.UseData(nil,0,PUnicodeChar(UnicodeString(lpath+lname)));
    // condition just to avoid flicks in root tree list
    if ctrl.FileCount<>lcnt then
    begin
      FillGrid(IntPtr(tvTree.Selected.Data));
    end;
  end;
end;

procedure TRGGUIForm.actEdRenameExecute(Sender: TObject);
var
  lname,lhelp:string;
  lidx,i:integer;
  isdir:boolean;
begin
  lname:=sgMain.Cells[colName,sgMain.Row]+
         sgMain.Cells[colExt ,sgMain.Row];
  lidx :=IntPtr(sgMain.Objects[colName,sgMain.Row]);
  isdir:=lname[Length(lname)]= '/';
  if isdir then
    lhelp:=rsDirName
  else
    lhelp:=rsFileName;
  lname:=UpCase(InputBox(rsRename, lhelp, lname));

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
  if Key=VK_RETURN then
  begin
    sgMainDblClick(Sender);
    Key:=0;
  end;

  if (Shift=[ssCtrl]) then
  begin
    case Key of
      VK_A: begin
        sgMain.Selection:=TGridRect(Rect(colState,1,colSource,sgMain.RowCount));
        Key:=0;
      end;
    end;
  end;

  if (Shift=[]) and (Key=VK_DELETE) then
  begin
    actEdDeleteExecute(Sender);
    Key:=0;
  end;
end;

procedure TRGGUIForm.sgMainDblClick(Sender: TObject);
var
  lname:string;
  i,lidx:integer;
begin
  if sgMain.Row<1 then exit;

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
  ls:string;
  i:integer;
begin
  if (ARow>0) and (ARow<=sgMain.RowCount) and
     (tvTree.Selected<>nil) and
     (IntPtr(UIntPtr(tvTree.Selected.Data))>=0) and
     (IntPtr(UIntPtr(sgMain.Objects[colName,ARow]))>=0) then
  begin
    i:=IntPtr(sgMain.Objects[colName,ARow]);
    if (ACol=colName) then
    begin
		  HintText:=
         WideToStr(ctrl.PathOfFile(i))+
         WideToStr(ctrl.Files[i]^.Name)
    end
    else if (ACol=colState) then
    begin
      ls:=sgMain.Cells[colState,ARow];
           if ls=stlblNew     then HintText:=rsNewFile
      else if ls=stlblChanged then HintText:=rsChangedFile
      else if ls=stlblDelete  then HintText:=rsDeleteFile
      else if ls=stlblLinkNew then HintText:=rsLinkNewFile
      else if ls=stlblLinkEd  then HintText:=rsLinkChangedFile
    end;
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
  ldir1,ldir2:boolean;
begin
{
  if ARow=1 then exit(-1);
  if BRow=1 then exit(1);
}

  s1:=(Sender as TStringGrid).Cells[colName,ARow];
  s2:=(Sender as TStringGrid).Cells[colName,BRow];
  ldir1:=(s1<>'') and (s1[Length(s1)]= '/');
  ldir2:=(s2<>'') and (s2[Length(s2)]= '/');
{
       if (s1 ='') and (s2='') then result:=0
  else if (s1<>'') and (s2='') then result:=1
  else if (s2<>'') and (s1='') then result:=-1

  else} if ldir1 and ldir2 then
  begin
    result:=CompareStr(s1,s2);
    if aCol<>colName then exit;
  end
  else if ldir1 and not ldir2 then begin result:=-1; exit; end
  else if ldir2 and not ldir1 then begin result:=1 ; exit; end
  else
  begin
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
  end;

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
    if sgMain.RowCount>2 then
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

  lext:=ExtractExt(lname);
  if lext<>'' then
    for i:=0 to RGTypeExtCount()-1 do
    begin
      if lext=RGTypeExtFromList(i) then
      begin
        if not fmFilterForm.exts[i] then exit;
        break;
      end;
    end;
  if RGTypeOfExt(lext)=typeUnknown then
    if not fmFilterForm.UnknownIsOn then exit;

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
    sgMain.Cells[colName  ,arow]:=ExtractNameOnly(lname);
    sgMain.Cells[colType  ,arow]:=RGTypeGroupName(lrec.ftype);
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

  if sgSortColumn>=0 then
  begin
    if (tvTree.Items.Count>0) and (tvTree.Selected<>tvTree.Items[0]) then
      lbase:=1
    else
      lbase:=0;
    if sgMain.RowCount>2 then
    sgMain.SortColRow(True, sgSortColumn, sgMain.FixedRows+lbase, sgMain.RowCount-1);
  end;

  if lcnt=1 then
  begin
    ClearInfo;
    StatusBar.Panels[1].Text:=rsNothingToShow;
  end
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
  begin
    // if we have child with "root" name already
    lnode:=anode.FindNode(lpath);
    if lnode<>nil then
    begin
      tvTree.Selected:=lnode;
      exit;
    end;

    ls:=GetPathFromNode(anode)+lpath;
  end;

  ldir:=ctrl.NewDir(PUnicodeChar(UnicodeString(ls)));
  if ldir>=0 then
  begin
    lnode:=tvTree.Items.AddChild(anode,lpath);
    lnode.Data:=pointer(IntPtr(ldir));
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

procedure TRGGUIForm.miTreeListClick(Sender: TObject);
var
  sl:TStringList;
  tn:TTreeNode;
  i:integer;
  b:boolean;
begin
  sl:=TStringList.Create;
  for i:=0 to tvTree.Items.Count-1 do
  begin
    b:=true;
    tn:=tvTree.Items[i].Parent;
    while tn<>nil do
    begin
      if not tn.Expanded then
      begin
        b:=false;
        break;
      end;
      tn:=tn.Parent;
    end;
    if b then
      sl.Add(GetPathFromNode(tvTree.Items[i]));
  end;
  Clipboard.AsText:=sl.Text;
  sl.Free;
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

end.
