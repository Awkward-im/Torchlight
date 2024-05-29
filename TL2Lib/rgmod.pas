{TODO: hash calc for required mods}
// PUnicodeChar(UnicodeString(ExtractFilenameOnly(fname)))
// PChar(string(strFile)+'MOD.DAT')
unit RGMod;

interface

uses
  classes,
  rgglobal;

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

//--- [TL2] binary format ---

function ReadModInfo       (fname:PChar; var   amod:TTL2ModInfo):boolean;
function ReadModInfoBuf    (abuf:PByte ; var   amod:TTL2ModInfo):boolean;
function ReadModInfoStream (ast:TStream; var   amod:TTL2ModInfo):boolean;
function WriteModInfo   (fname:PChar   ; const amod:TTL2ModInfo):integer;
function WriteModInfo   (out abuf:PByte; const amod:TTL2ModInfo):integer;
function WriteModInfoBuf(    abuf:PByte; const amod:TTL2ModInfo):integer;
function WriteModInfoStream(ast:TStream; const amod:TTL2ModInfo):integer;

procedure ClearModInfo(var amod:TTL2ModInfo); export;
procedure MakeModInfo (out amod:TTL2ModInfo); export;
procedure CopyModInfo (out dst :TTL2ModInfo; const src:TTL2ModInfo);

//--- Text config format ---

function ParseModConfig(anode:pointer; out amod:TTL2ModInfo):boolean;
function ReadModConfig (abuf:PByte   ; out amod:TTL2ModInfo):boolean;
function LoadModConfig (strFile:PChar; out amod:TTL2ModInfo):boolean;
function BuildModConfig(const amod:TTL2ModInfo):pointer;
function SaveModConfig (const amod:TTL2ModInfo; strFile:PChar):boolean;
function WriteModConfig(const amod:TTL2ModInfo; var abuf:PByte):boolean;


implementation

uses
  SysUtils, // CreateGUID call for MakeModInfo function
  rgstream,
  rwmemory,
  rgio.text,
  rgnode;

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

{%REGION ModInfo}

function WriteModInfoStream(ast:TStream; const amod:TTL2ModInfo):integer;
var
  lpos:integer;
  i:integer;
begin
  lpos:=ast.Position;

  ast.WriteWord(4);

  ast.WriteWord(amod.modver);

  // yes, first number is higher word
  ast.WriteQWord(ReverseWords(amod.gamever));
{
  ast.WriteWord(tTL2VerRec(amod.gamever).arr[3]);
  ast.WriteWord(tTL2VerRec(amod.gamever).arr[2]);
  ast.WriteWord(tTL2VerRec(amod.gamever).arr[1]);
  ast.WriteWord(tTL2VerRec(amod.gamever).arr[0]);
}
  // not real values coz no data/manifest written yet
  ast.WriteDWord(amod.offData);
  ast.WriteDWord(amod.offMan);

  ast.WriteShortString(amod.title);
  ast.WriteShortString(amod.author);
  ast.WriteShortString(amod.descr);
  ast.WriteShortString(amod.website);
  ast.WriteShortString(amod.download);
  ast.WriteQWord(QWord(amod.modid));
  //-
  ast.WriteDWord(amod.flags);

  ast.WriteQWord(QWord(amod.reqHash));
  ast.WriteWord(Length(amod.reqs));
  for i:=0 to High(amod.reqs) do
  begin
    ast.WriteShortString(amod.reqs[i].name);
    ast.WriteQWord(QWord(amod.reqs[i].id));
    ast.WriteWord       (amod.reqs[i].ver);
  end;

  ast.WriteWord(Length(amod.dels));
  for i:=0 to High(amod.dels) do
    ast.WriteShortString(amod.dels[i]);

  result:=ast.Position-lpos;
end;

function WriteModInfoBuf(abuf:PByte; const amod:TTL2ModInfo):integer;
var
  p:PByte;
  i:integer;
begin
  p:=abuf;

  memWriteWord(p,4);

  memWriteWord(p,amod.modver);

  // yes, first number is higher word
  memWriteQWord(p,ReverseWords(amod.gamever));
{
  memWriteWord(p,tTL2VerRec(amod.gamever).arr[3]);
  memWriteWord(p,tTL2VerRec(amod.gamever).arr[2]);
  memWriteWord(p,tTL2VerRec(amod.gamever).arr[1]);
  memWriteWord(p,tTL2VerRec(amod.gamever).arr[0]);
}
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

{TODO: static buf to GetMem/FreeMem}
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
  result:=WriteModInfoBuf(@buf[0],amod);
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

function ReadModInfoStream(ast:TStream; var amod:TTL2ModInfo):boolean;
var
  lversion,lpos,i,lcnt:integer;
begin
  FillChar(amod,SizeOf(amod),0);

  // wrong signature

  lpos:=ast.Position;
  lversion:=ast.ReadWord();
  if (lversion=0) or (lversion>4) then
  begin
    ast.Position:=lpos;
    amod.modid:=-1;
    amod.title:=nil;
    exit(false);
  end;

  result:=true;

//!!  amod.filename:=UTF8Decode(fname);

  amod.modver:=ast.ReadWord();

  if lversion>=4 then
  begin
    amod.gamever:=ReverseWords(ast.ReadQWord());
  end;

  if lversion=1 then
  begin
    for i:=0 to amod.modver do
    begin
      ast.ReadQWord(); // GUID per version
      ast.ReadByte (); // Major version
    end;
  end;

  amod.offData :=ast.ReadDWord();
  amod.offMan  :=ast.ReadDWord();
  amod.title   :=ast.ReadShortStringWide();
  amod.author  :=ast.ReadShortStringWide();
  amod.descr   :=ast.ReadShortStringWide();
  amod.website :=ast.ReadShortStringWide();
  amod.download:=ast.ReadShortStringWide();
  amod.modid   :=ast.ReadQWord();
  //-
  amod.flags   :=ast.ReadDWord();

  amod.reqHash :=ast.ReadQWord();
  lcnt:=ast.ReadWord();
  SetLength(amod.reqs,lcnt);
  for i:=0 to lcnt-1 do
  begin
    amod.reqs[i].name:=ast.ReadShortStringWide();
    amod.reqs[i].id  :=ast.ReadQWord();
    if lversion<>1 then
      amod.reqs[i].ver:=ast.ReadWord();
  end;

  if lversion>=3 then
  begin
    lcnt:=ast.ReadWord();
    SetLength(amod.dels,lcnt);
    for i:=0 to lcnt-1 do
      amod.dels[i]:=ast.ReadShortStringWide();
  end;
end;

function ReadModInfoBuf(abuf:PByte; var amod:TTL2ModInfo):boolean;
var
  lversion,i,lcnt:integer;
begin
  FillChar(amod,SizeOf(amod),0);

  // wrong signature

  lversion:=PWord(abuf)^;

  if (lversion=0) or (lversion>4) then
  begin
    amod.modid:=-1;
    amod.title:=nil;
    exit(false);
  end;

  inc(abuf,2);

  result:=true;

//!!  amod.filename:=UTF8Decode(fname);

  amod.modver:=memReadWord(abuf);

  if lversion>=4 then
  begin
    // yes, first number is higher word
    amod.gamever:=ReverseWords(memReadQWord(abuf));
{
    tTL2VerRec(amod.gamever).arr[3]:=memReadWord(abuf);
    tTL2VerRec(amod.gamever).arr[2]:=memReadWord(abuf);
    tTL2VerRec(amod.gamever).arr[1]:=memReadWord(abuf);
    tTL2VerRec(amod.gamever).arr[0]:=memReadWord(abuf);
}
  end;

  if lversion=1 then
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
    if lversion<>1 then
      amod.reqs[i].ver:=memReadWord(abuf);
  end;

  if lversion>=3 then
  begin
    lcnt:=memReadWord(abuf);
    SetLength(amod.dels,lcnt);
    for i:=0 to lcnt-1 do
      amod.dels[i]:=memReadShortString(abuf);
  end;
end;

{TODO: GetMem buf if modinfo>16k}
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
    CopyWide(amod.filename,PUnicodeChar(UnicodeString(ExtractFilenameOnly(fname))));
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

procedure CopyModInfo(out dst:TTL2ModInfo; const src:TTL2ModInfo);
var
  i:integer;
begin
  FillChar(dst,SizeOf(dst),0);
  dst.modid   :=src.modid;
  dst.gamever :=src.gamever;
  dst.title   :=CopyWide(src.title   );
  dst.author  :=CopyWide(src.author  );
  dst.descr   :=CopyWide(src.descr   );
  dst.website :=CopyWide(src.website );
  dst.download:=CopyWide(src.download);
  dst.filename:=CopyWide(src.filename);
  // start of additional info
  dst.steam_preview:=CopyWide(src.steam_preview);
  dst.steam_tags   :=CopyWide(src.steam_tags   );
  dst.steam_descr  :=CopyWide(src.steam_descr  );
  dst.long_descr   :=CopyWide(src.long_descr   );
  // end of additional info
  SetLength(dst.dels,Length(src.dels));
  for i:=0 to High(dst.dels) do dst.dels[i]:=CopyWide(src.dels[i]);
  dst.offData :=0;
  dst.offMan  :=0;
  dst.flags   :=src.flags;
  dst.reqHash :=src.reqHash;
  SetLength(dst.reqs,Length(src.reqs));
  for i:=0 to High(dst.reqs) do
  begin
    dst.reqs[i].name:=CopyWide(src.reqs[i].name);
    dst.reqs[i].id  :=src.reqs[i].id;
    dst.reqs[i].ver :=src.reqs[i].ver;
  end;
  dst.modver  :=src.modver;
end;

{%ENDREGION ModInfo}

{%REGION ModConfig}

function ParseModConfig(anode:pointer; out amod:TTL2ModInfo):boolean;
var
  lnode,lline:pointer;
  i,j,lcnt:integer;
begin
  result:=false;

  if anode=nil then exit;

  if IsNodeName(anode,'MOD') then
  begin
    result:=true;

    InitModInfo(amod);

    for i:=0 to GetChildCount(anode)-1 do
    begin
      lnode:=GetChild(anode,i);
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
  end;
end;

function ReadModConfig(abuf:PByte; out amod:TTL2ModInfo):boolean;
var
  lroot:pointer;
begin
  lroot:=ParseTextMem(abuf);

  result:=ParseModConfig(lroot, amod);
  DeleteNode(lroot);
end;

function LoadModConfig(strFile:PChar; out amod:TTL2ModInfo):boolean;
var
  lroot:pointer;
begin
  if (strFile<>nil) and not (strFile[Length(strFile)-1] in ['\','/']) then
    lroot:=ParseTextFile(strFile)
  else
    lroot:=ParseTextFile(PChar(string(strFile)+'MOD.DAT'));

  result:=ParseModConfig(lroot, amod);
  DeleteNode(lroot);
end;

function BuildModConfig(const amod:TTL2ModInfo):pointer;
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

  result:=lroot;
end;

function SaveModConfig(const amod:TTL2ModInfo; strFile:PChar):boolean;
var
  lroot:pointer;
begin
  lroot:=BuildModConfig(amod);

  if (strFile<>nil) and not (strFile[Length(strFile)-1] in ['\','/']) then
    result:=BuildTextFile(lroot, strFile)
  else
    result:=BuildTextFile(lroot, PChar(string(strFile)+'MOD.DAT'));

  DeleteNode(lroot);
end;

function WriteModConfig(const amod:TTL2ModInfo; var abuf:PByte):boolean;
var
  lroot:pointer;
begin
  lroot:=BuildModConfig(amod);

  result:=NodeToWide(lroot,PWideChar(abuf));

  DeleteNode(lroot);
end;

{%ENDREGION ModConfig}

end.
