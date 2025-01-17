{}
unit TLSGEffects;

interface

uses
  Classes,
  rgglobal,
  TLSGBase,
  rgstream;

type
  TTLEffectDamageType = (Physical, Magical, Fire, Ice, Electric, Poison, All);
  TTLEffectSource     = (OnCastCaster, OnCastReceiver, OnUpdateCaster, OnUpdateSelf);
  TTLEffectActivation = (Passive, Dynamic, Transfer);

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
    id        :TRGID;
    percentage:TRGFloat;
  end;

type
  TTLEffect = class;
  TTLEffectList = array of TTLEffect;
type
  TTLEffect = class(TLSGBaseClass)
  private
    procedure InternalClear;

  public
    constructor Create(achar:boolean); overload;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TStream; aVersion:integer); override;
    procedure SaveToStream  (AStream: TStream; aVersion:integer); override;

  private
    FFlags       :TTL2EffectFlags;
    FName        :string;
    FLinkName    :string;
    FGraph       :string;
    FParticles   :string;
    FUnitThemeId :TRGID;
    FClassId     :TRGID;
    FFromChar    :boolean;
    FProperties  :array [0..4] of TRGFloat;
    FStats       :array of TTL2Stat;
    FPropCount   :integer;
    FEffectType  :integer;
    FDamageType  :TTLEffectDamageType;
    FActivation  :TTLEffectActivation;
    FLevel       :integer;
    FDuration    :TRGFloat;
    FUnknown1    :TRGFloat;
    FDisplayValue:TRGFloat;
    FSource      :TTLEffectSource;
    FIcon        :string;

    tmp:array [0..63] of byte;

    function GetProperties():integer;             overload;
    function GetProperties(idx:integer):TRGFloat; overload;
    function GetStats     ():integer;             overload;
    function GetStats     (idx:integer):TTL2Stat; overload;

  public
    property Flags       :TTL2EffectFlags           read FFlags        write FFlags; //??
    property Name        :string                    read FName         write FName;
    property LinkName    :string                    read FLinkName     write FLinkName;
    property Graph       :string                    read FGraph        write FGraph;
    property Particles   :string                    read FParticles    write FParticles;
    property UnitThemeId :TRGID                     read FUnitThemeId  write FUnitThemeId;
    property ClassId     :TRGID                     read FClassId      write FClassId;
    property Properties  [idx:integer]:TRGFloat     read GetProperties; //!!
    property Stats       [idx:integer]:TTL2Stat     read GetStats     ; //!!
    property EffectType  :integer                   read FEffectType   write FEffectType;
    property DamageType  :TTLEffectDamageType       read FDamageType   write FDamageType;
    property Activation  :TTLEffectActivation       read FActivation   write FActivation;
    property Level       :integer                   read FLevel        write FLevel;
    property Duration    :TRGFloat                  read FDuration     write FDuration;
    property DisplayValue:TRGFloat                  read FDisplayValue write FDisplayValue;
    property Source      :TTLEffectSource           read FSource       write FSource;
    property Unknown     :TRGFloat                  read FUnknown1     write FUnknown1;
    property Icon        :string                    read FIcon         write FIcon;
  end;


function  ReadEffectList (AStream:TStream; aVersion:integer; atrans:boolean=false):TTLEffectList;
procedure WriteEffectList(AStream:TStream; alist:TTLEffectList; aVersion:integer);

function GetEffectType      (idx:integer):string;
function GetEffectDamageType(aval:TTLEffectDamageType):string;
function GetEffectSource    (aval:TTLEffectSource    ):string;
function GetEffectActivation(aval:TTLEffectActivation):string;

implementation

uses
  sysutils,
  tlsgcommon;

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

function GetEffectDamageType(aval:TTLEffectDamageType):string;
begin
  result:=EffectDamageTypes[ord(aval)];
end;

function GetEffectSource(aval:TTLEffectSource):string;
begin
  result:=EffectSources[ord(aval)];
end;

function GetEffectActivation(aval:TTLEffectActivation):string;
begin
  result:=EffectActivations[ord(aval)];
end;

//----- Effects class -----

constructor TTLEffect.Create(achar:boolean); overload;
begin
  inherited Create;

  DataType:=dtEffect;
  FFromChar:=achar;
end;

destructor TTLEffect.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTLEffect.InternalClear;
begin
  FillChar(FProperties,SizeOf(FProperties),0);
  SetLength(FStats ,0);
end;

procedure TTLEffect.Clear;
begin
  InternalClear;

  inherited;
end;

function TTLEffect.GetProperties():integer;
begin
  result:=FPropCount;
end;

function TTLEffect.GetProperties(idx:integer):single;
begin
  if (idx>=0) and (idx<Length(FProperties)) then
    result:=FProperties[idx]
  else
    result:=0;
end;

function TTLEffect.GetStats():integer;
begin
  result:=Length(FStats);
end;

function TTLEffect.GetStats(idx:integer):TTL2Stat;
begin
  if (idx>=0) and (idx<Length(FStats)) then
    result:=FStats[idx]
  else
  begin
    result.id:=RGIdEmpty;
    result.percentage:=0;
  end;
end;


procedure TTLEffect.LoadFromStream(AStream: TStream; aVersion:integer);
var
  i3:QWord;
  i1,i2,i4,i5,i6,i7,i8,i9:dword;
  f:single;
  lcnt:integer;
begin
  DataOffset:=AStream.Position;

  if aVersion>=tlsaveTL2Minimal then
    FFlags:=TTL2EffectFlags(AStream.ReadDword);

  FName:=AStream.ReadShortString();

  if aVersion>=tlsaveTL2Minimal then
  begin
    if modHasLinkName in FFlags then
      FLinkName:=AStream.ReadShortString();

    if modHasGraph in FFlags then
      FGraph:=AStream.ReadShortString();

    if modHasParticles in FFlags then
      FParticles:=AStream.ReadShortString();

    if modHasUnitTheme in FFlags then
      FUnitThemeId:=TRGID(AStream.ReadQWord);

    if FFromChar then
      FClassId:=TRGID(AStream.ReadQWord);
  end
  else
  begin
    FGraph    :=AStream.ReadShortString(); //??
    FParticles:=AStream.ReadShortString();
  end;

  // 5 properties max
  FPropCount:=AStream.ReadByte();
  if FPropCount>0 then
  begin
    if FPropCount>Length(FProperties) then
    begin
      DbgLn('Effect props '+IntToStr(FPropCount)+' more than maximum');
      AStream.Read(FProperties[0],Length(FProperties)*SizeOf(TRGFloat));
      AStream.Position:=AStream.Position+(FPropCount-Length(FProperties))*SizeOf(TRGFloat);
      FPropCount:=Length(FProperties);
    end
    else
      AStream.Read(FProperties[0],FPropCount*SizeOf(TRGFloat));
  end;

  lcnt:=AStream.ReadWord;
  SetLength(FStats,lcnt);
  if lcnt>0 then
    AStream.Read(FStats[0],lcnt*SizeOf(TTL2Stat));

  FEffectType  :=AStream.ReadDWord();
  FDamageType  :=TTLEffectDamageType(AStream.ReadDWord);

  if aVersion>=tlsaveTL2Minimal then
  begin
    FActivation  :=TTLEffectActivation(AStream.ReadDWord); // ????
    FLevel       :=AStream.ReadDWord;
    FDuration    :=AStream.ReadFloat;
    FUnknown1    :=AStream.ReadFloat;   // 0 ??  SoakScale??
    FDisplayValue:=AStream.ReadFloat;
    FSource      :=TTLEffectSource(AStream.ReadDWord);
  end
  else
  begin
    AStream.Read(tmp,64);
    AStream.Position:=AStream.Position-64;
    // 64 bytes
    i1:=AStream.ReadDword;              // 4 booleans, not mask (0,1,1,1) (1,0,1,1)
    i2:=AStream.ReadDword;              // 1 on pots, 0 on shirt
    FLevel       :=AStream.ReadDWord;   // at least, looks like
    i3:=AStream.ReadQWord;              // -1
    i4:=AStream.ReadDword;              // 100 usually
    i5:=AStream.ReadDword;              // pots=100, shirt =0
    i6:=AStream.ReadDword;              // 0
    i7:=AStream.ReadDword;              // "on time" ?
    i8:=AStream.ReadDword;              // 0
    f:=AStream.ReadFloat;               // 1.0 usually
    FDuration    :=AStream.ReadFloat;
    FUnknown1    :=AStream.ReadFloat;   // 0 ??  SoakScale??
    FDisplayValue:=AStream.ReadFloat;
    FSource      :=TTLEffectSource(AStream.ReadDWord); //?? =0
    i9:=AStream.ReadDword;              // 0
  end;

  if aVersion>=tlsaveTL2Minimal then
    if modHasIcon in FFlags then
      FIcon:=AStream.ReadByteString();

  LoadBlock(AStream);
end;

procedure TTLEffect.SaveToStream(AStream: TStream; aVersion:integer);
begin
  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;
  
  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteDword(DWord(FFlags));

  AStream.WriteShortString(FName);

  if aVersion>=tlsaveTL2Minimal then
  begin
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
  end
  else
  begin
    AStream.WriteShortString(FGraph);
    AStream.WriteShortString(FParticles);
  end;

  AStream.WriteByte(FPropCount);
  if FPropCount>0 then
    AStream.Write(FProperties[0],FPropCount*SizeOf(TRGFloat));

  AStream.WriteWord(Length(FStats));
  if Length(FStats)>0 then
    AStream.Write(FStats[0],Length(FStats)*SizeOf(TTL2Stat));

  AStream.WriteDWord(FEffectType);

  AStream.WriteDWord(DWord(FDamageType));

  if aVersion>=tlsaveTL2Minimal then
  begin
    AStream.WriteDWord(DWord(FActivation));

    AStream.WriteDWord(FLevel);
    AStream.WriteFloat(FDuration);
    //??
    AStream.WriteFloat(FUnknown1);
    AStream.WriteFloat(FDisplayValue);

    AStream.WriteDWord(DWord(FSource));
  end
  else
  begin
    AStream.Write(tmp,64);
{
    i:=AStream.WriteDword;              // 4 booleans, not mask (0,1,1,1) (1,0,1,1)
    i:=AStream.WriteDword;              // 1 on pots, 0 on shirt
    FLevel       :=AStream.WriteDWord;  // at least, looks like
    i:=AStream.WriteQWord;              // -1
    i:=AStream.WriteDword;              // 100 usually
    i:=AStream.WriteDword;              // pots=100, shirt =0
    i:=AStream.WriteDword;              // 0
    i:=AStream.WriteDword;              // "on time" ?
    i:=AStream.WriteDword;              // 0
    f:=AStream.WriteFloat;              // 1.0 usually
    FDuration    :=AStream.WriteFloat;
    FUnknown1    :=AStream.WriteFloat;  // 0 ??  SoakScale??
    FDisplayValue:=AStream.WriteFloat;
    FSource      :=TTLEffectSource(AStream.WriteDWord); //?? =0
    i:=AStream.WriteDword;              // 0
}
  end;

  if aVersion>=tlsaveTL2Minimal then
    if modHasIcon in FFlags then
      AStream.WriteByteString(FIcon);

  LoadBlock(AStream);
end;

function ReadEffectList(AStream:TStream; aVersion:integer; atrans:boolean=false):TTLEffectList;
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
      result[i]:=TTLEffect.Create(atrans);
      result[i].LoadFromStream(AStream, aVersion);
    end;
  end;
end;

procedure WriteEffectList(AStream:TStream; alist:TTLEffectList; aVersion:integer);
var
  i:integer;
begin
  AStream.WriteDWord(Length(alist));
  for i:=0 to High(alist) do
    alist[i].SaveToStream(AStream, aVersion);
end;

end.
