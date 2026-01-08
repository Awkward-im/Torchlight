{}
{TODO: Check file type (extension) changing on rename}
{$IFDEF Interface}

  procedure Rename();
  procedure CreateNewFile();
  procedure CreateNewDir();
  procedure Copy();
  procedure Move();      // ??copy+delete
  procedure Delete(acode: integer);    // not mark but delete

{$ELSE}

procedure TPanelForm.CreateNewDir();
var
  lname:string;
  lpath:PWideChar;
  ldir:integer;
begin
  lname:=sNewDir;
  if not InputQuery(rsCreateDir, rsDirName, lname) then exit;
  if lname='' then exit;

  if lname[Length(lname)]= '\' then lname[Length(lname)]:='/';
  if lname[Length(lname)]<>'/' then lname:=lname+'/';
  if IsNameExists(lname)>=0 then
  begin
    ShowMessage(rsExists);
    exit;
  end;

  ldir:=GetActiveDir(Ctrl,ListIndex);
  lpath:=Ctrl^.Dirs[ldir].Name;

  Ctrl^.NewDir(WideToStr(lpath)+lname);
end;

procedure TPanelForm.CreateNewFile();
var
  lname:string;
  lpath:PWideChar;
  ldir:integer;
begin
  lname:=sNewFile;
  if not InputQuery(rsCreateFile, rsFileDirName, lname) then exit;
  if lname='' then exit;

  if lname[Length(lname)]='/' then SetLength(lname,Length(lname)-1);
  if IsNameExists(lname)>=0 then
  begin
    ShowMessage(rsExists);
    exit;
  end;

  lname:=UpCase(lname);

  ldir:=GetActiveDir(Ctrl,ListIndex);
  lpath:=Ctrl^.Dirs[ldir].Name;

  Ctrl^.UseData(nil,0,WideToStr(lpath)+lname);
end;

procedure TPanelForm.Rename();
var
  lold,lname:string;
  pname,pc:PUnicodeChar;
  lfile:integer;
  ltype:boolean;
begin
  if GetPanelType()=panelTree then
    lfile:=Ctrl^.AsFile(GetActiveDir(Ctrl,ListIndex))
  else
    lfile:=GetActiveFile(Ctrl,ListIndex);
  lold:=FastWideToStr(Ctrl^.NameOfFile(lfile));

  lname:=lold;
  if not InputQuery(rsNewName, rsFileDirName, lname) then exit;
  if lname='' then exit;
  lname:=UpCase(lname);
  if lname=lold then exit;

  if IsNameExists(lname)>=0 then
  begin
    ShowMessage(rsExists);
    exit;
  end;

  if (not Ctrl^.IsDir(lfile)) and (ExtractExt(lname)<>ExtractExt(lold)) then
  begin
    if MessageDlg(rsWarning,rsTypeChanged,mtWarning,
       [mbOK,mbCancel],0,mbCancel)<>mrOk then
    begin
      exit;
    end;
    ltype:=true;
  end
  else
    ltype:=false;
    
  pc:=FastStrToWide(lname);
  if GetPanelType=panelList then
  begin
    Ctrl^.Rename(lfile,pc);
    if ltype then Ctrl^.Files[lfile]^.ftype:=RGTypeOfExt(lname);
  end
  //!!!theoretically, next not needs coz lfile will point to dir anyway
  else // if GetPanelType=panelTree then
    Ctrl^.Rename(Ctrl^.AsFile(GetActiveDir(Ctrl,ListIndex)),pc);
  FreeMem(pc);
end;

procedure TPanelForm.Copy();
begin
end;

procedure TPanelForm.Move();
begin
end;

{
  recursive (if needs) deleting of "ctrl", not "man" (it must be deleted by-the-way) records
}
procedure TPanelForm.Delete(acode:integer);
var
  arr:TIntegerDynArray;
  i,lidx:integer;
begin
  case acode of
    1: begin
      if GetPanelType()=panelTree then
        Ctrl^.MarkToRemove(Ctrl^.AsFile(IntPtr(tvTree.Selected.Data)))
      else if not IsParentDirSelected() then
        Ctrl^.MarkToRemove(GetSelectedFile());

      exit;
    end;

    2: begin
      if GetPanelType()=panelTree then
        Ctrl^.RemoveUpdate(Ctrl^.AsFile(IntPtr(tvTree.Selected.Data)))
      else
        Ctrl^.RemoveUpdate(GetSelectedFile());

      exit;
    end;
  end;

  if MessageDlg(rsWarning,rsSureToDelete,mtWarning,
     [mbOK,mbCancel],0,mbCancel)<>mrOk then
  begin
    exit;
  end;

  arr:=nil;
  if GetPanelType()=panelTree then
    lidx:=Ctrl^.AsFile(GetActiveDir(Ctrl,ListIndex))
  else
    lidx:=GetSelectionList(arr);
  if lidx<0 then
  begin
    for i:=0 to Length(arr)-1 do
      Ctrl^.Delete(arr[i]);
    SetLength(arr,0);
  end
  else
  begin
    Ctrl^.Delete(lidx);
  end;
end;

{$ENDIF}
