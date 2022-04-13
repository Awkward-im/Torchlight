unit unitCombine;

interface

// Statistic

// Adding

function AddMod(const aroot, asrc:string):integer;


implementation

{$R dict.rc}

uses
  fmAsk,
  Diff,

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
  lbuf,lnode:pointer;
  lsize:integer;
  isold,istext:boolean;
begin
  result:=0;

  //--- Check for text files/ Convert from binary if needs

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

  //--- check 1 - existing file

  if FileExists(ldst) then
  begin
    // Check for same file
    Assign(f,ldst);
    Reset(f);
    lsize:=FileSize(f);
    if lsize=asize then
    begin
      GetMem(lbuf,asize);
      BlockRead(f,lbuf^,asize);
      isold:=CompareMem(abuf,PByte(lbuf),asize);
      FreeMem(lbuf);
    end;
    Close(f);

    if isold then exit(1);

    RGLog.Add(adir+aname+' file exists already');

    if pourdata(aparam)^.act=ask then
    begin
      with tAskForm.Create(adir+aname, lsize, asize
           {, integer(pourdata(aparam)^.act)}) do
      begin
        pourdata(aparam)^.act:=tact(ShowModal());
        // 'skip' and 'overwrite' will be changed to 'ask' later?
        Free;
      end;
    end;

    case pourdata(aparam)^.act of
      ask: ; // Compare
      stop: exit(0);
      skip,
      skipall: exit(1);
      overwrite,
      overwritedir,
      overwriteall: ; // do nothing, just rewrite file
    else
    end;

    //  text file - use 'compare' result
    if istext then
    begin
    end;
  end
  else
  begin
    // Create directory (trying once per scanning dir)
    if pourdata(aparam)^.lastdir<>adir then
    begin
      if not (pourdata(aparam)^.act in [skipall,overwriteall]) then
        pourdata(aparam)^.act:=ask;

      ForceDirectories(pourdata(aparam)^.outdir+adir);
      pourdata(aparam)^.lastdir:=adir;
    end;
  end;

  Assign(f,ldst);
  Rewrite(f);
  if IOResult=0 then
  begin
    BlockWrite(f,abuf^,asize);
    Close(f);
    result:=1;
  end;
end;

function checkproc(const adir,aname:string; aparam:pointer):integer;
var
  ldst:string;
begin
  result:=0;

  ldst:=UpCase(adir);
  if Pos('MEDIA',adir)=1 then
  begin
    ldst:=UpCase(aname);
    if ldst<>'MOD.DAT' then // must be always coz outside MEDIA folder
    begin
      ldst:=ExtractFileExt(ldst);
      if (ldst<>'.BINDAT'   ) and
         (ldst<>'.BINLAYOUT') and
         (ldst<>'.RAW'      ) then
        result:=1;
    end;
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
