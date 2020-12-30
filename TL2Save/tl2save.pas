unit tl2save;

interface

uses
  classes,
  tl2statistic,
  rgstream,
  tl2common,
  rgglobal,
  tl2map,
  tl2item,
  tl2effects,
  tl2quest,
  tl2stats,
  tl2char;

type
  TTL2SaveFile = class
  //--- common part
  private
    FStream:TStream;

    procedure Error(const atext:string);
    function FixItems(aItems:TTL2ItemList):boolean;
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

    //--- Blocks
    FLastBlock :TTL2Stats;

    FUnknown1  :PByte;
    FUnknown2  :PByte;
    FUnknown3  :PByte;
    FUnkn3Size :integer;
    
    FCharInfo:TTL2Character;
    FPetInfos:TTL2CharArray;

    FClassString :string;
    FDifficulty  :TL2Difficulty;
    FHardcore    :boolean;
    FNewGameCycle:integer;
    FGameTime    :single;

    FBoundMods       :TTL2ModList;
    FRecentModHistory:TTL2ModList;
    FFullModHistory  :TTL2ModList;

    FKeyMapping:TTL2KeyMappingList;
    FFunctions :TTL2FunctionList;

    FQuests:TTL2Quest;

    FMovies    :TL2IdValList;
    FRecipes   :TL2IdList;
    FHistory   :TL2IdList;
    FMaps      :TTL2MapList;

    FStatistic :TTL2Statistic; // OR we can just keep pointer to buffer

    FWaypoint:string;
    FArea    :string;

    Unk1     :byte;
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
    function  GetPetInfo   (idx:integer):TTL2Character;
    function  GetKeyMapping(idx:integer):TTL2KeyMapping;
    function  GetMovie     (idx:integer):TL2IdVal;
    function  GetMap       (idx:integer):TTL2Map;

    function  GetStatistic (idx:integer):TRGInteger;
    procedure SetStatistic (idx:integer; aval:TRGInteger);
  public
    property Difficulty  :TL2Difficulty  read FDifficulty   write FDifficulty;
    property Hardcore    :boolean        read FHardcore     write FHardcore;
    property NewGameCycle:integer        read FNewGameCycle write FNewGameCycle;
    property GameTime    :single         read FGameTime     write FGameTime; //!! control!!

    property BoundMods       :TTL2ModList read FBoundMods         write FBoundMods;
    property RecentModHistory:TTL2ModList read FRecentModHistory  write FRecentModHistory;
    property FullModHistory  :TTL2ModList read FFullModHistory    write FFullModHistory;

    property CharInfo:TTL2Character read FCharInfo;
    property PetCount:integer read GetPetCount;
    property PetInfo[idx:integer]:TTL2Character read GetPetInfo;

    property MapCount:integer read GetMapCount;
    property Maps[idx:integer]:TTL2Map read GetMap;

    property History:TL2IdList read FHistory write FHistory;
    property Recipes:TL2IdList read FRecipes write FRecipes;

    property Movies    :TL2IdValList          read FMovies;
    property Movie     [idx:integer]:TL2IdVal read GetMovie;

    property KeyMapping[idx:integer]:TTL2KeyMapping read GetKeyMapping;
    property Keys     :TTL2KeyMappingList read FKeyMapping;
    property Functions:TTL2FunctionList   read FFunctions;

    property Quests:TTL2Quest read FQuests;
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
(*
    t = 0;
    l_flag = 1;
    if ( l_datasize )
    {
      l_enddata = &l_indata[l_datasize - 1];
      l_start = l_indata;
      do
      {
        if ( l_flag )
          l_byte = *l_start++;
        else
          l_byte = *l_enddata--;
        buf[t] = l_byte;
        if ( l_byte && l_byte != -1 )
          buf[t] = ~l_byte;
        l_flag = !l_flag;
        ++t;
      }
      while ( t < l_datasize );
    }
*)
(*
    t = 0;
    l_flag = true;
    if (_Size != NULL) {
      l_end = _DstBuf + _Size + -0x1;
      l_start = _DstBuf;
      do {
        if (l_flag) {
          l_byte = *l_start;
          l_start = l_start + 0x1;
        }
        else {
          l_byte = *l_end;
          l_end = l_end + -0x1;
        }
        buf[_Dst] = l_byte;
        if ((l_byte != 0x0) && (l_byte != 0xff)) {
          buf[_Dst] = ~l_byte;
        }
        l_flag = l_flag == false;
        t = t + 0x1;
      } while (t < _Size);
    }
*)
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

function CalcCheckSum(aptr:pByte; asize:cardinal):longword;
var
  i:cardinal;
begin
  result:=$14D3;

  for i:=0 to asize-1 do
  begin
    {$PUSH}
    {$Q-}
    result:=result+(result shl 5)+aptr[i];
    {$POP}
  end;
end;

//----- Get/Set methods -----

function TTL2SaveFile.GetPetCount:integer;
begin
  result:=Length(FPetInfos);
end;

function TTL2SaveFile.GetMapCount:integer;
begin
  result:=Length(FMaps);
end;

function TTL2SaveFile.GetMap(idx:integer):TTL2Map;
begin
  if (idx>=0) and (idx<Length(FMaps)) then
    result:=FMaps[idx]
  else
    result:=nil;
end;

function TTL2SaveFile.GetStatistic(idx:integer):TRGInteger;
begin
  if (idx>=0) and (idx<StatsCount) then
    result:=FStatistic[idx]
  else if idx<0 then
    result:=StatsCount
  else
    result:=0;
end;

procedure TTL2SaveFile.SetStatistic(idx:integer; aval:TRGInteger);
begin
  if (idx>=0) and (idx<StatsCount) then
    FStatistic[idx]:=aval;
end;

function TTL2SaveFile.GetMovie(idx:integer):TL2IdVal;
begin
  if (idx>=0) and (idx<Length(FMovies)) then
    result:=FMovies[idx]
  else
  begin
    result.id   :=RGIdEmpty;
    result.value:=0;
  end;
end;

function TTL2SaveFile.GetKeyMapping(idx:integer):TTL2KeyMapping;
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

function TTL2SaveFile.GetPetInfo(idx:integer):TTL2Character;
begin
  if (idx>=0) and (idx<Length(FPetInfos)) then
    result:=FPetInfos[idx]
  else
    result:=nil;
end;

//----- Read data -----

procedure TTL2SaveFile.ReadKeyMappingList;
var
  lcnt:cardinal;
begin
  lcnt:=FStream.ReadWord;
  SetLength(FKeyMapping,lcnt);
  if lcnt>0 then
    FStream.Read(FKeyMapping[0],lcnt*SizeOf(TTL2KeyMapping));

  // F## keys, 12 for PC
  lcnt:=FStream.ReadWord;
  SetLength(FFunctions,lcnt);
  if lcnt>0 then
    FStream.Read(FFunctions[0],lcnt*SizeOf(TTL2Function));
end;

procedure TTL2SaveFile.ReadModList(var ml:TTL2ModList);
var
  lcnt:cardinal;
begin
  lcnt:=FStream.ReadDWord;

  SetLength(ml,lcnt);
  if lcnt>0 then
    FStream.Read(ml[0],lcnt*SizeOf(TTL2Mod));
end;

function TTL2SaveFile.ReadStatistic():boolean;
var
  lcnt:cardinal;
begin
  lcnt:=FStream.ReadDWord;
  if lcnt>=StatsCount then // SizeOf(FStatistic) div SizeOf(TRGInteger)
  begin
    result:=true;
    FStream.Read(FStatistic,SizeOf(FStatistic));
    // unknown statistic
    if lcnt>StatsCount then
      FStream.Seek(lcnt*SizeOf(TRGInteger)-SizeOf(FStatistic),soCurrent);
  end
  else
    result:=false;
end;

//----- Write data -----

procedure TTL2SaveFile.WriteKeyMappingList;
var
  lcnt:cardinal;
begin
  lcnt:=Length(FKeyMapping);
  FStream.WriteWord(lcnt);
  if lcnt>0 then
    FStream.Write(FKeyMapping[0],lcnt*SizeOf(TTL2KeyMapping));

  lcnt:=Length(FFunctions);
  FStream.WriteWord(lcnt);
  if lcnt>0 then
    FStream.Write(FFunctions[0],lcnt*SizeOf(TTL2Function));
end;

procedure TTL2SaveFile.WriteModList(ml:TTL2ModList);
var
  lcnt:cardinal;
begin
  lcnt:=Length(ml);
  FStream.WriteDWord(lcnt);

  if lcnt>0 then
    FStream.Write(ml[0],lcnt*SizeOf(TTL2Mod));
end;

procedure TTL2SaveFile.WriteStatistic();
begin
  FStream.WriteDWord(StatsCount);
  FStream.Write(FStatistic,SizeOf(FStatistic));
end;

//----- processing -----

function ClearCheatItems(aItems:TTL2ItemList):boolean;
var
  i,j,k:integer;
  l:TTL2EffectList;
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

function TTL2SaveFile.ClearCheat:boolean;
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

{$I TL2Parse.inc}

{$I TL2Prepare.inc}

function TTL2SaveFile.FixItems(aItems:TTL2ItemList):boolean;
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

function TTL2SaveFile.FixModdedItems:boolean;
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

function TTL2SaveFile.LoadFromFile(const aname:string):boolean;
var
  lSaveHeader:TL2SaveHeader;
  lSaveFooter:TL2SaveFooter;
begin
  result:=false;

  if FStream<>nil then
    FStream.Free;

  FStream:=TMemoryStream.Create;
  try
    TMemoryStream(FStream).LoadFromFile(aname);

    if FStream.Size<(SizeOf(lSaveHeader)+SizeOf(lSaveFooter)) then
    begin
      Error(sWrongSize);
      Exit;
    end;

    FStream.Read(lSaveHeader,SizeOf(lSaveHeader));
    if (lSaveHeader.Version<tl2saveMinimal) or (lSaveHeader.Version>tl2saveCurrent) then
    begin
      Error(sWrongVersion);
      Exit;
    end;

    FStream.Seek(-SizeOf(lSaveFooter),soEnd);
    FStream.Read(lSaveFooter,SizeOf(lSaveFooter));

    if lSaveFooter.filesize<>FStream.Size then
    begin
      Error(sWrongFooter);
      Exit;
    end;
    
    if lSaveHeader.Encoded then
      Decode(TMemoryStream(FStream).Memory+ SizeOf(lSaveHeader),
                           FStream .Size  -(SizeOf(lSaveHeader)+SizeOf(lSaveFooter)));

    result:=true;
  except
    Error(sLoadFailed);
  end;
end;

procedure TTL2SaveFile.SaveToFile(const aname:string; aencoded:boolean=false);
var
  lsout:TMemoryStream;
  lSaveHeader:TL2SaveHeader;
  lSaveFooter:TL2SaveFooter;
begin
  lSaveHeader.Version :=tl2saveCurrent;
  lSaveHeader.Encoded :=aencoded;
  lSaveHeader.Checksum:=CalcCheckSum(
    TMemoryStream(FStream).Memory+ SizeOf(lSaveHeader),
                  FStream .Size  -(SizeOf(lSaveHeader)+SizeOf(lSaveFooter)));

  lsout:=TMemoryStream.Create;
  try
    try
      lsout.Write(lSaveHeader,SizeOf(lSaveHeader));
{data}
      FStream.Position:=SizeOf(lSaveHeader); //!!
      lsout.CopyFrom(FStream,FStream.Size-(SizeOf(lSaveHeader)+SizeOf(lSaveFooter)));
{}
      if aencoded then
        Encode(lsout.Memory+SizeOf(lSaveHeader),
               lsout.Size-(SizeOf(lSaveHeader)+SizeOf(lSaveFooter)));

      lSaveFooter.filesize:=lsout.Size+SizeOf(lSaveFooter);
      lsout.Write(lSaveFooter,SizeOf(lSaveFooter));

      lsout.SaveToFile(aname);
    except
      Error(sSavingFailed);
    end;
  finally
    lsout.Free;
  end;
end;

procedure TTL2SaveFile.Clear;
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

constructor TTL2SaveFile.Create;
begin
  inherited;

  FStream:=nil;
end;

destructor TTL2SaveFile.Destroy;
begin
  Clear;

  inherited;
end;

procedure TTL2SaveFile.Error(const atext:string);
begin
  if IsConsole then
    writeln(atext);
end;

end.
