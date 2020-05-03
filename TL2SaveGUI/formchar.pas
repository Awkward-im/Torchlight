unit formChar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  tl2save, tl2char;

type

  { TfmPet }

  TfmChar = class(TForm)
    cbEnabled : TCheckBox;
    cbImage   : TComboBox;  lblImage: TLabel;
    edOriginal: TEdit;

    cbSpell1: TComboBox;
    cbSpell2: TComboBox;
    cbSpell3: TComboBox;
    cbSpell4: TComboBox;
    edSpell1: TEdit;
    edSpell2: TEdit;
    edSpell3: TEdit;
    edSpell4: TEdit;

    edLevel      : TEdit;  lblLevel     : TLabel;
    edStrength   : TEdit;  lblStrength  : TLabel;
    edDexterity  : TEdit;  lblDexterity : TLabel;
    edFocus      : TEdit;  lblFocus     : TLabel;
    edVitality   : TEdit;  lblVitality  : TLabel;
    edGold       : TEdit;  lblGold      : TLabel;
    edSkin       : TEdit;  lblSkin      : TLabel;
    edExperience : TEdit;  lblExperience: TLabel;
    edFame       : TEdit;  lblFame      : TLabel;
    edFameExp    : TEdit;  lblFameExp   : TLabel;
    edHealth     : TEdit;  lblHealth    : TLabel;
    edHealthBonus: TEdit;  lblHeathBonus: TLabel;
    edMana       : TEdit;  lblMana      : TLabel;
    edManaBonus  : TEdit;  lblManaBonus : TLabel;
    edMorphTime  : TEdit;  lblMorphTime : TLabel;
    edTownTime   : TEdit;  lblTownTime  : TLabel;

    seScale: TFloatSpinEdit;  lblScale: TLabel;

    edName     : TEdit;
    lblSuffix  : TLabel;

    lbModList: TListBox;

    gbAction: TGroupBox;
    rbActionIdle   : TRadioButton;
    rbActionAttack : TRadioButton;
    rbActionDefence: TRadioButton;
  private
    SGame:TTL2SaveFile;

  public
    procedure FillInfo(aSGame:TTL2SaveFile);

  end;

implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

procedure TfmChar.FillInfo(aSGame:TTL2SaveFile);
var
  lChar:TTL2Character;
  lid:TL2ID;
  i:integer;
begin
  SGame:=aSGame;
  lChar:=aSGame.CharInfo;
  
  cbEnabled.Checked:=lChar.Enabled;

  edName.Text:=lChar.Name;
  if lChar.OriginId<>TL2IdEmpty then
    lid:=lChar.OriginId
  else
    lid:=lChar.ImageId;
  edOriginal.Caption:=GetTL2Class(lid);

  edLevel      .Text:=IntToStr(lChar.Level);
  edStrength   .Text:=IntToStr(lChar.Strength);
  edDexterity  .Text:=IntToStr(lChar.Dexterity);
  edFocus      .Text:=IntToStr(lChar.Focus);
  edVitality   .Text:=IntToStr(lChar.Vitality);
  edGold       .Text:=IntToStr(lChar.Gold);
  edSkin       .Text:=IntToStr(lChar.Skin);
  edExperience .Text:=IntToStr(lChar.Experience);
  edFame       .Text:=IntToStr(lChar.FameLevel);
  edFameExp    .Text:=IntToStr(lChar.FameExp);
  edHealth     .Text:=FloatToStr(lChar.Health);
  edHealthBonus.Text:=IntToStr(lChar.HealthBonus);
  edMana       .Text:=FloatToStr(lChar.Mana);
  edManaBonus  .Text:=IntToStr(lChar.ManaBonus);
  seScale.Value:=lChar.Scale;
  rbActionIdle   .Checked:=lChar.Action=Idle;
  rbActionAttack .Checked:=lChar.Action=Attack;
  rbActionDefence.Checked:=lChar.Action=Defence;

  lbModList.Clear;
  for i:=0 to High(lChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(lChar.ModIds[i]),nil);
end;

end.
