unit TLSGChar;

interface

uses
  classes,
  rgstream,
  tlsgcommon,
  rgglobal,
  tlsgbase,
  tlsgactive,
  tlsgeffects,
  tlsgitem;

type
  TTL2Action = (Idle, Attack, Defence);
type
  TTL2CharType = (ctPlayer, ctPet, ctMob);
type
  TTL2AIType = (
    NORMAL,
    RANGEDEFENDER,
    DEFENDER,
    RANGECASTER,
    CIRCLER,
    RESURRECTER,
    DUMMY,
    SUPPORT
  );

type
  TTL2Alignment = (
    NEUTRAL,
    GOOD,
    EVIL,
    ALL,
    BERSERK,
    EVILBERSERK,
    GOODBERSERK,
    SMASHABLE,
    NEUTRALHOSTILE,
    EVILONLY
  );

type
  TTL2Spell = record
    name :string;
    level:DWord;
  end;
  TTL2SpellList = array [0..3] of TTL2Spell;

type
  TTLCharacter = class(TLActiveClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TStream; aVersion:integer); override;
    procedure SaveToStream  (AStream: TStream; aVersion:integer); override;

  private
    FSign1          :Byte;
    FHidden         :Boolean;
    FCharType       :TTL2CharType;

    FWardrobe       :Boolean;

    // Pet's corner
    FMorphId        :TRGID;
    FScale          :TRGFloat;
    FSkin           :Byte;
    FMorphTime      :TRGFloat;
    FTownTime       :TRGFloat;
    FAction         :TTL2Action;
    FAlignment      :TTL2Alignment;
    FBravery        :TRGFloat;
    FAIType         :TTL2AIType;

    // unknowns
    FUnkn1          :TRGID;
    FUnkn2          :Byte;
    FUnkn3          :DWord;
    FUnkn4_1        :byte;
    FUnkn4_2        :byte;
    FUnkn7          :array [0..2] of TRGID;
    FUnkn17         :DWord;
    FUnkn9_1        :DWord;
    FUnkn9_2        :DWord;
    FUnkn11         :DWord;
    FUnkn12         :DWord;
    FUnkn14_1,
    FUnkn14_2,
    FUnkn14_3       :DWord;
    FUnkn15_1       :DWord;
    FUnkn15_2       :QWord;
    FUnkn15_3       :DWord;

    // player's Wardrobe etc
    FFace           :integer;
    FHairstyle      :integer;
    FHairColor      :integer;
    FFeature1       :integer;
    FFeature2       :integer;
    FFeature3       :integer;
    FGloves         :integer;
    FHead           :integer;
    FTorso          :integer;
    FPants          :integer;
    FShoulders      :integer;
    FBoots          :integer;

    FCheater        :byte;
    FPlayer         :string;

    FRewardExp      :integer;
    FRewardFame     :integer;
    FArmorFire      :integer;
    FArmorIce       :integer;
    FArmorElectric  :integer;
    FArmorPoison    :integer;
    // looks like common
    FExperience     :integer;
    FFameLevel      :integer;
    FFameExp        :integer;
    FHealth         :TRGFloat;
    FHealthBonus    :integer;
    FMana           :TRGFloat;
    FManaBonus      :integer;
    FPlayTime       :TRGFloat;
    FFreeSkillPoints:integer;
    FFreeStatPoints :integer;
    FStrength       :integer;
    FDexterity      :integer;
    FVitality       :integer;
    FFocus          :integer;
    FGold           :integer;
    FSkills         :TL2IdValList;
    FSpells         :TTL2SpellList;
    FItems          :TTLItemList;

    // buttons
    FRMB1 :TRGID;
    FRMB2 :TRGID;
    FLMB  :TRGID;
    FARMB1:TRGID;
    FARMB2:TRGID;
    FALMB :TRGID;

    function  GetStat(const iname:string):TRGInteger;
    procedure SetStat(const iname:string; aval:TRGInteger);
    function  GetSpell(idx:integer):TTL2Spell;
    procedure SetSpell(idx:integer; const aspell:TTL2Spell);
  protected
    function  GetDBMods():string; override;
  public
    function CheckForMods(alist:TTL2ModList):boolean;

    property Action:TTL2Action read FAction write FAction;
    property CharType       :TTL2CharType read FCharType;
    property Sign1          :Byte       read FSign1;
    property Hidden         :Boolean    read FHidden          write FHidden;
    property MorphId        :TRGID      read FMorphId         write FMorphId;
    property Player         :string     read FPlayer          write FPlayer;
    property MorphTime      :TRGFloat   read FMorphTime       write FMorphTime;
    property TownTime       :TRGFloat   read FTownTime        write FTownTime;

    property Face           :integer    read FFace            write FFace;
    property Hairstyle      :integer    read FHairstyle       write FHairstyle;
    property HairColor      :integer    read FHairColor       write FHairColor;
    property Feature1       :integer    read FFeature1        write FFeature1;
    property Feature2       :integer    read FFeature2        write FFeature2;
    property Feature3       :integer    read FFeature3        write FFeature3;
    property Gloves         :integer    read FGloves          write FGloves;
    property Head           :integer    read FHead            write FHead;
    property Torso          :integer    read FTorso           write FTorso;
    property Pants          :integer    read FPants           write FPants;
    property Shoulders      :integer    read FShoulders       write FShoulders;
    property Boots          :integer    read FBoots           write FBoots;

    property Cheater        :byte       read FCheater         write FCheater;
    property Experience     :integer    read FExperience      write FExperience;
    property FameLevel      :integer    read FFameLevel       write FFameLevel;
    property FameExp        :integer    read FFameExp         write FFameExp;
    property Health         :TRGFloat   read FHealth          write FHealth;
    property HealthBonus    :integer    read FHealthBonus     write FHealthBonus;
    property Mana           :TRGFloat   read FMana            write FMana;
    property ManaBonus      :integer    read FManaBonus       write FManaBonus;
    property PlayTime       :TRGFloat   read FPlayTime        write FPlayTime;
    property FreeSkillPoints:integer    read FFreeSkillPoints write FFreeSkillPoints;
    property FreeStatPoints :integer    read FFreeStatPoints  write FFreeStatPoints;
    property ArmorFire      :integer    read FArmorFire       write FArmorFire;
    property ArmorIce       :integer    read FArmorIce        write FArmorIce;
    property ArmorElectric  :integer    read FArmorElectric   write FArmorElectric;
    property ArmorPoison    :integer    read FArmorPoison     write FArmorPoison;
    property Strength       :integer    read FStrength        write FStrength;
    property Dexterity      :integer    read FDexterity       write FDexterity;
    property Vitality       :integer    read FVitality        write FVitality;
    property Focus          :integer    read FFocus           write FFocus;
    property Gold           :integer    read FGold            write FGold;
    property Scale          :TRGFloat   read FScale           write FScale;
    property Skin           :byte       read FSkin            write FSkin;
    property RewardExp      :integer    read FRewardExp       write FRewardExp;
    property RewardFame     :integer    read FRewardFame      write FRewardFame;

    property Spells[idx:integer ]:TTL2Spell  read GetSpell write SetSpell;
    property Skills:TL2IdValList read FSkills  write FSkills;
    property Items :TTLItemList  read FItems  {write FItems};
  end;
type
  TTLCharArray = array of TTLCharacter;

function ReadCharData(AStream:TStream; aVersion:integer; aCharType:TTL2CharType):TTLCharacter;


implementation

uses
  rgdb;

//----- Init / Free -----

constructor TTLCharacter.Create;
begin
  inherited;

  DataType:=dtChar;
end;

destructor TTLCharacter.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTLCharacter.InternalClear;
var
  i:integer;
begin
  SetLength(FSkills,0);
  for i:=0 to High(FItems) do
    FItems[i].Free;
  SetLength(FItems,0);

  inherited;
end;

procedure TTLCharacter.Clear;
begin
  InternalClear;

  Inherited;
end;

//----- Properties -----

function TTLCharacter.GetDBMods():string;
begin
  if FDBMods='' then
  begin
    case FCharType of
      ctPlayer: FDBMods:=RGDBGetClassMods(FID);
      ctPet   : FDBMods:=RGDBGetPetMods(FID);
      ctMob   : FDBMods:=RGDBGetMobMods(FID);
    end;
  end;
  result:=FDBMods;
end;

function TTLCharacter.GetStat(const iname:string):TRGInteger;
var
  i:integer;
begin

  i:=RGDBGetStatIdx(Stats,iname);
  if i>=0 then
    result:=Stats[i].value
  else
    result:=0;
end;

procedure TTLCharacter.SetStat(const iname:string; aval:TRGInteger);
var
  i:integer;
begin
  i:=RGDBGetStatIdx(Stats,iname);
  if i>=0 then
    Stats[i].value:=aval;
end;

function TTLCharacter.GetSpell(idx:integer):TTL2Spell;
begin
  if idx in [0..3] then
  begin
    result.name :=FSpells[idx].name;
    result.level:=FSpells[idx].level;
  end
  else
  begin
    result.name :='';
    result.level:=0;
  end;
end;

procedure TTLCharacter.SetSpell(idx:integer; const aspell:TTL2Spell);
begin
  if idx in [0..3] then
  begin
    FSpells[idx].name :=aspell.name;
    FSpells[idx].level:=aspell.level;
  end;
end;

//----- Load / Save -----

procedure TTLCharacter.LoadFromStream(AStream: TStream; aVersion:integer);
var
  i,lcnt:integer;
begin
  DbgLn('start char');
  if aVersion>=tlsaveTL2Minimal then
    DataSize:=AStream.ReadDWord;

  DataOffset:=AStream.Position;

  // signature
  if aVersion>=$42 then
    FSign:=AStream.ReadByte;           // $FF (main char and pet) or 02 (monsters, additional pets)
  if aVersion>=tlsaveTL2Minimal then
  begin
    FSign1:=AStream.ReadByte;          // 0
    Check(FSign1,'sign 1 '+HexStr(AStream.Position,8),0);
  end;

  FHidden  :=AStream.ReadByte<>0;
	
  FMorphId:=TRGID(AStream.ReadQWord);  // current Class ID (with sex)
  FID     :=TRGID(AStream.ReadQword);  // *$FF or base class id (if morphed)
  if FID=RGIdEmpty then
  begin
    FID     :=FMorphId;
    FMorphId:=RGIdEmpty;
  end;
  //??
  FUnkn1:=TRGID(AStream.ReadQword);    //!! runtime ID

  if aVersion>=tlsaveTL2Minimal then
  begin
    //??
    FUnkn2:=AStream.ReadByte;
    Check(FUnkn2,'pre-wardrobe_'+HexStr(AStream.Position,8),0);
  {
    1 - ??NPC?? and Brazier too
    but "Rusted Dwarven Mechanoid"?? inactive state maybe?
    forest gargoyle
  }
    // Really, THIS flag IS mean ctPlayer
    FWardrobe:=AStream.ReadByte<>0;    // not sure but why not?
    if FWardrobe then
    begin
      if FCharType<>ctPlayer then DbgLn('!!non-player wardrobe_'+HexStr(AStream.Position,8));
      FFace     :=Integer(AStream.ReadDWord);  // (FACE) face
      FHairStyle:=Integer(AStream.ReadDWord);  // (HAIR) hairstyle
      FHairColor:=Integer(AStream.ReadDWord);  // (HAIRCOLOR) haircolor (+bandana for outlander)
      FFeature1 :=Integer(AStream.ReadDWord);  // (FEATURE1) like Underwear
      FFeature2 :=Integer(AStream.ReadDWord);  // (FEATURE2) like Bagpack
      FFeature3 :=Integer(AStream.ReadDWord);  // (FEATURE3)
      FGloves   :=Integer(AStream.ReadDWord);  // (GLOVES)
      FHead     :=Integer(AStream.ReadDWord);  // (HEAD)
      FTorso    :=Integer(AStream.ReadDWord);  // (TORSO)
      FPants    :=Integer(AStream.ReadDWord);  // (PANTS)
      FShoulders:=Integer(AStream.ReadDWord);  // (SHOULDERS)
      FBoots    :=Integer(AStream.ReadDWord);  // (BOOTS)
    end;
    //??
    FUnkn3:=AStream.ReadDWord;  // 0
    Check(FUnkn3,'pre-pet enabled_'+HexStr(AStream.Position,8),0);
    {
      1=Nether-Thrall; 2=snowfang or 4=skeleton (like alignment)
      22 for one NPC (quest? assist?)
    }
    FEnabled:=AStream.ReadByte<>0;     // 1 (pet - enabled)

    //??  if aVersion<$24 then FUnkn4_1:=0 else
    FUnkn4_1:=AStream.ReadByte;        // ??non-interract??
    if FUnkn4_1<>0 then DbgLn('  idk really at '+HexStr(AStream.Position,8));
    {
     some of NPCs; chests; snakes and frogs
    }
    FUnkn4_2:=AStream.ReadByte;        // ??BOSS??
    if FUnkn4_2<>0 then DbgLn('  like a boss at '+HexStr(AStream.Position,8));

  //!!  if aVersion<$2F then AStream.ReadByte;
  end
  else
  begin
    FUnkn2  :=AStream.ReadByte;
    FUnkn3  :=AStream.ReadByte;
    FEnabled:=AStream.ReadByte<>0; // 1
    FUnkn4_1:=AStream.ReadByte;
    FUnkn4_2:=AStream.ReadByte;
  end;
  
  if (FCharType=ctPlayer) or           //!! if ver<0x30 or FWardrobe
     (aVersion<tlsaveTL2Minimal) then
    FCheater:=AStream.ReadByte;        //!! cheat (67($43) or 78($4E)[=elfly] no cheat, 214($D6) IS cheat

  if aVersion>=tlsaveTL2Minimal then
    FAIType:=TTL2AIType(AStream.ReadByte); // if ver>=$1E

  FMorphTime:=AStream.ReadFloat;       // pet morph time, sec
  FTownTime :=AStream.ReadFloat;       // time to town, sec
  FAction   :=TTL2Action(AStream.ReadDWord);     // pet action (idle, defense, attack)
  FAlignment:=TTL2Alignment(AStream.ReadDWord);  // Alignment

  FScale:=AStream.ReadFloat;           // scale (1.0 for char) (pet size)

  Funkn7[0]:=TRGID(AStream.ReadQWord); // -1 // !! "master" runtime ID, player or "unit spawner"
  Funkn7[1]:=TRGID(AStream.ReadQWord); // -1 // /(chest?) unit spawner/ in some layouts
  if Funkn7[0]<>RGIdEmpty then DbgLn('  after scale[0]='+HexStr(Funkn7[0],16)+' at '+HexStr(AStream.Position,8));
  if Funkn7[1]<>RGIdEmpty then DbgLn('  after scale[1]='+HexStr(Funkn7[1],16)+' at '+HexStr(AStream.Position,8));

  if aVersion>=tlsaveTL2Minimal then
  begin
    Funkn7[2]:=TRGID(AStream.ReadQWord);
    if Funkn7[2]<>RGIdEmpty then DbgLn('  after scale[2]='+HexStr(Funkn7[2],16)+' at '+HexStr(AStream.Position,8));
  end;

  //??
  FUnkn17:=AStream.ReadDWord;
  //  isPet:=(FUnkn17=$FFFFFFFF); //  const. elfly=69DF417B ?? if not -1 then "player" presents
  if FUnkn17<>$FFFFFFFF then DbgLn('pre-name is '+HexStr(FUnkn17,8));

  FName:=AStream.ReadShortString();    // Char name
  DbgLn('  name:'+FName);

  if aVersion>=tlsaveTL2Minimal then
  begin
    FSuffix:=AStream.ReadShortString();    // ver>=$16 like mob title "(Teleporting)"
    if FCharType=ctPlayer then                        // if ver >=0x26 or FWardrobe
      FPlayer:=AStream.ReadShortString();  // "PLAYER" (prefix) !!!!! not exists for pets!!!!!!
  end;
  
  //??
  FUnkn9_1:=AStream.ReadDWord; // 0
  Check(FUnkn9_1,'after player '+HexStr(AStream.Position,8),0);
  FUnkn9_2:=AStream.ReadDWord; // 0
  Check(FUnkn9_2,'like unkstat '+HexStr(AStream.Position,8),0);
  {
    maybe flag mask? 0,1,2,[4],7...
  }

  AStream.Read(FOrientation,SizeOf(FOrientation));

  FLevel      :=AStream.ReadDWord;     // level
  FExperience :=AStream.ReadDWord;     // exp
  FFameLevel  :=AStream.ReadDWord;     // fame level
  FFameExp    :=AStream.ReadDWord;     // fame exp
  FHealth     :=AStream.ReadFloat;     // current HP
  FHealthBonus:=AStream.ReadDWord;     // health bonus (pet=full hp)
  //??
  FUnkn11     :=AStream.ReadDWord;     // 0
  if FUnkn11<>0 then DbgLn(' after hp '+HexStr(FUnkn11,8)+' at '+HexStr(AStream.Position,8));
  FMana       :=AStream.ReadFloat;     // current MP
  FManaBonus  :=AStream.ReadDWord;     // Mana bonus   (pet=full mp)
  //??
  FUnkn12     :=AStream.ReadDWord;     // 0
  if Funkn12<>0 then DbgLn('  after mana '+HexStr(Funkn12,8)+' at '+HexStr(AStream.Position,8));

  FRewardExp  :=AStream.ReadDWord;     // Reward exp (stat "Experience_Monster")
  FRewardFame :=AStream.ReadDWord;     // Reward fame

  FPlayTime   :=AStream.ReadFloat;     // play time, sec
  FBravery    :=AStream.ReadFloat;

  FFreeStatPoints :=AStream.ReadDWord; // unallocated statpoints
  FFreeSkillPoints:=AStream.ReadDWord; // unallocated skillpoints

  if aVersion<tlsaveTL2Minimal then    //!!
    AStream.ReadDWord;

  // mouse button skills.
  FRMB1 :=TRGID(AStream.ReadQWord);    // skill ID RMB active = Pet 1st spell?
  FRMB2 :=TRGID(AStream.ReadQWord);    // skill ID RMB secondary
  FLMB  :=TRGID(AStream.ReadQWord);    // skill ID LMB
  if aVersion>=tlsaveTL2Minimal then
  begin
    // second weapon set (!!!!!!!!!) not for pets
    FARMB1:=TRGID(AStream.ReadQWord);  // skill ID RMB active
    FARMB2:=TRGID(AStream.ReadQWord);  // skill ID RMB secondary
    FALMB :=TRGID(AStream.ReadQWord);  // skill ID LMB
  end;

  if aVersion>=tlsaveTL2Minimal then
  begin
    // CURRENT Skill list. depends of current weapon (passive mainly)
    FSkills:=AStream.ReadIdValList;
  end
  else
  begin
    //!!!!!!!!!!!!!!!!!!!
    // Skill levels
    lcnt:=AStream.ReadDWord;
    SetLength(FSkills,lcnt);
    for i:=0 to lcnt-1 do
      FSkills[i].value:=AStream.ReadDWord;
  end;

  // Spell list
  for i:=0 to 3 do
  begin
    FSpells[i].name :=AStream.ReadShortString; // spell name
    FSpells[i].level:=AStream.ReadDWord;       // spell level
  end;

  //??
  FUnkn14_1:=AStream.ReadDword;        //?? phys
  Check(FUnkn14_1,'FUnkn14_1 '+HexStr(AStream.Position,8),0);
  FUnkn14_2:=AStream.ReadDword;        //?? magic
  Check(FUnkn14_2,'FUnkn14_2 '+HexStr(AStream.Position,8),0);
  FArmorFire    :=AStream.ReadDword;
  FArmorIce     :=AStream.ReadDword;
  FArmorElectric:=AStream.ReadDword;
  FArmorPoison  :=AStream.ReadDword;
  FUnkn14_3:=AStream.ReadDword;        //?? all emements
  Check(FUnkn14_3,'FUnkn14_3 '+HexStr(AStream.Position,8),0);

  FStrength :=AStream.ReadDWord;       // strength      0 for pet
  FDexterity:=AStream.ReadDWord;       // dexterity     0 for pet
  FVitality :=AStream.ReadDWord;       // vitality      10\ sure, pet have hp/mp bonuses
  FFocus    :=AStream.ReadDWord;       // focus         10/
  FGold     :=AStream.ReadDWord;       // gold          0

  //??
  Funkn15_1:=AStream.ReadDWord;
  Funkn15_2:=AStream.ReadQWord;
  Funkn15_3:=AStream.ReadDWord;
  if Funkn15_1<>0         then DbgLn('  after gold[0]='+HexStr(Funkn15_1,8 )+' at '+HexStr(AStream.Position,8));
  if Funkn15_2<>QWord(-1) then DbgLn('  after gold[1]='+HexStr(Funkn15_2,16)+' at '+HexStr(AStream.Position,8));
  if Funkn15_3<>DWord(-1) then DbgLn('  after gold[3]='+HexStr(Funkn15_3,8 )+' at '+HexStr(AStream.Position,8));
  {
    AStream.ReadDWord;                 // -1 at start; 0..11
    AStream.ReadQWord;                 // -1 or QUEST_GUID
    AStream.ReadDWord;                 // -1 "3" - quest state?
  }

  if aVersion>=tlsaveTL2Minimal then
    FSkin:=AStream.ReadByte;           // ver>=$2D FF OR pet texture (color)

  if aVersion>=tlsaveTL2Minimal then
    FModIds:=AStream.ReadIdList
  else
    FModNames:=AStream.ReadShortStringList;

  //----- item list -----

  FItems:=ReadItemList(AStream, aVersion);

  //----- Effects -----
  // dynamic,passive,transfer

  for i:=0 to 2 do
    FEffects[i]:=ReadEffectList(AStream,aVersion,true);

  if aVersion>=tlsaveTL2Minimal then
  begin
    FAugments:=AStream.ReadShortStringList;

    //----- STATS -----

  { two base:
    CURRENT_PLAYER_STAT_PTS  - unallocated stat points
    CURRENT_PLAYER_SKILL_PTS - unallocated skill points
    multiply_hotbar adds SELECTED_HOTBAR stat
  }
    FStats:=AStream.ReadIdValList;

    //----- Fixes -----

    if FCharType=ctPlayer then
    begin
      i:=RGDBGetStatIdx(FStats,DefaultStats[DefStatStat].id);
      if i>=0 then
      begin
        if      FFreeStatPoints<FStats[i].value then FFreeStatPoints:=FStats[i].value
        else if FFreeStatPoints>FStats[i].value then FStats[i].value:=FFreeStatPoints;
      end;
      i:=RGDBGetStatIdx(FStats,DefaultStats[DefStatSkill].id);
      if i>=0 then
      begin
        if      FFreeSkillPoints<FStats[i].value then FFreeSkillPoints:=FStats[i].value
        else if FFreeSkillPoints>FStats[i].value then FStats[i].value:=FFreeSkillPoints;
      end;
    end;
  end;

  DbgLn('end char'#13#10'---------');
  LoadBlock(AStream);
end;

procedure TTLCharacter.SaveToStream(AStream: TStream; aVersion:integer);
var
  i:integer;
begin
  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteDWord(DataSize);

  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;

  //----- Fixes -----

  if FCharType=ctPlayer then
  begin
    i:=RGDBGetStatIdx(FStats,DefaultStats[DefStatStat].id);
    if i>=0 then
    begin
      if      FFreeStatPoints<FStats[i].value then FFreeStatPoints:=FStats[i].value
      else if FFreeStatPoints>FStats[i].value then FStats[i].value:=FFreeStatPoints;
    end;
    i:=RGDBGetStatIdx(FStats,DefaultStats[DefStatSkill].id);
    if i>=0 then
    begin
      if      FFreeSkillPoints<FStats[i].value then FFreeSkillPoints:=FStats[i].value
      else if FFreeSkillPoints>FStats[i].value then FStats[i].value:=FFreeSkillPoints;
    end;
  end;

  // signature
  if aVersion>=$42 then
    AStream.WriteByte(FSign );         // $FF or 2
  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteByte(FSign1);         // 0

  AStream.WriteByte(byte(FHidden) and 1);

  if FMorphId=RGIdEmpty then
  begin
    AStream.WriteQWord(QWord(FID));
    AStream.WriteQWord(QWord(RGIdEmpty));
  end
  else
  begin
    AStream.WriteQWord(QWord(FMorphId));
    AStream.WriteQWord(QWord(FID));
  end;
  AStream.WriteQWord(QWord(FUnkn1));    //!! (changing) (F6ED2564.F596F9AA)

  if aVersion>=tlsaveTL2Minimal then
  begin
    AStream.WriteByte(FUnkn2);
    AStream.WriteByte(byte(FWardrobe) and 1);
    if FWardrobe then // WARDROBE
    begin
      AStream.WriteDWord(Cardinal(FFace     ));  // face
      AStream.WriteDWord(Cardinal(FHairStyle));  // hairstyle
      AStream.WriteDWord(Cardinal(FHairColor));  // haircolor (+bandana for outlander)
      AStream.WriteDWord(Cardinal(FFeature1 ));
      AStream.WriteDWord(Cardinal(FFeature2 ));
      AStream.WriteDWord(Cardinal(FFeature3 ));
      AStream.WriteDWord(Cardinal(FGloves   ));
      AStream.WriteDWord(Cardinal(FHead     ));
      AStream.WriteDWord(Cardinal(FTorso    ));
      AStream.WriteDWord(Cardinal(FPants    ));
      AStream.WriteDWord(Cardinal(FShoulders));
      AStream.WriteDWord(Cardinal(FBoots    ));
    end;

    AStream.WriteDWord(FUnkn3);
    AStream.WriteByte (byte(FEnabled) and 1);
    AStream.WriteByte (FUnkn4_1);
    AStream.WriteByte (FUnkn4_2);
  end
  else
  begin
    AStream.WriteByte(FUnkn2);
    AStream.WriteByte(FUnkn3);
    AStream.WriteByte(byte(FEnabled) and 1);
    AStream.WriteByte(FUnkn4_1);
    AStream.WriteByte(FUnkn4_2);
  end;

  if (FCharType=ctPlayer) or
     (aVersion<tlsaveTL2Minimal) then
    AStream.WriteByte(FCheater);

  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteByte(ord(FAIType));

  AStream.WriteFloat(FMorphTime);
  AStream.WriteFloat(FTownTime);        // time to town,sec?
  AStream.WriteDWord(ord(FAction));     // 1  (pet status)
  AStream.WriteDWord(ord(FAlignment));  // 1
  AStream.WriteFloat(FScale);           // scale (1.0 for char) (pet size)
  
  AStream.WriteQWord(QWord(FUnkn7[0]));
  AStream.WriteQWord(QWord(FUnkn7[1]));
  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteQWord(QWord(FUnkn7[2]));

  AStream.WriteDWord(FUnkn17);

  AStream.WriteShortString(FName);
  if aVersion>=tlsaveTL2Minimal then
  begin
    AStream.WriteShortString(FSuffix);
    if FCharType=ctPlayer{(FUnkn17<>$FFFFFFFF)} then
      AStream.WriteShortString(FPlayer);  // "PLAYER" !!!!! not exists for pets!!!!!!
  end;
  
  AStream.WriteDWord(FUnkn9_1);
  AStream.WriteDWord(FUnkn9_2);

  AStream.Write(FOrientation,SizeOf(FOrientation));

  AStream.WriteDWord(FLevel);           // level
  AStream.WriteDWord(FExperience);      // exp
  AStream.WriteDWord(FFameLevel);       // fame level
  AStream.WriteDWord(FFameExp);         // fame
  AStream.WriteFloat(FHealth);          // current HP
  AStream.WriteDWord(FHealthBonus);     // health bonus (pet=full hp)
  AStream.WriteDWord(FUnkn11);
  AStream.WriteFloat(FMana);            // current MP
  AStream.WriteDWord(FManaBonus);       // Mana bonus   (pet=full mp)

  AStream.WriteDWord(FUnkn12);
  AStream.WriteDWord(FRewardExp);       // reward - exp
  AStream.WriteDWord(FRewardFame);      // reward - fame

  AStream.WriteFloat(FPlayTime);        // play time, sec
  AStream.WriteFloat(FBravery);         // 1.0
  AStream.WriteDWord(FFreeStatPoints ); // unallocated statpoints ? (elfly have 35 with 30 in fact)
  AStream.WriteDWord(FFreeSkillPoints); // unallocated skillpoints? (elfly have 28 with 28 in fact)

  if aVersion<tlsaveTL2Minimal then     //!!
    AStream.WriteDWord(0);

  // mouse button skils
  AStream.WriteQWord(QWord(FRMB1));     // skill ID RMB active = Pet 1st spell?
  AStream.WriteQWord(QWord(FRMB2));     // skill ID RMB secondary
  AStream.WriteQWord(QWord(FLMB ));     // skill ID LMB

  // second weapon set
  if aVersion>=tlsaveTL2Minimal then
  begin
    AStream.WriteQWord(QWord(FARMB1));  // skill ID RMB active
    AStream.WriteQWord(QWord(FARMB2));  // skill ID RMB secondary
    AStream.WriteQWord(QWord(FALMB ));  // skill ID LMB
  end;

  if aVersion>=tlsaveTL2Minimal then
  begin
    // CURRENT Skill list. depends of current weapon (passive mainly)
    AStream.WriteIdValList(FSkills);
  end
  else
  begin
    AStream.WriteDWord(Length(FSkills));
    for i:=0 to High(FSkills) do
      AStream.WriteDWord(FSkills[i].value);
  end;

  // Spell list
  for i:=0 to 3 do
  begin
    AStream.WriteShortString(FSpells[i].name ); // spell name
    AStream.WriteDWord      (FSpells[i].level); // spell level
  end;

  AStream.WriteDWord(FUnkn14_1);
  AStream.WriteDWord(FUnkn14_2);
  AStream.WriteDWord(FArmorFire);
  AStream.WriteDWord(FArmorIce);
  AStream.WriteDWord(FArmorElectric);
  AStream.WriteDWord(FArmorPoison);
  AStream.WriteDWord(FUnkn14_3);

  AStream.WriteDWord(FStrength );     // strength      0 for pet
  AStream.WriteDWord(FDexterity);     // dexterity     0 for pet
  AStream.WriteDWord(FVitality );     // vitality      10\ sure, pet have hp/mp bonuses
  AStream.WriteDWord(FFocus    );     // focus         10/
  AStream.WriteDWord(FGold     );     // gold          0

  AStream.WriteDWord(FUnkn15_1);
  AStream.WriteQWord(FUnkn15_2);
  AStream.WriteDWord(FUnkn15_3);

  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteByte(FSkin);         // FF OR pet texture (color)

  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteIdList(FModIds)      // mod id list
  else
    AStream.WriteShortStringList(FModNames);

  //!!!!  next is not supports tl1 yet

  WriteItemList(AStream,FItems, aVersion);

  //----- Effects -----
  // dynamic,passive,transfer

  for i:=0 to 2 do
    WriteEffectList(AStream,FEffects[i], aVersion);

  if aVersion>=tlsaveTL2Minimal then
  begin
    AStream.WriteShortStringList(FAugments);
    
    //----- STATS -----

    AStream.WriteIdValList(FStats);
  end;

  LoadBlock(AStream);

  if aVersion>=tlsaveTL2Minimal then
    FixSize(AStream);
end;

function ReadCharData(AStream:TStream; aVersion:integer; aCharType:TTL2CharType):TTLCharacter;
begin
  result:=TTLCharacter.Create();
  result.FCharType:=aCharType;
  try
    result.LoadFromStream(AStream,aVersion);
  except
    RGLog.Add('got char exception at '+HexStr(result.DataOffset,8));
    AStream.Position:=result.DataOffset+result.DataSize;
  end;
end;

//----- Other -----

function TTLCharacter.CheckForMods(alist:TTL2ModList):boolean;
begin
  result:=inherited CheckForMods(alist);

  // really, "not char" means "just pet" here
  // means, ModIds is nil
  // so, we just replace pet type by one of standard type
  if not result and (FCharType<>ctPlayer) then
  begin
    FID:=RGDBGetDefaultPet();
    Changed:=true;
    result:=true;
  end;
end;

end.
