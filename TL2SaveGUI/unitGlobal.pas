{
  Global but depending of mods:
char:    Exp/fame levels
char:    HP/MP per stat
char:    Spell list
skill:   Skill tiers
  Class Local: 
char:    HP/MP bonus per level
char:    Stats/skills per level
}
unit unitGlobal;

interface

uses
  rgglobal,
  rgdb;

procedure LoadGameGlobals;
procedure ClearGameGlobals;

var
  ExpGate   :TIntegerDynArray = nil;
  FameGate  :TIntegerDynArray = nil;
  HPperVit  :TIntegerDynArray = nil;
  MPperFocus:TIntegerDynArray = nil;

var
  SpellList:tSkillArray;


implementation

procedure ClearGameGlobals;
begin
  SetLength(ExpGate   ,0);
  SetLength(FameGate  ,0);
  SetLength(HPperVit  ,0);
  SetLength(MPperFocus,0);

  SetLength(SpellList,0);
end;

procedure LoadGameGlobals;
var
  i:integer;
begin
  if Length(ExpGate)=0 then
  begin
    ExpGate:=RGDBGetGraphArray('EXPERIENCEGATE');
    if Length(ExpGate)=0 then
      ExpGate:=Copy(DefaultExpGate);
  end;

  if Length(FameGate)=0 then
  begin
    FameGate:=RGDBGetGraphArray('FAMEGATE');
    if Length(FameGate)=0 then
      FameGate:=Copy(DefaultFameGate);
  end;
  if Length(HPperVit)=0 then
  begin
    HPperVit:=RGDBGetGraphArray('HP_PLAYER_BONUS_VITALITY');
    if Length(HPperVit)=0 then
    begin
      SetLength(HPperVit,1000);
      for i:=0 to 999 do
        HPperVit[i]:=DefaultHPperVit*i;
    end;
  end;
  if Length(MPperFocus)=0 then
  begin
    MPperFocus:=RGDBGetGraphArray('MANA_PLAYER_BONUS_FOCUS');
    if Length(MPperFocus)=0 then
    begin
      SetLength(MPperFocus,1000);
      for i:=0 to 999 do
        MPperFocus[i]:=DefaultMPperFocus*i;
    end;
  end;

  RGDBCreateSpellList(SpellList);
end;

end.
