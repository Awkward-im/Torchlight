unit TL2EditText;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ActnList, ExtCtrls, Menus,
  TL2DataUnit, TL2ProjectForm;

type

  { TEditTextForm }

  TEditTextForm = class(TForm)
    actShowDupe: TAction;
    ActionList: TActionList;
    actPrevLine        : TAction;
    actNextLine        : TAction;
    actPrevUntranslated: TAction;
    actNextUntranslated: TAction;
    actMarkAsPartial   : TAction;
    actShowSample      : TAction;
    actTranslate       : TAction;
    pnl_1_File: TPanel;
    lblFile    : TLabel;
    lblTag     : TLabel;
    lblTagValue: TLabel;
    pnl_3_Original: TPanel;
    memOriginal: TMemo;
    pnl_5_Translation: TPanel;
    memTrans: TMemo;
    pnl_6_Bottom: TPanel;
    lblNumber: TLabel;
    bbCancel : TBitBtn;
    bbOK     : TBitBtn;
    pnl_4_Toolbar: TPanel;
    sbPrevUntranslated: TSpeedButton;
    sbPrev            : TSpeedButton;
    sbNext            : TSpeedButton;
    sbNextUntranslated: TSpeedButton;
    sbPartial         : TSpeedButton;
    sbShowSample      : TSpeedButton;
    sbTranslate       : TSpeedButton;
    sbShowDupe: TSpeedButton;
    procedure actMarkAsPartialExecute(Sender: TObject);
    procedure actNextLineExecute(Sender: TObject);
    procedure actNextUntranslatedExecute(Sender: TObject);
    procedure actPrevLineExecute(Sender: TObject);
    procedure actPrevUntranslatedExecute(Sender: TObject);
    procedure actShowDupeExecute(Sender: TObject);
    procedure actShowSampleExecute(Sender: TObject);
    procedure actTranslateExecute(Sender: TObject);
    procedure bbOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure memTransKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
  LCLType,
  TL2DataModule,
  TL2SettingsForm,
  TL2DupeForm,
  TL2SimForm,
  TL2Text;

resourcestring
  sShow  = 'Click on "Show Doubles" button to show';

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
    prj.data.CheckTheSame(fidx,TL2Settings.cbAutoAsPartial.Checked);
  end;

  fIdx:=idx;

  if idx<0 then exit;

  //--- Navigation
  actPrevUntranslated.Tag:=0;
  i:=idx-1;
  while i>=0 do
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
  while i<prj.data.LineCount do
  begin
    if prj.data.State[i]<>stReady then
    begin
      actNextUntranslated.Tag:=i;
      break;
    end;
    inc(i);
  end;
  actNextUntranslated.Enabled:=actNextUntranslated.Tag>0;

  actPrevLine.Enabled:=fIdx>0;
  actNextLine.Enabled:=fIdx<(prj.data.LineCount-1);

  //--- Addition
  i:=prj.data.RefCount[idx];
  if i=1 then
  begin
{
    lblFile    .Caption:=prj.data.SrcFile[idx];
		lblTagValue.Caption:=prj.data.SrcTag [idx];
}
    i:=prj.data.Ref[idx];
    lblFile    .Caption:=prj.data.Refs.GetFile(i);
		lblTagValue.Caption:=prj.data.Refs.GetTag (i);
    lblTag.Visible:=true;
    actShowDupe.Visible:=false;
  end
  else if i=0 then
  begin
    lblFile    .Caption:=rsNoRef;
    lblTagValue.Caption:='';
    lblTag.Visible:=false;
    actShowDupe.Visible:=false;
  end
  else
  begin
	  lblFile    .Caption:=StringReplace(rsSeveralRefs,'%d',IntToStr(i),[]);
		lblTagValue.Caption:=sShow;
    lblTag.Visible:=false;
    actShowDupe.Visible:=true;
  end;
  lblNumber.Caption:=IntToStr(idx+1)+' / '+IntToStr(prj.data.LineCount);

  sbPartial.Down:=prj.data.State[idx]=stPartial;

  actShowSample.visible:=prj.data.Similars[idx];

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

procedure TEditTextForm.actShowDupeExecute(Sender: TObject);
begin
  with TDupeForm.Create(Self,prj.data,fidx) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TEditTextForm.actShowSampleExecute(Sender: TObject);
begin
  with TSimilarForm.Create(Self,prj.data,fidx) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TEditTextForm.actTranslateExecute(Sender: TObject);
begin
  if memTrans.SelLength>0 then
    memTrans.SelText:=Translate(memTrans.SelText)
  else if memOriginal.SelLength>0 then
    memTrans.Text:=Translate(memOriginal.SelText)
  else
    memTrans.Text:=Translate(memOriginal.Text);
  sbPartial.Down:=true;
end;

procedure TEditTextForm.bbOKClick(Sender: TObject);
begin
  SelectLine(-1);
  ModalResult:=mrOk;
end;

//----- Base -----

procedure TEditTextForm.memTransKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ls:AnsiString;
begin
  if (Key=VK_C) and (Shift=[ssAlt]) then
  begin
    if FillColorPopup(memTrans,memOriginal.Text) then
    begin
      Key:=0;
    end;
  end;

  if (Key=VK_V) and (Shift=[ssAlt]) then
  begin
    if FillParamPopup(memTrans,memOriginal.Text) then
    begin
      Key:=0;
    end;
  end;

  if (Key=VK_U) and (Shift=[ssAlt]) then
  begin
    memTrans.SelText:='|u';
    Key:=0;
  end;

  if (Key=VK_N) and (Shift=[ssAlt]) then
  begin
    memTrans.SelText:='\n';
    Key:=0;
  end;

  if (Key=VK_DELETE) and (Shift=[ssAlt]) then
  begin
    if memTrans.Text<>'' then
      ls:=memTrans.Text
    else
      ls:=memOriginal.Text;
    if RemoveColor(ls,ls) then
    begin
      memTrans.Text:=ls;
      actMarkAsPartial.Checked:=true;
      Key:=0;
    end;
  end
end;

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
