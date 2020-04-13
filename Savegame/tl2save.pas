unit tl2save;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2types,
  tl2map,
  tl2char;

// these types used just in this unit ("global" save file data)
type
  TTL2Difficulty = (Casual, Normal, Veteran, Expert);

type
  TTL2Mod = packed record
    id     :QWord;
    version:word;
  end;
  TTL2ModList = array of TTL2Mod;

type
  TTL2Function = packed record
    id :TL2ID;
    unk:TL2ID;
  end;
  TTL2FunctionList = array of TTL2Function;
type
  TTL2KeyMapping = packed record
    id      :TL2ID;
    datatype:byte;   // (0=item, 2-skill)
    key     :word;   // or byte, (byte=3 or 0 for quick keys)
  end;
  TTL2KeyMappingList = array of TTL2KeyMapping;

const
  StatsCount = 22;

type
  TTL2Statistic = packed record
    statTotalTime  :TL2UInteger; // total time in game, msec
    statGold       :TL2Integer ; // gold collected
    statDifficulty :TL2Integer ; // difficulty
    statSteps      :TL2Integer ; // steps done
    statTasks      :TL2Integer ; // tasks (quests) done
    statDeaths     :TL2Integer ; // number of deaths
    statMobs       :TL2Integer ; // mobs killed
    statHeroes     :TL2Integer ; // heroes killed
    statSkills     :TL2Integer ; // skills used
    statTreasures  :TL2Integer ; // hidden treasures opened
    statTraps      :TL2Integer ; // traps activated
    statBroken     :TL2Integer ; // items broken
    statPotions    :TL2Integer ; // potions used
    statPortal     :TL2Integer ; // portals opened
    statFish       :TL2Integer ; // fish catched
    statGambled    :TL2Integer ; // time gambled
    statCharmed    :TL2Integer ; // items charmed
    statTransform  :TL2Integer ; // items transformed
    statDmgObtained:TL2Integer ; // max.damage obtained
    statDamage     :TL2Integer ; // max damage made
    statLevelTime  :TL2UInteger; // time on map, msec ?? last ingame time, msec
    statExploded   :TL2Integer ; // mobs blasted
  end;
const
  RealStatsCount = SizeOf(TTL2Statistic) div SizeOf(TL2Integer);

type
  TTL2SaveFile = class
  //--- common part
  private
    FStream:TTL2Stream;
    FChanged:boolean;

    procedure Error(const atext:string);
  public
    constructor Create;
    destructor Destroy; override;

{
    Out: FStream with Header, decoded data, footer
}
    procedure LoadFromFile(const aname:string);
    procedure SaveToFile  (const aname:string; aencoded:boolean=false);

    function  Parse(amode:TTL2ParseType):boolean;
    function  Prepare:boolean;

  //--- TL2 save part
  private

    //--- Blocks
    FLastBlock :PByte;
    FQuestBlock:PByte;
    FUnknown1  :PByte;
    FUnknown2  :PByte;
    FUnknown3  :PByte;
    FQBlockSize:integer;
    FUnkn3Size :integer;
    FLBlockSize:integer;
    
    FCharInfo:TTL2Character;
    FPetInfos:array of TTL2Character;

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

    FMovies    :TL2IdValList;
    FRecipes   :TL2IdList;
    FHistory   :TL2IdList;
    FMaps      :TTL2MapList;

    FStatistic :TTL2Statistic; // OR we can just keep pointer to buffer

    FMap :string;
    FArea:string;

    Unk1,Unk2:DWord;
    
    function  ReadStatistic():boolean;
    procedure ReadModList(var ml:TTL2ModList);
    procedure ReadKeyMappingList;

    procedure WriteKeyMappingList;
    procedure WriteModList(ml:TTL2ModList);
    procedure WriteStatistic();

    function  GetPetInfo   (idx:integer):TTL2Character;
    function  GetKeyMapping(idx:integer):TTL2KeyMapping;
    function  GetMovie     (idx:integer):TL2IdVal;
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
    property PetInfo[idx:integer]:TTL2Character read GetPetInfo;

    property Movie     [idx:integer]:TL2IdVal       read GetMovie;
    property KeyMapping[idx:integer]:TTL2KeyMapping read GetKeyMapping;

    property Statistic:TTL2Statistic read FStatistic;

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
  // statistic
  rsTotalTime   = 'total time in game, msec';
  rsGold        = 'gold collected';
  rsDifficulty  = 'difficulty';
  rsSteps       = 'steps done';
  rsTasks       = 'tasks (quests) done';
  rsDeaths      = 'number of deaths';
  rsMobs        = 'mobs killed';
  rsHeroes      = 'heroes killed';
  rsSkills      = 'skills used';
  rsTreasures   = 'hidden treasures opened';
  rsTraps       = 'traps activated';
  rsBroken      = 'items broken';
  rsPotions     = 'potions used';
  rsPortal      = 'portals opened';
  rsFish        = 'fish catched';
  rsGambled     = 'time gambled';
  rsCharmed     = 'items charmed';
  rsTransform   = 'items transformed';
  rsDmgObtained = 'max.damage obtained';
  rsDamage      = 'max damage made';
  rsLevelTime   = 'time on map, msec';
  rsExploded    = 'mobs exploded';

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

//----- Save/load -----

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
  if (idx>=0) and (idx<Length(FKeyMapping)) then
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
begin
  if IsConsole then
  begin
    writeln('Statistic'#13#10+
            '---------');
    with FStatistic do
    begin
      writeln(rsTotalTime  ,': ',MSecToTime(statTotalTime)); // total time in game, msec
      writeln(rsGold       ,': ',statGold       ); // gold collected
      writeln(rsDifficulty ,': ',statDifficulty ); // difficulty
      writeln(rsSteps      ,': ',statSteps      ); // steps done
      writeln(rsTasks      ,': ',statTasks      ); // tasks (quests) done
      writeln(rsDeaths     ,': ',statDeaths     ); // number of deaths
      writeln(rsMobs       ,': ',statMobs       ); // mobs killed
      writeln(rsHeroes     ,': ',statHeroes     ); // heroes killed
      writeln(rsSkills     ,': ',statSkills     ); // skills used
      writeln(rsTreasures  ,': ',statTreasures  ); // hidden treasures opened
      writeln(rsTraps      ,': ',statTraps      ); // traps activated
      writeln(rsBroken     ,': ',statBroken     ); // items broken
      writeln(rsPotions    ,': ',statPotions    ); // potions used
      writeln(rsPortal     ,': ',statPortal     ); // portals opened
      writeln(rsFish       ,': ',statFish       ); // fish catched
      writeln(rsGambled    ,': ',statGambled    ); // time gambled
      writeln(rsCharmed    ,': ',statCharmed    ); // items charmed
      writeln(rsTransform  ,': ',statTransform  ); // items transformed
      writeln(rsDmgObtained,': ',statDmgObtained); // max.damage obtained
      writeln(rsDamage     ,': ',statDamage     ); // max damage made
      writeln(rsLevelTime  ,': ',MSecToTime(statLevelTime)); // time on map, msec ?? last ingame time, msec
      writeln(rsExploded   ,': ',statExploded   ); // mobs exploded
    end;
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
  FChanged:=false;
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
{
  if not FChanged then
  begin
    PTL2SaveHeader(FStream.Memory)^:=0;
    // header.encoded MUST BE cleared
    FStream.SaveToFile(aname);
    exit;
  end;
}
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

constructor TTL2SaveFile.Create;
begin
  inherited;

  FStream:=nil;
end;

destructor TTL2SaveFile.Destroy;
var
  i:integer;
begin
  FStream.Free;

  if FCharInfo<>nil then FCharInfo.Free;

  for i:=0 to High(FPetInfos) do
    if FPetInfos[i]<>nil then FPetInfos[i].Free;
  SetLength(FPetInfos,0);

  FreeMem(FUnknown1);

  SetLength(FBoundMods       ,0);
  SetLength(FRecentModHistory,0);
  SetLength(FFullModHistory  ,0);

  SetLength(FKeyMapping,0);
  SetLength(FFunctions ,0);
  SetLength(FMovies    ,0);
  SetLength(FRecipes   ,0);

  for i:=0 to High(FMaps) do
    if FMaps[i]<>nil then FMaps[i].Free;
  SetLength(FMaps,0);

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
