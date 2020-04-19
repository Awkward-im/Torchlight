unit TL2Item;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2base,
  tl2types,
  tl2Effects;

type
  TTL2Item = class;
  TTL2ItemList = array of TTL2Item;
type
  TTL2Item = class(TL2BaseClass)
  private
    FItemId   :TL2ID;
    FName     :string;
    FPrefix   :string;
    FSuffix   :string;

    FModIds:TL2IdList;

    FEnchantmentCount:integer;
    FStashPosition   :integer;

    FLevel      :integer;
    FStackSize  :integer;
    FSocketCount:integer;
    FSocketables:TTL2ItemList;

    FWeaponDamage:integer;
    FArmor       :integer;
    FArmorType   :integer;

    FEffects1:TTL2EffectList;
    FEffects2:TTL2EffectList;
    FEffects3:TTL2EffectList;
    FAugments:TL2StringList;
    FStats   :TL2IdValList;

  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

  end;


function  ReadItemList (AStream:TTL2Stream):TTL2ItemList;
procedure WriteItemList(AStream:TTL2Stream; alist:TTL2ItemList);


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

  for i:=0 to High(FEffects1) do FEffects1[i].Free;
  SetLength(FEffects1,0);
  for i:=0 to High(FEffects2) do FEffects2[i].Free;
  SetLength(FEffects2,0);
  for i:=0 to High(FEffects3) do FEffects3[i].Free;
  SetLength(FEffects3,0);

  SetLength(FAugments,0);

  inherited;
end;

procedure TTL2Item.LoadFromStream(AStream: TTL2Stream);
var
  lcnt:integer;
begin
  FDataOffset:=AStream.Position;

  AStream.ReadByte;                   // "2"
  FItemId:=TL2ID(AStream.ReadQWord);  // Item ID
  FName  :=AStream.ReadShortString(); // name
  FPrefix:=AStream.ReadShortString(); // prefix
  FSuffix:=AStream.ReadShortString(); // suffix

  //??
  AStream.ReadQWord;
  AStream.ReadQWord;     // changing
  AStream.ReadQWord;

  FModIds:=AStream.ReadIdList;

  //??
  AStream.ReadByte;      // 0
  AStream.ReadQWord;     // *FF
  AStream.ReadQWord;     // *FF props - not -1  MEDIA\LAYOUTS\ACT1_PASS1\1X1SINGLE_ROOM_A\PAPASS_PB_A.LAYOUT
  AStream.ReadQWord;     // *FF props - not -1  ?
  AStream.ReadDWord;     // 0

  FEnchantmentCount:=integer(AStream.ReadDWord); // enchantment count // prop=E56DE12D
  FStashPosition   :=integer(AStream.ReadDWord); // stash position $285 = 645 . -1 for props

  //--?? 95 bytes
  // 7 times
  AStream.ReadByte;  // 1  props: 0 0
  AStream.ReadByte;  // 1         1 1
  AStream.ReadByte;  // 1         0 0
  AStream.ReadByte;  // 1         1 0
  AStream.ReadByte;  // 1         1 1
  AStream.ReadByte;  // 0         0 1
  AStream.ReadByte;  // 1         0 0
  // 7 times
  AStream.ReadFloat;  // C390C993 = -289.57   num
  AStream.ReadFloat;  //                       0
  AStream.ReadFloat;  //                      num
  AStream.ReadFloat;  //                      num
  AStream.ReadFloat;  //                       0
  AStream.ReadFloat;  // 66.27                num
  AStream.ReadFloat;  //                      1.0
  // 35<--| --> 60 / 4 = 15
  AStream.ReadFloat;  // ?
  AStream.ReadFloat;  // ?
  AStream.ReadFloat;  // ? = 0
  AStream.ReadFloat;  // ?
  AStream.ReadFloat;  // 1.0
  AStream.ReadDWord;  // ?
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  //   \ qword
  AStream.ReadDWord;  //   /
  AStream.ReadFloat;  // ?
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadFloat;

  FLevel      :=integer(AStream.ReadDWord); // 1  for props (22)
  FStackSize  :=integer(AStream.ReadDWord); // -1 for props (1)
  FSocketCount:=integer(AStream.ReadDWord); // 0  for props (A009CC81)

  FSocketables:=ReadItemList(AStream);

  //??
  AStream.ReadDWord;  // 0
  FWeaponDamage:=integer(AStream.ReadDWord); // -1 for props
  FArmor       :=integer(AStream.ReadDWord); // -1 for props
  FArmorType   :=integer(AStream.ReadDWord); //  0 for props (2)

  //??
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF

  //??
  lcnt:=AStream.ReadWord;
  if IsConsole then if lcnt>0 then writeln('item-pre effect at ',HexStr(AStream.Position,8));
  // 00 00 00 00 | 00 00 00 00 | <cnt> 00 00 00
  AStream.Seek(lcnt*12,soCurrent); // 8+4 ?

  // dynamic,passive,transfer
  FEffects1:=ReadEffectList(AStream);
  FEffects2:=ReadEffectList(AStream);
  FEffects3:=ReadEffectList(AStream);

  FAugments:=AStream.ReadShortStringList;

  FStats:=AStream.ReadIdValList;

//  FDataSize:=AStream.Position-FDataOffset;
  CloneStream(AStream);
end;

procedure TTL2Item.SaveToStream(AStream: TTL2Stream);
begin
  if not FChanged then
  begin
    if ToStream(AStream) then exit;
  end;

  AStream.WriteByte(2);                // "2"
  AStream.WriteQWord(QWord(FItemId));  // Item ID
  AStream.WriteShortString(FName);     // name
  AStream.WriteShortString(FPrefix);   // prefix
  AStream.WriteShortString(FSuffix);   // suffix

  //??
  AStream.ReadQWord;
  AStream.ReadQWord;     // changing
  AStream.ReadQWord;

  AStream.WriteIdList(FModIds);

  //??
  AStream.ReadByte;      // 0
  AStream.ReadQWord;     // *FF
  AStream.ReadQWord;     // *FF
  AStream.ReadQWord;     // *FF
  AStream.ReadDWord;     // 0

  AStream.WriteDWord(DWord(FEnchantmentCount)); // enchantment count
  AStream.WriteDWord(DWord(FStashPosition   )); // stash position $285 = 645

  //--?? 95 bytes
  // 7 times
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 1
  AStream.ReadByte;  // 0
  AStream.ReadByte;  // 1
  // 7 times
  AStream.ReadFloat;  // C390C993 = -289.57
  AStream.ReadFloat;
  AStream.ReadFloat;
  AStream.ReadFloat;
  AStream.ReadFloat;
  AStream.ReadFloat;  // 66.27
  AStream.ReadFloat;
  // 35<--| --> 60 / 4 = 15
  AStream.ReadFloat;  // ?
  AStream.ReadFloat;  // ?
  AStream.ReadFloat;  // ? = 0
  AStream.ReadFloat;  // ?
  AStream.ReadFloat;  // 1.0
  AStream.ReadDWord;  // ?
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  //   \ qword
  AStream.ReadDWord;  //   /
  AStream.ReadFloat;  // ?
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadDWord;  // 0
  AStream.ReadFloat;

  AStream.WriteDWord(FLevel);
  AStream.WriteDWord(FStackSize);
  AStream.WriteDWord(FSocketCount);

  WriteItemList(AStream,FSocketables);

  //??
  AStream.ReadDWord;  // 0
  AStream.WriteDWord(DWord(FWeaponDamage));
  AStream.WriteDWord(DWord(FArmor));
  AStream.WriteDWord(DWord(FArmorType));

  //??
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF

  //??
//  lcnt:=AStream.ReadWord;
//  AStream.Seek(lcnt*12,soCurrent); // 8+4 ?
  
  // dynamic,passive,transfer
  WriteEffectList(AStream,FEffects1);
  WriteEffectList(AStream,FEffects2);
  WriteEffectList(AStream,FEffects3);

  AStream.WriteShortStringList(FAugments);

  AStream.WriteIdValList(FStats);
end;

function ReadItemList(AStream:TTL2Stream):TTL2ItemList;
var
  i,lcnt:integer;
  lpos:cardinal;
begin
  result:=nil;
  lcnt:=AStream.ReadDWord;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
    begin
lpos:=AStream.Position;
      
      result[i]:=TTL2Item.Create;
try
      result[i].LoadFromStream(AStream);
except
writeln('item exception ',i,' at ',HexStr(lpos,8));
end;
    end;

  end;
end;

procedure WriteItemList(AStream:TTL2Stream; alist:TTL2ItemList);
var
  i:integer;
begin
  AStream.WriteDWord(Length(alist));
  for i:=0 to High(alist) do
    alist[i].SaveToStream(AStream);
end;

end.
