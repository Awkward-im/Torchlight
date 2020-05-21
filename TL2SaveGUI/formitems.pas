unit formItems;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  tl2item, formItem;

type

  { TfmItems }

  TfmItems = class(TForm)
    lblCount: TLabel;
    lbItemList: TListBox;
    pnlLeftTop: TPanel;
    pnlItem: TPanel;
    pnlLeft: TPanel;
    Splitter: TSplitter;

    procedure FormCreate(Sender: TObject);
    procedure lbItemListSelectionChange(Sender: TObject; User: boolean);
  private
    FItem:TfmItem;
    FItems:TTL2ItemList;

  public
    procedure FillInfo(aItems:TTL2ItemList);

  end;

implementation

{$R *.lfm}

uses
  formButtons,
  tl2db;

procedure TfmItems.lbItemListSelectionChange(Sender: TObject; User: boolean);
var
  litem:TTL2Item;
  i:integer;
begin
  FItem.Visible:=false;

  for i:=0 to lbItemList.Count-1 do
    if lbItemList.Selected[i] then
    begin
      lblCount.Caption:=IntToStr(i+1)+' / '+IntToStr(lbItemList.Count);
      litem:=FItems[integer(lbItemList.Items.Objects[i])];

      fmButtons.btnExport.Enabled:=true;
      fmButtons.Name  :='item '+IntToStr(i);
      fmButtons.SClass:=litem;

      FItem.FillInfo(litem);
      FItem.Visible:=true;

      break;
    end;
end;

procedure TfmItems.FormCreate(Sender: TObject);
begin
  FItem:=TfmItem.Create(Self);
  FItem.Parent:=pnlItem;
end;

procedure TfmItems.FillInfo(aItems:TTL2ItemList);
var
  ls:String;
  i:integer;
begin
  FItems:=aItems;
  FItem.Visible:=false;

  lblCount.Caption:=IntToStr(Length(aItems));
  lbitemList.Clear;
  if Length(aItems)>0 then
  begin
    lbitemList.Sorted:=false;
    for i:=0 to High(aItems) do
    begin
      ls:=aItems[i].Name;
      if (ls='') or (ls=' ') then ls:='- empty -';
      lbItemList.AddItem(ls,TObject(i));
    end;
    lbitemList.Sorted:=true;
    lbItemList.ItemIndex:=0;
  end;

  fmButtons.btnExport.Enabled:=false;
  fmButtons.Ext:='.itm';
end;

end.

