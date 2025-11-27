{
  Read base settings
  load gui plugin
  make new pak
  load existing pak
}
unit RGGUI.Core;

interface

uses
  inifiles,
  rgctrl;

{%REGION Controller}
type
  TDirListElement = record
    path    :integer;                         // directory (for case when selected=-1)
    selected:integer;                         // selected file (-1 if empty [or parent])
  end;
  TCtrlListElement = record
    Ctrl   :PRGController;                    // controller
    Items  :array [0..15] of TDirListElement; // list of dir list items (for multi lists)
    CurItem:integer;                          // index of Items array
  end;

var
  CtrlList  :array of TCtrlListElement;
  CtrlCount :integer;
  ActiveCtrl:integer;
{%ENDREGION Controller}

{%REGION Settings}
var
  cfgGUIPlugin   :AnsiString;
  cfgUnpackTree  :Boolean;
  cfgUsePAKName  :Boolean;
  cfgMakeMODDAT  :Boolean;
  cfgFastScan    :Boolean;
  cfgSaveDateTime:Boolean;
  cfgUnpackDir   :AnsiString;
  cfgSaveMode    :integer;    // sm* const (See below)
  cfgSaveUTF8    :Boolean;
  cfgSaveSettings:Boolean;

// Save Mode
const
  smBinary = 1;
  smText   = 2;
  smRename = 3;
  smGUTS   = 4;
  
var
  ConfigName:AnsiString;

{%ENDREGION Settings}

procedure SetActiveFile(aidx:integer; actrl:PRGController=nil; aItem:integer=0);
function  GetActiveFile(              actrl:PRGController=nil; aItem:integer=0):integer;
procedure SetActiveDir (aidx:integer; actrl:PRGController=nil; aItem:integer=0);
function  GetActiveDir (              actrl:PRGController=nil; aItem:integer=0):integer;

procedure LoadCoreSettings(acfg:TIniFile=nil);
procedure SaveCoreSettings(acfg:TIniFile=nil);

function NewPak  ():PRGController;
function LoadPak (const aname:AnsiString):PRGController;
function ClosePak(actrl:PRGController=nil):boolean;

function SaveFile(actrl:PRGController; aidx:integer;
      testonly:boolean=false):boolean;


implementation

uses
  SysUtils,
  rgglobal,

  rgfiletype,
  rgfile,
  rgpak
  ;
  
const
  sSectSettings = 'settings';
  sGUIDir       = 'guidir';
  sOutDir       = 'outdir';
  sSavePath     = 'savepath';
  sUsePAKName   = 'usefname';
  sSaveUTF8     = 'saveutf8';
  sFastScan     = 'fastscan';
  sDecoding     = 'decoding';
  sMODDAT       = 'moddat';
  sSaveSettings = 'savesettings';
  sSaveDateTime = 'savedatetime';
  sDebugLevel   = 'debuglevel';
{
  sSectSrcFont  = 'srcfont';
  sFontName     = 'Name';
  sFontCharset  = 'Charset';
  sFontSize     = 'Size';
  sFontStyle    = 'Style';
  sFontColor    = 'Color';
}
procedure SaveCoreSettings(acfg:TIniFile=nil);
var
  config:TIniFile;
//  ls:AnsiString;
//  lstyle:TFontStyles;
begin
  if cfgSaveSettings then
  begin
    if acfg=nil then
      config:=TMemIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes])
    else
      config:=acfg;

    config.WriteString (sSectSettings,sOutDir      ,cfgUnpackDir);
    config.WriteBool   (sSectSettings,sSavePath    ,cfgUnpackTree);
    config.WriteBool   (sSectSettings,sUsePakName  ,cfgUsePakName);
    config.WriteBool   (sSectSettings,sMODDAT      ,cfgMakeMODDAT);
    config.WriteBool   (sSectSettings,sFastScan    ,cfgFastScan);
    config.WriteBool   (sSectSettings,sSaveDateTime,cfgSaveDateTime);
    config.WriteBool   (sSectSettings,sSaveUTF8    ,cfgSaveUTF8);
    config.WriteInteger(sSectSettings,sDecoding    ,cfgSaveMode);

    config.WriteBool   (sSectSettings,sSaveSettings,cfgSaveSettings);

    //--- Font
{
    config.WriteString (sSectSrcFont,sFontName   ,SrcFont.Name);
    config.WriteInteger(sSectSrcFont,sFontCharset,SrcFont.Charset);
    config.WriteInteger(sSectSrcFont,sFontSize   ,SrcFont.Size);
    config.WriteString (sSectSrcFont,sFontColor  ,ColorToString(SrcFont.Color));

    lstyle:=SrcFont.Style;
    ls:='';
    if fsBold      in lstyle then ls:='bold ';
    if fsItalic    in lstyle then ls:=ls+'italic ';
    if fsUnderline in lstyle then ls:=ls+'underline ';
    if fsStrikeOut in lstyle then ls:=ls+'strikeout ';
    config.WriteString(sSectSrcFont,sFontStyle,ls);
}
    if acfg=nil then
    begin
      config.UpdateFile;
      config.Free;
    end;
  end;
end;

procedure LoadCoreSettings(acfg:TIniFile=nil);
var
  config:TIniFile;
//  ls:AnsiString;
//  lstyle:TFontStyles;
begin
  if acfg=nil then
  begin
    if ConfigName='' then ConfigName:=ChangeFileExt(ParamStr(0),'.INI');
    config:=TIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes])
  end
  else
  begin
    if ConfigName='' then ConfigName:=acfg.FileName;
    config:=acfg;
  end;

  rgDebugLevel:=TRGDebugLevel(config.ReadInteger(sSectSettings,sDebugLevel,1));

  cfgGUIPlugin   :=config.ReadString (sSectSettings,sGUIDir,'');

  cfgUnpackDir   :=config.ReadString (sSectSettings,sOutDir      ,ExtractFileDir(ParamStr(0)));
  cfgUnpackTree  :=config.ReadBool   (sSectSettings,sSavePath    ,true);
  cfgUsePAKName  :=config.ReadBool   (sSectSettings,sUsePAKName  ,true);
  cfgMakeMODDAT  :=config.ReadBool   (sSectSettings,sMODDAT      ,true);
  cfgFastScan    :=config.ReadBool   (sSectSettings,sFastScan    ,false);
  cfgSaveDateTime:=config.ReadBool   (sSectSettings,sSaveDateTime,true);
  cfgSaveUTF8    :=config.ReadBool   (sSectSettings,sSaveUTF8    ,false);
  cfgSaveMode    :=config.ReadInteger(sSectSettings,sDecoding    ,smRename);

  cfgSaveSettings:=config.ReadBool   (sSectSettings,sSaveSettings,false);

//--- Font
{
  SrcFont.Name   :=config.ReadString (sSectSrcFont,sFontName   ,defFontName);
  SrcFont.Charset:=config.ReadInteger(sSectSrcFont,sFontCharset,defFontCharset);
  SrcFont.Size   :=config.ReadInteger(sSectSrcFont,sFontSize   ,defFontSize);
  SrcFont.Color  :=StringToColor(
      config.ReadString(sSectSrcFont,sFontColor,ColorToString(defFontColor)));

  ls:=config.ReadString(sSectSrcFont,sFontStyle,defFontStyle);
  lstyle:=[];
  if Pos('bold'     ,ls)<>0 then lstyle:=lstyle+[fsBold];
  if Pos('italic'   ,ls)<>0 then lstyle:=lstyle+[fsItalic];
  if Pos('underline',ls)<>0 then lstyle:=lstyle+[fsUnderline];
  if Pos('strikeout',ls)<>0 then lstyle:=lstyle+[fsStrikeOut];
  SrcFont.Style:=lstyle;
  SetPreviewFont(SrcFont);
}
  if acfg=nil then config.Free;
end;

function ExpandCtrlList():PRGController;
begin
  if CtrlCount>=Length(CtrlList) then
    SetLength(CtrlList,CtrlCount+8);
  FillChar(CtrlList[CtrlCount],SizeOf(TCtrlListElement),0);
  GetMem(result,SizeOf(TRGController));
  result^.Init;
  CtrlList[CtrlCount].Ctrl:=result;
  ActiveCtrl:=CtrlCount;
  inc(CtrlCount);
end;

function NewPak():PRGController;
begin
  result:=ExpandCtrlList();
  result^.NewDir('MEDIA/');
end;

function LoadPak(const aname:AnsiString):PRGController;
var
  lmode:integer;
begin
  result:=ExpandCtrlList();
  with result^ do
  begin
{
  StatusBar.Panels[1].Text:=rsReadPAK;
  Application.ProcessMessages;
}
    if cfgFastScan then
      lmode:=piParse
    else
      lmode:=piFullParse;
    if PAK.GetInfo(aname,lmode) then
      Rebuild();
  end;
end;

function ClosePak(actrl:PRGController=nil):boolean;
var
  i:integer;
begin
  result:=false;
  if (actrl=nil) and (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then
     actrl:=CtrlList[ActiveCtrl].Ctrl;
  if actrl^.UpdatesCount()>0 then
  begin
{    if MessageDlg(rsWarning,rsUnsaved,mtWarning,
       [mbOK,mbCancel],0,mbCancel)<>mrOk then
    begin
      exit(false);
    end;
}
  end;

  actrl^.Free;

  for i:=0 to CtrlCount-1 do
  begin
    if CtrlList[i].Ctrl=actrl then
    begin
      if i<(CtrlCount-1) then
        move(CtrlList[i+1],CtrlList[i],SizeOf(TCtrlListElement)*(CtrlCount-i-1));
      FreeMem(actrl);
      dec(CtrlCount);
      break;
    end;
  end;
  result:=true;
end;

function SaveFile(const adir,aname:string;
                  adata:PByte; asize:integer;
                  aver:integer; atime:TDateTime;
                  testonly:boolean):boolean;
var
  f:file of byte;
  pc:PUnicodeChar;
  ls,lext:string;
  ltype,lsize:integer;
  ldecompiled:boolean;
begin
  result:=false;

  ltype:=RGTypeOfExt(aname);

  ldecompiled:=IsSource(adata);
  ls:=adir+aname;

  // save decoded file

  if (cfgSaveMode<>smBinary) and ((ltype and $FF)=typeData) then
  begin
    if not ldecompiled then
    begin
      DecompileFile(adata, asize, ls, pc, cfgSaveUTF8);
    end
    else
    begin
      pc:=pointer(adata);
      case GetSourceEncoding(adata) of
        tofSrcWide: if     cfgSaveUTF8 then pc:=pointer(WideToUtf8(PUnicodeChar(adata)));
        tofSrcUTF8: if not cfgSaveUTF8 then pc:=        UTF8ToWide(PAnsiChar   (adata));
      end;
    end;

    if (pc<>nil) and not testonly then
    begin
      if (cfgSaveMode=smRename) or (ltype=typeRaw) then
        lext:='.TXT'
      else
        lext:='';

      AssignFile(f,ls+lext);
      Rewrite(f);
      if IOResult=0 then
      begin
        if cfgSaveUTF8 then
          lsize:=Length(PAnsiChar(pc))
        else
          lsize:=Length(pc)*SizeOf(WideChar);
        BlockWrite(f,pc^,lsize);
        CloseFile(f);
        if atime>0 then FileSetDate(ls+lext,atime);
      end;
    end;
    
    if PByte(pc)<>adata then FreeMem(pc);
  end;

  // save binary file

  pc:=pointer(adata);
  if ldecompiled and (cfgSaveMode<>smText) and ((ltype and $FF)=typeData) then
  begin
    adata:=nil;
    asize:=CompileFile(PByte(pc),aname,adata,aver);
  end;
  
  if not testonly then
  begin
    // set decoding binary file extension
    lext:='';
    if (cfgSaveMode=smGUTS) and ((ltype and $FF)=typeData) then
    begin
      if ltype=typeLayout then
      begin
        if aver=verTL1 then
        begin
          // TL1 have different LAYOUT format for UI dir
          if (not ldecompiled) and
             (Pos('MEDIA/UI/',adir)>0) then
//             (Pos('MEDIA/UI/',UpCase(StringReplace(adir,'\','/',[rfReplaceAll])))=1) then
            lext:=''
          else
            lext:='.CMP'
        end
        else
          lext:='.BINLAYOUT'
      end
      else if ltype=typeRaw then
        lext:=''
      else
      begin
        // TL1 and TL2 have XML form of Imageset
        if (ltype=typeImageset) and (not ldecompiled) and
           (ABS(aver) in [verTL1,verTL2]) then
          lext:=''
        else if aver=verTL1 then
          lext:='.ADM'
        else
          lext:='.BINDAT';
      end;
    end;

    // save binary file
    if not ((cfgSaveMode=smText) and ((ltype and $FF)=typeData)) or
       ((ltype=typeImageset) and (not ldecompiled)) then
    begin
      ls:=ls+lext;
      AssignFile(f,ls);
      Rewrite(f);
      if IOResult=0 then
      begin
        BlockWrite(f,adata^,asize);
        CloseFile(f);
        if atime>0 then FileSetDate(ls,atime);
      end;
    end;
  end;
  if adata<>PByte(pc) then FreeMem(adata); // if conversion from text

  result:=true;
end;

function SaveFile(const adir,aname:string;
                  adata:PByte; asize:integer;
                  aver:integer=verUnk):boolean;
var
  loutdir:string;
begin
  if (adir<>'') and not (adir[Length(adir)] in ['\','/']) then
    loutdir:=adir+'\'
  else
    loutdir:=adir;

  RGLog.Reserve('Saving '+loutdir+aname);

  result:=SaveFile(loutdir, aname, adata, asize, aver, 0, false);
end;

function SaveFile(actrl:PRGController; aidx:integer;
      testonly:boolean=false):boolean;
var
  lbuf:PByte;
  loutdir,lsdir,lsname:string;
  ltime:TDateTime;
  lsize:integer;
begin
  result:=false;
  if aidx<0 then exit;

  // try to get data
  if actrl^.Files[aidx]^.ftype=typeDirectory then exit;

  lbuf:=nil;
  lsize:=actrl^.GetAsIs(aidx,lbuf);
  if lsize=0 then exit;

  // try to create dir

  lsdir :=FastWideToStr(actrl^.PathOfFile(aidx));
  lsname:=FastWideToStr(actrl^.NameOfFile(aidx));

  ltime:=0;
  if not testonly then
  begin
    if cfgUnpackDir='' then
      loutdir:=ExtractFileDir(ParamStr(0))
    else
      loutdir:=cfgUnpackDir;
    if not (loutdir[Length(loutdir)] in ['\','/']) then loutdir:=loutdir+'\';

    if cfgUsePakName then loutdir:=loutdir+actrl^.PAK.Name+'\';
    if cfgUnpackTree then loutdir:=loutdir+lsdir;

    if not ForceDirectories(loutdir) then exit;

    // 2.5 - try to get file time

    if cfgSaveDateTime then
      ltime:=FileTimeToDateTime(actrl^.Files[aidx]^.ftime);
  end;

  RGLog.Reserve('Processing '+lsdir+lsname);

  result:=SaveFile(loutdir, lsname, lbuf, lsize, actrl^.PAK.Version, ltime, testonly);

  FreeMem(lbuf);
end;

procedure SetActiveFile(aidx:integer; actrl:PRGController=nil; aItem:integer=0);
var
  i:integer;
begin
  if (actrl= nil) and (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then actrl:=CtrlList[ActiveCtrl].Ctrl;
  if (actrl<>nil) then
  begin
    for i:=0 to CtrlCount-1 do
    begin
      if CtrlList[i].ctrl=actrl then
      begin
        with CtrlList[i] do
        begin
          if (CurItem>=0) and (CurItem<16) then
          begin
            Items[CurItem].selected:=aidx;
          end;
        end;
        break;
      end;
    end;
  end;
end;

function GetActiveFile(actrl:PRGController=nil; aItem:integer=0):integer;
var
  i:integer;
begin
  if (actrl=nil) and (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then actrl:=CtrlList[ActiveCtrl].Ctrl;
  if (actrl<>nil) then
  begin
    for i:=0 to CtrlCount-1 do
    begin
      if CtrlList[i].ctrl=actrl then
      begin
        with CtrlList[i] do
        begin
          if (CurItem>=0) and (CurItem<16) then
            exit(Items[CurItem].selected);
        end;
      end;
    end;
  end;
  result:=-1;
end;

procedure SetActiveDir(aidx:integer; actrl:PRGController=nil; aItem:integer=0);
var
  i:integer;
begin
  if (actrl= nil) and (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then actrl:=CtrlList[ActiveCtrl].Ctrl;
  if (actrl<>nil) then
  begin
    for i:=0 to CtrlCount-1 do
    begin
      if CtrlList[i].ctrl=actrl then
      begin
        with CtrlList[i] do
        begin
          if (CurItem>=0) and (CurItem<16) then
          begin
            Items[CurItem].path:=aidx;
          end;
        end;
        break;
      end;
    end;
  end;
end;

function GetActiveDir(actrl:PRGController=nil; aItem:integer=0):integer;
var
  i:integer;
begin
  if (actrl=nil) and (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then actrl:=CtrlList[ActiveCtrl].Ctrl;
  if (actrl<>nil) then
  begin
    for i:=0 to CtrlCount-1 do
    begin
      if CtrlList[i].ctrl=actrl then
      begin
        with CtrlList[i] do
        begin
          if (CurItem>=0) and (CurItem<16) then
            exit(Items[CurItem].path);
        end;
      end;
    end;
  end;
  result:=-1;
end;

end.
