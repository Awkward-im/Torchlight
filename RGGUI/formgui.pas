{%TODO unpack not single file but tree branch}
unit formGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids, Menus,
  ActnList, ExtCtrls, ComboEx, StdCtrls, EditBtn, Buttons, TreeFilterEdit,
  rgglobal;

type

  { TRGGUIForm }

  TRGGUIForm = class(TForm)
    bbExtSelect: TBitBtn;
    bbCatInverse: TBitBtn;
    cbUnpackTree: TCheckBox;
    deOutDir: TDirectoryEdit;
    gbDecoding: TGroupBox;
    ImageList: TImageList;
    lblNote: TLabel;
    lblOutDir: TLabel;
    miExtractTree: TMenuItem;
    miExtractDir: TMenuItem;
    miExtractVisible: TMenuItem;
    PageControl: TPageControl;

    pnlFilter: TPanel;
    ccbCategory : TCheckComboBox;    lblCategory : TLabel;
    ccbExtension: TCheckComboBox;    lblExtension: TLabel;

    pnlTree: TPanel;
    mnuTree: TPopupMenu;
    rbGUTSStyle: TRadioButton;
    rbTextRename: TRadioButton;
    rbBinOnly: TRadioButton;
    rbTextOnly: TRadioButton;
    sgMain: TStringGrid;
    Splitter1: TSplitter;
    StatusBar: TStatusBar;
    Setings: TTabSheet;
    Grid: TTabSheet;

    ToolBar: TToolBar;
    tbOpen  : TToolButton;
    tbSep1  : TToolButton;
    tbAbout : TToolButton;
    tbSaveAs: TToolButton;

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

    edTreeFilter: TTreeFilterEdit;
    tvTree: TTreeView;

    procedure actFileCloseExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure bbExtSelectClick(Sender: TObject);
    procedure bbCatInverseClick(Sender: TObject);
    procedure ccbFilterCloseUp(Sender: TObject);
    procedure ccbFilterItemChange(Sender: TObject; AIndex: Integer);
    procedure DoExtractDir(Sender: TObject);
    procedure DoExtractGrid(Sender: TObject);
    procedure DoExtractTree(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sgMainCompareCells(Sender: TObject; ACol, ARow, BCol,
      BRow: Integer; var Result: integer);
    procedure sgMainDblClick(Sender: TObject);
    procedure tvTreeSelectionChanged(Sender: TObject);
  private
    fFilterWasChanged: Boolean;
    rgpi:TPAKInfo;
    LastExt,LastFilter:string;
    FLastIndex:integer;

    procedure AddBranch(aroot: TTreeNode; const aname: string; acode: integer);
    procedure FillCatList();
    procedure FillExtList();
    procedure FillGrid(idx:integer=-1);
    function FillGridLine(arow: integer; const adir: string;
      const afile: TMANFileInfo): boolean;
    procedure FillTree();
    function GetPathFromNode(aNode: TTreeNode): string;
    procedure LoadSettings;
    procedure SaveSettings;
    function UnpackSingleFile(const adir, aname: string): boolean;

  public

  end;

var
  RGGUIForm: TRGGUIForm;

implementation

{$R *.lfm}
{$R dict.rc}

uses
  inifiles,
  rgfiletype,
  rgdatunpack,
  rglayunpack,
  rgdict,
  rgnode,
  rgpak;

{
resourcestring
  rsCategory = 'Category';
}
const
  cSep = '/';

const
  colDir    = 1;
  colName   = 2;
  colType   = 3;
  colTime   = 4;
  colPack   = 5;
  colUnpack = 6;
  colSource = 7;

const
  INIFileName   = 'RGGUI.INI';
  sSectSettings = 'settings';
  sOutDir       = 'outdir';
  sSavePath     = 'savepath';
  sDecoding     = 'decoding';

const
  DefaultExt    = '.MOD';
  DefaultFilter = 'MOD files|*.MOD|PAK files|*.PAK|MAN files|*.MAN|Supported files|*.MOD;*.PAK;*.MAN|All files|*.*';

//----- Support -----

const
  FileTimeBase      = -109205.0;
  FileTimeStep: Extended = 24.0 * 60.0 * 60.0 * 1000.0 * 1000.0 * 10.0; // 100 nSek per Day

function FileTimeToDateTime(const FileTime: Int64): TDateTime;
begin
  Result := FileTime / FileTimeStep;
  Result := Result + FileTimeBase;
end;

{ TRGGUIForm }

procedure TRGGUIForm.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
//    OpenDialog.Title  :=rsFileOpen;
    OpenDialog.Options   :=[ofFileMustExist];
    OpenDialog.DefaultExt:=LastExt;
    OpenDialog.Filter    :=LastFilter;

    if OpenDialog.Execute then
    begin
      LastExt   :=OpenDialog.DefaultExt;
      LastFilter:=OpenDialog.Filter;

      actFileCloseExecute(Sender);
      rgpi.fname:=OpenDialog.FileName;
      if GetPAKInfo(OpenDialog.FileName,rgpi,piFullParse) then
      begin
        Self.Caption:='RGGUI - '+rgpi.fname;
        StatusBar.SimpleText:='Total: '+IntToStr(rgpi.total)+'; dirs: '+IntToStr(Length(rgpi.Entries));
      end;
      FillExtList();
      FillTree();
    end;
  finally
    OpenDialog.Free;
  end;
end;

//----- Settings -----

procedure TRGGUIForm.SaveSettings;
var
  config:TIniFile;
  i:integer;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  config.WriteString(sSectSettings,sOutDir   ,deOutDir.Text);
  config.WriteBool  (sSectSettings,sSavePath ,cbUnpackTree.Checked);
  if      rbBinOnly   .Checked then i:=1
  else if rbTextOnly  .Checked then i:=2
  else if rbTextRename.Checked then i:=3
  else if rbGUTSStyle .Checked then i:=4
  else i:=0;
  config.WriteInteger(sSectSettings,sDecoding,i);

  config.UpdateFile;
  config.Free;
end;

procedure TRGGUIForm.LoadSettings;
var
  config:TIniFile;
  i:integer;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  deOutDir.Text       :=config.ReadString (sSectSettings,sOutDir  ,GetCurrentDir());
  cbUnpackTree.Checked:=config.ReadBool   (sSectSettings,sSavePath,true);
  case config.ReadInteger(sSectSettings,sDecoding,3) of
    1: rbBinOnly  .Checked:=true;
    2: rbTextOnly .Checked:=true;
    4: rbGUTSStyle.Checked:=true;
  else
    rbTextRename.Checked:=true;
  end;

  config.Free;
end;

//----- Filter panel -----

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

//----- Form -----

procedure TRGGUIForm.FormCreate(Sender: TObject);
begin
  LastExt   :=DefaultExt;
  LastFilter:=DefaultFilter;
  FLastIndex:=-1;

  LoadSettings();
//  rbTextOnly.Checked:=true;

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
end;

procedure TRGGUIForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveSettings();

  FreePAKInfo(rgpi);
end;

procedure TRGGUIForm.actFileCloseExecute(Sender: TObject);
begin
  FreePAKInfo(rgpi);
  sgMain.Clear;
end;

procedure TRGGUIForm.actFileExitExecute(Sender: TObject);
begin
  actFileCloseExecute(Sender);
  Close;
end;

//----- Unpack -----

function TRGGUIForm.UnpackSingleFile(const adir,aname:string):boolean;
var
  f:file of byte;
  loutdir,lext:string;
  lnode:pointer;
  lbin:PByte;
  ltype,lsize:integer;
begin
  result:=false;

  if cbUnpackTree.Checked then
    loutdir:=deOutDir.Text+'\'+adir
  else
    loutdir:=deOutDir.Text;
  if not ForceDirectories(loutdir) then exit;

  ltype:=GetExtInfo(aname,rgpi.ver)^._type;

  lsize:=UnpackFile(rgpi,adir+aname,lbin);
  if lsize>0 then
  begin
    if (not rbBinOnly.Checked) and
       (ltype in [typeAnimation,typeDAT,typeHIE,typeWDAT,typeLayout]) then
    begin
      if ltype=typeLayout then
        lnode:=DoParseLayout(lbin,adir+aname)
      else
        lnode:=DoParseDat(lbin);

      if rbTextRename.Checked then
        lext:='.TXT'
      else
        lext:='';
      WriteDatTree(lnode,PChar(loutdir+'\'+aname+lext));
      DeleteNode(lnode);
    end;
    // save binary file
    lext:='';
    if rbGUTSStyle.Checked then
    begin
      if ltype=typeLayout then
        lext:='.BINLAYOUT'
      else if ltype in [typeAnimation,typeDAT,typeHIE,typeWDAT] then
        lext:='.BINDAT';
    end;
    if not (rbTextOnly.Checked and (ltype in [typeAnimation,typeDAT,typeHIE,typeWDAT,typeLayout])) then
    begin
      AssignFile(f,loutdir+'\'+aname+lext);
      Rewrite(f);
      if IOResult=0 then
      begin
        BlockWrite(f,lbin^,lsize);
        CloseFile(f);
      end;
    end;

    FreeMem(lbin);
    result:=true;
  end;
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

procedure TRGGUIForm.DoExtractDir(Sender: TObject);
var
  i,idx:integer;
begin
  idx:=IntPtr(tvTree.Selected.Data);
  for i:=0 to High(rgpi.Entries[idx].Files) do
  begin
    if rgpi.Entries[idx].Files[i].ftype<>typeDirectory then
      UnpackSingleFile(rgpi.Entries[idx].name,rgpi.Entries[idx].Files[i].name)
  end;
end;

procedure TRGGUIForm.DoExtractTree(Sender: TObject);
var
  ls:PWideChar;
  i,j,idx,llen:integer;
begin
  idx:=IntPtr(tvTree.Selected.Data);
  ls:=rgpi.Entries[idx].name;
  llen:=Length(ls);
  for i:=0 to High(rgpi.Entries) do
  begin
    if (i=idx) or (CompareWide(ls,rgpi.Entries[i].name,llen)=0) then
      for j:=0 to High(rgpi.Entries[i].Files) do
      begin
        if rgpi.Entries[i].Files[j].ftype<>typeDirectory then
          UnpackSingleFile(rgpi.Entries[i].name,rgpi.Entries[i].Files[j].name)
      end;
  end;
end;

//----- Grid -----

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
  i:integer;
begin
  i:=sgMain.Row;

  if UnpackSingleFile(sgMain.Cells[colDir,i],sgMain.Cells[colName,i]) then
    ShowMessage('File '+sgMain.Cells[colDir,i]+sgMain.Cells[colName,i]+#13#10'unpacked succesfully.');
end;

function TRGGUIForm.FillGridLine(arow:integer; const adir:string; const afile:TMANFileInfo):boolean;
var
  lext:string;
  lcat:integer;
  i:integer;
begin
  result:=false;

  if afile.size_s=0 then exit;
  
  lext:=string(ExtractFileExt(afile.name));
  for i:=0 to ccbExtension.Items.Count-1 do
  begin
    if (not ccbExtension.Checked[i]) and
       (ccbExtension.Items  [i]=lext) then exit;
  end;

  lcat:=GetExtCategory(lext);
  if not ccbCategory.Checked[lcat] then exit(false);

  sgMain.Cells[colDir   ,arow]:=adir;
  sgMain.Cells[colName  ,arow]:=afile.name;
  sgMain.Cells[colPack  ,arow]:=IntToStr(afile.size_c);
  sgMain.Cells[colUnpack,arow]:=IntToStr(afile.size_u);
  sgMain.Cells[colType  ,arow]:=PAKCategoryName(PAKTypeToCategory(afile.ftype));
  if sgMain.Columns[colTime-1].Visible and (afile.ftime<>0) then
  begin
    try
      sgMain.Cells[colTime,arow]:=DateTimeToStr(FileTimeToDateTime(afile.ftime));
    except
      sgMain.Cells[colTime,arow]:='0x'+HexStr(afile.ftime,16);
    end;
  end
  else
    sgMain.Cells[colTime,arow]:='';
  if afile.size_s<>afile.size_u then
    sgMain.Cells[colSource,arow]:=IntToStr(afile.size_s)
  else
    sgMain.Cells[colSource,arow]:='';

  result:=true;
end;

procedure TRGGUIForm.FillGrid(idx:integer=-1);
var
  i,j:integer;
  lcnt:integer;
begin
  if idx>=Length(rgpi.Entries) then exit;

  FLastIndex:=idx;
  sgMain.Clear;
  sgMain.BeginUpdate;
  sgMain.Columns[colTime-1].Visible:=(ABS(rgpi.ver)=verTL2);
  sgMain.Columns[colDir -1].Visible:=idx<0;
  lcnt:=1;

  if idx<0 then
  begin
    sgMain.RowCount:=rgpi.total+1;
    for i:=0 to High(rgpi.Entries) do
    begin
      for j:=0 to High(rgpi.Entries[i].Files) do
      begin
        if FillGridLine(lcnt, rgpi.Entries[i].name, rgpi.Entries[i].Files[j]) then
          inc(lcnt);
      end;
    end;
  end
  else
  begin
    sgMain.RowCount:=Length(rgpi.Entries[idx].Files)+1;
    for j:=0 to High(rgpi.Entries[idx].Files) do
    begin
      if FillGridLine(lcnt, rgpi.Entries[idx].name, rgpi.Entries[idx].Files[j]) then
        inc(lcnt);
    end;
  end;

  sgMain.RowCount:=lcnt;

  sgMain.EndUpdate;
end;

//----- Tree -----

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
  for i:=0 to High(rgpi.Entries) do
  begin
    ls:=UpCase(WideString(rgpi.Entries[i].name));
    if sl.IndexOf(ls)<0 then
      sl.AddObject(ls,TObject(IntPtr(i)));
  end;
  sl.Sort;
  
  with tvTree do
  begin
    BeginUpdate;
    lroot:=Items.AddFirst(nil,'MOD');
    for i:=0 to sl.Count-1 do
    begin
      AddBranch(lroot{nil},sl[i],IntPtr(sl.Objects[i]));
//      if (i>0) and ((i mod 100)=0) then Application.ProcessMessages;
    end;
    lroot:=tvTree.Items[0];
    lroot.Expanded:=true;
    lroot.Selected:=true;
    EndUpdate;
  end;

  sl.Free;
end;

end.
