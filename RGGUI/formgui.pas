{TODO: option: keep PAK open}
{TODO: option: ask unpack path}
{TODO: Save: full repack or fast}
{TODO: Redraw grid line after unpack if cbFastScan.Checked}
{TODO: save changed file at update list: packed data, size, path (replace on updates)}
{TODO: Tree changes: check update list first, man next}
{TODO: make button for non-scale image preview}
{TODO: make button for "show all categories", double icon set/clear}
{TODO: edit DAT-type files on the place. "Save" button on info panel}
{TODO: replace bitbutton by speed button (scale problem)}
unit formGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids, Menus,
  ActnList, ExtCtrls, ComboEx, StdCtrls, EditBtn, Buttons, StdActns,
  TreeFilterEdit, SynEdit, SynHighlighterXML, SynHighlighterT, SynEditTypes,
  rgglobal, rgman, rgpak;

type

  { TRGGUIForm }

  TRGGUIForm = class(TForm)
    bbExtSelect: TBitBtn;
    bbCatInverse: TBitBtn;
    bbSave: TBitBtn;
    bbCollapse: TBitBtn;
    bbResetColumns: TBitBtn;
    btnMODDAT: TButton;
    cbShowPreview: TCheckBox;
    cbUnpackTree: TCheckBox;
    cbMODDAT: TCheckBox;
    cbSaveSettings: TCheckBox;
    cbExt: TCheckBox;
    cbCategory: TCheckBox;
    cbTime: TCheckBox;
    cbPacked: TCheckBox;
    cbUnpacked: TCheckBox;
    cbSource: TCheckBox;
    cbSaveWidth: TCheckBox;
    cbFastScan: TCheckBox;
    deOutDir: TDirectoryEdit;
    edTreeFilter: TTreeFilterEdit;
    gbDecoding: TGroupBox;
    gbColumns: TGroupBox;
    imgPreview: TImage;
    ImageList: TImageList;
    lblPackVal: TLabel;
    lblUnpackVal: TLabel;
    lblTimeVal: TLabel;
    lblOffsetVal: TLabel;
    lblSrcVal: TLabel;
    lblPacked: TLabel;
    lblUnpacked: TLabel;
    lblTime: TLabel;
    lblOffset: TLabel;
    lblSource: TLabel;
    lblOutDir: TLabel;
    miHelpShowLog: TMenuItem;
    miExtractTree   : TMenuItem;
    miExtractDir    : TMenuItem;
    miExtractVisible: TMenuItem;
    PageControl: TPageControl;
    pnlEditButtons: TPanel;
    pnlTreeFilter: TPanel;
    pnlInfo: TPanel;
    pnlAdd: TPanel;

    pnlFilter: TPanel;
    ccbCategory : TCheckComboBox;    lblCategory : TLabel;
    ccbExtension: TCheckComboBox;    lblExtension: TLabel;

    pnlTree: TPanel;
    mnuTree: TPopupMenu;
    rbGUTSStyle: TRadioButton;
    rbTextRename: TRadioButton;
    rbBinOnly: TRadioButton;
    rbTextOnly: TRadioButton;
    ReplaceDialog: TReplaceDialog;
    sgMain: TStringGrid;
    sbEdReset: TSpeedButton;
    sbEdUndo: TSpeedButton;
    sbEdSave: TSpeedButton;
    sbEdImport: TSpeedButton;
    sbEdExport: TSpeedButton;
    sbEdSearch: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar: TStatusBar;
    Setings: TTabSheet;
    Grid: TTabSheet;
    SynTSyn: TSynTSyn;
    SynEdit: TSynEdit;
    SynXMLSyn: TSynXMLSyn;

    ToolBar: TToolBar;
    tbOpen    : TToolButton;
    tbSaveAs  : TToolButton;
    tbSep1    : TToolButton;
    tbExt     : TToolButton;
    tbCategory: TToolButton;
    tbTime    : TToolButton;
    tbPacked  : TToolButton;
    tbUnpacked: TToolButton;
    tbSource  : TToolButton;
    tbSep2    : TToolButton;
    tbInfo    : TToolButton;
    tbSep3    : TToolButton;
    tbShowLog : TToolButton;

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

    ActionList: TActionList;
    actFileOpen   : TAction;
    actFileSave   : TAction;
    actFileSaveAs : TAction;
    actFileClose  : TAction;
    actFileExit   : TAction;
    actEditExtract: TAction;
    actEditDelete : TAction;
    actEditSearch : TAction;
    actEditReplace: TAction;
    actHelpAbout  : TAction;
    actInfoInfo   : TAction;
    actShowLog    : TAction;

    actEdReset    : TAction; // Reset content to container
    actEdUndo     : TAction; // Reset content to last
    actEdSave     : TAction; // Save for update
    actEdImport   : TAction; // Load (import) content
    actEdExport   : TAction; // Export content
    actEdSearch   : TAction; // Seacrh/replace

    tvTree: TTreeView;

    procedure actEdSearchExecute(Sender: TObject);
    procedure actFileCloseExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actInfoInfoExecute(Sender: TObject);
    procedure actShowLogExecute(Sender: TObject);
    procedure bbCollapseClick(Sender: TObject);
    procedure bbExtSelectClick(Sender: TObject);
    procedure bbCatInverseClick(Sender: TObject);
    procedure cbShowPreviewChange(Sender: TObject);
    procedure ReplaceExecute(Sender: TObject);
    procedure ResetView(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
    procedure SetupView(Sender: TObject);
    procedure ccbFilterCloseUp(Sender: TObject);
    procedure ccbFilterItemChange(Sender: TObject; AIndex: Integer);
    procedure DoExtractDir(Sender: TObject);
    procedure DoExtractGrid(Sender: TObject);
    procedure DoExtractTree(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sgMainCompareCells(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
    function  SaveFile(const adir, aname: string; adata: PByte; asize:integer): boolean;
    procedure sgMainHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure sgMainSelection(Sender: TObject; aCol, aRow: Integer);
    procedure tbColumnClick(Sender: TObject);
    procedure tvTreeSelectionChanged(Sender: TObject);
  private
    FUData:pointer;
    fmi:TForm;
    rgpi:TRGPAK;
    LastExt:string;
    LastFilter:integer;
    FLastIndex:integer;
    FUSize:integer;
    inProcess:boolean;
    fFilterWasChanged:Boolean;

    procedure AddBranch(aroot: TTreeNode; const aname: string; acode: integer);
    procedure ClearInfo();
    procedure ExtractSingleDir(adir: integer);
    procedure FillCatList();
    procedure FillExtList();
    procedure FillGrid(idx:integer=-1);
    function  FillGridLine(arow: integer; const adir: string; afile: PMANFileInfo): boolean;
    procedure FillTree();
    function  GetPathFromNode(aNode: TTreeNode): string;
    procedure LoadSettings;
    procedure OpenFile(const aname: string);
    procedure PreviewImage(const aname: string);
    procedure PreviewSource(atype: byte; const adir, aname: string);
    procedure PreviewText();
    procedure SaveSettings;
    function  UnpackSingleFile(const adir, aname: string): boolean;

  public

  end;

var
  RGGUIForm: TRGGUIForm;

implementation

{$R *.lfm}
{$R ..\TL2Lib\dict.rc}

uses
  IntfGraphics,
  inifiles,
  fpimage,
  fpwritebmp,
  berodds,

  unitLogForm,
  fmmodinfo,

  rgfiletype,
  rgio.text,
  rgio.dat,
  rgio.raw,
  rgio.layout,
  TL2Mod,
  rgdict,
  rgdictlayout,
  rgnode,
  rgstream;

{%REGION Constants}
const
  cSep = '/';

const
  colCount  = 0;
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
  sFastScan     = 'fastscan';
  sDecoding     = 'decoding';
  sMODDAT       = 'moddat';
  sExt          = 'ext';
  sFilter       = 'filter';
  sSaveSettings = 'savesettings';
  sShowExt      = 'showext';
  sShowCategory = 'showcategory';
  sShowTime     = 'showtime';
  sShoPacked    = 'shopacked';
  sShowUnpacked = 'showunpacked';
  sShowSource   = 'showsource';
  sShowPreview  = 'showpreview';
  sSaveWidth    = 'savewidth';
  sTreeWidth    = 'width_tree';
  sGridWidth    = 'width_grid';

const
  sFillGrid = ' Build file list. Please, wait...';

const
  setBinary = [
    typeUnknown,
    typeMesh,
    typeSkeleton,
    typeTTF,
    typeMPP,
    typeBIK,
    typeSBIN
  ];

  setImage = [
    typeDDS,
    typeImage,
    typeJPG
  ];

  setSound = [
    typeSound
  ];

  setText = [
    typeScheme,
    typeFont,
    typeImageSet,
    typeLookNFeel,
    typeMaterial,
    typeProgram,
    typeCompositor,
    typeShader,
    typePU,
    typeAnno
  ];

  setData = [
    typeAnimation,
    typeDAT,
    typeWDAT,
    typeHIE,
    typeLayout,
    typeRAW
  ];

const
  DefaultExt    = '.MOD';
  DefaultFilter = 'MOD files|*.MOD|PAK files|*.PAK|MAN files|*.MAN|Supported files|*.MOD;*.PAK;*.MAN|All files|*.*';
const
  defTreeWidth = 256;
  defGridWidth = 360;

{%ENDREGION Constants}

//----- Support -----

const
  FileTimeBase      = -109205.0;
  FileTimeStep: Extended = 24.0 * 60.0 * 60.0 * 1000.0 * 1000.0 * 10.0; // 100 nSec per Day

function FileTimeToDateTime(const FileTime: Int64): TDateTime;
begin
  Result := FileTime / FileTimeStep;
  Result := Result + FileTimeBase;
end;

{ TRGGUIForm }

procedure TRGGUIForm.OpenFile(const aname:string);
var
  lmode:integer;
begin
//??  rgpi.fname:=WideString(aname);
  if cbFastScan.Checked then
    lmode:=piParse
  else
    lmode:=piFullParse;
  rgpi.Init;
  if rgpi.GetInfo(aname,lmode) then
  begin
    btnMODDAT.Visible:=rgpi.Version=verTL2Mod;
    Self.Caption:='RGGUI - '+AnsiString(rgpi.Name);
    StatusBar.Panels[0].Text:='Total: '+IntToStr(rgpi.man.total)+'; dirs: '+IntToStr(rgpi.man.EntriesCount);
//      sgMain.Columns[colTime-1].Visible:=(cbTime.Checked) and (ABS(rgpi.Version)=verTL2);
    SetupView(Self);

    FreeAndNil(fmi);
    actInfoInfo.Enabled:=true;
    actFileClose.Enabled:=true;
  end;
//  FillExtList();
  FillTree();
end;

{%REGION Settings}

procedure TRGGUIForm.ResetView(Sender: TObject);
begin
  pnlTree.Width:=defTreeWidth;
  sgMain .Width:=defGridWidth;
  sgMain.Columns[colDir   -1].Width:=256;
  sgMain.Columns[colName  -1].Width:=144;
  sgMain.Columns[colExt   -1].Width:=48;
  sgMain.Columns[colType  -1].Width:=80;
  sgMain.Columns[colTime  -1].Width:=110;
  sgMain.Columns[colPack  -1].Width:=80;
  sgMain.Columns[colUnpack-1].Width:=80;
  sgMain.Columns[colSource-1].Width:=80;
end;

procedure TRGGUIForm.SetupView(Sender: TObject);
begin
  sgMain.Columns[colExt   -1].Visible:=(cbExt     .Checked);
  sgMain.Columns[colType  -1].Visible:=(cbCategory.Checked);
  sgMain.Columns[colTime  -1].Visible:=(cbTime    .Checked) and (ABS(rgpi.Version)=verTL2);
  sgMain.Columns[colPack  -1].Visible:=(cbPacked  .Checked);
  sgMain.Columns[colUnpack-1].Visible:=(cbUnpacked.Checked);
  sgMain.Columns[colSource-1].Visible:=(cbSource  .Checked);

  tbExt     .Down:=(cbExt     .Checked);
  tbCategory.Down:=(cbCategory.Checked);
  tbTime    .Down:=(cbTime    .Checked) and (ABS(rgpi.Version)=verTL2);
  tbPacked  .Down:=(cbPacked  .Checked);
  tbUnpacked.Down:=(cbUnpacked.Checked);
  tbSource  .Down:=(cbSource  .Checked);
//  sgMainSelection(sgMain, sgMain.Col, sgMain.Row);
end;

procedure TRGGUIForm.tbColumnClick(Sender: TObject);
begin
  if      Sender=tbExt      then cbExt     .Checked:=not cbExt     .Checked
  else if Sender=tbCategory then cbCategory.Checked:=not cbCategory.Checked
  else if Sender=tbTime     then cbTime    .Checked:=not cbTime    .Checked
  else if Sender=tbPacked   then cbPacked  .Checked:=not cbPacked  .Checked
  else if Sender=tbUnpacked then cbUnpacked.Checked:=not cbUnpacked.Checked
  else if Sender=tbSource   then cbSource  .Checked:=not cbSource  .Checked;
  SetupView(Sender);
end;

procedure TRGGUIForm.SaveSettings;
var
  config:TIniFile;
  i:integer;
begin
  if cbSaveSettings.Checked then
  begin
    config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

    config.WriteString (sSectSettings,sOutDir      ,deOutDir.Text);
    config.WriteString (sSectSettings,sExt         ,LastExt);
    config.WriteInteger(sSectSettings,sFilter      ,LastFilter);
    config.WriteBool   (sSectSettings,sSavePath    ,cbUnpackTree.Checked);
    config.WriteBool   (sSectSettings,sMODDAT      ,cbMODDAT.Checked);
    config.WriteBool   (sSectSettings,sFastScan    ,cbFastScan.Checked);
    config.WriteBool   (sSectSettings,sSaveSettings,cbSaveSettings.Checked);

    config.WriteBool(sSectSettings,sShowExt     ,cbExt     .Checked);
    config.WriteBool(sSectSettings,sShowCategory,cbCategory.Checked);
    config.WriteBool(sSectSettings,sShowTime    ,cbTime    .Checked);
    config.WriteBool(sSectSettings,sShoPacked   ,cbPacked  .Checked);
    config.WriteBool(sSectSettings,sShowUnpacked,cbUnpacked.Checked);
    config.WriteBool(sSectSettings,sShowSource  ,cbSource  .Checked);

    config.WriteBool(sSectSettings,sShowPreview,cbShowPreview.Checked);

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

    config.UpdateFile;
    config.Free;
  end;
end;

procedure TRGGUIForm.LoadSettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  deOutDir.Text         :=config.ReadString (sSectSettings,sOutDir      ,GetCurrentDir());
  LastExt               :=config.ReadString (sSectSettings,sExt         ,DefaultExt);
  LastFilter            :=config.ReadInteger(sSectSettings,sFilter      ,4);
  cbUnpackTree.Checked  :=config.ReadBool   (sSectSettings,sSavePath    ,true);
  cbMODDAT.Checked      :=config.ReadBool   (sSectSettings,sMODDAT      ,true);
  cbFastScan.Checked    :=config.ReadBool   (sSectSettings,sFastScan    ,false);
  cbSaveSettings.Checked:=config.ReadBool   (sSectSettings,sSaveSettings,false);

  cbExt     .Checked:=config.ReadBool(sSectSettings,sShowExt     ,true);
  cbCategory.Checked:=config.ReadBool(sSectSettings,sShowCategory,false);
  cbTime    .Checked:=config.ReadBool(sSectSettings,sShowTime    ,false);
  cbPacked  .Checked:=config.ReadBool(sSectSettings,sShoPacked   ,false);
  cbUnpacked.Checked:=config.ReadBool(sSectSettings,sShowUnpacked,false);
  cbSource  .Checked:=config.ReadBool(sSectSettings,sShowSource  ,false);

  cbShowPreview.Checked:=config.ReadBool(sSectSettings,sShowPreview,false);

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

  case config.ReadInteger(sSectSettings,sDecoding,4) of
    1: rbBinOnly  .Checked:=true;
    2: rbTextOnly .Checked:=true;
    4: rbGUTSStyle.Checked:=true;
  else
    rbTextRename.Checked:=true;
  end;

  config.Free;
end;

{%ENDREGION Settings}

{%REGION Save}

function TRGGUIForm.SaveFile(const adir,aname:string; adata:PByte; asize:integer):boolean;
var
  f:file of byte;
  loutdir,lext:string;
  lnode:pointer;
  ltype:integer;
begin
  result:=false;

  if cbUnpackTree.Checked then
    loutdir:=deOutDir.Text+'\'+adir
  else
    loutdir:=deOutDir.Text;
  if not ForceDirectories(loutdir) then exit;

//  ltype:=GetExtInfo(aname,rgpi.ver)^._type;
  ltype:=PAKExtType(aname);

  // save decoded file
  if (not rbBinOnly.Checked) and (ltype in setData) then
  begin
    if ltype=typeLayout then
      lnode:=ParseLayoutMem(adata,adir+aname)
    else if ltype=typeRAW then
      lnode:=ParseRawMem(adata,adir+aname)
    else
      lnode:=ParseDatMem(adata);

    if rbTextRename.Checked or (ltype=typeRAW) then
      lext:='.TXT'
    else
      lext:='';
    BuildTextFile(lnode,PChar(loutdir+'\'+aname+lext));
    DeleteNode(lnode);
  end;

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
    AssignFile(f,loutdir+'\'+aname+lext);
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,adata^,asize);
      CloseFile(f);
    end;
  end;

  result:=true;
end;

procedure TRGGUIForm.bbSaveClick(Sender: TObject);
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
      lname:=sgMain.Cells[colName,i];
{
      if FUData=nil then
      begin
        if UnpackFile(rgpi,ldir+lname,FUData)=0 then exit;
      end;
}
      lsize:=rgpi.UnpackFile(ldir+lname,lptr);
      if lsize>0 then
      begin
        if SaveFile(ldir, lname, lptr, lsize) then
          inc(lcnt);
      end;
    end;
  end;
  FreeMem(lptr);

  if lcnt=1 then
    ShowMessage('File '+ldir+lname+#13#10'unpacked succesfully.')
  else if lcnt>1 then
    ShowMessage(IntToStr(lcnt)+' files unpacked succesfully.');
end;

{%ENDREGION Save}

{%REGION Filter}

procedure TRGGUIForm.bbExtSelectClick(Sender: TObject);
var
  i:integer;
  b:boolean;
begin
  b:=not ccbExtension.Checked[0];
  for i:=0 to ccbExtension.Count-1 do
    ccbExtension.Checked[i]:=b;

  FillGrid(FLastIndex);
end;

procedure TRGGUIForm.bbCatInverseClick(Sender: TObject);
var
  i:integer;
begin
  for i:=0 to ccbCategory.Count-1 do
    ccbCategory.Checked[i]:= not ccbCategory.Checked[i];

  FillGrid(FLastIndex);
end;

procedure TRGGUIForm.ccbFilterCloseUp(Sender: TObject);
begin
  (Sender as TCheckComboBox).ItemIndex:=-1;
//  ccbCategory.Text:=rsCategory; //!! not working
  if fFilterWasChanged then
  begin
    FillGrid(FLastIndex);
    fFilterWasChanged:=false;
  end;
end;

procedure TRGGUIForm.ccbFilterItemChange(Sender: TObject; AIndex: Integer);
begin
  fFilterWasChanged:=true;
end;

procedure TRGGUIForm.FillExtList();
var
  i:integer;
begin
  ccbExtension.ReadOnly:=true;
  ccbExtension.Clear;

  // of course, better to show just PAK/MOD used exts
  for i:=0 to High(TableExt) do
    ccbExtension.AddItem(TableExt[i]._ext,cbChecked);
end;

procedure TRGGUIForm.FillCatList();
begin
  ccbCategory.ReadOnly:=true;
  ccbCategory.Clear;
  ccbCategory.AddItem(PAKCategoryName(catUnknown),cbUnChecked);
  ccbCategory.AddItem(PAKCategoryName(catModel  ),cbUnChecked);
  ccbCategory.AddItem(PAKCategoryName(catImage  ),cbChecked);
  ccbCategory.AddItem(PAKCategoryName(catSound  ),cbChecked);
  ccbCategory.AddItem(PAKCategoryName(catFolder ),cbUnChecked);
  ccbCategory.AddItem(PAKCategoryName(catFont   ),cbUnChecked);
  ccbCategory.AddItem(PAKCategoryName(catData   ),cbChecked);
  ccbCategory.AddItem(PAKCategoryName(catLayout ),cbChecked);
  ccbCategory.AddItem(PAKCategoryName(catShaders),cbUnChecked);
  ccbCategory.AddItem(PAKCategoryName(catOther  ),cbUnChecked);
  ccbCategory.ItemIndex:=-1;
end;

{%ENDREGION Filter}

{%REGION Form}

procedure TRGGUIForm.sgMainHeaderSized(Sender: TObject; IsColumn: Boolean; Index: Integer);
var
  i,j:integer;
begin
  j:=0;

  for i:=0 to sgMain.ColCount-2 do
    inc(j,sgMain.ColWidths[i]);
  if sgMain.Width>(j+8) then sgMain.Width:=j+8;
end;

procedure TRGGUIForm.FormCreate(Sender: TObject);
begin
  FLastIndex:=-1;
  FUData    :=nil;

  fmLogForm:=nil;

  SynTSyn:=TSynTSyn.Create(Self);

  LoadSettings();
  SetupView(Self);

  RGTags.Import('RGDICT','TEXT');

  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  // Category
  FillCatList();

  // Extension
  FillExtList();

  if ParamCount>0 then
    OpenFile(ParamStr(1))
  else
    rgpi.Init;

  PageControl.ActivePageIndex:=1;

  inProcess:=false;
end;

procedure TRGGUIForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if FUData<>nil then FreeMem(FUData);

  SaveSettings();

//  actFileCloseExecute(Sender);
  rgpi.Free;

  actFileClose.Enabled:=false; //??
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

      actFileCloseExecute(Sender);

      OpenFile(OpenDialog.FileName);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TRGGUIForm.actFileCloseExecute(Sender: TObject);
begin
  rgpi.Free;
  sgMain.Clear;
  ClearInfo();
  tvTree.Items.Clear;
  actInfoInfo.Enabled:=false;
  FreeAndNil(fmi);
end;

procedure TRGGUIForm.actFileExitExecute(Sender: TObject);
begin
  actFileCloseExecute(Sender);
  Close;
end;

procedure TRGGUIForm.actInfoInfoExecute(Sender: TObject);
begin
  if fmi=nil then
  begin
    fmi:=TMODInfoForm.Create(Self,true);
    TMODInfoForm(fmi).LoadFromInfo(rgpi.modinfo);
  end;
  fmi.ShowOnTop;
end;

procedure TRGGUIForm.actShowLogExecute(Sender: TObject);
begin
  if fmLogForm=nil then
    fmLogForm:=TfmLogForm.Create(Self);
  fmLogForm.ShowOnTop;
end;

{%ENDREGION Form}

{%REGION Unpack}

function TRGGUIForm.UnpackSingleFile(const adir,aname:string):boolean;
var
  ldata:PByte;
  lsize:integer;
begin
  ldata:=nil;
  lsize:=rgpi.UnpackFile(adir+aname,ldata);
  if lsize>0 then
  begin
    result:=SaveFile(adir,aname,ldata,lsize);
    FreeMem(ldata);
  end
  else
    result:=false;
end;

procedure TRGGUIForm.DoExtractGrid(Sender: TObject);
var
  i:integer;
begin
  for i:=1 to sgMain.RowCount-1 do
  begin
    UnpackSingleFile(sgMain.Cells[colDir,i],sgMain.Cells[colName,i])
  end;
end;

procedure TRGGUIForm.ExtractSingleDir(adir:integer);
var
  p:PMANFileInfo;
  ldir:PWideChar;
begin
  if rgpi.man.GetFirstFile(p,adir)<>0 then
  begin
    ldir:=rgpi.man.GetDirName(adir);
    repeat
      if not (p^.ftype in [typeDelete,typeDirectory]) then
        UnpackSingleFile(ldir,rgpi.man.GetName(p^.name))
    until rgpi.man.GetNextFile(p)=0;
  end;
end;

procedure TRGGUIForm.DoExtractDir(Sender: TObject);
begin
  ExtractSingleDir(IntPtr(tvTree.Selected.Data));
end;

procedure TRGGUIForm.DoExtractTree(Sender: TObject);
var
  ls:PWideChar;
  i,idx,llen:integer;
begin
  idx:=IntPtr(tvTree.Selected.Data);
  if idx>=0 then
  begin
    ls:=rgpi.man.GetDirName(idx);
    llen:=Length(ls);
  end;

  for i:=0 to rgpi.man.EntriesCount-1 do
  begin
    if not rgpi.man.IsDirDeleted(i) then
      if (idx<0) or (i=idx) or (CompareWide(ls,rgpi.man.GetDirName(i),llen)=0) then
        ExtractSingleDir(i);
  end;

  if (idx<0) and (cbMODDAT.Checked) and (rgpi.Version=verTL2Mod) then
  begin
    SaveModConfiguration(rgpi.modinfo,PChar(deOutDir.Text+'\'+'MOD.DAT'));
  end;
end;

{%ENDREGION}

{%REGION Preview}

procedure TRGGUIForm.ClearInfo();
begin
  lblPackVal  .Caption:='';
  lblUnpackVal.Caption:='';
  lblSrcVal   .Caption:='';
  lblOffsetVal.Caption:='';
  lblTimeVal  .Caption:='';

//  memText.Clear;
  SynEdit.Clear;
  imgPreview.Picture.Clear;
  SynEdit.Visible:=false;
  imgPreview.Visible:=false;

  FreeMem(FUData); FUData:=nil;
end;

procedure TRGGUIForm.PreviewImage(const aname:string);
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
  if ExtractFileExt(aname)='.DDS' then
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
      lstr.SetBuffer(FUData);
      imgPreview.Picture.LoadFromStream(lstr);
    // not free FUData coz dirty trick
    finally
      lstr.Free;
    end;
  end;
  imgPreview.Visible:=true;
end;

procedure TRGGUIForm.PreviewSource(atype:byte; const adir,aname:string);
var
  lnode:pointer;
  pc:PWideChar;
begin
  if atype=typeLayout then
    lnode:=ParseLayoutMem(FUData,adir+aname)
  else if atype=typeRAW then
    lnode:=ParseRawMem(FUData,adir+aname)
  else
    lnode:=ParseDatMem(FUData);
  if NodeToWide(lnode,pc) then
  begin
//!!    pnlEditButtons.Visible:=true;

    SynEdit.Highlighter:=SynTSyn;
    SynEdit.Text:=WideToStr(pc+1);//WideCharToString(pc+1); // skip sign
    SynEdit.Visible:=true;
    FreeMem(pc);
  end;
  DeleteNode(lnode);
end;

procedure TRGGUIForm.PreviewText();
var
  ltext:string;
begin
  SetString(ltext,PChar(FUData),FUSize);
  SynEdit.Highlighter:=SynXMLSyn;
  SynEdit.Text:=ltext;
  SynEdit.Visible:=true;
end;

procedure TRGGUIForm.sgMainSelection(Sender: TObject; aCol, aRow: Integer);
var
  mfi:PMANFileInfo;
  ldir,lname:string;
begin
  ClearInfo();

  if (aCol<1) or (aRow<1) then
    Exit;

  ldir :=sgMain.Cells[colDir ,aRow];
  lname:=sgMain.Cells[colName,aRow];
  StatusBar.Panels[1].Text:='File path: '+ldir;

  mfi:=rgpi.man.SearchFile(ldir+lname);
  if mfi<>nil then
  begin
    RGLog.Reserve('Processing '+ldir+lname);

    lblPackVal  .Caption:=IntToStr(mfi^.size_c);
    lblUnpackVal.Caption:=IntToStr(mfi^.size_u);
    lblSrcVal   .Caption:=IntToStr(mfi^.size_s);
    lblOffsetVal.Caption:='0x'+HexStr(mfi^.offset,8);
    try
      lblTimeVal.Caption:=DateTimeToStr(FileTimeToDateTime(mfi^.ftime));
    except
      lblTimeVal.Caption:='0x'+HexStr(mfi^.ftime,16);
    end;

    if mfi^.ftype in (setBinary+[typeDelete,typeDirectory]) then exit;

    if not cbShowPreview.Checked then exit;

    //!! what to show in lsize=0 ?
    FUSize:=rgpi.UnpackFile(ldir+lname,FUData);
    if FUSize>0 then
    begin
//!!      pnlEditButtons.Visible:=false;
      // Text
      if      mfi^.ftype in setText then PreviewText()
      else if mfi^.ftype in setData then PreviewSource(mfi^.ftype, ldir, lname);
//      else SynEdit.Visible:=false;

      // Image
      if mfi^.ftype in setImage then
        PreviewImage(lname);
//      else imgPreview.Visible:=false;

      // Sound
      if mfi^.ftype=typeSound then
      begin
      end
      else
      ;

    end;

  end;

end;

procedure TRGGUIForm.cbShowPreviewChange(Sender: TObject);
begin
  sgMainSelection(sgMain, 2, sgMain.Row);
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

{%REGION Grid}

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

function TRGGUIForm.FillGridLine(arow:integer; const adir:string; afile:PMANFileInfo):boolean;
var
  lname,lext:string;
  lcat:integer;
  i:integer;
begin
  result:=false;

  if afile^.size_s=0 then exit;

  lname:=WideToStr(rgpi.man.GetName(afile^.name));
  lext:=ExtractFileExt(lname);
  for i:=0 to ccbExtension.Items.Count-1 do
  begin
    if (not ccbExtension.Checked[i]) and
       (ccbExtension.Items[i]=lext) then exit;
  end;

  lcat:=PAKExtCategory(lext);
  if not ccbCategory.Checked[lcat] then exit(false);

  sgMain.Cells[colDir   ,arow]:=adir;
  sgMain.Cells[colName  ,arow]:=lname;
  sgMain.Cells[colExt   ,arow]:=Copy(lext,2);
  sgMain.Cells[colPack  ,arow]:=IntToStr(afile^.size_c);
  sgMain.Cells[colUnpack,arow]:=IntToStr(afile^.size_u);
  sgMain.Cells[colType  ,arow]:=PAKCategoryName(PAKTypeToCategory(afile^.ftype){lcat});
  if {sgMain.Columns[colTime-1].Visible and} (afile^.ftime<>0) then
  begin
    try
      sgMain.Cells[colTime,arow]:=DateTimeToStr(FileTimeToDateTime(afile^.ftime));
    except
      sgMain.Cells[colTime,arow]:='0x'+HexStr(afile^.ftime,16);
    end;
  end
  else
    sgMain.Cells[colTime,arow]:='';
  if afile^.size_s<>afile^.size_u then
    sgMain.Cells[colSource,arow]:=IntToStr(afile^.size_s)
  else
    sgMain.Cells[colSource,arow]:='';

  result:=true;
end;

procedure TRGGUIForm.FillGrid(idx:integer=-1);
var
  lname:string;
  p:PMANFileInfo;
  i:integer;
  lcnt:integer;
begin
  if inProcess then exit;

  if idx>=rgpi.man.EntriesCount then exit;

  inProcess:=true;

  FLastIndex:=idx;
  sgMain.Clear;
  sgMain.BeginUpdate;
  sgMain.Columns[colDir-1].Visible:=idx<0;
  lcnt:=1;

  if idx<0 then
  begin
    Self.Caption:='RGGUI - '+AnsiString(rgpi.Name)+sFillGrid;

    sgMain.RowCount:=rgpi.man.total+1;
    for i:=0 to rgpi.man.EntriesCount-1 do
    begin
      if not rgpi.man.IsDirDeleted(i) then
      begin
        if rgpi.man.GetFirstFile(p,i)<>0 then
        begin
          lname:=rgpi.man.GetDirName(i);
          repeat
            if FillGridLine(lcnt, lname, p) then
              inc(lcnt);
          until rgpi.man.GetNextFile(p)=0;
        end;

        if (lcnt mod 1000)=0 then
          Application.ProcessMessages;
      end;
    end;
    Self.Caption:='RGGUI - '+AnsiString(rgpi.Name);
  end
  else
  begin
    sgMain.RowCount:=rgpi.man.Dirs[idx].count+1;
    if rgpi.man.GetFirstFile(p,idx)<>0 then
    begin
      lname:=rgpi.man.GetDirName(idx);
      repeat
        if FillGridLine(lcnt, lname, p) then
          inc(lcnt);
      until rgpi.man.GetNextFile(p)=0;
    end;
  end;

  sgMain.RowCount:=lcnt;
  bbSave.Visible:=lcnt>1;
  actEditExtract.Enabled:=lcnt>1;
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
var
  i:integer;
begin
  tvTree.BeginUpdate;
  for i:=2 to tvTree.Items.Count-1 do
    tvTree.Items[i].Expanded:=false;
  tvTree.Items[1].Expanded:=true;
  tvTree.Items[0].Expanded:=true;
  tvTree.EndUpdate;
end;

function TRGGUIForm.GetPathFromNode(aNode:TTreeNode):string;
begin
  result:='';
  repeat
    result:=aNode.Text+cSep+result;
    aNode:=aNode.Parent;
  until aNode=nil;
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

procedure TRGGUIForm.AddBranch(aroot:TTreeNode; const aname:string; acode:integer);
var
  ls:string;
  i,j,k:integer;
begin
  if aname='' then exit;

  i:=Pos(cSep,aname);
  if i<1 then i:=Length(aname)+1;
  ls:=Copy(aname,1,i-1);

  k:=-1;
  for j:=0 to aroot.Count-1 do
  begin
    if aroot.Items[j].Text=ls then
    begin
      k:=j;
      break;
    end;
  end;

 if k<0 then
  begin
    aroot:=tvTree.Items.AddChild(aroot,ls);
    if i>=Length(aname) then
      aroot.Data:=pointer(IntPtr(acode));
  end
  else
    aroot:=aroot.Items[k];

  if i<Length(aname) then
    AddBranch(aroot,Copy(aname,i+1),acode);
end;

procedure TRGGUIForm.FillTree();
var
  sl:TStringList;
  lroot:TTreeNode;
  ls:string;
  i:integer;
begin
  tvTree.Items.Clear;

  sl:=TStringList.Create;
  sl.Sorted:=true;
  for i:=0 to rgpi.man.EntriesCount-1 do
  begin
    if not rgpi.man.IsDirDeleted(i) then
    begin
      ls:=UpCase(WideToStr(rgpi.man.GetDirName(i)));
      if sl.IndexOf(ls)<0 then
        sl.AddObject(ls,TObject(IntPtr(i)));
    end;
  end;
  sl.Sort;

  with tvTree do
  begin
    BeginUpdate;
    lroot:=Items.AddFirst(nil,'MOD');
    lroot.Data:=pointer(-1);

    for i:=0 to sl.Count-1 do
    begin
      AddBranch(lroot{nil},sl[i],IntPtr(sl.Objects[i]));
    end;
    lroot:=tvTree.Items[0];
    if tvTree.Items.Count>20 then
      bbCollapseClick(bbCollapse);
    EndUpdate;
  end;
  sl.Free;
  bbCollapse.Enabled:=tvTree.Items.Count>2;
  if bbCollapse.Enabled then
    tvTree.Items[1].Selected:=true;
end;

{%ENDREGION Tree}

end.
