unit unitCombine;

interface

// Statistic

// Adding

function AddMod(const aroot, asrc:string):integer;


implementation

{$R dict.rc}

uses
  fmAsk,

  sysutils,
  rgglobal,
  rglogging,
  rgscan,
  rgdict,
  rgio.Text,
  rgio.Layout,
  rgio.Dat,
  rgnode,
  unitComboCommon;

type
  pourdata = ^tourdata;
  tourdata = record
    outdir :string;
    lastdir:string;
    act   :tact;
  end;
var
  scandata:tourdata;

function actproc(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  f:file of byte;
  ldst:string;
  lnode:pointer;
  istext:boolean;
begin
  result:=0;

  case UpCase(ExtractFileExt(aname)) of
    '.DAT',
    '.TEMPLATE',
    '.ANIMATION',
    '.WDAT': begin
      // check if file is real text or binary
      // MAYBE translate binary to text here
      istext:=true;
      lnode:=ParseDatMem(abuf);
      if lnode<>nil then
      begin
        NodeToWide(lnode,PWideChar(abuf));
        DeleteNode(lnode);
        asize:=Length(PWideChar(abuf))*SizeOf(WideChar);
      end;
    end;
    '.LAYOUT': begin
      istext:=true;
      lnode:=ParseLayoutMem(abuf,adir+aname);
      if lnode<>nil then
      begin
        NodeToWide(lnode,PWideChar(abuf));
        DeleteNode(lnode);
        asize:=Length(PWideChar(abuf))*SizeOf(WideChar);
      end;
    end;
  else
    istext:=false;
  end;

  ldst:=pourdata(aparam)^.outdir+adir+aname;
  // check 1 - existing file
  if FileExists(ldst) then
  begin
    RGLog.Add(adir+aname+' file exists already');
    // check 2 - file size (maybe not needed)
    // check 3 - file content (what about different spaces only? use textdiff?)

    if pourdata(aparam)^.act=ask then
      with tAskForm.Create(adir+aname) do
      begin
        pourdata(aparam)^.act:=tact(ShowModal());
        // 'skip' and 'overwrite' will be changed to 'ask' later?
        Free;
      end;

    if istext then
    begin
    end;
  end
  else
  begin
    if pourdata(aparam)^.lastdir<>adir then
    begin
      if not (pourdata(aparam)^.act in [skipall,overwriteall]) then
        pourdata(aparam)^.act:=ask;

      ForceDirectories(pourdata(aparam)^.outdir+adir);
      pourdata(aparam)^.lastdir:=adir;
    end;
    // Save file aname to pourdata(aparam)^.outdir+adir
    if istext then
    begin
    end;

    Assign(f,ldst);
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,abuf^,asize);
      Close(f);
      result:=1;
      // what about set source file date time?
    end;

  end;
end;

function checkproc(const adir,aname:string; aparam:pointer):integer;
var
  ldst:string;
begin
  ldst:=UpCase(aname);
  if ldst='MOD.DAT' then
    result:=0
  else
  begin
    ldst:=ExtractFileExt(ldst);
    if (ldst='.BINDAT') or
       (ldst='.BINLAYOUT') or
       (ldst='.RAW') then
      result:=0
    else
      result:=1;
  end;
end;

function AddMod(const aroot, asrc:string):integer;
begin
  RGLog.Add('Trying to append '+asrc);

  scandata.outdir :=aroot;
  scandata.lastdir:='';
  scandata.act    :=ask;

  if not (aroot[Length(aroot)] in ['\','/']) then scandata.outdir:=scandata.outdir+'\';

  result:=MakeRGScan(asrc,'',[],@actproc,@scandata,@checkproc);
end;

initialization

RGTags.Import('RGDICT','TEXT');

LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
LoadLayoutDict('LAYRG' , 'TEXT', verRG);
LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
LoadLayoutDict('LAYHOB', 'TEXT', verHob);

end.
