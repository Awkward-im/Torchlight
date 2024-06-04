{TODO: remove total using (recalc for .Build)}
{TODO: better way to set ftype that calc on request}
{TODO: Add source file name to TManFileInfo}
unit RGMan;

interface

uses
  Classes,
  zipper,
  rgfs,
  rgglobal;


type
  PManFileInfo = ^TManFileInfo;
  TManFileInfo = object (TFileInfo)
    size_u  :dword;
    size_s  :dword;     // MAN: looks like source,not compiled, size (unusable)
    size_c  :dword;     // PAK: from TPAKFileHeader
    offset  :dword;     // MAN: PAK data block offset (??changed to "data" field)
    _ftype  :byte;      // MAN: RGFileType unified type
  private
    function GetFType:byte;
  public
    property ftype:Byte read GetFType write _ftype;
  end;
  TAManFileInfo = array of TManFileInfo;

type
  PRGManifest = ^TRGManifest;
  TRGManifest = object (TRGDirList)
  private
    FLUnpacked:integer; // largest unpacked file size
    FLPacked  :integer; // largest   packed file size
    FRoot     :PUnicodeChar;
// not used yet
//    FPath     :string;  // disk path for unpacked files

  private
    function  GetSize(idx:integer):integer;
    procedure SetRoot(apath:PUnicodeChar);

  // Main
  public
    procedure Init;
    procedure Free;

    {
      Parse Manifest from memory block addressed by aptr
    }
    function Parse(aptr:PByte; aver:integer):integer;
    {
      Build manifest for files in dir
      PNG ignored if DDS with same name presents
      .TXT .BINDAT and .BINLAYOUT are ignored if base files exists
    }
    function Build(const adir:string):integer;

    {
      Saves manifest by one part, files and dirs together
      GUTS saves files first, then dirs
    }
    function SaveToStream(ast:TStream; aver:integer):integer;
    function SaveToFile  (const afname:string; aver:integer):integer;

    function ParseZip(aunzip:TUnZipper):integer;

  // Properties statistic
  public
    Deleted:TDirEntries;

    property LargestPacked  :integer index 0 read GetSize;
    property LargestUnpacked:integer index 1 read GetSize;
    property Root:PUnicodeChar read FRoot write SetRoot; // really, is "MEDIA/" always

  end;


implementation

uses
  sysutils,

  rwmemory,

  rgstream,
  rgfile,
  rgfiletype;

{%REGION Common}
function TManFileInfo.GetFType:byte;
begin
  if _ftype=typeUnknown then _ftype:=PAKExtType(Name);
  result:=_ftype;
end;

procedure TRGManifest.SetRoot(apath:PUnicodeChar);
begin
  if CompareWide(FRoot,apath)<>0 then
  begin
    FreeMem(FRoot);
    FRoot:=CopyWide(apath);
  end;
end;

function TRGManifest.GetSize(idx:integer):integer;
var
  i:integer;
begin
       if idx=0 then result:=FLPacked
  else if idx=1 then result:=FLUnpacked
  else result:=0;

  if result=0 then
  begin
    for i:=0 to FileCount-1 do
    begin
      if not IsFileDeleted(i) then
      begin
        if PManFileInfo(Files[i])^.size_c>FLPacked   then FLPacked  :=PManFileInfo(Files[i])^.size_c;
        if PManFileInfo(Files[i])^.size_u>FLUnpacked then FLUnpacked:=PManFileInfo(Files[i])^.size_u;
      end;
    end;

         if idx=0 then result:=FLPacked
    else if idx=1 then result:=FLUnpacked;
  end;
end;

procedure TRGManifest.Init;
begin
  inherited Init(SizeOf(TManFileInfo));

  Root      :=nil;
  FLUnpacked:=0;
  FLPacked  :=0;
end;

procedure TRGManifest.Free;
begin
  FreeMem(FRoot);

  Finalize(Deleted);

  inherited Free;
end;
{%ENDREGION}

{%REGION I/O}
function TRGManifest.Parse(aptr:PByte; aver:integer):integer;
const
  bufsize = 1024;
var
  pc:PWideChar;
  lbuf:array [0..bufsize-1] of byte;
  i,j:integer;
  lcnt,lentries,lentry,lfile:integer;
begin
  result:=0;

  case aver of
    verTL2Mod,
    verTL2:begin
      i:=memReadWord(aptr);                   // 0002 version/signature
      if i>=2 then                            // 0000 - no "checksum" field??
        memReadDWord(aptr);                   // checksum?
      pc:=memReadShortString(aptr);           // root directory !!
      FreeMem(pc);
    end;

    verHob,
    verRGO,
    verRG :begin
    end;

  else
    exit;
  end;

  FileCapacity:=memReadDWord(aptr);           // total directory records
  lentries:=memReadDWord(aptr);               // entries
  DirCapacity:=lentries;
  total:=0;

  for i:=0 to lentries-1 do
  begin
    lentry:=AddPath(memReadShortStringBuf(aptr,@lbuf,bufsize));
    lcnt:=memReadDWord(aptr);
    for j:=0 to lcnt-1 do
    begin
      lfile:=AppendFile(lentry,nil);
      with PManFileInfo(Files[lfile])^ do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=PAKTypeToCommon(memReadByte(aptr),aver);
        Name    :=memReadShortStringBuf(aptr,@lbuf,bufsize);
        offset  :=memReadDWord(aptr);
        size_s  :=memReadDWord(aptr);
        if (aver=verTL2   ) or
           (aver=verTL2Mod) then
        begin
          ftime:=QWord(memReadInteger64(aptr));
        end;
      end;
    end;
  end;
  {
    TL2 Mod Manifest starts from nameless dir with MEDIA/ child
    paks starts right from MEDIA/ folder
  }
  if Dirs[0].count=0 then
  begin
    AppendFile(0,Dirs[1].Name);
  end;
  result:=total;
end;

{$PUSH}
{$I-}
function TRGManifest.SaveToStream(ast:TStream; aver:integer):integer;
var
  p:PManFileInfo;
  lpos,ltotalpos:integer;
  i,ltotal:integer;
begin
  try
    lpos:=ast.Position;

    case aver of
      verTL2Mod,
      verTL2: begin
        ast.WriteWord (2); // writing always "new" version
        ast.WriteDWord(0); // Hash (game don't check it anyway)
        ast.WriteShortString(strRootDir);
      end;

      verHob,
      verRGO,
      verRG: begin
      end;
    else
      exit(0);
    end;

    ltotalpos:=ast.Position;
    ast.WriteDWord(total); //!! maybe beter to calculate at runtime
    ast.WriteDWord(DirCount);

    ltotal:=0;
    for i:=0 to DirCount-1 do
    begin
      if not IsDirDeleted(i) then
      begin
      inc(ltotal);
        ast.WriteShortString(Dirs[i].name);
        ast.WriteDWord(Dirs[i].count);

        if GetFirstFile(p,i)<>0 then
        repeat
          inc(ltotal);
          with p^ do
          begin
            ast.WriteDWord(checksum);
            ast.WriteByte(PAKTypeToReal(ftype,aver));
            ast.WriteShortString(p^.Name);
            ast.WriteDWord(offset);
            ast.WriteDWord(size_s);
            if (aver=verTL2   ) or
               (aver=verTL2Mod) then
              ast.WriteQWord(ftime);
          end;
        until GetNextFile(p)=0;
      end;
    end;

    if ltotal>total then
    begin
      total:=ltotal;
      ast.WriteDwordAt(total,ltotalpos);
    end;

    result:=total;

  except
    result:=0;
    try
      ast.Position:=lpos;
    except
    end;
  end;
end;
{$POP}

function TRGManifest.SaveToFile(const afname:string; aver:integer):integer;
var
  lst:TMemoryStream;
begin
  result:=0;

  lst:=TMemoryStream.Create;
  try
    result:=SaveToStream(lst,aver);
    if result>0 then
      lst.SaveToFile(afname);
  finally
    lst.Free;
  end;
end;

function CheckFName(const adir,aname:UnicodeString):UnicodeString;
var
  lext:array [0..15] of UnicodeChar;
  lname:UnicodeString;
  lextpos,j,k:integer;
begin
  result:='';
  
  lextpos:=Length(aname);
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
      lext[k]:=UpCase(aname[j]);
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
  if PAKExtType(lname)<>typeUnknown then
    result:=lname;
end;

{
  Build files tree [from MEDIA folder] [from dir]
  excluding PNG if DDS presents
  [excluding data sources]
  as is, bin+src (data cmp to choose), bin, src
}
procedure CycleDir(const abasedir:UnicodeString; var aman:TRGManifest; aentry:integer);
var
  sr:TUnicodeSearchRec;
  lcurdir,ldir,lname:UnicodeString;
  i,lstart,lend:integer;
begin
  ldir:=aman.Dirs[aentry].name;
  lcurdir:=abasedir+ldir;

  if FindFirst(lcurdir+'*.*',faAnyFile and faDirectory,sr)=0 then
  begin

    lstart:=aman.DirCount;

    repeat
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          lname:=sr.Name+'/';
//          for j:=1 to Length(lname)-1 do lname[j]:=UpCase(lname[j]);
//          aman.AppendDir(PUnicodeChar(ldir+lname));
          aman.AddPath(PUnicodeChar(ldir+lname));
          with PManFileInfo(aman.Files[aman.AddFile(aentry,PUnicodeChar(lname))])^ do
            ftype:=typeDirectory;
        end;
      end
      else
      begin
        lname:=CheckFName(abasedir+ldir,sr.Name);
        if lname<>'' then
        begin
//          for j:=1 to Length(lname) do lname[j]:=UpCase(lname[j]);
          with PManFileInfo(aman.Files[aman.AddFile(aentry,PUnicodeChar(lname))])^ do
          begin
            ftype :=PAKExtType(lname);
            ftime :=sr.Time;
            size_s:=sr.Size;
            //!!
            if aman.FLUnpacked<sr.Size then aman.FLUnpacked:=sr.Size;
          end;
        end;
      end;
    until FindNext(sr)<>0;

    FindClose(sr);
    lend:=aman.DirCount;

    for i:=lstart to lend-1 do
    begin
      CycleDir(abasedir,aman,i);
    end;  

  end;
end;

function TRGManifest.Build(const adir:string):integer;
var
  ls:UnicodeString;
begin
  result:=0;

  ls:=UnicodeString(adir);
  if not (adir[Length(adir)] in ['/','\']) then ls:=ls+'/';

  Init;

  AddPath(nil);
  CycleDir(ls,self,0);

  result:=total;
end;
{%ENDREGION}

function TRGManifest.ParseZip(aunzip:TUnZipper):integer;
var
  lentry:TFullZipFileEntry;
  lext,lname:string;
//  lroot:array [0..63] of WideChar;
  lrootlen:integer;
  pc:PUnicodeChar;
  i,j,lfile:integer;
begin
  // 1 - extract root
  lname:=aunzip.Entries[0].ArchiveFileName;
  lrootlen:=Length(FRoot);
{
  if lname<>'' then
  begin
    lrootlen:=1;
    while not (lname[lrootlen] in ['/',#0]) do
    begin
      lroot[lrootlen-1]:=UnicodeChar(ORD(UpCase(lname[lrootlen])));
      inc(lrootlen);
    end;
    lroot[lrootlen-1]:='/';
    lroot[lrootlen]:=#0;
    Root:=@lroot;
  end;
}
  //!!!NEED to remove parent mod folder (maybe other than MEDIA/ too)
  result:=aunzip.Entries.Count;
  for i:=0 to result-1 do
  begin
    lentry:=aunzip.Entries[i];
//    if lentry.IsDirectory then
//      AddPath(ExtractFilePath(lentry.ArchiveFileName));
//    else
    begin
      lname:=UpCase(lentry.ArchiveFileName);
      // skip compiled files
      if IsExtFile(lname) then
      begin
        for j:=0 to result-1 do
        begin
          if lname=UpCase(aunzip.Entries[j].ArchiveFileName) then
          begin
            lname:='';
            break;
          end;
        end;
        if lname='' then continue;
      end;
      lfile:=AddPath(ExtractPath(lname));
      lfile:=AddFile(lfile,pointer(UnicodeString(ExtractName(lname))));
      with PManFileInfo(Files[lfile])^ do
      begin
        checksum:=lentry.CRC32;
        if lentry.IsDirectory then
          ftype:=typeDirectory
        else
          ftype   :=PAKExtType(lname);
        offset  :=i;
        size_s  :=lentry.Size;
        size_c  :=lentry.CompressedSize;
        size_u  :=lentry.Size;
        ftime   :=DateTimeToFileTime(lentry.DateTime);
      end;
    end;
  end;
end;

end.
