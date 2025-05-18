{TODO: Edit translation in form (+button) with set for others}
unit TL2SimForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

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
    procedure FillList(aline:integer);

  public
    constructor Create(AOwner:TComponent; aline:integer); overload;
  end;


implementation

{$R *.lfm}

uses
  LCLType,
//  TL2DupeForm,
  TLTrSQL;

{ TSimilarForm }

constructor TSimilarForm.Create(AOwner:TComponent; aline:integer);
begin
  inherited Create(AOwner);

  Font.Assign(Application.MainForm.Font);

  FillList(aline);
end;

procedure TSimilarForm.lbSelectionChange(Sender: TObject; User: boolean);
var
  i:integer;
begin
  i:=IntPtr(lbSimList.Items.Objects[lbSimList.ItemIndex]);

  lblPartial.Visible:=TRCache[i].part;

  memText .Text:=TRCache[i].src;
  memTrans.Text:=TRCache[i].dst;

(*
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
*)
end;

procedure TSimilarForm.btnDupesClick(Sender: TObject);
begin
{
  with TDupeForm.Create(Self,fdata^,
      IntPtr(lbSimList.Items.Objects[lbSimList.ItemIndex])) do
  begin
    ShowModal;
    Free;
  end;
}
end;

procedure TSimilarForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then ModalResult:=mrOk;
end;

procedure TSimilarForm.FillList(aline:integer);
var
  ltmpl:AnsiString;
  i:integer;
begin
  lbSimList.Clear;

  lbSimList.AddItem(TRCache[aline].src,TObject(IntPtr(aline)));
//  GetSimilars(TRCache[aline].id,larr);
{
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
}
  lbSimList.ItemIndex:=0;
end;


end.

