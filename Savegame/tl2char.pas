unit TL2Char;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2types,
  tl2effects,
  tl2item;

type
  TTL2Action = (Idle, Attack, Defence);

type
  TTL2Spell = record
    name :string;
    level:DWord;
  end;
  TTL2SpellList = array [0..3] of TTL2Spell;

type
  TTL2Character = class
  private
    FDescr:string;
    
    Data:PByte;
    Size:cardinal;
    FItemData:PByte;
    FItemSize:cardinal;
    FMode:TTL2ParseType;

  private
    FSign           :Byte;

    // Pet's corner
    FImageId,
    FOriginId       :TL2ID;
    Unk1            :TL2ID;
    FScale          :TL2Float;
    FSkin           :Byte;
    FEnabled        :TL2Boolean;
    FMorphTime      :TL2Float;
    FTownTime       :TL2Float;
    FAction         :TTL2Action;

    // player's Wardrobe etc
    FFace           :integer;
    FHairstyle      :integer;
    FHairColor      :integer;
    FCheater        :byte;
    FPlayer         :string;

    // looks like common
    FCharacterName  :string;
    FPosition       :TL2Coord;
    FLevel          :integer;
    FExperience     :integer;
    FFameLevel      :integer;
    FFame           :integer;
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
    FModIds         :TL2IdList;

    FItems          :TTL2ItemList;
    FEffects1       :TTL2EffectList;
    FEffects2       :TTL2EffectList;
    FEffects3       :TTL2EffectList;
    FAugments       :TL2StringList;
    FStats          :TL2IdValList;
  public
    constructor Create(amode:TTL2ParseType; const adescr:string); overload;
    destructor  Destroy; override;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

  public
    property Name           :string   read FCharacterName   write FCharacterName;
    property Player         :string   read FPlayer          write FPlayer;
    property Face           :integer  read FFace            write FFace;
    property Hairstyle      :integer  read FHairstyle       write FHairstyle;
    property HairColor      :integer  read FHairColor       write FHairColor;
    property Cheater        :byte     read FCheater         write FCheater;
    property Position       :TL2Coord read FPosition        write FPosition;
    property Level          :integer  read FLevel           write FLevel;
    property Experience     :integer  read FExperience      write FExperience;
    property FameLevel      :integer  read FFameLevel       write FFameLevel;
    property Fame           :integer  read FFame            write FFame;
    property Health         :TL2Float read FHealth          write FHealth;
    property HealthBonus    :integer  read FHealthBonus     write FHealthBonus;
    property Mana           :TL2Float read FMana            write FMana;
    property ManaBonus      :integer  read FManaBonus       write FManaBonus;
    property PlayTime       :TL2Float read FPlayTime        write FPlayTime;
    property FreeSkillPoints:integer  read FFreeSkillPoints write FFreeSkillPoints;
    property FreeStatPoints :integer  read FFreeStatPoints  write FFreeStatPoints;
    property Strength       :integer  read FStrength        write FStrength;
    property Dexterity      :integer  read FDexterity       write FDexterity;
    property Vitality       :integer  read FVitality        write FVitality;
    property Focus          :integer  read FFocus           write FFocus;
    property Gold           :integer  read FGold            write FGold;
    property Scale          :TL2Float read FScale           write FScale;
{
    property Skills   [idx:integer]:TL2IdVal    read  GetSkills;
    property Spells   [idx:integer]:TTL2Spell   read  GetSpells;
    property ModIds   [idx:integer]:TL2ID       read  GetModIds;
    property Items    [idx:integer]:TTL2Item    read  GetItems;
    property Passives1[idx:integer]:TTL2Passive read  GetPassives1;
    property Passives2[idx:integer]:TTL2Passive read  GetPassives2;
}
  end;

// Have Block length
function  ReadCharData (AStream:TTL2Stream; amode:TTL2ParseType=ptLite; const adescr:string=''):TTL2Character;
procedure WriteCharData(AStream:TTL2Stream; achar:TTL2Character);


implementation


constructor TTL2Character.Create(amode:TTL2ParseType; const adescr:string);
begin
  inherited Create;

  FDescr:=adescr;
  FMode:=amode;
end;

destructor TTL2Character.Destroy;
var
  i:integer;
begin
  FreeMem(FItemData);
  
  SetLength(FSkills,0);
  SetLength(FModIds,0);

  FreeMem(Data);

  for i:=0 to High(FItems) do FItems[i].Free;
  SetLength(FItems,0);

  for i:=0 to High(FEffects1) do FEffects1[i].Free;
  SetLength(FEffects1,0);
  for i:=0 to High(FEffects2) do FEffects2[i].Free;
  SetLength(FEffects2,0);
  for i:=0 to High(FEffects3) do FEffects3[i].Free;
  SetLength(FEffects3,0);

  SetLength(FAugments,0);

  inherited;
end;

procedure TTL2Character.LoadFromStream(AStream: TTL2Stream);
var
  lcnt,i:integer;
  lpos:cardinal;
  isPet:boolean;
begin

if FMode=ptLite then exit;

  lpos:=AStream.Position;

  // signature
  FSign:=AStream.ReadByte;  // $FF or 02
  AStream.ReadWord;         // 0
	
  FImageId :=TL2ID(AStream.ReadQWord);    // current Class ID (with sex)
  FOriginId:=TL2ID(AStream.ReadQword);    // *$FF or base class id (if morphed)

  Unk1:=TL2ID(AStream.ReadQword);    //!! (changing) (F6ED2564.F596F9AA)

  // really, that must mean "image" i think
  isPet:=(AStream.ReadWord and $0100)=0;     // :1B -  $0100 flags?
  if not isPet then // WARDROBE
  begin
    FFace     :=AStream.ReadDWord;    // face
    FHairStyle:=AStream.ReadDWord;    // hairstyle
    FHairColor:=AStream.ReadDWord;    // haircolor (+bandana for outlander)
    // !!*$FF = 36
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadDWord;
  end;
  //??
  AStream.ReadDWord;    // 0
  FEnabled:=AStream.ReadByte<>0; // 1 (pet - enabled)
  //??
  AStream.ReadByte;     // 0
  AStream.ReadByte;     // 0

  if not isPet then
    FCheater:=AStream.ReadByte; //!!!! cheat (67($43) or 78($4E)[=elfly] no cheat, 214($D6) IS cheat
  //??
  AStream.ReadByte;     // pet: elfly=4, lonelfly=0, rage=0 :24 for pet, :55 for char

  FMorphTime:=AStream.ReadFloat;   // pet morph time
  FTownTime :=AStream.ReadFloat;   //!!!!!!!!!! time to town,sec?
  FAction   :=TTL2Action(AStream.ReadDWord);  // 1  (pet status)
  //??
  AStream.ReadDWord;    // 1
  FScale:=AStream.ReadFloat;   // scale (1.0 for char) (pet size)
  //??
  AStream.ReadQWord;    // ? player = FFFFFFFF, pet - no
  AStream.ReadQWord;    // -1
  AStream.ReadQWord;    // -1

  // can it be a name hash?
  isPet:=(AStream.ReadDWord=$FFFFFFFF); //  const. elfly=69DF417B ?? if not -1 then "player" presents

  FCharacterName:=AStream.ReadShortString(); // :55(pet) Char name
  Check(AStream.ReadWord,'name_between',0);  // empty (len=0) atm or WORD = number?
  if not isPet then
    FPlayer:=AStream.ReadShortString();      // "PLAYER" !!!!! not exists for pets!!!!!!
  //??
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0 / elfly=7, rage=2, lonelfly=2, zorro=0

  FPosition:=AStream.ReadCoord; //!!!!!!!!

  //??
  // direction
  AStream.ReadCoord;   // Forward
  AStream.ReadDWord;   // 0

  AStream.ReadCoord;   // Up
  AStream.ReadDWord;   // 0
  
  AStream.ReadCoord;   // Right
  AStream.ReadDWord;   // 0

  AStream.ReadDWord;   // 0
  AStream.ReadDWord;   // 0
  AStream.ReadDWord;   // 0
  AStream.ReadFloat;   // float=1.0

  FLevel      :=AStream.ReadDWord;    // level
  FExperience :=AStream.ReadDWord;    // exp
  FFameLevel  :=AStream.ReadDWord;    // fame level
  FFame       :=AStream.ReadDWord;    // fame
  FHealth     :=AStream.ReadFloat;    // current HP
  FHealthBonus:=AStream.ReadDWord;    // health bonus (pet=full hp)
  Check(AStream.ReadDWord,'stat',0);  // 0 ?? charge maybe? or armor?
  FMana       :=AStream.ReadFloat;    // current MP
  FManaBonus  :=AStream.ReadDWord;    // Mana bonus   (pet=full mp)
  //??
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  FPlayTime:=AStream.ReadFloat;    // play time, sec
  AStream.ReadFloat;               // 1.0
  FFreeSkillPoints:=AStream.ReadDWord; // unallocated skillpoints? (elfly have 28 with 28 in fact)
  FFreeStatPoints :=AStream.ReadDWord; // unallocated statpoints ? (elfly have 35 with 30 in fact)

  // mouse button skils
  AStream.ReadQWord;    // skill ID RMB active = Pet 1st spell?
  AStream.ReadQWord;    // skill ID RMB secondary
  AStream.ReadQWord;    // skill ID LMB
  // second weapon set (!!!!!!!!!) not for pets
  AStream.ReadQWord;    // skill ID RMB active
  AStream.ReadQWord;    // skill ID RMB secondary
  AStream.ReadQWord;    // skill ID LMB
{  Pet: 6x4b = Nizza: 27BA7400, 27BA6E00,

}
  // CURRENT Skill list. depends of current weapon (passive mainly)
  FSkills:=AStream.ReadIdValList;

  // Spell list
  for i:=0 to 3 do
  begin
    FSpells[i].name :=AStream.ReadShortString; // spell name
    FSpells[i].level:=AStream.ReadDWord;       // spell level
  end;

  //!!-- 28 bytes
  AStream.ReadQWord;    // 0 same as pets
  AStream.ReadDWord;    // 0, Elfly pet = $0197 (407)
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0 same as pets

  FStrength :=AStream.ReadDWord;    // strength      0 for pet
  FDexterity:=AStream.ReadDWord;    // dexterity     0 for pet
  FVitality :=AStream.ReadDWord;    // vitality      10\ sure, pet have hp/mp bonuses
  FFocus    :=AStream.ReadDWord;    // focus         10/
  FGold     :=AStream.ReadDWord;    // gold          0
  //??
  AStream.ReadDWord;    // $FF=-1 / 1/0 (elfly)      0
  AStream.ReadQWord;    // FF same as pets
  AStream.ReadDWord;    // FF same as pets

  FSkin:=AStream.ReadByte;  // FF OR pet texture (color)

  // mod id list
  FModIds:=AStream.ReadIdList;

//  if FDescr<>'' then SaveDump(FDescr+'_data.dmp',AStream.Memory+lpos,(AStream.Position-lpos));

//-----------------------------
  if FMode=ptLite then
//  if not (FMode in [ptDeep,ptDeepest]) then
  begin
    FItemSize:=Size-(AStream.Position-lpos);
    if FDescr<>'' then SaveDump(FDescr+'_rest.dmp',AStream.Memory+AStream.Position,FItemSize);
    FItemData:=AStream.ReadBytes(FItemSize);
    exit;
  end;
//-----------------------------

  //----- item list -----

  FItems:=ReadItemList(AStream);

  //----- Effects -----
  // dynamic,passive,transfer

  FEffects1:=ReadEffectList(AStream,true);
  FEffects2:=ReadEffectList(AStream,true);
  FEffects3:=ReadEffectList(AStream,true);

  FAugments:=AStream.ReadShortStringList;
  
  //----- STATS -----

{ two base:
  CURRENT_PLAYER_STAT_PTS  - unallocated stat points
  CURRENT_PLAYER_SKILL_PTS - unallocated skill points
  multiply_hotbar adds SELECTED_HOTBAR stat
}
  FStats:=AStream.ReadIdValList;
end;

procedure TTL2Character.SaveToStream(AStream: TTL2Stream);
var
  i:integer;
  isPet:boolean;
begin
  // signature
  AStream.WriteByte(FSign); // $FF
  AStream.WriteWord(0);     // 0

  AStream.WriteQWord(FImageId);  // current Class ID (with sex)
  AStream.WriteQWord(FOriginId); // *$FF or base class id (if morphed)
  AStream.WriteQWord(Unk1);      //!! (changing) (F6ED2564.F596F9AA)

  // really, that must mean "image" i think
  isPet:=(AStream.ReadWord and $0100)=0;     // :1B -  $0100 flags?
  if not isPet then // WARDROBE
  begin
    AStream.WriteDWord(FFace);         // face
    AStream.WriteDWord(FHairStyle);    // hairstyle
    AStream.WriteDWord(FHairColor);    // haircolor (+bandana for outlander)
    // !!*$FF = 36
    AStream.WriteFiller(36);
  end;
  AStream.ReadDWord;    // 0
  AStream.ReadByte;     // 1 (pet - enabled)
  AStream.ReadByte;     // 0
  AStream.ReadByte;     // 0

  if not isPet then
    AStream.WriteByte(FCheater); // cheat (67($43) or 78($4E)[=elfly] no cheat, 214($D6) IS cheat

  AStream.ReadByte;     // pet: elfly=4, lonelfly=0, rage=0 :24 for pet, :55 for char

  AStream.ReadDWord;    // 0
  AStream.WriteFloat(FTownTime);     // time to town,sec?
  AStream.WriteDWord(ord(FAction));  // 1  (pet status)

  AStream.ReadDWord;    // 1
  AStream.WriteFloat(FScale);   // scale (1.0 for char) (pet size)
  
  AStream.ReadQWord;    // ? player = FFFFFFFF, pet - no
  AStream.ReadQWord;    // -1
  AStream.ReadQWord;    // -1

  isPet:=(AStream.ReadDWord=$FFFFFFFF); //  const. elfly=69DF417B ?? if not -1 then "player" presents

  AStream.WriteShortString(FCharacterName); // :55(pet) Char name
  AStream.WriteWord(0);                     // empty (len=0) atm or WORD = number?
  if not isPet then
    AStream.WriteShortString(FPlayer);      // "PLAYER" !!!!! not exists for pets!!!!!!
  
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0 / elfly=7, rage=2, lonelfly=2, zorro=0

  AStream.WriteCoord(FPosition);

  // Orientation
  AStream.ReadCoord;   // Forward
  AStream.ReadDWord;   // 0
  AStream.ReadCoord;   // Right
  AStream.ReadDWord;   // 0
  AStream.ReadCoord;   // Up
  AStream.ReadDWord;   // 0

  AStream.ReadDWord;   // 0
  AStream.ReadDWord;   // 0
  AStream.ReadDWord;   // 0
  AStream.ReadFloat;   // float=1.0

  AStream.WriteDWord(FLevel);        // level
  AStream.WriteDWord(FExperience);   // exp
  AStream.WriteDWord(FFameLevel);    // fame level
  AStream.WriteDWord(FFame);         // fame
  AStream.WriteFloat(FHealth);       // current HP
  AStream.WriteDWord(FHealthBonus);  // health bonus (pet=full hp)
  AStream.WriteDWord(0);             // 0
  AStream.WriteFloat(FMana);         // current MP
  AStream.WriteDWord(FManaBonus);    // Mana bonus   (pet=full mp)

  AStream.ReadDWord;    // 0 <e1>
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  AStream.WriteFloat(FPlayTime);    // play time, sec
  AStream.ReadFloat;               // 1.0
  AStream.WriteDWord(FFreeSkillPoints); // unallocated skillpoints? (elfly have 28 with 28 in fact)
  AStream.WriteDWord(FFreeStatPoints ); // unallocated statpoints ? (elfly have 35 with 30 in fact)

  // mouse button skils
  AStream.ReadQWord;    // skill ID RMB active = Pet 1st spell?
  AStream.ReadQWord;    // skill ID RMB secondary
  AStream.ReadQWord;    // skill ID LMB
  // second weapon set
  AStream.ReadQWord;    // skill ID RMB active
  AStream.ReadQWord;    // skill ID RMB secondary
  AStream.ReadQWord;    // skill ID LMB

  // CURRENT Skill list. depends of current weapon (passive mainly)
  AStream.WriteIdValList(FSkills);

  // Spell list
  for i:=0 to 3 do
  begin
    AStream.WriteShortString(FSpells[i].name ); // spell name
    AStream.WriteDWord      (FSpells[i].level); // spell level
  end;

  //!!-- 28 bytes
  AStream.ReadQWord;    // 0 same as pets
  AStream.ReadDWord;    // 0, Elfly pet = $0197 (407)
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0 same as pets

  AStream.WriteDWord(FStrength );    // strength      0 for pet
  AStream.WriteDWord(FDexterity);    // dexterity     0 for pet
  AStream.WriteDWord(FVitality );    // vitality      10\ sure, pet have hp/mp bonuses
  AStream.WriteDWord(FFocus    );    // focus         10/
  AStream.WriteDWord(FGold     );    // gold          0

  AStream.ReadDWord;    // $FF=-1 / 1/0 (elfly)      0
  AStream.ReadQWord;    // FF same as pets
  AStream.ReadDWord;    // FF same as pets

  AStream.WriteByte(FSkin); // FF OR pet texture (color)

  // mod id list
  AStream.WriteIdList(FModIds);


  AStream.Write(FItemData^,FItemSize);
end;

function ReadCharData(AStream:TTL2Stream; amode:TTL2ParseType=ptLite; const adescr:string=''):TTL2Character;
var
  llen,lpos:cardinal;
begin
  llen:=AStream.ReadDWord;
  lpos:=AStream.Position;

  if adescr<>'' then SaveDump(adescr+'.dmp',AStream.Memory+lpos,llen);

  result:=TTL2Character.Create(amode,adescr);

  result.Size:=llen;
  if amode=ptLite then
  begin
    result.Data:=AStream.ReadBytes(llen);
  end
  else
    try
      result.LoadFromStream(AStream);
    except
writeln('got char exception');
    end;

  AStream.Seek(lpos+llen,soFromBeginning);
end;

procedure WriteCharData(AStream:TTL2Stream; achar:TTL2Character);
begin
  if achar.FMode=ptLite then
  begin
    AStream.WriteDWord(achar.Size);
    AStream.Write(achar.Data^,achar.Size);
  end
  else
  //!!!! Size??
    try
      achar.SaveToStream(AStream);
    except
    end;
end;

end.
