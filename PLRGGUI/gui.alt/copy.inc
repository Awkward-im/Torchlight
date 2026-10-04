{TODO: Check again: FROM=get file and format, get path; TO=check and create path, check and copy file}

{$IFDEF Interface}

  function CopyShellToShell(const asrc, adst:AnsiString; var aact:TRGDoubleAction):integer;
  function CopyShellToCtrl (const asrc:AnsiString; actrl:PRGController; const adst:AnsiString):integer;
  function CopyCtrlToShell (actrl:PRGController; aidx:integer; const apath:AnsiString):integer;
  function CopyCtrlToCtrl  (asrc :PRGController; aidx:integer; adst:PRGController; apath:PUnicodeChar):integer;
  procedure Copy();
  function OnImportDouble(actrl:PRGController; idx:integer;
           var newdata:PByte; var newsize:integer):TRGDoubleAction;

{$ELSE}

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

function TRGGUI2Form.CopyShellToShell(const asrc, adst:AnsiString; var aact:TRGDoubleAction):integer;
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

function TRGGUI2Form.CopyShellToCtrl(const asrc:AnsiString; actrl:PRGController; const adst:AnsiString):integer;
begin
  result:=0;

  if asrc[Length(asrc)] in ['\','/'] then
    result:=actrl^.ImportDir(adst+ExtractName(asrc),asrc,false,false)
  else
    if actrl^.AddFileData(asrc,
        adst+FixFileExt(ExtractName(asrc)), true)>=0 then
      inc(result);
end;

function TRGGUI2Form.CopyCtrlToShell(actrl:PRGController; aidx:integer; const apath:AnsiString):integer;
var
  lname,ls:AnsiString;
  lbuf:PByte;
  lidx,lsize:integer;
begin
  result:=0;
  lname:=FastWideToStr(actrl^.NameOfFile(aidx));
  ls:=apath+lname;
  if actrl^.IsDir(aidx) then
  begin
    if not DirectoryExists(ls) then MkDir(ls);

    if actrl^.GetFirstFile(lidx,actrl^.AsDir(aidx)) then
    begin
      repeat
        inc(result,CopyCtrlToShell(actrl,lidx, ls));
      until not actrl^.GetNextFile(lidx);
    end;
  end
  else
  begin
    if not FileExists(ls) then
    begin
      lbuf:=nil;
      lsize:=actrl^.GetAsIs(aidx,lbuf);
      if lsize>0 then
      begin
        if SaveFile(apath,lname,lbuf,lsize,
           actrl^.Pak.Version,
           FileTimeToDateTime(actrl^.Files[aidx]^.ftime), false) then inc(result);
        FreeMem(lbuf);
      end;
    end
    else
    begin
    end;
  end;
end;

function TRGGUI2Form.CopyCtrlToCtrl(
               asrc:PRGController; aidx:integer;
               adst:PRGController; apath:PUnicodeChar):integer;
var
  lpc,pc:PUnicodeChar;
  psrc,pdst:PRGCtrlInfo;
  ls:AnsiString;
  lcs_s,lcs_d:dword;
  lidx:integer;
  lact:TRGDoubleAction;
begin
  result:=0;
  pc:=ConcatWide(apath,asrc^.NameOfFile(aidx));
  if asrc^.IsDir(aidx) then
  begin
    adst^.NewDir(pc);
    if asrc^.GetFirstFile(lidx,asrc^.AsDir(aidx)) then
    begin
      repeat
        inc(result,CopyCtrlToCtrl(asrc, lidx, adst, pc));
      until not asrc^.GetNextFile(lidx);
    end;
  
  end
  else
  begin
    lidx:=adst^.SearchFile(pc);
    if lidx<0 then
    begin
      if adst^.CopyFile(asrc, aidx, pc) then result:=1;
    end
    else
    begin
      psrc:=asrc^.Files[aidx];
      pdst:=adst^.Files[lidx];

      // File with same name but different checksum (content)
      if psrc^.checksum<>pdst^.checksum then
      begin
//        ShowMessage(IntToStr(Ord(actrl^.OnDouble(lidx,PByte(apath),0))));
        // Skip, overwrite, update, [to all], stop

        lpc:=ConcatWide(adst^.PathOfFile(lidx),adst^.NameOfFile(lidx));
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
                InputBox('Rename existing file', 'Enter new name', asrc^.NameOfFile(lidx)) );
          end;

          da_saveas: begin
            lpc:=StrToWide(
                InputBox('Rename new file', 'Enter new name', asrc^.NameOfFile(lidx)) );
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

procedure TRGGUI2Form.Copy();
var
  lpath:PUnicodeChar;
  lsrc,ldst:PRGController;
  lpsrc,lpdst:TPanelForm;
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
        result:=CopyShellToCtrl (lpsrc.ShellPath+FastWideToStr(lsrc^.NameOfFile(aidx)),ldst,lspath)
      else
        result:=CopyShellToShell(lpsrc.ShellPath+FastWideToStr(lsrc^.NameOfFile(aidx)),lspath,lact);
    end
    else if (ldsttype=panelList) or (ldsttype=panelTree) then
    begin
      result:=CopyCtrlToCtrl(lsrc,aidx,ldst,lpath);
    end
    else
      result:=CopyCtrlToShell(lsrc,aidx,lspath);
  end;

begin
  lpsrc:=TPanelForm(Panels[ActivePanel]);
  lsrctype:=lpsrc.GetPanelType();
  if not lsrctype in [panelList,panelTree,panelShell,panelShellTree] then exit;

  lpdst:=TPanelForm(GetOppositePanel(lpsrc));
  ldsttype:=lpdst.GetPanelType();
  if not ldsttype in [panelList,panelTree,panelShell,panelShellTree] then exit;

  lsrc:=lpsrc.Ctrl;
  ldst:=lpdst.Ctrl;
  if (ldsttype=panelShell) or (ldsttype=panelShellTree) then
  begin
    lspath:=lpdst.ShellPath;
    ls:=Format(rsSureToCopyShell,[lspath]);
    lpath:=nil;
  end
  else
  begin
    // MUST use copy coz name buffer can be changed while copying files
    lpath:=CopyWide(ldst^.Dirs[GetActiveDir(ldst,lpdst.ListIndex)].Name);
    lspath:=FastWideToStr(lpath);
    ls:=StringReplace(
      StringReplace(rsSureToCopy,'$1',ldst^.Pak.Name,[]),
      '$2',lpath,[]);
  //  ls:=Format(rsSureToCopy,[ldst^.Pak.Name,lpath]);
  end;
  
  if MessageDlg(ls,mtConfirmation,mbOkCancel,0)<>mrOk then exit;

  ldst^.OnDouble:=@OnImportDouble;

  lact:=da_ask;
  arr:=nil;
  lidx:=lpsrc.GetSelectionList(arr);
  //!! don't forget to check destination file existing !!
  if lidx<0 then
  begin
    lcopied:=0;
    ldst^.OnChange(ldst,0,faStart);

    for i:=0 to Length(arr)-1 do
      inc(lcopied,CopySingle(arr[i]));

    ldst^.OnChange(ldst,lcopied,faFinish);
    SetLength(arr,0);
  end
  else
    lcopied:=CopySingle(lidx);

  FreeMem(lpath);

  ldst^.OnDouble:=nil;

  if lcopied>0 then
  begin
    ShowMessage(rsCopied+' '+IntToStr(lcopied));
    lpdst.RefreshList();
  end
  else
    ShowMessage(rsNotCopied);
end;

function TRGGUI2Form.OnImportDouble(actrl:PRGController; idx:integer;
         var newdata:PByte; var newsize:integer):TRGDoubleAction;
var
  ls:AnsiString;
  f:file of byte;
  lold,lnew:PByte;
  loldsize,lnewsize:integer;
  istext:boolean;
begin
  result:=da_skip;
(*
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
*)
end;

{$ENDIF}
