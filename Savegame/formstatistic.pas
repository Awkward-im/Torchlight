unit formStatistic;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  tl2save;

type

  { TfmStatistic }

  TfmStatistic = class(TForm)
    bbUpdate: TBitBtn;
    gbStatistic: TGroupBox;

    procedure bbUpdateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    StatEdits:array of TEdit;
    sg:TTL2SaveFile;

  public
    procedure FillStatistic(asg:TTL2SaveFile);

  end;

var
  fmStatistic: TfmStatistic;

implementation

{$R *.lfm}

{ TfmStatistic }

uses
  tl2statistic;


const
  CoordLeft  = 1;
  CoordTop   = 1;
  WidthLabel = 200;
  WidthEdit  = 90;
  Gap        = 4;
  HeightEdit = 21;

procedure TfmStatistic.FormCreate(Sender: TObject);
var
  i:integer;
  lx,ly:integer;
begin

  lx:=CoordLeft;
  ly:=CoordTop;

  SetLength(StatEdits,StatsCount);

  for i:=0 to StatsCount-1 do
  begin
    if i=((StatsCount+1) div 2) then
    begin
      lx:=CoordLeft+WidthLabel+Gap+WidthEdit+16;
      ly:=CoordTop;
    end;

    with TLabel.Create(Self) do
    begin
      AutoSize :=false;
      Left     :=lx;
      Top      :=ly;
      Width    :=WidthLabel;
      Height   :=HeightEdit;
      Layout   :=tlCenter;
      Alignment:=taRightJustify;
      Parent   :=gbStatistic;
      Caption  :=GetStatDescr(i);
      Visible  :=True;
    end;
    StatEdits[i]:=TEdit.Create(Self);
    with StatEdits[i] do
    begin
      AutoSize:=false;
      Left       :=lx+WidthLabel+Gap;
      Top        :=ly;
      Width      :=WidthEdit;
      Height     :=HeightEdit;
      Parent     :=gbStatistic;
      ReadOnly   :=not IsStatEditable(i);
      Enabled    :=IsStatEditable(i);
      NumbersOnly:=IsStatNumeric(i);
      Visible    :=True;
    end;

    inc(ly,HeightEdit+Gap);
  end;

  with gbStatistic do
  begin
    Width :=2*(CoordLeft+WidthLabel+Gap+WidthEdit)+24;
    Height:=2*CoordTop+(HeightEdit+Gap)*(1+(StatsCount+1) div 2);
  end;
  bbUpdate.Top:=gbStatistic.Top+gbStatistic.Height+8;
end;

procedure TfmStatistic.bbUpdateClick(Sender: TObject);
var
  i:integer;
begin
  for i:=0 to High(StatEdits) do
  begin
    if StatEdits[i].Enabled then
    begin
      sg.Statistic[i]:=StrToInt(StatEdits[i].Text);
    end;
  end;
end;

procedure TfmStatistic.FillStatistic(asg:TTL2SaveFile);
var
  i:integer;
begin
  for i:=0 to High(StatEdits) do
  begin
    StatEdits[i].Text:=GetStatText(i,asg.Statistic[i]);
  end;
  sg:=asg;
end;

end.
