unit tl2save;

interface

uses
  classes,
  tl2statistic,
  tl2stream,
  tl2common,
  tl2types,
  tl2map,
  tl2quest,
  tl2stats,
  tl2char;

type
  TTL2SaveFile = class
  //--- common part
  private
    FStream:TTL2Stream;

    procedure Error(const atext:string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

{
    Out: FStream with Header, decoded data, footer
}
    procedure LoadFromFile(const aname:string);
    procedure SaveToFile  (const aname:string; aencoded:boolean=false);

    function  Parse():boolean;
    function  Prepare:boolean;

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
    FDifficulty  :TTL2Difficulty;
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

    FMap :string;
    FArea:string;

    Unk1,Unk2,Unk3:DWord;
    UnkCoord:TL2Coord;

    //----- User portal -----

    FPortalOpened:ByteBool;
    FPortalCoord :TL2Coord;
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

    function  GetStatistic (idx:integer):TL2Integer;
    procedure SetStatistic (idx:integer; aval:TL2Integer);
  public
    procedure DumpStatistic;
    procedure DumpKeyMapping;
    procedure DumpModList(const acomment:string; alist:TTL2ModList);
    
    property Difficulty  :TTL2Difficulty read FDifficulty   write FDifficulty;
    property Hardcore    :boolean        read FHardcore     write FHardcore;
    property NewGameCycle:integer        read FNewGameCycle write FNewGameCycle;
    property GameTime    :single         read FGameTime     write FGameTime; //!! control!!

    property BoundMods       :TTL2ModList read FBoundMods;
    property RecentModHistory:TTL2ModList read FRecentModHistory;
    property FullModHistory  :TTL2ModList read FFullModHistory;

    property CharInfo:TTL2Character read FCharInfo;
    property PetCount:integer read GetPetCount;
    property PetInfo[idx:integer]:TTL2Character read GetPetInfo;

    property MapCount:integer read GetMapCount;
    property Maps[idx:integer]:TTL2Map read GetMap;

    property Recipes:TL2IdList read FRecipes;

    property Movies    :TL2IdValList          read FMovies;
    property Movie     [idx:integer]:TL2IdVal read GetMovie;

    property KeyMapping[idx:integer]:TTL2KeyMapping read GetKeyMapping;
    property Keys     :TTL2KeyMappingList read FKeyMapping;
    property Functions:TTL2FunctionList   read FFunctions;

    property Quests:TTL2Quest read FQuests;
    property Stats :TTL2Stats read FLastBlock;

    // Statistic
    property Statistic[idx:integer]:TL2Integer read GetStatistic write SetStatistic;
    
    property TimePlayed       :TL2Integer index statTotalTime  read GetStatistic write SetStatistic;
    property GoldGathered     :TL2Integer index statGold       read GetStatistic write SetStatistic;
//    property GameDifficulty   :TL2Integer index statDifficulty read GetStatistic write SetStatistic;
    property StepsTaken       :TL2Integer index statSteps      read GetStatistic write SetStatistic;
    property QuestsDone       :TL2Integer index statQuests     read GetStatistic write SetStatistic;
    property Deaths           :TL2Integer index statDeaths     read GetStatistic write SetStatistic;
    property MonstersKilled   :TL2Integer index statMonsters   read GetStatistic write SetStatistic;
    property ChampionsKilled  :TL2Integer index statChampions  read GetStatistic write SetStatistic;
    property SkillsUsed       :TL2Integer index statSkills     read GetStatistic write SetStatistic;
    property LootablesLooted  :TL2Integer index statTreasures  read GetStatistic write SetStatistic;
    property TrapsSprung      :TL2Integer index statTraps      read GetStatistic write SetStatistic;
    property BreakablesBroken :TL2Integer index statBroken     read GetStatistic write SetStatistic;
    property PotionsUsed      :TL2Integer index statPotions    read GetStatistic write SetStatistic;
    property PortalsUsed      :TL2Integer index statPortals    read GetStatistic write SetStatistic;
    property FishCaught       :TL2Integer index statFish       read GetStatistic write SetStatistic;
    property TimesGambled     :TL2Integer index statGambled    read GetStatistic write SetStatistic;
    property ItemsEnchanted   :TL2Integer index statEnchanted  read GetStatistic write SetStatistic;
    property ItemsTransmuted  :TL2Integer index statTransmuted read GetStatistic write SetStatistic;
    property DamageTaken      :TL2Integer index statDmgTaken   read GetStatistic write SetStatistic;
    property DamageDealt      :TL2Integer index statDmgDealt   read GetStatistic write SetStatistic;
    property LevelTime        :TL2Integer index statLevelTime  read GetStatistic write SetStatistic;
    property MonstersExploded :TL2Integer index statExploded   read GetStatistic write SetStatistic;

    property ClassString:string read FClassString;
    property Map        :string read FMap;
    property Area       :string read FArea;
  end;

//====================

implementation

uses
  sysutils,
  tl2db;

resourcestring
  sLoadFailed   = 'Savegame loading failed';
  sSavingFailed = 'Savegame saving failed';
  sWrongSize    = 'Wrong file size';
  sWrongVersion = 'Wrong save file signature';
  sWrongFooter  = 'Wrong save file size';

//----- support functions -----

procedure Decode(inbuf:pByte; asize:cardinal);
var
  loIndex,hiIndex:cardinal;
  loByte,hiByte:byte;
begin
  loIndex:=0;
  hiIndex:=asize-1;
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

function TTL2SaveFile.GetStatistic(idx:integer):TL2Integer;
begin
  if (idx>=0) and (idx<StatsCount) then
    result:=FStatistic[idx]
  else if idx<0 then
    result:=StatsCount
  else
    result:=0;
end;

procedure TTL2SaveFile.SetStatistic(idx:integer; aval:TL2Integer);
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
    result.id   :=TL2IdEmpty;
    result.value:=0;
  end;
end;

function TTL2SaveFile.GetKeyMapping(idx:integer):TTL2KeyMapping;
begin
  if (idx>=0) and (idx<Length(FKeyMapping)) then
    result:=FKeyMapping[idx]
  else
  begin
    result.id      :=TL2IdEmpty;
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

//----- Dumps -----

procedure TTL2SaveFile.DumpKeyMapping;
var
  i:integer;
begin
  if IsConsole then
  begin
    if Length(FKeyMapping)>0 then
    begin
      writeln('Key Mapping'#13#10+
              '-----------');
      for i:=0 to High(FKeyMapping) do
        with FKeyMapping[i] do
        begin
          if      datatype=0 then writeln(GetTL2Item (id),'  item  ' ,GetTL2KeyType(key))
          else if datatype=2 then writeln(GetTL2Skill(id),'  skill  ',GetTL2KeyType(key))
          else                    writeln(GetTL2Skill(id),'  ['+inttostr(datatype)+']  ',GetTL2KeyType(key));
        end;
      writeln;
    end;
    if Length(FFunctions)>0 then
    begin
      writeln('Functions'#13#10+
              '---------');
      for i:=0 to High(FFunctions) do
        with FFunctions[i] do
        begin
          if id<>TL2IdEmpty then writeln('F',i+1,' - ',GetTL2Skill(id));
        end;
    end;
  end;
end;

procedure TTL2SaveFile.DumpModList(const acomment:string; alist:TTL2ModList);
var
  i,lver:integer;
begin
  if IsConsole then
    if Length(alist)>0 then
    begin
      writeln(acomment,#13#10+
              '-----------');
      for i:=0 to High(alist) do
        with alist[i] do
        begin
          writeln(GetTL2Mod(id,lver),' v.',version);
        end;
      writeln;
    end;
end;

procedure TTL2SaveFile.DumpStatistic;
var
  i:integer;
begin
  if IsConsole then
  begin
    writeln('Statistic'#13#10+
            '---------');
    for i:=0 to StatsCount-1 do
      writeln(GetStatDescr(i)+': '+GetStatText(i,FStatistic[i]));
  end;
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
  if lcnt>=StatsCount then // SizeOf(FStatistic) div SizeOf(TL2Integer)
  begin
    result:=true;
    FStream.Read(FStatistic,SizeOf(FStatistic));
    // unknown statistic
    if lcnt>StatsCount then
      FStream.Seek(lcnt*SizeOf(TL2Integer)-SizeOf(FStatistic),soCurrent);
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

{$I TL2Parse.inc}

{$I TL2Prepare.inc}

//===== Global savegame class things =====

procedure TTL2SaveFile.LoadFromFile(const aname:string);
var
  lSaveHeader:TL2SaveHeader;
  lSaveFooter:TL2SaveFooter;
begin
  if FStream<>nil then
    FreeAndNil(FStream);

  FStream:=TTL2Stream.Create;
  try
    FStream.LoadFromFile(aname);

    if FStream.Size<(SizeOf(lSaveHeader)+SizeOf(lSaveFooter)) then
      Error(sWrongSize);

    FStream.Read(lSaveHeader,SizeOf(lSaveHeader));
    if lSaveHeader.Sign<>$44 then
      Error(sWrongVersion);

    FStream.Seek(-SizeOf(lSaveFooter),soEnd);
    FStream.Read(lSaveFooter,SizeOf(lSaveFooter));

    if lSaveFooter.filesize<>FStream.Size then
      Error(sWrongFooter);
    
    if lSaveHeader.Encoded then
      Decode(FStream.Memory+ SizeOf(lSaveHeader),
             FStream.Size  -(SizeOf(lSaveHeader)+SizeOf(lSaveFooter)));
  except
    Error(sLoadFailed);
  end;
end;

procedure TTL2SaveFile.SaveToFile(const aname:string; aencoded:boolean=false);
type
  PTL2SaveHeader = ^TL2SaveHeader;
var
  lsout:TMemoryStream;
  lSaveHeader:TL2SaveHeader;
  lSaveFooter:TL2SaveFooter;
begin
  lSaveHeader.Sign    :=$44;
  lSaveHeader.Encoded :=aencoded;
  lSaveHeader.Checksum:=CalcCheckSum(
    FStream.Memory+SizeOf(lSaveHeader),
    FStream.Size-(SizeOf(lSaveHeader)+SizeOf(lSaveFooter)));

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

  Free;
  Halt;
end;

end.
