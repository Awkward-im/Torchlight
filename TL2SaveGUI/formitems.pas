{TODO: make different icons for activated and not activated props}
unit formItems;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, ListViewFilterEdit, tlsgitem, tlsgchar, formItem;

type

  { TfmItems }

  TfmItems = class(TForm)
    cbEquipped: TCheckBox;
    lvfeItemList: TListViewFilterEdit;
    lvItemList: TListView;
    pnlItem: TPanel;
    pnlLeft: TPanel;
    Splitter: TSplitter;

    procedure cbEquippedChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvfeItemListAfterFilter(Sender: TObject);
    procedure lvItemListChange    (Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure lvItemListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    FItem:TfmItem;
    FChar:TTLCharacter;
    FItems:TTLItemList;
    procedure FillItemList();
    function GetItemIcon(idx: integer): integer;

  public
    procedure FillInfo(aItems:TTLItemList; aChar:TTLCharacter=nil);

  end;

implementation

{$R *.lfm}

uses
  formButtons,
  rgglobal;

const
  imgGold         = 0;
  imgEquipped     = 1;
  imgUnrecognized = 2;
  imgUsable       = 3;
  imgModded       = 4;
  imgUnknown      = 6;

procedure TfmItems.lvItemListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  litem:TTLItem;
begin
  if Selected then
  begin
    lvItemList.Columns[0].Caption:=IntToStr(Item.Index+1)+' / '+
       IntToStr(lvItemList.Items.Count)+' ['+IntToStr(Length(FItems))+']';

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

procedure TfmItems.lvfeItemListAfterFilter(Sender: TObject);
var
  lcnt:integer;
begin
  if lvItemList.Items.Count>0 then
  begin
    lvItemList.ItemIndex:=0;
    lcnt:=1;
  end
  else
    lcnt:=0;

  lvItemList.Columns[0].Caption:=IntToStr(lcnt)+' / '+
     IntToStr(lvItemList.Items.Count)+' ['+IntToStr(Length(FItems))+']';
end;

procedure TfmItems.cbEquippedChange(Sender: TObject);
begin
  FillItemList();
end;

function TfmItems.GetItemIcon(idx:integer):integer;
var
  litem:TTLItem;
begin
  litem:=FItems[idx];
  if      litem.IsProp       then result:=imgUnknown
  else if litem.ID=RGIdEmpty then result:=imgGold
  else if litem.Flags[0]     then result:=imgEquipped
  else if litem.IsUsable     then result:=imgUsable
  else if not litem.Flags[6] then result:=imgUnrecognized
  else if litem.ModIds<>nil  then result:=imgModded
  else                            result:=-1;
end;

procedure TfmItems.lvItemListChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if Change=ctText then
  begin
    Item.ImageIndex:=GetItemIcon(UIntPtr(Item.Data));
  end;
end;

procedure TfmItems.FillItemList();
var
  ls:String;
  i:integer;
begin
  lvfeItemList.FilteredListView:=nil;
  lvItemList.Clear;
  lvfeItemList.Items.Clear;
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
      lvItemList.Items[i].ImageIndex:=GetItemIcon(UIntPtr(lvItemList.Items[i].Data));
    end;
    lvItemList.SortColumn:=0;
    lvItemList.Sort;

    if lvItemList.Items.Count>0 then
      lvItemList.ItemIndex:=0;
  end;

  lvfeItemList.FilteredListView:=lvItemList;
  lvfeItemList.SortData:=true;
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

