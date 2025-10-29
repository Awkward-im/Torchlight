unit TLScan;


interface

uses
  rgglobal;

type
  //file scan only
  TDoAddModInfo = procedure (const mi:TTL2ModInfo) of object;
  // 0 - process; 1 - skip; 2 - stop
  TOnFileScan   = function  (const fname:AnsiString; idx, atotal:integer):integer of object;

  // both, file scan and load translation
  TDoAddString  = function  (const astr, afile, atag:AnsiString; aline:integer):integer of object;

  // load translation only
//  TDoAddText    = function  (const astr,atrans:PAnsiChar):integer of object;
const
  OnFileScan  :TOnFileScan   = nil;

  DoAddModInfo:TDoAddModInfo = nil;
  DoAddString :TDoAddString  = nil;
//  DoAddText   :TDoAddText    = nil;


function Scan(const adir :AnsiString; allText:boolean; withChild:boolean):integer;
function Scan(const afile:AnsiString):integer;

//function LoadAsText(const fname:AnsiString):integer;
//function LoadAsNode(const fname:AnsiString):integer;
//function Load      (const fname:AnsiString):integer;

implementation

uses
  Classes,
  SysUtils,

  rgdict,
  rgdictlayout,
  rgnode,
  rgpak,
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
    '.EXE',
    '.PSD'
  );

const
{
  // TRANSLATION.DAT
  sBeginFile   = '[TRANSLATIONS]';
  sEndFile     = '[/TRANSLATIONS]';
  sBeginBlock  = '[TRANSLATION]';
  sEndBlock    = '[/TRANSLATION]';
  sOriginal    = '<STRING>ORIGINAL:';
  sTranslated  = '<STRING>TRANSLATION:';
  // additional tags. not used usually
  sFile        = '<STRING>FILE:';
  sProperty    = '<STRING>PROPERTY:';
}
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


function ProcessSource(astr:PWideChar; const fname:AnsiString; atype:integer):integer;
var
  slin:TStringList;
  s,ls,ltag:AnsiString;
  lfline,lline:integer;
  i,j:integer;
begin
  result:=0;

  slin:=TStringList.Create;
  try
    if (ord(astr^)=SIGN_UNICODE) or (astr^='[') then
      slin.Text:=WideToStr(astr)
    else
      slin.Text:=PAnsiChar(astr);
  except
    slin.Free;
    exit;
  end;

  for lline:=0 to slin.Count-1 do
  begin
    s:=slin[lline];

    i:=-1;
    // <TRANSLATE> tag for all file types
    j:=Pos(sTranslate,s);
    if j>0 then
    begin
      inc(j,Length(sTranslate));  // points to tag for text
      i:=Pos(':',s,j);
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
        inc(j,Length(sString)); // points to tag for text
        lfline:=lline+1;
        // <STRING>DESCRIPTION: case (old GUTS?)
        //better to use text compare with length
        if pos(sDescription+':',s,j)=j then
        begin
          ltag:=sDescription;
          i:=j+Length(sDescription+':'){11+1};            // points to text
        end
        else if atype=1 then    // layout
        begin
          if
             (pos(sText    +':',s,j)=j) or
             (pos(sToolTip +':',s,j)=j) or
             (pos(sTitle   +':',s,j)=j) or
             (pos(sGreet   +':',s,j)=j) or
             (pos(sComplete+':',s,j)=j) or
             (pos(sText_       ,s,j)=j) or
             (pos(sDialog_     ,s,j)=j) or
             (pos(sFailed  +':',s,j)=j) or
             (pos(sReturn  +':',s,j)=j) or
             (pos(sComplRet+':',s,j)=j) then
          begin
            i:=Pos(':',s,j);
            ltag:=Copy(s,j,i-j);
            inc(i);             // points to text
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
          i:=DoAddString(ls,fname,ltag,lfline);
          if i>0 then inc(result);
        end;
      end;
    end;

  end;

  slin.Free;
end;

function ProcessNode(anode:pointer; const afile:AnsiString; atype:integer; var FScanLine:integer):integer;
var
  ptag,pc:PWideChar;
//  ltag:array [0..63] of AnsiChar;
//  lpc:PAnsiChar;
//  ls:AnsiString;
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
         (CompareWide(ptag,sText     )=0) or
         (CompareWide(ptag,sToolTip  )=0) or
         (CompareWide(ptag,sTitle    )=0) or
         (CompareWide(ptag,sGreet    )=0) or
         (CompareWide(ptag,sComplete )=0) or
         (CompareWide(ptag,sText_  ,5)=0) or
         (CompareWide(ptag,sDialog_,7)=0) or
         (CompareWide(ptag,sFailed   )=0) or
         (CompareWide(ptag,sReturn   )=0) or
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
{
      // fast Wide to Ansi convert
      lpc:=@ltag;
      if ptag<>nil then
        while ptag^<>#0 do
        begin
          lpc^:=CHR(ORD(ptag^));
          inc(lpc);
          inc(ptag);
        end;
      lpc^:=#0;
}
      i:=DoAddString(WideToStr(pc),afile,FastWideToStr(ptag),lline);
      if i>0 then inc(result);
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

function Scan(const adir:AnsiString; allText:boolean; withChild:boolean):integer;
var
  lmodinfo:TTL2ModInfo;
  st:TFileStream;
//  p:pointer;
//  FScanLine:integer;
  sl:TStringList;
  pcw:PWideChar;
  lRootScanDir:AnsiString;
  i,llen,lsize:integer;
begin
  result:=0;

  if adir[Length(adir)] in ['\','/'] then
    lRootScanDir:=Copy(adir,1,Length(adir)-1)
  else
    lRootScanDir:=adir;

  sl:=TStringList.Create();
  CycleDir(sl, lRootScanDir, allText, withChild);

  if sl.Count>0 then
  begin
    RGLog.Add('Check '+IntToStr(sl.Count)+' files');
    pcw:=nil;
    llen:=Length(lRootScanDir)+2; // to get relative filepath+name later
    i:=0;
    while i<sl.Count do
    begin
      if Assigned(OnFileScan) then
        case OnFileScan(sl[i],i+1,sl.Count) of
          0: ;
          1: begin inc(i); continue; end;
          2: break;
        end;

      if UpCase(ExtractName(sl[i]))=TL2ModData then
      begin
        if Assigned(DoAddModInfo) then
        begin
          MakeModInfo(lmodinfo);
          LoadModConfig(PAnsiChar(sl[i]),lmodinfo);
          DoAddModInfo(lmodinfo);
          ClearModInfo(lmodinfo);
        end;
      end
      else
      begin
{
        p:=ParseTextFile(PAnsiChar(sl[i]));
        FScanLine:=0;
        ProcessNode(p,PAnsiChar(sl[i])+llen,IntPtr(sl.Objects[i]),FScanLine);
        DeleteNode(p);
}

        st:=nil;
        lsize:=0;
        try
          st:=TFileStream.Create(sl[i],fmOpenRead);
          lsize:=st.size;
          if (pcw=nil) or (MemSize(pcw)<(lsize+2)) then
          begin
            FreeMem(pcw);
            GetMem (pcw,Align(lsize+2,16000));
          end;
          st.Read(pcw^,lsize);
        finally
          st.Free;
        end;

        if lsize>0 then
        begin
          PByte(pcw)[lsize  ]:=0;
          PByte(pcw)[lsize+1]:=0;
          inc(result,ProcessSource(pcw,Copy(sl[i],llen),IntPtr(sl.Objects[i])));
        end;
      end;
      inc(i);
    end;
    RGLog.Add('Total: '+IntToStr(result)+' lines in '+IntToStr(i)+' files');

    FreeMem(pcw);
  end
  else
    RGLog.Add('No files to check');

  sl.Free;
end;

type
  PCounter = ^TCounter;
  TCounter = record
    count:integer;
    total:integer;
  end;

function myactproc(
          abuf:PByte; asize:integer;
          const adir,aname:AnsiString;
          aparam:pointer):cardinal;
var
  lnode:pointer;
  ltype:integer;
  FScanLine:integer;
begin
  result:=0;

  inc(PCounter(aparam)^.count);
  if Assigned(OnFileScan) then
    case OnFileScan(adir+'/'+aname,PCounter(aparam)^.count,PCounter(aparam)^.total) of
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

function Scan(const afile:AnsiString):integer;
var
  lmodinfo:TTL2ModInfo;
  lScanIdx:TCounter;
  lpak:TRGPAK;
begin
  // call it before mod content to be sure what mod record is ready
  if Assigned(DoAddModInfo) then
  begin
    if ReadModInfo(PChar(afile), lmodinfo) then
    begin
      DoAddModInfo(lmodinfo);
      ClearModInfo(lmodinfo);
    end;
  end;

  lScanIdx.count:=0;

  lpak:=TRGPAK.Create;
  lpak.GetInfo(afile,piNoParse);
  lScanIdx.total:=lpak.GetFilesInfo(afile);
  lpak.Free;
  
  result:=MakeRGScan(afile,'',['.DAT','.LAYOUT','.TEMPLATE','.WDAT'],@myactproc,@lScanIdx,nil);
end;

(*
function ProcessAsNode(var anode:pointer):integer;
var
  pt,ps:pointer;
  i,j:integer;
  src,dst,lfile,ltag:PWideChar;
  ls:AnsiString;
begin
  result:=0;
  if anode=nil then exit;

  if CompareWide(GetNodeName(anode),'TRANSLATIONS')<>0 then
  begin
    DeleteNode(anode);
    exit;
  end;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    pt:=GetChild(anode,i);
    if (GetNodeType(pt)=rgGroup) and (CompareWide(GetNodeName(pt),'TRANSLATION')=0) then
    begin
      src  :=nil;
      dst  :=nil;
      lfile:=nil;
      ltag :=nil;
      for j:=0 to GetChildCount(pt)-1 do
      begin
        ps:=GetChild(pt,j);
        if GetNodeType(ps)=rgString then
        begin
          if      CompareWide(GetNodeName(ps),'ORIGINAL'   )=0 then src  :=AsString(ps)
          else if CompareWide(GetNodeName(ps),'TRANSLATION')=0 then dst  :=AsString(ps)
          else if CompareWide(GetNodeName(ps),'FILE'       )=0 then lfile:=AsString(ps)
          else if CompareWide(GetNodeName(ps),'PROPERTY'   )=0 then ltag :=AsString(ps);
          if (src<>nil) and (dst<>nil) then break;
        end;
      end;
      if (src<>'') {and (ldst<>'')} then
      begin
        if CompareWide(src,dst)=0 then dst:=nil;
        ls:=WideToStr(src);
        if Assigned(DoAddString) and (lfile<>nil) then
        begin
          DoAddString(
            ls,
            WideToStr(lfile),
            WideToStr(ltag),
            0);
        end;
        if Assigned(DoAddText) then
          DoAddText(PAnsiChar(ls),PAnsiChar(WideToStr(dst)));
        inc(result);
      end
    end;
  end;
  RGLog.Add('Total: '+IntToStr(result)+' lines');

  DeleteNode(anode);
end;

function LoadAsNode(const fname:AnsiString):integer;
var
  p:pointer;
begin
  p:=ParseTextFile(PChar(fname));
  result:=ProcessAsNode(p);
end;

function LoadAsText(const fname:AnsiString):integer;
var
  slin:TStringList;
  s,lsrc,ldst,lfile,ltag:AnsiString;
  lcnt,lline:integer;
  i,stage:integer;

  st:TFileStream;
  pcw:PWideChar;
begin
  result:=0;
  if fname='' then exit;

  pcw:=nil;
  st:=nil;
  try
    st:=TFileStream.Create(fname,fmOpenRead);
    GetMem(pcw,st.size+2);
    st.Read(pcw^,st.size);
    PByte(pcw)[st.size  ]:=0;
    PByte(pcw)[st.size+1]:=0;
  except
    if pcw<>nil then FreeMem(pcw);
    st.Free;
    exit;
  end;
  st.Free;

  slin:=TStringList.Create;
  try
    if (ord(pcw^)=SIGN_UNICODE) or (pcw^='[') then
      slin.Text:=WideToStr(pcw)
    else
      slin.Text:=PAnsiChar(pcw);
  except
    slin.Free;
    exit;
  end;
  FreeMem(pcw);

  lline:=0;
  lcnt :=0;
  lsrc :='';
  ldst :='';
  lfile:='';
  ltag :='';

  stage:=1;

  while lline<slin.Count do
  begin
    s:=slin[lline];
    if s<>'' then
    begin
      case stage of
        // <STRING>ORIGINAL:
        // <STRING>TRANSLATION:
        // [/TRANSLATION]
        3: begin
          i:=0;
          if (lsrc='') then
          begin
            i:=Pos(sOriginal,s);
            if i<>0 then lsrc:=Copy(s,i+Length(sOriginal));
          end;

          if (i=0) and (ldst='') then
          begin
            i:=Pos(sTranslated,s);
            if i<>0 then ldst:=Copy(s,i+Length(sTranslated));
            if ldst=lsrc then ldst:='';
          end;

          if (i=0) and (lfile='') then
          begin
            i:=Pos(sFile,s);
            if i<>0 then lfile:=Copy(s,i+Length(sFile));
          end;

          if (i=0) and (ltag='') then
          begin
            i:=Pos(sProperty,s);
            if i<>0 then ltag:=Copy(s,i+Length(sProperty));
          end;

          if (i=0) then
          begin
            if Pos(sEndBlock,s)<>0 then
            begin
              stage:=2;

              if (lsrc<>'') {and (ldst<>'')} then
              begin
                if Assigned(DoAddString) and (lfile<>'') then
                begin
                  DoAddString(
                    lsrc,
                    lfile,
                    ltag,
                    0);
                end;
                if Assigned(DoAddText) then
                  if DoAddText(PAnsiChar(lsrc),PAnsiChar(ldst))>0 then
                    inc(lcnt);
              end
              else if lsrc='' then
              begin
                result:=-3;
//                Error(result,fname,lline); // no original text
//!!                break;
{
              end
              else if ldst='' then
              begin
                result:=-4;
                Error(result,fname,lline); // no translated text
//!!                break;
}
              end;

            end
            else
            begin
              result:=-5;
//              Error(result,fname,lline); // no end of block
//??            break;
            end;
          end;

        end;

        // [TRANSLATION] and [/TRANSLATIONS]
        2: begin
          if Pos(sBeginBlock,s)<>0 then
          begin
            stage:=3;
            lsrc :='';
            ldst :='';
            lfile:='';
            ltag :='';
          end
          else if Pos(sEndFile,s)<>0 then break // end of file
          else
          begin
            result:=-2;
//            Error(result,fname,lline); // no block start
//??            break;
          end;
        end;

        // [TRANSLATIONS]
        1: begin
          if Pos(sBeginFile,s)<>0 then
            stage:=2
          else
          begin
            result:=-1;
//            Error(result,fname,lline); // no file starting tag
            break;
          end;
        end;
      end;
    end;
    inc(lline);
  end;

  slin.Free;
  result:=lcnt;
  RGLog.Add('Total: '+IntToStr(result)+' lines');
end;

function Load(const fname:AnsiString):integer;
var
  p:pointer;
begin
  result:=0;
  if fname='' then exit;

  p:=ParseDatFile(PChar(fname));
  if p=nil then
  begin
    p:=ParseTextFile(PChar(fname));
    if p=nil then exit;
  end;
  result:=ProcessAsNode(p);
end;
*)
end.
