unit TL2Mod;

interface

uses
  TL2ModInfo;

// PAK and MOD content file types
const
  pftDat       = $00;
  pftLayout    = $01;
  pftMesh      = $02;
  pftSkeleton  = $03;
  pftDds       = $04;
  pftPng       = $05;
  pftOgg       = $06;
  pftDirectory = $07;
  pftMaterial  = $08;
  pftRaw       = $09;
  //
  pftImageSet  = $0B;
  pftTtf       = $0C;
  pftFont      = $0D;
  //
  //
  pftAnimation = $10;
  pftHie       = $11;
  pftOther     = $12;
  pftScheme    = $13;
  pftLookNFeel = $14;
  pftMpd       = $15;

type
  TPAKHeader = record
  end;
type
  TMANHeader = record
    sign    :word;
    checksum:dword;
    root    :PWideChar; //??
    cnt     :dword;     // total entries?
    entrycnt:dword;     // with files?
  end;
type
  TModDirEntry = record  // real field order
    filetime:UInt64;     // 6
    filename:PWideChar;  // 3
    checksum:dword;      // 1
    offset  :dword;      // 4
    u_size  :dword;      // 5
    filetype:byte;       // 2
  end;

implementation

uses
  TL2DatNode;

function LoadModConfiguration(strFilePath:PChar; var amod:TTL2ModInfo):boolean;
var
  lnode,lroot,lgroup:pointer;
  ls:string;
  i:integer;
begin
  result:=false;

  if strFilePath<>nil then
    ls:=string(strFilePath)+'\MOD.DAT'
  else
    ls:='MOD.DAT';

  lroot:=ParseDatFile(PChar(ls));
  if lroot=nil then exit;
{
  if not WideCompare(lroot^.Name,'MOD') then exit;
  for i:=0 to lroot^.childcount-1 do
  begin
    lnode:=lroot^.children[i];
    if WideCompare(lnode^.Name,'NAME') then
    begin
    end
    else if WideCompare(lnode^.Name,'MOD_ID') then
    begin
    end
    else if WideCompare(lnode^.Name,'AUTHOR') then
    begin
    end
    else if WideCompare(lnode^.Name,'DESCRIPTION') then
    begin
    end
    else if WideCompare(lnode^.Name,'WEBSITE') then
    begin
    end
    else if WideCompare(lnode^.Name,'DOWNLOAD_URL') then
    begin
    end
    else if WideCompare(lnode^.Name,'VERSION') then
    begin
    end
    else if WideCompare(lnode^.Name,'MOD_FILE_NAME') then
    begin
    end
    else if WideCompare(lnode^.Name,'REMOVE_FILES') then
    begin
    end
    else if WideCompare(lnode^.Name,'REQUIRED_MODS') then
    begin
    end;
  end;
}
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
