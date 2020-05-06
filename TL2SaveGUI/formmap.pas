unit formMap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  tl2save, tl2map;

type

  { TfmMap }

  TfmMap = class(TForm)
    lblMapName: TLabel;
    lblName: TLabel;
    lblUnknown : TLabel;  lblUnknownCount: TLabel;
    lblTriggers: TLabel;  lblTriggerCount: TLabel;
    lblMatrix  : TLabel;  lblMatrixValue : TLabel;
    lblLayouts: TLabel;
    lbLayouts: TListBox;
    lbUnknList:TListBox;
    sgLayData: TStringGrid;
  private
    SGame:TTL2SaveFile;
    MapIndex:integer;

  public
    procedure FillInfo(aSGame:TTL2SaveFile; idx:integer);

  end;

var
  fmMap: TfmMap;

implementation

{$R *.lfm}

uses
  tl2db,
  tl2types;

procedure TfmMap.FillInfo(aSGame:TTL2SaveFile; idx:integer);
var
  lMap:TTL2Map;
  lid:TL2ID;
  i:integer;
begin
  SGame:=aSGame;
  MapIndex:=idx;
  lMap:=aSGame.Maps[idx];

  lblMapName.Caption:=lMap.Name;
  lblTriggerCount.Caption:=IntToStr(Length(lMap.Triggers));
  lblUnknownCount.Caption:=IntToStr(Length(lMap.Unknown));
  lblMatrixValue .Caption:=IntToStr(lMap.FoW_X)+' x '+IntToStr(lMap.FoW_Y);

  lbUnknList.Clear;
  for i:=0 to High(lMap.UnknList) do
    lbUnknList.AddItem('0x'+IntToHex(lMap.UnknList[i],16),nil);

  lbLayouts.Clear;
  for i:=0 to High(lMap.LayoutList) do
    lbLayouts.AddItem(lMap.LayoutList[i],nil);

  sgLayData.Clear;
  sgLayData.RowCount:=1+Length(lMap.LayData);
  for i:=0 to High(lMap.LayData) do
  begin
    sgLayData.Cells[0,i+1]:='0x'+IntToHex(lMap.LayData[i].id,16);
    sgLayData.Cells[1,i+1]:=IntToStr(lMap.LayData[i].value);
    sgLayData.Cells[2,i+1]:='0x'+IntToHex(lMap.LayData[i].unkn,16);
  end;
end;

end.

