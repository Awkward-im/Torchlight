unit TL2Mod;

interface

uses
  rgglobal;

type
  tTL2VerRec = record
    arr:array [0..3] of word;
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

function ReadModInfo    (fname:PChar   ; var   amod:TTL2ModInfo):boolean; export;
function ReadModInfoBuf (abuf:PByte    ; var   amod:TTL2ModInfo):boolean;
function WriteModInfo   (fname:PChar   ; const amod:TTL2ModInfo):integer; export;
function WriteModInfo   (out abuf:PByte; const amod:TTL2ModInfo):integer;
function WriteModInfoBuf(    abuf:PByte; const amod:TTL2ModInfo):integer;
procedure ClearModInfo(var amod:TTL2ModInfo); export;
procedure MakeModInfo (out amod:TTL2ModInfo); export;

function LoadModConfiguration(strFile:PChar; out amod:TTL2ModInfo):boolean;
function SaveModConfiguration(const amod:TTL2ModInfo; strFile:PChar):boolean;


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
  SysUtils, // CreateGUID call for MakeModInfo function
  rgmemory,
  rgio.text,
  rgnode;

//----- MOD Header -----

function WriteModInfoBuf(abuf:PByte; const amod:TTL2ModInfo):integer;
var
  p:PByte;
  i:integer;
begin
  p:=abuf;

  memWriteWord(p,4);

  memWriteWord(p,amod.modver);

  // yes, first number is higher word
  memWriteWord(p,tTL2VerRec(amod.gamever).arr[3]);
  memWriteWord(p,tTL2VerRec(amod.gamever).arr[2]);
  memWriteWord(p,tTL2VerRec(amod.gamever).arr[1]);
  memWriteWord(p,tTL2VerRec(amod.gamever).arr[0]);

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

  result:=p-abuf;
end;

function WriteModInfo(out abuf:PByte; const amod:TTL2ModInfo):integer;
var
  buf:array [0..16383] of byte;
begin
  result:=WriteModInfoBuf(@buf,amod);
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

function ReadModInfoBuf(abuf:PByte; var amod:TTL2ModInfo):boolean;
var
  mt:PTL2ModTech;
  i,lcnt:integer;
begin
  result:=false;

  FillChar(amod,SizeOf(amod),0);

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
    tTL2VerRec(amod.gamever).arr[3]:=memReadWord(abuf);
    tTL2VerRec(amod.gamever).arr[2]:=memReadWord(abuf);
    tTL2VerRec(amod.gamever).arr[1]:=memReadWord(abuf);
    tTL2VerRec(amod.gamever).arr[0]:=memReadWord(abuf);
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

function ReadModInfo(fname:PChar; var amod:TTL2ModInfo):boolean;
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
    if i>MinTL2ModInfoSize then
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

  if i>MinTL2ModInfoSize then
  begin
    result:=ReadModInfoBuf(@buf,amod);
    CopyWide(amod.filename,PWideChar(WideString(ExtractFilenameOnly(fname))));
  end
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
  if amod.filename<>nil then FreeMem(amod.filename);

  if amod.steam_preview<>nil then FreeMem(amod.steam_preview);
  if amod.steam_tags   <>nil then FreeMem(amod.steam_tags);
  if amod.steam_descr  <>nil then FreeMem(amod.steam_descr);
  if amod.long_descr   <>nil then FreeMem(amod.long_descr);
  
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

procedure InitModInfo(out amod:TTL2ModInfo);
begin
  FillChar(amod,SizeOf(amod),0);
  amod.gamever:=$0001001900050002;
end;

procedure MakeModInfo(out amod:TTL2ModInfo);
var
  lguid:TGUID;
begin
  InitModInfo(amod);
  amod.modver:=1;
  CreateGUID(lguid);
  amod.modid:=Int64(MurmurHash64B(lguid,16,0));
end;

//----- MOD.DAT -----

function LoadModConfiguration(strFile:PChar; out amod:TTL2ModInfo):boolean;
var
  lnode,lroot,lline:pointer;
  i,j,lcnt:integer;
begin
  result:=false;

  if (strFile<>nil) and not (strFile[Length(strFile)-1] in ['\','/']) then
    lroot:=ParseTextFile(strFile)
  else
    lroot:=ParseTextFile(PChar(string(strFile)+'MOD.DAT'));

  if lroot=nil then exit;

  if IsNodeName(lroot,'MOD') then
  begin
    result:=true;

    InitModInfo(amod);

    for i:=0 to GetChildCount(lroot)-1 do
    begin
      lnode:=GetChild(lroot,i);
      if      IsNodeName(lnode,'NAME'         ) then CopyWide(amod.title   ,AsString(lnode))
      else if IsNodeName(lnode,'AUTHOR'       ) then CopyWide(amod.author  ,AsString(lnode))
      else if IsNodeName(lnode,'DESCRIPTION'  ) then CopyWide(amod.descr   ,AsString(lnode))
      else if IsNodeName(lnode,'WEBSITE'      ) then CopyWide(amod.website ,AsString(lnode))
      else if IsNodeName(lnode,'DOWNLOAD_URL' ) then CopyWide(amod.download,AsString(lnode))
      else if IsNodeName(lnode,'MOD_FILE_NAME') then CopyWide(amod.filename,AsString(lnode))
      else if IsNodeName(lnode,'VERSION'      ) then amod.modver:=AsInteger  (lnode)
      else if IsNodeName(lnode,'MOD_ID'       ) then amod.modid :=AsInteger64(lnode)

      else if IsNodeName(lnode,'STEAM_PREVIEW_FILE'      ) then CopyWide(amod.steam_preview,AsString(lnode))
      else if IsNodeName(lnode,'STEAM_TAGS'              ) then CopyWide(amod.steam_tags   ,AsString(lnode))
      else if IsNodeName(lnode,'STEAM_CHANGE_DESCRIPTION') then CopyWide(amod.steam_descr  ,AsString(lnode))
      else if IsNodeName(lnode,'LONG_DESCRIPTION'        ) then CopyWide(amod.long_descr   ,AsString(lnode))
      
      else if IsNodeName(lnode,'REMOVE_FILES' ) then
      begin
        if GetNodeType(lnode)=rgGroup then
        begin
          SetLength(amod.dels,GetChildCount(lnode));
          lcnt:=0;
          for j:=0 to High(amod.dels) do
          begin
            lline:=GetChild(lnode,j);
            if IsNodeName(lline,'FILE') then
            begin
              CopyWide(amod.dels[lcnt],AsString(lline));
              inc(lcnt);
            end;
          end;
          SetLength(amod.dels,lcnt);
        end;
      end
      else if IsNodeName(lnode,'REQUIRED_MODS') then
      begin
        if GetNodeType(lnode)=rgGroup then
        begin
          SetLength(amod.reqs,GetChildCount(lnode));
          lcnt:=0;
          for j:=0 to High(amod.reqs) do
          begin
            lline:=GetChild(lnode,j);
            if IsNodeName(lline,'ID') then
            begin
              amod.reqs[lcnt].id:=AsInteger(lline);
              inc(lcnt);
            end;
          end;
          SetLength(amod.reqs,lcnt);
        end;
      end;
    end;

    DeleteNode(lroot);
  end;
end;

function SaveModConfiguration(const amod:TTL2ModInfo; strFile:PChar):boolean;
var
  lroot,lgroup:pointer;
  i:integer;
begin
  lroot:=AddGroup(nil,'MOD');
  AddString   (lroot,'NAME'         , amod.title   );
  AddInteger64(lroot,'MOD_ID'       , amod.modid   );
  AddInteger  (lroot,'VERSION'      , amod.modver  );
  AddString   (lroot,'AUTHOR'       , amod.author  );
  AddString   (lroot,'DESCRIPTION'  , amod.descr   );
  AddString   (lroot,'WEBSITE'      , amod.website );
  AddString   (lroot,'DOWNLOAD_URL' , amod.download);
  AddString   (lroot,'MOD_FILE_NAME', amod.filename);

  if amod.steam_preview<>nil then AddString(lroot,'STEAM_PREVIEW_FILE'      , amod.steam_preview);
  if amod.steam_tags   <>nil then AddString(lroot,'STEAM_TAGS'              , amod.steam_tags   );
  if amod.steam_descr  <>nil then AddString(lroot,'STEAM_CHANGE_DESCRIPTION', amod.steam_descr  );
  if amod.long_descr   <>nil then AddString(lroot,'LONG_DESCRIPTION'        , amod.long_descr   );

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

  if (strFile<>nil) and not (strFile[Length(strFile)-1] in ['\','/']) then
    result:=BuildTextFile(lroot, strFile)
  else
    result:=BuildTextFile(lroot, PChar(string(strFile)+'MOD.DAT'));

  DeleteNode(lroot);
end;


end.
