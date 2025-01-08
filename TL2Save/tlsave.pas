unit TLSave;

interface

uses
  sysutils,
  classes,
  tlsgstatistic,
  rgstream,
  tlsgcommon,
  rgglobal,
  tl2map,
  tlsgitem,
  tlsgeffects,
  tlsgquest,
  tl2stats,
  tlsgchar;

type
  TTLSaveFile = class
  //--- common part
  private
    FStream:TStream;

    function FixItems(aItems:TTLItemList):boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    function  LoadFromFile(const aname:string):boolean;
    procedure SaveToFile  (const aname:string; aencoded:boolean=false);

    function  Parse():boolean;
    function  Prepare:boolean;

    function ClearCheat:boolean;
    function FixModdedItems:boolean;

  //--- TL2 save part
  private
    FVersion   :dword;
    FDataStart :integer;

    //--- Blocks
    FLastBlock :TTL2Stats;

    FUnknown1  :PByte;
    FUnknown2  :PByte;
    FUnknown3  :PByte;
    FUnkn3Size :integer;
    
    FCharInfo:TTLCharacter;
    FPetInfos:TTLCharArray;

    FClassString :string;
    FDifficulty  :TL2Difficulty;
    FHardcore    :boolean;
    FNewGameCycle:integer;
    FRetired     :boolean;
    FGameTime    :single;

    FBoundMods       :TTL2ModList;
    FRecentModHistory:TTL2ModList;
    FFullModHistory  :TTL2ModList;

    FKeyMapping:TTL2KeyMappingList;
    FFunctions :TTL2FunctionList;

    FQuests:TTLQuest;

    FCinematics:TL2StringList;
    FMovies    :TL2IdValList;
    FRecipes   :TL2IdList;
    FHistory   :TL2IdList;
    FMaps      :TTL2MapList;

    FStatistic :TTL2Statistic; // OR we can just keep pointer to buffer

    FWaypoint:string;
    FArea    :string;

    Unk2,Unk3:DWord;
    UnkCoord:TVector3;

    //----- User portal -----

    FPortalOpened:ByteBool;
    FPortalCoord :TVector3;
    FPortalPlace :string;

    function  ReadStatistic():boolean;
    procedure ReadModList(var ml:TTL2ModList);
    procedure ReadKeyMappingList;

    procedure WriteKeyMappingList;
    procedure WriteModList(ml:TTL2ModList);
    procedure WriteStatistic();

    function  GetMapCount:integer;
    function  GetPetCount:integer;
    function  GetPetInfo   (idx:integer):TTLCharacter;
    function  GetKeyMapping(idx:integer):TTL2KeyMapping;
    function  GetMovie     (idx:integer):TL2IdVal;
    function  GetMap       (idx:integer):TTL2Map;

    function  GetGameVersion:integer;
    function  GetStatistic (idx:integer):TRGInteger;
    procedure SetStatistic (idx:integer; aval:TRGInteger);
  public
    property GameVersion :integer        read GetGameVersion;
    property Difficulty  :TL2Difficulty  read FDifficulty   write FDifficulty;
    property Hardcore    :boolean        read FHardcore     write FHardcore;
    property NewGameCycle:integer        read FNewGameCycle write FNewGameCycle;
    property GameTime    :single         read FGameTime     write FGameTime; //!! control!!

    property BoundMods       :TTL2ModList read FBoundMods         write FBoundMods;
    property RecentModHistory:TTL2ModList read FRecentModHistory  write FRecentModHistory;
    property FullModHistory  :TTL2ModList read FFullModHistory    write FFullModHistory;

    property CharInfo:TTLCharacter read FCharInfo;
    property PetCount:integer read GetPetCount;
    property PetInfo[idx:integer]:TTLCharacter read GetPetInfo;

    property MapCount:integer read GetMapCount;
    property Maps[idx:integer]:TTL2Map read GetMap;

    property History:TL2IdList read FHistory write FHistory;
    property Recipes:TL2IdList read FRecipes write FRecipes;

    property Movies    :TL2IdValList          read FMovies;
    property Movie     [idx:integer]:TL2IdVal read GetMovie;

    property KeyMapping[idx:integer]:TTL2KeyMapping read GetKeyMapping;
    property Keys     :TTL2KeyMappingList read FKeyMapping;
    property Functions:TTL2FunctionList   read FFunctions;

    property Quests:TTLQuest  read FQuests;
    property Stats :TTL2Stats read FLastBlock;

    // Statistic
    property Statistic[idx:integer]:TRGInteger read GetStatistic write SetStatistic;
    
    property TimePlayed       :TRGInteger index statTotalTime  read GetStatistic write SetStatistic;
    property GoldGathered     :TRGInteger index statGold       read GetStatistic write SetStatistic;
    property StepsTaken       :TRGInteger index statSteps      read GetStatistic write SetStatistic;
    property QuestsDone       :TRGInteger index statQuests     read GetStatistic write SetStatistic;
    property Deaths           :TRGInteger index statDeaths     read GetStatistic write SetStatistic;
    property MonstersKilled   :TRGInteger index statMonsters   read GetStatistic write SetStatistic;
    property ChampionsKilled  :TRGInteger index statChampions  read GetStatistic write SetStatistic;
    property SkillsUsed       :TRGInteger index statSkills     read GetStatistic write SetStatistic;
    property LootablesLooted  :TRGInteger index statTreasures  read GetStatistic write SetStatistic;
    property TrapsSprung      :TRGInteger index statTraps      read GetStatistic write SetStatistic;
    property BreakablesBroken :TRGInteger index statBroken     read GetStatistic write SetStatistic;
    property PotionsUsed      :TRGInteger index statPotions    read GetStatistic write SetStatistic;
    property PortalsUsed      :TRGInteger index statPortals    read GetStatistic write SetStatistic;
    property FishCaught       :TRGInteger index statFish       read GetStatistic write SetStatistic;
    property TimesGambled     :TRGInteger index statGambled    read GetStatistic write SetStatistic;
    property ItemsEnchanted   :TRGInteger index statEnchanted  read GetStatistic write SetStatistic;
    property ItemsTransmuted  :TRGInteger index statTransmuted read GetStatistic write SetStatistic;
    property DamageTaken      :TRGInteger index statDmgTaken   read GetStatistic write SetStatistic;
    property DamageDealt      :TRGInteger index statDmgDealt   read GetStatistic write SetStatistic;
    property LevelTime        :TRGInteger index statLevelTime  read GetStatistic write SetStatistic;
    property MonstersExploded :TRGInteger index statExploded   read GetStatistic write SetStatistic;

    property ClassString:string read FClassString write FClassString;
    property Waypoint   :string read FWaypoint;
    property Area       :string read FArea;
  end;

//====================

implementation

resourcestring
  sLoadFailed   = 'Savegame loading failed';
  sSavingFailed = 'Savegame saving failed';
  sWrongSize    = 'Wrong file size';
  sWrongVersion = 'Wrong save file version';
  sWrongFooter  = 'Wrong save file size';

//----- support functions -----

procedure Decode(inbuf:pByte; asize:cardinal; amodern:boolean=true);
var
  loIndex,hiIndex:cardinal;
  i:integer;
  loByte,hiByte:byte;
  flag:boolean;
begin
  loIndex:=0;
  hiIndex:=asize-1;
  if amodern then
    while loIndex<=hiIndex do
    begin
      loByte:=byte((cardinal(inbuf[loIndex]) shr 4) or ((cardinal(inbuf[hiIndex]) shl 4)));
      hiByte:=byte((cardinal(inbuf[loIndex]) shl 4) or ((cardinal(inbuf[hiIndex]) shr 4)));

      if (loByte<>0) and (loByte<>$FF) then loByte:=loByte xor $FF;
      if (hiByte<>0) and (hiByte<>$FF) then hiByte:=hiByte xor $FF;

      inbuf[loIndex]:=loByte;
      inbuf[hiIndex]:=hiByte;

      inc(loIndex);
      dec(hiIndex);
    end
  else
  begin
    flag:=true;
    for i:=0 to asize-1 do
    begin
      if flag then
      begin
        loByte:=inbuf[loIndex];
        inc(loIndex);
      end
      else
      begin
        loByte:=inbuf[hiIndex];
        dec(hiIndex);
      end;
      if (loByte<>0) and (loByte<>$FF) then loByte:=loByte xor $FF;
      inbuf[i]:=loByte;

      flag:=not flag;
    end;
  end;
end;

procedure Encode(inbuf:pByte; asize:cardinal);
var
  loIndex,hiIndex:cardinal;
  loByte,hiByte:byte;
begin
  loIndex:=0;
  hiIndex:=asize-1;
  while loIndex<=hiIndex do
  begin
    loByte:=inbuf[loIndex]; if (loByte<>0) and (loByte<>$FF) then loByte:=loByte xor $FF;
    hiByte:=inbuf[hiIndex]; if (hiByte<>0) and (hiByte<>$FF) then hiByte:=hiByte xor $FF;

    inbuf[loIndex]:=byte((cardinal(loByte) shl 4) or ((cardinal(hiByte) shr 4)));
    inbuf[hiIndex]:=byte((cardinal(loByte) shr 4) or ((cardinal(hiByte) shl 4)));

    inc(loIndex);
    dec(hiIndex);
  end;
end;

//----- Get/Set methods -----

function TTLSaveFile.GetGameVersion:integer;
begin
  if FVersion=tlsaveTL1 then result:=verTL1 else result:=verTL2;
end;

function TTLSaveFile.GetPetCount:integer;
begin
  result:=Length(FPetInfos);
end;

function TTLSaveFile.GetMapCount:integer;
begin
  result:=Length(FMaps);
end;

function TTLSaveFile.GetMap(idx:integer):TTL2Map;
begin
  if (idx>=0) and (idx<Length(FMaps)) then
    result:=FMaps[idx]
  else
    result:=nil;
end;

function TTLSaveFile.GetStatistic(idx:integer):TRGInteger;
begin
  if (idx>=0) and (idx<StatsCountTL2) then
    result:=FStatistic[idx]
  else if idx<0 then
    result:=StatsCountTL2
  else
    result:=0;
end;

procedure TTLSaveFile.SetStatistic(idx:integer; aval:TRGInteger);
begin
  if (idx>=0) and (idx<StatsCountTL2) then
    FStatistic[idx]:=aval;
end;

function TTLSaveFile.GetMovie(idx:integer):TL2IdVal;
begin
  if (idx>=0) and (idx<Length(FMovies)) then
    result:=FMovies[idx]
  else
  begin
    result.id   :=RGIdEmpty;
    result.value:=0;
  end;
end;

function TTLSaveFile.GetKeyMapping(idx:integer):TTL2KeyMapping;
begin
  if (idx>=0) and (idx<Length(FKeyMapping)) then
    result:=FKeyMapping[idx]
  else
  begin
    result.id      :=RGIdEmpty;
    result.datatype:=0;
    result.key     :=0;
  end;
end;

function TTLSaveFile.GetPetInfo(idx:integer):TTLCharacter;
begin
  if (idx>=0) and (idx<Length(FPetInfos)) then
    result:=FPetInfos[idx]
  else
    result:=nil;
end;

//----- Read data -----

procedure TTLSaveFile.ReadKeyMappingList;
var
  lid:TRGID;
  i,lcnt,lcnt1:integer;
begin
  lcnt:=FStream.ReadWord;
  SetLength(FKeyMapping,lcnt);

  if FVersion>=tlsaveTL2Minimal then
  begin
    if lcnt>0 then
      FStream.Read(FKeyMapping[0],lcnt*SizeOf(TTL2KeyMapping));
  end
  else
  begin
    // TL1 skills only
    for i:=0 to lcnt-1 do
    begin
      lid:=TRGID(FStream.ReadQWord);
      if lid<>-1 then
      begin
        FKeyMapping[i].id      :=lid;
        FKeyMapping[i].datatype:=2;
      end
      else
        FKeyMapping[i].datatype:=1;
      FKeyMapping[i].key:=i;
    end;
  end;
  // F## keys, 12 for PC
  lcnt1:=FStream.ReadWord;
  SetLength(FFunctions,lcnt1);
  if lcnt1>0 then
    FStream.Read(FFunctions[0],lcnt1*SizeOf(TTL2Function));

  // potion etc
  if FVersion<tlsaveTL2Minimal then
  begin
    lcnt1:=FStream.ReadWord;
    if lcnt1>lcnt then
    begin
      DbgLn('KeyMapping: '+IntToStr(lcnt1)+' items for '+IntToStr(lcnt)+' Skilled keys');
      lcnt1:=lcnt;
    end;

    // TL1 items only
    for i:=0 to lcnt1-1 do
    begin
      lid:=TRGID(FStream.ReadQWord);
      if lid<>-1 then
      begin
        FKeyMapping[i].id      :=lid;
        FKeyMapping[i].datatype:=0;
      end;
    end;
  end;

end;

procedure TTLSaveFile.ReadModList(var ml:TTL2ModList);
var
  i,lcnt:integer;
begin
  lcnt:=FStream.ReadDWord;

  SetLength(ml,lcnt);
  for i:=0 to lcnt-1 do
  begin
    FStream.Read(ml[i].id,8);
    if FVersion>=$44 then
      FStream.Read(ml[i].version,2);
  end;

//  if lcnt>0 then FStream.Read(ml[0],lcnt*SizeOf(TTL2Mod));
end;

function TTLSaveFile.ReadStatistic():boolean;
var
  lcnt:cardinal;
begin
  if FVersion>=tlsaveTL2Minimal then
  begin
    lcnt:=FStream.ReadDWord;
    if lcnt>=StatsCountTL2 then // SizeOf(FStatistic) div SizeOf(TRGInteger)
    begin
      result:=true;
      FStream.Read(FStatistic,SizeOf(FStatistic));
      // unknown statistic
      if lcnt>StatsCountTL2 then
        FStream.Seek(lcnt*SizeOf(TRGInteger)-SizeOf(FStatistic),soCurrent);
    end
    else
      result:=false;
  end
  else
  begin
    FStream.Read(FStatistic,StatsCountTL1*SizeOf(DWord));
  end;
end;

//----- Write data -----

procedure TTLSaveFile.WriteKeyMappingList;
var
  lid:TRGID;
  i,lcnt:integer;
begin
  lcnt:=Length(FKeyMapping);
  FStream.WriteWord(lcnt);
  if lcnt>0 then
    if FVersion>=tlsaveTL2Minimal then
      FStream.Write(FKeyMapping[0],lcnt*SizeOf(TTL2KeyMapping))
    else
    begin
      for i:=0 to lcnt-1 do
      begin
        if KeyMapping[i].datatype=2 then
          lid:=KeyMapping[i].id
        else
          lid:=TRGID(-1);
        FStream.WriteQWord(QWord(lid));
      end;
    end;

  i:=Length(FFunctions);
  FStream.WriteWord(i);
  if i>0 then
    FStream.Write(FFunctions[0],i*SizeOf(TTL2Function));

  if FVersion<tlsaveTL2Minimal then
  begin
    FStream.WriteWord(lcnt);
    for i:=0 to lcnt-1 do
    begin
      if KeyMapping[i].datatype=0 then
        lid:=KeyMapping[i].id
      else
        lid:=TRGID(-1);
      FStream.WriteQWord(QWord(lid));
    end;
  end;
end;

procedure TTLSaveFile.WriteModList(ml:TTL2ModList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(ml);
  FStream.WriteDWord(lcnt);

  if lcnt>0 then
    FStream.Write(ml[0],lcnt*SizeOf(TTL2Mod));
end;

procedure TTLSaveFile.WriteStatistic();
begin
  if FVersion>=tlsaveTL2Minimal then
  begin
    FStream.WriteDWord(StatsCountTL2);
    FStream.Write(FStatistic,SizeOf(FStatistic));
  end
  else
    FStream.Write(FStatistic,StatsCountTL1*SizeOf(DWord));
end;

//----- processing -----

function ClearCheatItems(aItems:TTLItemList):boolean;
var
  i,j,k:integer;
  l:TTLEffectList;
begin
  result:=false;
  for i:=0 to High(aItems) do
  begin
    for k:=0 to 2 do
      for j:=0 to High(aItems[i].Effects[k]) do
      begin
        if aItems[i].Effects[k][j].EffectType=TL2Cheat then
        begin
          l:=aItems[i].Effects[k];
          aItems[i].Effects[k][j].Free;
          Delete(l,j,1);
          aItems[i].Effects[k]:=l;
          result:=true;
          break;
        end;
      end;
  end;
end;

function TTLSaveFile.ClearCheat:boolean;
var
  i:integer;
begin
  result:=false;

  // Character items
  if ClearCheatItems(CharInfo.Items) then
  begin
    CharInfo.Changed:=true;
    result:=true;
  end;
  // Pet items
  for i:=0 to PetCount-1 do
    if ClearCheatItems(PetInfo[i].Items) then
    begin
      PetInfo[i].Changed:=true;
      result:=true;
    end;
end;

{$I TLSGParse.inc}
{$I TLSGPrepare.inc}

function TTLSaveFile.FixItems(aItems:TTLItemList):boolean;
var
  i:integer;
begin
  result:=false;
  for i:=0 to High(aItems) do
  begin
    if aItems[i].ModIds<>nil then
    begin
      if aItems[i].CheckForMods(BoundMods) then
      begin
        if aItems[i].Changed then result:=true;
      end;
    end;
  end;
end;

function TTLSaveFile.FixModdedItems:boolean;
var
  i:integer;
begin
  result:=false;
  // Character items
  if FixItems(CharInfo.Items) then
  begin
    CharInfo.Changed:=true;
    result:=true;
  end;
  // Pet items
  for i:=0 to PetCount-1 do
    if FixItems(PetInfo[i].Items) then
    begin
      PetInfo[i].Changed:=true;
      result:=true;
    end;
end;

//===== Global savegame class things =====

function TTLSaveFile.LoadFromFile(const aname:string):boolean;
var
  lchecksum,lsize:dword;
  lscramble:byte;
begin
  result:=false;

  if FStream<>nil then
    FStream.Free;

  FStream:=TMemoryStream.Create;
  try
    TMemoryStream(FStream).LoadFromFile(aname);

    if FStream.Size<6 then
    begin
      RGLog.Add(sWrongSize);
      Exit;
    end;

    FStream.Read(FVersion,4);
{
    if (FVersion<tl2saveMinimal) or (FVersion>tl2saveCurrent) then
    begin
      RGLog.Add(sWrongVersion);
      Exit;
    end;
}
    if FVersion>=tlsaveTL2Encoded  then FStream.Read(lscramble,1) else lscramble:=0;
    if FVersion>=tlsaveTL2Checksum then FStream.Read(lchecksum,4) else lchecksum:=0;

    FDataStart:=FStream.Position;
    
    FStream.Seek(-4,soEnd);
    FStream.Read(lsize,4);

    if lsize<>FStream.Size then
    begin
      RGLog.Add(sWrongFooter);
      Exit;
    end;
    
    if lscramble<>0 then
      Decode(TMemoryStream(FStream).Memory+FDataStart,
                           FStream .Size  -FDataStart-SizeOf(lsize),
                           FVersion>=tlsaveTL2Scramble);

    result:=true;
  except
    RGLog.Add(sLoadFailed);
  end;
end;

procedure TTLSaveFile.SaveToFile(const aname:string; aencoded:boolean=false);
var
  lsout:TMemoryStream;
  lpos:SizeInt;
  lchecksum,lsize:dword;
begin
  if FVersion>=tlsaveTL2Minimal then
    FVersion:=tlsaveTL2
  else
    FVersion:=tlsaveTL1;

  lsout:=TMemoryStream.Create;
  try
    try
      lsout.Write(FVersion,4);
      if FVersion>=tlsaveTL2Encoded  then lsout.Write(ORD(aencoded),1);
      if FVersion>=tlsaveTL2Checksum then
      begin
        lchecksum:=CalcCheckSum(
          TMemoryStream(FStream).Memory+FDataStart,
                        FStream .Size  -FDataStart-4);
        lsout.Write(lchecksum,4);
      end;
      lpos:=lsout.Position;
{data}
      FStream.Position:=FDataStart;
      lsout.CopyFrom(FStream,FStream.Size-FDataStart-4);
{}
      // Modern only
      if aencoded and (FVersion>=tlsaveTL2Encoded) then
        Encode(lsout.Memory+lpos,
               lsout.Size  -lpos-4);

      lsize:=lsout.Size+4;
      lsout.Write(lsize,4);

      lsout.SaveToFile(aname);
    except
      RGLog.Add(sSavingFailed);
    end;
  finally
    lsout.Free;
  end;
end;

procedure TTLSaveFile.Clear;
var
  i:integer;
begin
  FStream.Free;

  SetLength(FMovies,0);

  SetLength(FBoundMods       ,0);
  SetLength(FRecentModHistory,0);
  SetLength(FFullModHistory  ,0);

  FCharInfo.Free;

  SetLength(FKeyMapping,0);
  SetLength(FFunctions ,0);
  SetLength(FCinematics,0);

  FreeMem(FUnknown1);

  for i:=0 to High(FPetInfos) do
    if FPetInfos[i]<>nil then FPetInfos[i].Free;
  SetLength(FPetInfos,0);

  FreeMem(FUnknown2);

  for i:=0 to High(FMaps) do
    if FMaps[i]<>nil then FMaps[i].Free;
  SetLength(FMaps,0);

  FreeMem(FUnknown3);

  FQuests.Free;

  SetLength(FRecipes,0);

  FLastBlock.Free;
end;

constructor TTLSaveFile.Create;
begin
  inherited;

  FStream:=nil;
end;

destructor TTLSaveFile.Destroy;
begin
  Clear;

  inherited;
end;

end.
