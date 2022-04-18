unit fmComboDiff;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Buttons, ActnList, SynEdit, SynHighlighterT, SynEditMiscClasses,
  SynEditMarkupSpecialLine, Diff, SynEditTypes;

type

  { TCompareForm }

  TCompareForm = class(TForm)
    actCopy: TAction;
    actSave: TAction;
    actRefresh: TAction;
    actCancel: TAction;
    actNext: TAction;
    actPrev: TAction;
    ActionList: TActionList;
    sbPrev: TSpeedButton;
    cbNext: TSpeedButton;
    sbSave: TSpeedButton;
    sbRecomp: TSpeedButton;
    sbCancel: TSpeedButton;
    sbCopyLine: TSpeedButton;
    Splitter: TSplitter;
    seOld: TSynEdit;
    seNew: TSynEdit;
    StatusBar: TStatusBar;
    ToolBar: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    procedure NextClick(Sender: TObject);
    procedure PrevClick(Sender: TObject);
    procedure seOldChange(Sender: TObject);
    procedure seStatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure SESpecialLineMarkup(Sender: TObject; Line: integer;
      var Special: boolean; Markup: TSynSelectedColor);
  private
    SynTSyn: TSynTSyn;
    Diff: TDiff;
    procedure DoCompare(slold, slnew: TStrings);

  public
    constructor Create(const fname:string; anew:PByte); overload;

  end;

var
  CompareForm: TCompareForm;

implementation

{$R *.lfm}

uses
  rgglobal;

{ TCompareForm }

procedure TCompareForm.SESpecialLineMarkup(Sender: TObject; Line: integer;
  var Special: boolean; Markup: TSynSelectedColor);
begin
  with Diff.Compares[Line-1] do
  begin
    if Kind=ckAdd then
    begin
      Special := True ; //marca como línea especial
      Markup.Background := clAqua;
//      seOld.Lines[i]:=slold[oldindex1];
    end;
    if Kind=ckDelete then
    begin
      Special := True ; //marca como línea especial
      Markup.Background := clOlive;
//      seNew.Lines[i]:=slnew[oldindex2];
    end;
    if Kind=ckModify then
    begin
      Special := True ; //marca como línea especial
      Markup.Background := clGray;
    end;
  end;
end;

procedure TCompareForm.seStatusChange(Sender: TObject; Changes: TSynStatusChanges);
begin
  if      Sender=seold then senew.TopLine:=(Sender as TSynEdit).TopLine
  else if Sender=senew then seold.TopLine:=(Sender as TSynEdit).TopLine;
end;

procedure TCompareForm.DoCompare(slold,slnew:TStrings);
var
  hlold,hlnew:Diff.TIntegerList;
  i,ltop:integer;
begin
  {TODO: case insensitive}
  {TODO: skip whitespaces}
  hlold:=TIntegerList.Create;
  hlnew:=TIntegerList.Create;

  hlold.Clear;
  for i:=0 to slold.Count-1 do
    hlold.Add(RGHash(PChar(slold[i])));

  hlnew.Clear;
  for i:=0 to slnew.Count-1 do
    hlnew.Add(RGHash(PChar(slnew[i])));

  Diff.Execute(hlold, hlnew);

  with Diff.DiffStats do
  begin
    StatusBar.Panels[0].Text := ' Matches: ' + inttostr(matches);
    StatusBar.Panels[1].Text := ' Modifies: ' + inttostr(modifies);
    StatusBar.Panels[2].Text := ' Adds: ' + inttostr(adds);
    StatusBar.Panels[3].Text := ' Deletes: ' + inttostr(deletes);
  end;

  seOld.Lines.Clear;
  seNew.Lines.Clear;
  seOld.Lines.Capacity:=Diff.Count;
  seNew.Lines.Capacity:=Diff.Count;

  // Fill editor content
  ltop:=-1;
  for i:=0 to Diff.Count-1 do
  begin
    seOld.Lines.Add('');
    seNew.Lines.Add('');
    with Diff.Compares[i] do
    begin
      if Kind<>ckAdd then
      begin
        seOld.Lines[i]:=slold[oldindex1];
      end;
      if Kind<>ckDelete then
      begin
        seNew.Lines[i]:=slnew[oldindex2];
      end;
      if Kind=ckModify then
      begin
      end;
      if (ltop<0) and (Kind<>ckNone) then
       ltop:=i;
    end;
  end;
  // pos to first difference
  if ltop>=0 then
  begin
    seOld.TopLine:=ltop;
    seNew.TopLine:=ltop;
    seold.CaretY :=ltop;
    senew.CaretY :=ltop;
  end;

  hlold.Free;
  hlnew.Free;

  with Diff.DiffStats do
  begin
    actCopy.Enabled:=(modifies+adds+deletes)>0;
    actNext.Enabled:=(modifies+adds+deletes)>1;
    actPrev.Enabled:=(modifies+adds+deletes)>1;
  end;
end;

procedure TCompareForm.seOldChange(Sender: TObject);
begin
  actSave.Enabled:=seold.Modified;
end;

constructor TCompareForm.Create(const fname:string; anew:PByte);
var
  slold,slnew:TStringList;
  pc:PWideChar;
begin
  Create(nil);

  Diff := TDiff.Create(self);

  SynTSyn:=TSynTSyn.Create(Self);
  seOld.Highlighter:=SynTSyn;
  seNew.Highlighter:=SynTSyn;

  slold:=TStringList.Create;
  slnew:=TStringList.Create;

  slold.LoadFromFile(fname,TEncoding.Unicode);
  pc:=PWideChar(anew);
  if ord(pc^)=$FEFF then inc(pc);
  slnew.Text:=WideToStr(pc);

  DoCompare(slold, slnew);
end;

procedure TCompareForm.PrevClick(Sender: TObject);
var
  row: integer;
  Kind: TChangeKind;
begin
  {TODO: Recompare before if was changed}
//  row:=seold.TopLine;
  row:=seold.CaretY;
  if row=0 then exit;

  Kind:=Diff.Compares[row].Kind;
  while (row>0) and (Diff.Compares[row].Kind=Kind) do dec(row);

  if Diff.Compares[row].Kind=ckNone then
  begin
    Kind:=ckNone;
    while (row>0) and (Diff.Compares[row].Kind=Kind) do dec(row);
  end;

//  If row<seold.TopLine then
  If row<seold.CaretY then
  begin
    seold.CaretY:=row;
    senew.CaretY:=row;
//    seold.TopLine:=row;
//    senew.TopLine:=row;
  end;
  {TODO: actPrev.Enabled:=false if first occur}
end;

procedure TCompareForm.NextClick(Sender: TObject);
var
  row: integer;
  Kind: TChangeKind;
begin
{TODO: Recompare before if was changed}
//  row:=seold.TopLine;
  row:=seold.CaretY;
  if row=(seold.Lines.Count-1) then exit;

  Kind:=Diff.Compares[row].Kind;
  while (row<seold.Lines.Count-1) and
    (Diff.Compares[row].Kind=Kind) do inc(row);

  if Diff.Compares[row].Kind=ckNone then
  begin
    Kind:=ckNone;
    while (row<seold.Lines.Count-1) and
      (Diff.Compares[row].Kind=Kind) do inc(row);
  end;

//  if row>seold.TopLine then
  if row>seold.CaretY then
  begin
    seold.CaretY:=row;
    senew.CaretY:=row;
//    seold.TopLine:=row;
//    senew.TopLine:=row;
  end;
  {TODO: actNext.Enabled:=false if last occur}
end;

end.
