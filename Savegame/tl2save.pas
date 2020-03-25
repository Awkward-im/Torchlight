unit tl2save;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2char;

// these types used just in this unit ("global" save file data)
type
  TTL2Difficulty = (Casual, Normal, Veteran, Expert);

type
  TTL2Mod = packed record
    modid :QWord;
    modver:word;
  end;
  TTL2ModList = array of TTL2Mod;

type
  TTL2Movie = packed record
    id  :QWord;
    flag:DWord;
  end;
  TTL2MovieList = array of TTL2Movie;
type
  TTL2KeyMapping = packed record
    id      :QWord;
    datatype:byte;   // (0=item, 2-skill)
    key     :word;   // or byte, (byte=3 or 0 for quick keys)
  end;
  TTL2KeyMappingList = array of TTL2KeyMapping;

type
  TTL2Statistic = packed record
    statTotalTime  :dword; // total time in game, msec
    statGold       :dword; // gold collected
    statDifficulty :dword; // difficulty
    statSteps      :dword; // steps done
    statTasks      :dword; // tasks (quests) done
    statDeaths     :dword; // number of deaths
    statMobs       :dword; // mobs killed
    statHeroes     :dword; // heroes killed
    statSkills     :dword; // skills used
    statTreasures  :dword; // hidden treasures opened
    statTraps      :dword; // traps activated
    statBroken     :dword; // items broken
    statPotions    :dword; // potions used
    statPortal     :dword; // portals opened
    statFish       :dword; // fish catched
    statGambled    :dword; // time gambled
    statCharmed    :dword; // items charmed
    statTransform  :dword; // items transformed
    statDmgObtained:dword; // max.damage obtained
    statDamage     :dword; // max damage made
    statLevelTime  :dword; // time on map, msec ?? last ingame time, msec
    statBlasted    :dword; // mobs blasted
  end;

type
  TTL2SaveFile = class
  //--- common part
  private
    FStream:TTL2Stream;
    FName  :string;

    procedure Error(const atext:string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const aname:string);
    procedure SaveToFile  (const aname:string; aencoded:boolean=false);

    function  Parse(amode:TTL2ParseType):boolean;
    function  Prepare:boolean;

  //--- TL2 save part
  private
    FCharInfo:TTL2Character;
    FPetInfo :TTL2Character;
    FCharInfoOffset:cardinal;
    FPetInfoOffset :cardinal;

    FClassString :string;
    FDifficulty  :TTL2Difficulty;
    FHardcore    :boolean;
    FNewGameCycle:integer;

    FBoundMods       :TTL2ModList;
    FRecentModHistory:TTL2ModList;
    FFullModHistory  :TTL2ModList;

    FMovies    :TTL2MovieList;
    FKeyMapping:TTL2KeyMappingList;

    FStatistic :TTL2Statistic; // OR we can just keep pointer to buffer

    FMap :string;
    FArea:string;

    function  ReadStatistic():boolean;
    procedure ReadModList(var ml:TTL2ModList);
    procedure ReadKeyMappingList;
    procedure ReadMovieList;

    function  GetKeyMapping(idx:integer):TTL2KeyMapping;
    function  GetMovie     (idx:integer):TTL2Movie;
  public
    procedure DumpKeyMapping;
    
    property ClassString :string         read FClassString;
    property Difficulty  :TTL2Difficulty read FDifficulty   write FDifficulty;
    property Hardcore    :boolean        read FHardcore     write FHardcore;
    property NewGameCycle:integer        read FNewGameCycle write FNewGameCycle;

    property BoundMods       :TTL2ModList read FBoundMods;
    property RecentModHistory:TTL2ModList read FRecentModHistory;
    property FullModHistory  :TTL2ModList read FFullModHistory;

    property CharInfo:TTL2Character read FCharInfo;
    property PetInfo :TTL2Character read FPetInfo;

    property Movie     [idx:integer]:TTL2Movie      read GetMovie;
    property KeyMapping[idx:integer]:TTL2KeyMapping read GetKeyMapping;

    property Statistic:TTL2Statistic read FStatistic;

    property Map :string read FMap;
    property Area:string read FArea;
  end;

//====================

implementation

uses
  sysutils;

resourcestring
  sWrongSize    = 'Wrong file size';
  sWrongVersion = 'Wrong save file signature';
  sWrongFooter  = 'Wrong save file size';

type
  PTL2SaveHeader = ^TTL2SaveHeader;
  TTL2SaveHeader = packed record
    Sign    :dword; // 0x00000044
    Encoded :byte;  // 1 - encoded
    Checksum:dword;
  end;
  PTL2SaveFooter = ^TTL2SaveFooter;
  TTL2SaveFooter = packed record
    filesize:dword;
  end;
const
  HeaderSize = SizeOf(TTL2SaveHeader);
  FooterSize = SizeOf(TTL2SaveFooter);

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

function CalcCheckSum(aptr:pByte; asize:cardinal):cardinal;
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

function TTL2SaveFile.GetMovie(idx:integer):TTL2Movie;
begin
  if (idx>=0) and (idx<Length(FMovies)) then
    result:=FMovies[idx]
  else
  begin
    result.id  :=QWord(-1);
    result.flag:=0;
  end;
end;

function TTL2SaveFile.GetKeyMapping(idx:integer):TTL2KeyMapping;
begin
  if (idx>=0) and (idx<Length(FKeyMapping)) then
    result:=FKeyMapping[idx]
  else
  begin
    result.id      :=QWord(-1);
    result.datatype:=0;
    result.key     :=0;
  end;
end;

procedure TTL2SaveFile.DumpKeyMapping;
var
  i:integer;
begin
  if IsConsole then
    if Length(FKeyMapping)>0 then
    begin
      writeln('Key Mapping'#13#10+
              '-----------');
      for i:=0 to High(FKeyMapping) do
        with FKeyMapping[i] do
          writeln(IntToHex(id,16),#9,datatype,#9,IntToHex(key,0));
    end;
end;

procedure TTL2SaveFile.ReadMovieList;
var
  lcnt:cardinal;
begin
  lcnt:=FStream.ReadWord;
  SetLength(FMovies,lcnt);
  if lcnt>0 then
    FStream.Read(FMovies[0],lcnt*SizeOf(TTL2Movie));
end;

procedure TTL2SaveFile.ReadKeyMappingList;
var
  lcnt:cardinal;
begin
  lcnt:=FStream.ReadWord;
  SetLength(FKeyMapping,lcnt);
  if lcnt>0 then
    FStream.Read(FKeyMapping[0],lcnt*SizeOf(TTL2KeyMapping));
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
  if lcnt>=22 then // SizeOf(FStatistic) div SizeOf(DWord)
  begin
    result:=true;
    FStream.Read(FStatistic,SizeOf(FStatistic));
    // unknown statistic
    if lcnt>22 then
      FStream.Seek(lcnt*SizeOf(DWord)-SizeOf(FStatistic),soCurrent);
  end
  else
    result:=false;
end;

//----- processing -----

function TTL2SaveFile.Parse(amode:TTL2ParseType):boolean;
var
  lcnt:integer;
begin
  result:=true;

  FStream.Position:=HeaderSize;

  FClassString :=FStream.ReadShortString();
  FDifficulty  :=TTL2Difficulty(FStream.ReadDWord);
  FHardcore    :=FStream.ReadByte<>0;
  FNewGameCycle:=FStream.ReadDWord;

  //!! Unknown 1
  FStream.ReadByte;  // 0
  FStream.ReadDWord; // (changing) +

  //-- Movies
  ReadMovieList;

  //--- Mod lists
  ReadModList(FBoundMods);
  ReadModList(FRecentModHistory);
  ReadModList(FFullModHistory);

  //=== Character Data
  FCharInfoOffset:=FStream.Position;
  FCharInfo:=ReadCharData(FStream,amode,'charinfo');

  //-- Keymapping table
  ReadKeyMappingList;
  DumpKeyMapping;

  //?? 2 bytes(=12) + $FF block 12*16
  lcnt:=FStream.ReadWord; // 12
  FStream.Seek(lcnt*16,soCurrent);

  //--- Statistic
  ReadStatistic();

  FMap :=FStream.ReadShortString(); // map
  FArea:=FStream.ReadShortString(); // area

  //!!
  FStream.ReadDWord; // 0

  FStream.ReadSingle; // $C479C000=-999
  FStream.ReadSingle;
  FStream.ReadSingle;
  
  // 15 bytes
  FStream.ReadDWord; // 0
  FStream.ReadDWord;
  FStream.ReadDWord;
  FStream.ReadWord;
  FStream.ReadByte;

  FStream.ReadDWord;  // 1
  FStream.ReadDWord;  // 1

  //=== Pet Data
  FPetInfoOffset:=FStream.Position;
  FPetInfo:=ReadCharData(FStream,amode,'petinfo');

  if amode<>ptDeepest then exit;

//---
// undiscovered: locations, quests, keybinding? etc
//---
end;

function TTL2SaveFile.Prepare:boolean;
begin
  result:=true;
end;

procedure TTL2SaveFile.LoadFromFile(const aname:string);
var
  lpheader:PTL2SaveHeader;
  lpfooter:PTL2SaveFooter;
begin
  if FStream<>nil then
    FreeAndNil(FStream);

  FStream:=TTL2Stream.Create;
  FName  :=aname;

  FStream.LoadFromFile(aname);

  if FStream.Size<(HeaderSize+FooterSize) then
    Error(sWrongSize);
  lpheader:=PTL2SaveHeader(FStream.Memory);
  if lpheader^.Sign<>$44 then
    Error(sWrongVersion);
  lpfooter:=PTL2SaveFooter(FStream.Memory+FStream.Size-FooterSize);

  if lpfooter^.filesize<>FStream.Size then
    Error(sWrongFooter);
  
  if lpheader^.Encoded<>0 then
    Decode(FStream.Memory+HeaderSize,FStream.Size-(HeaderSize+FooterSize));
end;

procedure TTL2SaveFile.SaveToFile(const aname:string; aencoded:boolean=false);
var
  ls:TTL2Stream;
  lpheader:PTL2SaveHeader;
  lpfooter:PTL2SaveFooter;
begin
  FStream.Position:=0;
  lpfooter:=PTL2SaveFooter(FStream.Memory+FStream.Size-FooterSize);
  lpfooter^.filesize:=FStream.Size;

  lpheader:=PTL2SaveHeader(FStream.Memory);
  lpheader^.Sign    :=$44;
  lpheader^.Encoded :=ORD(aencoded) and 1;
  lpheader^.Checksum:=CalcCheckSum(FStream.Memory+HeaderSize,FStream.Size-(HeaderSize+FooterSize));

  if aencoded then
  begin
    ls:=TTL2Stream.Create;
    ls.LoadFromStream(FStream);
    ls.Position:=0;
    Encode(ls.Memory+HeaderSize,ls.Size-(HeaderSize+FooterSize));
    ls.SaveToFile(aname);
    ls.Free;
  end
  else
    FStream.SaveToFile(aname);
end;

constructor TTL2SaveFile.Create;
begin
  inherited;

  FStream:=nil;
end;

destructor TTL2SaveFile.Destroy;
begin
  FStream.Free;

  if FCharInfo<>nil then FCharInfo.Free;
  if FPetInfo <>nil then FPetInfo.Free;

  SetLength(FBoundMods       ,0);
  SetLength(FRecentModHistory,0);
  SetLength(FFullModHistory  ,0);

  SetLength(FKeyMapping,0);
  SetLength(FMovies    ,0);

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
