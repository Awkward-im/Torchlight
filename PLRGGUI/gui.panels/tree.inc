{%REGION Tree}
(*

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

{
  Process faDeleting coz need to translate File to Dir index
  IdDir at faDeleted will not work til check name, not ftype
}
procedure TPanelForm.ProcessTreeEvent(aidx:integer; aevent:integer);
var
  lnode,lparent:TTreeNode;
  ldir:integer;
begin
  if not (aevent in [faAdd,faRename,faDeleting,faDeleted,faMove,faStatus]) then exit;
  if (aevent<>faDeleted) and (not Ctrl^.IsDir(aidx)) then exit;

  case aevent of
    faAdd: begin
      ldir:=Ctrl^.FileDir(aidx);
      lparent:=tvTree.Items.FindNodeWithData(pointer(IntPtr(ldir)));
      // case when several branches was made without redraw
      if lparent=nil then
        FillTree(ldir)
      else
        tvTree.Selected:=tvTree.Items.AddChild(lparent,Ctrl^.NameOfFile(aidx));
    end;

    faRename: begin
      lnode:=tvTree.Items.FindNodeWithData(pointer(IntPtr(Ctrl^.AsDir(aidx))));
      if lnode<>nil then lnode.Text:=Ctrl^.NameOfFile(aidx);
    end;

    faDeleting: begin
      lnode:=tvTree.Items.FindNodeWithData(pointer(IntPtr(Ctrl^.AsDir(aidx))));
      if lnode<>nil then
      begin
//        lparent:=tvTree.Items.FindNodeWithData(pointer(IntPtr(Ctrl^.FileDir(aidx))));
        lparent:=lnode.Parent;
        tvTree.Items.Delete(lnode);
        tvTree.Selected:=lparent;
      end;
    end;

    // all we need is just repaint
    faStatus: begin
      lnode:=tvTree.Items.FindNodeWithData(pointer(IntPtr(Ctrl^.AsDir(aidx))));
      if lnode<>nil then lnode.Enabled:=PRGCtrlInfo(Ctrl^.Files[aidx])^.action<>act_delete;
    end;

    // idk what to do
    faMove: begin
    end;
  end;
end;

{%ENDREGION Tree}
