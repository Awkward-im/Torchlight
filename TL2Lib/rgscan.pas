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

function MakeRGScan(
    const aroot,adir:string;
    aext:array of string;
    actproc:TProcessProc=nil; aparam:pointer=nil;
    checkproc:TCheckNameProc=nil):integer;

procedure PrepareRGScan(out aptr:pointer;
    const apath:string;
    aext:array of string;
    aparam:pointer);

procedure EndRGScan(aptr:pointer);

function GetRGScan(aptr:pointer; const afile:string; out abuf:pointer):integer;
function DoRGScan (aptr:pointer; const apath:string;
    actproc:TProcessProc=nil; checkproc:TCheckNameProc=nil):integer;


implementation

uses
  sysutils,
  rgman,
  rgpak,
  rgfiletype;

type
  PScanObj = ^TScanObj;
  TScanObj = object
  private
    FExts     :array of string;
    FRoot     :string;     // not used, mod file path or scan starting dir
    FDir      :PWideChar;  // not used, starting dir inside root
    FParam    :pointer;
    FMod      :TPAKInfo;
    FCheckProc:TCheckNameProc;
    FActProc  :TProcessProc;

    FCount    :integer;

    function  CheckExt (const afile:string):boolean;
    function  CheckName(apath,afile:PWideChar):boolean;
  public
    procedure Free;
    procedure ScanMod();
    procedure CycleDir(const adir:string);
  end;


procedure TScanObj.Free;
begin
  if FMod.ver<>verUnk then
    FreePAKInfo(FMod);

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
{
  if (FDir<>nil) and (CompareWide(FDir,apath,Length(FDir))<>0) then
    result:=false
  else
}
    result:=CheckExt(afile) and
      ((FCheckProc=nil) or (FCheckProc(apath,afile,FParam)>0));
end;

procedure TScanObj.ScanMod();
var
  lbuf:PByte;
  i,j,lsize:integer;
begin
  for j:=0 to High(FMod.Entries) do
  begin
    if (FDir=nil) or (CompareWide(FDir,FMod.Entries[j].Name,Length(FDir))=0) then
    begin
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
  end;
end;

{$PUSH}
{$I-}
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
          CycleDir(adir+DirectorySeparator+sr.Name);
      end
      else
      begin
        {TODO: option to NOT process mod files}
        if CheckExt(sr.Name) and
           ((FCheckProc=nil) or (FCheckProc(adir,sr.Name,FParam)>0)) then
        begin
          if Pos('.MOD',UpCase(sr.Name))=(Length(sr.Name)-3) then
          begin
            inc(FCount,MakeRGScan(adir+DirectorySeparator+sr.Name,'',FExts,
                FActProc,FParam,FCheckProc));
//            ScanMod(adir+DirectorySeparator+sr.Name)
          end
          else if (FActProc=nil) then inc(FCount)
          else
          begin
            Assign(f,adir+DirectorySeparator+sr.Name);
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
{$POP}

procedure PrepareRGScan(out aptr:pointer;
    const apath:string;
    aext:array of string;
    aparam:pointer);
var
  ldir:string;
begin
  aptr:=nil;

  if apath[Length(apath)] in ['/','\'] then
    ldir:=Copy(apath,1,Length(apath)-1)
  else if DirectoryExists(apath) then
    ldir:=apath
  else if FileExists(apath) then
  begin
    ldir:='';
  end
  else
    Exit;

  New(PScanObj(aptr));

  if ldir='' then
    GetPAKInfo(apath,PScanObj(aptr)^.FMod,piParse)
  else
    PScanObj(aptr)^.FMod.ver:=verUnk;

  PScanObj(aptr)^.FRoot :=ldir;
  PScanObj(aptr)^.FExts :=Copy(aext);
  PScanObj(aptr)^.FParam:=aparam;
//  PScanObj(aptr)^.FCount:=0;
end;

procedure EndRGScan(aptr:pointer);
begin
  PScanObj(aptr)^.Free;
  Dispose(PScanObj(aptr));
end;

{$PUSH}
{$I-}
function GetRGScan(aptr:pointer; const afile:string; out abuf:pointer):integer;
var
  f:file of byte;
begin
  if aptr=nil then Exit(0);

  if PScanObj(aptr)^.FMod.ver=verUnk then
  begin
    Assign(f,PScanObj(aptr)^.FRoot+DirectorySeparator+afile);
    Reset(f);
    if IOResult=0 then
    begin
      result:=FileSize(f);
      GetMem(abuf,result);
      BlockRead(f,abuf^,result);
      Close(f);
    end;
  end
  else
  begin
    result:=UnpackFile(PScanObj(aptr)^.FMod, afile, abuf);
  end;
end;
{$POP}

function DoRGScan(aptr:pointer; const apath:string;
    actproc:TProcessProc=nil; checkproc:TCheckNameProc=nil):integer;
begin
  if aptr=nil then Exit(0);

  PScanObj(aptr)^.FCount:=0; //!!

  PScanObj(aptr)^.FCheckProc:=checkproc;
  PScanObj(aptr)^.FActProc  :=actproc;
  PScanObj(aptr)^.FDir      :=StrToWide(apath);

  if PScanObj(aptr)^.FMod.ver=verUnk then
    PScanObj(aptr)^.CycleDir(PScanObj(aptr)^.FRoot+DirectorySeparator+apath)
  else
    PScanObj(aptr)^.ScanMod();
  
  result:=PScanObj(aptr)^.FCount;
end;

function MakeRGScan(
    const aroot,adir:string;
    aext:array of string;
    actproc:TProcessProc=nil; aparam:pointer=nil;
    checkproc:TCheckNameProc=nil):integer;
var
  lptr:pointer;
begin
  PrepareRGScan(lptr,aroot,aext,aparam);
  result:=DoRGScan(lptr,adir,actproc,checkproc);
  EndRGScan(lptr);
end;

end.
