{TODO: Check RemoveUpdate}
{TODO: Check what saving uses Ctrl, NOT Man name}
{TODO: Check mark of deleting for files with same name}
{TODO: Check for source of text files for "source size" field}
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
  TRGOnChange = RGFS.TRGOnChange;
type
  PRGCtrlInfo = ^TRGCtrlInfo;
  TRGCtrlInfo = object(TFileInfo)
    data  :PByte;   // Data of update
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
    size    :dword;     // ?? MAN: looks like source,not compiled, size (unusable)
    offset  :dword;     // !! MAN: PAK data block offset (??changed to "data" field)
// unnecessary
    ftype   :word;      // !! MAN: RGFileType unified type
    action  :byte;      // act_* constant
    state   :byte;      // state* constant
  end;

type
  // "newdata" is filename if "newsize"=0
  TRGOnDouble  = function(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction of object;

const
  faAdd      = RGFS.faAdd;      // file/dir added
  faRename   = RGFS.faRename;   // file/dir renamed
  faDeleting = RGFS.faDeleting; // file/dir deleted
  faDeleted  = RGFS.faDeleted;  // file/dir deleted
  faMove     = RGFS.faMove;     // unimplemented
  faChanged  = 10; // file content changed
  faInfo     = 11; // file info updated (like PAK'ed size). No need to save
  faStatus   = 12; // file/dir status changed (delete/recover)
  faStart    = 13; // start  group operation
  faFinish   = 14; // finish group operation (idx - count)

type

  { TRGController }

  PRGController = ^TRGController;
  TRGController = object(TRGDirList)
  private
    FPAK:TRGPAK;
    FOnDouble :TRGOnDouble;

    FLinks:array of PWideChar;

    procedure ClearElement(idx:integer);
    procedure FixSizes(idx:integer; adata:PByte; asize:cardinal);
    procedure CopyInfo(afrom:PRGCtrlInfo; ato:PManFileInfo);
    function  WriteToPAK(var apak:TRGPAK; const fname:string;
         aver:integer; achanges:boolean=false):boolean;
    function  OnDoubleDef(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction;

    function GetFileInfoPtr(idx:integer):PRGCtrlInfo;
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

    //--- Get info ---
    
    // Build file list and file info
    procedure GetFullInfo(idx:integer; out info:TRGFullInfo);

    // read update from file or buffer ONLY, NOT PAK
    function GetUpdate (idx:integer; var buf:PByte):dword;
    // read updated or unpacked from PAK content
    function GetContent(idx:integer; var buf:PByte):dword;
    // unpacked binary, data as is. Like GetContent but with checksum (and event)
    function GetAsIs   (idx:integer; var buf:PByte):dword;
    // unpacked binary, data as text
    function GetSource (idx:integer; var buf:PByte):dword;
    // unpacked binary, data as binary
    function GetBinary (idx:integer; var buf:PByte):dword;
    // unpacked for non-packable, packed binary for others
    // PS. var size_u, DO NOT "out" for
    function GetPacked (idx:integer; var buf:PByte; var asize_u:dword):dword;

    //--- Updater functions ---

    {
      Amount of all updates
    }
    function UpdatesCount():integer;
    {
      Amount of changes required repack ("data" and "file")
    }
    function UpdateChanges():integer;
    {
      state* const for update element
    }
    function GetUpdateState(idx:integer):integer;
    {
      Delete update, keep manifest record (if any)
    }
    function RemoveUpdate(aidx:integer):integer;
    {
      Remove item at all (update+manifest)
    }
    procedure Delete(aidx:integer);
    {
      Mark to remove from PAK
    }
    procedure MarkToRemove(idx:integer);
    {
      add new dir to both Dir and Files lists. negative result points to existing already
      MUST ends by slash
    }
    function NewDir(adir:integer; aname:PWideChar):integer;
    function NewDir(apath:PWideChar):integer;
    function NewDir(const apath:AnsiString):integer;
    {
      import dir with files and subdirs. apply different actions if files exists
    }
    function ImportDir(const adst, adir:string; nochild:boolean=false): integer;
    {
      import PAK content
    }
    function LinkPAK(afile:PWideChar):integer;
    {
      use adata as buffer, no allocate
    }
    function UseData(adata:PByte; asize:cardinal; apath:PWideChar):integer;
    function UseData(adata:PByte; asize:cardinal; const apath:AnsiString):integer;
    {
      allocate buffer, copy adata content
    }
    function AddUpdate(adata:PByte; asize:cardinal; apath:PWideChar):integer;
    function AddUpdate(adata:PByte; asize:cardinal; const apath:AnsiString):integer;
    {
      allocate buffer, copy unpacked source data
    }
    function AddCopy(idx:integer):integer;
//    function  AddCopy  (adata:PByte; asize:cardinal; apath:PWideChar):integer;
    {
      keep filename or allocate buffer and load file content
    }
    function AddFileData(afdata:PWideChar; afname:PWideChar; acontent:boolean=false):integer;


    property Files[idx:integer]:PRGCtrlInfo read GetFileInfoPtr;
  end;

function GetChangesName(atype:integer):AnsiString;


implementation

uses
  SysUtils,
  CRC,
  RGMod,
  RGFileType,
  RGFile;

function GetChangesName(atype:integer):AnsiString;
begin
  case atype of
    faAdd     : result:='Add'    ;
    faRename  : result:='Rename' ;
    faDeleting: result:='Deleting';
    faDeleted : result:='Deleted' ;
    faMove    : result:='Move'   ;
    faChanged : result:='Changed';
    faInfo    : result:='Info'   ;
    faStatus  : result:='Status' ;
    faStart   : result:='Start'  ;
    faFinish  : result:='Finish' ;
  else
    result:='Unknown';
  end;
end;

{ TRGController }

function TRGController.GetFileInfoPtr(idx:integer):PRGCtrlInfo; //inline;
begin
  result:=PRGCtrlInfo(pointer(TRGDirList.GetFileInfoPtr(idx)));
end;

function TRGController.OnDoubleDef(idx:integer; var newdata:PByte; var newsize:integer):TRGDoubleAction;
begin
  result:=da_overwriteall;
end;

procedure TRGController.Init;
begin
  FillChar(self,SizeOf(self),0);
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
    RGLog.AddWide(PWideChar(Dirs[i].Name{+' '+IntToStr(Dirs[i].index)}));
  end;
  RGLog.Add(#13#10'Files: '+IntToStr(FileCount));
  for i:=0 to FileCount-1 do
  begin
    RGLog.AddWide(PWideChar(Files[i]^.Name{+' '+IntToStr(Files[i]^.index)+' '+IntToStr(Files[i]^.parent)}));
  end;
end;

function TRGController.Rebuild():integer;
var
  lsrc:PRGManifest;
  ldir,ldirs:integer;
  lidx,lfile:integer;
begin
  result:=0;

  OnChange(@self,0,faStart);

  lsrc:=@PAK.Man;

  DirCapacity :=lsrc^.DirCapacity;
  FileCapacity:=lsrc^.FileCapacity;
  // No need to check for existing
  for ldirs:=0 to lsrc^.DirCount-1 do
  begin
    if not lsrc^.IsDirDeleted(ldirs) then
    begin
      ldir:=AddPath(lsrc^.Dirs[ldirs].name);//!!
//      ldir:=AppendDir(PAK.Man.Dirs[ldirs].name);//!!
      if PAK.Man.GetFirstFile(lidx,ldirs) then
        repeat
          lfile:=DoAddFile(ldir,nil{PAK.Man.Files[lidx]^.name});//!!
          inc(result);
          with PRGCtrlInfo(Files[lfile])^ do
          begin
            SameNameAs(lsrc^.Files[lidx]);
            source:=lidx;
          end;
        until not lsrc^.GetNextFile(lidx);
    end;
  end;
  OnChange(@self,result,faFinish);
end;

procedure TRGController.FixSizes(idx:integer; adata:PByte; asize:cardinal);
begin
  Files[idx]^.size:=asize;
  OnChange(@self,idx,faInfo);
end;

procedure TRGController.CopyInfo(afrom:PRGCtrlInfo; ato:PManFileInfo);
begin
  ato^.size    :=afrom^.size;
  ato^.ftime   :=afrom^.ftime;
  ato^.checksum:=afrom^.checksum;
end;

procedure TRGController.GetFullInfo(idx:integer; out info:TRGFullInfo);
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
    info.size  :=p^.size;
    info.ftype :=RGTypeOfExt(info.name); // p^.ftype;
    info.ftime :=p^.ftime;
  end
  else
  begin
    with PManFileInfo(PAK.Man.Files[p^.source])^ do
    begin
      info.size_u:=size_u;
      info.size_c:=size_c;
      info.size  :=size;
      info.offset:=offset;
      info.ftype :=ftype;
      info.ftime :=ftime;
    end;
  end;

  info.action:=p^.action;
  info.state:=GetUpdateState(idx);
end;

function TRGController.GetUpdateState(idx:integer):integer;
begin
  if idx<0 then exit(0);
  with PRGCtrlInfo(Files[idx])^ do
    case action of
      act_mark  : result:=stateRemove;
      act_delete: result:=stateDelete;
// False work with MEDIA on new pak
//      act_dir   : if source<0 then result:=stateNew else result:=stateChanged;
      act_data  : if source<0 then result:=stateNew else result:=stateChanged;
      act_file  : if source<0 then
        result:=stateNew+stateLink
      else
        result:=stateChanged+stateLink;
    else
      result:=stateNone;
    end;
end;

{%REGION GetData}

function TRGController.GetUpdate(idx:integer; var buf:PByte):dword;
var
  f:File of byte;
  sr:TUnicodeSearchRec;
  p:PRGCtrlInfo;
  lext:UnicodeString;
  lres:integer;
  ltime:UINt64;
  lchanged:boolean;
begin
  result:=0;
  if IsFileDeleted(idx) then exit;

  p:=PRGCtrlInfo(Files[idx]);

  lchanged:=false;

  // read from file
  if p^.action=act_file then
  begin
    {$I-}
    AssignFile(f,PWideChar(p^.data));
    Reset(f);
    lres:=IOResult();
    if lres<>0 then
    begin
      lext:=UpCase(ExtractFileExt(PWideChar(p^.data)));
      if (lext='.DAT') or (lext='.ANIMATION') or
         (lext='.HIE') or (lext='.TEMPLATE' ) then
      begin
        if PAK.Version=verTL1 then
          lext:=UnicodeString(PWideChar(p^.data))+'.ADM'
        else
          lext:=UnicodeString(PWideChar(p^.data))+'.BINDAT'
      end
      else if UpCase(lext)='.LAYOUT' then
        lext:=UnicodeString(PWideChar(p^.data))+'.BINLAYOUT'
      else
        lext:='';

      if lext<>'' then
      begin
        AssignFile(f,lext);
        Reset(f);
        lres:=IOResult();
      end;
    end;
    if lres=0 then
    begin
      result:=FileSize(f);
      if result>0 then
      begin
        lchanged:=lchanged or (p^.size<>result);
        p^.size:=result;

        if FindFirst(PWideChar(p^.data),faAnyFile,sr)=0 then
        begin
          ltime:=DateTimeToFileTime(sr.TimeStamp);
          lchanged:=lchanged or (p^.ftime<>ltime);
          p^.ftime:=ltime;
          FindClose(sr);
        end;
        if lchanged then OnChange(@self,idx,faInfo);

        if (buf=nil) or (MemSize(buf)<(result+2)) then
        begin
          FreeMem(buf);
          GetMem(buf,Align(result+2,4096));
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
        GetMem(buf,Align(result+2,4096));
      end;
      move(PByte(p^.data)^,buf^,result);
      buf[result  ]:=0;
      buf[result+1]:=0;
    end;
  end;

//  FixSizes(idx,buf,result);
end;

function TRGController.GetContent(idx:integer; var buf:PByte):dword;
var
  p:PRGCtrlInfo;
begin
  result:=0;
  if IsFileDeleted(idx) then exit;

  p:=PRGCtrlInfo(Files[idx]);
  if p^.action in [act_data, act_file] then
  begin
    result:=GetUpdate(idx,buf);
  end
  else
  begin
//    if PManFileInfo(FPAK.Man.Files[p^.source])^.ftype=typeDirectory then exit;
//    if IsDir(idx) then exit;
    if p^.ftype=typeDirectory then exit;
    // theoretically, must use "source"m not "idx" index
//    result:=FPAK.UnpackFile(PathOfFile(idx),p^.name,buf);
    result:=FPAK.UnpackFile(FPAK.Man.PathOfFile(p^.source),p^.name,buf);
  end;
end;

function TRGController.GetAsIs(idx:integer; var buf:PByte):dword;
var
  p:PRGCtrlInfo;
begin
  result:=GetContent(idx,buf);

  if result>0 then
  begin
    p:=PRGCtrlInfo(Files[idx]);
    if p^.checksum=0 then
    begin
      p^.checksum:=crc32(0,buf,result);
//      OnChange(@self,idx,faInfo); //!! fired twice after GetUpdate
    end;
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
  linfo:boolean;
begin
  result:=GetContent(idx,buf);

  if result>0 then
  begin
    p:=PRGCtrlInfo(Files[idx]);
    linfo:=false;

    if ((p^.ftype  and $FF)=typeData) and not isSource(buf) then
    begin
      if DecompileFile(buf,result,p^.name,lbuf) then
      begin
        FreeMem(buf);
        buf:=PByte(lbuf);
        result:=(Length(lbuf){+1})*SizeOf(WideChar);
        if p^.size=0 then
        begin
          linfo:=true;
          p^.size:=result;
        end;
      end;
    end;

    if p^.checksum=0 then
    begin
      linfo:=true;
      p^.checksum:=crc32(0,buf,result);
    end;

//    if linfo then OnChange(@self,idx,faInfo);
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
  linfo:boolean;
begin
  result:=GetContent(idx,buf);

  if result>0 then
  begin
    p:=PRGCtrlInfo(Files[idx]);
    linfo:=false;

    if ((p^.ftype and $FF)=typeData) and isSource(buf) then
    begin
      lbuf:=buf;
      buf:=nil;
      result:=CompileFile(lbuf,p^.Name,buf,FPAK.Version);
      FreeMem(lbuf);
    end;

    if p^.checksum=0 then
    begin
      linfo:=true;
      p^.checksum:=crc32(0,buf,result);
    end;
//    if linfo then OnChange(@self,idx,faInfo);
  end;
end;

{
  source - compile+pack
  binary - pack
}
function TRGController.GetPacked(idx:integer; var buf:PByte; var asize_u:dword):dword;
var
  p:PRGCtrlInfo;
  lbuf:PByte;
begin
  result:=0;
  if IsFileDeleted(idx) then exit;

  p:=PRGCtrlInfo(Files[idx]);
  if p^.action in [act_data, act_file] then
  begin
    asize_u:=GetUpdate(idx,buf);
    if asize_u=0 then exit;

    if RGTypeExtInfo(p^.Name,FPAK.Version)^._pack then
    begin
      if ((p^.ftype and $FF)=typeData) and isSource(buf) then
      begin
        lbuf:=buf;
        buf:=nil;
        asize_u:=CompileFile(lbuf,p^.Name,buf,FPAK.Version);
        FreeMem(lbuf);
      end;

      p^.checksum:=crc32(0,buf,asize_u);
      lbuf:=buf;
      buf:=nil;
      result:=RGFilePack(lbuf,asize_u,buf,result);
      FreeMem(lbuf);

//      OnChange(@self,idx,faInfo); //!!
    end
    else
    begin
      result:=asize_u;
    end;
  end
  else
  begin
    with PManFileInfo(FPAK.Man.Files[p^.source])^ do
    begin
//    if IsDir(idx) then exit;
      if ftype=typeDirectory then exit;
      if offset=0 then
      begin
        RGLog.Add('Next file have offset=0');
        RGLog.AddWide(p^.Name);
        exit;
      end;
    end;

    result:=FPAK.ExtractFile(FPAK.Man.PathOfFile(p^.source),p^.name,asize_u,buf);
//    result:=FPAK.ExtractFile(PathOfFile(idx),p^.name,asize_u,buf);
  end;
end;

{%ENDREGION GetData}

{%REGION Updater}
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

function TRGController.RemoveUpdate(aidx:integer):integer;
var
  p:PRGCtrlInfo;
begin
  if aidx>=0 then
  begin
    ClearElement(aidx);
    p:=PRGCtrlInfo(Files[aidx]);
    result:=p^.source;
    if result<0 then
    begin
      if isDir(aidx) then
        DeletePath(AsDir(aidx))
      else
        DeleteFile(aidx);
    end
    else
    begin
      p^.SameNameAs(PAK.Man.Files[result]);
      OnChange(@self,aidx,faStatus);
    end;
  end
  else
    result:=-1;
end;

procedure TRGController.MarkToRemove(idx:integer);
begin
  if idx>0 then
  begin
    ClearElement(idx);
    PRGCtrlInfo(Files[idx])^.action:=act_delete;
    OnChange(@self,idx,faStatus);
  end;
end;

function TRGController.NewDir(adir:integer; aname:PWideChar):integer;
var
  lfile:integer;
begin
  result:=SearchFile(adir,aname);
  if result<0 then
  begin
    result:=DoAddDir(adir, aname);
    lfile:=AsFile(result);
    with Files[lfile]^ do
    begin
      source:=-1;
      ftype :=typeDirectory;
      action:=act_dir;
    end;
    OnChange(@self,lfile,faAdd);
  end
  else
    result:=-result;
end;

function TRGController.NewDir(apath:PWideChar):integer;
var
  lfile:integer;
begin
  result:=SearchPath(apath);
  if result<0 then
  begin
    result:=DoAddPath(apath);
    lfile:=AsFile(result);
    with Files[lfile]^ do
    begin
      source:=-1;
      ftype :=typeDirectory;
      action:=act_dir;
    end;
    OnChange(@self,lfile,faAdd);
  end
  else
    result:=-result;
end;

function TRGController.NewDir(const apath:AnsiString):integer;
var
  pc:PWideChar;
begin
//  result:=NewDir(PUnicodeChar(UnicodeString(apath)));
  pc:=FastStrToWide(apath);
  result:=NewDir(pc);
  FreeMem(pc);
end;

function TRGController.UseData(adata:PByte; asize:cardinal; const apath:AnsiString):integer;
var
  pc:PUnicodeChar;
begin
//  result:=UseData(adata,asize,PUnicodeChar(UnicodeString(apath)));
  pc:=FastStrToWide(apath);
  result:=UseData(adata,asize,pc);
  FreeMem(pc);
end;

function TRGController.UseData(adata:PByte; asize:cardinal; apath:PWideChar):integer;
var
  lcnt:integer;
begin
  lcnt:=total;
  result:=DoAddFile(apath); // Add file without event
  ClearElement(result);
  with PRGCtrlInfo(Files[result])^ do
  begin
    if total<>lcnt then source:=-1;
    data  :=adata;
    size  :=asize;
    action:=act_data;
    ftime :=DateTimeToFileTime(Now());
    ftype :=RGTypeOfExt(apath);

//    FixSizes(result,adata,asize);
    if total<>lcnt then OnChange(@self,result,faAdd);
  end;
end;

function TRGController.AddUpdate(adata:PByte; asize:cardinal; const apath:AnsiString):integer;
var
  pc:PUnicodeChar;
begin
//  result:=AddUpdate(adata,asize,PUnicodeChar(UnicodeString(apath)));
  pc:=FastStrToWide(apath);
  result:=AddUpdate(adata,asize,pc);
  FreeMem(pc);
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

  OnChange(@self,result,faChanged); // can call twice, at add and change
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
  p^.size  :=lman^.size;
  p^.ftime :=lman^.ftime;
  p^.ftype :=RGTypeOfExt(lman^.Name);
end;

function TRGController.AddFileData(afdata:PWideChar; afname:PWideChar; acontent:boolean=false):integer;
var
  lftime,lfsize:Int64;
  lptr:PByte;
  f:file of byte;
  sr:TUnicodeSearchRec;
  lcnt:integer;
begin
  if FindFirst(afdata,faAnyFile,sr)=0 then
  begin
    lftime:=DateTimeToFileTime(sr.TimeStamp);
    lfsize:=sr.Size;
    FindClose(sr);
  end
  else
  begin
    lftime:=0;
    lfsize:=0;
  end;

  if not acontent then
  begin
    lcnt:=total;
    result:=DoAddFile(afname);
    ClearElement(result);
    with PRGCtrlInfo(Files[result])^ do
    begin
      if total<>lcnt then source:=-1;
      ftype :=RGTypeOfExt(afname);
      data  :=PByte(CopyWide(afdata));
      action:=act_file;
      ftime :=lftime;
      size  :=lfsize;
    end;
  end
  else
  begin
    system.Assign(f,afdata);
    system.Reset(f);
    if IOResult=0 then
    begin
      if lfsize=0 then
         lfsize:=FileSize(f);
      if lfsize>0 then
      begin
        GetMem(lptr,lfsize);
        BlockRead(f,lptr^,lfsize);
      end
      else
        lptr:=nil;
      system.Close(f);

      result:=UseData(lptr,lfsize,afname);
      Files[result]^.ftime :=lftime; // overwrite current time from UseData
      PRGCtrlInfo(Files[result])^.size:=lfsize;
    end
    else
      result:=SearchFile(afname);
  end;
  if (result>=0) then OnChange(@self,result,faChanged);
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
  lsize_u,lsize_c:cardinal;
//  pc:PUnicodeChar;
begin
  result:=false;

  if aver=1000 then aver:=FPAK.Version;
  apak.CreatePAK(fname,@FPAK.modinfo,aver);

  lbuf:=nil;

  for i:=0 to DirCount-1 do
  begin
//pc:=Dirs[i].name;
    if isDirDeleted(i) then continue;
    lidx:=AsFile(i);
//    if lidx<0 then continue;
    if GetUpdateState(lidx)=stateDelete then continue;

    // save empty dirs coz they are saved in parent list
//    ldir:=apak.man.AddPath(Dirs[i].name);
    ldir:=-1;

    if GetFirstFile(j,i) then
      repeat
//pc:=PRGCtrlInfo(Files[j])^.name;
        if achanges then
          if not (GetUpdateState(j) in
             [stateNew,stateChanged,stateNew+stateLink,stateChanged+stateLink]) then
            Continue;

        p:=PRGCtrlInfo(Files[j]);

        if p^.action=act_delete then continue;

        // Add dir ONLY with files/subdirs
        if ldir=-1 then ldir:=apak.man.AddPath(Dirs[i].name);

        // 1 - create MAN record
//!!        lidx:=apak.man.CloneFile(ldir,p);
        lidx:=apak.man.AddFile(ldir,p^.Name);
        lman:=PManFileInfo(apak.man.Files[lidx]);

//    if not IsDir(lidx) then exit;
        if not (lman^.ftype in [typeDirectory]) then
        begin
RGLog.Reserve('Packing '+FastWideToStr(Dirs[i].Name)+FastWideToStr(p^.Name));
          lsize_u:=p^.size;
          lsize_c:=GetPacked(j,lbuf,lsize_u);

          CopyInfo(p,lman);

//          OnChange(@self,lidx,faInfo);

          if lman^.size=0 then lman^.size:=lman^.size_u;
          lman^.offset:=apak.WritePackedFile(lbuf,lsize_u,lsize_c);
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
  Build files tree [from MEDIA folder] [from dir]
  as is, bin+src (data cmp to choose), bin, src
  adir   - current disk dir
  actrl  - our manifest
  aentry - current manifest directory
}
function CycleDir(const adir:UnicodeString; var actrl:TRGController; aentry:integer;
   aact:TRGDoubleAction; nochild:boolean):TRGDoubleAction;
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
        if (sr.Name<>'.') and (sr.Name<>'..') and (not nochild) then
        begin
          i:=actrl.NewDir(PUnicodeChar(ldir+sr.Name+'/'));
          case CycleDir(adir+sr.Name+'/', actrl, ABS(i), aact, false) of
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
//                if GetUpdateState(i)=stateNone then
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

function TRGController.ImportDir(const adst, adir:string; nochild:boolean=false):integer;
var
  ls:UnicodeString;
  ldir:integer;
begin
  result:=total;
  OnChange(@self,0,faStart);

  ls:=UnicodeString(adir);
  if not (adir[Length(adir)] in ['/','\']) then ls:=ls+'/';

  if DirCount=0 then AddPath(nil);
  ldir:=SearchPath(adst);
  if ldir<0 then ldir:=0;
  CycleDir(ls,self,ldir,da_ask,nochild);

  // new records only
  // but skip starting empty file
  if result=0 then result:=1;
  result:=total-result;

  OnChange(@self,result,faFinish);
end;

function TRGController.LinkPAK(afile:PWideChar):integer;
begin
  result:=total;
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
  result:=total-result;
end;


procedure TRGController.Delete(aidx:integer);
{
var
  lsrc:PRGManifest;
  i,lidx:integer;
}
begin
  // delete Update / Ctrl. Man record will be unref and delete at the end.
  // Pak saving must use Ctrl. Else: use commented variant
  ClearElement(aidx);
  if IsDir(aidx) then DeletePath(AsDir(aidx)) else DeleteFile(aidx);
{
  // 1
  ClearElement(aidx);
  lidx:=Files[aidx].source;
  if lidx>=0 then
  begin
    lsrc:=@PAK.Man;
    if lsrc^.IsDir(lidx) then lsrc^.DeletePath(lidx) else lsrc^.DeleteFile(lidx);
  end;
  if IsDir(aidx) then DeletePath(aidx) else DeleteFile(aidx);

  // 2
  lidx:=RemoveUpdate(aidx);
  if lidx>=0 then
  begin
    lsrc:=@PAK.Man;
    if lsrc^.IsDir(lidx) then lsrc^.DeletePath(lidx) else lsrc^.DeleteFile(lidx);
    if       IsDir(aidx) then       DeletePath(aidx) else       DeleteFile(aidx);
  end;
}
end;

end.
