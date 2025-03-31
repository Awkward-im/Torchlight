unit TLScan;


interface

uses
  rgglobal;

type
  // 0 - process; 1 - skip; 2 - stop
  TOnFileScan   = function  (const fname:AnsiString; idx, atotal:integer):integer of object;

  TDoAddModInfo = procedure (const mi:TTL2ModInfo) of object;
  TDoAddString  = function  (const astr:PWideChar;
      const afile, atag:AnsiString; aline:integer):integer of object;

const
  OnFileScan  :TOnFileScan   = nil;

  DoAddModInfo:TDoAddModInfo = nil;
  DoAddString :TDoAddString  = nil;


function Scan(const adir:AnsiString; allText:boolean; withChild:boolean):boolean;
function Scan(const afile:AnsiString):boolean;


implementation

uses
  Classes,
  SysUtils,

  rgdict,
  rgdictlayout,
  rgnode,
  rgio.Text,
  rgio.dat,
  rgio.layout,
  rgmod,
  rgscan;

{
resourcestring
  // Open file error codes
  sNoFileStart  = 'No file starting tag';
  sNoBlockStart = 'No block start';
  sNoOrignText  = 'No original text';
  sNoTransText  = 'No translated text';
  sNoEndBlock   = 'No end of block';
}

const
  KnownGoodExt: array of string = (
    '.DAT',
    '.LAYOUT',
    '.TEMPLATE',
    '.WDAT'
  );

  KnownBadExt: array of string = (
    '.BIN',
    '.BINDAT',
    '.BINLAYOUT',
    '.DDS',
    '.MPP',
    '.RAW',
    '.ANIMATION',
    '.MATERIAL',
    '.MESH',
    '.SKELETON',
    '.OGG',
    '.WAV',
    '.FONT',
    '.TTF',
    '.PNG',
    '.BAK',
    '.DLL',
    '.EXE'
  );

const
  // TRANSLATION.DAT
  sBeginFile   = '[TRANSLATIONS]';
  sEndFile     = '[/TRANSLATIONS]';
  sBeginBlock  = '[TRANSLATION]';
  sEndBlock    = '[/TRANSLATION]';
  sOriginal    = '<STRING>ORIGINAL:';
  sTranslated  = '<STRING>TRANSLATION:';
  sFile        = '<STRING>FILE:';
  sProperty    = '<STRING>PROPERTY:';
  // Translation
  sTranslate   = '<TRANSLATE>';
  sDescription = 'DESCRIPTION';
  // Layouts
  sString      = '<STRING>';
  sText_       = 'TEXT ';
  sDialog_     = 'DIALOG ';
  sText        = 'TEXT';
  sToolTip     = 'TOOL TIP';
  sTitle       = 'TITLE';
  sGreet       = 'GREET';
  sFailed      = 'FAILED';
  sReturn      = 'RETURN';
  sComplete    = 'COMPLETE';
  sComplRet    = 'COMPLETE RETURN';

{
procedure ReadSrcFile(const fname:AnsiString; atype:integer; arootlen:integer);
var
  slin:TStringList;
  s,ls,ltag,lfile:AnsiString;
  lfline,lline:integer;
  i,j:integer;
begin
  slin:=TStringList.Create;
  try
    slin.LoadFromFile(fname,TEncoding.Unicode);
  except
    slin.Free;
    exit;
  end;

  lfile:=Copy(fname,arootlen);

  for lline:=0 to slin.Count-1 do
  begin
    s:=slin[lline];

    i:=-1;
    // <TRANSLATE> tag for all file types
    j:=Pos(sTranslate,s);
    if j>0 then
    begin
      inc(j,Length(sTranslate));  // points to tag for text
      i:=Pos(':',s);
      if i>0 then
      begin
        ltag:=Copy(s,j,i-j);
        inc(i);                   // points to text
      end
      else
      begin
        ltag:='';
        i:=j;                     // 'no tag' version (really?)
      end;
      lfline:=-(lline+1);
    end
    // <STRING> tag for some cases
    else
    begin
      j:=pos(sString,s);
      if j>0 then
      begin
        lfline:=lline+1;
        // <STRING>DESCRIPTION: case (old GUTS?)
        if pos(sString+sDescription+':',s)>0 then
        begin
          inc(j,Length(sString)); // points to tag for text
          i:=Pos(':',s);
          ltag:=Copy(s,j,i-j);
          inc(i);                 // points to text
        end
        else if atype=1 then // layout
        begin
          if (pos(sString+sText_       ,s)>0) or
             (pos(sString+sDialog_     ,s)>0) or
             (pos(sString+sText    +':',s)>0) or
             (pos(sString+sToolTip +':',s)>0) or
             (pos(sString+sTitle   +':',s)>0) or
             (pos(sString+sGreet   +':',s)>0) or
             (pos(sString+sFailed  +':',s)>0) or
             (pos(sString+sReturn  +':',s)>0) or
             (pos(sString+sComplete+':',s)>0) or
             (pos(sString+sComplRet+':',s)>0) then
          begin
            inc(j,Length(sString)); // points to tag for text
            i:=Pos(':',s);
            ltag:=Copy(s,j,i-j);
            inc(i);                 // points to text
          end;
        end;
      end;
    end;

    if i>0 then
    begin
      ls:=Copy(s,i,Length(s));
      if (ls<>'') and (ls<>' ') then
      begin
        if Assigned(DoAddString) then
        begin
          i:=DoAddString(ls,lfile,ltag,lfline);
//        if i<>0 then Refs.AddRef(ABS(i)-1,Refs.NewRef(lfile,ltag,lfline));
        end;
      end;
    end;

  end;

  slin.Free;
end;
}
{%REGION Read Binary}

function ProcessNode(anode:pointer; const afile:string; atype:integer; var FScanLine:integer):integer;
var
  ptag,pc:PWideChar;
  i,lline:integer;
begin
  result:=0;
  pc:=nil;

  inc(FScanLine);
  case GetNodeType(anode) of
    rgGroup: begin
{
      // no need tags but needs text values
      if (CompareWide(GetNodeName(anode),'UISTRINGS')=0) and
         (ExtractName(afile)='GLOBALS.DAT') then
        inc(FScanLine,GetChildCount(anode))
      else
}
        for i:=0 to GetChildCount(anode)-1 do
        begin
          inc(result,ProcessNode(GetChild(anode,i),afile,atype,FScanLine));
        end;

      inc(FScanLine); // for "Group close" line

      exit;
    end;

    rgTranslate: begin
      ptag:=GetNodeName(anode);
      pc  :=AsTranslate(anode);
      lline:=-FScanLine;
    end;

    rgString: begin
      ptag:=GetNodeName(anode);

      if CompareWide(ptag,sDescription)=0 then
        pc:=AsString(anode)
      else if (atype=1) and (  // layout
         (CompareWide(ptag,sText_  ,5)=0) or
         (CompareWide(ptag,sDialog_,7)=0) or
         (CompareWide(ptag,sText     )=0) or
         (CompareWide(ptag,sToolTip  )=0) or
         (CompareWide(ptag,sTitle    )=0) or
         (CompareWide(ptag,sGreet    )=0) or
         (CompareWide(ptag,sFailed   )=0) or
         (CompareWide(ptag,sReturn   )=0) or
         (CompareWide(ptag,sComplete )=0) or
         (CompareWide(ptag,sComplRet )=0)) then
        pc:=AsString(anode);

      lline:=FScanLine;
    end;
  else
    exit;
  end;

  if (pc<>nil) and not ((pc^=' ') and ((pc+1)^=#0)) then
  begin
    result:=1;
    if Assigned(DoAddString) then
    begin
      i:=DoAddString(pc,afile,FastWideToStr(ptag),lline);
//    if i<>0 then Refs.AddRef(ABS(i)-1,Refs.NewRef(afile,ltag,lline));
    end;
  end;
end;

{$I-}
function CheckSourceFile(const fname:AnsiString; allText:boolean):integer;
var
  f:file of byte;
  lext:AnsiString;
  i:integer;
  lsign:word;
begin
  result:=-1;
//  if UpCase(ExtractFileName(fname))='MOD.DAT' then exit;

  lext:=ExtractExt(fname);

  for i:=0 to High(KnownGoodExt) do
    if lext=KnownGoodExt[i] then
    begin
      result:=i;
      exit;
    end;

  if allText then
  begin
    for i:=0 to High(KnownBadExt) do
      if lext=KnownBadExt[i] then exit;

    AssignFile(f,fname);
    Reset(f);
    if IOResult=0 then
    begin
      i:=FileSize(f);
      if i>2 then
      begin
        BlockRead(f,lsign,2);
        if lsign=$FEFF then
          result:=1000;
      end;
      CloseFile(f);
    end;
  end;
end;

procedure CycleDir(sl:TStringList;
    const adir:AnsiString; allText:boolean; withChild:boolean);
var
  sr:TSearchRec;
  lname:AnsiString;
  i:integer;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if withChild and (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(sl, lname, allText, withChild);
      end
      else
      begin
        i:=CheckSourceFile(lname, allText);
        if i>=0 then
          sl.AddObject(lname,TObject(IntPtr(i)));
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

function Scan(const adir:AnsiString; allText:boolean; withChild:boolean):boolean;
var
  lmodinfo:TTL2ModInfo;
  p:pointer;
  sl:TStringList;
  lRootScanDir:AnsiString;
  i{,llen},FScanLine:integer;
begin
  result:=true;

  if adir[Length(adir)] in ['\','/'] then
    lRootScanDir:=Copy(adir,1,Length(adir)-1)
  else
    lRootScanDir:=adir;

  sl:=TStringList.Create();
  CycleDir(sl, lRootScanDir, allText, withChild);

  if sl.Count>0 then
  begin
//    FRefs.AddRoot(lRootScanDir+'/');
//    llen:=Length(lRootScanDir)+2; // to get relative filepath+name later
    for i:=0 to sl.Count-1 do
    begin
      if Assigned(OnFileScan) then
        case OnFileScan(sl[i],i+1,sl.Count) of
          0: ;
          1: continue;
          2: begin
            result:=false;
            break;
          end;
        end;

      if UpCase(ExtractName(sl[i]))=TL2ModData then
      begin
        if Assigned(DoAddModInfo) then
        begin
          MakeModInfo(lmodinfo);
          LoadModConfig(PChar(sl[i]),lmodinfo);
          DoAddModInfo(lmodinfo);
          ClearModInfo(lmodinfo);
        end;
      end
      else
      begin
        p:=ParseTextFile(PChar(sl[i]));
        FScanLine:=0;
        ProcessNode(p,sl[i],IntPtr(sl.Objects[i]),FScanLine);
        DeleteNode(p);
//        ReadSrcFile(sl[i],IntPtr(sl.Objects[i]),llen);
      end;
    end;

  end;

  sl.Free;
end;

function myactproc(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  lnode:pointer;
  ltype:integer;
  FScanLine:integer;
begin
  result:=0;

  inc(PInteger(aparam)^);
  if Assigned(OnFileScan) then
    case OnFileScan(adir+'/'+aname,PInteger(aparam)^,0) of
      0: ;
      1: exit;
      2: exit(sres_fail);
    end;

  if Pos('TRANSLATIONS',UpCase(adir))>0 then exit;

  if ExtractExt(aname)='.LAYOUT' then
  begin
    lnode:=ParseLayoutMem(abuf,adir); // for checking, Particles, UI or Layout
    ltype:=1;
  end
  else
  begin
    lnode:=ParseDatMem(abuf);
    ltype:=0;
  end;
  if lnode=nil then exit;

  FScanLine:=0;
  if ProcessNode(lnode,adir+aname,ltype,FScanLine)>0 then result:=1;

  DeleteNode(lnode);
end;

function Scan(const afile:AnsiString):boolean;
var
  lmodinfo:TTL2ModInfo;
  lScanIdx:integer;
begin

  RGTags.Import('RGDICT','TEXT');

  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  lScanIdx:=0;

//  FRefs.AddRoot(afile);
  // call it before mod content to be sure what mod record is ready
  if Assigned(DoAddModInfo) then
  begin
    if ReadModInfo(PChar(afile), lmodinfo) then
    begin
      DoAddModInfo(lmodinfo);
      ClearModInfo(lmodinfo);
    end;
  end;

  result:=MakeRGScan(afile,'',['.DAT','.LAYOUT','.TEMPLATE','.WDAT'],@myactproc,@lScanIdx,nil)>0;
end;


end.
