{}
unit TL2Modifiers;

interface

uses
  Classes,
  TL2Stream;

type
  TTL2ModifierDamageType = (Physical, Magical, Fire, Ice, Electric, Poison, All);
  TTL2ModifierSource     = (OnCastCaster, OnCastReceiver, OnUpdateCaster, OnUpdateSelf);
  TTL2ModifierActivation = (Passive, Dynamic, Transfer);

  TTL2ModifierFlag = (
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
    modIsDisabled          // $00200000
  );

  TTL2ModifierFlags = set of TTL2ModifierFlag;

type
  TTL2StatName = packed record
    id        :Int64;
    percentage:single;
  end;

type
  TTL2Modifier = class;
  TTL2ModifierList = array of TTL2Modifier;
type
  TTL2Modifier = class
  private
    FFlags       :TTL2ModifierFlags;
    FName        :string;
    FGraph       :string;
    FParticles   :string;
    FUnitThemeId :QWord;
    FProperties  :array of single;
    FStatNames   :array of TTL2StatName;
    FEffectType  :integer;
    FDamageType  :TTL2ModifierDamageType;
    FActivation  :TTL2ModifierActivation;
    FLevel       :integer;
    FDuration    :single;
//        public byte[] Unknown1 { get; set; }
    FDisplayValue:single;
    FSource      :TTL2ModifierSource;
    FIcon        :string;

    function GetProperties(idx:integer):single;
    function GetStatNames (idx:integer):TTL2StatName;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

    property Flags       :TTL2ModifierFlags         read FFlags        write FFlags; //??
    property Name        :string                    read FName         write FName;
    property Graph       :string                    read FGraph        write FGraph;
    property Particles   :string                    read FParticles    write FParticles;
    property UnitThemeId :QWord                     read FUnitThemeId  write FUnitThemeId;
    property Properties  [idx:integer]:single       read GetProperties; //!!
    property StatNames   [idx:integer]:TTL2StatName read GetStatNames;  //!!
    property EffectType  :integer                   read FEffectType   write FEffectType;
    property DamageType  :TTL2ModifierDamageType    read FDamageType   write FDamageType;
    property Activation  :TTL2ModifierActivation    read FActivation   write FActivation;
    property Level       :integer                   read FLevel        write FLevel;
    property Duration    :single                    read FDuration     write FDuration;
    property DisplayValue:single                    read FDisplayValue write FDisplayValue;
    property Source      :TTL2ModifierSource        read FSource       write FSource;
    property Icon        :string                    read FIcon         write FIcon;
  end;


function ReadModifierList(AStream:TTL2Stream):TTL2ModifierList;


implementation


constructor TTL2Modifier.Create;
begin
  inherited;

end;

destructor TTL2Modifier.Destroy;
begin
  SetLength(FProperties,0);
  SetLength(FStatNames ,0);

  inherited;
end;

function TTL2Modifier.GetProperties(idx:integer):single;
begin
  if (idx>=0) and (idx<Length(FProperties)) then
    result:=FProperties[idx]
  else
    result:=0;
end;

function TTL2Modifier.GetStatNames(idx:integer):TTL2StatName;
begin
  if (idx>=0) and (idx<Length(FStatNames)) then
    result:=FStatNames[idx]
  else
  begin
    result.id:=-1;
    result.percentage:=0;
  end;
end;

procedure TTL2Modifier.LoadFromStream(AStream: TTL2Stream);
var
  i,lcnt:integer;
begin
  FFlags:=TTL2ModifierFlags(AStream.ReadDword); // $00008041
  FName :=AStream.ReadShortString();

  //?? what about modHasLinkName

  if modHasGraph in FFlags then
    FGraph:=AStream.ReadShortString();

  if modHasParticles in FFlags then
    FParticles:=AStream.ReadShortString();

  if modHasUnitTheme in FFlags then
    FUnitThemeId:=AStream.ReadQWord();

  lcnt:=AStream.ReadByte();
  SetLength(FProperties,lcnt); // 40800000 = 4.0
  for i:=0 to lcnt-1 do
    FProperties[i]:=AStream.ReadFloat;

  lcnt:=AStream.ReadWord; // 0
  SetLength(FStatNames,lcnt);
  if lcnt>0 then
    AStream.Read(FStatNames[0],lcnt*SizeOf(TTL2StatName));

  FEffectType := AStream.ReadDWord(); // $67

  FDamageType := TTL2ModifierDamageType(AStream.ReadDWord); // 6
  FActivation := TTL2ModifierActivation(AStream.ReadDWord); // 0

  FLevel   :=AStream.ReadDWord;    // $30  -as item
  FDuration:=AStream.ReadFloat;   // -1000 ms?
  AStream.ReadDWord;  // 0
  FDisplayValue := AStream.ReadFloat;       // 4.0

  FSource := TTL2ModifierSource(AStream.ReadDWord);  // 3

  if modHasIcon in FFlags then
    FIcon:=AStream.ReadByteString();

end;

procedure TTL2Modifier.SaveToStream(AStream: TTL2Stream);
begin
end;

function ReadModifierList(AStream:TTL2Stream):TTL2ModifierList;
var
  i,lcnt:integer;
begin
  result:=nil;
  lcnt:=AStream.ReadDWord;
  if lcnt>0 then
  else
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
    begin
      result[i]:=TTL2Modifier.Create;
      result[i].LoadFromStream(AStream);
    end;
  end;
end;

end.
