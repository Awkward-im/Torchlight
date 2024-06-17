unit TLSGActive;

interface

uses
  rgglobal,
  tlsgbase,
  tlsgeffects;

type
  TLActiveClass = class(TLSGBaseClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

  protected
    FID     :TRGID;
    FName   :string;
    FSuffix :string;
    FLevel  :integer;

    FSign   :Byte;
    FEnabled:Boolean;

    // Orientation
    FOrientation:packed record
      FPosition     :TVector3;
      FRotation     :array [0..3,0..3] of TRGFloat;
    end;

    FDBMods  :string;
    FModIds  :TL2IdList;               // TL2
    FModNames:TL2StringList;           // TL1
    FEffects :array [0..2] of TTLEffectList;
    FAugments:TL2StringList;
    FStats   :TL2IdValList;

    function  GetDBMods():string; virtual;

  private
    function  GetStat(const iname:string):TRGInteger;
    procedure SetStat(const iname:string; aval:TRGInteger);
    function  GetEffects(idx:integer):TTLEffectList;
    procedure SetEffects(idx:integer; aval:TTLEffectList);

  public
    // true - mod found/replaced; false - unsupported mod
    function CheckForMods(alist:TTL2ModList):boolean;

    property Name   :string     read FName    write FName;
    property Suffix :string     read FSuffix  write FSuffix;
    property ID     :TRGID      read FID      write FID;
    property Level  :integer    read FLevel   write FLevel;
    property Sign   :Byte       read FSign    write FSign;
    property Enabled:Boolean    read FEnabled write FEnabled;
    property Coord  :TVector3   read FOrientation.FPosition;

    property ModIds  :TL2IdList      read FModIds   write FModIds;
    property ModNames:TL2StringList  read FModNames write FModNames;
    property Effects[idx:integer]:TTLEffectList read GetEffects write SetEffects;
    property Augments:TL2StringList  read FAugments;
    property Stats   :TL2IdValList   read FStats;
    property Stat[iname:string]:TRGInteger read GetStat  write SetStat;
  end;


implementation

uses
  tl2db;

//----- Init / Free -----

constructor TLActiveClass.Create;
begin
  inherited;
end;

destructor TLActiveClass.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TLActiveClass.InternalClear;
var
  i,j:integer;
begin
  FDBMods:='';
  
  SetLength(FModIds  ,0);
  SetLength(FModNames,0);

  for i:=0 to 2 do
  begin
    for j:=0 to High(FEffects[i]) do
      FEffects[i][j].Free;
    SetLength(FEffects[i],0);
  end;

  SetLength(FAugments,0);
  SetLength(FStats,0);
end;

procedure TLActiveClass.Clear;
begin
  InternalClear;

  Inherited;
end;

//----- properties -----

function TLActiveClass.GetDBMods():string;
begin
  result:=FDBMods;
end;

function TLActiveClass.GetStat(const iname:string):TRGInteger;
var
  i:integer;
begin

  i:=GetStatIdx(Stats,iname);
  if i>=0 then
    result:=Stats[i].value
  else
    result:=0;
end;

procedure TLActiveClass.SetStat(const iname:string; aval:TRGInteger);
var
  i:integer;
begin
  i:=GetStatIdx(Stats,iname);
  if i>=0 then
    Stats[i].value:=aval;
end;

function TLActiveClass.GetEffects(idx:integer):TTLEffectList;
begin
  if (idx>=0) and (idx<=2) then
    result:=FEffects[idx]
  else
    result:=FEffects[0]
end;

procedure TLActiveClass.SetEffects(idx:integer; aval:TTLEffectList);
begin
  if (idx>=0) and (idx<=2) then
    FEffects[idx]:=aval
  else
    FEffects[0]:=aval
end;

//----- Other -----

function TLActiveClass.CheckForMods(alist:TTL2ModList):boolean;
var
  llist:TL2IdList;
  lmodid:TRGID;
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
    if lmodid<>RGIdEmpty then
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
