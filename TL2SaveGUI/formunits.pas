unit formUnits;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  tl2save, tl2map;

type

  { TfmUnits }

  TfmUnits = class(TForm)
    btnItems: TButton;
    cbEnabled: TCheckBox;
    cbImage: TComboBox;
    cbSpell1: TComboBox;
    cbSpell2: TComboBox;
    cbSpell3: TComboBox;
    cbSpell4: TComboBox;
    edDexterity: TEdit;
    edExperience: TEdit;
    edFame: TEdit;
    edFameExp: TEdit;
    edFocus: TEdit;
    edGold: TEdit;
    edHealth: TEdit;
    edHealthBonus: TEdit;
    edLevel: TEdit;
    edMana: TEdit;
    edManaBonus: TEdit;
    edMorphTime: TEdit;
    edName: TEdit;
    edOriginal: TEdit;
    edSkin: TEdit;
    edSpell1: TEdit;
    edSpell2: TEdit;
    edSpell3: TEdit;
    edSpell4: TEdit;
    edStrength: TEdit;
    edTownTime: TEdit;
    edVitality: TEdit;
    gbAction: TGroupBox;
    lblDexterity: TLabel;
    lblExperience: TLabel;
    lblFame: TLabel;
    lblFameExp: TLabel;
    lblFocus: TLabel;
    lblGold: TLabel;
    lblHealth: TLabel;
    lblHeathBonus: TLabel;
    lblImage: TLabel;
    lblLevel: TLabel;
    lblMana: TLabel;
    lblManaBonus: TLabel;
    lblMorphTime: TLabel;
    lblScale: TLabel;
    lblSkin: TLabel;
    lblStrength: TLabel;
    lblSuffix: TLabel;
    lblTownTime: TLabel;
    lblVitality: TLabel;
    lbModList: TListBox;
    lbUnitList: TListBox;
    rbActionAttack: TRadioButton;
    rbActionDefence: TRadioButton;
    rbActionIdle: TRadioButton;
    seScale: TFloatSpinEdit;
    procedure lbUnitListSelectionChange(Sender: TObject; User: boolean);
  private
    SGame:TTL2SaveFile;
    FMap:TTL2Map;

  public
    procedure FillInfo(aSGame:TTL2SaveFile; idx:integer);

  end;

var
  fmUnits: TfmUnits;

implementation

{$R *.lfm}

uses
  tl2char,
  tl2types,
  tl2db;

procedure TfmUnits.lbUnitListSelectionChange(Sender: TObject; User: boolean);
var
  lid:TL2ID;
  i,j:integer;
  lunit:TTL2Character;
begin
  for i:=0 to lbUnitList.Count-1 do
    if lbUnitList.Selected[i] then
    begin
      lunit:=FMap.MobInfos[integer(lbUnitList.Items.Objects[i])];

      cbEnabled.Checked:=lunit.Enabled;

      edName.Text:=lunit.Name;
      if lunit.OriginId<>TL2IdEmpty then
        lid:=lunit.OriginId
      else
        lid:=lunit.ImageId;
      edOriginal.Caption:=GetTL2Pet(lid);

      edLevel      .Text:=IntToStr(lunit.Level);
      edStrength   .Text:=IntToStr(lunit.Strength);
      edDexterity  .Text:=IntToStr(lunit.Dexterity);
      edFocus      .Text:=IntToStr(lunit.Focus);
      edVitality   .Text:=IntToStr(lunit.Vitality);
      edGold       .Text:=IntToStr(lunit.Gold);
      edSkin       .Text:=IntToStr(lunit.Skin);
      edExperience .Text:=IntToStr(lunit.Experience);
      edFame       .Text:=IntToStr(lunit.FameLevel);
      edFameExp    .Text:=IntToStr(lunit.FameExp);
      edHealth     .Text:=FloatToStr(lunit.Health);
      edHealthBonus.Text:=IntToStr(lunit.HealthBonus);
      edMana       .Text:=FloatToStr(lunit.Mana);
      edManaBonus  .Text:=IntToStr(lunit.ManaBonus);
      seScale.Value:=lunit.Scale;
      rbActionIdle   .Checked:=lunit.Action=Idle;
      rbActionAttack .Checked:=lunit.Action=Attack;
      rbActionDefence.Checked:=lunit.Action=Defence;

      lbModList.Clear;
      for j:=0 to High(lunit.ModIds) do
        lbModList.AddItem(GetTL2Mod(lunit.ModIds[j]),nil);

      break;
    end;
end;

procedure TfmUnits.FillInfo(aSGame:TTL2SaveFile; idx:integer);
var
  i:integer;
begin
  SGame:=aSGame;
  FMap:=aSGame.Maps[idx];

  lbUnitList.Clear;
  for i:=0 to High(FMap.MobInfos) do
  begin
    lbUnitList.AddItem(FMap.MobInfos[i].Name,TObject(i));
  end;
end;

end.

