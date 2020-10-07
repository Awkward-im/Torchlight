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
    lblTextFile.Caption:=data._File [i];
    lblTextTag .Caption:=data.Attrib[i];
    memText.Text       :=data.Line  [i];
    i:=data.SimIndex[i];
    lblSimLine .Caption:=IntToStr(data.FileLine[i]);
    lblSimFile .Caption:=data._File [i];
    lblSimTag  .Caption:=data.Attrib[i];
    memSim.Text        :=data.Line  [i];
  end;
end;

procedure TSimilaristForm.lbDupesSelectionChange(Sender: TObject; User: boolean);
var
  lridx,i:integer;
begin
  with (Owner as TTL2Project) do
  begin
    lridx:=IntPtr(lbSimilars.Items.Objects[lbSimilars.ItemIndex]);
    lblTextLine.Caption:=IntToStr(data.ref.GetLine(lridx));
    lblTextFile.Caption:=data.ref.GetFile(lridx);
    lblTextTag .Caption:=data.ref.GetTag (lridx);
    lridx:=data.ref.Dupe[lridx]-1;
    lblSimLine .Caption:=IntToStr(data.ref.GetLine(lridx));
    lblSimFile .Caption:=data.ref.GetFile(lridx);
    lblSimTag  .Caption:=data.ref.GetTag (lridx);

    memText.Text:='';
    memSim .Text:='';
    for i:=0 to data.Lines-1 do
    begin
      if lridx=data.refs[i] then
      begin
        memText.Text:=data.Line [i];
        memSim .Text:=data.Trans[i];
        break;
      end;
    end;
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
  i,j:integer;
begin
  lbSimilars.Clear;

  with (Owner as TTL2Project) do
  begin
    i:=0;
    while i<data.Referals do
    begin
      j:=data.ref.Dupe[i];
      // search line index where ref.dup<-1
      // =0 = dupe in preloads
      // >0 = ref # +1
      // <0 - base, count of doubles
//      txt:=SearchForRef();
      if j>0 then
        lbSimilars.AddItem(data.ref.GetFile(i),TObject(IntPtr(i)));
      inc(i);
    end;
    lblTotal.Caption:=sTotal+': '+IntToStr(lbSimilars.Items.Count);
  end;

  if lbSimilars.Items.Count>0 then
    lbSimilars.ItemIndex:=0;
end;

end.

