{NOTE: ignoring changes if empty dir added only}
{TODO: add DoubleAction option: askfortext  to ask for DATA files only?}
{TODO: add act_file for PAK files. OR create new like act_link}
{TODO: add PAK paths and import dirs catalogue}
{TODO: Update = AddDirectory (like man.build)}
{TODO: combine several PAKS into one (at least, as catalogue) [like mod combiner doing]}
{TODO: rename update methods}
{TODO: File.ftype=dir -> "data" is Dirs index?}
{TODO: if "file" was updated in editor. update file or buf?}
{TODO: Rename+update->rename;delete,new|update+rename->update;new,update,delete old}
{TODO: Add marks for all files/subdirs if dir marked for deleting}
{TODO: Replace ctrl.PAK.Name, ctrl.PAK.Version and ctrl.PAK.modinfo}
{TODO: Add update memory consumption count}
unit RGCtrl;

interface

uses
  RGGlobal,
  RGFS,
  RGMan,
  RGPAK;

type
  PRGCtrlInfo = ^TRGCtrlInfo;
  TRGCtrlInfo = object(TManFileInfo)
    data  :PByte;   // Data of update
    size  :integer; // size of Update data (looks like one of size_* double)
    source:integer; // MAN index
    action:integer; // Action of update
    link  :integer; // index of PAK/imported directory
  end;

// Updater action codes
const
  act_none   = 0; // get info, no update action
  act_data   = 1; // text/binary data
  act_file   = 2; // disk file (or pak?) rename to link?
  act_copy   = 3; // just copy of unpacked original PAK data
  act_delete = 4; // delete from PAK
  act_dir    = 5; // (dir only) new dir
  act_reset  = 6; // (event) delete from update (reset)
  act_mark   = 7; // mark for delete (MOD data)

const
  stateNone    = 0;
  stateNew     = 1;
  stateChanged = 2;
  stateDelete  = 3;
  stateRemove  = 4;
  stateLink    = 100;

type
  PRGFullInfo = ^TRGFullInfo;
  TRGFullInfo = record
    name    :PWideChar;
    path    :PWideChar;
    ftime   :UInt64;    // MAN: TL2 only
    size_u  :dword;     // !! PAK: from TPAKFileHeader
// dev only
    size_c  :dword;     // !! PAK: from TPAKFileHeader
    checksum:dword;     // MAN: CRC32
    size_s  :dword;     // ?? MAN: looks like source,not compiled, size (unusable)
    offset  :dword;     // !! MAN: PAK data block offset (??changed to "data" field)
// unnecessary
    ftype   :word;      // !! MAN: RGFileType unified type
    action  :byte;      // act_* constant
    state   :byte;      // state* constant
  end;

type
  // "newdata" is filename if "newsize"=0
  TRGOnDouble = function(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction of object;
type

  { TRGController }

  TRGController = object(TRGDirList)
  private
    FPAK:TRGPAK;
    FOnDouble:TRGOnDouble;
    FLinks:array of PWideChar;

    procedure ClearElement(idx:integer);
    procedure FixSizes(idx:integer; adata:PByte; asize:cardinal);
    procedure CopyInfo(afrom:PRGCtrlInfo; ato:PManFileInfo);
    function  WriteToPAK(var apak:TRGPAK; const fname:string;
         aver:integer; achanges:boolean=false):boolean;
    function  OnDoubleDef(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction;

  public
    property PAK:TRGPAK read FPAK write FPAK;
    property OnDouble:TRGOnDouble read FOnDouble write FOnDouble;

  public
    procedure Init;
    procedure Free;
    procedure Clear;
    function  Rebuild():integer;

    function  SavePatch(const fname:string; aver:integer):boolean;
    function  SaveAs   (const fname:string; aver:integer):boolean;
    function  Save: boolean;

    procedure Trace();

    // Build file list and file info
    procedure GetFullInfo(idx:integer; var info:TRGFullInfo);

    // read update from file or buffer
    function GetUpdate(idx:integer; var buf:PByte):dword;
    // unpacked binary, data as text
    function GetSource(idx:integer; var buf:PByte):dword;
    // unpacked binary, data as binary
    function GetBinary(idx:integer; var buf:PByte):dword;
    // unpacked for unpackable, packed binary for others
    // PS. var size_u, DO NOT "out" for
    function GetPacked(idx:integer; var buf:PByte; var size_u:dword):dword;

    //--- Updater functions ---

    {
      Rename file/dir
    }
    function Rename(idx:integer; newname:PWideChar):boolean;
    {
      Amount of all updates
    }
    function UpdatesCount(): integer;
    {
      Amount of changes required repack ("data" and "file")
    }
    function UpdateChanges():integer;
    {
      state* const for update element
    }
    function UpdateState(idx:integer):integer;
    {
      Delete update
    }
    function RemoveUpdate(idx: integer): integer;
    {
      Mark to remove from PAK
    }
    procedure MarkToRemove(idx:integer);
    {
      add new dir to both Dir and Files lists. negative result points to existing already
      MUST ends by slash
    }
    function NewDir(apath:PWideChar):integer;
    {
      import dir with files and subdirs. apply different actions if files exists
    }
    function ImportDir(const adst, adir: string): integer;
    {
      import PAK content
    }
    function LinkPAK(afile:PWideChar):integer;
    {
      use adata as buffer, no allocate
    }
    function UseData(adata:PByte; asize:cardinal; apath:PWideChar):integer;
    {
      allocate buffer, copy adata content
    }
    function AddUpdate(adata:PByte; asize:cardinal; apath:PWideChar):integer;
    {
      allocate buffer, copy unpacked source data
    }
    function AddCopy(idx:integer):integer;
//    function  AddCopy  (adata:PByte; asize:cardinal; apath:PWideChar):integer;
    {
      keep filename or allocate buffer and load file content
    }
    function AddFileData(afile:PWideChar; apath:PWideChar; acontent:boolean=false):integer;
  end;


implementation

uses
  SysUtils,
  crc,
  RGMod,
  RGFileType,
  RGFile;

{ TRGController }


function TRGController.OnDoubleDef(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction;
begin
  result:=da_overwriteall;
end;

procedure TRGController.Init;
begin
  Inherited Init(SizeOf(TRGCtrlInfo));

  FLinks:=nil;
  FPAK:=TRGPAK.Create;
  FPAK.Version:=verTL2;
  FOnDouble:=@OnDoubleDef;
end;

procedure TRGController.Clear;
var
  i:integer;
begin
  for i:=0 to FileCount-1 do
    if not IsFileDeleted(i) then
      ClearElement(i);

  for i:=0 to High(FLinks) do
    FreeMem(FLinks[i]);
  SetLength(FLinks,0);

  inherited Clear;
end;

procedure TRGController.Free;
begin
  FPAK.Free;
  
  Clear;

  inherited Free;
end;

procedure TRGController.ClearElement(idx:integer);
begin
  with PRGCtrlInfo(Files[idx])^ do
  begin
    case action of 
      act_copy,
      act_data,
      act_file: begin
        FreeMem(data);
        data:=nil;
      end;
    end;
    action:=act_none;
  end;
end;

procedure TRGController.Trace();
var
  i:integer;
begin
  RGLog.Add('Dirs: '+IntToStr(DirCount));
  for i:=0 to DirCount-1 do
  begin
    RGLog.AddWide(Dirs[i].Name);
  end;
  RGLog.Add('Files: '+IntToStr(FileCount));
  for i:=0 to FileCount-1 do
  begin
    RGLog.AddWide(Files[i]^.Name);
  end;
end;

function TRGController.Rebuild():integer;
var
  ldir,ldirs:integer;
  lidx,lfile:integer;
begin
  result:=0;

  DirCapacity :=PAK.Man.DirCapacity;
  FileCapacity:=PAK.Man.FileCapacity;
  // No need to check for existing
  for ldirs:=0 to PAK.Man.DirCount-1 do
  begin
    if not PAK.Man.IsDirDeleted(ldirs) then
    begin
      ldir:=AppendDir(PAK.Man.Dirs[ldirs].name);
      if PAK.Man.GetFirstFile(lidx,ldir) then
        repeat
          lfile:=AppendFile(ldir,nil{PAK.Man.Files[lidx]^.name});
          with PRGCtrlInfo(Files[lfile])^ do
          begin
            SameNameAs(PAK.Man.Files[lidx]);
            source:=lidx;
          end;
        until not PAK.Man.GetNextFile(lidx);
    end;
  end;
end;

procedure TRGController.FixSizes(idx:integer; adata:PByte; asize:cardinal);
begin
  with PRGCtrlInfo(Files[idx])^ do
  begin
    size_s:=0;
    size_u:=0;
    size_c:=0;
    case RGTypeOfFile(adata,asize) of
      tofPacked   : size_c:=asize;
      tofPackedHdr: begin
        size_u:=PPAKFileHeader(adata)^.size_u;
        size_c:=PPAKFileHeader(adata)^.size_c;
      end;
      tofRawHdr   : begin
        size_u:=PPAKFileHeader(adata)^.size_u;
        size_c:=PPAKFileHeader(adata)^.size_u;
      end;
    else
      if ((ftype and $FF)=typeData) and IsSource(adata) then size_s:=asize
      else size_u:=asize;
    end;  
  end;
end;

procedure TRGController.CopyInfo(afrom:PRGCtrlInfo; ato:PManFileInfo);
//var p:PManFileInfo;
begin
// can't use just move coz it changes PARENT, NEXT and OFFSET fields too
{
  if afrom^.action in [act_dir, act_data, act_file] then
    p:=afrom
  else // if afrom.source<>0 then
    p:=PManFileInfo(FPAK.Man.Files[afrom^.source]);
  move(p^,ato^,SizeOf(TManFileInfo));
}
  ato^.size_u  :=ato^.size_u;
  ato^.size_s  :=ato^.size_s;
  ato^.size_c  :=ato^.size_c;
  // not required usually
//  ato^.name    :=afrom^.name;
//  ato^.offset  :=afrom^.offset;
//  ato^._ftype  :=afrom^._ftype;
  ato^.ftime   :=afrom^.ftime;
  ato^.checksum:=afrom^.checksum;
end;

procedure TRGController.GetFullInfo(idx:integer; var info:TRGFullInfo);
var
  p:PRGCtrlInfo;
begin
  FillChar(info,SizeOf(info),0);
  if idx<0 then exit;

  p:=PRGCtrlInfo(Files[idx]);

  info.name    :=p^.Name;
  info.path    :=PathOfFile(idx);
  info.checksum:=p^.checksum;

  if (p^.action in [act_data, act_file]) or (p^.source<0) then
  begin
    info.size_u:=p^.size_u;
    info.size_c:=p^.size_c;
    info.size_s:=p^.size_s;
    info.offset:=0;
    info.ftype :=RGTypeOfExt(info.name);
    info.ftime :=p^.ftime;
  end
  else
  begin
    with PManFileInfo(PAK.Man.Files[p^.source])^ do
    begin
      info.size_u:=size_u;
      info.size_c:=size_c;
      info.size_s:=size_s;
      info.offset:=offset;
      info.ftype :=ftype;
      info.ftime :=ftime;
    end;
  end;

  info.action:=p^.action;
  info.state:=UpdateState(idx);
{
  case info.action of
    act_mark  : info.state:=stateRemove;
    act_delete: info.state:=stateDelete;
    act_data  : if p^.source<0 then info.state:=stateNew else info.state:=stateChanged;
    act_file  : if p^.source<0 then
      info.state:=stateNew+stateLink
    else
      info.state:=stateChanged+stateLink;
  else
    info.state:=0;
  end
}
end;

function TRGController.UpdateState(idx:integer):integer;
begin
  if idx<0 then exit(0);
  with PRGCtrlInfo(Files[idx])^ do
    case action of
      act_mark  : result:=stateRemove;
      act_delete: result:=stateDelete;
      act_data  : if source<0 then result:=stateNew else result:=stateChanged;
      act_file  : if source<0 then
        result:=stateNew+stateLink
      else
        result:=stateChanged+stateLink;
    else
      result:=0;
    end;
end;

{%REGION GetData}

function TRGController.GetUpdate(idx:integer; var buf:PByte):dword;
var
  f:File of byte;
  p:PRGCtrlInfo;
begin
  result:=0;
  p:=PRGCtrlInfo(Files[idx]);

  if p<>nil then
  begin
    // read from file
    if p^.action=act_file then
    begin
      {%I-}
      AssignFile(f,PWideChar(p^.data));
      Reset(f);
      if IOResult=0 then
      begin
        result:=FileSize(f);
        if result>0 then
        begin
          if (buf=nil) or (MemSize(buf)<(result+2)) then
          begin
            FreeMem(buf);
            GetMem(buf,result+2);
          end;
          BlockRead(f,buf^,result);
          buf[result  ]:=0;
          buf[result+1]:=0;
        end;
        CloseFile(f);
      end;

    end
    // read from block
    else
    begin
      result:=p^.size;
      if result>0 then
      begin
        if (buf=nil) or (MemSize(buf)<(result+2)) then
        begin
          FreeMem(buf);
          GetMem(buf, result+2);
        end;
        move(PByte(p^.data)^,buf^,result);
        buf[result  ]:=0;
        buf[result+1]:=0;
      end;
    end;

    FixSizes(idx,buf,result);
{
    if (ftype in setData) and IsSource(buf) then
      p^.size_s:=result
    else
      p^.size_u:=result;
}
  end;
end;

{
  packed - unpack and decompile
  binary - decompile
}
function TRGController.GetSource(idx:integer; var buf:PByte):dword;
var
  p:PRGCtrlInfo;
  lbuf:PWideChar;
begin
  p:=PRGCtrlInfo(Files[idx]);
  if p^.action in [act_data, act_file] then
  begin
    result:=GetUpdate(idx,buf);
  end
  else
  begin
    if PManFileInfo(FPAK.Man.Files[p^.source])^.ftype=typeDirectory then exit(0);
    result:=FPAK.UnpackFile(PathOfFile(idx),p^.name,buf);
  end;

  if result>0 then
  begin
    p^.checksum:=crc32(0,buf,p^.size_u);
    if ((p^.ftype  and $FF)=typeData) and not isSource(buf) then
    begin
      if DecompileFile(buf,result,p^.name,lbuf) then
      begin
        FreeMem(buf);
        buf:=PByte(lbuf);
        result:=(Length(lbuf){+1})*SizeOf(WideChar);
        p^.size_s:=result;
      end;
    end;
  end
  else
  begin
    p^.checksum:=0;
    p^.size_s  :=0;
  end;
end;

{
  packed - unpack
  source - compile
}
function TRGController.GetBinary(idx:integer; var buf:PByte):dword;
var
  p:PRGCtrlInfo;
  lbuf:PByte;
begin
  p:=PRGCtrlInfo(Files[idx]);
  if p^.action in [act_data, act_file] then
  begin
    result:=GetUpdate(idx,buf);
  end
  else
  begin
    if PManFileInfo(FPAK.Man.Files[p^.source])^.ftype=typeDirectory then exit(0);
    result:=FPAK.UnpackFile(PathOfFile(idx),p^.name,buf);
  end;

  if result>0 then
  begin
    if ((p^.ftype and $FF)=typeData) and isSource(buf) then
    begin
      lbuf:=buf;
      buf:=nil;
      result:=CompileFile(lbuf,p^.Name,buf,FPAK.Version);
      p^.size_u:=result;
      FreeMem(lbuf);
    end;
  end
  else
  begin
    p^.size_u  :=0;
    p^.checksum:=0;
    exit;
  end;

  p^.checksum:=crc32(0,buf,p^.size_u);
end;

{
  source - compile+pack
  binary - pack
}
function TRGController.GetPacked(idx:integer; var buf:PByte; var size_u:dword):dword;
var
  p:PRGCtrlInfo;
  lbuf:PByte;
begin
  result:=0;
  p:=PRGCtrlInfo(Files[idx]);
  if p^.action in [act_data, act_file] then
  begin
    if GetUpdate(idx,buf)=0 then exit;

    if RGTypeExtInfo(p^.Name,FPAK.Version)^._pack then
    begin
      if ((p^.ftype and $FF)=typeData) and isSource(buf) then
      begin
        lbuf:=buf;
        buf:=nil;
        p^.size_u:=CompileFile(lbuf,p^.Name,buf,FPAK.Version);
        FreeMem(lbuf);
      end;

      p^.checksum:=crc32(0,buf,p^.size_u);
      lbuf:=buf;
      buf:=nil;
      size_u:=p^.size_u;
      p^.size_c:=RGFilePack(lbuf,size_u,buf,result);
      result:=p^.size_c;
      FreeMem(lbuf);
    end
    else
    begin
      p^.size_c:=p^.size_u;
      result:=p^.size_c;
    end;
  end
  else
  begin
    with PManFileInfo(FPAK.Man.Files[p^.source])^ do
    begin
      if ftype=typeDirectory then exit;
      if offset=0 then
      begin
        RGLog.Add('Next file have offset=0');
        RGLog.AddWide(p^.Name);
        exit;
      end;
    end;

    result:=FPAK.ExtractFile(PathOfFile(idx),p^.name,size_u,buf);
  end;
end;

{%ENDREGION GetData}

{%REGION Updater}

function TRGController.Rename(idx:integer; newname:PWideChar):boolean;
var
  ls:UnicodeString;
  i,ltype:integer;
begin
  result:=false;
  if idx>=0 then
  begin
    ltype:=PRGCtrlInfo(Files[idx])^.ftype;
    i:=Length(newname);
    // convert to UpperCase with slash for dirs
    if i>0 then
    begin
      if ltype=typeDirectory{IsDir(Files[idx])} then
        if (newname[i-1]<>'/') and (newname[i-1]<>'\') then inc(i);

      SetLength(ls,i);
      if ltype=typeDirectory then
      begin
        ls[i]:='/';
        dec(i);
      end;
      while i>0 do
      begin
        ls[i]:=FastUpCase(newname[i-1]);
        dec(i);
      end;
    end
    else
      ls:='';
    // search for existing
    GetFirstFile(i,FileDir(idx));
    repeat
      if CompareWide(Files[i]^.Name,PUnicodeChar(ls))=0 then exit;
    until not GetNextFile(i);
  
    if ltype=typeDirectory then
      RenameDir(PathOfFile(idx),Files[idx]^.Name,PUnicodeChar(ls))
    else
      Files[idx]^.Name:=PUnicodeChar(ls);
    result:=true;
  end;
end;

function TRGController.UpdatesCount():integer;
var
  i,ldirs:integer;
begin
  result:=0;
  ldirs:=0;
  for i:=0 to FileCount-1 do
  begin
    if not IsFileDeleted(i) then
      if PRGCtrlInfo(Files[i])^.action<>act_none then
      begin
        inc(result);
        if PRGCtrlInfo(Files[i])^.action=act_dir then
          inc(ldirs);
      end;
  end;
  // ignore changes if empty dir added only
  if ldirs=result then result:=0;
end;

function TRGController.UpdateChanges():integer;
var
  i:integer;
begin
  result:=0;
  for i:=0 to FileCount-1 do
  begin
    if not IsFileDeleted(i) then
      if PRGCtrlInfo(Files[i])^.action in [act_data,act_file] then inc(result);
  end;
end;

function TRGController.RemoveUpdate(idx:integer):integer;
begin
  if idx>=0 then
  begin
    ClearElement(idx);
    if PRGCtrlInfo(Files[idx])^.source<0 then
    begin
      if isDir(idx) then
        DeletePath(AsDir(idx))
      else
        DeleteFile(idx);
      idx:=-1;
    end;
  end;
  result:=idx;
end;

procedure TRGController.MarkToRemove(idx:integer);
begin
  if idx>=0 then
  begin
    ClearElement(idx);
    PRGCtrlInfo(Files[idx])^.action:=act_delete;
  end;
end;

function TRGController.NewDir(apath:PWideChar):integer;
var
  lslash,ldir,lfile,lcnt:integer;
  lc:UnicodeChar;
begin
  lcnt:=DirCount;
  result:=AddPath(apath);
  // if new dir was added
  if DirCount<>lcnt then
  begin
    // search dir name start
    lslash:=Length(apath)-2;
    while (lslash>0) and (apath[lslash]<>'/') do dec(lslash);

    // search parent dir
    if lslash>0 then
    begin
      inc(lslash);
      lc:=apath[lslash];
      apath[lslash]:=#0; // "cut" text AFTER "/"
      ldir:=SearchPath(apath);
      apath[lslash]:=lc;
    end
    else
      ldir:=0;

    lfile:=AddFile(ldir,apath+lslash);
    with PRGCtrlInfo(Files[lfile])^ do
    begin
      source:=-1;
      ftype :=typeDirectory;
      action:=act_dir;
// not used for dirs
//      ftime :=DateTimeToFileTime(Now());
    end;
    Dirs[result].index:=lfile;
  end
  else
    result:=-result;
end;

function TRGController.UseData(adata:PByte; asize:cardinal; apath:PWideChar):integer;
var
  lcnt:integer;
begin
  lcnt:=FileCount;
  result:=AddFile(apath);
  ClearElement(result);
  with PRGCtrlInfo(Files[result])^ do
  begin
    if FileCount<>lcnt then source:=-1;
    data  :=adata;
    size  :=asize;
    action:=act_data;
    ftime :=DateTimeToFileTime(Now());
    ftype :=RGTypeOfExt(apath);

    FixSizes(result,adata,asize);
  end;
end;

function TRGController.AddUpdate(adata:PByte; asize:cardinal; apath:PWideChar):integer;
var
  lptr:PByte;
begin
  if adata=nil then asize:=0;

  if asize=0 then
    lptr:=nil
  else
  begin
    GetMem(lptr,asize);
    move(adata^,lptr^,asize);
  end;
  result:=UseData(lptr,asize,apath);
end;
{
function TRGController.AddCopy(adata:PByte; asize:cardinal; apath:PWideChar):integer;
begin
  result:=AddUpdate(adata,asize,apath);
  PRGCtrlInfo(Files[result])^.action:=act_copy;
end;
}
function TRGController.AddCopy(idx:integer):integer;
var
  lman:PManFileInfo;
  p   :PRGCtrlInfo;
begin
  result:=idx;
  p:=PRGCtrlInfo(Files[idx]);
  if p^.source<0 then exit;

  //ClearElement(idx);
  FreeMem(p^.data);
  p^.data:=nil;

  lman:=PManFileInfo(FPAK.man.Files[p^.source]);
  FPAK.UnpackSingle(lman,p^.data);
  // Do we really need next? it just copy!
  p^.size_s:=lman^.size_s;
  p^.size_u:=lman^.size_u;
  p^.size_c:=lman^.size_c;
  p^.ftime :=lman^.ftime;
  p^.ftype :=RGTypeOfExt(lman^.Name);
end;

function TRGController.AddFileData(afile:PWideChar; apath:PWideChar; acontent:boolean=false):integer;
var
  lptr:PByte;
  f:file of byte;
  sr:TUnicodeSearchRec;
  lsize,lcnt:integer;
begin
  if not acontent then
  begin
    lcnt:=FileCount;
    result:=AddFile(apath);
    ClearElement(result);
    with PRGCtrlInfo(Files[result])^ do
    begin
      if FileCount<>lcnt then source:=-1;
      ftype :=RGTypeOfExt(apath);
      data  :=PByte(CopyWide(afile));
      action:=act_file;
      ftime :=0;
      size_s:=0;
      size_u:=0;
      size_c:=0;
    end;
  end
  else
  begin
    system.Assign(f,afile);
    system.Reset(f);
    if IOResult=0 then
    begin
      lsize:=FileSize(f);
      if lsize>0 then
      begin
        GetMem(lptr,lsize);
        BlockRead(f,lptr^,lsize);
      end
      else
        lptr:=nil;
      system.Close(f);

      result:=UseData(lptr,lsize,apath);

      if FindFirst(afile,faAnyFile,sr)=0 then
      begin
        Files[result]^.ftime:=sr.Time;
        FindClose(sr);
      end;

    end
    else
      result:=SearchFile(apath);
  end;
end;

{%ENDREGION Updater}

{%REGION Save}

function TRGController.WriteToPAK(var apak:TRGPAK; const fname:string;
    aver:integer; achanges:boolean=false):boolean;
var
  p:PRGCtrlInfo;
  lman:PManFileInfo;
  lbuf:PByte;
  lidx,i,j,ldir:integer;
begin
  result:=false;

  if aver=1000 then aver:=FPAK.Version;
  apak.CreatePAK(fname,@FPAK.modinfo,aver);

  lbuf:=nil;

  for i:=0 to DirCount-1 do
  begin
    if isDirDeleted(i) then continue;

    // save empty dirs coz they are saved in parent list
//    ldir:=apak.man.AddPath(Dirs[i].name);
    ldir:=-1;

    if GetFirstFile(j,i) then
      repeat
        if achanges then
          if not (UpdateState(j) in
             [stateNew,stateChanged,stateNew+stateLink,stateChanged+stateLink]) then
            Continue;

        p:=PRGCtrlInfo(Files[j]);

        if p^.action=act_delete then continue;

        // Add dir ONLY with files/subdirs
        if ldir=-1 then ldir:=apak.man.AddPath(Dirs[i].name);

        // 1 - create MAN record
        lidx:=apak.man.CloneFile(ldir,p);
        lman:=PManFileInfo(apak.man.Files[lidx]);

        if not (lman^.ftype in [typeDirectory]) then
        begin
          p^.size_c:=GetPacked(j,lbuf,p^.size_u);

          CopyInfo(p,lman);

          if lman^.size_s=0 then lman^.size_s:=lman^.size_u;
          lman^.offset:=apak.WritePackedFile(lbuf,p^.size_u,p^.size_c);
        end
        else
          CopyInfo(p,lman);
        
      until not GetNextFile(j);
  end;

  FreeMem(lbuf);

  apak.FinishPAK;
  result:=true;
end;

function TRGController.SavePatch(const fname:string; aver:integer):boolean;
var
  lpak:TRGPAK;
begin
  result:=false;

  lpak:=TRGPAK.Create;

  if WriteToPAK(lpak,ExtractFileDir(fname)+'\'+ExtractNameOnly(fname)+'_TMP', aver, true) then
  begin
    lpak.Rename(fname);
    result:=true;
  end;

  lpak.Free;
end;

function TRGController.SaveAs(const fname:string; aver:integer):boolean;
var
  lpak:TRGPAK;
begin
  result:=false;

  // just copy original (if only original is not directory)
  if (UpdatesCount=0) and (not FPAK.modinfo.modified) and (aver=FPAK.Version) then
  begin
    result:=FPAK.Clone(fname);
  end;

  if not result then
  begin
    lpak:=TRGPAK.Create;

    if WriteToPAK(lpak,ExtractFileDir(fname)+'\'+ExtractNameOnly(fname)+'_TMP', aver) then
    begin
      lpak.Rename(fname);
      result:=true;

      if FPAK.Name='' then
      begin
        FPAK.Free;
        Clear;
        FPAK:=lpak;
        FPAK.OpenPAK;
        Rebuild;
        exit;
      end;
    end;

	  lpak.Free;
  end;
end;

function TRGController.Save():boolean;
var
  lpak:TRGPAK;
  lname:string;
begin
  result:=false;
//  result:=SaveAs(FPAK.Directory+FPAK.Name);

  lname:=FPAK.Directory+FPAK.Name;
  lpak:=TRGPAK.Create;
  if WriteToPAK(lpak, lname+'_TMP',FPAK.Version) then
  begin
    FPAK.Free;
    lpak.Rename(lname);
    result:=true;

    Clear;
    FPAK:=lpak;
    FPAK.OpenPAK;
    Rebuild;
  end;
end;

{%ENDREGION Save}

{
  Check file name to include or not. skip unknown, png if dds presents
    and compiled data files if source presents
  in : dir and filename to check
  out: empty to skip, lname to include
}
function CheckFName(const adir,aname:UnicodeString):UnicodeString;
var
  lext:array [0..15] of UnicodeChar;
  lname:UnicodeString;
  lextpos,j,k:integer;
begin
  lextpos:=Length(aname);
  if aname[lextpos]='/' then
    exit(aname);

  result:='';
  
  while lextpos>1 do
  begin
    dec(lextpos);
    if aname[lextpos]='.' then break;
  end;
  // extract ext
  k:=0;
  if lextpos>1 then
    for j:=lextpos to Length(aname) do
    begin
      lext[k]:=FastUpCase(aname[j]);
      inc(k);
    end;
  lext[k]:=#0;

  if (CompareWide(lext,'.TXT'      )=0) or
     (CompareWide(lext,'.BINDAT'   )=0) or
     (CompareWide(lext,'.BINLAYOUT')=0) or
     (CompareWide(lext,'.CMP'      )=0) or
     (CompareWide(lext,'.ADM'      )=0) then
  begin
    lname:=Copy(aname,1,lextpos-1);
    if FileExists(adir+lname) then exit;
  end
  else if CompareWide(lext,'.PNG')=0 then
  begin
    lname:=aname;
    lname[lextpos+1]:='D';
    lname[lextpos+2]:='D';
    lname[lextpos+3]:='S';
    if FileExists(adir+lname) then
      exit
    else
      exit(aname);
  end
  else
    lname:=aname;

  // can't use lext coz need to delete ext to get real sometime
  if RGTypeOfExt(PUnicodeChar(lname))<>typeUnknown then
    result:=lname;
end;

{
  Build files tree [from MEDIA folder] [from dir]
  as is, bin+src (data cmp to choose), bin, src
  adir   - current disk dir
  actrl  - our manifest
  aentry - current manifest directory
}
function CycleDir(const adir:UnicodeString; var actrl:TRGController; aentry:integer;
   aact:TRGDoubleAction):TRGDoubleAction;
var
  sr:TUnicodeSearchRec;
  ldir,lname,ltmp:UnicodeString;
  lbuf:PByte;
  i,lsize:integer;
begin
  ldir:=actrl.Dirs[aentry].name;

  // IN: act=skip/over dir/all or ask
  if FindFirst(adir+'*.*',faAnyFile and faDirectory,sr)=0 then
  begin

    repeat
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          i:=actrl.NewDir(PUnicodeChar(ldir+sr.Name+'/'));
          case CycleDir(adir+sr.Name+'/', actrl, ABS(i), aact) of
            da_skipall     : aact:=da_skipall;
            da_overwriteall: aact:=da_overwriteall;
            da_stop:begin
              aact:=da_stop;
              break;
            end;
          else
          end;
        end;
      end
      else
      begin
        if UpCase(sr.Name)=TL2ModData then
        begin
          if actrl.PAK.modinfo.title=nil then
            LoadModConfig(PChar(AnsiString(adir+TL2ModData)),actrl.PAK.modinfo);
          continue;
        end;
        lname:=CheckFName(adir,sr.Name);
        if lname<>'' then
        begin
          i:=actrl.SearchFile(aentry,PUnicodeChar(lname));
          if i<0 then
          begin
            actrl.AddFileData(PUnicodeChar(adir+lname),PUnicodeChar(ldir+lname),false);
          end
          else
          begin
            RGLog.AddWide(PWideChar(adir+lname+' file exists already'));
            if aact=da_ask then
            begin
              if actrl.OnDouble=nil then aact:=da_overwriteall
              else
              begin
                ltmp :=adir+lname;
                lbuf :=PByte(PUnicodeChar(ltmp));
                lsize:=0;
                aact:=actrl.OnDouble(i,PByte(lbuf),lsize);
              end;
            end;

            case aact of
              da_stop: begin
                aact:=da_stop;
                break;
              end;

              da_skip,
              da_skipdir,
              da_skipall: begin
                if aact=da_skip then aact:=da_ask;
                continue;
              end;

              da_overwrite,
              da_overwritedir,
              da_overwriteall: begin
                if aact=da_overwrite then aact:=da_ask;
//                if UpdateState(i)=stateNone then
                actrl.AddFileData(PUnicodeChar(adir+lname),PUnicodeChar(ldir+lname),false);
              end;

//!! visual part. must be processed inside FOnDouble
//!! But requires ctrl or new name or new content (buf+size)
              da_compare: begin // data+size
                aact:=da_ask;
                actrl.UseData(lbuf,lsize,PUnicodeChar(ldir+lname));
              end;
              da_renameold: begin // name + check again. what if new name exists already?
                aact:=da_ask;
                actrl.Rename(i,PUnicodeChar(lbuf));
                actrl.AddFileData(PUnicodeChar(adir+lname),PUnicodeChar(ldir+lname),false);
                FreeMem(lbuf);
              end;
              da_saveas: begin // name + check again
                aact:=da_ask;
                actrl.AddFileData(
                    PUnicodeChar(adir+UnicodeString(PUnicodeChar(lbuf))),
                    PUnicodeChar(ldir+lname),false);
                FreeMem(lbuf);
              end;

            else
            end;

          end;
        end;
      end;
    until FindNext(sr)<>0;

    FindClose(sr);
  end;

  // OUT: skip/over all, ask or stop
  if aact in [da_stop,da_skipall,da_overwriteall] then
    result:=aact
  else
    result:=da_ask;
end;

function TRGController.ImportDir(const adst, adir:string):integer;
var
  ls:UnicodeString;
  ldir:integer;
begin
  result:=FileCount;

  ls:=UnicodeString(adir);
  if not (adir[Length(adir)] in ['/','\']) then ls:=ls+'/';

  if DirCount=0 then AddPath(nil);
  ldir:=SearchPath(adst);
  if ldir<0 then ldir:=0;
  CycleDir(ls,self,ldir,da_ask);

  // new records only
  // but skip starting empty file
  if result=0 then result:=1;
  result:=FileCount-result;
end;

function TRGController.LinkPAK(afile:PWideChar):integer;
begin
  result:=FileCount;
  if DirCount=0 then AddPath(nil);
  // Add PAK name to FLinks
  // MakeRGScan()
{
function MakeRGScan(
    const aroot,adir:string;
    aext:array of string;
    actproc:TProcessProc=nil; aparam:pointer=nil;
    checkproc:TCheckNameProc=nil):integer;
}
//  MakeRGScan(nil,afile,[],nil{CheckPAKFile},self,nil{CheckPAKFName});
  // set action=act_link

  if result=0 then result:=1;
  result:=FileCount-result;
end;

end.
