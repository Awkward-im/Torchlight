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
  TL2DupeForm,
  rgglobal,
  TL2Text,
  rgdb.text;

resourcestring
  rsNoRef = 'No reference for this text';


{ TSimilarForm }

constructor TSimilarForm.Create(AOwner:TComponent; aline:integer);
begin
  inherited Create(AOwner);

  Font.Assign(Application.MainForm.Font);

  edTmpl.Text:=FilteredString(TRCache[aline].src);
  FillList(aline);
end;

procedure TSimilarForm.lbSelectionChange(Sender: TObject; User: boolean);
var
  ldir,lfile,ltag:AnsiString;
  i,lline,lflags:integer;
begin
  i:=IntPtr(lbSimList.Items.Objects[lbSimList.ItemIndex]);

  lblPartial.Visible:=TRCache[i].part;

  memText .Text:=TRCache[i].src;
  memTrans.Text:=TRCache[i].dst;

  if (TRCache[i].flags and rfIsNoRef)<>0 then
  begin
    btnDupes   .Visible:=false;
    lblTextLine.Visible:=false;
    lblTextFile.Visible:=true;
    lblTextTag .Visible:=false;
    lblTextFile.Caption:=rsNoRef;
  end
  else if (TRCache[i].flags and rfIsManyRefs)<>0 then
  begin
    btnDupes   .Visible:=true;
    lblTextLine.Visible:=false;
    lblTextFile.Visible:=false;
    lblTextTag .Visible:=false;
  end
  else
  begin
    btnDupes   .Visible:=false;
    lblTextLine.Visible:=true;
    lblTextFile.Visible:=true;
    lblTextTag .Visible:=true;

    GetRef(GetLineRef(TRCache[i].id),ldir,lfile,ltag,lline,lflags);

    lblTextLine.Caption:=IntToStr(lline);
    lblTextFile.Caption:=ldir+lfile;
    lblTextTag .Caption:=ltag;
  end;

end;

procedure TSimilarForm.btnDupesClick(Sender: TObject);
begin
  with TDupeForm.Create(Self,IntPtr(lbSimList.Items.Objects[lbSimList.ItemIndex])) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TSimilarForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then ModalResult:=mrOk;
end;

procedure TSimilarForm.FillList(aline:integer);
var
  larr:TIntegerDynArray;
  ltmpl:AnsiString;
  i,j,lcnt:integer;
begin
  lbSimList.Clear;

  lbSimList.AddItem(TRCache[aline].src,TObject(IntPtr(aline)));
  lcnt:=GetSimilars(TRCache[aline].id,larr);
  for i:=0 to lcnt-1 do
    for j:=0 to High(TRCache) do
      if TRCache[j].id=larr[i] then
      begin
        lbSimList.AddItem(TRCache[j].src,TObject(IntPtr(j)));
        break;
      end;

  lbSimList.ItemIndex:=0;
  SetLength(larr,0);
end;


end.
