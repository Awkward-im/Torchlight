{%REGION Tree}

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
  SetPanelPath(Ctrl^.Dirs[adir].Name);
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

  if GetPanelType() in [panelShell, panelShellTree] then
//  if IntPtr(cbContent.Items.Objects[cbContent.ItemIndex])=ptShell then
  begin
    if sbTree.Down then
    begin
      SetPanelType(panelShellTree);
//      tvShell.Path:=FShellPath;
//      tvShell.SetFocus;
    end
    else
    begin
      SetPanelType(panelShell);
      FShellPath:=tvShell.Selected.GetTextPath;
      FillShellList(tvShell.Selected.Text);
      lvList.SetFocus;
    end;
  end
  else
  begin
    if sbTree.Down then
    begin
      SetPanelType(panelTree);
//      FillTree();
//      tvTree.SetFocus;
    end
    else
    begin
      SetPanelType(panelList);
      FillList (GetActiveDir(Ctrl,ListIndex));
      lvList.SetFocus;
    end;
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
    SetPanelPath(Ctrl^.Dirs[ldir].Name);
  end;
end;

procedure TPanelForm.tvTreeDblClick(Sender: TObject);
{
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
}
begin
  tvTreeSelectionChanged(Sender);
  if pnlTop.Visible then
  begin
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

procedure TPanelForm.FillTree();
var
  ldir:integer;
begin
{
  if (adir<0) or (adir>=Ctrl^.DirCount) then exit;
  if GetPanelType()<>panelTree then exit;

  SetActiveDir(adir,Ctrl,ListIndex);
}
  ldir:=GetActiveDir(Ctrl,ListIndex);
  tvTree.Items.Clear;
  with tvTree do
  begin
    BeginUpdate;
    AddBranch(Items.AddChildObjectFirst(nil,'MOD',pointer(-1)),0);

    if tvTree.Items.Count>20 then sbCollapseClick(sbCollapse);
    EndUpdate;
  end;
  tvTree.AlphaSort;
  if ldir>=0 then
  begin
    SelectTreePath(ldir);
    SetPanelPath(Ctrl^.Dirs[ldir].Name);
  end
  else
  begin
    tvTree.Items[0].Selected:=true;
    SetPanelPath('');
  end;
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
      begin
        SetActiveDir(ldir,Ctrl,ListIndex);
        FillTree();
      end
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
