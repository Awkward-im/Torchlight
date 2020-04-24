unit TL2Stats;

interface

uses
  TL2Types,
  TL2Stream,
  TL2Base;

type
  TTL2StringVal = record
    name :string;
    value:TL2Integer;
  end;
  TTL2StringValList = array of TTL2StringVal;

type
  TTL2Stats = class(TL2BaseClass)
  private
    procedure InternalClear;

  public
    constructor Create();
    destructor  Destroy; override;

    procedure Clear;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

  private
    FStatMobs   :array of array [0..39] of byte;
    FStatItems  :array of array [0..23] of byte;
    FStatSkills :array of array [0..16] of byte;
    FStatUnknown:array of array [0..30] of byte;
    FStatArea1  :TTL2StringValList;
    FStatArea2  :TTL2StringValList;
    FStatStats:TL2IdValList;

    FUnkn    :DWord;
    FUnkn17  :array [0..16] of byte;
    FUnkn9   :array [0.. 8] of byte;
    FUnknLast:DWord;

    FStatName :string;
    FStatClass:string;
    FStatPet  :string;
  end;

function ReadLastBlock(AStream:TTL2Stream):TTL2Stats;


implementation

uses
  Classes,
  TL2Common;

constructor TTL2Stats.Create;
begin
  inherited;

end;

destructor TTL2Stats.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Stats.InternalClear;
begin
  SetLength(FStatMobs   ,0);
  SetLength(FStatItems  ,0);
  SetLength(FStatSkills ,0);
  SetLength(FStatUnknown,0);
  SetLength(FStatArea1  ,0);
  SetLength(FStatArea2  ,0);
  SetLength(FStatStats  ,0);
end;

procedure TTL2Stats.Clear;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Stats.LoadFromStream(AStream:TTL2Stream);
var
  i,lcnt:integer;
begin
  FromStream(AStream);

  FUnkn:=Check(AStream.ReadDWord,'last block 1',1);

  AStream.Read(FUnkn17[0],17);
{
  AStream.ReadDWord; // 3DF65D40 = 0.12
  AStream.ReadDword; // 40
  AStream.ReadDWord; // 3DF65D40 = 0.12
  AStream.ReadDWord; // 0x##40

  AStream.ReadByte;  // 0
}
  // ?? mobs
  lcnt:=AStream.ReadDWord;
  SetLength(FStatMobs,lcnt);
  if lcnt>0 then
    AStream.Read(FStatMobs[0],lcnt*40);
{
  8b - mob id (media/units/monsters)
  4b - x?
  4b - y?
  4b - ?
  4b - 
  4b - 
  4b - ?
  4b - 
  2b
  2b
}

  // ?? items
  lcnt:=AStream.ReadDWord;
  SetLength(FStatItems,lcnt);
  if lcnt>0 then
    AStream.Read(FStatItems[0],lcnt*24);
{
  8b - item id (media\units\items)
  4b - 
  4b - 
  4b - [0]
  4b - amount?
}

  // ?? skills
  lcnt:=AStream.ReadDWord;
  SetLength(FStatSkills,lcnt);
  if lcnt>0 then
    AStream.Read(FStatSkills[0],lcnt*17);
{
  8b - skill id (media\skills)
  4b - 
  4b - 
  1b - 
}

  // ??
  lcnt:=AStream.ReadDWord;
  SetLength(FStatUnknown,lcnt);
  if lcnt>0 then
    AStream.Read(FStatUnknown[0],lcnt*31);
{
  4b - 131.87
  4b - ?
  4b - ?
  4b - ?
  1b - [0]
  4b - 
  1b
  4b
  4b
  1b
}

  //----- ?? Area (teleports? time on map?) -----
  // usually, count and titles are the same

  lcnt:=AStream.ReadDWord;
  SetLength(FStatArea1,lcnt);
  for i:=0 to lcnt-1 do
  begin
    FStatArea1[i].name :=AStream.ReadShortString;
    FStatArea1[i].value:=AStream.ReadDWord;
  end;

  lcnt:=AStream.ReadDWord;
  SetLength(FStatArea2,lcnt);
  for i:=0 to lcnt-1 do
  begin
    FStatArea2[i].name :=AStream.ReadShortString;
    FStatArea2[i].value:=AStream.ReadDWord;
  end;

  //----- ?? Unknown -----

  AStream.Read(FUnkn9[0],9);
{
  //?? byte, word, dword (word+word), word
  AStream.ReadDword; // 03 00 00 00  | 01 00 00 18
  AStream.ReadDWord; // 00 00 00 06  | 00 00 00 00
  AStream.ReadByte;  // 00           | 00
}
  //----- ?? [Mob] stats -----

  FStatStats:=AStream.ReadIdValList;

  FUnknLast:=Check(AStream.ReadDWord,'pre-end',0);

  FStatName :=AStream.ReadShortString; // player name
  FStatClass:=AStream.ReadShortString; // class
  FStatPet  :=AStream.ReadShortString; // Pet class

  AStream.ReadByte; // 0
end;

procedure TTL2Stats.SaveToStream(AStream:TTL2Stream);
var
  lOffs,i:integer;
begin
  if not Changed then
  begin
    if ToStream(AStream) then exit;
  end;

  AStream.WriteDWord(0);
  lOffs:=AStream.Position;

  AStream.WriteDWord(FUnkn);

  AStream.Write(FUnkn17[0],17);

  // ?? mobs
  AStream.WriteDWord(Length(FStatMobs));
  if Length(FStatMobs)>0 then
    AStream.Write(FStatMobs[0],Length(FStatMobs)*40);

  // ?? items
  AStream.WriteDWord(Length(FStatItems));
  if Length(FStatItems)>0 then
    AStream.Write(FStatItems[0],Length(FStatItems)*24);

  // ?? skills
  AStream.WriteDWord(Length(FStatSkills));
  if Length(FStatSkills)>0 then
  AStream.Write(FStatSkills[0],Length(FStatSkills)*17);

  // ??
  AStream.WriteDWord(Length(FStatUnknown));
  if Length(FStatUnknown)>0 then
    AStream.Write(FStatUnknown[0],Length(FStatUnknown)*31);

  //----- ?? Area (teleports? time on map?) -----

  AStream.WriteDWord(Length(FStatArea1));
  for i:=0 to High(FStatArea1) do
  begin
    AStream.WriteShortString(FStatArea1[i].name);
    AStream.WriteDWord      (FStatArea1[i].value);
  end;

  AStream.WriteDWord(Length(FStatArea2));
  for i:=0 to High(FStatArea2) do
  begin
    AStream.WriteShortString(FStatArea2[i].name);
    AStream.WriteDWord      (FStatArea2[i].value);
  end;

  //----- ?? Unknown -----

  AStream.Write(FUnkn9[0],9);

  //----- ?? [Mob] stats -----

  AStream.WriteIdValList(FStatStats);

  AStream.WriteDWord(FUnknLast);

  AStream.WriteShortString(FStatName ); // player name
  AStream.WriteShortString(FStatClass); // class
  AStream.WriteShortString(FStatPet  ); // Pet class

  AStream.WriteByte(0);

  FromStream(AStream,lOffs);
  SetSize   (AStream);
end;


function ReadLastBlock(AStream:TTL2Stream):TTL2Stats;
begin
  result:=TTL2Stats.Create;
  result.LoadFromStream(AStream);
end;

end.
