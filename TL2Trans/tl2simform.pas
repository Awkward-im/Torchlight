unit TL2SimForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TSimilaristForm }

  TSimilaristForm = class(TForm)
    lblTotal: TLabel;
    lblTextLine: TLabel;
    lblTextFile: TLabel;
    lblTextTag: TLabel;
    lblSimLine: TLabel;
    lblSimFile: TLabel;
    lblSimTag: TLabel;
    lbSimilars: TListBox;
    memText: TMemo;
    memSim: TMemo;
    procedure lbSimilarsSelectionChange(Sender: TObject; User: boolean);
  private
    procedure FillDupeList;
    procedure FillList;
    procedure lbDupesSelectionChange(Sender: TObject; User: boolean);

  public
    constructor Create(AOwner:TComponent; Sims:boolean); overload;
  end;


implementation

{$R *.lfm}

uses
  tl2projectform,
  TL2DataUnit;

resourcestring
  sTotal = 'Total';

{ TSimilaristForm }

constructor TSimilaristForm.Create(AOwner:TComponent; Sims:Boolean);
begin
  inherited Create(AOwner);

  Font.Assign((AOwner as TTL2Project).Font);

  if Sims then
  begin
    Caption:='Similarist '+(AOwner as TTL2Project).ProjectName;
    lbSimilars.OnSelectionChange:=@lbSimilarsSelectionChange;
    FillList;
  end
  else
  begin
    Caption:='Duplist '+(AOwner as TTL2Project).ProjectName;
    lbSimilars.OnSelectionChange:=@lbDupesSelectionChange;
    FillDupeList;
  end;
end;

procedure TSimilaristForm.lbSimilarsSelectionChange(Sender: TObject; User: boolean);
var
  i:integer;
begin
  i:=IntPtr(lbSimilars.Items.Objects[lbSimilars.ItemIndex]);
  with (Owner as TTL2Project) do
  begin
    lblTextLine.Caption:=IntToStr(data.FileLine[i]);
    lblTextFile.Caption:=data._File[i];
    lblTextTag .Caption:=data.Attrib[i];
    memText.Text       :=data.Line[i];
    i:=data.SimIndex[i];
    lblSimLine .Caption:=IntToStr(data.FileLine[i]);
    lblSimFile .Caption:=data._File[i];
    lblSimTag  .Caption:=data.Attrib[i];
    memSim.Text        :=data.Line[i];
  end;
end;

procedure TSimilaristForm.lbDupesSelectionChange(Sender: TObject; User: boolean);
{
var
  dub:pDoubleData;
}
begin
  with (Owner as TTL2Project) do
  begin
{
    dub:=data.Double[IntPtr(lbSimilars.Items.Objects[lbSimilars.ItemIndex])];
    lblTextLine.Caption:=IntToStr  (dub^.sLine);
    lblTextFile.Caption:=data._File[dub^.sFile];
    memText.Text       :=data.Line [dub^.sText];
    memSim.Text        :=data.Trans[dub^.sText];
    if dub^.sTag>=0 then
      lblTextTag.Caption:=data.Attrib[dub^.sTag]
    else
      lblTextTag.Caption:='';
}
  end;
end;

procedure TSimilaristForm.FillList;
var
  i:integer;
begin
  lbSimilars.Clear;

  with (Owner as TTL2Project) do
  begin
    i:=(cntBaseLines+cntModLines);
    while i<data.Lines do
    begin
      if data.SimIndex[i]>=0 then
        lbSimilars.AddItem(data.Line[i],TObject(IntPtr(i)));
      inc(i);
    end;

    lblTotal.Caption:=sTotal+': '+IntToStr(lbSimilars.Items.Count);
  end;

  if lbSimilars.Count>0 then
    lbSimilars.ItemIndex:=0;
end;

procedure TSimilaristForm.FillDupeList;
var
  i:integer;
begin
  lbSimilars.Clear;

  with (Owner as TTL2Project) do
  begin
    i:=0;
{
    while i<data.Referals do
    begin
      j:=data.ref.Dupe[i];
      // search line index where ref.dup<-1
      txt:=SearchForRef();
      lbSimilars.AddItem(data.Line[data.Double[i]^.stext],TObject(i));
      inc(i);
    end;
}
    lblTotal.Caption:=sTotal+': '+IntToStr(lbSimilars.Items.Count);
  end;

  if lbSimilars.Items.Count>0 then
    lbSimilars.ItemIndex:=0;
end;

end.

