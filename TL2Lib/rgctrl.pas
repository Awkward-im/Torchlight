{TODO: combine several PAKS into one (at least, as catalogue) [like mod combiner doing]}
{TODO: implement New PAK}
{TODO: rename update methods}
{TODO: File.ftype=dir -> "data" is Dirs index?}
{TODO: check "delete" state for dirs (if corresponding file record marked)}
{TODO: Apply (no save)}
{TODO: if "file" was updated in editor. update file or buf?}
{TODO: Rename+update->rename;delete,new|update+rename->update;new,update,delete old}
{TODO: Add marks for all files/subdirs if dir marked for deleting}
{TODO: Replace ctrl.PAK.Name, ctrl.PAK.Version and ctrl.PAK.modinfo}
{TODO: Add update memory consumption count}
{TODO: Add "add directory" action or at least function}
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
  end;

// Updater action codes
const
  act_none   = 0; // get info, no update action
  act_data   = 1; // text/binary data
  act_file   = 2; // disk file
  act_copy   = 3; // just copy of unpacked original PAK data
  act_delete = 4; // delete from PAK
  act_dir    = 5; // new dir
  act_reset  = 6; // delete from update (reset), event only
  act_mark   = 7; // mark for delete (MOD data)

const
  stateNew     = 1;
  stateChanged = 2;
  stateDelete  = 3;
  stateRemove  = 4;
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
    ftype   :byte;      // !! MAN: RGFileType unified type
    action  :byte;      // act_* constant
    state   :byte;      // state* constant
  end;

type

  { TRGController }

  TRGController = object(TRGDirList)
  private
    FPAK:TRGPAK;
    procedure ClearElement(idx:integer);
    procedure FixSizes(idx:integer; adata:PByte; asize:cardinal);
    procedure CopyInfo(afrom:PRGCtrlInfo; ato:PManFileInfo);
    function  WriteToPAK(var apak:TRGPAK; const fname:string; aver:integer=1000):boolean;

  public
    property PAK:TRGPAK read FPAK write FPAK;

  public
    procedure Init;
    procedure Free;
    procedure Clear;
    function  Rebuild():integer;

    function  SaveAs(const fname:string; aver:integer):boolean;
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
    function  UpdatesCount(): integer;
    {
      Amount of changes required repack ("data" and "file")
    }
    function  UpdateChanges():integer;
    {
      state* const for update element
    }
    function  UpdateState (idx:integer):integer;
    {
      Delete update
    }
    function RemoveUpdate(idx: integer): integer;
    {
      Mark to remove from PAK
    }
    procedure MarkToRemove(idx:integer);
    {
      add new dir to both Dir and Files lists
    }
    function  NewDir(apath:PWideChar):integer;
    {
      use adata as buffer, no allocate
    }
    function  UseData  (adata:PByte; asize:cardinal; apath:PWideChar):integer;
    {
      allocate buffer, copy adata content
    }
    function  AddUpdate(adata:PByte; asize:cardinal; apath:PWideChar):integer;
    {
      allocate buffer, copy unpacked source data
    }
    function  AddCopy  (idx:integer):integer;
//    function  AddCopy  (adata:PByte; asize:cardinal; apath:PWideChar):integer;
    {
      keep filename or allocate buffer and load file content
    }
    function  AddFileData(afile:PWideChar; apath:PWideChar; acontent:boolean=false):integer;
  end;


implementation

uses
  SysUtils,
  crc,
  rgfiletype,
  RGFile;

{ TRGController }

procedure TRGController.Init;
begin
  Inherited Init(SizeOf(TRGCtrlInfo));

  FPAK:=TRGPAK.Create;
end;

procedure TRGController.Clear;
var
  i:integer;
begin
  for i:=0 to FileCount-1 do
    if not IsFileDeleted(i) then
      ClearElement(i);

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

function TRGController.Rebuild(): integer;
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
      if (ftype in setData) and IsSource(adata) then size_s:=asize
      else size_u:=asize;
    end;  
  end;
end;

function TRGController.UpdateState(idx:integer):integer;
begin
  with PRGCtrlInfo(Files[idx])^ do
    case action of
      act_mark  : result:=stateRemove;
      act_delete: result:=stateDelete;
      act_data,
      act_file  : if source=0 then result:=stateNew else result:=stateChanged;
    else
      result:=0;
    end;
end;

procedure TRGController.CopyInfo(afrom:PRGCtrlInfo; ato:PManFileInfo);
var
  p:PManFileInfo;
begin
  if afrom^.action in [act_dir, act_data, act_file] then
    p:=afrom
  else // if afrom.source<>0 then
    p:=PManFileInfo(FPAK.Man.Files[afrom^.source]);
  move(p^,ato^,SizeOf(TManFileInfo));
end;

procedure TRGController.GetFullInfo(idx:integer; var info:TRGFullInfo);
var
  p:PRGCtrlInfo;
begin
  if idx<0 then
  begin
    FillChar(info,SizeOf(info),0);
    exit;
  end;
  p:=PRGCtrlInfo(Files[idx]);

  info.name    :=p^.Name;
  info.path    :=PathOfFile(idx);
  info.checksum:=p^.checksum;

  if (p^.action in [act_data, act_file]) or (p^.source=0) then
  begin
    info.size_u:=p^.size_u;
    info.size_c:=p^.size_c;
    info.size_s:=p^.size_s;
    info.offset:=0;
    info.ftype :=PAKExtType(info.name);
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
  // info.state:=UpdateState(idx);
  case info.action of
    act_mark  : info.state:=stateRemove;
    act_delete: info.state:=stateDelete;
    act_data,
    act_file  : if p^.source=0 then info.state:=stateNew else info.state:=stateChanged;
  else
    info.state:=0;
  end
end;

{%REGION GetData}

function TRGController.GetUpdate(idx:integer; var buf:PByte):dword;
var
  p:PRGCtrlInfo;
  f:File of byte;
begin
  result:=0;
  p:=PRGCtrlInfo(Files[idx]);

  if p<>nil then
  begin
    // read from file
    if p^.action=act_file then
    begin
      system.Assign(f,PWideChar(p^.data));
      system.Reset(f);
      if IOResult=0 then
      begin
        result:=FileSize(f);
        if result>0 then
        begin
          if (buf=nil) or (MemSize(buf)<result) then
          begin
            FreeMem(buf);
            GetMem(buf,result);
          end;
          BlockRead(f,buf^,result);
        end;
        system.Close(f);
      end;

    end
    // read from block
    else
    begin
      result:=p^.size;
      if result>0 then
      begin
        if (buf=nil) or (MemSize(buf)<result) then
        begin
          FreeMem(buf);
          GetMem(buf, result);
        end;
        move(PByte(p^.data)^,buf^,result);
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
    if (p^.ftype in setData) and not isSource(buf) then
    begin
      if DecompileFile(buf,result,p^.name,lbuf) then
      begin
        FreeMem(buf);
        buf:=PByte(lbuf);
        result:=(Length(lbuf)+1)*SizeOf(WideChar);
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

    if result>0 then
    begin
      if (p^.ftype in setData) and isSource(buf) then
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

  end
  else
  begin
    if PManFileInfo(FPAK.Man.Files[p^.source])^.ftype=typeDirectory then exit(0);
    result:=FPAK.UnpackFile(PathOfFile(idx),p^.name,buf);
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

    if GetExtInfo(p^.Name,FPAK.Version)^._pack then
    begin
      if (p^.ftype in setData) and isSource(buf) then
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
        ls[i]:=UpCase(newname[i-1]);
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
  
    Files[idx]^.Name:=PUnicodeChar(ls);
    if ltype=typeDirectory then RenameDir(PathOfFile(idx),Files[idx]^.Name,PUnicodeChar(ls));
    result:=true;
  end;
end;

function TRGController.UpdatesCount():integer;
var
  i:integer;
begin
  result:=0;
  for i:=0 to FileCount-1 do
  begin
    if not IsFileDeleted(i) then
      if PRGCtrlInfo(Files[i])^.action<>act_none then inc(result);
  end;
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
    if PRGCtrlInfo(Files[idx])^.source=0 then
    begin
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
      ftype :=typeDirectory;
      action:=act_dir;
// not used for dirs
//      ftime :=DateTimeToFileTime(Now());
    end;
    Dirs[result].index:=lfile;
  end
  else
    result:=-1;
end;

function TRGController.UseData(adata:PByte; asize:cardinal; apath:PWideChar):integer;
begin
  result:=AddFile(apath);
  ClearElement(result);
  with PRGCtrlInfo(Files[result])^ do
  begin
    data  :=adata;
    size  :=asize;
    action:=act_data;
    ftime :=DateTimeToFileTime(Now());
    ftype :=PAKExtType(apath);

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
  if p^.source=0 then exit;

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
  p^.ftype :=PAKExtType(lman^.Name);
end;

function TRGController.AddFileData(afile:PWideChar; apath:PWideChar; acontent:boolean=false):integer;
var
  lptr:PByte;
  f:file of byte;
  sr:TUnicodeSearchRec;
  lsize:integer;
begin
  if not acontent then
  begin
    result:=AddFile(apath);
    ClearElement(result);
    with PRGCtrlInfo(Files[result])^ do
    begin
      ftype :=PAKExtType(apath);
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

function TRGController.WriteToPAK(var apak:TRGPAK; const fname:string; aver:integer=1000):boolean;
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
    ldir:=apak.man.AddPath(Dirs[i].name);
//    ldir:=lpak.AddDirectory(Dirs[i].name);
    if GetFirstFile(j,i) then
      repeat
        p:=PRGCtrlInfo(Files[j]);

        if p^.action=act_delete then continue;

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

function TRGController.SaveAs(const fname:string; aver:integer):boolean;
var
  lpak:TRGPAK;
begin
  result:=false;

  // just copy original (if only original is not directory)
  if (UpdatesCount=0) and (not FPAK.modinfo.modified) and (aver=FPAK.Version) then
  begin
    FPAK.Clone(fname);
    result:=true;
  end
  else
  begin
    lpak:=TRGPAK.Create;

    if WriteToPAK(lpak,ExtractFileDir(fname)+'\'+ExtractFileNameOnly(fname)+'_TMP', aver) then
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
  if WriteToPAK(lpak, lname+'_TMP') then
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

end.
