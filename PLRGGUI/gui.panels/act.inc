{}
{$IFDEF Interface}

  procedure Delete(acode: integer);    // not mark but delete
  procedure DeleteSingleFile(idx:integer; ondisk:boolean);
{
  function CopyShellToShell(const asrc, adst:AnsiString; var aact:TRGDoubleAction):integer;
  function CopyShellToCtrl (const asrc, adst:AnsiString):integer;
  function CopyCtrlToShell (aidx:integer; const apath:AnsiString):integer;
  function CopyCtrlToCtrl  (aidx:integer; actrl:PRGController; apath:PUnicodeChar):integer;
  procedure Copy();
}
  //?? just copy from disk or link
  function OnImportDouble (actrl:PRGController; idx:integer;
           var newdata:PByte; var newsize:integer):TRGDoubleAction;

{$ELSE}

procedure TPanelForm.execGoToRoot(Sender: TObject);
begin
  case GetPanelType() of
    panelList: begin
      FillList(0);
    end;

    panelShell: begin
      FShellPath:='';
      FillShellList('');
    end;
  end;
end;

procedure TPanelForm.execNewDir(Sender: TObject);
var
  lname:string;
  lpath:PWideChar;
  ldir:integer;
begin
  lname:=sNewDir;
  if not InputQuery(rsCreateDir, rsDirName, lname) then exit;
  if lname='' then exit;

  if GetPanelType()=panelShell then
  begin
//    System.MkDir(FShellPath+lname);
    if SysUtils.CreateDir(FShellPath+lname) then
      FillShellList('');
    exit;
  end;

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

procedure TPanelForm.execNewFile(Sender: TObject);
var
  lname:string;
  lpath:PWideChar;
  ldir:integer;
begin
  if GetPanelType()=panelShell then exit;

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

procedure TPanelForm.execRename(Sender: TObject);
var
  lold,lname:string;
  pc:PUnicodeChar;
  ltype,lfile:integer;
  lchtype:boolean;
begin
  ltype:=GetPanelType();

  if ltype=panelTree then
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
    lchtype:=true;
  end
  else
    lchtype:=false;
    
  if ltype=panelShell then
  begin
    if SysUtils.RenameFile(FShellPath+lold,FShellPath+lname) then
      FillShellList(lname);
    exit;
  end;
  
  pc:=FastStrToWide(lname);
  if ltype=panelList then
  begin
    Ctrl^.Rename(lfile,pc);
    if lchtype then Ctrl^.Files[lfile]^.ftype:=RGTypeOfExt(lname);
  end
  //!!!theoretically, next not needs coz lfile will point to dir anyway
  else // if GetPanelType=panelTree then
    Ctrl^.Rename(Ctrl^.AsFile(GetActiveDir(Ctrl,ListIndex)),pc);
  FreeMem(pc);
end;

procedure TPanelForm.execSelectAll(Sender: TObject);
begin
  SelectAll(false);
end;

procedure TPanelForm.execInverse(Sender: TObject);
begin
  SelectAll(true);
end;

procedure TPanelForm.execDelete(Sender: TObject);
begin
  Delete(0);
end;

procedure TPanelForm.execMark(Sender: TObject);
begin
  if GetPanelType()=panelTree then
    Delete(1)
  else if not IsParentDirSelected() then
    Ctrl^.MarkToRemove(GetSelectedFile())

end;

procedure TPanelForm.execUndo(Sender: TObject);
begin
  if GetPanelType()=panelTree then
    Delete(2)
  else
    Ctrl^.RemoveUpdate(GetSelectedFile());
end;

procedure TPanelForm.execView(Sender: TObject);
var
  lform:TForm;
begin
  lform:=MakePreview(Ctrl^,GetSelectedFile(),false);
  if lform<>nil then lform.Show;
end;

{
  recursive (if needs) deleting of "ctrl", not "man" (it must be deleted by-the-way) records
}
procedure TPanelForm.DeleteSingleFile(idx:integer; ondisk:boolean);
var
  ls:AnsiString;
begin
  if ondisk then
  begin
    ls:=FShellPath+FastWideToStr(Ctrl^.NameOfFile(idx));
    if Ctrl^.IsDir(idx) then
    begin
      SetLength(ls,Length(ls)-1);
//      SysUtils.RemoveDir(ls);
      DeleteDirectory(ls,false);
    end
    else
      SysUtils.DeleteFile(ls);
  end;
  Ctrl^.Delete(idx);
end;

procedure TPanelForm.Delete(acode:integer);
var
  arr:TIntegerDynArray;
  i,lidx,ltype:integer;
begin
  arr:=nil;
  if (ltype=panelTree) or (ltype=panelShellTree) then
    lidx:=Ctrl^.AsFile(GetActiveDir(Ctrl,ListIndex))
  else
    lidx:=GetSelectionList(arr);

  ltype:=GetPanelType();
  if ltype<>panelShell then
  begin
    case acode of
      1: begin
        if lidx>=0 then
          Ctrl^.MarkToRemove(lidx)
        else
        begin
          Ctrl^.OnChange(Ctrl,0,faStart);
          for i:=0 to Length(arr)-1 do
          begin
            Ctrl^.MarkToRemove(arr[i]);
          end;
          Ctrl^.OnChange(Ctrl,Length(arr),faFinish);
          SetLength(arr,0);
        end;
        
//        if (GetPanelType()=panelTree) or not IsParentDirSelected() then
//          Ctrl^.MarkToRemove(GetSelectedFile());

        exit;
      end;

      2: begin
        if lidx>=0 then
          Ctrl^.RemoveUpdate(lidx)
        else
        begin
          Ctrl^.OnChange(Ctrl,0,faStart);
          for i:=0 to Length(arr)-1 do
          begin
            Ctrl^.RemoveUpdate(arr[i]);
          end;
          Ctrl^.OnChange(Ctrl,Length(arr),faFinish);
          SetLength(arr,0);
        end;

//        Ctrl^.RemoveUpdate(GetSelectedFile());

        exit;
      end;
    end;
  end;

  if MessageDlg(rsWarning,rsSureToDelete,mtWarning,
     [mbOK,mbCancel],0,mbCancel)<>mrOk then
  begin
    exit;
  end;
{
  arr:=nil;
  if (ltype=panelTree) or (ltype=panelShellTree) then
    lidx:=Ctrl^.AsFile(GetActiveDir(Ctrl,ListIndex))
  else
    lidx:=GetSelectionList(arr);
}
  if lidx<0 then
  begin
    Ctrl^.OnChange(Ctrl,0,faStart);
    for i:=0 to Length(arr)-1 do
    begin
      DeleteSingleFile(arr[i],(ltype=panelShell) or (ltype=panelShellTree));
    end;
    Ctrl^.OnChange(Ctrl,Length(arr),faFinish);
    SetLength(arr,0);
    if (ltype=panelList) or (ltype=panelTree) then
      FillList(GetActiveDir(Ctrl,ListIndex));
  end
  else
  begin
    DeleteSingleFile(lidx,(ltype=panelShell) or (ltype=panelShellTree));
  end;

  if (ltype=panelShell) or (ltype=panelShellTree) then
    FillShellList('');
end;

(*
function CopySingleFile(const afrom,ato:AnsiString; aact:TRGDoubleAction):TRGDoubleAction;
var
  lfrom,lto:AnsiString;
begin
  result:=aact;

  lfrom:=afrom;
  lto  :=ato;
{
  if FileExists(ato) then
  begin
    case aact of
      da_skipall: exit;
      da_overwriteall: ;
    end;

    case result of
      da_stop: exit;
      da_skipdir,
      da_skipall,
      da_skip: exit;
      da_compare:
      da_overwriteall,
      da_overwrite: ;
      da_renameold: lto:=
      da_saveas: lfrom:=
    end;
  end;
}
  fileutil.CopyFile(lfrom,lto,true,false);
end;

function TPanelForm.CopyShellToShell(const asrc, adst:AnsiString; var aact:TRGDoubleAction):integer;
var
  sr:TSearchRec;
begin
  result:=0;

  if asrc[Length(asrc)] in ['\','/'] then
  begin
    if not DirectoryExists(adst) then MkDir(adst);

    if SysUtils.FindFirst(asrc+'*.*',faAnyFile and faDirectory,sr)=0 then
    begin
      repeat
        if (sr.Attr and faDirectory)=faDirectory then
        begin
          if (sr.Name='.') or (sr.Name='..') then continue;

          CopyShellToShell(asrc+sr.Name+'/', adst+sr.Name+'/',aact);
        end
        else
          CopySingleFile(asrc+sr.Name, adst+sr.Name, aact);
      until SysUtils.FindNext(sr)<>0;
      SysUtils.FindClose(sr);
    end;
  end
  else
  begin
    CopySingleFile(asrc,adst,aact);
{
    if FileExists() then
    begin
    end
    else
;//      CopyFile
}
  end;
end;

function TPanelForm.CopyShellToCtrl(const asrc, adst:AnsiString):integer;
begin
  result:=0;

  if asrc[Length(asrc)] in ['\','/'] then
    result:=Ctrl^.ImportDir(adst+ExtractName(asrc),asrc,false,false)
  else
    if Ctrl^.AddFileData(asrc,
        adst+FixFileExt(ExtractName(asrc)), true)>=0 then
      inc(result);
end;

function TPanelForm.CopyCtrlToShell(aidx:integer; const apath:AnsiString):integer;
var
  lname,ls:AnsiString;
  lbuf:PByte;
  lidx,lsize:integer;
begin
  result:=0;
  lname:=FastWideToStr(Ctrl^.NameOfFile(aidx));
  ls:=apath+lname;
  if Ctrl^.IsDir(aidx) then
  begin
    if not DirectoryExists(ls) then MkDir(ls);

    if Ctrl^.GetFirstFile(lidx,Ctrl^.AsDir(aidx)) then
    begin
      repeat
        inc(result,CopyCtrlToShell(lidx, ls));
      until not Ctrl^.GetNextFile(lidx);
    end;
  end
  else
  begin
    if not FileExists(ls) then
    begin
      lbuf:=nil;
      lsize:=Ctrl^.GetAsIs(aidx,lbuf);
      if lsize>0 then
      begin
        if SaveFile(apath,lname,lbuf,lsize,
           Ctrl^.Pak.Version,
           FileTimeToDateTime(Ctrl^.Files[aidx]^.ftime), false) then inc(result);
        FreeMem(lbuf);
      end;
    end
    else
    begin
    end;
  end;
end;

function TPanelForm.CopyCtrlToCtrl(aidx:integer; actrl:PRGController; apath:PUnicodeChar):integer;
var
  lpc,pc:PUnicodeChar;
  psrc,pdst:PRGCtrlInfo;
  ls:AnsiString;
  lcs_s,lcs_d:dword;
  lidx:integer;
  lact:TRGDoubleAction;
begin
  result:=0;
  pc:=ConcatWide(apath,Ctrl^.NameOfFile(aidx));
  if Ctrl^.IsDir(aidx) then
  begin
    actrl^.NewDir(pc);
    if Ctrl^.GetFirstFile(lidx,Ctrl^.AsDir(aidx)) then
    begin
      repeat
        inc(result,CopyCtrlToCtrl(lidx, actrl, pc));
      until not Ctrl^.GetNextFile(lidx);
    end;
  
  end
  else
  begin
    lidx:=actrl^.SearchFile(pc);
    if lidx<0 then
    begin
      if Ctrl^.CopyFile(aidx, actrl, pc) then result:=1;
    end
    else
    begin
      psrc:=Ctrl^ .Files[aidx];
      pdst:=actrl^.Files[lidx];

      // File with same name but different checksum (content)
      if psrc^.checksum<>pdst^.checksum then
      begin
//        ShowMessage(IntToStr(Ord(actrl^.OnDouble(lidx,PByte(apath),0))));
        // Skip, overwrite, update, [to all], stop

        lpc:=ConcatWide(actrl^.PathOfFile(lidx),actrl^.NameOfFile(lidx));
        with tAskForm.Create(FastWideToStr(lpc), psrc^.Size, pdst^.Size) do
        begin
      //    ShowModal();
      //    result:=TRGDoubleAction(MyResult);
          lact:=ModalToAction(ShowModal());
          Free;
        end;
        FreeMem(lpc);
        lpc:=nil;
        
        case lact of
          da_renameold: begin
            lpc:=StrToWide(
                InputBox('Rename existing file', 'Enter new name', Ctrl^.NameOfFile(lidx)) );
          end;

          da_saveas: begin
            lpc:=StrToWide(
                InputBox('Rename new file', 'Enter new name', Ctrl^.NameOfFile(lidx)) );
          end;

          da_compare: begin
            if (psrc^.ftype and $FF)=typeData then
            begin
{
              with TCompareForm.Create(lold,lnew) do
              begin
                if ShowModal()=mrOk then
                begin
                  newdata:=PByte(UnicodeText());
                  newsize:=(Length(PUnicodeChar(newdata))+1)*SizeOf(WideChar);
                end
                else
                  lres:=da_skip;

                Free;
              end;
}
            end;
          end;

        else
        end;

      end;
    end;
  end;
  FreeMem(pc);
end;

procedure TPanelForm.Copy();
var
  lpath:PUnicodeChar;
  lctrl:PRGController;
  lpanel:TPanelForm;
  arr:TIntegerDynArray;
  lspath,ls:AnsiString;
  lcopied,i,lidx:integer;
  lsrctype,ldsttype:integer;
  lact:TRGDoubleAction;

  function CopySingle(aidx:integer):integer;
  begin
    if (lsrctype=panelShell) or (lsrctype=panelShellTree) then
    begin
      if (ldsttype=panelList) or (ldsttype=panelTree) then
        result:=lpanel.CopyShellToCtrl(FShellPath+FastWideToStr(Ctrl^.NameOfFile(aidx)),lspath)
      else
        result:=CopyShellToShell(FShellPath+FastWideToStr(Ctrl^.NameOfFile(aidx)),lspath,lact);
    end
    else if (ldsttype=panelList) or (ldsttype=panelTree) then
    begin
      result:=CopyCtrlToCtrl(aidx,lctrl,lpath);
    end
    else
      result:=CopyCtrlToShell(aidx,lspath);
  end;

begin
  lpanel:=GetOppositePanel();
  ldsttype:=lpanel.GetPanelType();
  if (ldsttype=panelView    ) or
     (ldsttype=panelSettings) or
     (ldsttype=panelLog     ) then exit;
  lsrctype:=GetPanelType();

  lctrl:=lpanel.Ctrl;
  if (ldsttype=panelShell) or (ldsttype=panelShellTree) then
  begin
    lspath:=lpanel.FShellPath;
    ls:=Format(rsSureToCopyShell,[lspath]);
    lpath:=nil;
  end
  else
  begin
    // MUST use copy coz name buffer can be changed while copying files
    lpath:=CopyWide(lctrl^.Dirs[GetActiveDir(lctrl,lpanel.ListIndex)].Name);
    lspath:=FastWideToStr(lpath);
    ls:=StringReplace(
      StringReplace(rsSureToCopy,'$1',lctrl^.Pak.Name,[]),
      '$2',lpath,[]);
  //  ls:=Format(rsSureToCopy,[lctrl^.Pak.Name,lpath]);
  end;
  
  if MessageDlg(ls,mtConfirmation,mbOkCancel,0)<>mrOk then exit;

  lctrl^.OnDouble:=@lpanel.OnImportDouble;

  lact:=da_ask;
  arr:=nil;
  lidx:=GetSelectionList(arr);
  //!! don't forget to check destination file existing !!
  if lidx<0 then
  begin
    lcopied:=0;
    lctrl^.OnChange(lctrl,0,faStart);

    for i:=0 to Length(arr)-1 do
      inc(lcopied,CopySingle(arr[i]));

    lctrl^.OnChange(lctrl,lcopied,faFinish);
    SetLength(arr,0);
  end
  else
    lcopied:=CopySingle(lidx);

  FreeMem(lpath);

  lctrl^.OnDouble:=nil;

  if lcopied>0 then
  begin
    ShowMessage(rsCopied+' '+IntToStr(lcopied));
    lpanel.RefreshList();
  end
  else
    ShowMessage(rsNotCopied);
end;
*)
function TPanelForm.OnImportDouble(actrl:PRGController; idx:integer;
         var newdata:PByte; var newsize:integer):TRGDoubleAction;
var
  ls:AnsiString;
  f:file of byte;
  lold,lnew:PByte;
  loldsize,lnewsize:integer;
  istext:boolean;
begin
  lnew:=nil;
  lold:=nil;

//  istext:=(RGTypeOfExt(FCtrl^.Files[idx]^.Name) and $FF)=typeData;
  istext:=(Ctrl^.Files[idx]^.ftype and $FF)=typeData;

  // if size=0 then newdata is PUnicodeChar'ed filename
  lnewsize:=newsize;
  if newsize=0 then
  begin
    if istext then
    begin
      DecompileFile(PUnicodeChar(newdata),lnew,false);
      lnewsize:=Length(PUnicodeChar(lnew))*SizeOf(WideChar);
    end
    else
    begin
      {$I-}
      AssignFile(f,PUnicodeChar(newdata));
      Reset(f);
      if IOResult=0 then
      begin
        lnewsize:=Filesize(f);
        GetMem(lnew,lnewsize);
        BlockRead(f,lnew^,lnewsize);
        CloseFile(f);
      end;
    end;
  end;

  // Check for same file
  loldsize:=Ctrl^.GetSource(idx,lold);
  if loldsize=lnewsize then
  begin
    if CompareMem(lold,lnew,loldsize) then
    begin
      FreeMem(lold);
      FreeMem(lnew);
      exit(da_skip);
    end;
  end;

  if newsize=0 then
    ls:=FastWideToStr(PUnicodeChar(newdata))
  else
    ls:=FastWideToStr(Ctrl^.PathOfFile(idx))+FastWideToStr(Ctrl^.NameOfFile(idx));

  with tAskForm.Create(ls, loldsize, lnewsize) do
  begin
//    ShowModal();
//    result:=TRGDoubleAction(MyResult);
    result:=ModalToAction(ShowModal());
    Free;
  end;
  
  case result of
    da_renameold: begin
      ls:=WideToStr(Ctrl^.NameOfFile(idx));
      if InputQuery(rsRenameOld, rsNewName, ls) then
        newdata:=PByte(StrToWide(ls))
      else
        result:=da_skip;
    end;

    da_saveas: begin
      ls:=WideToStr(Ctrl^.NameOfFile(idx));
      if InputQuery(rsRenameNew, rsNewName, ls) then
        newdata:=PByte(StrToWide(ls))
      else
        result:=da_skip;
    end;

    da_compare: begin
      if istext then
      begin
        with TCompareForm.Create(lold,lnew) do
        begin
          if ShowModal()=mrOk then
          begin
            newdata:=PByte(UnicodeText());
            // skip CRLF, Add Sign
            newsize:=(Length(PUnicodeChar(newdata))-1)*SizeOf(WideChar);
            system.move(newdata^,(newdata+2)^,newsize);
            PWord(newdata)^:=SIGN_UNICODE;
            PWord(newdata+newsize)^:=0;
          end
          else
            result:=da_skip;

          Free;
        end;
      end;
    end;

  else
  end;

  FreeMem(lold);
  FreeMem(lnew);
end;

procedure TPanelForm.execImportDir(Sender: TObject);
var
  ldir,ldst:AnsiString;
  lcnt:integer;
begin
  if SelectDirectory(rsSelectDir,'',ldir) then
  begin

    lcnt:=GetActiveDir(Ctrl,ListIndex);
    ldst:=FastWideToStr(Ctrl^.Dirs[lcnt].Name);

    Ctrl^.OnDouble:=@OnImportDouble;
    lcnt:=Ctrl^.ImportDir(ldst,ldir);
    Ctrl^.OnDouble:=nil;

    if lcnt>0 then
      ShowMessage(IntToStr(lcnt)+rsImported+#13#10+rsLinkingNote)
    else
      ShowMessage(rsNothingImported);
  end;
end;

procedure TPanelForm.execImportFile(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  ldir:AnsiString;
  i,lcnt,lresult:integer;
begin
  if not GetPanelType() in [panelTree, panelList] then exit;

  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Options    :=[ofFileMustExist,ofAllowMultiSelect,ofEnableSizing];
    OpenDialog.DefaultExt :='.*';
    OpenDialog.Filter     :='';
    OpenDialog.FilterIndex:=0;

    if OpenDialog.Execute then
    begin
      i:=GetActiveDir(Ctrl,ListIndex);
      ldir:=FastWideToStr(Ctrl^.Dirs[i].Name);

      lcnt:=OpenDialog.Files.Count;
      if lcnt>1 then OnChange(@self,0,faStart);
      lresult:=0;
      for i:=0 to lcnt-1 do
      begin
        // add update as file content (as is)
        if Ctrl^.AddFileData(OpenDialog.Files[i],
            ldir+FixFileExt(ExtractName(OpenDialog.Files[i])), true)>=0 then
          inc(lresult);
      end;
      if lcnt>1 then OnChange(@self,lresult,faFinish);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TPanelForm.execRefreshList(Sender: TObject);
var
  ltype:integer;
begin
  ltype:=GetPanelType();
  if      (ltype=panelShell) or (ltype=panelShellTree) then FillShellList('')
  else if (ltype=panelList ) or (ltype=panelTree     ) then FillList(GetActiveDir(Ctrl,ListIndex));
end;

procedure TPanelForm.execExtractSelected(Sender: TObject);
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

procedure TPanelForm.execExtractDir(Sender: TObject);
begin
  ExtractDir(Ctrl,GetActiveDir(Ctrl,ListIndex),true,false);
end;

procedure TPanelForm.execExtractCurDir(Sender: TObject);
begin
  ExtractDir(Ctrl,GetActiveDir(Ctrl,ListIndex),false,false);
end;

function TPanelForm.GetPathFromNode(aNode:TTreeNode):string;
//var ldir:integer;
begin
{  ldir:=IntPtr(UIntPtr(aNode.Data));
  if ldir<0 then
    result:=''
  else
	  result:=ctrl.Dirs[ldir].Name;
}
  result:='';
  repeat
    result:=aNode.Text+'/'+result;
    aNode:=aNode.Parent;
  until aNode=nil;
end;

procedure TPanelForm.execDirList(Sender: TObject);
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

{$ENDIF}
