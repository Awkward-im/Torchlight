{
  + Unpack all files (decode as separate task)
  + Unpack separate file[s]
  + Pack all files
  Pack separate file[s]
    Append to PAK (if new or larger)
    Add on place  (if exist and not larger)
  Reassemble PAK (no repack) = compact
  * Split   PAK to   PAK and MAN (now MOD as in  only)
  * Combine PAK from PAK and MAN (now MOD as out only)
  ??Convert combined PAK to MOD
}
unit RGPAK;

interface

uses
  classes,
  rgglobal;

//===== Container =====

const
  piNoParse   = 0; // just PAK version and MAN offset
  piParse     = 1; // TL2 MOD info, MAN content
  piFullParse = 2; // with packed/unpacked file size

function  GetPAKVersion(const fname:string):integer;
function  GetPAKInfo   (const fname:string; out ainfo:TPAKInfo; aparse:integer=piNoParse):boolean;
procedure FreePAKInfo  (var   ainfo:TPAKInfo);

// next function are for TL2 PAK part only
function  CalcPAKHash(ast:TStream; apos,asize:int64):dword;
function  CalcPAKHash(const fname:string):dword;

//===== [Un]Packing =====

function  UnpackFile(var ainfo:TPAKInfo; const afile:string; out aout:PByte):integer;
function  UnpackFile(var ainfo:TPAKInfo; const afile:string; const adir:string):boolean;
function  UnpackFile(var ainfo:TPAKInfo; apath,aname:PWideChar; out aout:PByte):integer;
function  UnpackFile(var ainfo:TPAKInfo; apath,aname:PWideChar; const adir:string):boolean;
function  UnpackAll (var ainfo:TPAKInfo; const adir:string):boolean;
procedure PackAll   (var ainfo:TPAKInfo);

type
  TPAKProgress = function(const ainfo:TPAKInfo; adir,afile:integer):integer;
var
  OnPAKProgress:TPAKProgress=nil;

//===== Manipulation =====

function PAKSplit  (const asrc:string; const adir:string=''; const afname:string=''):integer;
function PAKCombine(const asdir,aname:string; const adir:string=''):integer;

/////////////////////////////////////////////////////////

implementation

uses
  sysutils,
  paszlib,
  bufstream,
  {$IFDEF DEBUG}
  logging,
  {$ENDIF}
  rgfiletype,
  rgman,
  tl2mod;

//===== Container =====

const
  MaxSizeForMem   = 24*1024*1024;
  BufferStartSize = 64*1024;
  BufferPageSize  = 04*1024;

type
  TTL2PAKHeader = packed record
    MaxCSize:dword;     // largest packed file size in PAK
    Hash    :dword;
  end;
type
  TPAKHeader = packed record
    Version  :word;
    Reserved :dword;
    ManOffset:dword;
    MaxUSize :dword;    // largest UNpacked file size
  end;
type
  TRGOPAKHeader = packed record
    Version  :word;
    Reserved :dword;
    ManOffset:dword;
    ManSize  :dword;
    MaxUSize :dword;    // largest UNpacked file size
  end;
type
  PPAKFileHeader = ^TPAKFileHeader;
  TPAKFileHeader = packed record
    size_u:UInt32;
    size_c:UInt32;      // 0 means "no compression
  end;


function MakeFileName(const ainfo:TPAKInfo):WideString;
begin
  result:=ainfo.srcdir+ainfo.fname;
  case ainfo.ver of
    verTL2Mod: result:=result+'.MOD';
    verTL2   : result:=result+'.PAK';
    verHob   : result:=result+'.PAK';
    verRGO   : result:=result+'.PAK';
    verRG    : result:=result+'.PAK';
  end;
end;


//----- PAK/MOD -----

{$PUSH}
{$I-}
function GetBasePAKInfo(const fname:string; out ainfo:TPAKInfo):integer;
var
  buf:array [0..31] of byte;
  lhdr :TPAKHeader    absolute buf;
  lhdr2:TTL2PAKHeader absolute buf;
  lhdro:TRGOPAKHeader absolute buf;
  lmi  :TTL2ModTech   absolute buf;
  f:file of byte;
  ls:string;
begin
  FillChar(ainfo,SizeOf(ainfo),0);
//  FreePAKInfo(ainfo);
  ainfo.srcdir:=UnicodeString(ExtractFilePath(fname));
  ainfo.fname :=UnicodeString(ExtractFilenameOnly(fname));

  //--- Check by ext

  ls:=UpCase(ExtractFileExt(fname));

  if ls='.MAN' then
  begin
    ainfo.ver:=verTL2;
    exit(verTL2);
  end;

  //--- Get data

  Assign(f,fname);
  Reset(f);

  if IOResult<>0 then exit(verUnk);

  //--- Check by data

  ainfo.fsize:=FileSize(f);

  buf[0]:=0;
  BlockRead(f,buf,SizeOf(buf));
  Close(f);

  // check PAK version
  if lhdr.Reserved=0 then
  begin
    if      lhdr.Version=1 then ainfo.ver:=verRG
    else if lhdr.Version=5 then
    begin
      if lhdro.ManSize=(ainfo.fsize-lhdro.ManOffset) then
        ainfo.ver:=verRGO
      else
        ainfo.ver:=verHob;
    end;

    ainfo.man:=lhdr.ManOffset;
  end
  else
  begin
    // if we have MOD header
    if ((lmi.version=4) and (lmi.gamever[0]=1)) or
       (ls='.MOD') then
    begin
      ainfo.ver :=verTL2Mod;
      ainfo.data:=lmi.offData;
      ainfo.man :=lmi.offMan;
    end
    else
    begin
      ainfo.ver:=verTL2;
    end;
  end;

  result:=ainfo.ver;
end;
{$POP}

function GetPAKVersion(const fname:string):integer;
var
  linfo:TPAKInfo;
begin
  result:=GetBasePAKInfo(fname,linfo);
  FreePAKInfo(linfo);
end;

function GetCommonPAKInfo(const fname:string; var ainfo:TPAKInfo):boolean;
var
  f:file of byte;
  ltmp:PByte;
  lsize:integer;
begin
  if ainfo.fname<>UnicodeString(fname) then
    GetBasePAKInfo(fname,ainfo);

  //--- Parse: TL2ModInfo

  if ainfo.ver=verTL2Mod then
    ReadModInfo(PChar(fname),ainfo.modinfo);

  //--- Parse: read manifest

  if (ainfo.ver=verTL2) and (Pos('.MAN',fname)<6) then
    Assign(f,fname+'.MAN')
  else
    Assign(f,fname);
  Reset(f);
  if IOResult<>0 then exit(false);
  
  lsize:=FileSize(f)-ainfo.man;
  if lsize>0 then
  begin
    GetMem(ltmp,lsize);
    Seek(f,ainfo.man);
    BlockRead(f,ltmp^,lsize);
    ParseManifest(ainfo,ltmp);
    FreeMem(ltmp);
  end;
  Close(f);

  result:=true;
end;

{$PUSH}
{$I-}
function GetPAKSizes(const fname:string; var ainfo:TPAKInfo):boolean;
var
  f:file of byte;
  lfhdr:TPAKFileHeader;
  lst:TStream;
  ltmp:PByte;
  i,j:integer;
begin
  if ainfo.fsize<=MaxSizeForMem then
  begin
    if ainfo.ver=verTL2 then
      Assign(f,fname+'.MAN')
    else
      Assign(f,fname);
    Reset(f);
    if IOResult<>0 then exit(false);

    GetMem(ltmp,ainfo.fsize);
    BlockRead(f,ltmp^,ainfo.fsize);
    Close(f);
  end
  else
  begin
    lst:=TBufferedFileStream.Create(fname,fmOpenRead);
    ltmp:=nil;
  end;

  for i:=0 to High(ainfo.Entries) do
  begin
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      with ainfo.Entries[i].Files[j] do
        if offset<>0 then
        begin
          if ltmp<>nil then
          begin
            size_u:=PPAKFileHeader(ltmp+ainfo.data+offset)^.size_u;
            size_c:=PPAKFileHeader(ltmp+ainfo.data+offset)^.size_c;
          end
          else
          begin
            lst.Seek(ainfo.data+offset,soBeginning);
            lfhdr.size_u:=0;
            lfhdr.size_c:=0;
            lst.ReadBuffer(lfhdr,SizeOf(lfhdr));
            size_u:=lfhdr.size_u;
            size_c:=lfhdr.size_c;
          end;
        end;
    end;
  end;

  if ltmp<>nil then
    FreeMem(ltmp)
  else
    lst.Free;
end;
{$POP}

{
  Parse PAK/MOD/MAN file named ainfo.fname
}
function GetPAKInfo(const fname:string; out ainfo:TPAKInfo; aparse:integer=piNoParse):boolean;
begin
  result:=GetBasePAKInfo(fname,ainfo)<>verUnk;

  if aparse=piNoParse then exit;

  result:=GetCommonPAKInfo(fname,ainfo);
  
  if (aparse=piParse) then exit;
  if (ainfo.fsize=0 ) then exit(false);

  result:=GetPAKSizes(fname,ainfo);
end;


procedure FreePAKInfo(var ainfo:TPAKInfo);
var
  i,j:integer;
begin
  FreeMem(ainfo.root);

  if Length(ainfo.Entries)>0 then
  begin
    for i:=0 to High(ainfo.Entries) do
    begin
      FreeMem(ainfo.Entries[i].name);
      for j:=0 to High(ainfo.Entries[i].Files) do
      begin
        FreeMem(ainfo.Entries[i].Files[j].name);
        FreeMem(ainfo.Entries[i].Files[j].nametxt);
      end;
      SetLength(ainfo.Entries[i].Files,0);
    end;
    SetLength(ainfo.Entries,0);
  end;

  if Length(ainfo.Deleted)>0 then
  begin
    for i:=0 to High(ainfo.Deleted) do
    begin
      FreeMem(ainfo.Deleted[i].name);
      for j:=0 to High(ainfo.Deleted[i].Files) do
      begin
        FreeMem(ainfo.Deleted[i].Files[j].name);
        FreeMem(ainfo.Entries[i].Files[j].nametxt);
      end;
      SetLength(ainfo.Deleted[i].Files,0);
    end;
    SetLength(ainfo.Deleted,0);
  end;

  ClearModInfo(ainfo.modinfo);

  ainfo.fname :='';
  ainfo.srcdir:='';
  FillChar(ainfo,SizeOf(ainfo),0);
  ainfo.ver:=verUnk;
end;

//===== Files =====


procedure GetMaxSizes(const api:TPAKInfo; out acmax,aumax:integer);
begin
  if ABS(api.ver)=verTL2 then
  begin
    aumax:=0;
    acmax:=api.maxsize;
  end
  else
  begin
    acmax:=0;
    aumax:=api.maxsize;
  end;
end;

//----- Unpack -----

function UnpackSingle(var ainfo:TPAKInfo; fi:PMANFileInfo; out aout:PByte):integer;
var
  f:file of byte;
  lfhdr:TPAKFileHeader;
  lin:PByte;
begin
  result:=0;
  aout:=nil;

  if fi<>nil then
  begin
    if fi^.size_s=0 then exit;

    Assign(f,MakeFileName(ainfo));
    Reset(f);
    if IOResult<>0 then exit;

    Seek(f,ainfo.data+fi^.offset);
    BlockRead(f,lfhdr,SizeOf(lfhdr));

    fi^.size_u:=lfhdr.size_u;
    fi^.size_c:=lfhdr.size_c;

    GetMem(aout,lfhdr.size_u);
    if lfhdr.size_c>0 then
    begin
      GetMem(lin,lfhdr.size_c);
      BlockRead(f,lin^,lfhdr.size_c);

      uncompress(
          PChar(aout),lfhdr.size_u,
          PChar(lin ),lfhdr.size_c);

      FreeMem(lin);
    end
    else
    begin
      BlockRead(f,aout^,lfhdr.size_u);
    end;

    Close(f);
    result:=lfhdr.size_u;
  end;
end;

function UnpackFile(var ainfo:TPAKInfo; const afile:string; out aout:PByte):integer;
begin
  result:=UnpackSingle(ainfo,SearchFile(ainfo,afile),aout);
end;

function UnpackFile(var ainfo:TPAKInfo; apath,aname:PWideChar; out aout:PByte):integer;
begin
  result:=UnpackSingle(ainfo,SearchFile(ainfo,apath,aname),aout);
end;

function UnpackFile(var ainfo:TPAKInfo; const afile:string; const adir:string):boolean;
var
  f:file of byte;
  ldir:string;
  lout:PByte;
  lsize:integer;
begin
  lsize:=UnpackFile(ainfo, afile, lout);
  if lsize>0 then
  begin
    if adir='' then
      ldir:=ExtractFilePath(afile)
    else
      ldir:=adir;
    ForceDirectories(ldir);

    Assign(f,ldir+'\'+ExtractFileName(afile));
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,lout^,lsize);
      Close(f);
    end;
    FreeMem(lout);
  end;

  result:=lsize>0;
end;

function UnpackFile(var ainfo:TPAKInfo; apath,aname:PWideChar; const adir:string):boolean;
var
  f:file of byte;
  ldir:UnicodeString;
  lout:PByte;
  lsize:integer;
begin
  lsize:=UnpackFile(ainfo, apath, aname, lout);
  if lsize>0 then
  begin
    if adir='' then
      ldir:=apath
    else
      ldir:=UnicodeString(adir);
    ForceDirectories(ldir);

    Assign(f,ldir+'\'+aname);
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,lout^,lsize);
      Close(f);
    end;
    FreeMem(lout);
  end;

  result:=lsize>0;
end;

{$PUSH}
{$I-}
//!! filter needs
function UnpackAll(var ainfo:TPAKInfo; const adir:string):boolean;
var
  f:file of byte;
  lname,ldir,lcurdir:WideString;
  lfhdr:TPAKFileHeader;
  lst:TBufferedFileStream;
  buf,lptr,lin,lout:PByte;
  lcsize,lusize,i,j:integer;
  lres:integer;
begin

  //--- Prepare source file

  lname:=MakeFileName(ainfo);

  if Length(ainfo.Entries)=0 then
    GetCommonPAKInfo(string(lname),ainfo);

  if ainfo.fsize<=MaxSizeForMem then
  begin
    lst:=nil;

    Assign(f,lname);
    Reset(f);
    if IOResult<>0 then exit(false);

    GetMem   (  buf ,ainfo.fsize);
    BlockRead(f,buf^,ainfo.fsize);

    Close(f);
  end
  else
  begin
    try
      lst:=TBufferedFileStream.Create(PWideChar(lname),fmOpenRead);
    except
      exit(false);
    end;
    buf:=nil;
  end;

  //--- Analize MAN part

  if Length(ainfo.Entries)=0 then
  begin
  end;

  //--- Creating destination dir

  if adir<>'' then
  begin
    ainfo.srcdir:=UnicodeString(adir+'/'); //??
    ldir:=ainfo.srcdir;{WideString(adir)+'\'}
  end
  else
    ldir:='';

  ForceDirectories{CreateDir}(ldir+'MEDIA'); //!! ainfo.root

  //--- Unpacking

  lcsize:=0;
  lusize:=0;
  lout:=nil;
  lin :=nil;

  lres:=0;
  for i:=0 to High(ainfo.Entries) do
  begin
    //!! dir filter here
    if OnPAKProgress<>nil then
    begin
      lres:=OnPAKProgress(ainfo,i,-1);
      if lres<>0 then break;
    end;

    lcurdir:=ldir+WideString(ainfo.Entries[i].name);
    if lcurdir<>'' then
      ForceDirectories(lcurdir);
    for j:=0 to High(ainfo.Entries[i].Files) do
    begin

      with ainfo.Entries[i].Files[j] do
      begin
        if (offset>0) and (size_s>0) then
        begin
          //!! file fileter here
          if OnPAKProgress<>nil then
          begin
            lres:=OnPAKProgress(ainfo,i,j);
            if lres<>0 then break;
          end;

          // Memory
          if buf<>nil then
          begin
            lptr:=buf+ainfo.data+offset;
            lfhdr.size_u:=PPAKFileHeader(lptr)^.size_u;
            lfhdr.size_c:=PPAKFileHeader(lptr)^.size_c;
            inc(lptr,SizeOf(TPAKFileHeader));

            if lfhdr.size_c>0 then
            begin
              if lusize<lfhdr.size_u then
              begin
                lusize:=Align(lfhdr.size_u,BufferPageSize);
                if lusize<BufferStartSize then lusize:=BufferStartSize;
                ReallocMem(lout,lusize);
              end;
              uncompress(
                  PChar(lout),lfhdr.size_u,
                  PChar(lptr),lfhdr.size_c);
              lptr:=lout;
            end;
          end
          // File
          else
          begin
            lst.Seek(ainfo.data+offset,soBeginning);
            lst.ReadBuffer(lfhdr,SizeOf(lfhdr));

            if lusize<lfhdr.size_u then
            begin
              lusize:=Align(lfhdr.size_u,BufferPageSize);
              if lusize<BufferStartSize then lusize:=BufferStartSize;
              ReallocMem(lout,lusize);
            end;
            lptr:=lout;

            if lfhdr.size_c=0 then
            begin
              lst.ReadBuffer(lout^,lfhdr.size_u);
            end
            else
            begin
              if lcsize<lfhdr.size_c then
              begin
                lcsize:=Align(lfhdr.size_c,BufferPageSize);
                if lcsize<BufferStartSize then lcsize:=BufferStartSize;
                ReallocMem(lin,lcsize);
              end;
              lst.Readbuffer(lin^,lfhdr.size_c);
              uncompress(
                  PChar(lout),lfhdr.size_u,
                  PChar(lin ),lfhdr.size_c);
            end;
          end;

          //!!
          Assign (f,lcurdir+WideString(ainfo.Entries[i].Files[j].name));
          Rewrite(f);
          if IOResult=0 then
          begin
            BlockWrite(f,lptr^,lfhdr.size_u);
            Close(f);
          end;
        end
        //!! size/offset = 0 means "delete file"
        else
        begin
          if OnPAKProgress<>nil then
          begin
            lres:=OnPAKProgress(ainfo,-i,-j);
            if lres<>0 then break;
          end;

          //!! if type = 'delete dir' then remove dir
        end;
      end;

    end;
    if lres<>0 then break;
  end;
  if lout<>nil then FreeMem(lout);
  if lin <>nil then FreeMem(lin);

  if lst<>nil then lst.Free
  else FreeMem(buf);

  result:=true;
end;
{$POP}

//--- TL2 version only

{$PUSH}
{$Q-,R-}
function CalcPAKHash(ast:TStream; apos,asize:int64):dword;
var
  lpos,hash:Int64;
  seed:QWord;
  lofs:qword;
  step:integer;
  lbyte:byte;
begin
  lpos:=ast.Position;

  seed:=(asize shr 32)+(asize and $FFFFFFFF)*$29777B41;
  seed:=25+((seed and $FFFFFFFF) mod 51);
  if seed>75 then seed:=75;

  step:=asize div seed;
  if step<2 then step:=2;
  hash:=asize;

  lofs:=apos+8;
  while lofs<(apos+asize) do
  begin
    ast.Position:=lofs;
    lbyte:=ast.ReadByte();
    hash:=((hash*33)+shortint(lbyte)) and $FFFFFFFF;
    lofs:=lofs+step;
  end;
  ast.Position:=apos+asize-1;
  lbyte:=ast.ReadByte();

  result:=dword(((hash*33)+shortint(lbyte)) and $FFFFFFFF);

  ast.Position:=lpos;
end;
{$POP}

function CalcPAKHash(const fname:string):dword;
var
  lpi:TPAKInfo;
  lsize:int64;
  lst:TStream;
begin
  result:=dword(-1);

  if (not GeTPAKInfo(fname, lpi, piNoParse)) or
     (ABS(lpi.ver)<>verTL2) then
    exit;

  if lpi.ver=verTL2 then
    lsize:=lpi.fsize
  else
    lsize:=lpi.man-lpi.data;

  if lpi.fsize<=MaxSizeForMem then
  begin
    lst:=TMemoryStream.Create;
    try
      TMemoryStream(lst).LoadFromFile(fname);
      result:=CalcPAKHash(lst,lpi.data,lsize);
    finally
      lst.Free;
    end;
  end
  else
  begin
    try
      lst:=TBufferedFileStream.Create(fname,fmOpenRead);
      try
        result:=CalcPAKHash(lst,lpi.data,lsize);
      finally
        lst.Free;
      end;
    except
      exit;
    end;
  end;

end;

//----- Pack -----

{$PUSH}
{$I-}
procedure PackAll(var ainfo:TPAKInfo);
var
  f:file of byte;
  spak:TFileStream;
  TL2PAKHeader:TTL2PAKHeader; //??
  RGOPAKHeader:TRGOPAKHeader; //??
  PAKHeader:TPAKHeader;       //??
  lmodinfo:TTL2ModTech;
  fi:PMANFileInfo;
  lout,lin:PByte;
  ldir:PWideChar;
  lname:PWideChar;
  lsname:string;
  lManPos,lPakPos,lisize,losize:longword;
  largest_u,largest_c:integer;
  i,j,lres:integer;
begin
  //--- Initialization

  GetMaxSizes(ainfo,largest_c,largest_u);
  if largest_u>0 then
  begin
    lisize:=Align(largest_u,BufferPageSize);
    losize:=Round(lisize*1.2)+12;
    GetMem(lin ,lisize);
    GetMem(lout,losize);
  end
  else
  begin
    lisize:=0;
    lin   :=nil;
    lout  :=nil;
  end;

  //--- Write MOD

  lsname:=String(ainfo.srcdir+ainfo.fname);
  if ainfo.ver=verTL2Mod then
  begin
    lPakPos:=WriteModInfo(PChar(lsname+'.MOD'),ainfo.modinfo);
    spak:=TFileStream.Create(lsname+'.MOD',fmOpenReadWrite); //!! backup old??
    spak.Position:=lPakPos;
  end
  //--- Write PAK
  else
  begin  
    lPakPos:=0;
    spak:=TFileStream.Create(lsname+'.PAK',fmCreate); //!! backup old??
  end;

  // Just reserve place
  case ABS(ainfo.ver) of
    verTL2: spak.Write(TL2PAKHeader,SizeOf(TTL2PAKHeader));
    verRGO: spak.Write(RGOPAKHeader,SizeOf(TRGOPAKHeader));
  else      spak.Write(PAKHeader   ,SizeOf(TPAKHeader));
  end;

  for i:=0 to High(ainfo.Entries) do
  begin
    ldir:=ConcatWide(PWideChar(ainfo.srcdir),ainfo.Entries[i].name);

    for j:=0 to High(ainfo.Entries[i].Files) do
    begin
      fi:=@(ainfo.Entries[i].Files[j]);
      if (fi^.ftype in [typeDirectory,typeDelete]) or
         (fi^.size_s = 0) then
      begin
        if OnPAKProgress<>nil then
        begin
          lres:=OnPAKProgress(ainfo,-i,-j);
          if lres<>0 then break;
        end;
        continue;
      end;

      if OnPAKProgress<>nil then
      begin
        lres:=OnPAKProgress(ainfo,i,j);
        if lres<>0 then break;
      end;
      
      fi^.offset:=spak.Position;

      //--- Read file into memory

      lname:=ConcatWide(ldir,fi^.name);
      Assign(f,lname);
      FreeMem(lname);
      Reset(f);

      fi^.size_u:=FileSize(f);
      if lisize<fi^.size_u then
      begin
        lisize:=Align(fi^.size_u,BufferPageSize);
        losize:=Round(lisize*1.2)+12;
        ReallocMem(lin ,lisize);
        ReallocMem(lout,losize);
      end;
      BlockRead(f,lin^,fi^.size_u);
      Close(f);

      //--- Process

      fi^.checksum:=crc32(0,PChar(lin),fi^.size_u);

      spak.WriteData(fi^.size_u,4);
      // write uncompressed
      if largest_u<fi^.size_u then largest_u:=fi^.size_u;
      if not GetExtInfo(fi^.name,ainfo.ver)^._pack then
      begin
        spak.WriteData(0,4);
        spak.WriteData(lin,fi^.size_u);
      end
      else
      begin
        fi^.size_c:=losize;
        if compress(PChar(lout),fi^.size_c,PChar(lin),fi^.size_u)<>Z_OK then //!!!
        begin
          if OnPAKProgress<>nil then
          begin
            lres:=OnPAKProgress(ainfo,-i,-j);
            if lres<>0 then break;
          end;
        end;
        
        if largest_c<fi^.size_c then largest_c:=fi^.size_c;

        spak.WriteData(fi^.size_c,4);
        spak.WriteData(lout,fi^.size_c);
      end;
    end;
    FreeMem(ldir);
  end;

  //--- Write MAN

  lManPos:=spak.Size;

  if ainfo.ver=verTL2 then
    WriteManifest(ainfo)
  else
  begin
    if ainfo.ver=verTL2Mod then
    begin
      move(ainfo.modinfo,lmodinfo,SizeOf(TTL2ModTech));
      QWord(lmodinfo.gamever):=ReverseWords(ainfo.modinfo.gamever);
      lmodinfo.version:=4;
      lmodinfo.modver :=ainfo.modinfo.modver;
      lmodinfo.offData:=lPakPos;
      lmodinfo.offMan :=spak.Size;

      spak.Position:=0;
      spak.Write(lmodinfo,SizeOf(lmodinfo));
    end;
    spak.Position:=spak.Size;
    ManSaveToStream(spak,ainfo);
  end;

  //--- Change PAK Header
  
  spak.Position:=lPakPos;

  case ABS(ainfo.ver) of
    verTL2: begin
      TL2PAKHeader.MaxCSize:=largest_c;
      TL2PAKHeader.Hash    :=CalcPAKHash(spak,lPakPos,lManPos-lPakPos);
      spak.Write(TL2PAKHeader,SizeOf(TTL2PAKHeader))
    end;
    verRGO: begin
      RGOPAKHeader.Version  :=5;
      RGOPAKHeader.Reserved :=0;
      RGOPAKHeader.ManOffset:=lManPos;
      RGOPAKHeader.ManSize  :=spak.Size-lManPos;
      RGOPAKHeader.MaxUSize :=largest_u;
      spak.Write(RGOPAKHeader,SizeOf(TRGOPAKHeader));
    end;
  else
    if      ABS(ainfo.ver)=verHob then PAKHeader.Version:=5
    else if ABS(ainfo.ver)=verRG  then PAKHeader.Version:=1;
    PAKHeader.Reserved :=0;
    PAKHeader.ManOffset:=lManPos;
    PAKHeader.MaxUSize :=largest_u;
    spak.Write(PAKHeader,SizeOf(TPAKHeader));
  end;

  spak.Free;
end;
{$POP}

{TODO: pack separate file}
procedure PackFile(var ainfo:TPAKInfo;
    apath,aname:PWideChar;
    abuf:PByte; asize:integer);
var
  mi:PMANFileInfo;
begin
  // just add to MAN or remove from pack or modify MAN
  if (asize=0) or (abuf=nil) then ;

  mi:=SearchFile(ainfo,apath,aname);
  if mi<>nil then
  begin
    // Compile if needs
    // Pack file
{
  TMANFileInfo = record // not real field order
    ftime   :UInt64;    // TL2 only
    name    :PWideChar; // name in MAN
    nametxt :PWideChar; // source (text format) name
    checksum:dword;     // CRC32
    size_s  :dword;     // looks like source,not compiled, size (unusable)
    size_c  :dword;     // from TPAKFileHeader
    size_u  :dword;     // from TPAKFileHeader
    offset  :dword;
    ftype   :byte;
  end;

1 - source file
2 - packed data
3 - packed size
4 - unpacked size
5 - PAK position
6 - MAN position
      
    function CompressFile(fname:PWideChar; out abuf:PByte; out psize:integer; aver:integer=verTL2):integer;
    var
      f:file of byte;
      lbuf:PByte;
    begin
      result:=0;
      Assign(f,fname);
      Reset(f);
      if IOResult=0 then
      begin
        result:=FileSize(f);
        GetMem(lbuf,result);
        BlockRead(f,lbuf^,result);
      
        if not GetExtInfo(fname,aver)^._pack then
        begin
          abuf:=lbuf;
          psize:=result;
        end
        else
        begin
          psize:=Round(Align(result,BufferPageSize)*1.2)+12;
          GetMem(abuf,psize);
          
          if compress(abuf,psize,lbuf,result)<>Z_OK then
          begin
            if OnPAKProgress<>nil then
            begin
              lres:=OnPAKProgress(ainfo,-i,-j);
              if lres<>0 then break;
            end;
          end;
        end;
        Close(f);
      end;
    end;
}
    // replace in PAK if not greater than existing
    // or add to the end
  end
  else
  begin
    // Add to MAN, add to the end of PAK
    mi:=rgman.AddFile(ainfo,apath,aname);
  end;
end;

//----- something -----
{$IFDEF DEBUG}
function DoProgress(const ainfo:TPAKInfo; adir,afile:integer):integer;
begin
  result:=0;

  if afile>=0 then
    RGLog.Add('Processing file '+
      WideToStr(ainfo.Entries[adir].name)+
      WideToStr(ainfo.Entries[adir].Files[afile].name))
  else if adir>=0 then
    RGLog.Add('Processing dir '+WideToStr(ainfo.Entries[adir].name))
  else
    RGLog.Add('Skipping dummy '+
      WideToStr(ainfo.Entries[-adir].name)+
      WideToStr(ainfo.Entries[-adir].Files[-afile].name));

end;
{$ENDIF}

//===== Manipulation =====

function PAKSplit(const asrc:string; const adir:string=''; const afname:string=''):integer;
var
  ffin,ffout: file of byte;
  mi:TTL2ModInfo;
  lfname:string;
  ltmp:pbyte;
  lsize,fsize:integer;
begin
  result:=-1;

  // .MOD files only
  if (Length(asrc)>4) and
     (Pos('.MOD',UpCase(asrc))=(Length(asrc)-3)) then
  begin
    if ReadModInfo(PChar(asrc),mi) then
    begin
      if adir='' then
        lfname:=ExtractFilePath(asrc)
      else
      begin
        lfname:=adir;
        if not (lfname[Length(lfname)] in ['\','/']) then lfname:=lfname+'\';
      end;
      if lfname<>'' then ForceDirectories(lfname);
      if afname='' then
        lfname:=lfname+ExtractFileNameOnly(asrc)
      else
        lfname:=lfname+afname;

{
      fin:=TFileStream.Create(asrc,fmOpenRead);
}
      AssignFile(ffin,asrc);
      Reset(ffin);
      fsize:=FileSize(ffin);

      // PAK file
{
      fout:=TFileStream.Create(lfname+'.PAK',fmCreate);
      fin.Position:=mi.offData;
      fout.CopyFrom(fin,mi.offMan-mi.offData);
      fout.Free;
}
      AssignFile(ffout,lfname+'.PAK');
      Rewrite(ffout);
      Seek(ffin,mi.offData);
      lsize:=mi.offMan-mi.offData;
      GetMem    (      ltmp ,lsize);
      BlockRead (ffin ,ltmp^,lsize);
      BlockWrite(ffout,ltmp^,lsize);
      CloseFile(ffout);

      // MAN file
{
      fout:=TFileStream.Create(lfname+'.PAK.MAN',fmCreate);
      fin.Position:=mi.offMan;
      fout.CopyFrom(fin,fin.Size-mi.offMan);
      fout.Free;
}
      AssignFile(ffout,lfname+'.PAK.MAN');
      Rewrite(ffout);
      Seek(ffin,mi.offMan);
      fsize:=fsize-mi.offMan;
      if fsize>lsize then
        ReallocMem(ltmp,fsize);
      BlockRead (ffin ,ltmp^,fsize);
      BlockWrite(ffout,ltmp^,fsize);
      FreeMem(ltmp);
      CloseFile(ffout);

{
      fin.Free;
}
      CloseFile(ffin);

      // DAT file
      SaveModConfiguration(mi,PChar(lfname+'.DAT'));

      result:=0;
    end;
    ClearModInfo(mi);
  end;
end;

function PAKCombine(const asdir,aname:string; const adir:string=''):integer;
var
  mi:TTL2ModInfo;
  buf:PByte;
  fin,fout:TFileStream;
  lname,ldir:string;
  lsize:integer;
begin
  result:=-1;

  ldir:=asdir;
  if ldir<>'' then
    if not (ldir[Length(ldir)] in ['\','/']) then ldir:=ldir+'\';
  lname:=ldir+aname;

  if FileExists(lname+'.PAK') and
     FileExists(lname+'.PAK.MAN') then
  begin
    if      FileExists(lname+'.DAT'  ) then LoadModConfiguration(PChar(lname+'.DAT'),mi)
    else if FileExists(ldir+'MOD.DAT') then LoadModConfiguration(PChar(ldir+'MOD.DAT'),mi)
    else
    begin
      MakeModInfo(mi);
      mi.title:=StrToWide(aname);
    end;
    GetMem(buf,32767);
    lsize:=WriteModInfoBuf(buf,mi);
    ClearModInfo(mi);
    if adir <>'' then
    begin
      ldir:=adir;
      if not (ldir[Length(ldir)] in ['\','/']) then ldir:=ldir+'\';
    end;
    if ldir<>'' then ForceDirectories(ldir);
    fout:=TFileStream.Create(ldir+aname+'.MOD',fmCreate);

    fin:=TFileStream.Create(lname+'.PAK',fmOpenRead);

    PTL2ModTech(buf)^.offData:=lsize;
    PTL2ModTech(buf)^.offMan :=lsize+fin.Size;
    fout.WriteData(buf,lsize);
    FreeMem(buf);

    fout.CopyFrom(fin,fin.Size);
    fin.Free;

    fin:=TFileStream.Create(lname+'.PAK.MAN',fmOpenRead);
    fout.CopyFrom(fin,fin.Size);
    fin.Free;

    fout.Free;
  end;
end;

initialization
{$IFDEF DEBUG}
  OnPAKProgress:=@DoProgress;
{$ELSE}
  OnPAKProgress:=nil;
{$ENDIF}
end.
