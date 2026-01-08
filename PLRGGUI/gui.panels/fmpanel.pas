unit fmPanel;

{$mode ObjFPC}{$H+}

interface

uses
  uni_profiler,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Buttons, TreeFilterEdit, ListViewFilterEdit,
  RGGlobal, RGCtrl;


{$DEFINE Interface}

type

  { TPanelForm }

  TPanelForm = class(TForm)
    cbContent: TComboBox;
    lvfeFull: TListViewFilterEdit;
    sbFilter: TSpeedButton;
    sbFull: TSpeedButton;
    tfeTree: TTreeFilterEdit;
    ilPanel: TImageList;
    lblPath: TLabel;
    lvList: TListView;
    pnlTop: TPanel;
    sbAttr: TSpeedButton;
    sbType: TSpeedButton;
    sbTime: TSpeedButton;
    sbSize: TSpeedButton;
    sbCollapse: TSpeedButton;
    sbTree: TSpeedButton;
    tvTree: TTreeView;

    procedure cbContentChange(Sender: TObject);

    procedure DoListDblClick  (Sender: TObject);
    procedure DoListKeyDown   (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure lvfeFullAfterFilter(Sender: TObject);
    procedure SetPanelActive  (Sender: TObject);

    procedure lvListCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvListCompare   (Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure lvListShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure AddListRow(aidx:integer);

    procedure sbColumnsClick(Sender: TObject);
    procedure sbFilterClick(Sender: TObject);
    procedure sbFullClick(Sender: TObject);

    procedure DoTreeKeyDown  (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sbCollapseClick(Sender: TObject);
    procedure sbTreeClick    (Sender: TObject);
    procedure tvTreeDblClick (Sender: TObject);
    procedure tvTreeSelectionChanged(Sender: TObject);
  private
    fmPreview:TForm;
    FOnChange:TRGOnChange;

    procedure AddBranch(aroot:TTreeNode; adir:integer);
    procedure FillTree      (adir:integer);
    procedure SelectTreePath(adir:integer);
    procedure FillList      (adir:integer);
    procedure FillFullList();

    procedure ShowHideColumn(acol:integer; ashow:boolean);
    procedure UnpackSelected();
    function  GetSelectionList(var arr:TIntegerDynArray):integer;
    function  IsParentDirSelected():boolean;
    procedure SelectFile(aidx:integer);
    procedure SelectInList(afirst:boolean);

    procedure SelectLine();
    procedure SelectAll();

    procedure ProcessTreeEvent(aidx:integer; aevent:integer);
    procedure ProcessListEvent(aidx:integer; aevent:integer);

{$I act.inc}
    
    function OnChangeDefault(actrl:pointer; idx:integer; aevent:integer):integer;
  public
    Ctrl:PRGController;
    ListIndex:integer; // index in (Dirs:array [0..15] of TDirListElement)

    procedure SetupView(atype:integer);

{
  Directory must not have same name as file too. No case-sensitive
  Return file index (-1 if not found)
  Why here, not in Ctrl? coz we search in current dir only
  OR we can use SearchFile (active dir+name)
}
    function  IsNameExists(const aname:AnsiString):integer;
    function  GetOppositePanel():TPanelForm;
    function  GetPanelType    ():integer;
    function  GetSelectedFile ():integer;
    procedure FillCombo();
    procedure SetColumnState(acol:integer; ashow:boolean);
    procedure SetCtrl(actrl:PRGController);
    procedure ShowPreview(actrl:PRGController; aidx:integer);

    procedure UpdatePreview(aidx: integer; actrl: PRGController; aList: integer);

    property  OnChange:TRGOnChange read FOnChange write FOnChange;
  end;

var
  PanelForm: TPanelForm;

const
  colName = 0;
  colExt  = 1;
  colType = 2;
  colSize = 3;
  colTime = 4;
  colAttr = 5; // Attrib (file state) not used atm

const
  panelList = 0;
  panelView = 1;
  panelTree = 2;


implementation

{$R *.lfm}

uses
  LCLType,
  LCLIntf,

  RGFileType,
  fmFilter,

  RGGUI.Core,
  RGGUI.Shared,
  RGPreview;


{$UNDEF Interface}

const
  ptView = -1;

resourcestring
  rsPreview = '~~Preview';

{ TPanelForm }

{$I act.inc}

{%REGION NotVisual}
procedure TPanelForm.SetCtrl(actrl:PRGController);
var
  lidx:integer;
begin
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
    begin
      if Ctrl<>nil then ActiveCtrl:=GetCtrlIndex(Ctrl)
      else ActiveCtrl:=-1;
    end;
  end;
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
  for i:=0 to PanelCount-1 do
  begin
    if Panels[i]=Self then
    begin
      ActivePanel:=i;
      break;
    end;
  end;
end;

function TPanelForm.IsNameExists(const aname:AnsiString):integer;
begin
  result:=Ctrl^.IsNameExists(GetActiveDir(Ctrl,ListIndex),aname);
end;

{%ENDREGION NotVisual}

// Use combobox selection for type
function TPanelForm.GetPanelType():integer;
var
  lidx:integer;
begin
  result:=panelList;
  lidx:=cbContent.ItemIndex;
  if lidx>=0 then
  begin
    lidx:=IntPtr(cbContent.Items.Objects[lidx]);
    if lidx=ptView then
      result:=panelView
    else if {sbTree.visible and }sbTree.Down then
      result:=panelTree;
  end;
end;

procedure TPanelForm.SetupView(atype:integer);
begin
  sbFull.Down:=false;
  lvfeFull.Visible:=false;
  sbFilter.Visible:=false;

  case atype of
    panelList: begin
//RemoveEventHandler(@UpdatePreview);
      lvList.Visible:=true;
      sbType.Visible:=true;
      sbTime.Visible:=true;
      sbSize.Visible:=true;
      sbAttr.Visible:=true;
      sbFull.Visible:=true;

      tvTree    .Visible:=false;
      tfeTree   .Visible:=false;
      sbCollapse.Visible:=false;
      sbTree    .Visible:=true;
    end;

    panelView: begin
//AddFileEventHandler(@UpdatePreview);
      
      lvList.Visible:=false;
      sbType.Visible:=false;
      sbTime.Visible:=false;
      sbSize.Visible:=false;
      sbAttr.Visible:=false;
      sbFull.Visible:=false;

      tvTree    .Visible:=false;
      tfeTree   .Visible:=false;
      sbCollapse.Visible:=false;
      sbTree    .Visible:=false;
    end;

    panelTree: begin
//RemoveEventHandler(@UpdatePreview);
      lvList.Visible:=false;
      sbType.Visible:=false;
      sbTime.Visible:=false;
      sbSize.Visible:=false;
      sbAttr.Visible:=false;
      sbFull.Visible:=false;

      tfeTree.Filter:='';
      tvTree    .Visible:=true;
      tfeTree   .Visible:=true;
      sbCollapse.Visible:=true;
      sbTree    .Visible:=true;
    end;
  end;
end;

procedure TPanelForm.cbContentChange(Sender: TObject);
var
  lpanel:TPanelForm;
  lidx,ltype:integer;
begin
  SetPanelActive(self);

  if fmPreview<>nil then
  begin
    fmPreview.Free;
    fmPreview:=nil;
  end;

  lpanel:=GetOppositePanel();
  ltype :=lpanel.GetPanelType();

  lidx:=IntPtr(cbContent.Items.Objects[cbContent.ItemIndex]);
  if lidx=ptView then
  begin
//    SetCtrl(lpanel.Ctrl);
    SetupView(panelView);
    if ltype=panelList then
    begin
      ShowPreview(lpanel.Ctrl,lpanel.GetSelectedFile());
    end;
  end
  else
  begin
    SetCtrl(CtrlList[lidx].Ctrl);
    if GetPanelType()=panelList then
    begin
      SetupView(panelList);
      FillList (GetActiveDir(Ctrl,ListIndex));
      if (ListIndex=ActivePanel) and Application.Active then lvList.SetFocus;
    end
    else
    begin
      SetupView(panelTree);
      FillTree (GetActiveDir(Ctrl,ListIndex));
    end;

    if ltype=panelView then
    begin
      lpanel.ShowPreview(Ctrl,GetSelectedFile());
    end;
  end;
end;

procedure TPanelForm.FillCombo();
var
  i,lold,lidx:integer;
  lobj:integer;
begin
  // save current content
  lidx:=cbContent.ItemIndex;
  if lidx>=0 then
  begin
    lobj:=IntPtr(cbContent.Items.Objects[lidx]);
  end
  else
    lobj:=10000;

  cbContent.Clear;
  cbContent.Sorted:=true;

  // fill with sorting
  for i:=0 to CtrlCount-1 do
    cbContent.AddItem(CtrlList[i].Ctrl^.Pak.Name,TObject(IntPtr(i)));
  cbContent.Sorted:=false;
  cbContent.AddItem(rsPreview,TObject(ptView));

  // Active panel: choose last used Controller
  if Self=Panels[ActivePanel] then
  begin
    lidx:=0;
    for i:=0 to cbContent.Items.Count-1 do
    begin
      if (CtrlCount-1)=IntPtr(cbContent.Items.Objects[i]) then
      begin
        lidx:=i;
        break;
      end;
    end;
    cbContent.ItemIndex:=lidx;
    cbContentChange(cbContent);
  end
  // Inactive panel, keep used Controller (if was)
  else
  begin
    lold:=-1;
    if lobj=ptView then cbContent.ItemIndex:=cbContent.Items.Count-1
    else
    begin
      lidx:=0;
      for i:=0 to cbContent.Items.Count-1 do
      begin
        if lobj=IntPtr(cbContent.Items.Objects[i]) then
        begin
          lidx:=i;
          lold:=i;
          break;
        end;
      end;
      cbContent.ItemIndex:=lidx;
    end;
    if lold<0 then cbContentChange(cbContent);
  end;
end;

procedure TPanelForm.ShowPreview(actrl:PRGController; aidx:integer);
begin
  fmPreview.Free;
  fmPreview:=nil;
  if (actrl<>nil) and (aidx>=0) then
  begin
    if actrl^.Files[aidx]^.ftype<>typeDirectory then
    begin
      fmPreview:=MakePreview(actrl^,aidx);
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

procedure TPanelForm.SetColumnState(acol:integer; ashow:boolean);
begin
       if acol=colType then sbType.Down:=ashow
  else if acol=colTime then sbTime.Down:=ashow
  else if acol=colSize then sbSize.Down:=ashow
  else if acol=colAttr then sbAttr.Down:=ashow
end;

procedure TPanelForm.sbColumnsClick(Sender: TObject);
begin
//  ldohide:=(Sender as TSpeedButton).Up;
       if Sender=sbType then ShowHideColumn(colType,(Sender as TSpeedButton).Down)
  else if Sender=sbTime then ShowHideColumn(colTime,(Sender as TSpeedButton).Down)
  else if Sender=sbSize then ShowHideColumn(colSize,(Sender as TSpeedButton).Down)
  else if Sender=sbAttr then ShowHideColumn(colAttr,(Sender as TSpeedButton).Down);
end;

procedure TPanelForm.DoListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  lform:TForm;
  ldir:integer;
begin
  // DblClick, Change directory
  if (Key=VK_RETURN) and (Shift=[]) then
  begin
    DoListDblClick(Sender);
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
  // [Un] Select All
  else if (Key=VK_A) and (Shift=[ssCtrl]) then
  begin
    SelectAll();
  end
  // Rename
  else if (Key=VK_F2) and (Shift=[]) then
  begin
    Rename();
  end
  // Preview in separate window
  else if (Key=VK_F3) and (Shift=[]) then
  begin
    lform:=MakePreview(Ctrl^,GetSelectedFile());
    if lform<>nil then lform.Show;
  end
  // Create New file
  else if ((Key=VK_N ) and (Shift=[ssCtrl])) or
          ((Key=VK_F4) and (Shift=[])) then
  begin
    CreateNewFile();
  end
  // Copy file/dir [opposite panel]
  else if (Key=VK_F5) and (Shift=[]) then
  begin
//    Copy();
  end
  // Move file/dir [opposite panel]
  else if (Key=VK_F6) and (Shift=[]) then
  begin
//    Move();
  end
  // Create new dir
  else if (Key=VK_F7) and (Shift=[]) then
  begin
    CreateNewDir();
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
    UnpackSelected();
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
  // Rename
  else if (Key=VK_F2) and (Shift=[]) then
  begin
    Rename();
  end
  // Create New
  else if ((Key=VK_N ) and (Shift=[ssCtrl])) or
          (((Key=VK_F7) or (Key=VK_F4)) and (Shift=[])) then
  begin
    CreateNewDir();
  end
  // Copy file/dir [opposite panel]
  else if (Key=VK_F5) and (Shift=[]) then
  begin
  end
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
  end
  else
    exit;
  Key:=0;
end;

// right now - just directory changing
procedure TPanelForm.DoListDblClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=GetSelectedFile();
  if lidx>=0 then
  begin
    with Ctrl^.Files[lidx]^ do
      if (ftype=typeDirectory) and
         (action<>act_delete) then
        FillList(Ctrl^.AsDir(lidx));
  end
  // ROOT dir
  else
    FillList(0);
end;

procedure TPanelForm.UnpackSelected();
var
  ls:AnsiString;
  lselect:TIntegerDynArray;
  lcnt,i,lfile:integer;
begin
  lselect:=nil;
  lfile:=GetSelectionList(lselect);

  lcnt:=0;
  if lfile>=0 then
  begin
    if Ctrl^.IsDir(lfile) then
      lcnt:=ExtractDir(Ctrl,Ctrl^.AsDir(lfile),true)
    else
      if SaveFile(Ctrl,lfile) then lcnt:=1;
  end
  else
  begin
    for i:=0 to High(lselect) do
    begin
      lfile:=lselect[i];
      if Ctrl^.IsDir(lfile) then
        inc(lcnt,ExtractDir(Ctrl,Ctrl^.AsDir(lfile),true))
      else
        if SaveFile(Ctrl,lfile) then inc(lcnt);
    end;
  end;

  if lcnt=1 then
  begin
    if Ctrl^.IsDir(lfile) then ls:='Directory ' else ls:='File ';
    ShowMessage(ls+
          WideToStr(Ctrl^.PathOfFile(lfile))+
          WideToStr(Ctrl^.NameOfFile(lfile))+
          #13#10+rsUnpackSucc);
  end
  else if lcnt>1 then ShowMessage(IntToStr(lcnt)+rsFilesUnpackSucc);

  SetLength(lselect,0);
end;

procedure TPanelForm.sbFilterClick(Sender: TObject);
begin
  if fmFilterForm=nil then
  begin
    fmFilterForm:=TFilterForm.Create(Self);
  end;
  fmFilterForm.ShowOnTop;
end;

{$I lv.inc}

{$I tree.inc}

procedure TPanelForm.UpdatePreview(aidx:integer; actrl:PRGController; aList:integer);
{
var
  lpanel:TPanelForm;
begin
  lpanel:=GetOppositePanel();
  if (aList=lpanel.ListIndex) and (lpanel.GetPanelType()=panelList) then
}
begin
  if aList<>ListIndex then
    ShowPreview(actrl,aidx);
end;

procedure TPanelForm.FormCreate(Sender: TObject);
begin
  FOnChange:=@OnChangeDefault;

  lvList.SortColumn:=colExt;
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

