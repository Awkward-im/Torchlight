unit tl2save;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2types,
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
    statBlasted    :TL2Integer ; // mobs blasted
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
    FCharInfo:TTL2Character;
    FPetInfo :TTL2Character;
    FCharInfoOffset:cardinal;
    FPetInfoOffset :cardinal;

    FClassString :string;
    FDifficulty  :TTL2Difficulty;
    FHardcore    :boolean;
    FNewGameCycle:integer;
    FGameTime    :single;

    FBoundMods       :TTL2ModList;
    FRecentModHistory:TTL2ModList;
    FFullModHistory  :TTL2ModList;

    FMovies    :TL2IdValList;
    FKeyMapping:TTL2KeyMappingList;

    FStatistic :TTL2Statistic; // OR we can just keep pointer to buffer

    FMap :string;
    FArea:string;

    FUnknown1:PByte;
    TheRest  :PByte;
    RestSize :cardinal;
    
    function  ReadStatistic():boolean;
    procedure ReadModList(var ml:TTL2ModList);
    procedure ReadKeyMappingList;

    procedure WriteKeyMappingList;
    procedure WriteModList(ml:TTL2ModList);
    procedure WriteStatistic();

    function  GetKeyMapping(idx:integer):TTL2KeyMapping;
    function  GetMovie     (idx:integer):TL2IdVal;
  public
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
    property PetInfo :TTL2Character read FPetInfo;

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

//----- Dumps -----

procedure TTL2SaveFile.DumpKeyMapping;
var
  ls:string;
  i:integer;
begin
  if IsConsole then
    if Length(FKeyMapping)>0 then
    begin
      writeln('Key Mapping'#13#10+
              '-----------');
      for i:=0 to High(FKeyMapping) do
        with FKeyMapping[i] do
        begin
          if      datatype=0 then ls:='items'
          else if datatype=2 then ls:='skill'
          else ls:='['+inttostr(datatype)+']';
          writeln(GetTL2Skill(id),'  ',ls,'  ',GetTL2KeyType(key));
        end;
      writeln;
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

//----- Read data -----

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

function TTL2SaveFile.Parse(amode:TTL2ParseType):boolean;
var
  lcnt{,lcnt1}:integer;
begin
  result:=true;

  FStream.Position:=SizeOf(TL2SaveHeader);

  FClassString :=FStream.ReadShortString();
  FDifficulty  :=TTL2Difficulty(FStream.ReadDWord);
  FHardcore    :=FStream.ReadByte<>0;
  FNewGameCycle:=FStream.ReadByte;

  //!!
  FStream.ReadDWord; // 0

  FGameTime:=FStream.ReadFloat; // game time (hh.mm)

  //-- Movies
  FMovies:=FStream.ReadIdValList;

  //--- Mod lists
  ReadModList(FBoundMods);         // DumpModList('Bound mods'        ,FBoundMods);
  ReadModList(FRecentModHistory);  // DumpModList('Recent mod history',FRecentModHistory);
  ReadModList(FFullModHistory);    // DumpModList('Full mod history'  ,FFullModHistory);

  //=== Character Data
  FCharInfoOffset:=FStream.Position;
  FCharInfo:=ReadCharData(FStream,amode,'charinfo.dmp');

  //-- Keymapping table
  ReadKeyMappingList;
  DumpKeyMapping;

  //?? 2 bytes(=12) + $FF block 12*16
  lcnt:=FStream.ReadWord; // 12
  FStream.Seek(lcnt*16,soCurrent);

  //--- Statistic
  ReadStatistic();

  FMap :=FStream.ReadShortString(); // map
  FArea:=FStream.ReadShortString(); // area (region)

  //!!
  FUnknown1:=FStream.ReadBytes(39);
{
  FStream.ReadDWord; // 0

  FStream.ReadFloat; // $C479C000=-999
  FStream.ReadFloat;
  FStream.ReadFloat;
  
  // 15 bytes
  FStream.ReadDWord; // 0
  FStream.ReadDWord;
  FStream.ReadDWord;
  FStream.ReadWord;
  FStream.ReadByte;

  FStream.ReadDWord;  // 1
  FStream.ReadDWord;  // 1
}
  //=== Pet Data
  FPetInfoOffset:=FStream.Position;
  FPetInfo:=ReadCharData(FStream,amode,'petinfo.dmp');

//  if amode<>ptDeepest then exit;
  // !!!!
  RestSize:=FStream.Size-SizeOf(TL2SaveFooter)-FStream.Position;
  TheRest :=FStream.ReadBytes(RestSize);
  SaveDump('rest.dmp',TheRest,RestSize);

exit;
(*
//!!!!!!!!!!!!!!!!!!!!
// undiscovered: locations, quests, keybinding? etc
//!!!!!!!!!!!!!!!!!!!!

  FStream.Seek(34,soCurrent); // 0
  FStream.ReadDWord; // 7 for elfly
  FStream.ReadDword; // 0

  FStream.ReadFloat; // 47EE5583 = 122027.0234  0 for Zorro
  FStream.ReadFloat; //(playtime) 47EECAF4 = 122261.9062  441CC954 for Zorro (changed) 627,1427
  FStream.ReadFloat; // 1.0 3A83126F for Zorro  0,00100000004749745

  FStream.ReadShortString; // Area "LAVERSDEN"
  FStream.ReadWord;   // 0

  lcnt :=FStream.ReadDword;  // 29  29*23 = 667
  lcnt1:=FStream.ReadDword;  // 23
  //!! Block: 29*23*4
  FStream.Seek(lcnt*lcnt1*SizeOf(Single),soCurrent); // 0  :E82F
{
  FStream.Seek(80,soCurrent); // 0  :E82F

  FStream.ReadFloat; // 3F28C52C = 0.66
  FStream.ReadFloat; // 3F65864A = 0.896
  FStream.ReadFloat; // 3F7EBBFF = 0.995
  FStream.ReadFloat; // 3F7CA3E8 = 0.9868
  FStream.ReadFloat; // 1.0
  FStream.ReadFloat; // 3F795093 = 0.9738
  FStream.ReadFloat; // 3F42E6F0 = 0.7613
  // ... if 7*16 = 112 bytes. 112*667?? :172C6 something
}
  // :F29B
  FStream.ReadDWord; // 0
  lcnt:=FStream.ReadDword; // 14
  FStream.Seek(lcnt*(8+4+8),soCurrent);
{
  // :F2A3 +14*(8+4+8) = +14*20 = +280 = F3BB
  // 5361955370E81ED3: "LAYOUTS\GENERIC_CAVE\1X1SINGLE_ROOM_BOSS\1XSLAVERSBASEMENT_PB_A.LAYOUT
  // 4b=00
  // 56486755FDC4E322: ??
}
  // :F3BB
  FStream.ReadDWord;  // 2
  FStream.ReadDWord;  // 643BC0F76B020D58 ??
  FStream.ReadDWord;  // 39815D860999E059 ??

  // :F3CF
  FStream.ReadDWord;  // 18
  // A0 01 00 00 02 00 00
  // :F3DA
  FStream.ReadQWord;  // D35C7DDB557F7C52: "UNITS\MONSTERS\QUESTUNITS\ESTHERIANS\A1A1-CAPTUREDENCHANTER.DAT 
  FStream.ReadQWord;  // *FF
  FStream.ReadQWord;  // 715E733670A1DC5D: ??
  FStream.ReadDWord;  // 1

  FStream.ReadDword;
  FStream.ReadDword;
  FStream.ReadDword;
  FStream.ReadDword;
  FStream.ReadDword;

  FStream.ReadFloat; // 3FB33333
  // 7*4b*FF
  // NPC name
*)
end;

function TTL2SaveFile.Prepare:boolean;
begin
  // if not parsed then error

  result:=true;

  FStream.Position:=SizeOf(TL2SaveHeader); //!!

  FStream.WriteShortString(FClassString);
  FStream.WriteDword(DWord(FDifficulty));
  FStream.WriteByte(Ord(FHardcore));
  FStream.WriteByte(FNewGameCycle);

  FStream.WriteDWord(0);
  FStream.WriteFloat(FGameTime);

  //-- Movies
  FStream.WriteIdValList(FMovies);

  //--- Mod lists
  WriteModList(FBoundMods);
  WriteModList(FRecentModHistory);
  WriteModList(FFullModHistory);

  //=== Character Data
  WriteCharData(FStream,FCharInfo);

  //-- Keymapping table
  WriteKeyMappingList;

  //!!
  FStream.WriteWord(12);
  FStream.WriteFiller(12*16);

  //--- Statistic
  WriteStatistic();

  FStream.WriteShortString(FMap); // map
  FStream.WriteShortString(FArea); // area (region)

  //!!
  FStream.Write(FUnknown1^,39);
{
  FStream.WriteDWord(0);

  FStream.WriteFloat(-999);
  FStream.WriteFloat(-999);
  FStream.WriteFloat(-999);
  
  // 15 bytes
  FStream.WriteDWord(0);
  FStream.WriteDWord(0);
  FStream.WriteDWord(0);
  FStream.WriteWord(0);
  FStream.WriteByte(0);

  FStream.WriteDWord(1);
  FStream.WriteDWord(1);
}
  //=== Pet Data
  WriteCharData(FStream,FPetInfo);

  // !!!!
  FStream.Write(TheRest^,RestSize);

end;

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
var
  lsout:TMemoryStream;
  lSaveHeader:TL2SaveHeader;
  lSaveFooter:TL2SaveFooter;
begin
  if not FChanged then
  begin
    FStream.SaveToFile(aname);
    exit;
  end;

  FStream.Position:=0; //!!

  lSaveHeader.Sign    :=$44;
  lSaveHeader.Encoded :=aencoded;
  lSaveHeader.Checksum:=CalcCheckSum(FStream.Memory,FStream.Size);

  lsout:=TMemoryStream.Create;
  try
    try
      lsout.Write(lSaveHeader,SizeOf(lSaveHeader));

      lsout.CopyFrom(FStream,FStream.Size);

      if aencoded then
        Encode(lsout.Memory+SizeOf(lSaveHeader),lsout.Size-SizeOf(lSaveHeader));

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
begin
  FStream.Free;

  if FCharInfo<>nil then FCharInfo.Free;
  if FPetInfo <>nil then FPetInfo.Free;

  FreeMem(FUnknown1);
  FreeMem(TheRest);

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
