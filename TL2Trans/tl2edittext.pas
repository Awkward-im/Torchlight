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
    mnuColor: TPopupMenu;
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
    procedure memTransKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
  private
    prj:TTL2Project;
    fIdx:integer;
    function FillColorPopup: boolean;
    function FillParamPopup: boolean;
    procedure PopupColorChanged(Sender: TObject);
    procedure PopupParamChanged(Sender: TObject);

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
  TL2Text;

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
    memTrans.SelText:=Translate(memTrans.SelText)
  else if memOriginal.SelLength>0 then
    memTrans.Text:=Translate(memOriginal.SelText)
  else
    memTrans.Text:=Translate(memOriginal.Text);
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

//----- Copy from TL2ProjectForm -----

procedure TEditTextForm.PopupParamChanged(Sender:TObject);
begin
  memTrans.SelText:=Copy((Sender as TMenuItem).Caption,4);
end;

function TEditTextForm.FillParamPopup:boolean;
const
  maxparams=10;
var
  lPopItem:TMenuItem;
  ls:AnsiString;
  params :array [0..maxparams-1] of String[31];
  idx,i,lcnt,llen:integer;
begin
  result:=false;
  mnuColor.Items.Clear;

  lcnt:=0;
  ls:=memOriginal.Text;
  llen:=Length(ls);
  i:=1;

  repeat
    if ls[i]='[' then
    begin
      params[lcnt]:='';
      repeat
        params[lcnt]:=params[lcnt]+ls[i];
        inc(i);
      until (i>llen) or (ls[i]=']');
      if i<=llen then
      begin
        inc(i);
        params[lcnt]:=params[lcnt]+']';
        // for case of [[param]]
        if (i<=llen) and (ls[i]=']') then
        begin
          params[lcnt]:=params[lcnt]+']';
          inc(i);
        end;
        inc(lcnt);
        if lcnt=maxparams then break;
      end;
    end
    else if ls[i]='<' then
    begin
      params[lcnt]:='';
      repeat
        params[lcnt]:=params[lcnt]+ls[i];
        inc(i);
      until (i>llen) or (ls[i]='>');
      if i<=llen then
      begin
        inc(i);
        params[lcnt]:=params[lcnt]+'>';
        inc(lcnt);
        if lcnt=maxparams then break;
      end;
    end
    else
      inc(i);
  until i>llen;

  if lcnt=0 then exit;

  if lcnt=1 then
  begin
    memTrans.SelText:=params[0];
  end
  else
  begin
    for i:=0 to lcnt-1 do
    begin
      lPopItem:=TMenuItem.Create(mnuColor);
      if i<9 then
        lPopItem.Caption:='&'+IntToStr(i+1)+' '+params[i]
      else
        lPopItem.Caption:='&0 '+params[i];
      lPopItem.OnClick:=@PopupParamChanged;
      mnuColor.Items.Add(lPopItem);
    end;

    mnuColor.PopUp;
  end;
end;

procedure TEditTextForm.PopupColorChanged(Sender:TObject);
begin
  memTrans.SelText:=InsertColor(memTrans.SelText,Copy((Sender as TMenuItem).Caption,4));
end;

function TEditTextForm.FillColorPopup:boolean;
const
  maxcolors=10;
var
  lPopItem:TMenuItem;
  ls:AnsiString;
  colors :array [0..maxcolors-1] of String[10]; //#124'cAARRGGBB', 10 times per text must be enough
  idx,i,llcnt,lcnt,llen:integer;
begin
  result:=false;
  mnuColor.Items.Clear;

  //-- Fill colors array
  lcnt:=0;
  ls:=memOriginal.Text;
  llen:=Length(ls)-10;
  i:=1;
  repeat
    if (ls[i]=#124) then
    begin
      inc(i);
      if (ls[i]='c') then
      begin
        inc(i);
        SetLength(colors[lcnt],10);
        colors[lcnt][ 1]:=#124;
        colors[lcnt][ 2]:='c';
        colors[lcnt][ 3]:=ls[i]; inc(i);
        colors[lcnt][ 4]:=ls[i]; inc(i);
        colors[lcnt][ 5]:=ls[i]; inc(i);
        colors[lcnt][ 6]:=ls[i]; inc(i);
        colors[lcnt][ 7]:=ls[i]; inc(i);
        colors[lcnt][ 8]:=ls[i]; inc(i);
        colors[lcnt][ 9]:=ls[i]; inc(i);
        colors[lcnt][10]:=ls[i]; inc(i);

        llcnt:=0;
        while llcnt<lcnt do
        begin
          if colors[lcnt]=colors[llcnt] then
            break;
          inc(llcnt);
        end;
        if llcnt=lcnt then
        begin
          inc(lcnt);
          if lcnt=maxcolors then break;
        end;
      end
      else
        inc(i);
    end
    else
      inc(i);
  until i>llen;

  if lcnt=0 then
    exit;

  //-- replace without confirmations if one color only
  if lcnt=1 then
  begin
    memTrans.SelText:=InsertColor(memTrans.SelText,colors[0]);
  end
  //-- Create and call menu if several colors
  else
  begin
    for i:=0 to lcnt-1 do
    begin
      lPopItem:=TMenuItem.Create(mnuColor);
      if i<9 then
        lPopItem.Caption:='&'+IntToStr(i+1)+' '+colors[i]
      else
        lPopItem.Caption:='&0 '+colors[i];
      lPopItem.OnClick:=@PopupColorChanged;
      mnuColor.Items.Add(lPopItem);
    end;

    mnuColor.PopUp;
  end;
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

procedure TEditTextForm.memTransKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ls:AnsiString;
begin
  if (Key=VK_C) and (Shift=[ssAlt]) then
  begin
    if FillColorPopup then
    begin
      Key:=0;
    end;
  end;

  if (Key=VK_V) and (Shift=[ssAlt]) then
  begin
    if FillParamPopup then
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

constructor TEditTextForm.Create(AOwner:TComponent);
begin
  inherited;

  prj:=(AOwner as TTL2Project);
  fIdx:=-1;

  Font.Assign(TL2DM.TL2Font);
end;

end.
