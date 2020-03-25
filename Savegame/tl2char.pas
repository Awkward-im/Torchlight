unit TL2Char;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2passive,
  tl2item;

type
  TTL2Action = (Idle, Attack, Defence);

type
  TTL2Skill = packed record
    id   : QWord;
    level: DWord;
  end;
  TTL2SkillList = array of TTL2Skill;

type
  TTL2Spell = record
    name :string;
    level:DWord;
  end;
  TTL2SpellList = array [0..3] of TTL2Spell;

type
  TTL2Character = class
  private
    FMode:TTL2ParseType;
//    byte[] Unknown1
//    byte[] Block1
//    byte[] Unknown2
    FFace     :integer;
    FHairstyle:integer;
    FHairColor:integer;
//    byte[] Unknown3
    FCheater  :integer;
//    byte[] Unknown4
    FCharacterName:string;
//    byte[] Unknown5
    FPlayer       :string;
//    byte[] Unknown6
    FLevel      :integer;
    FExperience :integer;
    FFameLevel  :integer;
    FFame       :integer;
    FHealth     :single;
    FHealthBonus:integer;
//    byte[] Unknown7
    FMana       :single;
    FManaBonus  :integer;
//    byte[] Unknown8
    FPlayTime   :single;
//    byte[] Unknown9
    FFreeSkillPoints:integer;
    FFreeStatPoints :integer;
//    byte[] Unknown10
    FSkills:TTL2SkillList;
    FSpells:TTL2SpellList;
//    byte[] Unknown11
    FStrength :integer;
    FDexterity:integer;
    FVitality :integer;
    FFocus    :integer;
    FGold     :integer;
//    byte[] Unknown12
//    byte[] Block2
    FModIds   :TTL2ModIdList;
    FItems    :TTL2ItemList;
    FPassives1:TTL2PassiveList;
    FPassives2:TTL2PassiveList;
//    byte[] Unknown13
//    ShortStringList Unknown14
//    byte[] Unknown15
  public
    constructor Create(amode:TTL2ParseType); overload;
    destructor Destroy; override;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

  end;

// Have Block length
function ReadCharData(AStream:TTL2Stream; amode:TTL2ParseType=ptLite; const adescr:string=''):TTL2Character;


implementation


function ReadSkillList(AStream:TTL2Stream):TTL2SkillList;
var
  lcnt:cardinal;
begin
  result:=nil;
  lcnt:=AStream.ReadDword;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    AStream.Read(result[0],lcnt*SizeOf(TTL2Skill));
  end;
end;

constructor TTL2Character.Create(amode:TTL2ParseType);
begin
  inherited Create;

  FMode:=amode;
end;

destructor TTL2Character.Destroy;
begin

  inherited;
end;

procedure TTL2Character.LoadFromStream(AStream: TTL2Stream);
var
  lcnt,i:integer;
  isPet:boolean;
begin
  //?? signature
  AStream.ReadByte;     // $FF
  AStream.ReadWord;     // 0

  AStream.ReadQWord;    // current Class ID (with sex)
  AStream.ReadQword;    // *$FF or base class id (if morphed)
  AStream.ReadQword;    //!! (changing)

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
  AStream.ReadDWord;    // 0
  AStream.ReadByte;     // 1
  AStream.ReadByte;     // 0
  AStream.ReadByte;     // 0

  if not isPet then
    FCheater:=AStream.ReadByte; //!!!! cheat (67($43) or 78($4E)[=elfly] no cheat, 214($D6) IS cheat

  AStream.ReadByte;     // pet: elfly=4, lonelfly=0, rage=0 :24 for pet, :55 for char

  AStream.ReadDWord;    // 0
  AStream.ReadSingle;   // time to town,sec?
  TTL2Action(AStream.ReadDWord);  // 1  (pet status)

  AStream.ReadDWord;    // 1
  AStream.ReadSingle;   // scale (1.0 for char) (pet size)
  
  AStream.ReadQWord;    // ? player = FFFFFFFF, pet - no
  AStream.ReadQWord;    // -1
  AStream.ReadQWord;    // -1

  isPet:=(AStream.ReadDWord=$FFFFFFFF); //  const. elfly=69DF417B ?? if not -1 then "player" presents

  FCharacterName:=AStream.ReadShortString(); // :55(pet) Char name
  AStream.ReadShortString();                 // empty (len=0) atm or trail of char name?
  if not isPet then
    FPlayer:=AStream.ReadShortString();      // "PLAYER" !!!!! not exists for pets!!!!!!
  
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0 / elfly=7, rage=2, lonelfly=2, zorro=0

  AStream.ReadSingle;   // float?
  AStream.ReadSingle;   // float?
  AStream.ReadSingle;   // float?  elfly
  AStream.ReadSingle;   // float?  + 3
  AStream.ReadSingle;   // ?       + 3
  AStream.ReadSingle;   // ?       + 1
  AStream.ReadDWord;    // 0
  AStream.ReadSingle;   // float?  + 3
  AStream.ReadSingle;   // float?  + 2
  AStream.ReadSingle;   // float?  + 8
  AStream.ReadDWord;    // 0
  AStream.ReadSingle;   // float?  + 3
  AStream.ReadSingle;   // float?  + 1
  AStream.ReadSingle;   // float?  + 1
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  AStream.ReadSingle;   // float=1.0

  FLevel      :=AStream.ReadDWord;    // level
  FExperience :=AStream.ReadDWord;    // exp
  FFameLevel  :=AStream.ReadDWord;    // fame level
  FFame       :=AStream.ReadDWord;    // fame
  FHealth     :=AStream.ReadSingle;   // float, current HP (4573->283,9)
  FHEalthBonus:=AStream.ReadDWord;    // health bonus pet 17547 (0a00=2560)
  AStream.ReadDWord;                  // <CD> 0
  FMana       :=AStream.ReadSingle;   // float, MP        320
  FManaBonus  :=AStream.ReadDWord;    // Mana bonus             (6B=107)

  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  FPlayTime:=AStream.ReadSingle;    // play time, sec
  AStream.ReadSingle;               // 1.0
  FFreeSkillPoints:=AStream.ReadDWord; // unallocated skillpoints? (elfly have 28 with 28 in fact)
  FFreeStatPoints :=AStream.ReadDWord; // unallocated statpoints ? (elfly have 35 with 30 in fact)
  // mouse button skills
  AStream.ReadQWord;    // skill ID RMB active = Pet 1st spell?
  AStream.ReadQWord;    // skill ID RMB secondary
  AStream.ReadQWord;    // skill ID LMB
  // second weapon set
  AStream.ReadQWord;    // skill ID RMB active
  AStream.ReadQWord;    // skill ID RMB secondary
  AStream.ReadQWord;    // skill ID LMB

  // CURRENT Skill list. depends of current weapon (passive mainly)
  FSkills:=ReadSkillList(AStream);

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

  AStream.ReadDWord;    // $FF=-1 / 1/0 (elfly)      0
  AStream.ReadQWord;    // FF same as pets
  AStream.ReadDWord;    // FF same as pets

  AStream.ReadByte;     // FF OR pet texture (color)

  // mod id list
  FModIds:=ReadModIdList(AStream);

//-----------------------------
  if not (FMode in [ptDeep,ptDeepest]) then exit;
//-----------------------------

  // item list
//SaveDump('items.bin',FBuffer+lpos,lCharInfoSize-(lpos-apos));
  FItems:=ReadItemList(AStream); // :457

  // "passives"                         // activation: passive
  FPassives1:=ReadPassiveList(AStream);
  FPassives2:=ReadPassiveList(AStream);

  //?? DYNAMIC activation passive names? activation: dynamic, duration: instant
  // full chargebar state?
  AStream.ReadDWord;    // 0

  ReadShortStringList(AStream);
{
  lcnt:=AStream.ReadDWord;
  for i:=0 to lcnt-1 do
  begin
    ls:=AStream.ReadShortString(); // spell name
  end;
}

  //-- stats
  lcnt:=AStream.ReaDWord;
{ atm just 2:
  CURRENT_PLAYER_STAT_PTS  - unallocated stat points
  CURRENT_PLAYER_SKILL_PTS - unallocated skill points
}
  for i:=0 to lcnt-1 do
  begin
    AStream.ReadShortString(); // flag
    AStream.ReadDWord;         // value
  end;

end;

procedure TTL2Character.SaveToStream(AStream: TTL2Stream);
begin
end;

function ReadCharData(AStream:TTL2Stream; amode:TTL2ParseType=ptLite; const adescr:string=''):TTL2Character;
var
  llen,lpos:cardinal;
begin
  llen:=AStream.ReadDWord();
  lpos:=AStream.Position;

  if adescr<>'' then
    SaveDump(adescr,AStream.Memory+lpos,llen);

  if amode=ptLite then
  begin
    result:=nil;
  end
  else
  begin
    result:=TTL2Character.Create(amode);
    result.LoadFromStream(AStream);
  end;

  AStream.Seek(lpos+llen,soFromBeginning);
end;

end.
