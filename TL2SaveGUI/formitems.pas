unit formItems;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, tl2item, tl2char, formItem;

type

  { TfmItems }

  TfmItems = class(TForm)
    lvItemList: TListView;
    pnlItem: TPanel;
    pnlLeft: TPanel;
    Splitter: TSplitter;

    procedure FormCreate(Sender: TObject);
    procedure lvItemListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    FItem:TfmItem;
    FChar:TTL2Character;
    FItems:TTL2ItemList;

  public
    procedure FillInfo(aItems:TTL2ItemList; aChar:TTL2Character=nil);

  end;

implementation

{$R *.lfm}

uses
  formButtons,
  rgglobal,
  tl2db;

const
  imgGold     = 0;
  imgEquipped = 1;
  imgUnknown  = 2;
  imgUsable   = 3;
  imgModded   = 4;

procedure TfmItems.lvItemListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  litem:TTL2Item;
begin
  if Selected then
  begin
    lvItemList.Columns[0].Caption:=IntToStr(Item.Index+1)+' / '+IntToStr(lvItemList.Items.Count);
    litem:=FItems[UIntPtr(Item.Data)];

    FItem.FillInfo(litem,FChar);
    FItem.Visible:=true;

    fmButtons.btnExport.Enabled:=true;
    fmButtons.Ext   :='.itm';
    fmButtons.Name  :='item ['+IntToStr(Item.Index)+'] '+litem.Name;
    fmButtons.SClass:=litem;
  end;
end;

procedure TfmItems.FormCreate(Sender: TObject);
begin
  FItem:=TfmItem.Create(Self);
  FItem.Parent:=pnlItem;
end;

procedure TfmItems.FillInfo(aItems:TTL2ItemList; aChar:TTL2Character=nil);
var
  ls:String;
  litem:TTL2Item;
  i,limg:integer;
begin
  FItems:=aItems;
  FChar :=aChar;

  FItem.Visible:=false;
  fmButtons.btnExport.Enabled:=false;

  lvItemList.Clear;
  lvItemList.Columns[0].Caption:=IntToStr(Length(aItems));
  if Length(aItems)>0 then
  begin
    for i:=0 to High(aItems) do
    begin
      ls:=aItems[i].Name;
      if (ls='') or (ls=' ') then ls:='- empty -';
      lvItemList.AddItem(ls,TObject(IntPtr(i)));
    end;
    // Assign images
    for i:=0 to lvItemList.Items.Count-1 do
    begin
      litem:=FItems[UIntPtr(lvItemList.Items[i].Data)];
      limg:=-1;
      if litem.ID=RGIdEmpty      then limg:=imgGold
      else if litem.Flags[0]     then limg:=imgEquipped
      else if litem.IsUsable     then limg:=imgUsable
      else if not litem.Flags[6] then limg:=imgUnknown
      else if litem.ModIds<>nil  then limg:=imgModded;

if litem.IsProp then limg:=6;

      lvItemList.Items[i].ImageIndex:=limg;
    end;
    lvItemList.SortColumn:=0;
    lvItemList.Sort;
    lvItemList.ItemIndex:=0;
  end;

end;

end.

