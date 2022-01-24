{
  text, dat, layout or universal?
  1 + scan dir with single unpacked mod
  2 - scan dirs with unpacked mods
  3 - scan dirs with packed mods
  4 + scan packed mod content

}
unit RGScan;

interface

uses
  rgglobal;

type
  TCheckNameProc = function(const adir,aname:string; aparam:pointer):integer;
  TProcessProc   = function(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;

//--- CheckName templates
function FnCheckDAT   (const adir,aname:string; aparam:pointer):integer;
function FnCheckLAYOUT(const adir,aname:string; aparam:pointer):integer;
function FnCheckText  (const adir,aname:string; aparam:pointer):integer;

function ScanExt(
    const aroot,adir:string;
    actproc:TProcessProc=nil;
    aparam:pointer=nil;
    aext:array of string):integer;

function ScanDir(
    const aroot,adir:string;
    actproc:TProcessProc=nil;
    aparam:pointer=nil;
    checkproc:TCheckNameProc=nil):integer;

function ScanMod(
    const afname,adir:string;
    actproc:TProcessProc=nil;
    aparam:pointer=nil;
    checkproc:TCheckNameProc=nil):integer;


implementation

uses
  sysutils,
  rgman,
  rgpak,
  rgfiletype;

type
  TScanObj = object
  private
    FExts     :array of string;
    FRoot     :string;     // not used, mod file path or scan starting dir
    FDir      :PWideChar;  // not used, starting dir inside root
    FParam    :pointer;
    FMod      :TPAKInfo;
    FCheckProc:TCheckNameProc;
    FActProc  :TProcessProc;
    FCurEntry :integer;

    FCount    :integer;

    function  CheckExt (const afile:string):boolean;
    function  CheckName(apath,afile:PWideChar):boolean;
  public
    procedure Free;
    procedure ScanMod(const afname:string);
    procedure CycleDir(const adir:string);
  end;


function FnCheckText(const adir,aname:string; aparam:pointer):integer;
var
  ls:string;
begin
  ls:=UpCase(ExtractFileExt(aname));
  if (ls='.DAT') or (ls='.TEMPLATE') or (ls='.LAYOUT') or (ls='.WDAT') then result:=1
  else result:=0;
end;
function FnCheckDAT(const adir,aname:string; aparam:pointer):integer;
var
  ls:string;
begin
  ls:=UpCase(ExtractFileExt(aname));
  if (ls='.DAT') or (ls='.TEMPLATE') or (ls='.WDAT') then result:=1
  else result:=0;
end;
function FnCheckLAYOUT(const adir,aname:string; aparam:pointer):integer;
var
  ls:string;
begin
  ls:=UpCase(ExtractFileExt(aname));
  if ls='.LAYOUT' then result:=1
  else result:=0;
end;

procedure TScanObj.Free;
begin
  FreeMem(FDir);
end;

function TScanObj.CheckExt(const afile:string):boolean;
var
  ls:string;
  i:integer;
begin
  if FExts=nil then result:=true
  else
  begin
    ls:=UpCase(ExtractFileExt(afile));
    for i:=0 to High(FExts) do
    begin
      if ls=FExts[i] then
        exit(true);
    end;
    result:=false;
  end;
end;

function TScanObj.CheckName(apath,afile:PWideChar):boolean;
begin
  if (FDir<>nil) and (CompareWide(FDir,apath,Length(FDir))<>0) then
    result:=false
  else
    result:=CheckExt(afile) and
      ((FCheckProc=nil) or (FCheckProc(apath,afile,FParam)>0));
end;

procedure TScanObj.ScanMod(const afname:string);
var
  lbuf:PByte;
  i,j,lsize:integer;
begin
  GetPAKInfo(afname,FMod,piParse);
  {TODO: Add MOD.DAT emulation?}

  for j:=0 to High(FMod.Entries) do
  begin
    FCurEntry:=j;
    for i:=0 to High(FMod.Entries[j].Files) do
    begin
      if (not (FMod.Entries[j].Files[i].ftype in [typeDirectory,typeDelete])) and
         CheckName(FMod.Entries[j].Name,
                   FMod.Entries[j].Files[i].name) then
      begin
        if (FActProc=nil) then inc(FCount)
        else
        begin
          lsize:=UnpackFile(
              FMod,
              FMod.Entries[j].Name,
              FMod.Entries[j].Files[i].name,
              lbuf);

          if (FActProc(lbuf,lsize,
            FMod.Entries[j].Name,
            FMod.Entries[j].Files[i].name,
            FParam)>0) then inc(FCount);

          FreeMem(lbuf);
        end;
      end;
    end;
  end;

  FreePAKInfo(FMod);
end;

procedure TScanObj.CycleDir(const adir:string);
var
  sr:TSearchRec;
  f:file of byte;
  lbuf:PByte;
  lsize:integer;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(adir+'\'+sr.Name);
      end
      else
      begin
        {TODO: option to NOT process mod files}
        if CheckExt(sr.Name) and
           ((FCheckProc=nil) or (FCheckProc(adir,sr.Name,FParam)>0)) then
        begin
          if Pos('.MOD',UpCase(sr.Name))=(Length(sr.Name)-3) then
            ScanMod(adir+'\'+sr.Name)
          else if (FActProc=nil) then inc(FCount)
          else
          begin
            Assign(f,adir+'/'+sr.Name);
            Reset(f);
            if IOResult=0 then
            begin
              lsize:=FileSize(f);
              GetMem(lbuf,lsize);
              BlockRead(f,lbuf^,lsize);
              Close(f);
              if (FActProc(lbuf,lsize,adir,sr.Name,FParam)>0) then inc(FCount);
              FreeMem(lbuf);
            end;
          end;
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;


function ScanExt(const aroot,adir:string;
    actproc:TProcessProc=nil; aparam:pointer=nil;
    aext:array of string):integer;
var
  lscan:TScanObj;
begin
  lscan.FRoot     :=aroot;
  lscan.FDir      :=StrToWide(adir);
  lscan.FExts     :=Copy(aext);
  lscan.FCheckProc:=nil;
  lscan.FActProc  :=actproc;
  lscan.FParam    :=aparam;
  lscan.FMod.ver  :=verUnk;
  lscan.FCount    :=0;

  if not (lscan.FRoot[Length(lscan.FRoot)] in ['/','\']) then
    lscan.FRoot:=lscan.FRoot+'/';

  lscan.CycleDir(lscan.FRoot+adir);
  result:=lscan.FCount;
  lscan.Free;
end;

function ScanDir(const aroot,adir:string;
    actproc:TProcessProc=nil; aparam:pointer=nil;
    checkproc:TCheckNameProc=nil):integer;
var
  lscan:TScanObj;
begin
  lscan.FRoot     :=aroot;
  lscan.FDir      :=StrToWide(adir);
  lscan.FExts     :=nil;
  lscan.FCheckProc:=checkproc;
  lscan.FActProc  :=actproc;
  lscan.FParam    :=aparam;
  lscan.FMod.ver  :=verUnk;
  lscan.FCount    :=0;

  if not (lscan.FRoot[Length(lscan.FRoot)] in ['/','\']) then
    lscan.FRoot:=lscan.FRoot+'/';

  lscan.CycleDir(lscan.FRoot+adir);
  result:=lscan.FCount;
  lscan.Free;
end;

function ScanMod(const afname,adir:string;
    actproc:TProcessProc=nil; aparam:pointer=nil;
    checkproc:TCheckNameProc=nil):integer;
var
  lscan:TScanObj;
begin
  lscan.FRoot     :=ExtractFilePath(afname);
  lscan.FDir      :=StrToWide(adir);
  lscan.FExts     :=nil;
  lscan.FCheckProc:=checkproc;
  lscan.FActProc  :=actproc;
  lscan.FParam    :=aparam;
  lscan.FMod.ver  :=verUnk;
  lscan.FCount    :=0;

  lscan.ScanMod(afname);
  result:=lscan.FCount;
  lscan.Free;
end;

end.
