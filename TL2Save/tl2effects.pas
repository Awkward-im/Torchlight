{}
unit TL2Effects;

interface

uses
  Classes,
  TL2Types,
  TL2Base,
  TL2Stream;

type
  TTL2EffectDamageType = (Physical, Magical, Fire, Ice, Electric, Poison, All);
  TTL2EffectSource     = (OnCastCaster, OnCastReceiver, OnUpdateCaster, OnUpdateSelf);
  TTL2EffectActivation = (Passive, Dynamic, Transfer);

  TTL2EffectFlag = (
    modUnknown1          , // $00000001
    modUnknown2          , // $00000002
    modExclusive         , // $00000004
    modNotMagical        , // $00000008
    modSaves             , // $00000010
    modDisplayPositive   , // $00000020
    modUnknown3          , // $00000040
    modUseOwnerLevel     , // $00000080
    modHasGraph          , // $00000100
    modIsBonus           , // $00000200
    modIsEnchantment     , // $00000400
    modHasLinkName       , // $00000800
    modHasParticles      , // $00001000
    modHasUnitTheme      , // $00002000
    modUnknown4          , // $00004000
    modUnknown5          , // $00008000
    modRemoveOnDeath     , // $00010000
    modHasIcon           , // $00020000
    modDisplayMaxModifier, // $00040000
    modIsForWeapon       , // $00080000
    modIsForArmor        , // $00100000
    modIsDisabled        , // $00200000
    // not realized (just reserved by me)
    modUnknown6          , // $00400000
    modUnknown7          , // $00800000
    modUnknown8          , // $01000000
    modUnknown9          , // $02000000
    modUnknown10         , // $04000000
    modUnknown11         , // $08000000
    modUnknown12         , // $10000000
    modUnknown13         , // $20000000
    modUnknown14         , // $40000000
    modUnknown15           // $80000000
  );

  TTL2EffectFlags = set of TTL2EffectFlag;

type
  TTL2Stat = packed record
    id        :TL2ID;
    percentage:TL2Float;
  end;

type
  TTL2Effect = class;
  TTL2EffectList = array of TTL2Effect;
type
  TTL2Effect = class(TL2BaseClass)
  private
    procedure InternalClear;

  public
    constructor Create(achar:boolean); overload;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TTL2Stream); override;
    procedure SaveToStream  (AStream: TTL2Stream); override;

  private
    FFlags       :TTL2EffectFlags;
    FName        :string;
    FLinkName    :string;
    FGraph       :string;
    FParticles   :string;
    FUnitThemeId :TL2ID;
    FClassId     :TL2ID;
    FFromChar    :boolean;
    FProperties  :array of TL2Float;
    FStats       :array of TTL2Stat;
    FEffectType  :integer;
    FDamageType  :TTL2EffectDamageType;
    FActivation  :TTL2EffectActivation;
    FLevel       :integer;
    FDuration    :TL2Float;
    FUnknown1    :TL2Float;
    FDisplayValue:TL2Float;
    FSource      :TTL2EffectSource;
    FIcon        :string;

    function GetProperties(idx:integer):TL2Float; overload;
    function GetProperties:integer;               overload;
    function GetStats:integer;                    overload;
    function GetStats     (idx:integer):TTL2Stat; overload;

  public
    property Flags       :TTL2EffectFlags           read FFlags        write FFlags; //??
    property Name        :string                    read FName         write FName;
    property LinkName    :string                    read FLinkName     write FLinkName;
    property Graph       :string                    read FGraph        write FGraph;
    property Particles   :string                    read FParticles    write FParticles;
    property UnitThemeId :TL2ID                     read FUnitThemeId  write FUnitThemeId;
    property ClassId     :TL2ID                     read FClassId      write FClassId;
    property Properties  [idx:integer]:TL2Float     read GetProperties; //!!
    property Stats       [idx:integer]:TTL2Stat     read GetStats     ; //!!
    property EffectType  :integer                   read FEffectType   write FEffectType;
    property DamageType  :TTL2EffectDamageType      read FDamageType   write FDamageType;
    property Activation  :TTL2EffectActivation      read FActivation   write FActivation;
    property Level       :integer                   read FLevel        write FLevel;
    property Duration    :TL2Float                  read FDuration     write FDuration;
    property DisplayValue:TL2Float                  read FDisplayValue write FDisplayValue;
    property Source      :TTL2EffectSource          read FSource       write FSource;
    property Unknown     :TL2Float                  read FUnknown1     write FUnknown1;
    property Icon        :string                    read FIcon         write FIcon;
  end;


function  ReadEffectList (AStream:TTL2Stream; atrans:boolean=false):TTL2EffectList;
procedure WriteEffectList(AStream:TTL2Stream; alist:TTL2EffectList);

function GetEffectType      (idx:integer):string;
function GetEffectDamageType(aval:TTL2EffectDamageType):string;
function GetEffectSource    (aval:TTL2EffectSource    ):string;
function GetEffectActivation(aval:TTL2EffectActivation):string;

implementation

const
  EffectDamageTypes : array [0..6] of string = (
    'Physical',
    'Magical',
    'Fire',
    'Ice',
    'Electric',
    'Poison',
    'All'
  );
  EffectSources : array [0..3] of string = (
    'On Cast Caster',
    'On Cast Receiver',
    'On Update Caster',
    'On Update Self'
  );
  EffectActivations :array [0..2] of string = (
    'Passive',
    'Dynamic',
    'Transfer'
  );

  EffectNames : array [0..238] of string = (
    'MELEEDAMAGEBONUS',
    'RANGEDDAMAGEBONUS',
    'DEFENSE',
    'MAGIC',
    'MAX MANA',
    'MAX HP',
    'MANA RECHARGE',
    'HP RECHARGE',
    'ARMOR BONUS',
    'TO HIT BONUS',
    'DAMAGE BONUS',
    'DAMAGE TAKEN',
    'KNOCK BACK',
    'SIGHT BONUS',
    'VIEW ANGLE BONUS',
    'PERCENT MELEEDAMAGE',
    'PERCENT RANGEDDAMAGE',
    'PERCENT DEFENSE',
    'PERCENT MAGIC',
    'PERCENT MANA',
    'PERCENT HP',
    'PERCENT SPEED',
    'PERCENT ATTACK SPEED',
    'PERCENT ARMOR BONUS',
    'PERCENT TO HIT BONUS',
    'PERCENT DAMAGE BONUS',
    'PERCENT DAMAGE TAKEN',
    'PERCENT MAGICAL DROP',
    'PERCENT GOLD DROP',
    'PERCENT CAST SPEED',
    'PERCENT LIFE STOLEN',
    'PERCENT MANA STOLEN',
    'PERCENT DAMAGE REFLECTED',
    'PERCENT BLOCK CHANCE',
    'PERCENT ITEM REQUIREMENTS',
    'PHYSICAL DEFENSE',
    'MAGICAL DEFENSE',
    'FIRE DEFENSE',
    'ICE DEFENSE',
    'ELECTRICAL DEFENSE',
    'POISON DEFENSE',
    'PERCENT SIGHT BONUS',
    'PERCENT VIEW ANGLE BONUS',
    'KNOCK BACK EFFECT',
    'PERCENT ACTIVE DISTANCE BONUS',
    'OPEN WAYPOINT PORTAL',
    'IDENTIFY',
    'SUMMON DURATION',
    'DAMAGE REFLECTION',
    'LIFE STEAL',
    'MANA STEAL',
    'GOLD DROP',
    'DAMAGE',
    'PERCENT KNOCK BACK RESISTANCE',
    'DEGRADE ARMOR',
    'CRITICAL CHANCE',
    'INTERRUPT CHANCE',
    'TRANSFORM',
    'UNIT THEME',
    'SCALE',
    'MISSILE REFLECT',
    'MISSILE REFLECT VISUAL',
    'PERCENT BLOCK CHANCE BASE',
    'VELOCITY MULT',
    'STUN',
    'LEARN SKILL',
    'DEGRADE ARMOR EFFECT',
    'DESUMMON MONSTER',
    'XP GAIN BONUS',
    'STRENGTH BONUS',
    'DEXTERITY BONUS',
    'PERCENT STRENGTH BONUS',
    'PERCENT DEXTERITY BONUS',
    'TRANSFORM PERMANENT',
    'CAST SKILL',
    'CAST SKILL ON TARGET',
    'CAST SKILL AT TARGET',
    'FAME GAIN BONUS',
    'MISSILE RANGE BONUS',
    'FLEE EFFECT',
    'TURN ALIGNMENT',
    'CAST SKILL ON STRUCK',
    'SKILL BONUS',
    'PRICE REDUCTION',
    'FISHING LUCK',
    'ATTACK SPELL BONUS',
    'DEFENSE SPELL BONUS',
    'CHARM SPELL BONUS',
    'DUAL WIELDING BONUS',
    'PERCENT CRITICAL DAMAGE',
    'POTION EFFICIENCY',
    'PERCENT PET DAMAGE',
    'PERCENT PET VELOCITY',
    'REDUCED ITEM REQUIREMENTS',
    'ARMOR ITEM REQUIREMENTS',
    'SPELL REQUIREMENTS',
    'PET DEPARTURE TIME',
    'PERCENT PET ARMOR',
    'MARTIAL ITEM REQUIREMENTS',
    'PERCENT MARTIAL ITEM DAMAGE BONUS',
    'RANGED ITEM REQUIREMENTS',
    'MAGIC ITEM REQUIREMENTS',
    'PERCENT RANGED ITEM DAMAGE BONUS',
    'PERCENT MAGIC ITEM DAMAGE BONUS',
    'PERCENT PET HEALTH',
    'CAST SKILL ON DEATH',
    'FREEZE',
    'BURN',
    'POISON',
    'SHOCK',
    'KILL',
    'FADE OUT',
    'SET VISIBLE',
    'WARP',
    'PERMANENT STRENGTH',
    'PERMANENT DEXTERITY',
    'PERMANENT MAGIC',
    'PERMANENT HEALTH',
    'PERMANENT DEFENSE',
    'PERMANENT MANA',
    'AWARD STATPOINT',
    'FLEE RESIST',
    'SHIELD BUFFER',
    'MANA RECHARGE PLAYER',
    'HP RECHARGE PLAYER',
    'LIFE STEAL MASTER',
    'PERCENT LIFE STOLEN MASTER',
    'STOP SKILL',
    'SILENCE',
    'DESUMMON ON DEATH',
    'EMOTIONAL DAMAGE',
    'FUTURISTICNESS',
    'JAUNTINESS',
    'SOCKS',
    'LOGIC RESISTANCE',
    'NOODLE ARMS',
    'INTERRUPT RESISTANCE',
    'CHARM RESISTANCE',
    'SILENCE_RESISTANCE',
    'STUN RESISTANCE',
    'SLOW RESISTANCE',
    'OPEN PORTAL',
    'SWAP POS WITH PET',
    'RESPEC',
    'PERCENT BLIND',
    'EXPLODE DEAD',
    'ADD STAT',
    'ADD STAT TO LEVEL',
    'SET STAT',
    'SET STAT ON LEVEL',
    'CLEAR STAT',
    'CLEAR STAT ON LEVEL',
    'CAST SKILL ON STRIKE',
    'PERCENT DUAL WIELDING ATTACK',
    'DAMAGE BONUS SECONDARY',
    'SET MESH INVISIBLE',
    'DAMAGE CHANCE',
    'TELEPORT RANDOM',
    'TELEPORT',
    'TELEPORT RESISTANCE',
    'SPAWN UNIT',
    'SPAWN UNIT ON DEATH',
    'WARP TO POI',
    'DESTRUCTABLE SHIELD',
    'DISENCHANT',
    'ADD TRIGGERABLE',
    'REMOVE TRIGGERABLE',
    'INTERRUPT',
    'ADD CHARGE PERCENT',
    'SET CHARGE PERCENT',
    'MAX CHARGES',
    'ADD CHARGES',
    'PERCENT CHARGE BAR DECAY RATE',
    'CHARGE BAR DECAY DELAY',
    'PERCENT CHARGING BONUS',
    'PERCENT MANA COST BONUS',
    'CHARGE BAR DECAY RATE',
    'EXPLODE ON DEATH',
    'DODGE CHANCE BONUS',
    'FUMBLE CHANCE REDUCTION',
    'FUMBLE PENALTY REDUCTION',
    'CONVERT CHARGE TO STAT',
    'CONVERT CHARGE PERCENT TO STAT',
    'CAST SKILL ON DEATH FROM EFFECT OWNER',
    'SCALE BY HP',
    'HP MOD OVER TIME',
    'TRANSFORMATION TIME',
    'TRAP DISARM CHANCE',
    'ELEMENTAL EFFECT DURATION BONUS',
    'BURN DURATION BONUS',
    'FREEZE DURATION BONUS',
    'SHOCK DURATION BONUS',
    'POISON DURATION BONUS',
    'NONE',
    'CAST SKILL ON RANGED STRIKE',
    'CAST SKILL ON MELEE STRIKE',
    'IMMOBILIZE',
    'IMMOBILIZE RESISTANCE',
    'CAST SKILL FROM TARGET',
    'CAST SKILL ON MELEE STRIKE FROM TARGET',
    'CAST SKILL ON RANGED STRIKE FROM TARGET',
    'CAST SKILL ON STRIKE FROM TARGET',
    'BLIND',
    'CAST SKILL ON KILL',
    'CAST SKILL ON KILL AT TARGET',
    'SHIELD BREAK',
    'CAST SKILL ON MELEE SKILL STRIKE',
    'CAST SKILL ON MELEE SKILL STRIKE FROM TARGET',
    'CAST SKILL ON RANGED SKILL STRIKE',
    'CAST SKILL ON RANGED SKILL STRIKE FROM TARGET',
    'CAST SKILL ON SKILL STRIKE',
    'CAST SKILL ON SKILL STRIKE FROM TARGET',
    'TARGET LOCKED',
    'RETARGET',
    'AGRO',
    'SHIELD BREAK EFFECT',
    'MODIFY SKILL COOLDOWN REMAINING',
    'SET SKILL COOLDOWN REMAINING',
    'INNATE ICE DEFENSE',
    'INNATE FIRE DEFENSE',
    'INNATE ELECTRIC DEFENSE',
    'INNATE POISON DEFENSE',
    'SET SKILL LEVEL',
    'PULL',
    'PULL RESISTANCE',
    'PULL EFFECT',
    'MISS CHANCE',
    'SKILL ENABLE',
    'SKILL DISABLE',
    'DRAW HEALTH',
    'DRAW MANA',
    'PERCENT DAMAGE TAKEN BY MONSTER COUNT',
    'REMOVE EFFECT',
    'BLIND RESISTANCE',
    'PERCENT DAMAGE BONUS BY MONSTER COUNT',
    'TELEPORT NOPARTICLE',
    'TELEPORT RANDOM NOPARTICLE',
    'MINIONDAMAGE',
    'CHEATED'
  );

function GetEffectType(idx:integer):string;
begin
  if (idx>=0) and (idx<=High(EffectNames)) then
    result:=EffectNames[idx]
  else
    result:='';
end;

function GetEffectDamageType(aval:TTL2EffectDamageType):string;
begin
  result:=EffectDamageTypes[ord(aval)];
end;

function GetEffectSource(aval:TTL2EffectSource):string;
begin
  result:=EffectSources[ord(aval)];
end;

function GetEffectActivation(aval:TTL2EffectActivation):string;
begin
  result:=EffectActivations[ord(aval)];
end;

//----- Effects class -----

constructor TTL2Effect.Create(achar:boolean); overload;
begin
  inherited Create;

  DataType:=dtEffect;
  FFromChar:=achar;
end;

destructor TTL2Effect.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Effect.InternalClear;
begin
  SetLength(FProperties,0);
  SetLength(FStats ,0);
end;

procedure TTL2Effect.Clear;
begin
  InternalClear;

  inherited;
end;

function TTL2Effect.GetProperties():integer;
begin
  result:=Length(FProperties);
end;

function TTL2Effect.GetProperties(idx:integer):single;
begin
  if (idx>=0) and (idx<Length(FProperties)) then
    result:=FProperties[idx]
  else
    result:=0;
end;

function TTL2Effect.GetStats():integer;
begin
  result:=Length(FStats);
end;

function TTL2Effect.GetStats(idx:integer):TTL2Stat;
begin
  if (idx>=0) and (idx<Length(FStats)) then
    result:=FStats[idx]
  else
  begin
    result.id:=TL2IdEmpty;
    result.percentage:=0;
  end;
end;


procedure TTL2Effect.LoadFromStream(AStream: TTL2Stream);
var
  lcnt:integer;
begin
  DataOffset:=AStream.Position;

  FFlags:=TTL2EffectFlags(AStream.ReadDword);
  FName :=AStream.ReadShortString();

  if modHasLinkName in FFlags then
    FLinkName:=AStream.ReadShortString();

  if modHasGraph in FFlags then
    FGraph:=AStream.ReadShortString();

  if modHasParticles in FFlags then
    FParticles:=AStream.ReadShortString();

  if modHasUnitTheme in FFlags then
    FUnitThemeId:=TL2ID(AStream.ReadQWord);

  if FFromChar then
    FClassId:=TL2ID(AStream.ReadQWord);

  // 5 properties max

  lcnt:=AStream.ReadByte();
  SetLength(FProperties,lcnt);
  if lcnt>0 then
    AStream.Read(FProperties[0],lcnt*SizeOf(TL2Float));

  lcnt:=AStream.ReadWord;
  SetLength(FStats,lcnt);
  if lcnt>0 then
    AStream.Read(FStats[0],lcnt*SizeOf(TTL2Stat));

  FEffectType  :=AStream.ReadDWord();
  FDamageType  :=TTL2EffectDamageType(AStream.ReadDWord);
  FActivation  :=TTL2EffectActivation(AStream.ReadDWord); // ????
  FLevel       :=AStream.ReadDWord;
  FDuration    :=AStream.ReadFloat;
  FUnknown1    :=AStream.ReadFloat;  // 0 ??  SoakScale??
  FDisplayValue:=AStream.ReadFloat;
  FSource      :=TTL2EffectSource(AStream.ReadDWord);

  if modHasIcon in FFlags then
    FIcon:=AStream.ReadByteString();

  LoadBlock(AStream);
end;

procedure TTL2Effect.SaveToStream(AStream: TTL2Stream);
begin
  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;
  
  AStream.WriteDword(DWord(FFlags));
  AStream.WriteShortString(FName);

  if modHasLinkName in FFlags then
    AStream.WriteShortString(FLinkName);

  if modHasGraph in FFlags then
    AStream.WriteShortString(FGraph);

  if modHasParticles in FFlags then
    AStream.WriteShortString(FParticles);

  if modHasUnitTheme in FFlags then
    AStream.WriteQWord(QWord(FUnitThemeId));

  if FFromChar then
    AStream.WriteQWord(QWord(FClassId));

  AStream.WriteByte(Length(FProperties));
  if Length(FProperties)>0 then
    AStream.Write(FProperties[0],Length(FProperties)*SizeOf(TL2Float));

  AStream.WriteWord(Length(FStats));
  if Length(FStats)>0 then
    AStream.Write(FStats[0],Length(FStats)*SizeOf(TTL2Stat));

  AStream.WriteDWord(FEffectType);

  AStream.WriteDWord(DWord(FDamageType));
  AStream.WriteDWord(DWord(FActivation));

  AStream.WriteDWord(FLevel);
  AStream.WriteFloat(FDuration);
  //??
  AStream.WriteFloat(FUnknown1);
  AStream.WriteFloat(FDisplayValue);

  AStream.WriteDWord(DWord(FSource));

  if modHasIcon in FFlags then
    AStream.WriteByteString(FIcon);

  LoadBlock(AStream);
end;

function ReadEffectList(AStream:TTL2Stream; atrans:boolean=false):TTL2EffectList;
var
  i,lcnt:integer;
begin
  result:=nil;
  lcnt:=AStream.ReadDWord;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
    begin
      result[i]:=TTL2Effect.Create(atrans);
      result[i].LoadFromStream(AStream);
    end;
  end;
end;

procedure WriteEffectList(AStream:TTL2Stream; alist:TTL2EffectList);
var
  i:integer;
begin
  AStream.WriteDWord(Length(alist));
  for i:=0 to High(alist) do
    alist[i].SaveToStream(AStream);
end;

end.
