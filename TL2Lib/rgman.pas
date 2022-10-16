{TODO: save compiled manifest size}
{TODO: calculate largest file size on parse and add. Or just on build?}
unit RGMan;

interface

uses
  Classes,
  TextCache,
  rgglobal;


type
  PMANFileInfo = ^TMANFileInfo;
  TMANFileInfo = record // not real field order
    ftime   :UInt64;    // MAN: TL2 only
{
    memadr  :PByte;     // file memory placement address
}
    name    :cardinal;  // !! MAN: TextCache index
//    nametxt :PUnicodeChar; // source (text format) name
    checksum:dword;     // MAN: CRC32
    size_s  :dword;     // ?? MAN: looks like source,not compiled, size (unusable)
    size_c  :dword;     // !! PAK: from TPAKFileHeader
    size_u  :dword;     // !! PAK: from TPAKFileHeader
    offset  :dword;     // !! MAN: PAK data block offset
    next    :integer;
    ftype   :byte;      // !! MAN: RGFileType unified type
  end;
  TMANFileInfos = array of TMANFileInfo;

type
  PMANDirEntry = ^TMANDirEntry;
  TMANDirEntry = record
    name:cardinal;      // TextCache index
    count,
    first,
    last:integer;
  end;
  TMANDirEntries = array of TMANDirEntry;

type
  PRGManifest = ^TRGManifest;
  TRGManifest = object
public
//  private
    cntEntry  :integer; // total count of Entries
    cntFiles  :integer; // total count of file records
    FLUnpacked:integer; // largest unpacked file size
    FLPacked  :integer; // largest   packed file size
  public
    Entries:TMANDirEntries;
    Deleted:TMANDirEntries;
    Files  :TMANFileInfos;
    Names  :TTextCache;
  public
    // not necessary fields
    root   :PUnicodeChar;   // same as first directory, MEDIA (usually)
    total  :integer;        // total "file" elements. Can be calculated when needs
    reserve:integer;        // "total" records count (GUTS gives more than put)
    largest:integer;        // largest source file size
  private
    function  SetName(aname:PUnicodeChar):integer;
    function  GetFilesCapacity():integer;
    procedure SetFilesCapacity(acnt:cardinal);
    function  GetEntriesCapacity():integer;
    procedure SetEntriesCapacity(acnt:cardinal);
    function  GetSize(idx:integer):integer;

    function AddEntryFile(aentry:integer; aname:PUnicodeChar=nil):PManFileInfo;
    function AddEntry (const apath:PUnicodeChar=pointer(-1)):integer;
    function DoAddPath(const apath:UnicodeString):integer;
  public
    procedure Init;
    procedure Free;

    function Parse(aptr:PByte; aver:integer):integer;
    function Build(const adir:string):integer;

    function SaveToStream(ast:TStream; aver:integer):integer;
    function SaveToFile  (const afname:string; aver:integer):integer;

    function SearchEntry(apath:PUnicodeChar):integer;
    function SearchFile(aentry:integer; aname:PUnicodeChar):PMANFileInfo;
    function SearchFile(apath,aname:PUnicodeChar):PMANFileInfo;
    function SearchFile(const fname:string):PMANFileInfo;

    function AddPath(apath:PUnicodeChar):integer;
    function AddPath(const apath:string):integer;

    function AddFile(apath,aname:PUnicodeChar):PMANFileInfo;

    function GetName     (idx:integer):PUnicodeChar;
    function GetEntryName(idx:integer):PUnicodeChar;

    // result=0 means "end"
    function GetFirstFile(out p:PMANFileInfo; aentry:integer):integer;
    function GetNextFile (var p:PMANFileInfo):integer;

  public
    property EntriesCount:integer read cntEntry;
    property FilesCount  :integer read cntFiles;
    property LargestPacked  :integer index 0 read GetSize;
    property LargestUnpacked:integer index 1 read GetSize;
//    property Entries  [idx:integer]:PMANDirEntry read GetEntry;
    property EntryName[idx:integer]:PUnicodeChar read GetEntryName;
//    property FileName[p:PMANFileInfo]:PUnicodeChar read GetFileName;
//    property Files   [aentry:integer; idx:integer]:PMANFileInfo read GetEntryFile;
//    property FileName[aentry:integer; idx:integer]:PunicodeChar read GetFileName;
  end;


{$IFDEF DEBUG}
//  Manifest to text file (DAT format)
procedure MANtoFile(const fname:string; const aman:TRGManifest; afull:boolean=false);
//  Text file (DAT format) to manifest
procedure FileToMAN(const fname:string; out aman:TRGManifest);
{$ENDIF DEBUG}


implementation

uses
  sysutils,

  rwmemory,

{$IFDEF DEBUG}
  rgnode,
  rgio.text,
{$ENDIF DEBUG}
  rgstream,
  rgfiletype;

const
  incEBase = 512;
  incEntry = 256;
  incFBase = 128;
  incFFile = 16;


function TRGManifest.SetName(aname:PUnicodeChar):integer; inline;
begin
  result:=names.Append(aname);
end;

function TRGManifest.GetName(idx:integer):PUnicodeChar; inline;
begin
  result:=PUnicodeChar(names[idx]);
end;

function TRGManifest.GetEntryName(idx:integer):PUnicodeChar;
begin
  if (idx>0) and (idx<cntEntry) then
    result:=GetName(Entries[idx].name)
  else
    result:=nil;
end;

function TRGManifest.GetFilesCapacity():integer; inline;
begin
  result:=Length(Files);
end;

procedure TRGManifest.SetFilesCapacity(acnt:cardinal);
begin
  if acnt>Length(Files) then
    SetLength(Files,acnt);
end;

function TRGManifest.GetEntriesCapacity():integer; inline;
begin
  result:=Length(Entries);
end;

procedure TRGManifest.SetEntriesCapacity(acnt:cardinal);
begin
  if acnt>Length(Entries) then
    SetLength(Entries,acnt);
end;

function TRGManifest.GetFirstFile(out p:PMANFileInfo; aentry:integer):integer;
begin
  result:=Entries[aentry].first;
  if result<>0 then p:=@Files[result];
end;

function TRGManifest.GetNextFile(var p:PMANFileInfo):integer;
begin
  result:=p^.next;
  if result<>0 then p:=@Files[result];
end;

function TRGManifest.GetSize(idx:integer):integer;
var
  i:integer;
begin
       if idx=0 then result:=FLPacked
  else if idx=1 then result:=FLUnpacked;

  if result=0 then
  begin
    for i:=0 to cntFiles-1 do
    begin
      if Files[i].size_c>FLPacked   then FLPacked  :=Files[i].size_c;
      if Files[i].size_u>FLUnpacked then FLUnpacked:=Files[i].size_u;
    end;

         if idx=0 then result:=FLPacked
    else if idx=1 then result:=FLUnpacked;
  end;
end;

procedure TRGManifest.Init;
begin
  FillChar(self,SizeOf(self),0);
{
  cntEntry:=0;
  cntFiles:=0;

  Initialize(Entries);
  Initialize(Deleted);
  Initialize(Files);
//  FillChar(aman,SizeOf(aman),0); //!!
}
  names.Init(false);
end;

procedure TRGManifest.Free;
begin
  FreeMem(root);

  names.Clear;
  Finalize(Entries);
  Finalize(Deleted);
  Finalize(Files);
end;

//----- Search -----

function TRGManifest.SearchEntry(apath:PUnicodeChar):integer;
var
  i:integer;
begin
  for i:=0 to cntEntry-1 do
  begin
    if CompareWide(GetEntryName(i),apath)=0 then
      exit(i);
  end;

  result:=-1;
end;

function TRGManifest.SearchFile(aentry:integer; aname:PUnicodeChar):PMANFileInfo;
begin
  if (aentry>=0) and (aentry<cntEntry) then
  begin
    if GetFirstFile(result,aentry)<>0 then
      repeat
        if CompareWide(GetName(result^.name),aname)=0 then exit;
      until GetNextFile(result)=0;
  end;
  
  result:=nil;
end;

function TRGManifest.SearchFile(apath,aname:PUnicodeChar):PMANFileInfo;
begin
  result:=SearchFile(SearchEntry(apath),aname);
end;

function TRGManifest.SearchFile(const fname:string):PMANFileInfo;
var
  lpath,lname:UnicodeString;
begin
  lname:=UpCase(UnicodeString(fname));
  lpath:=ExtractFilePath(lname);
  lname:=ExtractFileName(lname);

  result:=SearchFile(pointer(lpath),pointer(lname));
end;

//----- Add -----

function TRGManifest.AddEntryFile(aentry:integer; aname:PUnicodeChar=nil):PManFileInfo;
var
  i:integer;
begin
  //!!
  if aentry<0 then exit(nil);
  
  // expand if needs
  if cntFiles=0 then
  begin
    SetFilesCapacity(incFBase);
    cntFiles:=1;
  end
  else if cntFiles=GetFilesCapacity() then
    SetFilesCapacity(cntFiles+incFFile);

  // links
  i:=Entries[aentry].last;
  if i>0 then
    Files[i].next:=cntFiles
  else
    Entries[aentry].first:=cntFiles;

  Entries[aentry].last:=cntFiles;
  inc(Entries[aentry].count);

  // data
  result:=@Files[cntFiles];
  FillChar(result^,SizeOf(result^),0);
  if aname<>nil then
    result^.name:=SetName(aname);

  inc(cntFiles);
  inc(total);
end;

function TRGManifest.AddEntry(const apath:PUnicodeChar=pointer(-1)):integer;
begin
  // Check for first allocation. It have empty name ALWAYS
  if Length(Entries)=0 then
    SetEntriesCapacity(incEBase);

  if cntEntry=0 then
  begin
    FillChar(Entries[0],SizeOf(Entries[0]),0); //??
    cntEntry:=1;
  end;

  if (apath=nil) or (apath^=#0) then exit(0);

  // expand if needs
  if cntEntry=GetEntriesCapacity() then
    SetEntriesCapacity(cntEntry+incEntry);

  result:=cntEntry;
  // FillChar is not needs coz auto
  FillChar(Entries[result],SizeOf(TMANDirEntry),0);

  if apath<>pointer(-1) then
    Entries[result].name:=SetName(apath);
  
  inc(cntEntry);
  inc(total);
end;

function TRGManifest.DoAddPath(const apath:UnicodeString):integer;
var
  lslash,lentry:integer;
begin
  // if exists already
  result:=SearchEntry(PUnicodeChar(apath));
  if result>=0 then exit;

  // add parent dir
  lslash:=Length(apath)-1;
  while (lslash>1) and (apath[lslash]<>'/') do dec(lslash);
  if lslash>1 then
  begin
    lentry:=DoAddPath(Copy(apath,1,lslash));

    with AddEntryFile(lentry,PUnicodeChar(apath)+lslash)^ do
      ftype:=typeDirectory;
  end;

  result:=AddEntry(PUnicodeChar(apath));
end;

function TRGManifest.AddPath(apath:PUnicodeChar):integer;
var
  ws:UnicodeString;
  i,lsize:integer;
begin
  if cntEntry=0 then
    AddEntry(nil);
  
  if (apath=nil) or (apath^=#0) then exit(0);
  
  // Upper case, no starting slashes but with ending
  ws:=UpCase(UnicodeString(apath));
  lsize:=Length(ws);
  for i:=1 to lsize do
    if ws[i]='\' then ws[i]:='/';
  i:=1;
  while ws[i]='/' do inc(i);
  dec(i);
  if i>0 then Delete(ws,1,i); dec(lsize,i);

  if ws[lsize]<>'/' then ws:=ws+'/';

  result:=DoAddPath(ws);
end;

function TRGManifest.AddPath(const apath:string):integer;
begin
  result:=AddPath(PUnicodeChar(UnicodeString(apath)))
end;

{
  Add file with relative path.
  requires root dir to get physical file info like time and size
}
function TRGManifest.AddFile(apath,aname:PUnicodeChar):PMANFileInfo;
var
  lentry:integer;
begin
  lentry:=AddPath(apath);
  if lentry<0 then exit(nil);

  result:=SearchFile(lentry,aname);
  if result<>nil then exit;

  // add record if file was not found
  result:=AddEntryFile(lentry,aname);

  with result^ do
  begin
    name :=SetName(aname);
    ftype:=PAKExtType(aname); //!! not requires at start but good for filter
  end;

end;

{
  Parse Manifest from memory block addressed by aptr
}
function TRGManifest.Parse(aptr:PByte; aver:integer):integer;
const
  bufsize = 1024;
var
  lbuf:array [0..bufsize-1] of byte;
  i,j:integer;
  lcnt,lentries,lentry:integer;
begin
  result:=0;

  case aver of
    verTL2Mod,
    verTL2:begin
      i:=memReadWord(aptr);                   // 0002 version/signature
      if i>=2 then                            // 0000 - no "checksum" field??
        memReadDWord(aptr);                   // checksum?
      root:=memReadShortString(aptr);         // root directory !!
    end;

    verHob,
    verRGO,
    verRG :begin
    end;

  else
    exit;
  end;

//  InitManifest(aman);

  reserve :=memReadDWord(aptr);               // total directory records
  lentries:=memReadDWord(aptr);               // entries
  SetEntriesCapacity(lentries);
  total:=0;

  for i:=0 to lentries-1 do
  begin
    lentry:=AddEntry(memReadShortStringBuf(aptr,@lbuf,bufsize));
    lcnt:=memReadDWord(aptr);
    for j:=0 to lcnt-1 do
    begin
      with AddEntryFile(lentry)^ do
      begin
        checksum:=memReadDWord(aptr);
        ftype   :=PAKTypeToCommon(memReadByte(aptr),aver);
        name    :=SetName(memReadShortStringBuf(aptr,@lbuf,bufsize));
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

  result:=total;
end;

{$PUSH}
{$I-}
function TRGManifest.SaveToStream(ast:TStream; aver:integer):integer;
var
  p:PMANFileInfo;
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
        ast.WriteShortString(root);
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
    ast.WriteDWord(cntEntry);

    ltotal:=0;
    for i:=0 to cntEntry-1 do
    begin
      ast.WriteShortString(GetEntryName(i));
      ast.WriteDWord(Entries[i].count);

      if GetFirstFile(p,i)<>0 then
      repeat
        inc(ltotal);
        with p^ do
        begin
          ast.WriteDWord(checksum);
          ast.WriteByte(PAKTypeToReal(ftype,aver));
          ast.WriteShortString(GetName(name));
          ast.WriteDWord(offset);
          ast.WriteDWord(size_s);
          if (aver=verTL2   ) or
             (aver=verTL2Mod) then
            ast.WriteQWord(ftime);
        end;
     until GetNextFile(p)=0;
    end;

    if ltotal>total then
    begin
      total:=ltotal;
      lpos:=ast.Position;
      try
        ast.Position:=ltotalpos;
        ast.WriteDWord(total);
        ast.Position:=lpos;
      except
      end;
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
     (CompareWide(lext,'.BINLAYOUT')=0) then
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
  j,i,lstart,lend:integer;
begin
  ldir:=aman.GetEntryName(aentry);
  lcurdir:=abasedir+ldir;

  if FindFirst(lcurdir+'*.*',faAnyFile and faDirectory,sr)=0 then
  begin

    lstart:=aman.cntEntry;

    repeat
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          lname:=sr.Name+'/';
          for j:=1 to Length(lname)-1 do lname[j]:=UpCase(lname[j]);
          aman.AddEntry(PUnicodeChar(ldir+lname));
          with aman.AddEntryFile(aentry,PUnicodeChar(lname))^ do
            ftype:=typeDirectory;
        end;
      end
      else
      begin
        lname:=CheckFName(abasedir+ldir,sr.Name);
        if lname<>'' then
        begin
          for j:=1 to Length(lname) do lname[j]:=UpCase(lname[j]);
          with aman.AddEntryFile(aentry,PUnicodeChar(lname))^ do
          begin
            ftype :=PAKExtType(lname);
            ftime :=sr.Time;
            size_s:=sr.Size;
          end;
        end;
      end;
    until FindNext(sr)<>0;

    FindClose(sr);
    lend:=aman.cntEntry;

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
  if not (ls[Length(ls)] in ['/','\']) then ls:=ls+'/';

  Init;

  AddEntry(nil);
  CycleDir(ls,self,0);

  root:=CopyWide('MEDIA/');

  result:=total;
end;

{$IFDEF DEBUG}
procedure MANtoFile(const fname:string; const aman:TRGManifest; afull:boolean=false);
var
  p:PMANFileInfo;
  lman,lp,lc:pointer;
  i:integer;
begin
  lman:=nil;

  lman:=AddGroup(nil,'MANIFEST');
//??  AddString (lman,'FILE' ,PUnicodeChar(ainfo.fname));
  if afull then
  begin
    AddInteger(lman,'TOTAL',aman.total);
    AddInteger(lman,'COUNT',Length(aman.Entries));
  end;

  for i:=0 to aman.cntEntry-1 do
  begin
    lp:=AddGroup(lman,'FOLDER');
    AddString (lp,'NAME' ,aman.GetEntryName(i));
    if afull then
      AddInteger(lp,'COUNT',aman.Entries[i].count);
    lp:=AddGroup(lp,'CHILDREN');


    if aman.GetFirstFile(p,i)<>0 then
    repeat
      lc:=AddGroup(lp,'CHILD');
      with p^ do
      begin
        AddString (lc,'NAME',aman.GetName(name));
        AddInteger(lc,'TYPE',ftype);  // required for TL2 type 18 (dir to delete)
        AddInteger(lc,'SIZE',size_s); // required for zero-size files (file to delete)
        if afull then
        begin
          AddUnsigned(lc,'CRC'   ,checksum);
          AddInteger (lc,'OFFSET',offset);
//          if ABS(ainfo.ver)=verTL2 then
          if ftime<>0 then
            AddInteger64(lc,'TIME',ftime);
        end;
      end;
   until aman.GetNextFile(p)=0
  end;

  BuildTextFile(lman,PChar(fname));
  DeleteNode(lman);
end;

procedure FileToMAN(const fname:string; out aman:TRGManifest);
var
  lman,lp,lg,lc:pointer;
  pw:PUnicodeChar;
  i,j,k,lentry:integer;
begin
  lman:=ParseTextFile(PChar(fname));
  if lman<>nil then
  begin
    if IsNodeName(lman,'MANIFEST') then
    begin

      for i:=0 to GetChildCount(lman)-1 do
      begin
        lc:=GetChild(lman,i);
        case GetNodeType(lc) of
          rgString: begin
//            if IsNodeName(lc,'FILE') then ainfo.fname:=AsString(lc);
          end;

          rgInteger: begin
            if IsNodeName(lc,'TOTAL') then aman.total:=AsInteger(lc);
            if IsNodeName(lc,'COUNT') then aman.SetEntriesCapacity(AsInteger(lc));
          end;

          rgGroup: begin
            if IsNodeName(lc,'FOLDER') then
            begin
              if Length(aman.Entries)=0 then
                aman.SetEntriesCapacity(GetGroupCount(lc));

              for j:=0 to GetChildCount(lc)-1 do
              begin
                lentry:=aman.AddEntry();
                lp:=GetChild(lc,j);
                case GetNodeType(lp) of
                  rgString: begin
                    if IsNodeName(lp,'NAME') then
                      aman.Entries[lentry].name:=aman.SetName(AsString(lp));
                  end;

                  rgInteger: begin
                    if IsNodeName(lp,'COUNT') then
                      aman.SetFilesCapacity(aman.cntFiles+AsInteger(lp));
                  end;

                  rgGroup: begin
                    if IsNodeName(lp,'CHILDREN') then
                    begin
{
                      if Length(aman.Entries[j].Files)=0 then
                        SetLength(aman.Entries[j].Files,GetGroupCount(lp));
}
                      for k:=0 to GetChildCount(lp)-1 do
                      begin
                        lg:=GetChild(lp,k);
                        if (GetNodeType(lg)=rgGroup) and
                           (IsNodeName(lg,'CHILD')) then
                        begin

                          with aman.AddEntryFile(lentry)^ do
                            case GetNodeType(lg) of
                              rgInteger: begin
                                pw:=GetNodeName(lg);
                                if      CompareWide(pw,'TYPE'  )=0 then ftype :=AsInteger(lg)
                                else if CompareWide(pw,'SIZE'  )=0 then size_s:=AsInteger(lg)
                                else if CompareWide(pw,'OFFSET')=0 then offset:=AsInteger(lg);
                              end;
                              rgString   : name    :=aman.SetName(AsString(lg));
                              rgUnsigned : checksum:=AsUnsigned(lg);
                              rgInteger64: ftime   :=AsInteger64(lg);
                            end;

                        end;
                      end;
                    end;
                  end;

                end;

              end;
            end;
          end;

        end;

      end;
    end;

    DeleteNode(lman);
  end;
end;
{$ENDIF DEBUG}

end.
