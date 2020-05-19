unit formPet;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  tl2save, tl2char;

type

  { TfmPet }

  TfmPet = class(TForm)
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
    PetIndex:integer;

    function GetMainPetFlag:boolean;
  public
    procedure FillInfo(aSGame:TTL2SaveFile; idx:integer);

    property IsMainPet:boolean read GetMainPetFlag;
  end;

implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

function TfmPet.GetMainPetFlag:boolean;
begin
  result:=SGame.PetInfo[PetIndex].Sign=$FF;
end;

procedure TfmPet.FillInfo(aSGame:TTL2SaveFile; idx:integer);
var
  lPet:TTL2Character;
  lid:TL2ID;
  i:integer;
begin
  SGame:=aSGame;
  PetIndex:=idx;
  lPet:=aSGame.PetInfo[idx];
  
  cbEnabled.Checked:=lPet.Enabled;

  edName.Text:=lPet.Name;
  if lPet.OriginId<>TL2IdEmpty then
    lid:=lPet.OriginId
  else
    lid:=lPet.ImageId;
  edOriginal.Caption:=GetTL2Pet(lid);

  edLevel      .Text:=IntToStr(lPet.Level);
  edStrength   .Text:=IntToStr(lPet.Strength);
  edDexterity  .Text:=IntToStr(lPet.Dexterity);
  edFocus      .Text:=IntToStr(lPet.Focus);
  edVitality   .Text:=IntToStr(lPet.Vitality);
  edGold       .Text:=IntToStr(lPet.Gold);
  edSkin       .Text:=IntToStr(lPet.Skin);
  edExperience .Text:=IntToStr(lPet.Experience);
  edFame       .Text:=IntToStr(lPet.FameLevel);
  edFameExp    .Text:=IntToStr(lPet.FameExp);
  edHealth     .Text:=FloatToStr(lPet.Health);
  edHealthBonus.Text:=IntToStr(lPet.HealthBonus);
  edMana       .Text:=FloatToStr(lPet.Mana);
  edManaBonus  .Text:=IntToStr(lPet.ManaBonus);
  seScale.Value:=lPet.Scale;
  rbActionIdle   .Checked:=lPet.Action=Idle;
  rbActionAttack .Checked:=lPet.Action=Attack;
  rbActionDefence.Checked:=lPet.Action=Defence;

  lbModList.Clear;
  for i:=0 to High(lPet.ModIds) do
    lbModList.AddItem(GetTL2Mod(lPet.ModIds[i]),nil);
end;
(*
procedure TfmPet.bbUpdateClick(Sender: TObject);
var
  lPet:TTL2Character;
  lid:TL2ID;
  i:integer;
begin
  lPet:=aSGame.PetInfo[PetIndex];
  
  lPet.Enabled:=cbEnabled.Checked;
  lPet.Name:=edName.Text;
{
  if lPet.OriginId<>TL2IdEmpty then
    lid:=lPet.OriginId
  else
    lid:=lPet.ImageId;
  edOriginal.Caption:=GetTL2Pet(lid);
 }
  Val(edLevel      .Text,lPet.Level      ); 
  Val(edStrength   .Text,lPet.Strength   );  
  Val(edDexterity  .Text,lPet.Dexterity  ); 
  Val(edFocus      .Text,lPet.Focus      ); 
  Val(edVitality   .Text,lPet.Vitality   ); 
  Val(edGold       .Text,lPet.Gold       ); 
  Val(edSkin       .Text,lPet.Skin       ); 
  Val(edExperience .Text,lPet.Experience );
  Val(edFame       .Text,lPet.FameLevel  );
  Val(edFameExp    .Text,lPet.FameExp    );
  Val(edHealth     .Text,lPet.Health     );
  Val(edHealthBonus.Text,lPet.HealthBonus);
  Val(edMana       .Text,lPet.Mana       );
  Val(edManaBonus  .Text,lPet.ManaBonus  );
  lPet.Scale:=seScale.Value;

  if      rbActionIdle   .Checked then lPet.Action:=Idle
  else if rbActionAttack .Checked then lPet.Action:=Attack
  else if rbActionDefence.Checked then lPet.Action:=Defence;
{
  lbModList.Clear;
  for i:=0 to High(lPet.ModIds) do
    lbModList.AddItem(GetTL2Mod(lPet.ModIds[i]),nil);
}
end;
*)
end.
