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

// return length of Root dir name
function PrepareRGScan(out aptr:pointer;
    const apath:string;
    aext:array of string;
    aparam:pointer):integer;

procedure EndRGScan(aptr:pointer);

function GetRGScan(aptr:pointer; const afile:string; out abuf:pointer):integer;
function DoRGScan (aptr:pointer; const apath:string;
    actproc:TProcessProc=nil; checkproc:TCheckNameProc=nil):integer;


implementation

uses
  sysutils,
  rgpak,
  rgman,
  rgfiletype;

type
  PScanObj = ^TScanObj;
  TScanObj = object
  private
    FExts     :array of string;
    FRoot     :string;     // not used, mod file path or scan starting dir
    FDir      :PWideChar;  // not used, starting dir inside root
    FParam    :pointer;
    FMod      :TRGPAK;
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
  FMod.Free;

  SetLength(FExts,0);
  FRoot:='';
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
  p:PMANFileInfo;
  lname,lfname:PWideChar;
  res,j,lsize:integer;
begin
  lbuf:=nil;
  for j:=0 to FMod.man.EntriesCount-1 do
  begin
    if FMod.man.IsDirDeleted(j) then continue;

    if (FDir=nil) or (CompareWide(FDir,FMod.man.GetDirName(j),Length(FDir))=0) then
    begin
      if FMod.man.GetFirstFile(p,j)<>0 then
      begin
        lname:=FMod.man.GetDirName(j);
        repeat
          lfname:=FMod.man.GetName(p^.name);
          if (not (p^.ftype in [typeDirectory,typeDelete])) and
             CheckName(lname,lfname) then
          begin
            if (FActProc=nil) then inc(FCount)
            else
            begin
              if (p^.size_s>0) and
                 (p^.offset>0) then
              begin
                lsize:=FMod.UnpackFile(lname,lfname,lbuf);

                res:=FActProc(lbuf,lsize,lname,lfname,FParam);

                if res>0 then inc(FCount)
                else if res<0 then
                begin
                  FCount:=-ABS(FCount);
                  FreeMem(lbuf);
                  exit;
                end;

              end;
            end;
          end;
        until FMod.man.GetNextFile(p)=0;
      end;
    end;
  end;
  FreeMem(lbuf);
end;

{$PUSH}
{$I-}
procedure TScanObj.CycleDir(const adir:string);
var
  sr:TSearchRec;
  f:file of byte;
  lbuf:PByte;
  ldir:string;
  res,lsize:integer;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          CycleDir(adir+'/'+sr.Name);
          if FCount<0 then break;
        end;
      end
      else
      begin
        ldir:=Copy(adir,Length(FRoot)+2)+'/'; // skip DirectorySeparator
        if CheckExt(sr.Name) and
           ((FCheckProc=nil) or (FCheckProc(ldir,sr.Name,FParam)>0)) then
        begin
          if Pos('.MOD',UpCase(sr.Name))=(Length(sr.Name)-3) then
          begin
            if UpCase(sr.Name)<>TL2EditMod then //!!!!!!!!!!
            begin
              res:=MakeRGScan(adir+'/'+sr.Name,'',FExts,
                  FActProc,FParam,FCheckProc);
              if      res>0 then inc(FCount,res)
              else if res<0 then break;
            end;
          end
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
              res:=FActProc(lbuf,lsize,ldir,sr.Name,FParam);
              FreeMem(lbuf);
              if res>0 then inc(FCount)
              else if res<0 then
              begin
                FCount:=-ABS(FCount);
                break;
              end;
            end;
          end;
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;
{$POP}

function PrepareRGScan(out aptr:pointer;
    const apath:string;
    aext:array of string;
    aparam:pointer):integer;
var
  ldir:string;
begin
  aptr:=nil;

  if apath='' then Exit
  else if apath[Length(apath)] in ['/','\'] then
    ldir:=Copy(apath,1,Length(apath)-1)
  else if DirectoryExists(apath) then
    ldir:=apath
  else if FileExists(apath) then
  begin
    ldir:='';
  end
  else
    Exit;

  result:=Length(ldir);

//  New(PScanObj(aptr));
  GetMem  (aptr ,SizeOf(TScanObj));
  FillChar(aptr^,SizeOf(TScanObj),0);

  PScanObj(aptr)^.FMod.Init;
  if ldir='' then
    PScanObj(aptr)^.FMod.GetInfo(apath,piParse)
  else
    PScanObj(aptr)^.FMod.Version:=verUnk;

  PScanObj(aptr)^.FRoot :=ldir;
  PScanObj(aptr)^.FExts :=Copy(aext);
  PScanObj(aptr)^.FParam:=aparam;
//  PScanObj(aptr)^.FCount:=0;
end;

procedure EndRGScan(aptr:pointer);
begin
  if aptr<>nil then
  begin
    PScanObj(aptr)^.Free;
    FreeMem(aptr);
//    Dispose(PScanObj(aptr));
  end;
end;

{$PUSH}
{$I-}
function GetRGScan(aptr:pointer; const afile:string; out abuf:pointer):integer;
var
  f:file of byte;
begin
  result:=0;

  if aptr=nil then Exit;

  if PScanObj(aptr)^.FMod.Version=verUnk then
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
    abuf:=nil;
    result:=PScanObj(aptr)^.FMod.UnpackFile(afile, abuf);
  end;
end;
{$POP}

function DoRGScan(aptr:pointer; const apath:string;
    actproc:TProcessProc=nil; checkproc:TCheckNameProc=nil):integer;
var
  ls:string;
begin
  if aptr=nil then Exit(0);

  PScanObj(aptr)^.FCount:=0; //!!

  PScanObj(aptr)^.FCheckProc:=checkproc;
  PScanObj(aptr)^.FActProc  :=actproc;
  PScanObj(aptr)^.FDir      :=StrToWide(apath);

  if PScanObj(aptr)^.FMod.Version=verUnk then
  begin
    if apath='' then
      PScanObj(aptr)^.CycleDir(PScanObj(aptr)^.FRoot)
    else
    begin
      ls:=apath;
      if ls[Length(ls)] in ['/','\'] then SetLength(ls,High(ls));
      if ls<>'' then
        PScanObj(aptr)^.CycleDir(PScanObj(aptr)^.FRoot+DirectorySeparator+ls)
      else
        PScanObj(aptr)^.CycleDir(PScanObj(aptr)^.FRoot);
    end;
  end
  else
    PScanObj(aptr)^.ScanMod();
  
  FreeMem(PScanObj(aptr)^.FDir);

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
  if lptr<>nil then
  begin
    result:=DoRGScan(lptr,adir,actproc,checkproc);
    EndRGScan(lptr);
  end
  else
    result:=0;
end;

end.
