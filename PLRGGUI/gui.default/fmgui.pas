{TODO: show layout game version at least for changed/added files}
{TODO: Save pak or file: check setData binary files version, repack if needs}
{TODO: add hash brute form}
{TODO: 1-setting to save linked file on disk/mem; 2-ask every time/once}
{TODO: Add file search}
{TODO: StatusBar: change statistic when add/delete dir/file}
{TODO: StatusBar: path changes on dir with files only}
{TODO: option: ask unpack path}
{TODO: replace bitbutton by speed button (scale problem)}
unit fmGUI;

{$mode objfpc}{$H+}
{$WARN 4055 off : Conversion between ordinals and pointers is not portable}
{$WARN 5024 off : Parameter "$1" not used}
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids, Menus,
  ActnList, ExtCtrls, StdCtrls, EditBtn, Buttons, TreeFilterEdit,
  RGGlobal, RGPak, RGCtrl, Types;

type

  { TRGGUIForm }

   TRGGUIForm = class(TForm)
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
    procedure CoreDirChanged(Sender: TObject; var Value: String);
    procedure CoreOptChanged(Sender: TObject);
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
    FCtrl:PRGController;

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
    procedure LoadSettings;
    function  SaveAs(asPatch: boolean): boolean;
    procedure SaveSettings;
    procedure SetupView;
    procedure ExtractSingleDir(adir: integer);
    function  OnImportDouble(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction;

    function  GUIOnChange(actrl:pointer; idx:integer; atype:integer):integer;
  public
    SrcFont: TFont;
  end;

var
  RGGUIForm: TRGGUIForm;


implementation

{$R *.lfm}

uses
  LCLIntf,
  LCLType,
  IniFiles,
  Clipbrd,

  fmLog,
  fmFilter,
  fmGameVersion,
  fmModInfo,
  fmAsk,
  fmComboDiff,

  RGGUI.Core,
  RGGUI.Shared,
  RGPreview,
  RGPlugins,

  RGFileType,
  RGFile,
  RGPrepare,
  RGMod
  ;


{%REGION Constants}

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
  sSectSettings = 'settings';
  sExt          = 'ext';
  sFilter       = 'filter';
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

const
  sMedia       = 'MEDIA';

const
  defTreeWidth = 256;
  defGridWidth = 360;

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
begin
  if cbSaveSettings.Checked then
  begin
    config:=TMemIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes]);

    SaveCoreSettings(config);

    config.WriteString (sSectSettings,sExt         ,LastExt);
    config.WriteInteger(sSectSettings,sFilter      ,LastFilter);

    config.WriteBool   (sSectSettings,sShowDir     ,bShowDir     );
    config.WriteBool   (sSectSettings,sShowExt     ,bShowExt     );
    config.WriteBool   (sSectSettings,sShowCategory,bShowCategory);
    config.WriteBool   (sSectSettings,sShowTime    ,bShowTime    );
    config.WriteBool   (sSectSettings,sShoPacked   ,bShowPacked  );
    config.WriteBool   (sSectSettings,sShowUnpacked,bShowUnpacked);
    config.WriteBool   (sSectSettings,sShowSource  ,bShowSource  );

    config.WriteBool   (sSectSettings,sShowPreview ,actShowPreview.Checked);
    config.WriteBool   (sSectSettings,sPreview     ,cbPreview     .Checked);

    config.WriteBool   (sSectSettings,sSaveWidth   ,cbSaveWidth.Checked);
    if cbSaveWidth.Checked then
    begin
      config.WriteInteger(sSectSettings,sTreeWidth,pnlTree.Width);
      // don't use sgMain.Width coz it can be wrong with no preview on
      config.WriteInteger(sSectSettings,sGridWidth,Splitter2.Left{Self.Width-pnlAdd.Width});
    end;

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
  config:=TIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  LastExt               :=config.ReadString (sSectSettings,sExt         ,RGDefaultExt);
  LastFilter            :=config.ReadInteger(sSectSettings,sFilter      ,RGDefaultFilter);

  // Core
  deOutDir      .Text   :=cfgUnpackDir;
  cbUnpackTree  .Checked:=cfgUnpackTree;
  cbUseFName    .Checked:=cfgUsePakName;
  cbMODDAT      .Checked:=cfgMakeMODDAT;
  cbFastScan    .Checked:=cfgFastScan;
  cbSaveSettings.Checked:=cfgSaveSettings;
  cbSaveDateTime.Checked:=cfgSaveDateTime;
  cbSaveUTF8    .Checked:=cfgSaveUTF8;
  case cfgSaveMode of
    smBinary: rbBinOnly  .Checked:=true;
    smText  : rbTextOnly .Checked:=true;
    smGUTS  : rbGUTSStyle.Checked:=true;
  else // smRename
    rbTextRename.Checked:=true;
  end;

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
  SetPreviewFont(SrcFont);

  fmFilterForm.LoadSettings(config);
  config.Free;
end;

procedure TRGGUIForm.CoreOptChanged(Sender: TObject);
begin
       if Sender=cbUnpackTree   then cfgUnpackTree  :=cbUnpackTree  .Checked
  else if Sender=cbSaveUTF8     then cfgSaveUTF8    :=cbSaveUTF8    .Checked
  else if Sender=cbMODDAT       then cfgMakeMODDAT  :=cbMODDAT      .Checked
  else if Sender=cbFastScan     then cfgFastScan    :=cbFastScan    .Checked
  else if Sender=cbUseFName     then cfgUsePakName  :=cbUseFName    .Checked
  else if Sender=cbSaveDateTime then cfgSaveDateTime:=cbSaveDateTime.Checked
  else if Sender=cbSaveSettings then cfgSaveSettings:=cbSaveSettings.Checked

  else if Sender=rbBinOnly      then cfgSaveMode    :=smBinary
  else if Sender=rbTextOnly     then cfgSaveMode    :=smText
  else if Sender=rbTextRename   then cfgSaveMode    :=smRename
  else if Sender=rbGUTSStyle    then cfgSaveMode    :=smGUTS

  else if Sender=deOutDir       then cfgUnpackDir   :=deOutDir.Text;
end;

procedure TRGGUIForm.CoreDirChanged(Sender: TObject; var Value: String);
begin
  cfgUnpackDir:=deOutDir.Text;
end;

{%ENDREGION Settings}

{%REGION Form}

procedure TRGGUIForm.SetupView;
begin
  actFileSave.Enabled:=(FCtrl^.DirCount>1) or (FCtrl^.FileCount>0);

  if FCtrl^.PAK.Name='' then
  begin
    Self.Caption:='RGGUI';
  end
  else
  begin
    Self.Caption:='RGGUI - ('+GetGameName(FCtrl^.PAK.Version)+') '+FCtrl^.PAK.Name;
  end;

  EdGridFilter.Text:='';

  SetupColumns(Self);

  StatusBar.Panels[0].Text:=rsFiles+IntToStr(FCtrl^.FileCount)+
                            rsDirs +IntToStr(FCtrl^.DirCount);
  StatusBar.Panels[1].Text:=rsReady;
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
  begin
    StatusBar.Panels[1].Text:=rsReadPAK;
    Application.ProcessMessages;

    FCtrl:=LoadPak(ParamStr(1));
  end
  else
    FCtrl:=NewPak();

  FillTree();
  SetupView();

  FCtrl^.OnChange:=@GUIOnChange;

  PageControl.ActivePageIndex:=1;
//  inProcess:=false;

  FillEditMenu(miEdit);
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
  if FCtrl^.UpdatesCount()>0 then
  begin
    if MessageDlg(rsWarning,rsUnsaved,mtWarning,
       [mbOK,mbCancel],0,mbCancel)<>mrOk then
    begin
      exit(false);
    end;
  end;

  ClearInfo();

  ClosePreviews(FCtrl);
  ClosePak(FCtrl);
  FCtrl:=nil;

  sgMain.Clear;
  tvTree.Items.Clear;
  FreeAndNil(fmi);

  result:=true;
end;

procedure TRGGUIForm.actFileCloseExecute(Sender: TObject);
begin
  if FileClose() then
  begin
    NewPAK();
    FillTree();
    SetupView();

    FCtrl^.OnChange:=@GUIOnChange;
  end;
end;

procedure TRGGUIForm.actFileExitExecute(Sender: TObject);
begin
//  if FileClose() then
  begin
//    actFileExit.Enabled:=false;
    Close;
  end;
end;

procedure TRGGUIForm.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Options    :=[ofFileMustExist];
    OpenDialog.DefaultExt :=LastExt;
    OpenDialog.Filter     :=RGDefReadFilter;
    OpenDialog.FilterIndex:=LastFilter;

    if OpenDialog.Execute then
    begin
      LastExt   :=OpenDialog.DefaultExt;
      LastFilter:=OpenDialog.FilterIndex;

      FileClose();

      FCtrl:=LoadPak(OpenDialog.FileName);
      FillTree();
      SetupView();

      FCtrl^.OnChange:=@GUIOnChange;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TRGGUIForm.actFileSaveExecute(Sender: TObject);
begin
  if FCtrl^.Save() then
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

function TRGGUIForm.SaveAs(asPatch:boolean):boolean;
var
  dlg:TSaveDialog;
  ls:AnsiString;
  lver:integer;
begin
  dlg:=TSaveDialog.Create(nil);
  try
    case FCtrl^.PAK.Version of
      verTL2: dlg.FilterIndex:=1;
      verHob: dlg.FilterIndex:=3;
      verRG : dlg.FilterIndex:=4;
      verRGO: dlg.FilterIndex:=5;
      verTL1: dlg.FilterIndex:=6;
    else
      dlg.FilterIndex:=1;
    end;
    if asPatch then
      dlg.Title:=rsSavePatch
    else
      dlg.Title:=rsSave;
    dlg.InitialDir:=FCtrl^.PAK.Directory;
    dlg.FileName  :=FCtrl^.PAK.Name;
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
      if asPatch then
      begin
        result:=FCtrl^.SavePatch(dlg.Filename,lver);
        ls:=rsSavedPatch;
      end
      else
      begin
        result:=FCtrl^.SaveAs(dlg.Filename,lver);
        ls:=rsSavedAs;
        if result then
        begin
          tvTreeSelectionChanged(self);
          SetupView();
        end;
      end;
      if result then
        ShowMessage(ls+' '+dlg.Filename)
      else
        ShowMessage(rsCantSave+' '+dlg.Filename);
    end;
  finally
    dlg.Free;
  end;
end;

procedure TRGGUIForm.actFileSaveAsExecute(Sender: TObject);
begin
  SaveAs(false);
end;

procedure TRGGUIForm.actFileSavePatchExecute(Sender: TObject);
begin
  SaveAs(true);
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
      SetPreviewFont(SrcFont);
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
  if cfgUnpackDir='' then
    loutdir:=ExtractFileDir(ParamStr(0))
  else
    loutdir:=cfgUnpackDir;
  if not (loutdir[Length(loutdir)] in ['\','/']) then loutdir:=loutdir+'\';
  if cfgUsePakName then loutdir:=loutdir+FCtrl^.PAK.Name+'\';

  OpenDocument(loutdir);
end;

procedure TRGGUIForm.actShowInfoExecute(Sender: TObject);
begin
  if fmi=nil then
  begin
    fmi:=TMODInfoForm.Create(Self,@(FCtrl^.PAK.modinfo),false);
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
  ls,lname:string;
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
      lname:=FileNames[i];
      if DirectoryExists(lname) then
      begin
        FCtrl^.ImportDir(ls,lname);
      end
      else if FileExists(lname) then
      begin
        pc:=StrToWide(lname);
        FCtrl^.AddFileData(pc, PUnicodeChar(UnicodeString(
            ls+
            FixFileExt(ExtractName(lname))
            )), true);
        FreeMem(pc);
      end;
    end;
    FillTree();
    exit;
  end;
end;

function TRGGUIForm.GUIOnChange(actrl:pointer; idx:integer; atype:integer):integer;
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
      ldir :=WideToStr(FCtrl^.PathOfFile(idx));
      lname:=WideToStr(FCtrl^.Files[idx]^.Name);
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
          PrepareFeatureTags(FCtrl);
        end;
    end;
  end;
end;

{%ENDREGION Form}

{%REGION Save}
procedure TRGGUIForm.actEdExportExecute(Sender: TObject);
var
  llidx,lidx,i,lcnt:integer;
begin
  lcnt:=0;

  for i:=1 to sgMain.RowCount-1 do
  begin
    if sgMain.IsCellSelected[colDir,i] then
    begin
      lidx:=IntPtr(sgMain.Objects[colName,i]);
      if SaveFile(FCtrl,lidx) then
      begin
        llidx:=lidx;
        inc(lcnt);
      end;
    end;
//    if (i mod 100)=0 then Application.ProcessMessages;
  end;

  if lcnt=1 then
  begin
    ShowMessage('File '+
       FastWideToStr(FCtrl^.PathOfFile(llidx))+
       FastWideToStr(FCtrl^.NameOfFile(llidx))+#13#10+rsUnpackSucc)
  end
  else if lcnt>1 then
    ShowMessage(IntToStr(lcnt)+rsFilesUnpackSucc);
end;

procedure TRGGUIForm.ExtractSingleDir(adir:integer);
var
  lfile:integer;
begin
  if FCtrl^.GetFirstFile(lfile,adir) then
    repeat
      SaveFile(FCtrl,lfile,cbTest.Checked);
    until not FCtrl^.GetNextFile(lfile);
//  Application.ProcessMessages;
end;

procedure TRGGUIForm.DoExtractGrid(Sender: TObject);
var
  i,lcnt:integer;
begin
  lcnt:=0;
  for i:=1 to sgMain.RowCount-1 do
  begin
    if SaveFile(FCtrl,IntPtr(sgMain.Objects[colName,i]),cbTest.Checked) then inc(lcnt);
//    if (i mod 100)=0 then Application.ProcessMessages;
  end;
  if lcnt>0 then ShowMessage(IntToStr(lcnt)+rsFilesUnpackSucc);
end;

procedure TRGGUIForm.DoExtractDir(Sender: TObject);
begin
  ExtractSingleDir(IntPtr(PopupNode.Data));
end;

procedure TRGGUIForm.DoExtractTree(Sender: TObject);
var
  ls,pc:PWideChar;
  i,idx,llen:integer;
  ldl:TRGDebugLevel;
begin
  ldl:=rgDebugLevel;

  idx:=IntPtr(PopupNode.Data);
  if idx>0 then
  begin
    ls:=FCtrl^.Dirs[idx].Name;
    llen:=Length(ls);
  end
  else
  begin
    ls:='';
    llen:=0;
  end;

  for i:=0 to FCtrl^.DirCount-1 do
  begin
    if not FCtrl^.IsDirDeleted(i) then
    begin
      pc:=FCtrl^.Dirs[i].name;
      if (idx=0) or (i=idx) or (CompareWide(ls,pc,llen)=0) then
      begin
        StatusBar.Panels[1].Text:=rsExtractDir+WideToStr(pc);
        StatusBar.Update;
        ExtractSingleDir(i);
      end;
    end;
  end;

  if (idx<0) and (cbMODDAT.Checked) and (FCtrl^.PAK.Version=verTL2Mod) then
  begin
    SaveModConfig(FCtrl^.PAK.modinfo,PChar(deOutDir.Text+'\'+'MOD.DAT'));
  end;
  StatusBar.Panels[1].Text:=rsFilePath+sgMain.Cells[colDir ,sgMain.Row];
  ShowMessage(GetPathFromNode(PopupNode)+#13#10+rsUnpackSucc);

  rgDebugLevel:=ldl;
end;

{%ENDREGION Save}

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
          ((sgMain.RowCount=2) and (tvTree.Selected<>nil) and (IntPtr(UIntPtr(tvTree.Selected.Data))>0)));
//            (IntPtr(UIntPtr(sgMain.Objects[colName,1]))=-1);
  bParent:=(not bNoTree) and
          ((sgMain.Row     =1) and (tvTree.Selected<>nil) and (IntPtr(UIntPtr(tvTree.Selected.Data))>0));

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
//  lrec:TRGFullInfo;
  ldir:string;
  lfile:integer;
begin
  lfile:=IntPtr(sgMain.Objects[colName,aRow]);
  SetActiveFile(lfile,FCtrl,0);

  ClearInfo();

  if cbPreview.Checked and actShowPreview.Checked then
  begin
    if (aCol<1) or (aRow<1) or
  //    ((aRow=1) and (sgMain.Cells[colName,aRow]=strParentDir)) then
      ((aRow=1) and (IntPtr(UIntPtr(tvTree.Selected.Data))>1)) then
    begin
      Exit;
    end;

    ldir:=sgMain.Cells[colDir,aRow];

    if lfile>=0 then
    begin
      fmPreview:=MakePreview(FCtrl^,lfile);
      if fmPreview<>nil then
      begin
        fmPreview.BorderStyle:=bsNone;
        fmPreview.Align      :=alClient;
        fmPreview.Parent     :=pnlAdd;
        fmPreview.Visible    :=true;
      end;
    end;
    StatusBar.Panels[1].Text:=rsFilePath+ldir;
  end;
end;

procedure TRGGUIForm.actPreviewExecute(Sender: TObject);
var
  lform:TForm;
//  ldir:AnsiString;
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
//    ldir :=sgMain.Cells[colDir,sgMain.Row];

    if lfile>=0 then
    begin
      lform:=MakePreview(FCtrl^,lfile);
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
        FCtrl^.MarkToRemove(lidx);
        if PRGCtrlInfo(FCtrl^.Files[lidx])^.ftype=typeDirectory then
        begin
          MarkTree(FCtrl^.AsDir(lidx),false);
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
  lf.Version:=FCtrl^.PAK.Version;
  if lf.ShowModal=mrOK then
  begin
    idx:=lf.Version;
    if FCtrl^.PAK.Version<>idx then
    begin
      FCtrl^.PAK.Version:=idx;
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
      state:=FCtrl^.GetUpdateState(lfile);
      if FCtrl^.IsDir(lfile) then
      begin
        ldir:=FCtrl^.AsDir(lfile);
        if state=stateDelete then
        begin
          MarkTree(ldir,true);
        end;
      end
      else
        ldir:=-1;
      lfile:=FCtrl^.RemoveUpdate(lfile);
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
        FCtrl^.AddFileData(pc, PUnicodeChar(UnicodeString(
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
  ls:AnsiString;
  f:file of byte;
  lold,lnew:PByte;
  loldsize,lnewsize:integer;
  istext:boolean;
begin
  lnew:=nil;
  lold:=nil;

//  istext:=(RGTypeOfExt(FCtrl^.Files[idx]^.Name) and $FF)=typeData;
  istext:=(FCtrl^.Files[idx]^.ftype and $FF)=typeData;

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
  loldsize:=FCtrl^.GetSource(idx,lold);
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
    ls:=FastWideToStr(PUnicodeChar(newdata))
  else
    ls:=FastWideToStr(FCtrl^.PathOfFile(idx))+FastWideToStr(FCtrl^.NameOfFile(idx));
  with tAskForm.Create(ls, loldsize, lnewsize) do
  begin
    ShowModal();
    result:=TRGDoubleAction(MyResult);
    Free;
  end;
  
  case result of
    da_renameold: begin
      newdata:=PByte(StrToWide(
          InputBox('Rename existing file', 'Enter new name', FCtrl^.NameOfFile(idx)) ));
    end;

    da_saveas: begin
      newdata:=PByte(StrToWide(
          InputBox('Rename new file', 'Enter new name', FCtrl^.NameOfFile(idx)) ));
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

    FCtrl^.OnDouble:=@OnImportDouble;
    lcnt:=FCtrl^.ImportDir(GetPathFromNode(tvTree.Selected),ldir);
    FCtrl^.OnDouble:=nil;
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

    lcnt:=FCtrl^.FileCount;
    {lfile:=}FCtrl^.UseData(nil,0,PUnicodeChar(UnicodeString(lpath+lname)));
    // condition just to avoid flicks in root tree list
    if FCtrl^.FileCount<>lcnt then
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
  FCtrl^.Rename(lidx,PUnicodeChar(UnicodeString(lname)));
  if isdir then
  begin
    lidx:=FCtrl^.AsDir(lidx);
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
  if (FCtrl^.FileCount>0) {edGridFilter.Enabled} {and Length(edGridFilter.Text>3)} then
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
      if FCtrl^.GetUpdateState(lidx)<>stateDelete then
      begin
        lidx:=FCtrl^.AsDir(lidx);
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
         WideToStr(FCtrl^.PathOfFile(i))+
         WideToStr(FCtrl^.NameOfFile(i))
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

//  if afile^.size=0 then exit;

  lname:=WideToStr(FCtrl^.NameOfFile(afile));
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
  
  FCtrl^.GetFullInfo(afile,lrec);

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
    sgMain.Cells[colSource,arow]:=IntToStr(lrec.size);
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

  if idx>=FCtrl^.DirCount then exit;

  SetActiveDir(idx,FCtrl,0);

  inProcess:=true;

  FLastIndex:=idx;
  sgMain.Clear;
  sgMain.BeginUpdate;
  lcnt:=1;
  lbase:=0;

  if idx<=0 then
  begin
    StatusBar.Panels[1].Text:=rsBuildGrid;
    Self.Caption:='RGGUI - '+AnsiString(FCtrl^.PAK.Name)+rsBuildGrid;

    sgMain.RowCount:=FCtrl^.total+1; // ctrl.FileCount
    for i:=0 to FCtrl^.DirCount-1 do
    begin
      if not FCtrl^.IsDirDeleted(i) then
      begin

        if FCtrl^.GetFirstFile(lfile,i) then
        begin
          lname:=FCtrl^.Dirs[i].Name;
          repeat
            if FillGridLine(lcnt, lname, lfile) then
              inc(lcnt);
          until not FCtrl^.GetNextFile(lfile);
        end;

//        if (lcnt mod 1000)=0 then Application.ProcessMessages;
      end;
    end;
    Self.Caption:='RGGUI - ('+GetGameName(FCtrl^.PAK.Version)+') '+AnsiString(FCtrl^.PAK.Name);
  end
  else
  begin
{    if idx=1 then
      sgMain.RowCount:=ctrl.Dirs[idx].count+1
    else
}    begin
      sgMain.RowCount:=FCtrl^.Dirs[idx].count+2;
      sgMain.Cells  [colName,lcnt]:=strParentDir;
      sgMain.Objects[colName,lcnt]:=TObject(-1);
      inc(lcnt);
    end;
    lbase:=lcnt;

    if FCtrl^.GetFirstFile(lfile,idx) then
    begin
      lname:=FCtrl^.Dirs[idx].Name;
      repeat
        if FillGridLine(lcnt, lname, lfile) then
          inc(lcnt);
      until not FCtrl^.GetNextFile(lfile);
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

  ldir:=FCtrl^.NewDir(PUnicodeChar(UnicodeString(ls)));
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
  FCtrl^.MarkToRemove(FCtrl^.AsFile(ldir));
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
  FCtrl^.RemoveUpdate(FCtrl^.AsFile(ldir));
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
	  result:=FCtrl^.Dirs[ldir].Name;
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
  lnode:TTreeNode;
  i:integer;
begin
  for i:=0 to tvTree.Items.Count-1 do
  begin
    lnode:=tvTree.Items[i];
    if IntPtr(UIntPtr(lnode.Data))=adir then
    begin
      lnode.Enabled:=aEnable;
      if aEnable then
        tvTree.Select(lnode)
      else
        lnode.Collapse(true);
      exit;
    end;
  end;
end;

procedure TRGGUIForm.AddBranch(aroot:TTreeNode; const aname:string);
var
  lnode:TTreeNode;
  ls:string;
  i,ldir:integer;
begin
  ldir:=FCtrl^.SearchPath(aname);
  aroot.Data:=pointer(IntPtr(ldir));
  if FCtrl^.GetFirstFile(i,ldir) then
    repeat
      if FCtrl^.IsDir(i) then
      begin
        ls:=WideToStr(FCtrl^.NameOfFile(i));
        lnode:=tvTree.Items.AddChild(aroot,ls);
        AddBranch(lnode,aname+ls);
        if PRGCtrlInfo(FCtrl^.Files[i])^.action=act_delete then
          lnode.Enabled:=false;
      end;
    until not FCtrl^.GetNextFile(i);
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
