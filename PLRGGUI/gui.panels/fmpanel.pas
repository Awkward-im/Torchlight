unit fmPanel;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Buttons,
  rgglobal, rgctrl;

type

  { TPanelForm }

  TPanelForm = class(TForm)
    cbContent: TComboBox;
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
    procedure SetPanelActive  (Sender: TObject);

    procedure lvListCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvListCompare   (Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure lvListShowHint(Sender: TObject; HintInfo: PHintInfo);

    procedure sbColumnsClick(Sender: TObject);

    procedure DoTreeKeyDown  (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sbCollapseClick(Sender: TObject);
    procedure sbTreeClick    (Sender: TObject);
    procedure tvTreeDblClick (Sender: TObject);
    procedure tvTreeSelectionChanged(Sender: TObject);
  private
    fmPreview:TForm;

    procedure AddBranch(aroot:TTreeNode; adir:integer);
    procedure FillTree      (adir:integer);
    procedure SelectTreePath(adir:integer);
    procedure FillList      (adir:integer);

    procedure SetupView(atype:integer);

    procedure ShowHideColumn(acol:integer; ashow:boolean);
    procedure SelectLine();
    procedure UnpackSelected();
    function  GetSelectionList(var arr:TIntegerDynArray):integer;
    function  IsParentDirSelected():boolean;
  public
    Ctrl:PRGController;
    ListIndex:integer; // index in (Dirs:array [0..15] of TDirListElement)

    function  GetOppositePanel():TPanelForm;
    function  GetPanelType    ():integer;
    function  GetSelectedFile ():integer;
    procedure FillCombo();
    procedure SetColumnState(acol:integer; ashow:boolean);
    procedure SetCtrl(actrl:PRGController);
    procedure ShowPreview(actrl:PRGController; aidx:integer);

    procedure UpdatePreview(aidx: integer; actrl: PRGController; aList: integer);
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

  rgfiletype,

  rggui.core,
  rggui.shared,
  rgpreview;

const
  ptView = -1;

resourcestring
  rsPreview = '~~Preview';

{ TPanelForm }

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
  case atype of
    panelList: begin
//RemoveEventHandler(@UpdatePreview);
      lvList.Visible:=true;
      sbType.Visible:=true;
      sbTime.Visible:=true;
      sbSize.Visible:=true;
      sbAttr.Visible:=true;

      tvTree    .Visible:=false;
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

      tvTree    .Visible:=false;
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

      tvTree    .Visible:=true;
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

procedure TPanelForm.DoListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  lform:TForm;
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
  // Rename
  else if (Key=VK_F2) and (Shift=[]) then
  begin
  end
  // Preview in separate window
  else if (Key=VK_F3) and (Shift=[]) then
  begin
    lform:=MakePreview(Ctrl^,GetSelectedFile());
    if lform<>nil then lform.Show;
  end
  // Create New
  else if ((Key=VK_N ) and (Shift=[ssCtrl])) or
          ((Key=VK_F4) and (Shift=[])) then
  begin
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
    if Shift=[ssCtrl] then
    begin
      // restore
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
  end
  // Create New
  else if ((Key=VK_N ) and (Shift=[ssCtrl])) or
          ((Key=VK_F4) and (Shift=[])) then
  begin
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
    if Shift=[ssCtrl] then
    begin
      // restore
    end
    else if (Shift=[]) then
    begin
      Ctrl^.MarkToRemove(Ctrl^.AsFile(IntPtr(tvTree.Selected.Data)));
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
    if Ctrl^.Files[lidx]^.ftype=typeDirectory then
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

procedure TPanelForm.sbColumnsClick(Sender: TObject);
begin
//  ldohide:=(Sender as TSpeedButton).Up;
       if Sender=sbType then ShowHideColumn(colType,(Sender as TSpeedButton).Down)
  else if Sender=sbTime then ShowHideColumn(colTime,(Sender as TSpeedButton).Down)
  else if Sender=sbSize then ShowHideColumn(colSize,(Sender as TSpeedButton).Down)
  else if Sender=sbAttr then ShowHideColumn(colAttr,(Sender as TSpeedButton).Down);
end;

{$I lv.inc}

{%REGION Tree}
(*
function TPanelForm.GetPathFromNode(aNode:TTreeNode):string;
var
  ldir:integer;
begin
  ldir:=IntPtr(UIntPtr(aNode.Data));
  if ldir<0 then
    result:=''
  else
	  result:=Ctrl^.Dirs[ldir].Name;
{
  result:='';
  repeat
    result:=aNode.Text+cSep+result;
    aNode:=aNode.Parent;
  until aNode=nil;
}
end;

procedure TPanelForm.tvTreeContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
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

procedure TPanelForm.miTreeListClick(Sender: TObject);
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

procedure TPanelForm.AddNewDir(anode:TTreeNode; const apath:string);
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

procedure TPanelForm.miTreeNewClick(Sender: TObject);
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

procedure TPanelForm.miTreeDeleteClick(Sender: TObject);
var
  ldir:integer;
begin
  ldir:=IntPtr(UIntPtr(PopupNode.Data));
  FCtrl^.MarkToRemove(FCtrl^.AsFile(ldir));
  MarkTree(ldir,false);
end;

procedure TPanelForm.miTreeRestoreClick(Sender: TObject);
var
  ldir:integer;
begin
  ldir:=IntPtr(UIntPtr(PopupNode.Data));
  FCtrl^.RemoveUpdate(FCtrl^.AsFile(ldir));
  MarkTree(ldir,true);
end;

procedure TPanelForm.MarkTree(adir:integer; aEnable:boolean);
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
*)
procedure TPanelForm.SelectTreePath(adir:integer);
var
  i:integer;
begin
  if (tvTree.Selected<>nil) and (IntPtr(UIntPtr(tvTree.Selected.Data))=adir) then exit;

  for i:=0 to tvTree.Items.Count-1 do
  begin
    if IntPtr(UIntPtr(tvTree.Items[i].Data))=adir then
    begin
      tvTree.Select(tvTree.Items[i]);
      tvTree.MakeSelectionVisible();
      break;
    end;
  end;
  SetActiveDir(adir,Ctrl,ListIndex);
  lblPath.Caption:=Ctrl^.Dirs[adir].Name;
end;

procedure TPanelForm.sbCollapseClick(Sender: TObject);
begin
  tvTree.BeginUpdate;

  tvTree.FullCollapse;

  tvTree.Items[1].Expanded:=true;
  tvTree.Items[0].Expanded:=true;
  tvTree.EndUpdate;
end;

procedure TPanelForm.sbTreeClick(Sender: TObject);
begin
  SetPanelActive(self);

  if sbTree.Down then
  begin
    SetupView(panelTree);
    FillTree (GetActiveDir(Ctrl,ListIndex));
    tvTree.SetFocus;
  end
  else
  begin
    SetupView(panelList);
    FillList (GetActiveDir(Ctrl,ListIndex));
    lvList.SetFocus;
  end;
end;

procedure TPanelForm.tvTreeSelectionChanged(Sender: TObject);
var
  ldir:integer;
begin
  if tvTree.Selected<>nil then
  begin
    if tvTree.Selected<>tvTree.Items[0] then
    begin
      ldir:=IntPtr(tvTree.Selected.Data);
    end
    else
      ldir:=0;
    SetActiveDir(ldir,Ctrl,ListIndex);
    lblPath.Caption:=Ctrl^.Dirs[ldir].Name;
  end;
end;

procedure TPanelForm.tvTreeDblClick(Sender: TObject);
var
  ldir:integer;
begin
  if tvTree.Selected<>nil then
  begin
    if tvTree.Selected<>tvTree.Items[0] then
    begin
      ldir:=IntPtr(tvTree.Selected.Data);
    end
    else
      ldir:=0;
    SetActiveDir(ldir,Ctrl,ListIndex);

    sbTree.Down:=False;
    sbTreeClick(sbTree);
  end;
end;

procedure TPanelForm.AddBranch(aroot:TTreeNode; adir:integer);
var
  lnode:TTreeNode;
  ls:string;
  i:integer;
begin
  aroot.Data:=pointer(IntPtr(adir));
  if Ctrl^.GetFirstFile(i,adir) then
    repeat
      if Ctrl^.IsDir(i) then
      begin
        ls:=WideToStr(Ctrl^.NameOfFile(i));
        lnode:=tvTree.Items.AddChild(aroot,ls);
        AddBranch(lnode,Ctrl^.AsDir(i));
        if PRGCtrlInfo(Ctrl^.Files[i])^.action=act_delete then
          lnode.Enabled:=false;
      end;
    until not Ctrl^.GetNextFile(i);
end;

procedure TPanelForm.FillTree(adir:integer);
begin
  if (adir<0) or (adir>=Ctrl^.DirCount) then exit;
  if GetPanelType()<>panelTree then exit;

  SetActiveDir(adir,Ctrl,ListIndex);

  tvTree.Items.Clear;
  with tvTree do
  begin
    BeginUpdate;
    AddBranch(Items.AddChildObjectFirst(nil,'MOD',pointer(-1)),0);

    if tvTree.Items.Count>20 then sbCollapseClick(sbCollapse);
    EndUpdate;
  end;
  tvTree.AlphaSort;
  if adir>=0 then
    SelectTreePath(adir)
  else
    tvTree.Items[0].Selected:=true;

  lblPath.Caption:=Ctrl^.Dirs[adir].Name;
end;

{%ENDREGION Tree}

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

end.

