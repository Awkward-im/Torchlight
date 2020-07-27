unit TL2Active;

interface

uses
  TL2Types,
  TL2Base,
  TL2Effects;

type
  TL2ActiveClass = class(TL2BaseClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

  protected
    FID     :TL2ID;
    FName   :string;
    FSuffix :string;
    FLevel  :integer;

    FSign   :Byte;
    FEnabled:TL2Boolean;

    // Orientation
    FOrientation:packed record
      FPosition     :TL2Coord;
      FForward      :TL2Coord;
      FForwardValue :TL2Float;
      FUp           :TL2Coord;
      FUpValue      :TL2Float;
      FRight        :TL2Coord;
      FRightValue   :TL2Float;
      FScale        :TL2Coord;
      FScaleValue   :TL2Float;
    end;

    FDBMods  :string;
    FModIds  :TL2IdList;
    FEffects1:TTL2EffectList;
    FEffects2:TTL2EffectList;
    FEffects3:TTL2EffectList;
    FAugments:TL2StringList;
    FStats   :TL2IdValList;

    function  GetDBMods():string; virtual;

  private
    function  GetStat(const iname:string):TL2Integer;
    procedure SetStat(const iname:string; aval:TL2Integer);

  public
    // true - mod found/replaced; false - unsupported mod
    function CheckForMods(alist:TTL2ModList):boolean;

    property Name   :string     read FName    write FName;
    property Suffix :string     read FSuffix  write FSuffix;
    property ID     :TL2ID      read FID      write FID;
    property Level  :integer    read FLevel   write FLevel;
    property Sign   :Byte       read FSign    write FSign;
    property Enabled:TL2Boolean read FEnabled write FEnabled;
    property Coord  :TL2Coord   read FOrientation.FPosition;

    property ModIds  :TL2IdList      read FModIds   write FModIds;
    property Effects1:TTL2EffectList read FEffects1 write FEffects1;
    property Effects2:TTL2EffectList read FEffects2 write FEffects2;
    property Effects3:TTL2EffectList read FEffects3 write FEffects3;
    property Augments:TL2StringList  read FAugments;
    property Stats   :TL2IdValList   read FStats;
    property Stat[iname:string]:TL2Integer read GetStat  write SetStat;
  end;


implementation

uses
  tl2db;

//----- Init / Free -----

constructor TL2ActiveClass.Create;
begin
  inherited;
end;

destructor TL2ActiveClass.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TL2ActiveClass.InternalClear;
var
  i:integer;
begin
  FDBMods:='';
  
  SetLength(FModIds,0);

  for i:=0 to High(FEffects1) do FEffects1[i].Free;  SetLength(FEffects1,0);
  for i:=0 to High(FEffects2) do FEffects2[i].Free;  SetLength(FEffects2,0);
  for i:=0 to High(FEffects3) do FEffects3[i].Free;  SetLength(FEffects3,0);

  SetLength(FAugments,0);
  SetLength(FStats,0);
end;

procedure TL2ActiveClass.Clear;
begin
  InternalClear;

  Inherited;
end;


function TL2ActiveClass.GetDBMods():string;
begin
  result:=FDBMods;
end;

function TL2ActiveClass.GetStat(const iname:string):TL2Integer;
var
  i:integer;
begin

  i:=GetStatIdx(Stats,iname);
  if i>=0 then
    result:=Stats[i].value
  else
    result:=0;
end;

procedure TL2ActiveClass.SetStat(const iname:string; aval:TL2Integer);
var
  i:integer;
begin
  i:=GetStatIdx(Stats,iname);
  if i>=0 then
    Stats[i].value:=aval;
end;

function TL2ActiveClass.CheckForMods(alist:TTL2ModList):boolean;
var
  llist:TL2IdList;
  lmodid:TL2ID;
  lmods:string;
  i:integer;
begin
  result:=true;

  // Object is unmodded
  if ModIds=nil then
    exit;

  if alist<>nil then
  begin
    // Check : object's savegame mods are in alist
    // Action: Remove object's mods which not presents in alist
    llist:=nil;
    for i:=0 to High(ModIds) do
    begin
      if IsInModList(ModIds[i],alist) then
      begin
        SetLength(llist,Length(llist)+1);
        llist[High(llist)]:=ModIds[i];
      end;
    end;
    if Length(llist)<>Length(ModIds) then
    begin
      ModIds:=llist;
      Changed:=true;
    end;
    if Length(llist)>0 then exit;

    // Check : object exists in alist's mods (from DB info)
    // Action: Add mod which support object from alist to object's mod list
    // Remark: ModIds must be nil already
    lmods:=GetDBMods;

    lmodid:=IsInModList(lmods, alist);
    if lmodid<>TL2IdEmpty then
    begin
      if lmodid<>0 then
      begin
        SetLength(llist,1);
        llist[0]:=lmodid;
        ModIds:=llist;
      end;
      Changed:=true;
      exit;
    end;
  end;

  // Object's mod not found
  result:=false;
end;

end.
