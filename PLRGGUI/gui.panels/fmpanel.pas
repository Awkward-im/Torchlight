unit fmPanel;

{$mode ObjFPC}{$H+}

interface

uses
  uni_profiler, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, Buttons, ShellCtrls, Menus, ActnList, TreeFilterEdit,
  ListViewFilterEdit, RGGlobal, RGCtrl, Types;


{$DEFINE Interface}

type
  TRGOnPanelType = function (apanel:TForm; atype:integer; abefore:boolean):integer of object;
  TRGOnExecute   = function (actrl:PRGController; aidx:integer):integer of object;

type

  { TPanelForm }

  TPanelForm = class(TForm)
    actExtractCurDir: TAction;
    alPanel: TActionList;
    actImportFile: TAction;
    actImportDir : TAction;
    actView      : TAction;
    actRefresh   : TAction;
    actMark      : TAction;
    actUndo      : TAction;
    actRoot      : TAction;
    actNewFile   : TAction;
    actNewDir    : TAction;
    actRename    : TAction;
    actSelectAll : TAction;
    actInverse   : TAction;
    actExtract   : TAction;
    actExtractDir: TAction;
    actDelete    : TAction;
    actDirList   : TAction;
    mnuGrid: TPopupMenu;
    miGridExtract   : TMenuItem;
    miGridNew       : TMenuItem;
    miGridRename    : TMenuItem;
    miGridView      : TMenuItem;
    miGridSep1      : TMenuItem;
    miGridImportDir : TMenuItem;
    miGridImportFile: TMenuItem;
    miGridSep2      : TMenuItem;
    miGridCopy      : TMenuItem;
    miGridSepAlt    : TMenuItem;
    miGridDelete    : TMenuItem;
    miGridMark      : TMenuItem;
    miGridUndo      : TMenuItem;
    mnuTree: TPopupMenu;
    miTreeNew           : TMenuItem;
    miTreeExtractCurrent: TMenuItem;
    miTreeExtractSub    : TMenuItem;
    miTreeImportDir     : TMenuItem;
    miTreeCopyList      : TMenuItem;
    miTreeSep1          : TMenuItem;
    miTreeDelete        : TMenuItem;
    miTreeMark          : TMenuItem;
    miTreeUndo          : TMenuItem;
    mnuColumns: TPopupMenu;
    miColType  : TMenuItem;
    miColSize  : TMenuItem;
    miColPacked: TMenuItem;
    miColTime  : TMenuItem;
    miColAttr  : TMenuItem;
    ilPanel: TImageList;
    pnlPath: TPanel;
    pnlTop: TPanel;
    cbContent: TComboBox;
    pnlTopList: TPanel;
    lvfeFull : TListViewFilterEdit;
    sbFilter : TSpeedButton;
    sbFull   : TSpeedButton;
    sbColumns: TSpeedButton;
    lvList: TListView;
    pnlTopTree: TPanel;
    tfeTree   : TTreeFilterEdit;
    sbCollapse: TSpeedButton;
    sbTree    : TSpeedButton;
    tvShell: TShellTreeView;
    tvTree : TTreeView;

    procedure cbContentChange(Sender: TObject);
    procedure ColMenuClick(Sender: TObject);
    procedure execDelete(Sender: TObject);

    procedure execDirList(Sender: TObject);
    procedure execExtractCurDir(Sender: TObject);
    procedure execExtractDir(Sender: TObject);
    procedure execExtractSelected(Sender: TObject);
    procedure execGoToRoot(Sender: TObject);
    procedure execImportDir(Sender: TObject);
    procedure execImportFile(Sender: TObject);
    procedure execInverse(Sender: TObject);
    procedure execMark(Sender: TObject);
    procedure execNewDir(Sender: TObject);
    procedure execNewFile(Sender: TObject);
    procedure execRefreshList(Sender: TObject);
    procedure execRename(Sender: TObject);
    procedure execSelectAll(Sender: TObject);
    procedure execUndo(Sender: TObject);
    procedure execView(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SetPanelInactive(Sender: TObject);
    procedure SetPanelActive  (Sender: TObject);

    procedure lvfeFullAfterFilter(Sender: TObject);
    procedure lvListContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure DoListDblClick  (Sender: TObject);
    procedure DoListKeyDown   (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lvListCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvListItemChecked(Sender: TObject; Item: TListItem);
    procedure lvListSelectItem (Sender:TObject; Item:TListItem; Selected:Boolean);
    procedure lvListCompare    (Sender:TObject; Item1,Item2:TListItem; Data:Integer; var Compare:Integer);
    procedure lvListShowHint   (Sender:TObject; HintInfo:PHintInfo);
    procedure AddListRow(aidx:integer);

    procedure sbColumnsClick(Sender: TObject);
    procedure sbFilterClick (Sender: TObject);
    procedure sbFullClick   (Sender: TObject);

    procedure DoTreeKeyDown  (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sbCollapseClick(Sender: TObject);
    procedure sbTreeClick    (Sender: TObject);
    procedure tvTreeContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure tvTreeDblClick (Sender: TObject);
    procedure tvTreeSelectionChanged(Sender: TObject);
  private
    fmPreview :TForm;
    fmLog     :TForm;
    fmSettings:TForm;
    FOnChange :TRGOnChange;
    FOnType   :TRGOnPanelType;
    FOnExecute:TRGOnExecute;
    FShell    :TRGController;
    FShellPath:AnsiString;
    FPanelType:integer;
    FPopupNode: TTreeNode;

    procedure AddBranch(aroot:TTreeNode; adir:integer);
    procedure BuildShellRootList;
//    procedure SelectTreePath(adir:integer);
//    procedure FillTree      (adir:integer);
//    procedure FillList      (adir:integer);
    procedure FillFullList();
    procedure FillShellList(const aitem:AnsiString);
    function GetPathFromNode(aNode: TTreeNode): string;
    procedure ShowLog();
    procedure ShowSettings();

    procedure SetPanelPath(const apath:AnsiString);
    procedure ShowHideColumn(acol:integer; ashow:boolean);
    function  IsParentDirSelected():boolean;
    procedure SelectFile(aidx:integer);
    procedure SelectInList(afirst:boolean);

    procedure SelectLine();
    procedure SelectAll (ainverse:boolean=false);

    procedure ProcessTreeEvent(aidx:integer; aevent:integer);
    procedure ProcessListEvent(aidx:integer; aevent:integer);

{$I act.inc}
    
    function OnChangeDefault(actrl:pointer; idx:integer; aevent:integer):integer;
    function OnPanelTypeDef (apanel:TForm; atype:integer; abefore:boolean):integer;
    function OnExecuteDef   (actrl:PRGController; aidx:integer):integer;
    procedure SetOnExecute  (aproc:TRGOnExecute);
    procedure SetOnPanelType(aproc:TRGOnPanelType);
//    function  GetColumnState(acol:integer):boolean;

  public
    Ctrl:PRGController;
    ListIndex:integer; // index in (Dirs:array [0..15] of TDirListElement)

    procedure FillTree;
    procedure FillList(adir:integer);

{
  Directory must not have same name as file too. No case-sensitive
  Return file index (-1 if not found)
  Why here, not in Ctrl? coz we search in current dir only
  OR we can use SearchFile (active dir+name)
}
    function  IsNameExists(const aname:AnsiString):integer;
    function  GetOppositePanel():TPanelForm;
    procedure SetPanelType(atype: integer);
    function  GetPanelType    ():integer;
    function  GetSelectedFile ():integer;
    function  GetSelectionList(var arr:TIntegerDynArray):integer;
    procedure FillCombo(aremove:integer=0; arebuild:boolean=true); // enough for 2 panels

    procedure SetColumnState(acol:integer; ashow:boolean);
    procedure SetCtrl(actrl:PRGController);
    procedure SelectTreePath(adir:integer);

    procedure ShowPreview(actrl:PRGController; aidx:integer);
    procedure UpdatePreview(aidx: integer; actrl: PRGController; aList: integer);

    property  OnChange   :TRGOnChange    read FOnChange  write FOnChange;
    property  OnPanelType:TRGOnPanelType read FOnType    write SetOnPanelType; // FOnType;
    property  OnExecute  :TRGOnExecute   read FOnExecute write SetOnExecute;   // FOnExecute;
    property  PanelType:integer read GetPanelType write SetPanelType;
    property  ShowCol[acol:integer]:boolean {read GetColState} write ShowHideColumn;
    property  ShellPath  :AnsiString     read FShellPath;
  end;

var
  PanelForm: TPanelForm;

const
  colName = 0;
  colExt  = 1;
  colType = 2;
  colSize = 3;
  colPack = 4;
  colTime = 5;
  colAttr = 6; // Attrib (file state) not used atm

const
  panelUnknown   = -1;
  panelList      = 0;
  panelView      = 1;
  panelTree      = 2;
  panelShell     = 3;
  panelShellTree = 4;
  panelLog       = 5;
  panelSettings  = 6;


implementation

{$R *.lfm}

uses
  LCLType,
  LCLIntf,
  FileUtil,
  Clipbrd,
{$IFDEF Windows}
  Windows,
{$ENDIF}
  RGFileType,
  RGFile,
  fmFilter,
//  fmAsk,
  fmAskNew,
  fmComboDiff,
  fmLog,
  fmCorecfg,

  RGGUI.Core,
  RGGUI.Shared,
  RGPreview;


{$UNDEF Interface}

const
  ptView   = -1;
  ptShell  = -2;
  ptLog    = -3;
  ptConfig = -4;

resourcestring
  rsPreview = '~~Preview';
  rsShell   = '~~Shell';
  rsLog     = '~~Log';
  rsConfig  = '~~Settings';

{ TPanelForm }

{$I act.inc}

{%REGION NotVisual}
procedure TPanelForm.SetCtrl(actrl:PRGController);
//var lidx:integer;
begin
  Ctrl:=actrl;
  if self=Panels[ActivePanel] then
    ActiveCtrl:=Ctrl;
{
  if Ctrl<>actrl then
  begin
    lidx:=GetCtrlIndex(actrl);
    if lidx<0 then
      Ctrl:=nil
    else
    begin
      Ctrl:=actrl;
      with CtrlList[lidx] do
      begin
        if ListIndex<0 then ListIndex:=0;
//        if Dirs[ListIndex].path<0 then Dirs[ListIndex].path:=0;
//        FillList(Dirs[ListIndex].path);
      end;
    end;
    //!!
    if self=Panels[ActivePanel] then
      ActiveCtrl:=Ctrl;
  end;
}
end;

function TPanelForm.GetOppositePanel():TPanelForm;
begin
  result:=nil;
  if PanelCount=2 then
  begin
         if Panels[0]=Self then result:=TPanelForm(Panels[1])
    else if Panels[1]=Self then result:=TPanelForm(Panels[0]);
  end;
end;

procedure TPanelForm.SetPanelActive(Sender: TObject);
var
  i:integer;
begin
//  RGLog.Add('Enter list '+HexStr(Self));
  for i:=0 to PanelCount-1 do
  begin
    if Panels[i]=Self then
    begin
      if ActivePanel<>i then
      begin
        ActivePanel:=i;
        //!! event for active ctrl must be here
      end;
      break;
    end;
  end;
end;

procedure TPanelForm.SetPanelInactive(Sender: TObject);
begin
//  RGLog.Add('Leave list '+HexStr(Self));
end;


function TPanelForm.IsNameExists(const aname:AnsiString):integer;
begin
  result:=Ctrl^.IsNameExists(GetActiveDir(Ctrl,ListIndex),aname);
end;

{%ENDREGION NotVisual}

function TPanelForm.OnExecuteDef(actrl:PRGController; aidx:integer):integer;
begin
  result:=0;
end;

function TPanelForm.OnPanelTypeDef(apanel:TForm; atype:integer; abefore:boolean):integer;
begin
  result:=atype;
end;

procedure TPanelForm.SetOnExecute(aproc:TRGOnExecute);
begin
  if aproc=nil then
    FOnExecute:=@OnExecuteDef
  else
    FOnExecute:=aproc;
end;

procedure TPanelForm.SetOnPanelType(aproc:TRGOnPanelType);
begin
  if aproc=nil then
    FOnType:=@OnPanelTypeDef
  else
    FOnType:=aproc;
end;

function TPanelForm.GetPanelType():integer; inline;
begin
  result:=FPanelType;
end;

procedure TPanelForm.SetPanelType(atype:integer);
begin
  atype:=OnPanelType(Self,atype,true);
  if FPanelType=atype then exit;

  FPanelType:=atype;

  sbFull.Down:=false;
  lvfeFull.Visible:=false;
  sbFilter.Visible:=false;

  case FPanelType of
    panelList: begin
      pnlTopList.Visible:=true;
      pnlTopTree.Visible:=false;
      pnlPath   .Visible:=true;

      sbFull .Visible:=true;
      sbTree .Visible:=true;
      lvList .Visible:=true;
      tvShell.Visible:=false;
      tvTree .Visible:=false;
    end;

    panelView: begin
      AddFileEventHandler(@UpdatePreview);

      pnlTopList.Visible:=false;
      pnlTopTree.Visible:=false;
      pnlPath   .Visible:=false;

      sbTree .Visible:=false;
      lvList .Visible:=false;
      tvShell.Visible:=false;
      tvTree .Visible:=false;
    end;

    panelTree: begin
      pnlTopList.Visible:=false;
      pnlTopTree.Visible:=true;
      pnlPath   .Visible:=true;

      sbTree .Visible:=true;
      lvList .Visible:=false;
      tvShell.Visible:=false;
      tvTree .Visible:=true;
      tfeTree.Filter:='';

      FillTree();
      if tvTree.Showing then
        tvTree.SetFocus;
    end;

    panelShell: begin
      pnlTopList.Visible:=true;
      pnlTopTree.Visible:=false;
      pnlPath   .Visible:=true;

      sbFull .Visible:=false;
      sbTree .Visible:=true;
      lvList .Visible:=true;
      tvShell.Visible:=false;
      tvTree .Visible:=false;
    end;

    panelShellTree: begin
      pnlTopList.Visible:=false;
      pnlTopTree.Visible:=true;
      pnlPath   .Visible:=true;

      sbTree .Visible:=true;
      lvList .Visible:=false;
      tvShell.Visible:=true;
      tvTree .Visible:=false;

      tvShell.Path:=FShellPath;
      if tvShell.Showing then
        tvShell.SetFocus;
    end;

    panelLog: begin
      pnlTopList.Visible:=false;
      pnlTopTree.Visible:=false;
      pnlPath   .Visible:=false;

      sbTree .Visible:=false;
      lvList .Visible:=false;
      tvShell.Visible:=false;
      tvTree .Visible:=false;
    end;

    panelSettings: begin
      pnlTopList.Visible:=false;
      pnlTopTree.Visible:=false;
      pnlPath   .Visible:=false;

      sbTree .Visible:=false;
      lvList .Visible:=false;
      tvShell.Visible:=false;
      tvTree .Visible:=false;
    end;
  end;

  OnPanelType(Self,atype,false);
end;

procedure TPanelForm.cbContentChange(Sender: TObject);
var
  lpanel:TPanelForm;
  lctrl:IntPtr;
begin
  SetPanelActive(self);

  lctrl:=IntPtr(cbContent.Items.Objects[cbContent.ItemIndex]);

  if lctrl<>ptView then
  begin
    if fmPreview<>nil then
    begin
      fmPreview.Visible:=false;
      fmPreview.Free;
      fmPreview:=nil;
    end;
  end;

  if lctrl<>ptLog then
  begin
    if fmLog<>nil then
    begin
      fmLog.Free;
      fmLog:=nil;
    end;
  end;

  if lctrl<>ptConfig then
  begin
    if fmSettings<>nil then
      fmSettings.Hide;
{
    if fmSettings<>nil then
    begin
      fmSettings.Free;
      fmSettings:=nil;
    end;
}
  end;

  if lctrl=ptView then
  begin
//    SetCtrl(lpanel.Ctrl);
    SetPanelType(panelView);
  end

  else if lctrl=ptLog then
  begin
    SetPanelType(panelLog);
    if GetPanelType()=panelLog then ShowLog();
  end

  else if lctrl=ptConfig then
  begin
    SetPanelType(panelSettings);
    if GetPanelType()=panelSettings then ShowSettings();
  end

  else if lctrl=ptShell then
  begin
    Ctrl:=@FShell;
    if not sbTree.Down {GetPanelType()=panelShell} then
//    if GetPanelType()=panelShell then
    begin
      SetPanelType(panelShell);
      FillShellList('');
    end
    else
    begin
      SetPanelType(panelShellTree);
    end
  end

  else
  begin
    SetCtrl(PRGController(lctrl));
    if not sbTree.Down {GetPanelType()=panelList} then
    begin
      SetPanelType(panelList);
      FillList (GetActiveDir(Ctrl,ListIndex));
      if (ListIndex=ActivePanel) and lvList.Showing then lvList.SetFocus;
    end
    else
    begin
      SetPanelType(panelTree);
//      FillTree();
    end;
  end;
end;

procedure TPanelForm.FillCombo(aremove:integer=0; arebuild:boolean=true);
var
  lctrl:IntPtr;
  i,lidx:integer;
begin
  // save current content
  if (CtrlCount>0) and (Self=Panels[ActivePanel]) then
    lctrl:=IntPtr(CtrlList[CtrlCount-1].Ctrl)
  else
  begin
    lidx:=cbContent.ItemIndex;
    if lidx>=0 then
    begin
      lctrl:=IntPtr(cbContent.Items.Objects[lidx]);
    end
    else
      lctrl:=10000;
  end;

  cbContent.Clear;
  cbContent.Sorted:=true;

  // fill with sorting
  for i:=0 to CtrlCount-1 do
    cbContent.AddItem(CtrlList[i].Ctrl^.Pak.Name,TObject(CtrlList[i].Ctrl));

  cbContent.Sorted:=false;
  cbContent.AddItem(rsShell,TObject(ptShell));
  if aremove<>panelLog      then cbContent.AddItem(rsLog    ,TObject(ptLog));
  if aremove<>panelSettings then cbContent.AddItem(rsConfig ,TObject(ptConfig));
  if aremove<>panelView     then cbContent.AddItem(rsPreview,TObject(ptView));

  // Active panel: choose last used Controller
  // Inactive: choose previous, no need to rebuild
  // rebuild 
  lidx:=0;
  for i:=0 to cbContent.Items.Count-1 do
  begin
    if lctrl=IntPtr(cbContent.Items.Objects[i]) then
    begin
      lidx:=i;
      if Self<>Panels[ActivePanel] then
        arebuild:=false;
      break;
    end;
  end;
  cbContent.ItemIndex:=lidx;
  if arebuild then cbContentChange(cbContent);
end;

procedure TPanelForm.ShowLog();
begin
  if fmLog=nil then
  begin
    fmLog:=TfmLogForm.Create(Self);
    with TfmLogForm(fmLog) do
    begin
      BorderStyle:=bsNone;
      Align      :=alClient;
      Parent     :=Self;
      memLog.Text:=RGLog.Text;
      Visible    :=true;
    end;
  end;
end;

procedure TPanelForm.ShowSettings();
begin
  if fmSettings=nil then
  begin
    fmSettings:=TCoreCfgForm.Create(Self);
    with TCoreCfgForm(fmSettings) do
    begin
      BorderStyle:=bsNone;
      Align      :=alClient;
      Parent     :=Self;
//      Visible    :=true;
    end;
  end;
  TCoreCfgForm(fmSettings).FillSettings;
  fmSettings.Show;
end;

procedure TPanelForm.ShowPreview(actrl:PRGController; aidx:integer);
begin
  if fmPreview<>nil then
  begin
    fmPreview.Visible:=false;
    fmPreview.Free;
    fmPreview:=nil;
  end;
  if (actrl<>nil) and (aidx>=0) then
  begin
    if actrl^.Files[aidx]^.ftype<>typeDirectory then
    begin
      fmPreview:=MakePreview(actrl^,aidx,false);
      if fmPreview<>nil then
      begin
        fmPreview.BorderStyle:=bsNone;
        fmPreview.Align      :=alClient;
        fmPreview.Parent     :=Self;
        fmPreview.Visible    :=true;
      end;
    end;
  end;
end;

procedure TPanelForm.SetPanelPath(const apath:AnsiString); inline;
begin
  pnlPath.Caption:=apath;
end;

procedure TPanelForm.sbColumnsClick(Sender: TObject);
begin
  mnuColumns.PopUp;
end;

procedure TPanelForm.SetColumnState(acol:integer; ashow:boolean);
begin
  if FPanelType in [panelList,panelShell] then
  begin
         if acol=colType then miColType  .Checked:=ashow
    else if acol=colSize then miColSize  .Checked:=ashow
    else if acol=colPack then miColPacked.Checked:=ashow
    else if acol=colTime then miColTime  .Checked:=ashow
    else if acol=colAttr then miColAttr  .Checked:=ashow
    else exit;
    ShowHideColumn(acol, ashow);
  end;
end;

procedure TPanelForm.ColMenuClick(Sender: TObject);
var
  mi: TMenuItem;
begin
  mi:=Sender as TMenuItem;
  mi.Checked:=not mi.Checked;

       if Sender=miColType   then ShowHideColumn(colType,mi.Checked)
  else if Sender=miColSize   then ShowHideColumn(colSize,mi.Checked)
  else if Sender=miColPacked then ShowHideColumn(colPack,mi.Checked)
  else if Sender=miColTime   then ShowHideColumn(colTime,mi.Checked)
  else if Sender=miColAttr   then ShowHideColumn(colAttr,mi.Checked);
end;

procedure TPanelForm.DoListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  lform:TForm;
begin
  // DblClick, Change directory
  if (Key=VK_RETURN) and (Shift=[]) then
  begin
    DoListDblClick(Sender);
  end
  else if (Key=VK_R) and (Shift=[ssCtrl]) then
  begin
    execRefreshList(nil);
  end
  else if ((Key=VK_SPACE) or (Key=VK_INSERT)) and (Shift=[]) then
  begin
    SelectLine();
{
    Key:=VK_DOWN;
    exit;
}
  end
  // to first file
  else if (Key=VK_LEFT) and (Shift=[]) then
  begin
//    ldir:=GetActiveDir(Ctrl,ListIndex);
//    if ldir>=0 then SelectFile(Ctrl^.Dirs[ldir].first);
    SelectInList(true);
  end
  // to last file
  else if (Key=VK_RIGHT) and (Shift=[]) then
  begin
//    ldir:=GetActiveDir(Ctrl,ListIndex);
//    if ldir>=0 then SelectFile(Ctrl^.Dirs[ldir].last);
    SelectInList(false);
  end
  // Inverse selection
  else if (Key=VK_MULTIPLY) and (Shift=[]) then
  begin
    SelectAll(true);
  end
  // [Un] Select All
  else if (Key=VK_A) and (Shift=[ssCtrl]) then
  begin
    SelectAll(false);
  end
  // go to root
  else if (Key=VK_OEM_5) and (Shift=[ssCtrl]) then
  begin
    execGoToRoot(nil);
  end
  // Rename
  else if (Key=VK_F2) and (Shift=[]) then
  begin
    execRename(nil);
  end
  // Preview in separate window
  else if (Key=VK_F3) then
  begin
    lform:=MakePreview(Ctrl^,GetSelectedFile(),(Shift<>[]));
    if lform<>nil then lform.Show;
  end
  // Create New file
  else if ((Key=VK_N ) and (Shift=[ssCtrl])) or
          ((Key=VK_F4) and (Shift=[])) then
  begin
    execNewFile(nil);
  end
{
  // Copy file/dir [opposite panel]
  else if (Key=VK_F5) and (Shift=[]) then
  begin
    Copy();
  end
}
  // Move file/dir [opposite panel]
  else if (Key=VK_F6) and (Shift=[]) then
  begin
//    Move();
  end
  // Create new dir
  else if (Key=VK_F7) and (Shift=[]) then
  begin
    execNewDir(nil);
  end
  // Delete [restore?] file/dir
  else if (Key=VK_DELETE) or (Key=VK_F8) then
  begin
    if Shift=[ssAlt] then
    begin
      Delete(0);
    end
    else if Shift=[ssCtrl] then
    begin
      Ctrl^.RemoveUpdate(GetSelectedFile());
    end
    else if (Shift=[]) then
    begin
      if not IsParentDirSelected() then
        Ctrl^.MarkToRemove(GetSelectedFile())
    end
    else
      exit;
  end
  // Extract
  else if (Key=VK_F9) and (Shift=[]) then
  begin
    execExtractSelected(nil);
  end
  else
    exit;
  Key:=0;
end;

procedure TPanelForm.DoTreeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // DblClick, Change directory
  if (Key=VK_RETURN) and (Shift=[]) then
  begin
    tvTreeDblClick(Sender);
  end
  else if (Key=VK_R) and (Shift=[ssCtrl]) then
  begin
    execRefreshList(nil);
  end
  // Rename
  else if (Key=VK_F2) and (Shift=[]) then
  begin
    execRename(nil);
  end
  // Create New
  else if ((Key=VK_N ) and (Shift=[ssCtrl])) or
          (((Key=VK_F7) or (Key=VK_F4)) and (Shift=[])) then
  begin
    execNewDir(nil);
  end
{
  // Copy file/dir [opposite panel]
  else if (Key=VK_F5) and (Shift=[]) then
  begin
    Copy()
  end
}
  // Move file/dir [opposite panel]
  else if (Key=VK_F6) and (Shift=[]) then
  begin
  end
  // Delete [restore?] file/dir
  else if (Key=VK_DELETE) or (Key=VK_F8) then
  begin
    if Shift=[ssAlt] then
    begin
      Delete(0);
    end
    else if Shift=[ssCtrl] then
    begin
      Delete(2);
    end
    else if (Shift=[]) then
    begin
      Delete(1);
    end
    else
      exit;
  end
  // Extract
  else if (Key=VK_F9) and (Shift=[]) then
  begin
    ExtractDir(Ctrl,GetActiveDir(Ctrl,ListIndex),true,false);
  end
  else
    exit;
  Key:=0;
end;

// right now - just directory changing
procedure TPanelForm.DoListDblClick(Sender: TObject);
var
  ls:AnsiString;
  lidx:integer;
begin
  lidx:=GetSelectedFile();
  if lidx>=0 then
  begin
    with Ctrl^.Files[lidx]^ do
    begin
      if (ftype=typeDirectory) and
         (action<>act_delete) then
      begin
        if GetPanelType()=panelShell then
        begin
          FShellPath:=FShellPath+lvList.Selected.Caption;
          FillShellList('');
        end
        else
          FillList(Ctrl^.AsDir(lidx));
      end
      else if (ftype=typeUnknown) then
      begin
        FOnExecute(Ctrl,lidx);
      end;
    end;
  end
  // Parent dir
  else if GetPanelType()=panelShell then
  begin
    ls:=ExtractName(FShellPath);
    FShellPath:=ExtractPath(FShellPath);
    FillShellList(ls);
  end
  // ROOT dir
  else
    FillList(0);
end;

procedure TPanelForm.BuildShellRootList;
{$IF defined(windows) and not defined(wince)}
var
  r: LongWord;
  Drives: array[0..128] of char;
  pDrive: PChar;
begin
  r := GetLogicalDriveStrings(SizeOf(Drives), Drives);
  if r = 0 then Exit;
  if r > SizeOf(Drives) then Exit;
  pDrive := Drives;
  while pDrive^ <> #0 do
  begin
    Ctrl^.NewDir({ExcludeTrailingBackslash}(pDrive));
    Inc(pDrive, 4);
  end;
{$ELSE}
begin
  Ctrl^.NewDir('/');
{$ENDIF}
end;

procedure TPanelForm.sbFilterClick(Sender: TObject);
begin
  if fmFilterForm=nil then
  begin
    fmFilterForm:=TFilterForm.Create(Self);
  end;
  fmFilterForm.ShowOnTop;
end;

function TPanelForm.GetSelectedFile():integer;
begin
  if GetPanelType()=panelTree then
    result:=Ctrl^.AsFile(IntPtr(tvTree.Selected.Data))
  else if lvList.ItemIndex>=0 then
    result:=IntPtr(lvList.Items[lvList.ItemIndex].Data)
  else
    result:=-1;
end;

{$I lv.inc}

{$I tree.inc}

procedure TPanelForm.UpdatePreview(aidx:integer; actrl:PRGController; aList:integer);
begin
  if (GetPanelType()=panelView) {and (aList<>ListIndex)} then
    ShowPreview(actrl,aidx);
end;

procedure TPanelForm.FormCreate(Sender: TObject);
begin
  FPanelType:=panelUnknown;
  FOnChange:=@OnChangeDefault;
  FShell.Init(true);
  FShellPath:=ExtractPath(ParamStr(0));

  lvList.SortColumn:=colExt;
  FOnType   :=@OnPanelTypeDef;
  FOnExecute:=@OnExecuteDef;
end;

procedure TPanelForm.FormDestroy(Sender: TObject);
begin
  FShell.Free;
end;

function TPanelForm.OnChangeDefault(actrl:pointer; idx:integer; aevent:integer):integer;
var
  ltype:integer;
begin
  result:=1;
  if Ctrl=actrl then
  begin
    ltype:=GetPanelType();
    if ltype=panelTree then ProcessTreeEvent(idx, aevent);
    if ltype=panelList then ProcessListEvent(idx, aevent);
  end;
end;

end.

