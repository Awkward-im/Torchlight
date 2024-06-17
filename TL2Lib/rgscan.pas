{
  text, dat, layout or universal?
  1 + scan dir with single unpacked mod
  2 - scan dirs with unpacked mods
  3 - scan dirs with packed mods
  4 + scan packed mod content

}
{TODO: Create "Pause" and "Continue" functions}
unit RGScan;

interface

uses
  rgglobal;

const
  sres_break   = $80000000; // break cycle
  sres_fail    = $40000000; // test failed, no count increased
  sres_nocheck = $20000000; // no  need to check content, name test only
  sres_count   = $00FFFFFF; // mask to get item count
  sres_mask    = sres_break or sres_fail;
  
type
  // PWideChar for mods
  TCheckNameProc = function(const adir,aname:string; aparam:pointer):integer;
  TProcessProc   = function(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;

// Prepare - Do - End
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
    FRoot     :string;         // mod file path or scan starting dir
    FDir      :PWideChar;      // starting dir inside root
    FParam    :pointer;        // user data
    FMod      :TRGPAK;
    FCheckProc:TCheckNameProc;
    FActProc  :TProcessProc;

    FCount    :integer;

    function  CheckExt(const afile:string):boolean;
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
  result:=true;
  // do not check dir names
  if FExts<>nil then
  begin
    if afile[Length(afile)]<>'/' then
    begin
      ls:=rgglobal.ExtractFileExt(afile);
      for i:=0 to High(FExts) do
        if ls=FExts[i] then exit;

      result:=false;
    end;
  end;
end;

procedure TScanObj.ScanMod();
var
  lbuf:PByte;
  p:PManFileInfo;
  lname,lfname:PWideChar;
  llen,lres,j,lsize:integer;
begin
  lbuf:=nil;
  llen:=Length(FDir);
  for j:=0 to FMod.man.DirCount-1 do
  begin
    if FMod.man.IsDirDeleted(j) then continue;

    lname:=FMod.man.Dirs[j].Name;
    if (FDir=nil) or (CompareWide(FDir,lname,llen)=0) then
    begin
      if FMod.man.GetFirstFile(p,j)<>0 then
      begin
        repeat
          lfname:=p^.name;
          if (p^.ftype<>typeDelete) and CheckExt(lfname) then
          begin
            if FCheckProc<>nil then
              lres:=FCheckProc(lname,lfname,FParam)
            else
              lres:=0;

            if (lres and sres_nocheck)=0 then
            begin
              if p^.ftype<>typeDirectory then // useful when FCheckProc=nil
              begin
                if FActProc<>nil then
                  if (p^.size_s>0) {and (p^.offset>0)} then
                  begin
                    lsize:=FMod.UnpackFile(lname,lfname,lbuf);
                    lres:=FActProc(lbuf,lsize,lname,lfname,FParam);
                  end;
              end
              else lres:=sres_fail;
            end;
            if (lres and sres_fail )= 0 then inc(FCount,lres and sres_count);
            if (lres and sres_break)<>0 then
            begin
              FreeMem(lbuf);
              exit;
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
  ladir,ldir,lname:string;
  lres,lsize:integer;
begin
  ladir:=adir;
  if not (ladir[Length(ladir)] in ['/','\']) then ladir:=ladir+'/';

  if FindFirst(ladir+'*.*',faAnyFile{ and faDirectory},sr)=0 then
  begin
    ldir:=Copy(ladir,Length(FRoot)+1);
    repeat
      lname:=UpCase(sr.Name);
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (lname<>'.') and (lname<>'..') then
        begin
          if (FCheckProc<>nil) then
            lres:=FCheckProc(ldir,lname+'/',FParam)
          else
            lres:=0;

          if (lres and sres_fail )= 0 then CycleDir(ladir+lname+'/');
          if (lres and sres_break)<>0 then break;
        end;
      end
      else
      begin
        if CheckExt(lname) then
        begin
          if FCheckProc<>nil then
            lres:=FCheckProc(ldir,lname,FParam)
          else
            lres:=0;

          if (lres and sres_nocheck)=0 then
          begin
            lsize:=Length(sr.Name)-3;
            if (Pos('.MOD',lname)=lsize) or
               (Pos('.PAK',lname)=lsize) then
            begin
              if lname<>TL2EditMod then
              begin
                lres:=MakeRGScan(ladir+lname,'',FExts,
                    FActProc,FParam,FCheckProc);
              end;
            end
            else if FActProc<>nil then
            begin
              Assign(f,ladir+sr.Name);
              Reset(f);
              if IOResult=0 then
              begin
                lsize:=FileSize(f);
                GetMem(lbuf,lsize);
                BlockRead(f,lbuf^,lsize);
                Close(f);
                lres:=FActProc(lbuf,lsize,ldir,lname,FParam);
                FreeMem(lbuf);
              end;
            end;
          end;

          if (lres and sres_fail )= 0 then inc(FCount,lres and sres_count);
          if (lres and sres_break)<>0 then break;
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
  i:integer;
begin
  aptr:=nil;

  if apath='' then Exit
  else if apath[Length(apath)] in ['/','\'] then
  begin
    ldir:=Copy(apath,1);
    ldir[Length(ldir)]:='/';
  end
  else if DirectoryExists(apath) then
    ldir:=apath+'/'
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

  RGLog.Add('Scanning '+apath);

  PScanObj(aptr)^.FMod:=TRGPAK.Create();
  if ldir='' then
    PScanObj(aptr)^.FMod.GetInfo(apath,piParse)
  else
    PScanObj(aptr)^.FMod.Version:=verUnk;

  PScanObj(aptr)^.FMod.OpenPAK();
  PScanObj(aptr)^.FRoot:=ldir;

  SetLength(PScanObj(aptr)^.FExts,Length(aext));
  for i:=0 to High(aext) do
    PScanObj(aptr)^.FExts[i]:=Copy(aext[i],1);

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
    Assign(f,PScanObj(aptr)^.FRoot+afile);
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
  llen:integer;
begin
  if aptr=nil then Exit(0);

  PScanObj(aptr)^.FCount:=0; //!!

  PScanObj(aptr)^.FCheckProc:=checkproc;
  PScanObj(aptr)^.FActProc  :=actproc;
  ls:=apath;
  llen:=Length(ls);
  if (ls<>'') then
  begin
    if not (ls[llen] in ['\','/']) then ls:=ls+'/'
    else if llen>1 then ls[llen]:='/'
    else ls:='';
  end;

  PScanObj(aptr)^.FDir:=StrToWide(ls);

  if PScanObj(aptr)^.FMod.Version=verUnk then
    PScanObj(aptr)^.CycleDir(PScanObj(aptr)^.FRoot+ls)
  else
    PScanObj(aptr)^.ScanMod();
  
  FreeMem(PScanObj(aptr)^.FDir);

  result:=PScanObj(aptr)^.FCount; //!!
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
