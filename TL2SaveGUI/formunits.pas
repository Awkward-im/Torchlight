unit formUnits;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, tl2save, tl2map, formChar;

type

  { TfmUnits }

  TfmUnits = class(TForm)
    lblCount: TLabel;
    lbUnitList: TListBox;
    pnlLeftTop: TPanel;
    pnlLeft: TPanel;
    pnlCharInfo: TPanel;
    Splitter: TSplitter;

    procedure FormCreate(Sender: TObject);
    procedure lbUnitListSelectionChange(Sender: TObject; User: boolean);
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

procedure TfmUnits.lbUnitListSelectionChange(Sender: TObject; User: boolean);
var
  lunit:TTL2Character;
  i:integer;
begin
  FChar.Visible:=false;
  for i:=0 to lbUnitList.Count-1 do
    if lbUnitList.Selected[i] then
    begin
      lblCount.Caption:=IntToStr(i+1)+' / '+IntToStr(lbUnitList.Count);
      lunit:=FMap.MobInfos[IntPtr(lbUnitList.Items.Objects[i])];

      fmButtons.btnExport.Enabled:=true;
      fmButtons.Name  :='unit '+IntToStr(i);
      fmButtons.SClass:=lunit;

      FChar.FillInfo(lunit);
      FChar.Visible:=true;

      break;
    end;
end;

procedure TfmUnits.FormCreate(Sender: TObject);
begin
  FChar:=TfmChar.Create(Self);
  FChar.Parent:=pnlCharInfo;
end;

procedure TfmUnits.FillInfo(aSGame:TTL2SaveFile; idx:integer);
var
  i:integer;
begin
  SGame:=aSGame;
  FMap:=aSGame.Maps[idx];
  FChar.Visible:=false;

  lblCount.Caption:=IntToStr(Length(FMap.MobInfos));
  lbUnitList.Clear;
  if Length(FMap.MobInfos)>0 then
  begin
    lbUnitList.Sorted:=false;
    for i:=0 to High(FMap.MobInfos) do
    begin
      lbUnitList.AddItem(FMap.MobInfos[i].Name,TObject(IntPtr(i)));
    end;
    lbUnitList.Sorted:=true;
    lbUnitList.ItemIndex:=0;
  end;

  fmButtons.btnExport.Enabled:=false;
  fmButtons.Ext:='.chr';
end;

end.

