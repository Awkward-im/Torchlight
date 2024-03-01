{TODO: save as for editor}
{TODO: grid context menu: delete file (dir), undelete (delete update?), add file (dir), rename (name+data??)}
{TODO: Audio player as preview if bass.dll found}
{TODO: disable edSave and actEdUndo when no SynEdit, modified, actEdReset check for files/dir}
{TODO: Show files/dir on MEDIA level (yes, it possible)}
{TODO: change filter from checklistboxes to tree??}
{TODO: memory settings: max size to load PAK into memory}
{TODO: Add HASH calcualtor}
{TODO: Add file search}
{TODO: Add grid filter}
{TODO: Implement to open DIR (not PAK/MOD/MAN)}
{TODO: AutoSort on tree item change}
{TODO: Status bar path changes on dir with files only}
{TODO: option: keep PAK open}
{TODO: option: ask unpack path}
{TODO: Save: full repack or fast}
{TODO: Tree changes: check update list}
{TODO: replace bitbutton by speed button (scale problem)}
{TODO: change grid/preview border moving}
unit formGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids, Menus,
  ActnList, ExtCtrls, StdCtrls, EditBtn, Buttons, TreeFilterEdit,
  SynEdit, SynHighlighterXML, SynHighlighterT, SynEditTypes, SynPopupMenu,
  rgglobal, rgpak, rgctrl;

type

  { TRGGUIForm }

  TRGGUIForm = class(TForm)
    actResetView: TAction;
    bbCollapse: TBitBtn;
    cbUnpackTree: TCheckBox;
    cbMODDAT: TCheckBox;
    cbSaveSettings: TCheckBox;
    cbSaveWidth: TCheckBox;
    cbFastScan: TCheckBox;
    cbTest: TCheckBox;
    cbUseFName: TCheckBox;
    deOutDir: TDirectoryEdit;
    edTreeFilter: TTreeFilterEdit;
    imgPreview: TImage;
    ilBookmarks: TImageList;
    ilMain: TImageList;
    lblOutDir: TLabel;
    PageControl: TPageControl;
    pnlTreeFilter: TPanel;

    pnlInfo: TPanel;
    lblSize  : TLabel;  lblSizeVal: TLabel;
    lblTime  : TLabel;  lblTimeVal: TLabel;
    lblOffset: TLabel;  lblOffsetVal: TLabel;

    pnlAdd: TPanel;
    pnlTree: TPanel;

    gbDecoding: TGroupBox;
    rbGUTSStyle : TRadioButton;
    rbTextRename: TRadioButton;
    rbBinOnly   : TRadioButton;
    rbTextOnly  : TRadioButton;
    cbSaveUTF8  : TCheckBox;

    ReplaceDialog: TReplaceDialog;
    sgMain: TStringGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar: TStatusBar;
    Setings: TTabSheet;
    Grid: TTabSheet;
    SynPopupMenu: TSynPopupMenu;
    SynTSyn: TSynTSyn;
    SynEdit: TSynEdit;
    SynXMLSyn: TSynXMLSyn;

    ToolBar: TToolBar;
    tbOpen    : TToolButton;
    tbSaveAs  : TToolButton;
    tbSep1    : TToolButton;
    tbInfo    : TToolButton;
    tbShowLog : TToolButton;

    mnuTree: TPopupMenu;
    miExtractTree   : TMenuItem;
    miExtractDir    : TMenuItem;
    miExtractVisible: TMenuItem;

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
    actEdReset    : TAction; // Reset content to container
    actEdUndo     : TAction; // Reset content to last
    actEdSave     : TAction; // Save for update
    actEdImport   : TAction; // Load (import) content
    actEdExport   : TAction; // Export content
    actEdSearch   : TAction; // Seacrh/replace

    actShowFilter: TAction;

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
    tbResetView: TToolButton;
    tbSave: TToolButton;

    tvTree: TTreeView;

    procedure actEdExportExecute(Sender: TObject);
    procedure actEdImportExecute(Sender: TObject);
    procedure actEdResetExecute(Sender: TObject);
    procedure actEdSaveExecute(Sender: TObject);
    procedure actEdSearchExecute(Sender: TObject);
    procedure actEdUndoExecute(Sender: TObject);
    procedure actFileCloseExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileSaveAsExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure actShowInfoExecute(Sender: TObject);
    procedure actShowFilterExecute(Sender: TObject);
    procedure actShowLogExecute(Sender: TObject);
    procedure bbCollapseClick(Sender: TObject);
    procedure actScaleImageExecute(Sender: TObject);
    procedure actPreviewExecute(Sender: TObject);
    procedure ReplaceExecute(Sender: TObject);
    procedure actResetViewExecute(Sender: TObject);
    procedure SetupView(Sender: TObject);
    procedure DoExtractDir(Sender: TObject);
    procedure DoExtractGrid(Sender: TObject);
    procedure DoExtractTree(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sgMainCompareCells(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
    procedure sgMainDblClick(Sender: TObject);
    procedure sgMainGetCellHint(Sender: TObject; ACol, ARow: Integer; var HintText: String);
    procedure sgMainHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure sgMainKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgMainSelection(Sender: TObject; aCol, aRow: Integer);
    procedure SynEditStatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure tbColumnClick(Sender: TObject);
    procedure tvTreeSelectionChanged(Sender: TObject);
  private
    FUData:pointer;
    fmi:TForm;
    ctrl:TRGController;
    LastExt:string;
    LastFilter:integer;
    FLastIndex:integer;
    FUSize:integer;
    inProcess:boolean;
    bShowDir     : Boolean;
    bShowExt     : Boolean;
    bShowCategory: Boolean;
    bShowTime    : Boolean;
    bShowPacked  : Boolean;
    bShowUnpacked: Boolean;
    bShowSource  : Boolean;


    procedure ClearInfo();
    procedure FillGrid(idx:integer=-1);
    function  FillGridLine(arow: integer; const adir: string; afile: integer): boolean;
    procedure FillTree();
    procedure AddBranch(aroot: TTreeNode; const aname: string);
    function  GetPathFromNode(aNode: TTreeNode): string;
    procedure OpenPAK(const aname: string);
    function  SaveFile(const adir, aname: string; adata: PByte; asize:integer): boolean;
    procedure PreviewImage(const aext: string);
    procedure PreviewSource;
    procedure PreviewText();
    procedure LoadSettings;
    procedure SaveSettings;
    function  UnpackSingleFile(const adir, aname: string; var buf:PByte): boolean;
    procedure ExtractSingleDir(adir: integer; var buf:PByte);

  public

  end;

var
  RGGUIForm: TRGGUIForm;

implementation

{$R *.lfm}
{$R ..\TL2Lib\dict.rc}

uses
  LCLType,
  IntfGraphics,
  inifiles,
  fpimage,
  fpwritebmp,
  lazTGA,
  berodds,

  unitLogForm,
  unitFilterForm,
  fmmodinfo,

  rgfiletype,
  rgfile,
  TL2Mod,
  rgdict,
  rgdictlayout,
  rgstream;

{%REGION Constants}

const
  strParentDir = '. . /';
const
  lblNew     = '+';
  lblChanged = '*';
  lblDelete  = 'X';
  lblRemove  = 'R';

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
  defTreeWidth = 256;
  defGridWidth = 360;

resourcestring
  rsWarning         = 'Warning!';
  rsUnsaved         = 'You have unsaved changes. Exit anyway?';
  rsBuildTree       = ' Build tree';
  rsBuildGrid       = ' Build file list. Please, wait...';
  rsBuildPreview    = ' Build preview';
  rsUnpackSucc      = 'unpacked succesfully.';
  rsFilesUnpackSucc = ' files unpacked succesfully.';
  rsExtractDir      = 'Extract directory ';
  rsFilePath        = 'File path: ';
  rsTotal           = 'Total: ';
  rsDirs            = '; dirs: ';
  rsSaved           = 'File saved';
  rsSavedAs         = 'File saved as';
  rsCantSave        = 'Can''t save file';

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

procedure TRGGUIForm.SetupView(Sender: TObject);
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
  SetupView(Sender);
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
      config.WriteInteger(sSectSettings,sGridWidth,sgMain .Width);
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

  actShowPreview.Checked:=config.ReadBool(sSectSettings,sShowPreview,false);
  actScaleImage .Checked:=config.ReadBool(sSectSettings,sScaleImage ,false);

  rgDebugLevel:=TRGDebugLevel(config.ReadInteger(sSectSettings,sDebugLevel,1));

  cbSaveWidth.Checked:=config.ReadBool(sSectSettings,sSaveWidth,true);

  if cbSaveWidth.Checked then
  begin
    pnlTree.Width:=config.ReadInteger(sSectSettings,sTreeWidth,defTreeWidth);
    sgMain .Width:=config.ReadInteger(sSectSettings,sGridWidth,defGridWidth);
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

procedure TRGGUIForm.FormCreate(Sender: TObject);
begin
  FLastIndex:=-1;
  FUData    :=nil;

//  ctrl.Init;

  fmLogForm:=nil;
  fmFilterForm:=TFilterForm.Create(Self);

  SynTSyn:=TSynTSyn.Create(Self);

  LoadSettings();
  SetupView(Self);
  ClearInfo();

  RGTags.Import('RGDICT','TEXT');

  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  if ParamCount>0 then
    OpenPAK(ParamStr(1));

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

//  ctrl.Free;
  SaveSettings();
end;

procedure TRGGUIForm.actFileCloseExecute(Sender: TObject);
begin
  if ctrl.UpdatesCount()>0 then
  begin
    if MessageDlg(rsWarning,rsUnsaved,mtWarning,
       [mbOK,mbCancel],0,mbCancel)<>mrOk then
    begin
      exit;
    end;
  end;

  ctrl.Free;

  actScaleImage.Visible:=false;
  sgMain.Clear;
  ClearInfo();
  tvTree.Items.Clear;
  actShowInfo.Enabled:=false;
  FreeAndNil(fmi);

  actShowInfo  .Enabled:=false;
  actFileClose .Enabled:=false;
  actFileSave  .Enabled:=false;
  actFileSaveAs.Enabled:=false;
end;

procedure TRGGUIForm.actFileExitExecute(Sender: TObject);
begin
  if actFileClose.Enabled then actFileCloseExecute(Sender);
  if actFileClose.Enabled then exit;

  actFileExit.Enabled:=false;
  Close;
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

  if ctrl.PAK.GetInfo(aname,lmode) then
  begin
    ctrl.Rebuild();

//    no reason to set coz will overwrite by FillGrid anyway
//    Self.Caption:='RGGUI - '+AnsiString(ctrl.PAK.Name);
    StatusBar.Panels[0].Text:=rsTotal+IntToStr(ctrl.total)+rsDirs+IntToStr(ctrl.DirCount);

    SetupView(Self);

    FreeAndNil(fmi);
    actShowInfo  .Enabled:=true;
    actFileClose .Enabled:=true;
    actFileSave  .Enabled:=true;
    actFileSaveAs.Enabled:=true;
  end;

  FillTree();
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

      if actFileClose.Enabled then actFileCloseExecute(Sender);

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
begin
  dlg:=TSaveDialog.Create(nil);
  try
    case FPAK.Version of
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
      if ctrl.SaveAs(dlg.Filename,lver) then
        ShowMessage(rsSavedAs+' '+dlg.Filename)
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
        lext:='.BINDAT';
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
      ldir :=sgMain.Cells[colDir ,i];
      lname:=sgMain.Cells[colName,i]+sgMain.Cells[colExt,i];
//      lsize:=ctrl.GetBinary(ctrl.SearchFile(ldir+lname),lptr);
      lsize:=ctrl.GetBinary(IntPtr(sgMain.Objects[colName,i]),lptr);
      if lsize>0 then
      begin
        if SaveFile(ldir, lname, lptr, lsize) then
          inc(lcnt);
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
  i:integer;
begin
  ldata:=nil;
  for i:=1 to sgMain.RowCount-1 do
  begin
    UnpackSingleFile(
        sgMain.Cells[colDir ,i],
        sgMain.Cells[colName,i]+
        sgMain.Cells[colExt ,i],ldata);
//    if (i mod 100)=0 then Application.ProcessMessages;
  end;
  FreeMem(ldata);
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
  ExtractSingleDir(IntPtr(tvTree.Selected.Data),ldata);
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

  idx:=IntPtr(tvTree.Selected.Data);
  if idx>0 then
  begin
    ls:=ctrl.Dirs[idx].Name;
    llen:=Length(ls);
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
    SaveModConfiguration(ctrl.PAK.modinfo,PChar(deOutDir.Text+'\'+'MOD.DAT'));
  end;
  StatusBar.Panels[1].Text:=rsFilePath+sgMain.Cells[colDir ,sgMain.Row];

  rgDebugLevel:=ldl;
end;

{%ENDREGION}

{%REGION Preview}

procedure TRGGUIForm.ClearInfo();
var
  b:boolean;
begin
  lblSizeVal  .Caption:='';
  lblOffsetVal.Caption:='';
  lblTimeVal  .Caption:='';

  SynEdit.Clear;
  SynEdit.Visible:=false;

  imgPreview.Picture.Clear;
  imgPreview.Visible:=false;
  actScaleImage.Visible:=false;

  actEdSearch.Enabled:=false;

  FreeMem(FUData); FUData:=nil;

  if tvTree.Selected=nil then
    b:=false
  else if (IntPtr(UIntPtr(tvTree.Selected.Data))>1) then
    b:=(sgMain.Row>1)
  else
    b:=(sgMain.Row>0);

  actEdReset .Enabled:=b;
  actEdUndo  .Enabled:=b;
  actEdSave  .Enabled:=b;
  actEdExport.Enabled:=b;
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

procedure TRGGUIForm.PreviewSource();
var
  pc:PWideChar;
begin
//!!    pnlEditButtons.Visible:=true;

  pc:=PWideChar(FUData);
  if ORD(pc^)=SIGN_UNICODE then inc(pc);

  SynEdit.Highlighter:=SynTSyn;
  SynEdit.Text:=WideToStr(pc);
  SynEdit.Visible:=true;
  actEdSearch.Enabled:=true;
end;

procedure TRGGUIForm.PreviewText();
var
  ltext:string;
begin
  SetString(ltext,PChar(FUData),FUSize);

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
    RGLog.Reserve('Processing '+ldir+lname);

    ctrl.GetFullInfo(lfile,lrec);

    lblSizeVal  .Caption:=IntToStr(lrec.size_u);
    lblOffsetVal.Caption:='0x'+HexStr(lrec.offset,8);
    try
      lblTimeVal.Caption:=DateTimeToStr(FileTimeToDateTime(lrec.ftime));
    except
      lblTimeVal.Caption:='0x'+HexStr(lrec.ftime,16);
    end;

    ltype:=PAKExtType(lext);
    if ltype in (setBinary+[typeDelete,typeDirectory]) then exit;

     if not actShowPreview.Checked then exit;

    FUSize:=ctrl.GetSource(lfile,FUData);
    FillGridLine(sgMain.Row,ldir,lfile);
    if FUSize>0 then
    begin
      if ltype=typeImageset then
      begin
        if ABS(ctrl.PAK.Version)=verTL2 then
          lspec:=1
        else
          lspec:=2;
      end
      else
        lspec:=0;
//!!      pnlEditButtons.Visible:=false;
      // Text
      if (ltype in setText) and (lspec in [0,1]) then PreviewText()

      // DAT, RAW, ANIMATION, TEMPLATE, LAYOUT
      else if (ltype in setData) and (lspec in [0,2]) then PreviewSource()

      // Image
      else if ltype in setImage then PreviewImage(lext)

      // Sound
      else if ltype=typeSound then
      begin
      end
      else
      ;

    end;

  end;
  StatusBar.Panels[1].Text:=rsFilePath+ldir;
end;

procedure TRGGUIForm.SynEditStatusChange(Sender: TObject; Changes: TSynStatusChanges);
begin
  if scModified in Changes then Grid.Caption:='[*] Grid';
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

procedure TRGGUIForm.actEdUndoExecute(Sender: TObject);
begin
  sgMainSelection(sgMain, colName, sgMain.Row);
end;

procedure TRGGUIForm.actEdResetExecute(Sender: TObject);
var
  state,lfile:integer;
begin
  {TODO: Ask about changes (if any)}
  {TODO: Delete updates}
{
  lfile:=ctrl.SearchFile(
      sgMain.Cells[colDir ,sgMain.Row]+
      sgMain.Cells[colName,sgMain.Row]+
      sgMain.Cells[colExt ,sgMain.Row]);
}
  lfile:=IntPtr(sgMain.Objects[colName,sgMain.Row]);
  state:=ctrl.UpdateState(lfile);
  ctrl.RemoveUpdate(lfile);
  if state=stateNew then
  begin
    FillGrid(IntPtr(tvTree.Selected.Data));
  end
  else
  begin
    FillGridLine(sgMain.Row,sgMain.Cells[colDir ,sgMain.Row],lfile);
    sgMainSelection(sgMain, colName, sgMain.Row);
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
begin
  {TODO Ask for overwrite, name. Mark FILE as modified}
//!!  SynEdit.Lines.LoadFromFile(,TEncoding.Unicode);
end;

{%ENDREGION Preview}

{%REGION Grid}

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

procedure TRGGUIForm.sgMainCompareCells(Sender: TObject; ACol, ARow, BCol,
  BRow: Integer; var Result: integer);
var
  s1,s2:string;
  dt1,dt2:TDateTime;
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

  if (Sender as TStringGrid).SortOrder=soDescending then
    result:=-result;
end;

procedure TRGGUIForm.sgMainDblClick(Sender: TObject);
var
  lname:string;
  lparent:TTreeNode;
  ldir:integer;
  i:integer;
begin
  lname:=sgMain.Cells  [colName,sgMain.Row];
  if lname[Length(lname)]='/' then
  begin
    if lname=strParentDir then
    begin
      tvTree.Selected:=tvTree.Selected.Parent;
    end
    else
    begin
      ldir:=ctrl.FileDir(IntPtr(UIntPtr(sgMain.Objects[colName,sgMain.Row])));
      if tvTree.Selected=tvTree.TopItem then
      begin
        lparent:=nil;
        for i:=0 to tvTree.Items.Count-1 do
          if IntPtr(UIntPtr(tvTree.Items[i].Data))=ldir then
          begin
            lparent:=tvTree.Items[i];
            break;
          end;
      end
      else
        lparent:=tvTree.Selected;

      if lparent<>nil then
        for i:=0 to lparent.Count-1 do
          if lparent.Items[i].Text=lname then
          begin
            tvTree.Selected:=lparent.Items[i];
            break;
          end;
    end;
  end;
end;

procedure TRGGUIForm.sgMainGetCellHint(Sender: TObject; ACol, ARow: Integer; var HintText: String);
var
  i:integer;
begin
  if (ACol=colName) and (ARow>0) and (ARow<=sgMain.RowCount) and
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

function TRGGUIForm.FillGridLine(arow:integer; const adir:string; afile:integer):boolean;
var
  lrec:TRGFullInfo;
  lname,lext:string;
  i:integer;
  c:Char;
begin
  result:=false;

  //--- Filter

//  if afile^.size_s=0 then exit;

  lname:=WideToStr(ctrl.Files[afile]^.Name);
  lext :=ExtractFileExt(lname);
{
  if edGridFilter.Text<>'' then
    if Pos(edGridFilter.Text,lname)=0 then exit;
}

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
      sgMain.Cells[colType  ,arow]:=PAKCategoryName(PAKTypeToCategory(lrec.ftype));
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
    stateNew    : c:=lblNew;
    stateChanged: c:=lblChanged;
    stateDelete : c:=lblDelete;
    stateRemove : c:=lblRemove;
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
  lfile,lcnt:integer;
begin
  if inProcess then exit;

  if idx>=ctrl.DirCount then exit;

  inProcess:=true;

  FLastIndex:=idx;
  sgMain.Clear;
  sgMain.BeginUpdate;
  lcnt:=1;

  if idx<0 then
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
    if idx=1 then
      sgMain.RowCount:=ctrl.Dirs[idx].count+1
    else
    begin
      sgMain.RowCount:=ctrl.Dirs[idx].count+2;
      sgMain.Cells  [colName,lcnt]:=strParentDir;
      sgMain.Objects[colName,lcnt]:=TObject(-1);
      inc(lcnt);
    end;

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
  actEdExport.Visible:=(lcnt-idx)>0;

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
begin
  result:=ctrl.Dirs[IntPtr(UIntPtr(aNode.Data))].Name;
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
    tvTree.Items[1].Selected:=true;
end;

{%ENDREGION Tree}

initialization
  LazTGA.Register;

finalization
  LazTGA.UnRegister;
end.
