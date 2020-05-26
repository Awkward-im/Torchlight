unit formItem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, tl2item;

type

  { TfmItem }

  TfmItem = class(TForm)
    edName  : TEdit;  lblName  : TLabel;  edNameById: TEdit;
    edPrefix: TEdit;  lblPrefix: TLabel;
    edSuffix: TEdit;  lblSuffix: TLabel;

    edLevel   : TEdit;  lblLevel   : TLabel;
    edStack   : TEdit;  lblStack   : TLabel;
    edEnchant : TEdit;  lblEnchant : TLabel;
    edPosition: TEdit;  lblPosition: TLabel;  lblPosType: TLabel;
    edSockets : TEdit;  lblSockets : TLabel;

    edWeaponDmg: TEdit;  lblWeaponDmg: TLabel;
    edArmor    : TEdit;  lblArmor    : TLabel;
    edArmorType: TEdit;  lblArmorType: TLabel;  lblArmorByType: TLabel;

    lbModList : TListBox;
    lbAugments: TListBox;  lblAugments: TLabel;
    sgEffects : TStringGrid;

  private
    FItem:TTL2Item;

  public
    procedure FillInfo(aItem:TTL2Item);

  end;

implementation

{$R *.lfm}

uses
  tl2db;

procedure TfmItem.FillInfo(aItem:TTL2Item);
var
  i,j:integer;
begin
  FItem:=aItem;
  
  edName    .Text := aItem.Name;
  if aItem.IsProp then
    edNameById.Text := GetTL2Prop(aItem.ID)
  else
    edNameById.Text := GetTL2Item(aItem.ID);
  edPrefix  .Text := aItem.Prefix;
  edSuffix  .Text := aItem.Suffix;

  edLevel   .Text    := IntToStr(aItem.Level);
  edStack   .Text    := IntToStr(aItem.Stack);
  edEnchant .Text    := IntToStr(aItem.EnchantCount);
  edPosition.Text    := IntToStr(aItem.Position);
  lblPosType.Caption := ''; //!!
  edSockets.Text     := IntToStr(aItem.SocketCount);

  edWeaponDmg   .Text   := IntToStr(aItem.WeaponDamage);
  edArmor       .Text   := IntToStr(aItem.Armor);
  edArmorType   .Text   := IntToStr(aItem.ArmorType);
  lblArmorByType.Caption:= ''; //!!

  lbAugments.Clear;
  for i:=0 to High(aItem.Augments) do
    lbAugments.AddItem(aItem.Augments[i],nil);

  sgEffects.BeginUpdate;
  sgEffects.Clear;
  sgEffects.RowCount:=1+Length(aItem.Effects1)+Length(aItem.Effects2)+Length(aItem.Effects3);
  j:=1;
  for i:=0 to High(aItem.Effects1) do
  begin
    sgEffects.Objects[0,j]:=TObject(i);
    sgEffects.Cells[0,j]:='1';
    sgEffects.Cells[1,j]:=IntToStr(aItem.Effects1[i].EffectType);
    sgEffects.Cells[2,j]:=aItem.Effects1[i].Name;
    inc(j);
  end;
  for i:=0 to High(aItem.Effects2) do
  begin
    sgEffects.Objects[0,j]:=TObject(i);
    sgEffects.Cells[0,j]:='2';
    sgEffects.Cells[1,j]:=IntToStr(aItem.Effects2[i].EffectType);
    sgEffects.Cells[2,j]:=aItem.Effects2[i].Name;
    inc(j);
  end;
  for i:=0 to High(aItem.Effects3) do
  begin
    sgEffects.Objects[0,j]:=TObject(i);
    sgEffects.Cells[0,j]:='3';
    sgEffects.Cells[1,j]:=IntToStr(aItem.Effects3[i].EffectType);
    sgEffects.Cells[2,j]:=aItem.Effects3[i].Name;
    inc(j);
  end;
  sgEffects.EndUpdate;

  lbModList.Clear;
  for i:=0 to High(aItem.ModIds) do
    lbModList.AddItem(GetTL2Mod(aItem.ModIds[i]),nil);
end;

end.

