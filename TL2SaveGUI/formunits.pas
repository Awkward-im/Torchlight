unit formUnits;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, tl2save, tl2map, formChar;

type

  { TfmUnits }

  TfmUnits = class(TForm)
    lvUnitList: TListView;
    pnlLeft: TPanel;
    pnlCharInfo: TPanel;
    Splitter: TSplitter;

    procedure FormCreate(Sender: TObject);
    procedure lvUnitListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    FChar:TfmChar;
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
  formButtons,
  tl2char,
  tl2db;

const
  imgModded = 4;
  imgDead   = 7;

procedure TfmUnits.lvUnitListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  lunit:TTL2Character;
begin
  if Selected then
  begin
    lvUnitList.Columns[0].Caption:=IntToStr(Item.Index+1)+' / '+IntToStr(lvUnitList.Items.Count);
    lunit:=FMap.MobInfos[UIntPtr(Item.Data)];

    FChar.FillInfo(lunit);
    FChar.Visible:=true;

    fmButtons.btnExport.Enabled:=true;
    fmButtons.Name  :='unit ['+IntToStr(Item.Index)+'] '+lunit.Name;
    fmButtons.SClass:=lunit;
  end;
end;

procedure TfmUnits.FormCreate(Sender: TObject);
begin
  FChar:=TfmChar.Create(Self,ciUnit);
  FChar.Parent:=pnlCharInfo;
end;

procedure TfmUnits.FillInfo(aSGame:TTL2SaveFile; idx:integer);
var
  ls:string;
  lunit:TTL2Character;
  i,limg:integer;
begin
  SGame:=aSGame;
  FMap:=aSGame.Maps[idx];
  FChar.Visible:=false;

  fmButtons.btnExport.Enabled:=false;
  fmButtons.Ext:='.chr';
  lvUnitList.Clear;
  lvUnitList.Columns[0].Caption:=IntToStr(Length(FMap.MobInfos));
  if Length(FMap.MobInfos)>0 then
  begin
    for i:=0 to High(FMap.MobInfos) do
    begin
      if not FMap.MobInfos[i].Hidden then ls:='' else ls:='[*] ';
      lvUnitList.AddItem(ls+FMap.MobInfos[i].Name,TObject(IntPtr(i)));
    end;
    // Assign images
    for i:=0 to lvUnitList.Items.Count-1 do
    begin
      lunit:=FMap.MobInfos[UIntPtr(lvUnitList.Items[i].Data)];

      limg:=-1;
      if      lunit.Health=0    then limg:=imgDead
      else if lunit.ModIds<>nil then limg:=imgModded;

      lvUnitList.Items[i].ImageIndex:=limg;
    end;
    lvUnitList.SortColumn:=0;
    lvUnitList.Sort;
    lvUnitList.ItemIndex:=0;
  end;
end;

end.
