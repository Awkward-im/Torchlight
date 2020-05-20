unit formItems;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  tl2item;

type

  { TfmItems }

  TfmItems = class(TForm)
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

    lbModList: TListBox;

    lbItemList: TListBox;
    pnlLeft: TPanel;
    pnlItem: TPanel;
    Splitter: TSplitter;

    procedure lbItemListSelectionChange(Sender: TObject; User: boolean);
  private
    FItems:TTL2ItemList;

    procedure FillInfoInt(aItem:TTL2Item);
  public
    procedure FillInfo(aItems:TTL2ItemList);

  end;

implementation

{$R *.lfm}

uses
  formButtons,
  tl2db;

procedure TfmItems.FillInfoInt(aItem:TTL2Item);
begin
  edName    .Text := aItem.Name;
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
end;

procedure TfmItems.lbItemListSelectionChange(Sender: TObject; User: boolean);
var
  litem:TTL2Item;
  i:integer;
begin
  for i:=0 to lbItemList.Count-1 do
    if lbItemList.Selected[i] then
    begin
      litem:=FItems[integer(lbItemList.Items.Objects[i])];

      fmButtons.btnExport.Enabled:=true;
      fmButtons.Name  :='item '+IntToStr(i);
      fmButtons.SClass:=litem;

      FillInfoInt(litem);

      break;
    end;
end;

procedure TfmItems.FillInfo(aItems:TTL2ItemList);
var
  ls:String;
  i:integer;
begin
  FItems:=aItems;

  lbitemList.Clear;

  for i:=0 to High(aItems) do
  begin
    ls:=aItems[i].Name;
    if (ls='') or (ls=' ') then ls:='- empty -';
    lbItemList.AddItem(ls,TObject(i));
  end;

  fmButtons.btnExport.Enabled:=false;
  fmButtons.Ext:='.itm';
end;

end.

