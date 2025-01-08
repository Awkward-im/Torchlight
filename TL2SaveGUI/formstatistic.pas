unit formStatistic;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  tlsave;

type

  { TfmStatistic }

  TfmStatistic = class(TForm)
    bbUpdate: TBitBtn;
    gbStatistic: TGroupBox;

    procedure cbStatChange(Sender: TObject);
    procedure bbUpdateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    StatEdits:array of TEdit;
    SGame:TTLSaveFile;

  public
    procedure FillInfo(aSGame:TTLSaveFile);

  end;


implementation

{$R *.lfm}

{ TfmStatistic }

uses
  tlsgstatistic;


const
  CoordLeft  = 1;
  CoordTop   = 1;
  WidthLabel = 220;
  WidthEdit  = 80;
  Gap        = 6;
  HeightEdit = 21;

procedure TfmStatistic.FormCreate(Sender: TObject);
var
  i:integer;
  lx,ly:integer;
begin

  lx:=CoordLeft;
  ly:=CoordTop;

  SetLength(StatEdits,StatsCountTL2);

  for i:=0 to StatsCountTL2-1 do
  begin
    if i=((StatsCountTL2+1) div 2) then
    begin
      lx:=CoordLeft+WidthLabel+Gap+WidthEdit+16;
      ly:=CoordTop;
    end;

    StatEdits[i]:=TEdit.Create(Self);
    with StatEdits[i] do
    begin
      AutoSize:=false;
      Left       :=lx;
      Top        :=ly;
      Width      :=WidthEdit;
      Height     :=HeightEdit;
      Parent     :=gbStatistic;
      ReadOnly   :=not IsStatEditable(i);
      Enabled    :=IsStatEditable(i);
      NumbersOnly:=IsStatNumeric(i);
      OnChange   :=@cbStatChange;
      Visible    :=True;
    end;
    with TLabel.Create(Self) do
    begin
      AutoSize :=false;
      Left     :=lx+WidthEdit+Gap;
      Top      :=ly;
      Width    :=WidthLabel;
      Height   :=HeightEdit;
      Layout   :=tlCenter;
      Alignment:=taLeftJustify;
      Parent   :=gbStatistic;
      Caption  :=GetStatDescr(i);
      Visible  :=True;
    end;

    inc(ly,HeightEdit+Gap);
  end;

  with gbStatistic do
  begin
    Width :=2*(CoordLeft+WidthLabel+Gap+WidthEdit)+24;
    Height:=2*CoordTop+(HeightEdit+Gap)*(1+(StatsCountTL2+1) div 2);
  end;
  bbUpdate.Top:=gbStatistic.Top+gbStatistic.Height+8;
end;

procedure TfmStatistic.cbStatChange(Sender: TObject);
begin
{
if StatEdits[i].Enabled then
  begin
    SGame.Statistic[i]:=StrToInt(StatEdits[i].Text);
}
  bbUpdate.Enabled:=true;
end;

procedure TfmStatistic.bbUpdateClick(Sender: TObject);
var
  ls:string;
  i:integer;
begin
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;

  for i:=0 to High(StatEdits) do
  begin
    if StatEdits[i].Enabled then
    begin
      SGame.Statistic[i]:=StrToInt(StatEdits[i].Text);
    end;
  end;
  bbUpdate.Enabled:=false;
end;

procedure TfmStatistic.FillInfo(aSGame:TTLSaveFile);
var
  i:integer;
begin
  for i:=0 to High(StatEdits) do
  begin
    StatEdits[i].Text:=GetStatText(i,aSGame.Statistic[i]);
  end;

  SGame:=aSGame;
  bbUpdate.Enabled:=false;
end;

end.
