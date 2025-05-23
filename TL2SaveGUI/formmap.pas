unit formMap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  Buttons, tlsave, tl2map;

type

  { TfmMap }

  TfmMap = class(TForm)
    btnTriggerExport: TButton;
    sgLayouts: TStringGrid;
    lblTotalTime: TLabel;
    lblTTimeValue: TLabel;
    lblCurrentTime: TLabel;
    lblCTimeValue: TLabel;
    lblMapName: TLabel;
    lblName: TLabel;
    lblTriggers: TLabel;  lblTriggerCount: TLabel;
    lblMatrix  : TLabel;  lblMatrixValue : TLabel;
    lblLayouts: TLabel;
    lbUnknList:TListBox;
    sgLayData: TStringGrid;
    procedure btnTriggerExportClick(Sender: TObject);
  private
    FSGame:TTLSaveFile;
    MapIndex:integer;

  public
    procedure FillInfo(aSGame:TTLSaveFile; idx:integer);

  end;

var
  fmMap: TfmMap;

implementation

{$R *.lfm}

uses
  rgdb,
  tlsgcommon,
  tlsgtrigger,
  formSettings;

resourcestring
//  rsSaveUnknown = 'Save Unknown data';
  rsSaveTrigger = 'Save Trigger data';

procedure TfmMap.btnTriggerExportClick(Sender: TObject);
var
  lMap:TTL2Map;
  ldlg:TSaveDialog;
  lstrm:TMemoryStream;
begin
  lMap:=FSGame.Maps[MapIndex];
  ldlg:=TSaveDialog.Create(nil);
  ldlg.Title:=rsSaveTrigger;
  ldlg.FileName:=FSGame.CharInfo.Name+' map_'+IntToStr(MapIndex)+' ('+
      FSGame.Maps[MapIndex].Name+')_trigger';
  ldlg.DefaultExt:='.dmp';
  if ldlg.Execute then
  begin
    if Length(lMap.Triggers)>0 then
    begin
      lstrm:=TMemoryStream.Create;
      try
        lstrm.WriteDWord(Length(lMap.Triggers));
        lstrm.Write(lMap.Triggers[0],Length(lMap.Triggers)*SizeOf(TTL2Trigger));
        lstrm.SaveToFile(ldlg.FileName);
      finally
        lstrm.Free;
      end;
    end;
  end;
  ldlg.Free;
end;

procedure TfmMap.FillInfo(aSGame:TTLSaveFile; idx:integer);
var
  lMap:TTL2Map;
  i:integer;
begin
  FSGame:=aSGame;
  MapIndex:=idx;
  lMap:=aSGame.Maps[idx];

  lblMapName.Caption:=lMap.Name;
  lblTTimeValue.Caption:=MSecToTime(trunc(lMap.Time));
//    IntToStr(trunc(     lMap.Time))+':'+
//    IntToStr(Trunc(Frac(lMap.Time)*60));
  lblCTimeValue.Caption:=MSecToTime(trunc(lMap.CurrentTime));
//    IntToStr(trunc(     lMap.CurrentTime))+':'+
//    IntToStr(Trunc(Frac(lMap.CurrentTime)*60));
  lblTriggerCount.Caption:=IntToStr(Length(lMap.Triggers));
  lblMatrixValue .Caption:=IntToStr(lMap.FoW_X)+' x '+IntToStr(lMap.FoW_Y);

  lbUnknList.Clear;
  for i:=0 to High(lMap.UnknList) do
    lbUnknList.AddItem(TextId(lMap.UnknList[i]),nil);

  sgLayouts.Clear;
  sgLayouts.RowCount:=Length(lMap.LayoutList);
  for i:=0 to High(lMap.LayoutList) do
    sgLayouts.Cells[0,i]:=lMap.LayoutList[i];
  sgLayouts.AutoAdjustColumns;

  sgLayData.Clear;
  sgLayData.RowCount:=1+Length(lMap.LayData);
  for i:=0 to High(lMap.LayData) do
  begin
    sgLayData.Cells[1,i+1]:=TextId  (lMap.LayData[i].id);
    sgLayData.Cells[2,i+1]:=IntToStr(lMap.LayData[i].value);
    sgLayData.Cells[3,i+1]:=TextId  (lMap.LayData[i].unkn);
  end;
end;

end.
