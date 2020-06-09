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
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TTL2Stream); override;
    procedure SaveToStream  (AStream: TTL2Stream); override;

  private
    FItemId   :TL2ID;
    FName     :string;
    FPrefix   :string;
    FSuffix   :string;

    FModIds:TL2IdList;
    FIsProp:boolean;

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

    FSign:byte;
    FFlags:array [0..6] of byte;

    FPosition1:TL2Coord;
    FPosition2:TL2Coord;

    FUnkn1:array [0..23] of byte;
    FUnkn2:array [0..28] of byte;
    FUnkn3:array [0..63] of byte; // coords like for character
    FUnkn4:DWord;
    FUnkn5:array [0..11] of byte;
    FUnkn6:TL2IdValList;

    function GetFlags(idx:integer):boolean;
  public
    property Name  :string read FName;
    property Prefix:string read FPrefix;
    property Suffix:string read FSuffix;
    property ID    :TL2ID  read FItemId;

    property IsProp:boolean   read FIsProp write FIsProp;
    property ModIds:TL2IdList read FModIds write FModIds;

    property Flags[idx:integer]:boolean read GetFlags;
    property Position1:TL2Coord read FPosition1;
    property Position2:TL2Coord read FPosition2;

    property Level:integer read FLevel;
    property Stack:integer read FStackSize write FStackSize;
    property EnchantCount:integer read FEnchantmentCount write FEnchantmentCount;
    property Position:integer read FStashPosition;
    property SocketCount:integer read FSocketCount ; // write FSocketCount;
    property WeaponDamage:integer read FWeaponDamage;
    property Armor       :integer read FArmor;
    property ArmorType   :integer read FArmorType;

    property Unkn6   :TL2IdValList   read FUnkn6;
    property Effects1:TTL2EffectList read FEffects1 write FEffects1;
    property Effects2:TTL2EffectList read FEffects2 write FEffects2;
    property Effects3:TTL2EffectList read FEffects3 write FEffects3;

    property Augments:TL2StringList  read FAugments;
    property Stats   :TL2IdValList   read FStats;
  end;


function  ReadItemList (AStream:TTL2Stream):TTL2ItemList;
procedure WriteItemList(AStream:TTL2Stream; alist:TTL2ItemList);


implementation


constructor TTL2Item.Create;
begin
  inherited;

  DataType:=dtItem;
end;

destructor TTL2Item.Destroy;
begin
  InternalClear;

  inherited;
end;

function TTL2Item.GetFlags(idx:integer):boolean;
begin
  if (idx>=0) and (idx<=6) then
    result:=FFlags[idx]<>0
  else
    result:=false;
end;

procedure TTL2Item.InternalClear;
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
  SetLength(FStats,0);

  SetLength(FUnkn6,0);
end;

procedure TTL2Item.Clear;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Item.LoadFromStream(AStream: TTL2Stream);
var
  lcnt:integer;
begin
  DataOffset:=AStream.Position;

  FSign:=Check(AStream.ReadByte,'item sign_'+HexStr(AStream.Position,8),2); // "2" (0 for gold)
  FItemId:=TL2ID(AStream.ReadQWord);  // Item ID
  FName  :=AStream.ReadShortString(); // name
  FPrefix:=AStream.ReadShortString(); // prefix
  FSuffix:=AStream.ReadShortString(); // suffix

  //??
  AStream.Read(FUnkn1,24);
{
  AStream.ReadQWord;
  AStream.ReadQWord;     // changing (same as previous)
  AStream.ReadQWord;
}
  FModIds:=AStream.ReadIdList;

  //??
  AStream.Read(FUnkn2,29);
{
  AStream.ReadByte;      // 0    (1 - portal?)
  AStream.ReadQWord;     // *FF  (portal to? not in source)
  AStream.ReadQWord;     // *FF props - not -1  MEDIA\LAYOUTS\ACT1_PASS1\1X1SINGLE_ROOM_A\PAPASS_PB_A.LAYOUT
  AStream.ReadQWord;     // *FF props - not -1  ?
  AStream.ReadDWord;     // 0
}
  FEnchantmentCount:=integer(AStream.ReadDWord); // enchantment count // prop=E56DE12D
  FStashPosition   :=integer(AStream.ReadDWord); // stash position $285 = 645 . -1 for props

  AStream.Read(FFlags,7);
{    itm   prop
  0 - <equipped> flag
  1 - 1      ?
  2 - 1
  3 - 1
  4 - 1
  5 - 0
  6 - <recognized> flag
}
  // coordinates
  FPosition1:=AStream.ReadCoord(); // place where from picked up?
  FPosition2:=AStream.ReadCoord(); // 0 for equipped?
  AStream.Read(FUnkn3,64);
{ Like for character
  // direction
  AStream.ReadCoord;   // Forward
  AStream.ReadDWord;   // 0

  AStream.ReadCoord;   // Up
  AStream.ReadDWord;   // 0
  
  AStream.ReadCoord;   // Right
  AStream.ReadDWord;   // 0

  AStream.ReadDWord;   // 0  \
  AStream.ReadDWord;   // 0  | coord?
  AStream.ReadDWord;   // 0  /
  AStream.ReadFloat;   // float=1.0
}

  FLevel      :=integer(AStream.ReadDWord); // 1  for props (22)
  FStackSize  :=integer(AStream.ReadDWord); // -1 for props (1)
  FSocketCount:=integer(AStream.ReadDWord); // 0  for props (A009CC81)

  FSocketables:=ReadItemList(AStream);

  //??
  FUnkn4:=AStream.ReadDWord;  // 0
  FWeaponDamage:=integer(AStream.ReadDWord); // -1 for props
  FArmor       :=integer(AStream.ReadDWord); // -1 for props
  FArmorType   :=integer(AStream.ReadDWord); //  0 for props (2)

  //??
  AStream.Read(FUnkn5,12);
{
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF
}
  //??
  lcnt:=AStream.ReadWord;
(*
2 bytes  short   number of 12-byte-long damage things
X bytes  struct  list of 12-byte-long damage things{
    4 bytes  float  flat damage bonus from non-enchantment sources (all sources summed for given damage type)
    4 bytes  float  flat damage bonus from enchantment sources (all sources summed for given damage type)
    4 bytes  int    damage type (0=physical, 1=magical, 2=fire, 3=ice, 4=electric, 5=poison, 6=all)
    (what about base elemental damage? An entry for an element is added, but both values are zero
    and the real value is pulled from the item's bindat file)
}
*)
  SetLength(FUnkn6,lcnt);
  if lcnt>0 then
    AStream.Read(FUnkn6[0],lcnt*SizeOf(TL2IdVal));

  // dynamic,passive,transfer
  FEffects1:=ReadEffectList(AStream);
  FEffects2:=ReadEffectList(AStream);
  FEffects3:=ReadEffectList(AStream);

  FAugments:=AStream.ReadShortStringList;

  FStats:=AStream.ReadIdValList;

  LoadBlock(AStream);
end;

procedure TTL2Item.SaveToStream(AStream: TTL2Stream);
begin
  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;

  AStream.WriteByte(FSign);            // "2" (0 for gold)
  AStream.WriteQWord(QWord(FItemId));  // Item ID
  AStream.WriteShortString(FName);     // name
  AStream.WriteShortString(FPrefix);   // prefix
  AStream.WriteShortString(FSuffix);   // suffix

  //??
  AStream.Write(FUnkn1,24);
{
  AStream.ReadQWord;
  AStream.ReadQWord;     // changing
  AStream.ReadQWord;
}
  AStream.WriteIdList(FModIds);

  //??
  AStream.Write(FUnkn2,29);
{
  AStream.ReadByte;      // 0
  AStream.ReadQWord;     // *FF
  AStream.ReadQWord;     // *FF
  AStream.ReadQWord;     // *FF
  AStream.ReadDWord;     // 0
}
  AStream.WriteDWord(DWord(FEnchantmentCount)); // enchantment count
  AStream.WriteDWord(DWord(FStashPosition   )); // stash position $285 = 645

  // coordinates
  AStream.Write(FFlags,7);
  AStream.WriteCoord(FPosition1);
  AStream.WriteCoord(FPosition2);
  AStream.Write(FUnkn3,64);

  AStream.WriteDWord(FLevel);
  AStream.WriteDWord(dword(FStackSize));
  AStream.WriteDWord(dword(FSocketCount));

  WriteItemList(AStream,FSocketables);

  //??
  AStream.WriteDWord(FUnkn4);
  AStream.WriteDWord(DWord(FWeaponDamage));
  AStream.WriteDWord(DWord(FArmor));
  AStream.WriteDWord(DWord(FArmorType));

  //??
  AStream.Write(FUnkn5,12);
{
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF
  AStream.ReadDWord; // *FF
}
  //??
  AStream.WriteWord(Length(FUnkn6));
  if Length(FUnkn6)>0 then
    AStream.Write(FUnkn6[0],Length(FUnkn6)*SizeOf(TL2IdVal));
//  lcnt:=AStream.ReadWord;
//  AStream.Seek(lcnt*12,soCurrent); // 8+4 ?
  
  // dynamic,passive,transfer
  WriteEffectList(AStream,FEffects1);
  WriteEffectList(AStream,FEffects2);
  WriteEffectList(AStream,FEffects3);

  AStream.WriteShortStringList(FAugments);

  AStream.WriteIdValList(FStats);

  LoadBlock(AStream);
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
      result[i].IsProp:=false;
      try
        result[i].LoadFromStream(AStream);
      except
        if IsConsole then writeln('item exception ',i,' at ',HexStr(lpos,8));
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
