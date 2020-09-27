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
      id  :Int64;
      ver :Word;
    end;
    dels    :array of PWideChar;
    modver  :Word;
  end;

type
  TTL2ModTech = packed record
    version:Word; // 4
    modver :Word;
    gamever:array [0..3] of Word;
    offData:DWord;
    offMan :DWord;
  end;

function  ReadModInfo(fname:PChar; var amod:TTL2ModInfo):boolean; export;
procedure ClearModInfo(var amod:TTL2ModInfo); export;

function LoadModConfiguration(strFilePath:PChar; var amod:TTL2ModInfo):boolean;
function SaveModConfiguration(const amod:TTL2ModInfo; strFilePath:PChar):boolean;


implementation

uses
  rgglobal,
  rgmemory,
  rgnode;

//----- MOD Header -----

function ReadModInfo(fname:PChar; var amod:TTL2ModInfo):boolean;
var
  buf:array [0..16383] of byte;
  f:file of byte;
  p:pbyte;
  i,lcnt:integer;
begin
  result:=false;

  AssignFile(f,fname);
  try
    Reset(f);
    i:=FileSize(f);
    if i>SizeOf(buf) then i:=SizeOf(buf);
    BlockRead(f,buf[0],i);
  except
    i:=0;
  end;
  CloseFile(f);

  if i<(2+2+8+4+4+2*5+8) then exit; // minimal size of used header data

  p:=@buf[0];

  // wrong signature
  if pword(p)^<>4 then
  begin
    amod.modid:=-1;
    amod.title:=nil;
    exit;
  end;
  inc(p,2);

  result:=true;

//  amod.filename:=UTF8Decode(fname);

  amod.modver  :=memReadWord(p);
  amod.gamever :=             (QWord(memReadWord(p)) shl 48);
  amod.gamever :=amod.gamever+(QWord(memReadWord(p)) shl 32);
  amod.gamever :=amod.gamever+(DWord(memReadWord(p)) shl 16);
  amod.gamever :=amod.gamever+memReadWord(p);
  amod.offData :=memReadDWord(p);
  amod.offMan  :=memReadDWord(p);
  amod.title   :=memReadShortString(p);
  amod.author  :=memReadShortString(p);
  amod.descr   :=memReadShortString(p);
  amod.website :=memReadShortString(p);
  amod.download:=memReadShortString(p);
  amod.modid   :=memReadInteger64(p);
  //-
  amod.flags   :=memReadDWord(p);
  amod.reqHash :=memReadInteger64(p);
  lcnt:=memReadWord(p);
  SetLength(amod.reqs,lcnt);
  for i:=0 to lcnt-1 do
  begin
    amod.reqs[i].name:=memReadShortString(p);
    amod.reqs[i].id  :=memReadInteger64(p);
    amod.reqs[i].ver :=memReadWord(p);
  end;
  lcnt:=memReadWord(p);
  SetLength(amod.dels,lcnt);
  for i:=0 to lcnt-1 do
    amod.dels[i]:=memReadShortString(p);
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
