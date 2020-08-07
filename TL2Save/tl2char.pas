unit TL2Char;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2types,
  tl2base,
  tl2active,
  tl2effects,
  tl2item;

type
  TTL2Action = (Idle, Attack, Defence);
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
  TTL2Character = class(TL2ActiveClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TTL2Stream); override;
    procedure SaveToStream  (AStream: TTL2Stream); override;

  private
    FSign1          :Byte;
    FHidden         :TL2Boolean;
    FIsChar         :boolean;
    FIsPet          :boolean;

    FWardrobe       :TL2Boolean;

    // Pet's corner
    FMorphId        :TL2ID;
    FScale          :TL2Float;
    FSkin           :Byte;
    FMorphTime      :TL2Float;
    FTownTime       :TL2Float;
    FAction         :TTL2Action;
    FAlignment      :TTL2Alignment;
    FBravery        :TL2Float;
    FAIType         :TTL2AIType;

    // unknowns
    FUnkn1          :TL2ID;
    FUnkn2          :Byte;
    FUnkn3          :DWord;
    FUnkn4_1        :byte;
    FUnkn4_2        :byte;
    FUnkn7          :array [0..2] of TL2ID;
    FUnkn17         :DWord;
    FUnkn9_1        :DWord;
    FUnkn9_2        :DWord;
    FUnkn11         :DWord;
    FUnkn12         :DWord;
    FUnkn14_1,
    FUnkn14_2,
    FUnkn14_3       :DWord;
    FUnkn15         :array [0..3] of dword;

    // player's Wardrobe etc
    FWardUnkn       :array [0..8] of dword;
    FFace           :integer;
    FHairstyle      :integer;
    FHairColor      :integer;
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
    FHealth         :TL2Float;
    FHealthBonus    :integer;
    FMana           :TL2Float;
    FManaBonus      :integer;
    FPlayTime       :TL2Float;
    FFreeSkillPoints:integer;
    FFreeStatPoints :integer;
    FStrength       :integer;
    FDexterity      :integer;
    FVitality       :integer;
    FFocus          :integer;
    FGold           :integer;
    FSkills         :TL2IdValList;
    FSpells         :TTL2SpellList;
    FItems          :TTL2ItemList;

    // buttons
    FRMB1 :TL2ID;
    FRMB2 :TL2ID;
    FLMB  :TL2ID;
    FARMB1:TL2ID;
    FARMB2:TL2ID;
    FALMB :TL2ID;

    function  GetDBMods():string; override;
    function  GetStat(const iname:string):TL2Integer;
    procedure SetStat(const iname:string; aval:TL2Integer);
    function  GetSpell(idx:integer):TTL2Spell;
    procedure SetSpell(idx:integer; const aspell:TTL2Spell);
  public
    function CheckForMods(alist:TTL2ModList):boolean;

    property Action:TTL2Action read FAction write FAction;
    property IsChar         :boolean    read FIsChar;
    property IsPet          :boolean    read FIsPet;
    property Sign1          :Byte       read FSign1;
    property Hidden         :TL2Boolean read FHidden          write FHidden;
    property MorphId        :TL2ID      read FMorphId         write FMorphId;
    property Player         :string     read FPlayer          write FPlayer;
    property MorphTime      :TL2Float   read FMorphTime       write FMorphTime;
    property TownTime       :TL2Float   read FTownTime        write FTownTime;
    property Face           :integer    read FFace            write FFace;
    property Hairstyle      :integer    read FHairstyle       write FHairstyle;
    property HairColor      :integer    read FHairColor       write FHairColor;
    property Cheater        :byte       read FCheater         write FCheater;
    property Experience     :integer    read FExperience      write FExperience;
    property FameLevel      :integer    read FFameLevel       write FFameLevel;
    property FameExp        :integer    read FFameExp         write FFameExp;
    property Health         :TL2Float   read FHealth          write FHealth;
    property HealthBonus    :integer    read FHealthBonus     write FHealthBonus;
    property Mana           :TL2Float   read FMana            write FMana;
    property ManaBonus      :integer    read FManaBonus       write FManaBonus;
    property PlayTime       :TL2Float   read FPlayTime        write FPlayTime;
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
    property Scale          :TL2Float   read FScale           write FScale;
    property Skin           :byte       read FSkin            write FSkin;
    property RewardExp      :integer    read FRewardExp       write FRewardExp;
    property RewardFame     :integer    read FRewardFame      write FRewardFame;

    property Spells[idx:integer ]:TTL2Spell  read GetSpell write SetSpell;
    property Skills:TL2IdValList read FSkills  write FSkills;
    property Items :TTL2ItemList read FItems  {write FItems};
  end;
type
  TTL2CharArray = array of TTL2Character;

function ReadCharData(AStream:TTL2Stream; IsChar:boolean=false; IsPet:boolean=false):TTL2Character;


implementation

uses
  tl2db;

//----- Init / Free -----

constructor TTL2Character.Create;
begin
  inherited;

  DataType:=dtChar;
end;

destructor TTL2Character.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Character.InternalClear;
var
  i:integer;
begin
  SetLength(FSkills,0);
  for i:=0 to High(FItems) do
    FItems[i].Free;
  SetLength(FItems,0);

  inherited;
end;

procedure TTL2Character.Clear;
begin
  InternalClear;

  Inherited;
end;

//----- Properties -----

function TTL2Character.GetDBMods():string;
begin
  if FDBMods='' then
  begin
    if      FIsChar then FDBMods:=GetClassMods(FID)
    else if FIsPet  then FDBMods:=GetPetMods(FID)
    else                 FDBMods:=GetMobMods(FID);
  end;
  result:=FDBMods;
end;

function TTL2Character.GetStat(const iname:string):TL2Integer;
var
  i:integer;
begin

  i:=GetStatIdx(Stats,iname);
  if i>=0 then
    result:=Stats[i].value
  else
    result:=0;
end;

procedure TTL2Character.SetStat(const iname:string; aval:TL2Integer);
var
  i:integer;
begin
  i:=GetStatIdx(Stats,iname);
  if i>=0 then
    Stats[i].value:=aval;
end;

function TTL2Character.GetSpell(idx:integer):TTL2Spell;
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

procedure TTL2Character.SetSpell(idx:integer; const aspell:TTL2Spell);
begin
  if idx in [0..3] then
  begin
    FSpells[idx].name :=aspell.name;
    FSpells[idx].level:=aspell.level;
  end;
end;

//----- Load / Save -----

procedure TTL2Character.LoadFromStream(AStream: TTL2Stream);
var
  i:integer;
//  isPet:boolean;
begin
DbgLn('start char');
  DataSize  :=AStream.ReadDWord;
  DataOffset:=AStream.Position;

  // signature
  FSign    :=AStream.ReadByte;  // $FF (main char and pet) or 02 (monsters, additional pets)
  FSign1   :=AStream.ReadByte;  // 0
Check(FSign1,'sign 1 '+HexStr(AStream.Position,8),0);
{
  1 for Dwarven Sentry Top
}
  FHidden  :=AStream.ReadByte<>0;
	
  FMorphId:=TL2ID(AStream.ReadQWord); // current Class ID (with sex)
  FID     :=TL2ID(AStream.ReadQword); // *$FF or base class id (if morphed)
  if FID=TL2IdEmpty then
  begin
    FID     :=FMorphId;
    FMorphId:=TL2IdEmpty;
  end;
  //??
  FUnkn1:=TL2ID(AStream.ReadQword);   //!! runtime ID
  //??
  FUnkn2:=AStream.ReadByte;
Check(FUnkn2,'pre-wardrobe_'+HexStr(AStream.Position,8),0);
{
  1 - ??NPC?? and Brazier too
  but "Rusted Dwarven Mechanoid"?? inactive state maybe?
  forest gargoyle
}
  FWardrobe:=AStream.ReadByte<>0;     // not sure but why not?
  if FWardrobe then
  begin
if not FIsChar then DbgLn('!!non-player wardrobe_'+HexStr(AStream.Position,8));
    FFace     :=AStream.ReadDWord;    // face
    FHairStyle:=AStream.ReadDWord;    // hairstyle
    FHairColor:=AStream.ReadDWord;    // haircolor (+bandana for outlander)
    // !!*$FF = 36
    AStream.Read(FWardUnkn,36);
if
(FWardUnkn[0]<>$FFFFFFFF) or
(FWardUnkn[1]<>$FFFFFFFF) or
(FWardUnkn[2]<>$FFFFFFFF) or
(FWardUnkn[3]<>$FFFFFFFF) or
(FWardUnkn[4]<>$FFFFFFFF) or
(FWardUnkn[5]<>$FFFFFFFF) or
(FWardUnkn[6]<>$FFFFFFFF) or
(FWardUnkn[7]<>$FFFFFFFF) or
(FWardUnkn[8]<>$FFFFFFFF) then
DbgLn('!!unknown wardrobe at '+HexStr(AStream.Position,8));
{
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadDWord;
}
  end;
  //??
  FUnkn3:=AStream.ReadDWord;  // 0
Check(FUnkn3,'pre-pet enabled_'+HexStr(AStream.Position,8),0);
{
  1=Nether-Thrall; 2=snowfang or 4=skeleton (like alignment)
  22 for one NPC (quest? assist?)
}
  FEnabled:=AStream.ReadByte<>0; // 1 (pet - enabled)
  //??
  FUnkn4_1:=AStream.ReadByte;    // ??non-interract??
if FUnkn4_1<>0 then DbgLn('  idk really at '+HexStr(AStream.Position,8));
{
 some of NPCs; chests; snakes and frogs
}
  FUnkn4_2:=AStream.ReadByte;    // ??BOSS??
if FUnkn4_2<>0 then DbgLn('  like a boss at '+HexStr(AStream.Position,8));
  if FIsChar then
    FCheater:=AStream.ReadByte; //!!!! cheat (67($43) or 78($4E)[=elfly] no cheat, 214($D6) IS cheat
  //  :24 for pet, :55 for char
  FAIType   :=TTL2AIType(AStream.ReadByte);
  FMorphTime:=AStream.ReadFloat;   // pet morph time, sec
  FTownTime :=AStream.ReadFloat;   // time to town, sec
  FAction   :=TTL2Action(AStream.ReadDWord);     // pet action (idle, defense, attack)
  FAlignment:=TTL2Alignment(AStream.ReadDWord);  // Alignment

  FScale:=AStream.ReadFloat;   // scale (1.0 for char) (pet size)
  //??
  AStream.Read(FUnkn7,24);
if Funkn7[0]<>TL2IdEmpty then DbgLn('  after scale[0]='+HexStr(Funkn7[0],16)+' at '+HexStr(AStream.Position,8));
if Funkn7[1]<>TL2IdEmpty then DbgLn('  after scale[1]='+HexStr(Funkn7[1],16)+' at '+HexStr(AStream.Position,8));
if Funkn7[2]<>TL2IdEmpty then DbgLn('  after scale[2]='+HexStr(Funkn7[2],16)+' at '+HexStr(AStream.Position,8));
{
  AStream.ReadQWord;    // !! "master" runtime ID, player or "unit spawner"
  AStream.ReadQWord;    // -1 /unit spawner/ in some layouts
  AStream.ReadQWord;    // -1
}
  //??
  FUnkn17:=AStream.ReadDWord;
//  isPet:=(FUnkn17=$FFFFFFFF); //  const. elfly=69DF417B ?? if not -1 then "player" presents
if FUnkn17<>$FFFFFFFF then DbgLn('pre-name is '+HexStr(FUnkn17,8));

  FName  :=AStream.ReadShortString();    // :55(pet) Char name
DbgLn('  name:'+string(widestring(fname)));
  FSuffix:=AStream.ReadShortString();    // like mob title "(Teleporting)"
  if FIsChar then
    FPlayer:=AStream.ReadShortString();  // "PLAYER" (prefix) !!!!! not exists for pets!!!!!!
  //??
  FUnkn9_1:=AStream.ReadDWord; // 0
Check(FUnkn9_1,'after player '+HexStr(AStream.Position,8),0);
  FUnkn9_2:=AStream.ReadDWord; // 0 (SEE: Statistic=unknown) elfly=7, rage=2, lonelfly=2, zorro=0
Check(FUnkn9_2,'like unkstat '+HexStr(AStream.Position,8),0);
{
  maybe flag mask? 0,1,2,[4],7...
}

  AStream.Read(FOrientation,SizeOf(FOrientation));

  FLevel      :=AStream.ReadDWord;    // level
  FExperience :=AStream.ReadDWord;    // exp
  FFameLevel  :=AStream.ReadDWord;    // fame level
  FFameExp    :=AStream.ReadDWord;    // fame exp
  FHealth     :=AStream.ReadFloat;    // current HP
  FHealthBonus:=AStream.ReadDWord;    // health bonus (pet=full hp)
  //??
  FUnkn11     :=AStream.ReadDWord;    // 0
if FUnkn11<>0 then DbgLn(' after hp '+HexStr(FUnkn11,8)+' at '+HexStr(AStream.Position,8));
  FMana       :=AStream.ReadFloat;    // current MP
  FManaBonus  :=AStream.ReadDWord;    // Mana bonus   (pet=full mp)
  //??
  FUnkn12     :=AStream.ReadDWord;    // 0
if Funkn12<>0 then DbgLn('  after mana '+HexStr(Funkn12,8)+' at '+HexStr(AStream.Position,8));

  FRewardExp  :=AStream.ReadDWord;    // Reward exp (stat "Experience_Monster")
  FRewardFame :=AStream.ReadDWord;    // Reward fame

  FPlayTime   :=AStream.ReadFloat;    // play time, sec
  FBravery    :=AStream.ReadFloat;

  FFreeStatPoints :=AStream.ReadDWord; // unallocated statpoints
  FFreeSkillPoints:=AStream.ReadDWord; // unallocated skillpoints

  // mouse button skills.
  FRMB1 :=TL2ID(AStream.ReadQWord);    // skill ID RMB active = Pet 1st spell?
  FRMB2 :=TL2ID(AStream.ReadQWord);    // skill ID RMB secondary
  FLMB  :=TL2ID(AStream.ReadQWord);    // skill ID LMB
  // second weapon set (!!!!!!!!!) not for pets
  FARMB1:=TL2ID(AStream.ReadQWord);    // skill ID RMB active
  FARMB2:=TL2ID(AStream.ReadQWord);    // skill ID RMB secondary
  FALMB :=TL2ID(AStream.ReadQWord);    // skill ID LMB

  // CURRENT Skill list. depends of current weapon (passive mainly)
  FSkills:=AStream.ReadIdValList;

  // Spell list
  for i:=0 to 3 do
  begin
    FSpells[i].name :=AStream.ReadShortString; // spell name
    FSpells[i].level:=AStream.ReadDWord;       // spell level
  end;

  //??
  FUnkn14_1:=AStream.ReadDword;      //?? phys
Check(FUnkn14_1,'FUnkn14_1 '+HexStr(AStream.Position,8),0);
  FUnkn14_2:=AStream.ReadDword;      //?? magic
Check(FUnkn14_2,'FUnkn14_2 '+HexStr(AStream.Position,8),0);
  FArmorFire    :=AStream.ReadDword;
  FArmorIce     :=AStream.ReadDword;
  FArmorElectric:=AStream.ReadDword;
  FArmorPoison  :=AStream.ReadDword;
  FUnkn14_3:=AStream.ReadDword;      //?? all emements
Check(FUnkn14_3,'FUnkn14_3 '+HexStr(AStream.Position,8),0);

  FStrength :=AStream.ReadDWord;    // strength      0 for pet
  FDexterity:=AStream.ReadDWord;    // dexterity     0 for pet
  FVitality :=AStream.ReadDWord;    // vitality      10\ sure, pet have hp/mp bonuses
  FFocus    :=AStream.ReadDWord;    // focus         10/
  FGold     :=AStream.ReadDWord;    // gold          0
  //??
  AStream.Read(Funkn15,16);
if Funkn15[0]<>0         then DbgLn('  after gold[0]='+HexStr(Funkn15[0],8)+' at '+HexStr(AStream.Position,8));
if PInt64(@Funkn15[1])^<>-1 then
DbgLn('  after gold[1]='+HexStr(Funkn15[2],8)+HexStr(Funkn15[1],8)+' at '+HexStr(AStream.Position,8));
if Funkn15[3]<>$FFFFFFFF then DbgLn('  after gold[3]='+HexStr(Funkn15[3],8)+' at '+HexStr(AStream.Position,8));
{
  AStream.ReadDWord;    // -1 at start; 0..11
  AStream.ReadQWord;    // FF  or QUEST_GUID
  AStream.ReadDWord;    // FF  "3" - quest state?
}
  FSkin:=AStream.ReadByte;  // FF OR pet texture (color)

  // mod id list
  FModIds:=AStream.ReadIdList;

  //----- item list -----

  FItems:=ReadItemList(AStream);

  //----- Effects -----
  // dynamic,passive,transfer

  for i:=0 to 2 do
    FEffects[i]:=ReadEffectList(AStream,true);

  FAugments:=AStream.ReadShortStringList;
  
  //----- STATS -----

{ two base:
  CURRENT_PLAYER_STAT_PTS  - unallocated stat points
  CURRENT_PLAYER_SKILL_PTS - unallocated skill points
  multiply_hotbar adds SELECTED_HOTBAR stat
}
  FStats:=AStream.ReadIdValList;

  //----- Fixes -----

  if FIsChar then
  begin
    i:=GetStatIdx(FStats,DefaultStats[DefStatStat].id);
    if i>=0 then
    begin
      if      FFreeStatPoints<FStats[i].value then FFreeStatPoints:=FStats[i].value
      else if FFreeStatPoints>FStats[i].value then FStats[i].value:=FFreeStatPoints;
    end;
    i:=GetStatIdx(FStats,DefaultStats[DefStatSkill].id);
    if i>=0 then
    begin
      if      FFreeSkillPoints<FStats[i].value then FFreeSkillPoints:=FStats[i].value
      else if FFreeSkillPoints>FStats[i].value then FStats[i].value:=FFreeSkillPoints;
    end;
  end;

DbgLn('end char'#13#10'---------');
  LoadBlock(AStream);
end;

procedure TTL2Character.SaveToStream(AStream: TTL2Stream);
var
  i:integer;
begin
  AStream.WriteDWord(DataSize);

  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;

  //----- Fixes -----

  if FIsChar then
  begin
    i:=GetStatIdx(FStats,DefaultStats[DefStatStat].id);
    if i>=0 then
    begin
      if      FFreeStatPoints<FStats[i].value then FFreeStatPoints:=FStats[i].value
      else if FFreeStatPoints>FStats[i].value then FStats[i].value:=FFreeStatPoints;
    end;
    i:=GetStatIdx(FStats,DefaultStats[DefStatSkill].id);
    if i>=0 then
    begin
      if      FFreeSkillPoints<FStats[i].value then FFreeSkillPoints:=FStats[i].value
      else if FFreeSkillPoints>FStats[i].value then FStats[i].value:=FFreeSkillPoints;
    end;
  end;

  // signature
  AStream.WriteByte(FSign );  // $FF or 2
  AStream.WriteByte(FSign1);  // 0
  AStream.WriteByte(byte(FHidden) and 1);

  if FMorphId=TL2IdEmpty then
  begin
    AStream.WriteQWord(QWord(FID));
    AStream.WriteQWord(QWord(TL2IdEmpty));
  end
  else
  begin
    AStream.WriteQWord(QWord(FMorphId));
    AStream.WriteQWord(QWord(FID));
  end;
  AStream.WriteQWord(QWord(FUnkn1));    //!! (changing) (F6ED2564.F596F9AA)

  AStream.WriteByte(FUnkn2);
  AStream.WriteByte(byte(FWardrobe) and 1);
  if FWardrobe then // WARDROBE
  begin
    AStream.WriteDWord(FFace);       // face
    AStream.WriteDWord(FHairStyle);  // hairstyle
    AStream.WriteDWord(FHairColor);  // haircolor (+bandana for outlander)

    AStream.Write(FWardUnkn,36);
  end;

  AStream.WriteDWord(FUnkn3);
  AStream.WriteByte (byte(FEnabled) and 1);
  AStream.WriteByte (FUnkn4_1);
  AStream.WriteByte (FUnkn4_2);

  if FIsChar then
    AStream.WriteByte(FCheater);

  AStream.WriteByte(ord(FAIType));
  AStream.WriteFloat(FMorphTime);
  AStream.WriteFloat(FTownTime);        // time to town,sec?
  AStream.WriteDWord(ord(FAction));     // 1  (pet status)
  AStream.WriteDWord(ord(FAlignment));  // 1
  AStream.WriteFloat(FScale);           // scale (1.0 for char) (pet size)
  
  AStream.Write(FUnkn7,24);

  AStream.WriteDWord(FUnkn17);

  AStream.WriteShortString(FName);
  AStream.WriteShortString(FSuffix);
  if FIsChar{(FUnkn17<>$FFFFFFFF)} then
    AStream.WriteShortString(FPlayer);  // "PLAYER" !!!!! not exists for pets!!!!!!
  
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

  // mouse button skils
  AStream.WriteQWord(QWord(FRMB1));     // skill ID RMB active = Pet 1st spell?
  AStream.WriteQWord(QWord(FRMB2));     // skill ID RMB secondary
  AStream.WriteQWord(QWord(FLMB));      // skill ID LMB
  // second weapon set
  AStream.WriteQWord(QWord(FARMB1));    // skill ID RMB active
  AStream.WriteQWord(QWord(FARMB2));    // skill ID RMB secondary
  AStream.WriteQWord(QWord(FALMB));     // skill ID LMB

  // CURRENT Skill list. depends of current weapon (passive mainly)
  AStream.WriteIdValList(FSkills);

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

  AStream.WriteDWord(FStrength );    // strength      0 for pet
  AStream.WriteDWord(FDexterity);    // dexterity     0 for pet
  AStream.WriteDWord(FVitality );    // vitality      10\ sure, pet have hp/mp bonuses
  AStream.WriteDWord(FFocus    );    // focus         10/
  AStream.WriteDWord(FGold     );    // gold          0

  AStream.Write(FUnkn15,16);

  AStream.WriteByte(FSkin); // FF OR pet texture (color)

  // mod id list
  AStream.WriteIdList(FModIds);

  WriteItemList(AStream,FItems);

  //----- Effects -----
  // dynamic,passive,transfer

  for i:=0 to 2 do
    WriteEffectList(AStream,FEffects[i]);

  AStream.WriteShortStringList(FAugments);
  
  //----- STATS -----

  AStream.WriteIdValList(FStats);

  LoadBlock(AStream);
  FixSize  (AStream);
end;

function ReadCharData(AStream:TTL2Stream; IsChar:boolean=false; IsPet:boolean=false):TTL2Character;
begin
  result:=TTL2Character.Create();
  result.FIsChar:=IsChar;
  result.FIsPet :=IsPet;
  try
    result.LoadFromStream(AStream);
  except
    if IsConsole then writeln('got char exception at ',HexStr(result.DataOffset,8));
    AStream.Position:=result.DataOffset+result.DataSize;
  end;
end;

//----- Other -----

function TTL2Character.CheckForMods(alist:TTL2ModList):boolean;
begin
  result:=inherited CheckForMods(alist);

  // really, "not char" means "just pet" here
  // means, ModIds is nil
  // so, we just replace pet type by one of standard type
  if not (result or FIsChar) then
  begin
    FID:=GetDefaultPet();
    Changed:=true;
    result:=true;
  end;
end;

end.
