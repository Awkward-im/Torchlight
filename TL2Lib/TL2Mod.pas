unit TL2Mod;

interface

type
  // fields are rearranged
  TTL2ModInfo = record
    modid   :Int64;
    gamever :QWord;
    offData :DWord;
    offMan  :DWord;
    title   :PWideChar;
    author  :PWideChar;
    descr   :PWideChar;
    website :PWideChar;
    download:PWideChar;
    filename:PWideChar;
    flags   :DWord;
    reqHash :Int64;
    reqs    :array of record
      name:PWideChar;
      id  :Int64;       // just this field presents in MOD.DAT
      ver :Word;
    end;
    dels    :array of PWideChar;
    modver  :Word;
  end;

type
  // v.4 mod binary header start
  PTL2ModTech = ^TTL2ModTech;
  TTL2ModTech = packed record
    version:Word; // 4
    modver :Word;
    gamever:array [0..3] of Word;
    offData:DWord;
    offMan :DWord;
  end;

function ReadModInfo    (fname:PChar   ; out amod:TTL2ModInfo):boolean; export;
function ReadModInfoBuf (abuf:PByte    ; out amod:TTL2ModInfo):boolean;
function WriteModInfo   (fname:PChar   ; const amod:TTL2ModInfo):integer; export;
function WriteModInfo   (out abuf:PByte; const amod:TTL2ModInfo):integer;
function WriteModInfoBuf(out buf       ; const amod:TTL2ModInfo):integer;
procedure ClearModInfo(var amod:TTL2ModInfo); export;

function LoadModConfiguration(strFilePath:PChar; var amod:TTL2ModInfo):boolean;
function SaveModConfiguration(const amod:TTL2ModInfo; strFilePath:PChar):boolean;


const
  MinTL2ModInfoSize =
    2+ // mod format version
    2+ // mod version
    8+ // game version (v.4+)
    4+ // data offset
    4+ // man offset
    2+ // title
    2+ // author
    2+ // descr
    2+ // website
    2+ // download
    8+ // modid
    4+ // flags
    8+ // req. hash
    2+ // req. count
    2  // delete count (v.3+)
    ;

implementation

uses
  rgglobal,
  rgmemory,
  rgnode;

//----- MOD Header -----

type
  tVerRec = record
    arr:array [0..3] of word;
  end;

function WriteModInfoBuf(out buf; const amod:TTL2ModInfo):integer;
var
  p:PByte;
  i:integer;
begin
  p:=PByte(@buf);

  memWriteWord(p,4);

  memWriteWord(p,amod.modver);

  // yes, first number is higher word
  memWriteWord(p,tVerRec(amod.gamever).arr[3]);
  memWriteWord(p,tVerRec(amod.gamever).arr[2]);
  memWriteWord(p,tVerRec(amod.gamever).arr[1]);
  memWriteWord(p,tVerRec(amod.gamever).arr[0]);

  // not real values coz no data/manifest written yet
  memWriteDWord(p,amod.offData);
  memWriteDWord(p,amod.offMan);

  memWriteShortString(p,amod.title);
  memWriteShortString(p,amod.author);
  memWriteShortString(p,amod.descr);
  memWriteShortString(p,amod.website);
  memWriteShortString(p,amod.download);
  memWriteInteger64  (p,amod.modid);
  //-
  memWriteDWord(p,amod.flags);

  memWriteInteger64(p,amod.reqHash);
  memWriteWord(p,Length(amod.reqs));
  for i:=0 to High(amod.reqs) do
  begin
    memWriteShortString(p,amod.reqs[i].name);
    memWriteInteger64  (p,amod.reqs[i].id);
    memWriteWord       (p,amod.reqs[i].ver);
  end;

  memWriteWord(p,Length(amod.dels));
  for i:=0 to High(amod.dels) do
    memWriteShortString(p,amod.dels[i]);

  result:=p-PByte(@buf);
end;

function WriteModInfo(out abuf:PByte; const amod:TTL2ModInfo):integer;
var
  buf:array [0..16383] of byte;
begin
  result:=WriteModInfoBuf(buf,amod);
  if result>0 then
  begin
    GetMem(abuf,result);
    Move(buf[0],abuf^,result);
  end
  else
    abuf:=nil;
end;

function WriteModInfo(fname:PChar; const amod:TTL2ModInfo):integer;
var
  buf:array [0..16383] of byte;
  f:file of byte;
begin
  result:=WriteModInfoBuf(buf,amod);
  if result>0 then
  begin
{$PUSH}
{$I-}
    Assign(f,fname);
    Rewrite(f);
    if IOResult=0 then
    begin
      BlockWrite(f,buf[0],result);
      Close(f);
    end
    else
      result:=0;
{$POP}
  end;
end;

function ReadModInfoBuf(abuf:PByte; out amod:TTL2ModInfo):boolean;
var
  mt:PTL2ModTech;
  i,lcnt:integer;
begin
  result:=false;

  mt:=pointer(abuf);

  // wrong signature

  if (mt^.version=0) or (mt^.version>4) then
  begin
    amod.modid:=-1;
    amod.title:=nil;
    exit;
  end;

  inc(abuf,2);

  result:=true;

//!!  amod.filename:=UTF8Decode(fname);

  amod.modver:=memReadWord(abuf);

  if mt^.version>=4 then
  begin
    // yes, first number is higher word
    tVerRec(amod.gamever).arr[3]:=memReadWord(abuf);
    tVerRec(amod.gamever).arr[2]:=memReadWord(abuf);
    tVerRec(amod.gamever).arr[1]:=memReadWord(abuf);
    tVerRec(amod.gamever).arr[0]:=memReadWord(abuf);
{
    amod.gamever:=             (QWord(memReadWord(abuf)) shl 48);
    amod.gamever:=amod.gamever+(QWord(memReadWord(abuf)) shl 32);
    amod.gamever:=amod.gamever+(DWord(memReadWord(abuf)) shl 16);
    amod.gamever:=amod.gamever+memReadWord(abuf);
}
  end;

  if mt^.version=1 then
  begin
    for i:=0 to amod.modver do
    begin
      memReadInteger64(abuf); // GUID per version
      memReadByte(abuf);      // Major version
    end;
  end;

  amod.offData :=memReadDWord(abuf);
  amod.offMan  :=memReadDWord(abuf);
  amod.title   :=memReadShortString(abuf);
  amod.author  :=memReadShortString(abuf);
  amod.descr   :=memReadShortString(abuf);
  amod.website :=memReadShortString(abuf);
  amod.download:=memReadShortString(abuf);
  amod.modid   :=memReadInteger64(abuf);
  //-
  amod.flags   :=memReadDWord(abuf);

  amod.reqHash :=memReadInteger64(abuf);
  lcnt:=memReadWord(abuf);
  SetLength(amod.reqs,lcnt);
  for i:=0 to lcnt-1 do
  begin
    amod.reqs[i].name:=memReadShortString(abuf);
    amod.reqs[i].id  :=memReadInteger64(abuf);
    if mt^.version<>1 then
      amod.reqs[i].ver:=memReadWord(abuf);
  end;

  if mt^.version>=3 then
  begin
    lcnt:=memReadWord(abuf);
    SetLength(amod.dels,lcnt);
    for i:=0 to lcnt-1 do
      amod.dels[i]:=memReadShortString(abuf);
  end;
end;

function ReadModInfo(fname:PChar; out amod:TTL2ModInfo):boolean;
var
  buf:array [0..16383] of byte;
  f:file of byte;
  i:integer;
begin
{$PUSH}
{$I-}
  Assign(f,fname);
  Reset(f);
  if IOResult=0 then
  begin
    i:=FileSize(f);
    if i>0 then
    begin
      if i>SizeOf(buf) then i:=SizeOf(buf);
      buf[0]:=0;
      BlockRead(f,buf[0],i);
    end;
    Close(f);
  end
  else
    i:=0;
{$POP}

  if i>MinTL2ModInfoSize then // minimal size of used header data
    result:=ReadModInfoBuf(@buf,amod)
  else
    result:=false;

end;

procedure ClearModInfo(var amod:TTL2ModInfo);
var
  i:integer;
begin
  if amod.title   <>nil then FreeMem(amod.title);
  if amod.author  <>nil then FreeMem(amod.author);
  if amod.descr   <>nil then FreeMem(amod.descr);
  if amod.website <>nil then FreeMem(amod.website);
  if amod.download<>nil then FreeMem(amod.download);
  if Length(amod.reqs)>0 then
  begin
    for i:=0 to High(amod.reqs) do
      FreeMem(amod.reqs[i].name);
    SetLength(amod.reqs,0);
  end;
  if Length(amod.dels)>0 then
  begin
    for i:=0 to High(amod.dels) do
      FreeMem(amod.dels[i]);
    SetLength(amod.dels,0);
  end;
end;

//----- MOD.DAT -----

function LoadModConfiguration(strFilePath:PChar; var amod:TTL2ModInfo):boolean;
var
  lnode,lroot,lgroup:pointer;
  pcw:PWideChar;
  ls:string;
  i,j,lcnt:integer;
begin
  result:=false;

  if strFilePath<>nil then
    ls:=string(strFilePath)+'\MOD.DAT'
  else
    ls:='MOD.DAT';

  lroot:=ParseDatFile(PChar(ls));
  if lroot=nil then exit;

  if not CompareWide(GetNodeName(lroot),'MOD') then exit;

  for i:=0 to GetChildCount(lroot)-1 do
  begin
    lnode:=GetChild(lroot,i);
    pcw:=GetNodeName(lnode);
    if      CompareWide(pcw,'NAME'         ) then CopyWide(amod.title   ,AsString(lnode))
    else if CompareWide(pcw,'AUTHOR'       ) then CopyWide(amod.author  ,AsString(lnode))
    else if CompareWide(pcw,'DESCRIPTION'  ) then CopyWide(amod.descr   ,AsString(lnode))
    else if CompareWide(pcw,'WEBSITE'      ) then CopyWide(amod.website ,AsString(lnode))
    else if CompareWide(pcw,'DOWNLOAD_URL' ) then CopyWide(amod.download,AsString(lnode))
    else if CompareWide(pcw,'MOD_FILE_NAME') then CopyWide(amod.filename,AsString(lnode))
    else if CompareWide(pcw,'VERSION'      ) then amod.modver:=AsInteger  (lnode)
    else if CompareWide(pcw,'MOD_ID'       ) then amod.modid :=AsInteger64(lnode)
    else if CompareWide(pcw,'REMOVE_FILES' ) then
    begin
      if GetNodeType(lnode)=rgGroup then
      begin
        SetLength(amod.dels,GetChildCount(lnode));
        lcnt:=0;
        for j:=0 to High(amod.dels) do
        begin
          lgroup:=GetChild(lnode,j);
          if CompareWide(GetNodeName(lgroup),'FILE') then
          begin
            CopyWide(amod.dels[lcnt],AsString(lgroup));
            inc(lcnt);
          end;
        end;
        SetLength(amod.dels,lcnt);
      end;
    end
    else if CompareWide(pcw,'REQUIRED_MODS') then
    begin
      if GetNodeType(lnode)=rgGroup then
      begin
        SetLength(amod.dels,GetChildCount(lnode));
        lcnt:=0;
        for j:=0 to High(amod.dels) do
        begin
          lgroup:=GetChild(lnode,j);
          if CompareWide(GetNodeName(lgroup),'ID') then
          begin
            amod.reqs[lcnt].id:=AsInteger(lgroup);
            inc(lcnt);
          end;
        end;
        SetLength(amod.dels,lcnt);
      end;
    end;
  end;

  DeleteNode(lroot);
end;

function SaveModConfiguration(const amod:TTL2ModInfo; strFilePath:PChar):boolean;
var
  lroot,lgroup:pointer;
  ls:string;
  i:integer;
begin
  if strFilePath<>nil then
    ls:=string(strFilePath)+'\MOD.DAT'
  else
    ls:='MOD.DAT';

  lroot:=AddGroup(nil,'MOD');
  AddString   (lroot,'NAME'         , amod.title   );
  AddInteger64(lroot,'MOD_ID'       , amod.modid   );
  AddString   (lroot,'AUTHOR'       , amod.author  );
  AddString   (lroot,'DESCRIPTION'  , amod.descr   );
  AddString   (lroot,'WEBSITE'      , amod.website );
  AddString   (lroot,'DOWNLOAD_URL' , amod.download);
  AddString   (lroot,'MOD_FILE_NAME', amod.filename);
  AddInteger  (lroot,'VERSION'      , amod.modver  );

  if Length(amod.dels)>0 then
  begin
    lgroup:=AddGroup(lroot,'REMOVE_FILES');
    for i:=0 to High(amod.dels) do
      AddString(lgroup,'FILE',amod.dels[i]);
  end;

  if Length(amod.reqs)>0 then
  begin
    lgroup:=AddGroup(lroot,'REQUIRED_MODS');
    for i:=0 to High(amod.reqs) do
      AddInteger64(lgroup,'ID',amod.reqs[i].id);
  end;

  result:=WriteDatTree(lroot, pointer(ls));

  DeleteNode(lroot);
end;


end.
