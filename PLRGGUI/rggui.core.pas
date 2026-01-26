{
  Read base settings
  load gui plugin
  make new pak
  load existing pak
}
{TODO: Make Event OnChangeDir for SetActiveDir (OnChangeFile for SetActiveFile?)}
{TODO: move cfgOriginal (sVanilaPath) to GUI unit}
{NOTE: Set/GetActiveFile/Dir and ClosePak supports single instance of ctrl, not doubles}
unit RGGUI.Core;

interface

uses
  IniFiles,
  RGCtrl;

{%REGION Controller}
const
  MaxDirCount = 16;
type
  TDirListElement = record
    path    :integer;                         // directory (for case when selected=-1)
    selected:integer;                         // selected file (-1 if empty [or parent])
  end;
  TCtrlListElement = record
    Ctrl  :PRGController;                     // controller
    Dirs  :array [0..MaxDirCount-1] of TDirListElement;  // list of dir list items (for multi lists)
  end;

var
  CtrlList  :array of TCtrlListElement;       // list of opened paks
  CtrlCount :integer;
  ActiveCtrl:integer;
{%ENDREGION Controller}

{%REGION Settings}
var
  cfgOriginal    :AnsiString;
  cfgGUIPlugin   :AnsiString;
  cfgUnpackDir   :AnsiString;
  cfgSaveMode    :integer;    // sm* const (See below)
  cfgUnpackTree  :Boolean;
  cfgUsePAKName  :Boolean;
  cfgMakeMODDAT  :Boolean;
  cfgFastScan    :Boolean;
  cfgSaveDateTime:Boolean;
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

{%REGION Events}
type
  TSelectFileEvent = procedure (idx:integer; actrl:PRGController; aList:integer) of object;

procedure AddFileEventHandler(aproc:TSelectFileEvent);
procedure AddDirEventHandler (aproc:TSelectFileEvent);
procedure RemoveEventHandler (aproc:TSelectFileEvent);
{%ENDREGION Events}

function  GetCtrlIndex(actrl:PRGController):integer;
function  GetCtrl     (aidx:integer):PRGController;

procedure SetActiveFile(aidx:integer; actrl:PRGController{=nil}; aList:integer=0);
function  GetActiveFile(              actrl:PRGController{=nil}; aList:integer=0):integer;
procedure SetActiveDir (adir:integer; actrl:PRGController{=nil}; aList:integer=0);
function  GetActiveDir (              actrl:PRGController{=nil}; aList:integer=0):integer;

procedure LoadCoreSettings(acfg:TIniFile=nil);
procedure SaveCoreSettings(acfg:TIniFile=nil);

function NewPak  ():PRGController;
function LoadPak (const aname:AnsiString):PRGController;
function ClosePak(actrl:PRGController=nil; aforce:boolean=false):boolean;

{%REGION Unpack}
type
  TUnpackFileEvent = function (const adir, aname:string):integer of object;

function SaveFile(actrl:PRGController; aidx:integer; testonly:boolean=false):boolean;
function SaveFile(const adir,aname:string;        // destination dir and filename
                  adata:PByte; asize:integer;
                  aver:integer):boolean;
function SaveFile(const adir,aname:string;        // destination dir and filename
                  adata:PByte; asize:integer;
                  aver:integer; atime:TDateTime;  // if not 0, set time of file changing
                  testonly:boolean):boolean;      // do not save on disk. for unpack/convert check

function ExtractDir(actrl:PRGController; adir:integer; asubdir:boolean; testonly:boolean=false):integer;
{%ENDREGION Unpack}


implementation

uses
  SysUtils,
  RGGlobal,

  RGFileType,
  RGFile,
  RGMod,
  RGPak
  ;


{%REGION Events}
type
  TEventHandlers = array of TSelectFileEvent;
var
  SFHandlers:TEventHandlers;
  SDHandlers:TEventHandlers;

procedure AddHandler(var ahandlers:TEventHandlers; aproc:TSelectFileEvent);
var
  i,lidx:integer;
begin
  for i:=0 to High(ahandlers) do
  begin
    if TMethod(ahandlers[i]).Data=TMethod(aproc).Data then
    begin
      ahandlers[i]:=aproc;
      exit;
    end;
  end;
  lidx:=Length(ahandlers);
  SetLength(ahandlers,lidx+1);
  ahandlers[lidx]:=aproc;
end;

procedure AddFileEventHandler(aproc:TSelectFileEvent);
begin
  AddHandler(SFHandlers, aproc);
end;

procedure AddDirEventHandler(aproc:TSelectFileEvent);
begin
  AddHandler(SDHandlers, aproc);
end;

procedure RemoveEventHandler(aproc:TSelectFileEvent);
var
  i:integer;
begin
  // check for file select
  for i:=0 to High(SFHandlers) do
  begin
    if SFHandlers[i]=aproc then
    begin
      Delete(SFHandlers,i,1);
      exit;
    end;
  end;

  // Check for dir activate
  for i:=0 to High(SDHandlers) do
  begin
    if SDHandlers[i]=aproc then
    begin
      Delete(SDHandlers,i,1);
      exit;
    end;
  end;
end;
{%ENDREGION Events}

{%REGION Controller}
function GetCtrl(aidx:integer):PRGController; inline;
begin
  if (aidx>=0) and (aidx<CtrlCount) then
    result:=CtrlList[aidx].Ctrl
  else
    result:=nil;
end;

function GetCtrlIndex(actrl:PRGController):integer;
var
  i:integer;
begin
  if actrl=nil then
  begin
    if (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then
      exit(ActiveCtrl);
  end
  else
  begin
    for i:=0 to CtrlCount-1 do
      if CtrlList[i].ctrl=actrl then
        exit(i);
  end;
  result:=-1;
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
{%ENDREGION Controller}

{%REGION Settings}
const
  sSectSettings = 'settings';
  sGUIDir       = 'guidir';
  sUnpackDir    = 'outdir';
  sUnpackTree   = 'savepath';
  sUsePAKName   = 'usefname';
  sSaveUTF8     = 'saveutf8';
  sFastScan     = 'fastscan';
  sSaveMode     = 'decoding';
  sMODDAT       = 'moddat';
  sSaveSettings = 'savesettings';
  sSaveDateTime = 'savedatetime';
  sDebugLevel   = 'debuglevel';

  sVanilaPath   = 'originalpath';

procedure SaveCoreSettings(acfg:TIniFile=nil);
var
  config:TIniFile;
begin
  if cfgSaveSettings then
  begin
    if acfg=nil then
      config:=TMemIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes])
    else
      config:=acfg;

    config.WriteString (sSectSettings,sVanilaPath  ,cfgOriginal);

    config.WriteString (sSectSettings,sUnpackDir   ,cfgUnpackDir);
    config.WriteBool   (sSectSettings,sUnpackTree  ,cfgUnpackTree);
    config.WriteBool   (sSectSettings,sUsePakName  ,cfgUsePakName);
    config.WriteBool   (sSectSettings,sMODDAT      ,cfgMakeMODDAT);
    config.WriteBool   (sSectSettings,sFastScan    ,cfgFastScan);
    config.WriteBool   (sSectSettings,sSaveDateTime,cfgSaveDateTime);
    config.WriteBool   (sSectSettings,sSaveUTF8    ,cfgSaveUTF8);
    config.WriteInteger(sSectSettings,sSaveMode    ,cfgSaveMode);

    config.WriteBool   (sSectSettings,sSaveSettings,cfgSaveSettings);

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

  cfgOriginal    :=config.ReadString (sSectSettings,sVanilaPath  ,'');

  cfgUnpackDir   :=config.ReadString (sSectSettings,sUnpackDir   ,ExtractFileDir(ParamStr(0)));
  cfgUnpackTree  :=config.ReadBool   (sSectSettings,sUnpackTree  ,true);
  cfgUsePAKName  :=config.ReadBool   (sSectSettings,sUsePAKName  ,true);
  cfgMakeMODDAT  :=config.ReadBool   (sSectSettings,sMODDAT      ,true);
  cfgFastScan    :=config.ReadBool   (sSectSettings,sFastScan    ,false);
  cfgSaveDateTime:=config.ReadBool   (sSectSettings,sSaveDateTime,true);
  cfgSaveUTF8    :=config.ReadBool   (sSectSettings,sSaveUTF8    ,false);
  cfgSaveMode    :=config.ReadInteger(sSectSettings,sSaveMode    ,smRename);

  cfgSaveSettings:=config.ReadBool   (sSectSettings,sSaveSettings,false);

  if acfg=nil then config.Free;
end;
{%ENDREGION Settings}

{%REGION Container}
function NewPak():PRGController;
begin
  result:=ExpandCtrlList();
  result^.NewDir('MEDIA/');
  result^.PAK.Name:='NewPak'+IntToStr(CtrlCount); //!!
end;

function LoadPak(const aname:AnsiString):PRGController;
var
  lmode:integer;
begin
  result:=ExpandCtrlList();
  with result^ do
  begin
    if cfgFastScan then
      lmode:=piParse
    else
      lmode:=piFullParse;
    if PAK.GetInfo(aname,lmode) then
      Rebuild();
  end;
end;

function ClosePak(actrl:PRGController=nil; aforce:boolean=false):boolean;
var
  i:integer;
begin
  result:=false;
//  if (actrl=nil) then actrl:=GetCtrl(ActiveCtrl);
  if (actrl=nil) and (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then actrl:=CtrlList[ActiveCtrl].Ctrl;
  if (actrl=nil) then exit;

  if actrl^.UpdatesCount()>0 then
  begin
    if not aforce then exit;
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
{%ENDREGION Container}

{%REGION File}
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
                  aver:integer):boolean;
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

function SaveFile(actrl:PRGController; aidx:integer; testonly:boolean=false):boolean;
var
  lbuf:PByte;
  loutdir,lsdir,lsname:string;
  ltime:TDateTime;
  lsize:integer;
begin
  result:=false;
  if aidx<0 then exit;
//  if (actrl=nil) then actrl:=GetCtrl(ActiveCtrl);
  if (actrl=nil) and (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then actrl:=CtrlList[ActiveCtrl].Ctrl;
  if (actrl=nil) then exit;

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

    if cfgSaveDateTime then
      ltime:=FileTimeToDateTime(actrl^.Files[aidx]^.ftime);
  end;

  RGLog.Reserve('Processing '+lsdir+lsname);

  result:=SaveFile(loutdir, lsname, lbuf, lsize, actrl^.PAK.Version, ltime, testonly);

  FreeMem(lbuf);
end;

function ExtractDir(actrl:PRGController; adir:integer; asubdir:boolean; testonly:boolean=false):integer;
var
  ls,pc:PWideChar;
  i,llen:integer;
  lfile:integer;
//  ldl:TRGDebugLevel;
begin
  result:=0;
  if actrl^.IsDirDeleted(adir) then exit;

//  ldl:=rgDebugLevel;

  if not asubdir then
  begin
    if actrl^.GetFirstFile(lfile,adir) then
      repeat
        if SaveFile(actrl,lfile,testonly) then inc(result);
      until not actrl^.GetNextFile(lfile);

    exit;
  end;

  if adir>0 then
  begin
    ls:=actrl^.Dirs[adir].Name;
    llen:=Length(ls);
  end
  else
  begin
    ls:='';
    llen:=0;
  end;

  for i:=0 to actrl^.DirCount-1 do
  begin
    if not actrl^.IsDirDeleted(i) then
    begin
      pc:=actrl^.Dirs[i].name;
      if (adir<=0) or (i=adir) or (CompareWide(ls,pc,llen)=0) then
      begin
//        StatusBar.Panels[1].Text:=rsExtractDir+WideToStr(pc);
//        StatusBar.Update;

        if actrl^.GetFirstFile(lfile,i) then
          repeat
            if SaveFile(actrl,lfile,testonly) then inc(result);
          until not actrl^.GetNextFile(lfile);
      end;
    end;
  end;

  if (adir<0) and (cfgMakeMODDAT) and (actrl^.PAK.Version=verTL2Mod) then
  begin
    SaveModConfig(actrl^.PAK.modinfo,PChar(cfgUnpackDir+'\'+TL2ModData));
  end;
//  StatusBar.Panels[1].Text:=rsFilePath+sgMain.Cells[colDir ,sgMain.Row];
//  ShowMessage(GetPathFromNode(PopupNode)+#13#10+rsUnpackSucc);

//  rgDebugLevel:=ldl;
end;
{%ENDREGION File}

{%REGION Runtime}
procedure SetActiveFile(aidx:integer; actrl:PRGController{=nil}; aList:integer=0);
var
  i:integer;
begin
  i:=GetCtrlIndex(actrl);
  if i>=0 then
  begin
    with CtrlList[i] do
    begin
      if (aList<0) or (aList>=MaxDirCount) then aList:=0;
      Dirs[aList].selected:=aidx;
    end;
    for i:=0 to High(SFHandlers) do
      SFHandlers[i](aidx,actrl,aList);
  end;
end;

function GetActiveFile(actrl:PRGController{=nil}; aList:integer=0):integer;
var
  i:integer;
begin
  i:=GetCtrlIndex(actrl);
  if i>=0 then
    with CtrlList[i] do
    begin
      if (aList<0) or (aList>=MaxDirCount) then aList:=0;
      exit(Dirs[aList].selected);
    end;
  result:=-1;
end;

procedure SetActiveDir(adir:integer; actrl:PRGController{=nil}; aList:integer=0);
var
  i:integer;
begin
  i:=GetCtrlIndex(actrl);
  if i>=0 then
    with CtrlList[i] do
    begin
      if (aList<0) or (aList>=MaxDirCount) then aList:=0;
      with Dirs[aList] do
        if path<>adir then
        begin
          path    :=adir;
          selected:=-1;
          for i:=0 to High(SDHandlers) do
            SDHandlers[i](adir,actrl,aList);
        end;
    end;
end;

function GetActiveDir(actrl:PRGController{=nil}; aList:integer=0):integer;
var
  i:integer;
begin
  i:=GetCtrlIndex(actrl);
  if i>=0 then
    with CtrlList[i] do
    begin
      if (aList<0) or (aList>=MaxDirCount) then aList:=0;
      exit(Dirs[aList].path);
    end;
  result:=-1;
end;
{%ENDREGION Runtime}

procedure CloseAll();
begin
  while CtrlCount>0 do
  begin
    dec(CtrlCount);
    CtrlList[CtrlCount].ctrl^.Free;
    FreeMem(CtrlList[CtrlCount].ctrl);
  end;
  SetLength(CtrlList,0);
end;

finalization

  CloseAll();

end.
