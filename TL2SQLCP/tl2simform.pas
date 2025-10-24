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
  rsNoRef      = 'No reference for this text';
  rsAnotherMod = 'Looks like text is in another mod';


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
  if i<0 then
  begin
    lblPartial.Visible:=false;
    memText .Text:='';
    memTrans.Text:='';
  end
  else
  begin
    lblPartial.Visible:=TRCache[i].part;
    memText .Text:=TRCache[i].src;
    memTrans.Text:=TRCache[i].dst;
  end;

  if i<0 then
  begin
    btnDupes   .Visible:=false;
    lblTextLine.Visible:=false;
    lblTextFile.Visible:=true;
    lblTextTag .Visible:=false;
    lblTextFile.Caption:=rsAnotherMod;
  end
  else if (TRCache[i].flags and rfIsNoRef)<>0 then
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

    if GetRef(GetLineRef(TRCache[i].id),ldir,lfile,ltag,lline,lflags)>0 then
    begin
      lblTextLine.Caption:=IntToStr(lline);
      lblTextFile.Caption:=ldir+lfile;
      lblTextTag .Caption:=ltag;
    end;
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
  if Key=VK_ESCAPE then ModalResult:=mrCancel;
end;

procedure TSimilarForm.FillList(aline:integer);
var
  larr:TIntegerDynArray;
  ls:AnsiString;
  i,j,lcnt:integer;
  lfound:boolean;
begin
  lbSimList.Clear;

  lbSimList.AddItem(TRCache[aline].src,TObject(IntPtr(aline)));
  lcnt:=GetSimilars(TRCache[aline].id,larr);
  for i:=0 to lcnt-1 do
  begin
    lfound:=false;
    for j:=0 to High(TRCache) do
      if TRCache[j].id=larr[i] then
      begin
        lfound:=true;
        ls:=TRCache[j].src;
        if ls[Length(ls)]=' ' then ls[Length(ls)]:='~';
        lbSimList.AddItem(ls,TObject(IntPtr(j)));
        break;
      end;
    if not lfound then
    begin
      ls:=GetOriginal(larr[i]);
      if ls[Length(ls)]=' ' then ls[Length(ls)]:='~';
      lbSimList.AddItem(ls,TObject(-larr[i]));
    end;
  end;

  lbSimList.ItemIndex:=0;
  SetLength(larr,0);
end;


end.
