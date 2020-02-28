unit TL2EditText;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ActnList, ExtCtrls,
  TL2DataUnit, TL2ProjectForm;

type

  { TEditTextForm }

  TEditTextForm = class(TForm)
    actPrevLine: TAction;
    actNextLine: TAction;
    actPrevUntranslated: TAction;
    actNextUntranslated: TAction;
    actMarkAsPartial: TAction;
    actShowSample: TAction;
    actTranslate: TAction;
    ActionList: TActionList;
    bbCancel: TBitBtn;
    bbOK: TBitBtn;
    btnCloseSample: TSpeedButton;
    lblFile: TLabel;
    lblNumber: TLabel;
    memSample: TMemo;
    memOriginal: TMemo;
    memTrans: TMemo;
    pnl_2_Sample: TPanel;
    pnl_3_Original: TPanel;
    pnl_4_Toolbar: TPanel;
    pnl_5_Translation: TPanel;
    pnl_6_Bottom: TPanel;
    pnl_1_File: TPanel;
    sbPrev: TSpeedButton;
    sbNext: TSpeedButton;
    sbPartial: TSpeedButton;
    sbTranslate: TSpeedButton;
    sbShowSample: TSpeedButton;
    sbPrevUntranslated: TSpeedButton;
    sbNextUntranslated: TSpeedButton;
    procedure actMarkAsPartialExecute(Sender: TObject);
    procedure actNextLineExecute(Sender: TObject);
    procedure actNextUntranslatedExecute(Sender: TObject);
    procedure actPrevLineExecute(Sender: TObject);
    procedure actPrevUntranslatedExecute(Sender: TObject);
    procedure actShowSampleExecute(Sender: TObject);
    procedure actTranslateExecute(Sender: TObject);
    procedure bbOKClick(Sender: TObject);
    procedure btnCloseSampleClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    prj:TTL2Project;
    fIdx:integer;

  public
    constructor Create(AOwner:TComponent); override;
    procedure SelectLine(idx: integer);
  end;

var
  EditTextForm: TEditTextForm;

implementation

{$R *.lfm}

uses
  TL2DataModule,
  TL2SettingsForm;

function CRLFtoSlashN(const atext:AnsiString):AnsiString;
var
  i:integer;
begin
  result:=atext;
  i:=1;
  while i<Length(atext) do
  begin
    if (result[i]=#13) and (result[i+1]=#10) then
    begin
      result[i]:='\';
      inc(i);
      result[i]:='n';
    end;
    inc(i);
  end;
end;

function SlashNtoCRLF(const atext:AnsiString):AnsiString;
var
  i:integer;
begin
  result:=atext;
  i:=1;
  while i<Length(atext) do
  begin
    if (result[i]='\') and (result[i+1]='n') then
    begin
      result[i]:=#13;
      inc(i);
      result[i]:=#10;
    end;
    inc(i);
  end;
end;

procedure TEditTextForm.SelectLine(idx:integer);
var
  i:integer;
begin
  //--- Save previous
  if fIdx>=0 then
  begin
    if memTrans.Modified then
      prj.data.Trans[fidx]:=CRLFtoSlashN(memTrans.Text);

    if sbPartial.Down then
      prj.data.State[fidx]:=stPartial;

    prj.Modified:=true;
    prj.UpdateGrid(fidx);
    prj.MoveToIndex(fidx);
    prj.CheckTheSame;
  end;

  fIdx:=idx;

  if idx<0 then exit;

  //--- Navigation
  actPrevUntranslated.Tag:=0;
  i:=idx-1;
  while i>(prj.cntBaseLines+prj.cntModLines) do
  begin
    if prj.data.State[i]<>stReady then
    begin
      actPrevUntranslated.Tag:=i;
      break;
    end;
    dec(i);
  end;
  actPrevUntranslated.Enabled:=actPrevUntranslated.Tag>0;

  actNextUntranslated.Tag:=0;
  i:=idx+1;
  while i<prj.data.Lines do
  begin
    if prj.data.State[i]<>stReady then
    begin
      actNextUntranslated.Tag:=i;
      break;
    end;
    inc(i);
  end;
  actNextUntranslated.Enabled:=actNextUntranslated.Tag>0;

  actPrevLine.Enabled:=fIdx>(prj.cntBaseLines+prj.cntModLines);
  actNextLine.Enabled:=fIdx<(prj.data.Lines-1);

  //--- Addition
  lblFile  .Caption:=prj.data._File[idx];
  lblNumber.Caption:=IntToStr(idx+1-(prj.cntBaseLines+prj.cntModLines))+' / '+IntToStr(prj.data.Lines);

  sbPartial    .Down   :=prj.data.State [idx]=stPartial;
  actShowSample.Enabled:=prj.data.Sample[idx]<>'';

  //--- Text
  memOriginal.Text:=SlashNtoCRLF(prj.data.Line [idx]);
  memTrans   .Text:=SlashNtoCRLF(prj.data.Trans[idx]);
  memTrans.Modified:=false;
end;

//----- Actions -----

procedure TEditTextForm.actMarkAsPartialExecute(Sender: TObject);
begin
  if sbPartial.Down=true then
    prj.data.State[fIdx]:=stPartial
  else if memTrans.Text='' then
    prj.data.State[fIdx]:=stOriginal
  else
    prj.data.State[fIdx]:=stReady;
end;

procedure TEditTextForm.actNextLineExecute(Sender: TObject);
begin
  SelectLine(fIdx+1);
end;

procedure TEditTextForm.actNextUntranslatedExecute(Sender: TObject);
begin
  SelectLine(actNextUntranslated.Tag);
end;

procedure TEditTextForm.actPrevLineExecute(Sender: TObject);
begin
  SelectLine(fIdx-1);
end;

procedure TEditTextForm.actPrevUntranslatedExecute(Sender: TObject);
begin
  SelectLine(actPrevUntranslated.Tag);
end;

procedure TEditTextForm.actShowSampleExecute(Sender: TObject);
begin
  if pnl_2_Sample.Visible then
    pnl_2_Sample.Visible:=false
  else
  begin
    memSample.Text:=prj.data.Sample[fIdx];
    pnl_2_Sample.Visible:=true;
  end;
end;

procedure TEditTextForm.actTranslateExecute(Sender: TObject);
begin
  if memTrans.SelLength>0 then
    memTrans.SelText:=TranslateYandex(memTrans.SelText)
  else if memOriginal.SelLength>0 then
    memTrans.Text:=TranslateYandex(memOriginal.SelText)
  else
    memTrans.Text:=TranslateYandex(memOriginal.Text);
  sbPartial.Down:=true;
end;

procedure TEditTextForm.btnCloseSampleClick(Sender: TObject);
begin
  pnl_2_Sample.Visible:=false;
end;

procedure TEditTextForm.bbOKClick(Sender: TObject);
begin
  SelectLine(-1);
  ModalResult:=mrOk;
end;

//----- Base -----

procedure TEditTextForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if CloseAction=caFree then
  begin
    if prj.Modified then ModalResult:=mrOk
    else ModalResult:=mrCancel;
  end;
end;

constructor TEditTextForm.Create(AOwner:TComponent);
begin
  inherited;

  prj:=(AOwner as TTL2Project);
  fIdx:=-1;

  Font.Assign(TL2DM.TL2Font);
end;

end.

