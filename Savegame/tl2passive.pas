unit TL2Passive;

interface


uses
  classes,
  tl2stream,
  tl2common;

{
type
  TTL2Passive = record
    flags:dword;
    name :string;
    data :PByte;
  end;
  TTL2PassiveList = array of TTL2Passive;
}
type
  TTL2Passive = class;
  TTL2PassiveList = array of TTL2Passive;
type
  TTL2Passive = class
  private
    FFlags:dword;
    FName :string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

  end;


function ReadPassiveList(AStream:TTL2Stream):TTL2PassiveList;


implementation


constructor TTL2Passive.Create;
begin
  inherited;

end;

destructor TTL2Passive.Destroy;
begin

  inherited;
end;

procedure TTL2Passive.LoadFromStream(AStream: TTL2Stream);
var
  lcnt:integer;
  lsize:cardinal;
begin
  FFlags:=AStream.ReadDWord;         // flags
  FName :=AStream.ReadShortString(); // name
  //!!!!
  AStream.Seek(lsize,soCurrent);
end;

procedure TTL2Passive.SaveToStream(AStream: TTL2Stream);
begin
end;

function ReadPassiveList(AStream:TTL2Stream):TTL2PassiveList;
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
      result[i]:=TTL2Passive.Create;
      result[i].LoadFromStream(AStream);
    end;
  end;
end;

end.
