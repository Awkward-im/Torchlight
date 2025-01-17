unit formItems;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, tlsgitem, tlsgchar, formItem;

type

  { TfmItems }

  TfmItems = class(TForm)
    cbEquipped: TCheckBox;
    lvItemList: TListView;
    pnlItem: TPanel;
    pnlLeft: TPanel;
    Splitter: TSplitter;

    procedure cbEquippedChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvItemListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    FItem:TfmItem;
    FChar:TTLCharacter;
    FItems:TTLItemList;
    procedure FillItemList();

  public
    procedure FillInfo(aItems:TTLItemList; aChar:TTLCharacter=nil);

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
  litem:TTLItem;
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
  FItem.Align :=alClient;
end;

procedure TfmItems.cbEquippedChange(Sender: TObject);
begin
  FillItemList();
end;

procedure TfmItems.FillItemList();
var
  ls:String;
  litem:TTLItem;
  i,limg:integer;
begin
  lvItemList.Clear;
  lvItemList.Columns[0].Caption:=IntToStr(Length(FItems));
  if Length(FItems)>0 then
  begin
    for i:=0 to High(FItems) do
    begin
      if (cbEquipped.Visible) and
         (cbEquipped.Checked) and
         (not FItems[i].Flags[0]) then continue;

      ls:=FItems[i].Name;
      if (ls='') or (ls=' ') then ls:='- empty -';
      lvItemList.AddItem(ls,TObject(IntPtr(i)));
    end;
    // Assign images (separate coz can be sorted already)
    for i:=0 to lvItemList.Items.Count-1 do
    begin
      litem:=FItems[UIntPtr(lvItemList.Items[i].Data)];
      limg:=-1;
      if litem.IsProp then limg:=6
      else
      if litem.ID=RGIdEmpty      then limg:=imgGold
      else if litem.Flags[0]     then limg:=imgEquipped
      else if litem.IsUsable     then limg:=imgUsable
      else if not litem.Flags[6] then limg:=imgUnknown
      else if litem.ModIds<>nil  then limg:=imgModded;

      lvItemList.Items[i].ImageIndex:=limg;
    end;
    lvItemList.SortColumn:=0;
    lvItemList.Sort;
    lvItemList.ItemIndex:=0;
  end;

end;

procedure TfmItems.FillInfo(aItems:TTLItemList; aChar:TTLCharacter=nil);
begin
  FItems:=aItems;
  FChar :=aChar;

  FItem.Visible:=false;
  fmButtons.btnExport.Enabled:=false;

  cbEquipped.Visible:=aChar<>nil;

  FillItemList();
end;

end.

