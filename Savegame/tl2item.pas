unit TL2Item;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2modifiers;

type
  TTL2Item = class;
  TTL2ItemList = array of TTL2Item;
type
  TTL2Item = class
  private
//    MagicByte:byte;
    FItemId   :QWord;
    FName     :string;
    FPrefix   :string;
    FSuffix   :string;

//    byte[] Unknown1
    FModIds:TTL2ModIdList;
//    byte[] Unknown2
    FEnchantmentCount:integer;
    FStashPosition   :integer;
//    byte[] Unknown3
    FLevel      :integer;
    FStackSize  :integer;
    FSocketCount:integer;
    FSocketables:TTL2ItemList;
//    byte[] Unknown4
    FWeaponDamage:integer;
    FArmor       :integer;
    FArmorType   :integer;
//    byte[] Unknown5
//    short Unknown6Count
//    byte[] Unknown6
    FModifiers1:TTL2ModifierList;
    FModifiers2:TTL2ModifierList;
    FModifiers3:TTL2ModifierList;
    FAugments: TTL2StringList;
//    int Unknown7Count
//    byte[] Unknown7

  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

  end;


function ReadItemList(AStream:TTL2Stream):TTL2ItemList;



implementation


constructor TTL2Item.Create;
begin
  inherited;

end;

destructor TTL2Item.Destroy;
var
  i:integer;
begin
  SetLength(FModIds,0);
  for i:=0 to High(FSocketables) do
    FSocketables[i].Free;
  SetLength(FSocketables,0);
  SetLength(FModifiers1,0);
  SetLength(FModifiers2,0);
  SetLength(FModifiers3,0);
  SetLength(FAugments,0);

  inherited;
end;

procedure TTL2Item.LoadFromStream(AStream: TTL2Stream);
var
  lcnt:integer;
begin
  AStream.ReadByte;                   // "2"
  FItemId:=AStream.ReadQWord;         // Item ID
  FName  :=AStream.ReadShortString(); // name
  FPrefix:=AStream.ReadShortString(); // prefix
  FSuffix:=AStream.ReadShortString(); // suffix

  AStream.ReadQWord;
  AStream.ReadQWord;     // changing
  AStream.ReadQWord;

  FModIds:=ReadModIdList(AStream);

  AStream.ReadByte;      // 0
  AStream.ReadQWord;     // *FF
  AStream.ReadQWord;     // *FF
  AStream.ReadQWord;     // *FF
  AStream.ReadDWord;     // 0

  FEnchantmentCount:=AStream.ReadDWord; // enchantment count
  FStashPosition   :=AStream.ReadDWord; // stash position $285 = 645
  //-- 95 bytes
  // 7 times
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 0
  AStream.ReadByte;  // 1
  // 7 times
  AStream.ReadSingle; // C390C993 = -289.57
  AStream.ReadSingle;
  AStream.ReadSingle;
  AStream.ReadSingle;
  AStream.ReadSingle;
  AStream.ReadSingle; // 66.27
  AStream.ReadSingle;

  AStream.ReadSingle; // ?
  AStream.ReadSingle; // ?
  AStream.ReadSingle; // ? = 0
  AStream.ReadSingle; // ?
  AStream.ReadSingle; // 1.0
  AStream.ReadDWord;  // ?
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  //   \ qword
  AStream.ReadDWord;  //   /
  AStream.ReadSingle; // ?
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadSingle;

  FLevel      :=AStream.ReadDWord;
  FStackSize  :=AStream.ReadDWord;
  FSocketCount:=AStream.ReadDWord;

  FSocketables:=ReadItemList(AStream);

  AStream.ReadDWord;  // 0
  FWeaponDamage:=AStream.ReadDWord;
  FArmor       :=AStream.ReadDWord;
  FArmorType   :=AStream.ReadDWord;

  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF

  lcnt:=AStream.ReadWord;
  AStream.Seek(lcnt*12,soCurrent); // 8+4 ?
  
  FModifiers1:=ReadModifierList(AStream);
  FModifiers2:=ReadModifierList(AStream);
  FModifiers3:=ReadModifierList(AStream);

  FAugments:=ReadShortStringList(AStream);

  lcnt:=AStream.ReadDWord;
  AStream.Seek(lcnt*12,soCurrent); // 8+4 ?

end;

procedure TTL2Item.SaveToStream(AStream: TTL2Stream);
begin
end;

function ReadItemList(AStream:TTL2Stream):TTL2ItemList;
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
      result[i]:=TTL2Item.Create;
      result[i].LoadFromStream(AStream);
    end;
  end;
end;

end.
