unit fmComboDiff;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Buttons, ActnList, SynEdit, SynHighlighterT, SynEditMiscClasses,
  {SynEditMarkupSpecialLine, }Diff, SynEditTypes;

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
    procedure actCancelExecute(Sender: TObject);
    procedure actCopyClick(Sender: TObject);
    procedure actNextClick(Sender: TObject);
    procedure actPrevClick(Sender: TObject);
    procedure actRefreshExecute(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure seOldChange(Sender: TObject);
    procedure seStatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure SESpecialLineMarkup(Sender: TObject; Line: integer;
      var Special: boolean; Markup: TSynSelectedColor);
  private
    SynTSyn: TSynTSyn;
    Diff: TDiff;
    srcfile:string;

    procedure DoCompare(slold, slnew: TStrings);
    procedure GetPureText(se:TSynEdit; out sl:TStrings);

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
      Markup.Background := $FFAAAA;
//      seOld.Lines[i]:=slold[oldindex1];
    end;
    if Kind=ckDelete then
    begin
      Special := True ; //marca como línea especial
      Markup.Background := $AAAAFF;
//      seNew.Lines[i]:=slnew[oldindex2];
    end;
    if Kind=ckModify then
    begin
      Special := True ; //marca como línea especial
      Markup.Background := $AAFFAA;
      Markup.Foreground := $000000;
    end;
  end;
end;

procedure TCompareForm.seStatusChange(Sender: TObject; Changes: TSynStatusChanges);
begin
  if TSynStatusChange.scTopLine in Changes then
  begin
    if      Sender=seold then senew.TopLine:=(Sender as TSynEdit).TopLine
    else if Sender=senew then seold.TopLine:=(Sender as TSynEdit).TopLine;
  end;
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

  hlold.Count:=slold.Count;
  for i:=0 to slold.Count-1 do
    hlold.Items[i]:=RGHashB(PChar(slold[i]));

  hlnew.Count:=slnew.Count;
  for i:=0 to slnew.Count-1 do
    hlnew.Items[i]:=RGHashB(PChar(slnew[i]));

  Diff.Execute(hlold, hlnew);

  with Diff.DiffStats do
  begin
    StatusBar.Panels[0].Text := ' Matches: ' + inttostr(matches);
    StatusBar.Panels[1].Text := ' Modifies: ' + inttostr(modifies);
    StatusBar.Panels[2].Text := ' Adds: ' + inttostr(adds);
    StatusBar.Panels[3].Text := ' Deletes: ' + inttostr(deletes);
  end;

  seOld.Lines.Clear; //seOld.ClearAll;
  seNew.Lines.Clear; //seNew.ClearAll;
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
    inc(ltop);
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

procedure TCompareForm.GetPureText(se:TSynEdit; out sl:TStrings);
var
  i:integer;
begin
  sl:=TStringList.Create;
  sl.Capacity:=se.Lines.Count;

  for i:=0 to se.Lines.Count-1 do
    if se.Lines[i]<>'' then sl.Add(se.Lines[i]);
end;

constructor TCompareForm.Create(const fname:string; anew:PByte);
var
  slold,slnew:TStrings;
  pc:PWideChar;
begin
  Create(nil);

  Diff := TDiff.Create(self);

  SynTSyn:=TSynTSyn.Create(Self);
  seOld.Highlighter:=SynTSyn;
  seNew.Highlighter:=SynTSyn;

  srcfile:=fname;

  slold:=TStringList.Create;
  slnew:=TStringList.Create;

  slold.LoadFromFile(fname,TEncoding.Unicode);
  pc:=PWideChar(anew);
  if ord(pc^)=$FEFF then inc(pc);
  slnew.Text:=WideToStr(pc);

  DoCompare(slold, slnew);

  slold.Free;
  slnew.Free;
end;

procedure TCompareForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if seOld.Modified then
    if MessageDlg('Content was modified. Save at exit?',mtConfirmation,mbOkCancel,0)=mrOk then
      actSaveExecute(Sender);
end;

procedure TCompareForm.actPrevClick(Sender: TObject);
var
  row: integer;
  Kind: TChangeKind;
begin
  {TODO: Recompare before if was changed}
//  row:=seold.TopLine;
  row:=seold.CaretY-1;
  if row=0 then exit;

  Kind:=Diff.Compares[row].Kind;
  while (row>0) and (Diff.Compares[row].Kind=Kind) do dec(row);

  if Diff.Compares[row].Kind=ckNone then
  begin
    Kind:=ckNone;
    while (row>0) and (Diff.Compares[row].Kind=Kind) do dec(row);
  end;

//  If row<seold.TopLine then
  inc(row);
  If row<seold.CaretY then
  begin
    seold.CaretY:=row;
    senew.CaretY:=row;
//    seold.TopLine:=row;
//    senew.TopLine:=row;
  end;
  {TODO: actPrev.Enabled:=false if first occur}
end;

procedure TCompareForm.actRefreshExecute(Sender: TObject);
var
  slold,slnew:TStrings;
begin
  GetPureText(seold,slold);
  GetPureText(senew,slnew);

  DoCompare(slold,slnew);

  slold.Free;
  slnew.Free;
end;

procedure TCompareForm.actSaveExecute(Sender: TObject);
var
  slold:TStrings;
begin
  GetPureText(seold,slold);

  slold.WriteBOM:=true;
  slold.SaveToFile(srcfile,TEncoding.Unicode);
  slold.Free;
end;

procedure TCompareForm.actNextClick(Sender: TObject);
var
  row: integer;
  Kind: TChangeKind;
begin
{TODO: Recompare before if was changed}
//  row:=seold.TopLine;
  row:=seold.CaretY-1;
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
  inc(row);
  if row>seold.CaretY then
  begin
    seold.CaretY:=row;
    senew.CaretY:=row;
//    seold.TopLine:=row;
//    senew.TopLine:=row;
  end;
  {TODO: actNext.Enabled:=false if last occur}
end;

procedure TCompareForm.actCopyClick(Sender: TObject);
begin
//  seold.InsertTextAtCaret(senew.Lines[senew.CaretY-1]);
  seold.Lines[seold.CaretY-1]:=senew.Lines[senew.CaretY-1];
end;

procedure TCompareForm.actCancelExecute(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

end.
