unit TLSGItem;

interface

uses
  SysUtils,
  Classes,
  rgglobal,
  rgstream,
  tlsgcommon,
  tlsgbase,
  tlsgactive,
  tlsgeffects;

type
  TDamageBonus = record
    bonus  : TRGFloat; // flat damage bonus from non-enchantment sources
    enchant: TRGFloat; // flat damage bonus from enchantment sources (TL2 only)
    dmgtype: DWord;    // damage type (0=physical, 1=magical, 2=fire, 3=ice, 4=electric, 5=poison, 6=all)
  end;
  TDmgBonusList = array of TDamageBonus;

type
  TTLItem = class;
  TTLItemList = array of TTLItem;
type
  TTLItem = class(TLActiveClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TStream; aVersion:integer); override;
    procedure SaveToStream  (AStream: TStream; aVersion:integer); override;

    function CheckForMods(alist:TTL2ModList):boolean;

  private
    FPrefix:string;

    FQuestID:TRGID;

    FEnchantmentCount:integer;
    FStashPosition   :integer;

    FStackSize  :integer;
    FSocketCount:integer;
    FSocketables:TTLItemList;

    FWeaponDamage:integer;
    FArmor       :integer;
    FArmorType   :integer;

    FFlags:array [0..6] of byte;

    FPosition1:TVector3;

    FDmgBonus:array of TDamageBonus;

    FUseState:integer;

    function GetPropFlag:boolean;
    function GetFlags(idx:integer):boolean;
    function GetUsability:boolean;
//    function GetDBModList(aid:TRGID):string; override;
  protected
    function GetDBMods():string; override;
  public
    FUnkn1:array [0..2] of TRGID;
    FUnkn2b:byte;  // 0 - use 21 and 22; 1 - use 20
    FUnkn20:TRGID; // layout link?
    FUnkn21:TRGID; // unit spawner?
    FUnkn22:TRGID; // used with 21 only
    FUnkn23:DWord;

    FUnkn4:DWord;
    FUnkn5:integer;

    property Prefix:string read FPrefix;

    property IsProp:boolean read GetPropFlag;

    property Flags[idx:integer]:boolean read GetFlags;
    property Position1:TVector3 read FPosition1;
    property IsUsable:boolean read GetUsability;

    // Items
    property ItemStack   :integer read FStackSize write FStackSize;
    property EnchantCount:integer read FEnchantmentCount write FEnchantmentCount;
    property Position    :integer read FStashPosition;
    property SocketCount :integer read FSocketCount ; // write FSocketCount;
    property WeaponDamage:integer read FWeaponDamage;
    property Armor       :integer read FArmor;
    property ArmorType   :integer read FArmorType;

    property QuestID     :TRGID   read FQuestID;
    // Props
    property PropState   :integer read FStackSize write FStackSize;

    property DmgBonus:TDmgBonusList read FDmgBonus;
  end;


function  ReadItemList (AStream:TStream; aVersion:integer):TTLItemList;
procedure WriteItemList(AStream:TStream; alist:TTLItemList; aVersion:integer);


implementation

uses
  rgdb;

constructor TTLItem.Create;
begin
  inherited;

  DataType:=dtItem;
  FUseState:=-1;
end;

destructor TTLItem.Destroy;
begin
  InternalClear;

  inherited;
end;

function TTLItem.GetPropFlag:boolean;
begin
  result:=not ((FUnkn20=RGIdEmpty) and (FUnkn21=RGIdEmpty) and (FUnkn22=RGIdEmpty));
end;

function TTLItem.GetDBMods():string;
begin
  if FDBMods='' then
    FDBMods:=RGDBGetItemMods(FID);
  result:=FDBMods;
end;

function TTLItem.GetUsability:boolean;
begin
  if FUseState<0 then
  begin
    FUseState:=RGDBGetItemUsability(id);
  end;
  result:=FUseState>0;
end;

function TTLItem.GetFlags(idx:integer):boolean;
begin
  if (idx>=0) and (idx<=6) then
    result:=FFlags[idx]<>0
  else
    result:=false;
end;

procedure TTLItem.InternalClear;
var
  i:integer;
begin
  for i:=0 to High(FSocketables) do
    FSocketables[i].Free;
  SetLength(FSocketables,0);

  SetLength(FDmgBonus,0);

  inherited;
end;

procedure TTLItem.Clear;
begin
  InternalClear;

  inherited;
end;

procedure TTLItem.LoadFromStream(AStream: TStream; aVersion:integer);
var
ldebug:string;
  i,lcnt:integer;
begin
  DataOffset:=AStream.Position;
  ldebug:='';

  if aVersion>=tlsaveTL2Minimal then
  begin
    FSign:=AStream.ReadByte; // "2" (0 for gold)
    if (FSign<>0) and (FSign<>2) then ldebug:=ldebug+'sign '+HexStr(AStream.Position,8)+#13#10;
  end;
  FID    :=TRGID(AStream.ReadQWord);  // Item ID
  FName  :=AStream.ReadShortString(); // name
  FPrefix:=AStream.ReadShortString(); // prefix
  FSuffix:=AStream.ReadShortString(); // suffix

  //??
  if aVersion>=tlsaveTL2Minimal then
  begin
    AStream.Read(FUnkn1,24);
  {
    AStream.ReadQWord; // props: object ID in levelset layout
    AStream.ReadQWord; //
    AStream.ReadQWord; //
  }
    FModIds:=AStream.ReadIdList;
  end
  else
    AStream.Read(FUnkn1,16);

  {
    AStream.ReadByte;  // 0 (1 - "Layout link")
    AStream.ReadQWord; // -1 or "Layout Link" ID on location
    AStream.ReadQWord; // -1 or "Unit spawner"
    AStream.ReadQWord; // -1 or unknown (for unit spawner)
    AStream.ReadDWord; // 0
  }
  FUnkn2b:=AStream.ReadByte();
  if FUnkn2b>1 then ldebug:=ldebug+'funk2b '+IntToStr(FUnkn2b)+' at '+HexStr(AStream.Position,8)+#13#10;
  FUnkn20:=TRGID(AStream.ReadQWord());
  FUnkn21:=TRGID(AStream.ReadQWord());
  if aVersion>=tlsaveTL2Minimal then
    FUnkn22:=TRGID(AStream.ReadQWord())
  else
    FUnkn22:=RGIdEmpty;

  FUnkn23:=AStream.ReadDWord();
  if FUnkn23<>0 then ldebug:=ldebug+'funk23='+IntToStr(FUnkn23)+' at '+HexStr(AStream.Position,8)+#13#10;

  FEnchantmentCount:=integer(AStream.ReadDWord); // enchantment count // prop=E56DE12D
  FStashPosition   :=integer(AStream.ReadDWord); // stash position $285 = 645 . -1 for props

  if aVersion>=tlsaveTL2Minimal then
  begin
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
  end
  else
  begin
    AStream.Read(FFlags,6);
{
      0 -
      1 - 
      2 - 
      3 - 
      4 - 
      5 - 

}
  end;

  // coordinates
  FPosition1:=AStream.ReadCoord(); // place where from picked up?
  AStream.Read(FOrientation,SizeOf(FOrientation));

  if aVersion>=tlsaveTL2Minimal then
    FLevel:=integer(AStream.ReadDWord);

  // prop: chest: 1 - opened
  FStackSize  :=integer(AStream.ReadDWord); //-1 (or 0-1 for 2-state) props
  FSocketCount:=integer(AStream.ReadDWord); // 0  or unknown for props (loop?)

  FSocketables:=ReadItemList(AStream, aVersion);

  //??
  if aVersion>=tlsaveTL2Minimal then
  begin
    FUnkn4:=AStream.ReadDWord;  // 0
    if FUnkn4<>0 then ldebug:=ldebug+'before weap dmg_'+HexStr(AStream.Position,8)+#13#10;
  end;

  FWeaponDamage:=integer(AStream.ReadDWord); // -1 for non-weapon
  FArmor       :=integer(AStream.ReadDWord); // -1 for non-armor
  FArmorType   :=integer(AStream.ReadDWord); // 0 for items, 0-15 for props

  FQuestID:=TRGID (AStream.ReadQWord());
  FUnkn5  :=integer(AStream.ReadDWord());
{
  37 gold = 3*454; 48 = 0; 109, 51 = 211 - same values for same location?
  AStream.ReadQWord; // *FF
  AStream.ReadDWord; // *FF
}
  //??
  lcnt:=AStream.ReadWord;
  SetLength(FDmgBonus,lcnt);
  if lcnt>0 then
  begin
    if aVersion>=tlsaveTL2Minimal then
      AStream.Read(FDmgBonus[0],lcnt*SizeOf(TDamageBonus))
    else
    begin
      for i:=0 to lcnt-1 do
      begin
        FDmgBonus[i].bonus  :=AStream.ReadFloat;
        FDmgBonus[i].dmgtype:=AStream.ReadDWord;
      end;
    end;
  end;

  // dynamic,passive,transfer
  for i:=0 to 2 do
    FEffects[i]:=ReadEffectList(AStream, aVersion);

  if aVersion>=tlsaveTL2Minimal then
  begin
    FAugments:=AStream.ReadShortStringList;

    FStats:=AStream.ReadIdValList;
  end;

  if ldebug<>'' then
    DbgLn('start item '+FName+#13#10+
    ldebug+
    'end item'#13#10'---------');

  LoadBlock(AStream);
end;

procedure TTLItem.SaveToStream(AStream: TStream; aVersion:integer);
var
  i,lcnt:integer;
begin
  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;

  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteByte(FSign);          // "2" (0 for gold)

  AStream.WriteQWord(QWord(FID));      // Item ID
  AStream.WriteShortString(FName);     // name
  AStream.WriteShortString(FPrefix);   // prefix
  AStream.WriteShortString(FSuffix);   // suffix

  if aVersion>=tlsaveTL2Minimal then
  begin
    //??
    AStream.Write(FUnkn1,24);
    {
      AStream.WriteQWord;
      AStream.WriteQWord;     // changing
      AStream.WriteQWord;
    }
    AStream.WriteIdList(FModIds);
  end
  else
    AStream.Write(FUnkn1,16);

  //??
  AStream.WriteByte(FUnkn2b);
  AStream.WriteQWord(QWord(FUnkn20));
  AStream.WriteQWord(QWord(FUnkn21));
  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteQWord(QWord(FUnkn22));
  AStream.WriteDWord(FUnkn23);

  AStream.WriteDWord(DWord(FEnchantmentCount)); // enchantment count
  AStream.WriteDWord(DWord(FStashPosition   )); // stash position

  if aVersion>=tlsaveTL2Minimal then
    AStream.Write(FFlags,7)
  else
    AStream.Write(FFlags,6);

  // coordinates
  AStream.WriteCoord(FPosition1);
  AStream.Write(FOrientation,SizeOf(FOrientation));

  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteDWord(FLevel);

  AStream.WriteDWord(DWord(FStackSize));
  AStream.WriteDWord(DWord(FSocketCount));

  WriteItemList(AStream,FSocketables, aVersion);

  //??
  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteDWord(FUnkn4);

  AStream.WriteDWord(DWord(FWeaponDamage));
  AStream.WriteDWord(DWord(FArmor));
  AStream.WriteDWord(DWord(FArmorType));

  //??
  AStream.Write(FUnkn5,12);
{
  AStream.WriteDWord; // *FF
  AStream.WriteDWord; // *FF
  AStream.WriteDWord; // *FF
}
  //??
  lcnt:=Length(FDmgBonus);
  AStream.WriteWord(lcnt);
  if lcnt>0 then
  begin
    if aVersion>=tlsaveTL2Minimal then
      AStream.Write(FDmgBonus[0],lcnt*SizeOf(TDamageBonus))
    else
    begin
      for i:=0 to lcnt-1 do
      begin
        AStream.WriteFloat(FDmgBonus[i].bonus);
        AStream.WriteDWord(FDmgBonus[i].dmgtype);
      end;
    end;
  end;

  // dynamic,passive,transfer
  for i:=0 to 2 do
    WriteEffectList(AStream,FEffects[i], aVersion);

  if aVersion>=tlsaveTL2Minimal then
  begin
    AStream.WriteShortStringList(FAugments);

    AStream.WriteIdValList(FStats);
  end;

  LoadBlock(AStream);
end;

function ReadItemList(AStream:TStream; aVersion:integer):TTLItemList;
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
      
      result[i]:=TTLItem.Create;
//!!      result[i].IsProp:=false;
      try
        result[i].LoadFromStream(AStream, aVersion);
      except
        RGLog.Add('item exception '+IntToStr(i)+' at '+HexStr(lpos,8));
      end;
    end;

  end;
end;

procedure WriteItemList(AStream:TStream; alist:TTLItemList; aVersion:integer);
var
  i:integer;
begin
  AStream.WriteDWord(Length(alist));
  for i:=0 to High(alist) do
    alist[i].SaveToStream(AStream, aVersion);
end;

function TTLItem.CheckForMods(alist:TTL2ModList):boolean;
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
      lmodid:=RGDBGetAltItem(id,alist,lid);
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
