{}
{TODO: Check file type (extension) changing on rename}
{$IFDEF Interface}

  procedure Rename();
  procedure CreateNewFile();
  procedure CreateNewDir();
  procedure Copy();
  procedure Move();      // ??copy+delete
  procedure Delete();    // not mark but delete

{$ELSE}

procedure TPanelForm.CreateNewDir();
var
  lname:string;
  lpath:PWideChar;
  ldir:integer;
begin
  lname:=InputBox(rsCreateDir, rsDirName, sNewDir);
  if lname='' then exit;
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
  lname:=UpCase(InputBox(rsCreateFile, rsFileName, sNewFile));
  if lname='' then exit;
  if lname[Length(lname)]='/' then SetLength(lname,Length(lname)-1);
  if IsNameExists(lname)>=0 then
  begin
    ShowMessage(rsExists);
    exit;
  end;

  ldir:=GetActiveDir(Ctrl,ListIndex);
  lpath:=Ctrl^.Dirs[ldir].Name;

  Ctrl^.UseData(nil,0,WideToStr(lpath)+lname);
end;

procedure TPanelForm.Rename();
var
  lext,lname:string;
  pname,pc:PUnicodeChar;
  lfile:integer;
  ltype:boolean;
begin
  lfile:=GetActiveFile(Ctrl,ListIndex);
  lname:=FastWideToStr(Ctrl^.NameOfFile(lfile));
  lext:=ExtractExt(lname);
  lname:=UpCase(InputBox(rsNewName, rsFileDirName, lname));
  if lname='' then exit;
  if (not Ctrl^.IsDir(lfile)) and (ExtractExt(lname)<>lext) then
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
    
  if IsNameExists(lname)>=0 then
  begin
    ShowMessage(rsExists);
    exit;
  end;

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

procedure TPanelForm.Delete();
begin
  if MessageDlg(rsWarning,rsSureToDelete,mtWarning,
     [mbOK,mbCancel],0,mbCancel)<>mrOk then
  begin
    exit;
  end;
end;

{$ENDIF}
