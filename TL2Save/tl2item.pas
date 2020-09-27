unit TL2Item;

interface

uses
  Classes,
  rgstream,
  tl2common,
  tl2base,
  tl2active,
  rgglobal,
  tl2Effects;

type
  TTL2Item = class;
  TTL2ItemList = array of TTL2Item;
type
  TTL2Item = class(TL2ActiveClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TStream); override;
    procedure SaveToStream  (AStream: TStream); override;

    function CheckForMods(alist:TTL2ModList):boolean;

  private
    FPrefix:string;

//    FIsProp:boolean;

    FEnchantmentCount:integer;
    FStashPosition   :integer;

    FStackSize  :integer;
    FSocketCount:integer;
    FSocketables:TTL2ItemList;

    FWeaponDamage:integer;
    FArmor       :integer;
    FArmorType   :integer;

    FFlags:array [0..6] of byte;

    FPosition1:TVector3;

    FUnkn1:array [0..2] of TRGID;
    FUnkn2:array [0..28] of byte;
    FUnkn4:DWord;
    FUnkn5:array [0..2] of DWord;
    FUnkn6:TL2IdValList;

    FUseState:integer;

    function GetPropFlag:boolean;
    function GetDBMods():string; override;
    function GetFlags(idx:integer):boolean;
    function GetUsability:boolean;
//    function GetDBModList(aid:TRGID):string; override;
  public
    property Prefix:string read FPrefix;

    property IsProp:boolean read GetPropFlag;

    property Flags[idx:integer]:boolean read GetFlags;
    property Position1:TVector3 read FPosition1;
    property IsUsable:boolean read GetUsability;

    property Stack       :integer read FStackSize write FStackSize;
    property EnchantCount:integer read FEnchantmentCount write FEnchantmentCount;
    property Position    :integer read FStashPosition;
    property SocketCount :integer read FSocketCount ; // write FSocketCount;
    property WeaponDamage:integer read FWeaponDamage;
    property Armor       :integer read FArmor;
    property ArmorType   :integer read FArmorType;

    property Unkn6:TL2IdValList   read FUnkn6;
  end;


function  ReadItemList (AStream:TStream):TTL2ItemList;
procedure WriteItemList(AStream:TStream; alist:TTL2ItemList);


implementation

uses
  tl2db;

constructor TTL2Item.Create;
begin
  inherited;

  DataType:=dtItem;
  FUseState:=-1;
end;

destructor TTL2Item.Destroy;
begin
  InternalClear;

  inherited;
end;

function TTL2Item.GetPropFlag:boolean;
begin
  result:=FUnkn2[0]<>0;
end;

function TTL2Item.GetDBMods():string;
begin
  if FDBMods='' then
    FDBMods:=GetItemMods(FID);
  result:=FDBMods;
end;

function TTL2Item.GetUsability:boolean;
begin
  if FUseState<0 then
  begin
    FUseState:=GetItemUsability(id);
  end;
  result:=FUseState>0;
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
  for i:=0 to High(FSocketables) do
    FSocketables[i].Free;
  SetLength(FSocketables,0);

  SetLength(FUnkn6,0);

  inherited;
end;

procedure TTL2Item.Clear;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Item.LoadFromStream(AStream: TStream);
var
ldebug:string;
  i,lcnt:integer;
begin
  DataOffset:=AStream.Position;
ldebug:='';
  FSign:=AStream.ReadByte; // "2" (0 for gold)
if (FSign<>0) and (FSign<>2) then ldebug:=ldebug+'sign '+HexStr(AStream.Position,8)+#13#10;
  FID    :=TRGID(AStream.ReadQWord);  // Item ID
  FName  :=AStream.ReadShortString(); // name
  FPrefix:=AStream.ReadShortString(); // prefix
  FSuffix:=AStream.ReadShortString(); // suffix

  //??
  AStream.Read(FUnkn1,24);
{
  AStream.ReadQWord; // props: object ID in levelset layout
  AStream.ReadQWord; //
  AStream.ReadQWord; //
}
  FModIds:=AStream.ReadIdList;

  //??
  AStream.Read(FUnkn2,29);
if FUnkn2[0]>1 then ldebug:=ldebug+'funk2 '+HexStr(AStream.Position,8)+#13#10;
if pDWord(@FUnkn2[25])^<>0 then ldebug:=ldebug+'funk2(last) '+HexStr(AStream.Position,8)+#13#10;
{
  AStream.ReadByte;  // 0 (1 - "Layout link")
  AStream.ReadQWord; // -1 or "Layout Link" ID on location
  AStream.ReadQWord; // -1 or "Unit spawner"
  AStream.ReadQWord; // -1 or unknown (for unit spawner)
  AStream.ReadDWord; // 0
}
  FEnchantmentCount:=integer(AStream.ReadDWord); // enchantment count // prop=E56DE12D
  FStashPosition   :=integer(AStream.ReadDWord); // stash position $285 = 645 . -1 for props

  AStream.Read(FFlags,7);
if FFlags[4]<>1 then ldebug:=ldebug+'unknown item flag at '+HexStr(AStream.Position,8)+#13#10;
{    itm   prop
  0 - <equipped> flag
  1 - <enabled>
  2 - 1
  3 - 1
  4 - 1 <??visible>
  5 - 0 <??keep after activation>
  6 - <recognized> flag
}
  // coordinates
  FPosition1:=AStream.ReadCoord(); // place where from picked up?
  AStream.Read(FOrientation,SizeOf(FOrientation));

  FLevel      :=integer(AStream.ReadDWord); //
  FStackSize  :=integer(AStream.ReadDWord); // -1 (or 0-1 for 2-state) props
  FSocketCount:=integer(AStream.ReadDWord); // 0  or unknown for props

  FSocketables:=ReadItemList(AStream);

  //??
  FUnkn4:=AStream.ReadDWord;  // 0
if FUnkn4<>0 then ldebug:=ldebug+'before weap dmg_'+HexStr(AStream.Position,8)+#13#10;
  FWeaponDamage:=integer(AStream.ReadDWord); // -1 for non-weapon
  FArmor       :=integer(AStream.ReadDWord); // -1 for non-armor
  FArmorType   :=integer(AStream.ReadDWord); // 0 for items, 0-15 for props

  //??
  AStream.Read(FUnkn5,12);
if FUnkn5[0]<>$FFFFFFFF then ldebug:=ldebug+'Unkn5[0]='+HexStr(FUnkn5[0],8)+' at '+HexStr(AStream.Position,8)+#13#10;
if FUnkn5[1]<>$FFFFFFFF then ldebug:=ldebug+'Unkn5[1]='+HexStr(FUnkn5[1],8)+' at '+HexStr(AStream.Position,8)+#13#10;
if FUnkn5[2]<>$FFFFFFFF then ldebug:=ldebug+'Unkn5[2]='+HexStr(FUnkn5[2],8)+' at '+HexStr(AStream.Position,8)+#13#10;
{
  37 gold = 3*454; 48 = 0; 109, 51 = 211 - same values for same location?
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
  for i:=0 to 2 do
    FEffects[i]:=ReadEffectList(AStream);

  FAugments:=AStream.ReadShortStringList;

  FStats:=AStream.ReadIdValList;
if ldebug<>'' then
DbgLn('start item '+string(widestring(FName))+#13#10+
ldebug+
'end item'#13#10'---------');

  LoadBlock(AStream);
end;

procedure TTL2Item.SaveToStream(AStream: TStream);
var
  i:integer;
begin
  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;

  AStream.WriteByte(FSign);            // "2" (0 for gold)
  AStream.WriteQWord(QWord(FID));      // Item ID
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
  AStream.WriteDWord(DWord(FStashPosition   )); // stash position

  AStream.Write(FFlags,7);

  // coordinates
  AStream.WriteCoord(FPosition1);
  AStream.Write(FOrientation,SizeOf(FOrientation));

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
  
  // dynamic,passive,transfer
  for i:=0 to 2 do
    WriteEffectList(AStream,FEffects[i]);

  AStream.WriteShortStringList(FAugments);

  AStream.WriteIdValList(FStats);

  LoadBlock(AStream);
end;

function ReadItemList(AStream:TStream):TTL2ItemList;
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
//!!      result[i].IsProp:=false;
      try
        result[i].LoadFromStream(AStream);
      except
        if IsConsole then writeln('item exception ',i,' at ',HexStr(lpos,8));
      end;
    end;

  end;
end;

procedure WriteItemList(AStream:TStream; alist:TTL2ItemList);
var
  i:integer;
begin
  AStream.WriteDWord(Length(alist));
  for i:=0 to High(alist) do
    alist[i].SaveToStream(AStream);
end;

function TTL2Item.CheckForMods(alist:TTL2ModList):boolean;
var
  llist:TL2IdList;
  lid,lmodid:TRGID;
begin
  result:=inherited CheckForMods(alist);

  if not result then
  begin
    if alist<>nil then
    begin
      // Check : alternative object with same unittype
      // Action: replace one item by another
      // Remark: change JUST id, not name etc
      lmodid:=GetAlt(id,alist,lid);
      if lmodid<>RGIdEmpty then
      begin
        if lid<>id then
        begin
          id:=lid;
          if lmodid=0 then
            ModIds:=nil
          else
          begin
            SetLength(llist,1);
            llist[0]:=lmodid;
            ModIds:=llist;
          end;
        end;
        result:=true;
        Changed:=true;
      end;
    end;
  end;
end;

end.
