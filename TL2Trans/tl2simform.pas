{TODO: Edit translation in form (+button) with set for others}
unit TL2SimForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  TL2DataUnit;

type

  { TSimilarForm }

  TSimilarForm = class(TForm)
    btnDupes: TButton;
    lblPartial : TLabel;
    lblTextLine: TLabel;
    lblTextFile: TLabel;
    lblTextTag : TLabel;
    lbSimList: TListBox;
    edTmpl  : TEdit;
    memText : TMemo;
    memTrans: TMemo;
    procedure btnDupesClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lbSelectionChange(Sender: TObject; User: boolean);
  private
    fdata:PTL2Translation;
    procedure FillList(const adata:TTL2Translation; aline:integer);

  public
    constructor Create(AOwner:TComponent; const adata:TTL2Translation;
        aline:integer); overload;
  end;


implementation

{$R *.lfm}

uses
  LCLType,
  TL2DupeForm;

{ TSimilarForm }

constructor TSimilarForm.Create(AOwner:TComponent; const adata:TTL2Translation; aline:integer);
begin
  inherited Create(AOwner);

  Font.Assign(Application.MainForm.Font);

  fdata:=@adata;
  FillList(adata,aline);
end;

procedure TSimilarForm.lbSelectionChange(Sender: TObject; User: boolean);
var
  i:integer;
begin
  i:=IntPtr(lbSimList.Items.Objects[lbSimList.ItemIndex]);

  lblPartial.Visible:=fdata^.State[i] = stPartial;

  memText .Text:=fdata^.Line [i];
  memTrans.Text:=fdata^.Trans[i];

  if fdata^.RefCount[i]=1 then
  begin
    btnDupes   .Visible:=false;
    lblTextLine.Visible:=true;
    lblTextFile.Visible:=true;
    lblTextTag .Visible:=true;
{
    lblTextLine.Caption:=IntToStr(fdata^.SrcLine[i]);
    lblTextFile.Caption:=fdata^.SrcFile[i];
    lblTextTag .Caption:=fdata^.SrcTag [i];
}
    i:=fdata^.Ref[i];
    lblTextLine.Caption:=IntToStr(fdata^.Refs.GetLine(i));
    lblTextFile.Caption:=fdata^.Refs.GetFile(i);
    lblTextTag .Caption:=fdata^.Refs.GetTag(i);
  end
  else
  begin
    btnDupes   .Visible:=true;
    lblTextLine.Visible:=false;
    lblTextFile.Visible:=false;
    lblTextTag .Visible:=false;
  end;
end;

procedure TSimilarForm.btnDupesClick(Sender: TObject);
begin
  with TDupeForm.Create(Self,fdata^,
      IntPtr(lbSimList.Items.Objects[lbSimList.ItemIndex])) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TSimilarForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then ModalResult:=mrOk;
end;

procedure TSimilarForm.FillList(const adata:TTL2Translation; aline:integer);
var
  ltmpl:AnsiString;
  i:integer;
begin
  lbSimList.Clear;

  ltmpl:=adata.Template[aline];
  edTmpl.Text:=ltmpl;
  i:=0;
  // better to select by some way
  lbSimList.AddItem(adata.Line[aline],TObject(IntPtr(aline)));
  while i<adata.LineCount do
  begin
    if i<>aline then
    begin
      if adata.Template[i]=ltmpl then
        lbSimList.AddItem(adata.Line[i],TObject(IntPtr(i)))
    end;
    inc(i);
  end;

  lbSimList.ItemIndex:=0;
end;


end.

