{%REGION List (direct control access)}

{
  place:
  SetFocus
    cbContentChange
    sbTreeClick

  Non-event functions:
    procedure TPanelForm.SelectFile(aidx:integer);
    function  TPanelForm.IsParentDirSelected():integer; inline;
    procedure TPanelForm.GetSelectionList(var arr:TDynIntegerArray);
    function  TPanelForm.GetSelectedFile():integer; inline;
    procedure TPanelForm.SelectLine();
    procedure TPanelForm.FillList(adir:integer);
  Event functions:
    lvListSelectItem
    lvListCustomDrawItem
    lvListCompare
    lvListShowHint
}

procedure TPanelForm.sbFullClick(Sender: TObject);
begin
  sbFilter.Visible:=sbFull.Down;
  lvfeFull.Visible:=sbFull.Down;
  lvfeFull.FilteredListview:=nil;
  lvfeFull.Items.Clear;
  lvfeFull.Filter:='';

  if sbFull.Down then
  begin
    FillFullList();
    lvfeFull.SortData:=true;
    lvfeFull.FilteredListview:=lvList;
  end
  else
  begin
    FillList(0);
  end;
end;

procedure TPanelForm.ShowHideColumn(acol:integer; ashow:boolean); inline;
begin
  lvList.Column[acol].Visible:=ashow;
end;

function TPanelForm.IsParentDirSelected():boolean; inline;
begin
  result:=lvList.Selected.Caption=strParentDir;
end;

function TPanelForm.GetSelectedFile():integer; inline;
begin
  if lvList.ItemIndex>=0 then
    result:=IntPtr(lvList.Items[lvList.ItemIndex].Data)
  else
    result:=-1;
end;

function TPanelForm.GetSelectionList(var arr:TIntegerDynArray):integer;
var
  i,lcnt:integer;
begin
  if not lvList.Checkboxes then
  begin
    if (lvList.ItemIndex=0) and (lvList.Items[0].Caption=strParentDir) then
      result:=Ctrl^.AsFile(GetActiveDir(Ctrl,ListIndex))
    else
      result:=GetSelectedFile();
  end
  else
  begin
    result:=-1;
    lcnt:=0;
    for i:=0 to lvList.Items.Count-1 do
      if lvList.Items[i].Checked then inc(lcnt);
    SetLength(arr,lcnt);

    lcnt:=0;
    for i:=0 to lvList.Items.Count-1 do
    begin
      if lvList.Items[i].Checked then
      begin
        arr[lcnt]:=IntPtr(lvList.Items[i].Data);
        inc(lcnt);
      end;
    end;
  end;
end;

procedure TPanelForm.SelectAll();
var
  lstart,lcnt,i:integer;
begin
  if (lvList.Items.Count=0) then exit;
  if (lvList.Items[0].Caption=strParentDir) then
  begin
    if lvList.Items.Count=1 then exit;
    lstart:=1;
  end
  else
    lstart:=0;

  // have no any selection -> Select all
  if not lvList.Checkboxes then
  begin
    lvList.Checkboxes:=True;
    for i:=lstart to lvList.Items.Count-1 do
      lvList.Items[i].Checked:=true;
  end
  // have at least one selection
  else
  begin
    lcnt:=0;
    for i:=lstart to lvList.Items.Count-1 do
      if lvList.Items[i].Checked then inc(lcnt);

    // selected all -> Select nothing
    if lcnt=(lvList.Items.Count-lstart) then
    begin
{
      for i:=lstart to lvList.Items.Count-1 do
        lvList.Items[i].Checked:=false;
}
      lvList.Checkboxes:=false
    end
    else
      for i:=lstart to lvList.Items.Count-1 do
        lvList.Items[i].Checked:=true;
  end;
end;

procedure TPanelForm.SelectLine();
var
  lidx,lcnt,i:integer;
begin
  lidx:=lvList.ItemIndex;
  if (lidx=0) and (lvList.Items[0].Caption=strParentDir) then exit;

  // have no any selection
  if not lvList.Checkboxes then
  begin
    lvList.Checkboxes:=True;
    lvList.Items[lidx].Checked:=true;
  end
  // have at least one selection
  else
  begin
    lvList.Items[lidx].Checked:=not lvList.Items[lidx].Checked;

    lcnt:=0;
    for i:=0 to lvList.Items.Count-1 do
      if lvList.Items[i].Checked then inc(lcnt);

    if lcnt=0 then lvList.Checkboxes:=false;
  end;
//!!!!!!!!!!!!!!!!!!!!!!!!
  lvList.SetFocus;
  if lidx<(lvList.Items.Count-1) then inc(lidx);
  lvList.ItemIndex:=lidx;

    lvList.ItemFocused:=lvList.Items[lvList.ItemIndex];
    lvList.Items[lvList.ItemIndex].MakeVisible(true);
//  lvList.Items[lidx].Selected:=true;
//  lvList.Items[lidx].Focused :=true;
end;

procedure TPanelForm.lvListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  lpanel:TPanelForm;
  ltype,lfile:integer;
begin
  if Selected then
  begin
    lfile:=GetSelectedFile();
    SetActiveFile(lfile,Ctrl,ListIndex);

    // If only no handler set
    lpanel:=GetOppositePanel();
    ltype :=lpanel.GetPanelType();

    if ltype=panelView then
      lpanel.ShowPreview(Ctrl,lfile);
  end;
end;

procedure TPanelForm.lvListCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
{
TCustomDrawStateFlag = (
  cdsSelected,
  cdsGrayed,
  cdsDisabled,
  cdsChecked,
  cdsFocused,
  cdsDefault,
  cdsHot,
  cdsMarked,
  cdsIndeterminate
}
var
  lcbg:TColor;
begin
  case Ctrl^.GetUpdateState(IntPtr(Item.Data)) of
    stateNew    : lcbg:=clrNewBG;
    stateChanged: lcbg:=clrChangedBG;
    stateDelete : lcbg:=clrDeleteBG;
    stateLink   : lcbg:=clrLinkBG;
  else
    lcbg:=clWindow;
  end;

  Sender.Canvas.Brush.Color:=lcbg;
end;

procedure TPanelForm.lvListCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
  s1,s2,ss1,ss2:AnsiString;
  dt1,dt2:TDateTime;
  ldir1,ldir2:boolean;
begin
  s1:=Item1.Caption;
  s2:=Item2.Caption;
  ldir1:=(s1<>'') and (s1[Length(s1)]= '/');
  ldir2:=(s2<>'') and (s2[Length(s2)]= '/');

  if ldir1 and ldir2 then
  begin
    Compare:=CompareStr(s1,s2);
    if lvList.sortColumn<>colName then exit;
  end
  else if ldir1 and not ldir2 then begin Compare:=-1; exit; end
  else if ldir2 and not ldir1 then begin Compare:=1 ; exit; end
  else
  begin
    if lvList.sortColumn<>colName then
    begin
      ss1:=Item1.SubItems[lvList.sortColumn-1];
      ss2:=Item2.SubItems[lvList.sortColumn-1];
    end;
    if lvList.sortColumn=colSize then
    begin
      Compare:=StrToIntDef(ss1,0)-
               StrToIntDef(ss2,0);
    end
    else if lvList.sortColumn=colTime then
    begin
      dt1:=StrToDateTimeDef(ss1,0);
      dt2:=StrToDateTimeDef(ss2,0);
      if dt1>dt2 then
        Compare:=1
      else if dt1<dt2 then
        Compare:=-1
      else
        Compare:=0;
    end
    else if lvList.sortColumn=colExt then
    begin
      Compare:=CompareStr(ss1,ss2);
      if Compare=0 then
        Compare:=CompareStr(s1,s2);
    end
    else
      Compare:=CompareStr(s1,s2);
  end;

  if lvList.SortDirection=sdDescending then
    Compare:=-Compare;
end;

procedure TPanelForm.lvListShowHint(Sender: TObject; HintInfo: PHintInfo);
var
  lv:TListItem;
  si,lpos:integer;
//  ScrollInfo: TScrollInfo;
begin
  lv:=lvList.GetItemAt(HintInfo^.CursorPos.X,HintInfo^.CursorPos.Y);
  si:=-1;
  if lv<>nil then
  begin
//    GetScrollInfo(lvList.Handle, SB_HORZ, ScrollInfo);
    lpos:=-{ScrollInfo.nPos;//}GetScrollPos(lvList.Handle,SB_HORZ);
    while lpos<HintInfo^.CursorPos.X do
    begin
      Inc(si);
      Inc(lpos, lvList.Columns.Items[si].Width);
    end;
    if si>=lvList.Columns.Count then
      si:=-1;
  end;
  if si=0 then
    HintInfo^.HintStr:=lv.Caption;
  if si>0 then
    HintInfo^.HintStr:=lv.SubItems[si-1];
end;

procedure TPanelForm.lvfeFullAfterFilter(Sender: TObject);
begin
  if lvList.Items.Count>1 then
  begin
    lvList.SortColumn:=colExt;
    lvList.Sort;
  end;
end;

procedure TPanelForm.AddListRow(aidx:integer);
var
  ltime:UInt64;
  linfo:PRGCtrlInfo;
  lrec:TRGFullInfo;
  ls:AnsiString;
begin
  linfo:=Ctrl^.Files[aidx];
  with lvList.Items.Add do
  begin
    ls:=WideToStr(linfo^.Name);

    Ctrl^.GetFullInfo(aidx,lrec);

    if linfo^.ftype=typeDirectory then
    begin
      Caption:=ls;
      Data   :=pointer(IntPtr(aidx));
      SubItems.Add('');      // ext
      SubItems.Add(strDir);  // type
      SubItems.Add('');      // size
      SubItems.Add('');      // time
    end
    else
    begin
      Caption:=ExtractNameOnly(ls);
      Data   :=pointer(IntPtr(aidx));
      SubItems.Add(ExtractExt(ls));              // ext
      SubItems.Add(RGTypeGroupName(lrec.ftype)); // type
      SubItems.Add(IntToStr(lrec.size));         // size
      // Time
      ltime:=lrec.ftime;
      if ltime<>0 then
      begin
        try
          ls:=DateTimeToStr(FileTimeToDateTime(ltime));
        except
          ls:='0x'+HexStr(ltime,16);
        end;
      end
      else
        ls:='';
      SubItems.Add(ls);
    end;
    // State
    case lrec.state of
      stateNew              : ls:=stlblNew;
      stateChanged          : ls:=stlblChanged;
      stateDelete           : ls:=stlblDelete;
      stateNew    +stateLink: ls:=stlblLinkNew;
      stateChanged+stateLink: ls:=stlblLinkEd;
    else
      ls:=' ';
    end;
    SubItems.Add(ls);
  end;
end;

procedure TPanelForm.FillFullList();
var
  ltime:UInt64;
  linfo:PRGCtrlInfo;
  lrec:TRGFullInfo;
  ls:AnsiString;
  i:integer;
begin
  lvList.BeginUpdate;
  lvList.Clear;
  lvList.Checkboxes:=false;

  for i:=0 to Ctrl^.FileCount-1 do
  begin
    if Ctrl^.IsDir(i) or Ctrl^.IsFileDeleted(i) then continue;

    AddListRow(i);
  end;
  lvList.EndUpdate;

  if lvList.Items.Count>0 then
  begin
    lvList.SortColumn:=colExt;
 {
    if lvList.Items.Count>1 then
    begin
      lvList.SortColumn:=colExt;
      lvList.Sort;
    end;
}
    lvList.ItemIndex:=0;
  end;

  lblPath.Caption:=rsFullList;
end;

procedure TPanelForm.FillList(adir:integer);
var
  ltime:UInt64;
  c,ls:AnsiString;
  linfo:PRGCtrlInfo;
  lolddir,lfile:integer;
  lrec:TRGFullInfo;
begin
  if adir<0 then
  begin
    FillFullList();
    exit;
  end;

  if adir>=Ctrl^.DirCount then exit;
  if GetPanelType()<>panelList then exit;

  lolddir:=GetActiveDir(Ctrl,ListIndex);
  SetActiveDir(adir,Ctrl,ListIndex);

  lvList.BeginUpdate;
  lvList.Clear;
  lvList.Checkboxes:=false;

  // Parent dir
  if adir>0 then
    with lvList.Items.Add do
    begin
      Caption:=strParentDir;
      // dir index to file index and get it's parent
      Data   :=pointer(IntPtr(Ctrl^.AsFile(Ctrl^.FileDir(Ctrl^.AsFile(adir)))));
      lfile:=IntPtr(Ctrl^.AsFile(Ctrl^.FileDir(Ctrl^.AsFile(adir))));
    end;

  if Ctrl^.GetFirstFile(lfile,adir) then
  begin
    repeat
      AddListRow(lfile);
    until not Ctrl^.GetNextFile(lfile);
  end;
  lvList.EndUpdate;

  if lvList.Items.Count>0 then
  begin
    if lvList.Items.Count>1 then
	    lvList.Sort;

	  if lolddir<>adir then
      SelectFile(Ctrl^.AsFile(lolddir))
    else
      SelectFile(GetActiveFile(Ctrl,ListIndex));
  end;

  lblPath.Caption:=Ctrl^.Dirs[adir].Name;
end;

procedure TPanelForm.SelectFile(aidx:integer);
var
  i,lidx:integer;
begin
  lidx:=0;
  if aidx>=0 then
  begin
    for i:=0 to lvList.Items.Count-1 do
    begin
      if aidx=UIntPtr(lvList.Items[i].Data) then
      begin
        lidx:=i;
        break;
      end;
    end;
  end;
  lvList.ItemIndex:=lidx;
//  if (lidx<lvList.Items.Count) and Self.Showing then lvList.Items[lvList.ItemIndex].Focused:=true;
  if (lidx<lvList.Items.Count) and Self.Showing then 
  begin
    lvList.ItemFocused:=lvList.Items[lvList.ItemIndex];
    lvList.Items[lvList.ItemIndex].MakeVisible(true);
  end;
end;

procedure TPanelForm.SelectInList(afirst:boolean);
begin
  if lvList.Items.Count>1 then
  begin
    if afirst then
      lvList.ItemIndex:=0
    else
      lvList.ItemIndex:=lvList.Items.Count-1;

//    if Self.Showing then lvList.Items[lvList.ItemIndex].Focused:=true;
    lvList.ItemFocused:=lvList.Items[lvList.ItemIndex];
    lvList.Items[lvList.ItemIndex].MakeVisible(true);
//    lvList.TopItem:=lvList.Items[lvList.ItemIndex]
  end;
end;

procedure TPanelForm.ProcessListEvent(aidx:integer; aevent:integer);
var
  lv:TListItem;
  lidx,lsrcdir,lfiledir:integer;
begin
  lsrcdir :=GetActiveDir(Ctrl,ListIndex);
  lfiledir:=Ctrl^.FileDir(aidx);
  if lsrcdir<>lfiledir then exit;

  while true do
  begin
    case aevent of
      faAdd: begin
        AddListRow(aidx);
        lvList.Sort;
        lv:=lvList.Items.FindData(pointer(IntPtr(aidx)));
        lvList.ItemIndex:=lvList.Items.IndexOf(lv);
        lvList.ItemFocused:=lv;
      end;

      faRename: begin
        lv:=lvList.Items.FindData(pointer(IntPtr(aidx)));
        if lv<>nil then lv.Caption:=Ctrl^.NameOfFile(aidx);
      end;

      faDeleting: begin
        lv:=lvList.Items.FindData(pointer(IntPtr(aidx)));
        if lv<>nil then
        begin
          lidx:=lvList.ItemIndex;
          lv.Delete;
          if lidx>=lvList.Items.Count then lidx:=lvList.Items.Count-1;
          lvList.ItemIndex:=lidx;
          lvList.ItemFocused:=lvList.Items[lidx];
        end;
      end;

      // better was to change subitems but this is simpler
      faChanged,
      faInfo: begin
        lv:=lvList.Items.FindData(pointer(IntPtr(aidx)));
        if lv<>nil then
        begin
          lv.Delete;
          aevent:=faAdd;
          continue;
        end;
      end;

      faStatus: begin
        lvList.Refresh;
      end;

      // idk what to do
      faMove: begin
      end;
    end;

    break;
  end;

end;
  	
{%ENDREGION List}
