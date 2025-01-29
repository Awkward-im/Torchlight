unit formUnits;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, ListViewFilterEdit, tlsave, tl2map, formChar;

type

  { TfmUnits }

  TfmUnits = class(TForm)
    lvfeUnitList: TListViewFilterEdit;
    lvUnitList: TListView;
    pnlLeft: TPanel;
    pnlCharInfo: TPanel;
    Splitter: TSplitter;

    procedure FormCreate(Sender: TObject);
    procedure lvfeUnitListAfterFilter(Sender: TObject);
    procedure lvUnitListChange    (Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure lvUnitListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    FChar:TfmChar;
    SGame:TTLSaveFile;
    FMap:TTL2Map;
    function GetItemIcon(idx: integer): integer;

  public
    procedure FillInfo(aSGame:TTLSaveFile; idx:integer);

  end;

var
  fmUnits: TfmUnits;

implementation

{$R *.lfm}

uses
  formButtons,
  tlsgchar,
  rgdb;

const
  imgModded  = 4;
  imgUnknown = 6;
  imgDead    = 7;

procedure TfmUnits.lvUnitListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  lunit:TTLCharacter;
begin
  if Selected then
  begin
    lvUnitList.Columns[0].Caption:=IntToStr(Item.Index+1)+' / '+
       IntToStr(lvUnitList.Items.Count)+' ['+IntToStr(Length(FMap.MobInfos))+']';
    lunit:=FMap.MobInfos[UIntPtr(Item.Data)];

    FChar.FillInfo(lunit);
    FChar.Visible:=true;

    fmButtons.btnExport.Enabled:=true;
    fmButtons.Ext   :='.chr';
    fmButtons.Name  :='unit ['+IntToStr(Item.Index)+'] '+lunit.Name;
    fmButtons.SClass:=lunit;
  end;
end;

procedure TfmUnits.FormCreate(Sender: TObject);
begin
  FChar:=TfmChar.Create(Self,ciUnit);
  FChar.Parent:=pnlCharInfo;
  FChar.Align :=alClient;
end;

procedure TfmUnits.lvfeUnitListAfterFilter(Sender: TObject);
var
  lcnt:integer;
begin
  if lvUnitList.Items.Count>0 then
  begin
    lvUnitList.ItemIndex:=0;
    lcnt:=1;
  end
  else
    lcnt:=0;

  lvUnitList.Columns[0].Caption:=IntToStr(lcnt)+' / '+
     IntToStr(lvUnitList.Items.Count)+' ['+IntToStr(Length(FMap.MobInfos))+']';
end;

function TfmUnits.GetItemIcon(idx:integer):integer;
begin
  with FMap.MobInfos[idx] do
  begin
    if      Health=0    then result:=imgDead
    else if ModIds<>nil then result:=imgModded
    else if Hidden      then result:=imgUnknown
    else                     result:=-1;
  end;
end;

procedure TfmUnits.lvUnitListChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if Change=ctText then
  begin
    Item.ImageIndex:=GetItemIcon(UIntPtr(Item.Data));
  end;
end;

procedure TfmUnits.FillInfo(aSGame:TTLSaveFile; idx:integer);
var
  i:integer;
begin
  SGame:=aSGame;
  FMap:=aSGame.Maps[idx];

  FChar.Visible:=false;
  fmButtons.btnExport.Enabled:=false;

  lvfeUnitList.FilteredListView:=nil;

  lvUnitList.Clear;
  lvfeUnitList.Items.Clear;
  if Length(FMap.MobInfos)>0 then
  begin
    for i:=0 to High(FMap.MobInfos) do
    begin
      lvUnitList.AddItem(FMap.MobInfos[i].Name,TObject(IntPtr(i)));
    end;
    // Assign images (for case when already sorted after filling
    for i:=0 to lvUnitList.Items.Count-1 do
    begin
      lvUnitList.Items[i].ImageIndex:=GetItemIcon(UIntPtr(lvUnitList.Items[i].Data))
    end;
    lvUnitList.Sort;
    lvUnitList.ItemIndex:=0;
  end;

  lvfeUnitList.FilteredListView:=lvUnitList;
  lvfeUnitList.SortData:=true;
end;

end.
