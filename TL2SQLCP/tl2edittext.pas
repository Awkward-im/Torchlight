unit TL2EditText;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ActnList, ExtCtrls, Menus;

type

  { TEditTextForm }

  TEditTextForm = class(TForm)
    actShowAlt: TAction;
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
    sbAlt: TSpeedButton;
    procedure actMarkAsPartialExecute(Sender: TObject);
    procedure actNextLineExecute(Sender: TObject);
    procedure actNextUntranslatedExecute(Sender: TObject);
    procedure actPrevLineExecute(Sender: TObject);
    procedure actPrevUntranslatedExecute(Sender: TObject);
    procedure actShowAltExecute(Sender: TObject);
    procedure actShowDupeExecute(Sender: TObject);
    procedure actShowSampleExecute(Sender: TObject);
    procedure actTranslateExecute(Sender: TObject);
    procedure bbOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure memTransKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FIdx:integer;
    function CheckTheSame(idx: integer): integer;
    procedure SearchUntranslated(aidx: integer; anext: boolean);

  public
    constructor Create(AOwner:TComponent); override;
    procedure SelectLine(idx: integer);

    property EditIndex:integer read FIdx;
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
  TL2AltForm,
  TL2Text,
  rgdb.text;

resourcestring
  rsLanguage = 'Translation language';
  rsShow     = 'Click on "Show Doubles" button to show';

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

procedure TEditTextForm.SearchUntranslated(aidx:integer; anext:boolean);
var
  i:integer;
begin
  if not anext then
  begin
    actPrevUntranslated.Tag:=0;
    i:=aidx-1;
    while i>=0 do
    begin
      with TRCache[i] do
        if part or (dst='') or (src=dst) then
        begin
          actPrevUntranslated.Tag:=i;
          break;
        end;
      dec(i);
    end;
    actPrevUntranslated.Enabled:=actPrevUntranslated.Tag>0;
  end
  else
  begin
    actNextUntranslated.Tag:=0;
    i:=aidx+1;
    while i<Length(TRCache) do
    begin
      with TRCache[i] do
        if part or (dst='') or (src=dst) then
        begin
          actNextUntranslated.Tag:=i;
          break;
        end;
      inc(i);
    end;
    actNextUntranslated.Enabled:=actNextUntranslated.Tag>0;
  end;
end;

function TEditTextForm.CheckTheSame(idx:integer):integer;
var
  ltrans:AnsiString;
  litem:PTLCacheElement;
  i,ltmpl:integer;
begin
  result:=0;

  ltrans:=TRCache[idx].dst;
  if ltrans='' then exit;

  ltmpl:=TRCache[idx].tmpl;
  for i:=0 to High(TRCache) do
  begin
    if i<>idx then // not necessary, dst<>'' anyway
    begin
      litem:=@TRCache[i];

      if (litem^.dst =''   ) and
         (litem^.tmpl=ltmpl) then
      begin
        inc(result);
        litem^.dst  :=ReplaceTranslation(ltrans,litem^.src);
        litem^.part :=TL2Settings.cbAsPartial.Checked;
        litem^.flags:=litem^.flags or rfIsModified;
      end;
    end;
  end;
end;

procedure TEditTextForm.SelectLine(idx:integer);
var
  ls:AnsiString;
  ldir,lfile,ltag:AnsiString;
  lline,lflags:integer;
  i:integer;
  b:boolean;
begin
  //--- Save previous
  if FIdx>=0 then
  begin
    if memTrans.Modified then
    begin
      ls:=CRLFtoSlashN(memTrans.Text);

      if ls=TRCache[FIdx].src then ls:='';

      if TRCache[FIdx].dst<>ls then
      begin
        TRCache[FIdx].dst:=ls;
        TRCache[FIdx].flags:=TRCache[FIdx].flags or rfIsModified;
      end;
    end;

    if sbPartial.Down<>TRCache[FIdx].part then
    begin
      TRCache[FIdx].part :=sbPartial.Down;
      TRCache[FIdx].flags:=TRCache[FIdx].flags or rfIsModified;
    end;

    CheckTheSame(FIdx);

//    prj.UpdateGrid(FIdx);
//    prj.MoveToIndex(FIdx);
//    prj.data.CheckTheSame(FIdx,TL2Settings.cbAutoAsPartial.Checked);
  end;

  FIdx:=idx;

  if idx<0 then exit;

  //--- Navigation
  SearchUntranslated(idx,true);
  SearchUntranslated(idx,false);
{
  actPrevUntranslated.Tag:=0;
  i:=idx-1;
  while i>=0 do
  begin
    with TRCache[i] do
      if part or (dst='') or (src=dst) then
      begin
        actPrevUntranslated.Tag:=i;
        break;
      end;
    dec(i);
  end;
  actPrevUntranslated.Enabled:=actPrevUntranslated.Tag>0;

  actNextUntranslated.Tag:=0;
  i:=idx+1;
  while i<Length(TRCache) do
  begin
    with TRCache[i] do
      if part or (dst='') or (src=dst) then
      begin
        actNextUntranslated.Tag:=i;
        break;
      end;
    inc(i);
  end;
  actNextUntranslated.Enabled:=actNextUntranslated.Tag>0;
}
  actPrevLine.Enabled:=FIdx>0;
  actNextLine.Enabled:=FIdx<High(TRCache);

  //--- Addition
  if (TRCache[idx].flags and rfIsNoRef)<>0 then
  begin
    lblFile    .Caption:=rsNoRef;
    lblTagValue.Caption:='';
    lblTag     .Visible:=false;
    actShowDupe.Visible:=false;
  end
  else if (TRCache[idx].flags and rfIsManyRefs)<>0 then
  begin
	  lblFile.Caption:=StringReplace(rsSeveralRefs,'%d',
	      IntToStr(GetLineRefCount(TRCache[idx].id)),[]);
		lblTagValue.Caption:=rsShow;
    lblTag     .Visible:=false;
    actShowDupe.Visible:=true;
  end
  else
  begin
    i:=GetLineRef(TRCache[idx].id);
    GetRef(i, ldir,lfile,ltag,lline,lflags);
    lblFile    .Caption:=ldir+lfile;
		lblTagValue.Caption:=ltag;
    lblTag     .Visible:=true;
    actShowDupe.Visible:=false;
  end;

  lblNumber.Caption:=IntToStr(idx+1)+' / '+IntToStr(Length(TRCache));

  sbPartial.Down:=TRCache[idx].part;

  actShowSample.Visible:=GetSimilarCount(TRCache[idx].id)>0;

  //--- Text
  memOriginal.Text:=SlashNtoCRLF(TRCache[idx].src);
  memTrans   .Text:=SlashNtoCRLF(TRCache[idx].dst);
  memTrans.Modified:=false;
end;

//----- Actions -----

procedure TEditTextForm.actMarkAsPartialExecute(Sender: TObject);
begin
  TRCache[FIdx].part:=sbPartial.Down;
{
  TRCache[FIdx].part:=(sbPartial.Down) and
      (TRCache[FIdx].dst<>'') and
      (TRCache[FIdx].dst<>TRCache[FIdx].org);
}
end;

procedure TEditTextForm.actNextLineExecute(Sender: TObject);
begin
  SelectLine(FIdx+1);
end;

procedure TEditTextForm.actNextUntranslatedExecute(Sender: TObject);
begin
  SelectLine(actNextUntranslated.Tag);
end;

procedure TEditTextForm.actPrevLineExecute(Sender: TObject);
begin
  SelectLine(FIdx-1);
end;

procedure TEditTextForm.actPrevUntranslatedExecute(Sender: TObject);
begin
  SelectLine(actPrevUntranslated.Tag);
end;

procedure TEditTextForm.actShowAltExecute(Sender: TObject);
begin
  with TAltForm.Create(Self,FIdx) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TEditTextForm.actShowDupeExecute(Sender: TObject);
begin
  with TDupeForm.Create(Self,FIdx) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TEditTextForm.actShowSampleExecute(Sender: TObject);
begin
  with TSimilarForm.Create(Self,FIdx) do
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
//    if prj.Modified then ModalResult:=mrOk else
      ModalResult:=mrCancel;
  end;
end;

constructor TEditTextForm.Create(AOwner:TComponent);
begin
  inherited;

  FIdx:=-1;
  Caption:=rsLanguage+': '+CurLang;

  Font.Assign(TL2DM.TL2Font);
end;

end.
