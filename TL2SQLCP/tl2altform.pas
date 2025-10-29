unit TL2AltForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids;

type

  { TAltForm }

  TAltForm = class(TForm)
    lblTag: TLabel;
    lblFile: TLabel;
    lblMod: TLabel;
    memAltT: TMemo;
    memSrc: TMemo;
    memAlt: TMemo;
    sgAlts: TStringGrid;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgAltsDblClick(Sender: TObject);
    procedure sgAltsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgAltsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  private
    procedure FillList(aidx: integer);

  public
    SelectedText:AnsiString;

    constructor Create(AOwner:TComponent; aline:integer); overload;
  end;

var
  AltForm: TAltForm;

implementation

{$R *.lfm}

uses
  LCLType,
  tl2datamodule,
  rgglobal,
  rgdb.text;


{ TAltForm }

procedure TAltForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then
  begin
    Key:=0;
    ModalResult:=mrClose;
  end;
end;

procedure TAltForm.sgAltsDblClick(Sender: TObject);
begin
  SelectedText:=sgAlts.Cells[1,sgAlts.Row];
  ModalResult:=mrOk;
end;

procedure TAltForm.sgAltsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_RETURN then
  begin
    Key:=0;
    if sgAlts.Row>=0 then
      sgAltsDblClick(Sender)
    else
      ModalResult:=mrClose;
  end;

  if Key=VK_SPACE then
  begin
    Key:=0;
    if (sgAlts.Row>=0) and (memAltT.Text<>'') then
    begin
      SelectedText:=memAltT.Text;
      ModalResult:=mrOk;
    end
    else
      ModalResult:=mrClose;
  end;
end;

constructor TAltForm.Create(AOwner: TComponent; aline: integer);
begin
  inherited Create(AOwner);

  Font.Assign(Application.MainForm.Font);

  FillList(aline);
  Activecontrol:=sgAlts;
end;

procedure TAltForm.sgAltsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
var
  ls:AnsiString;
  lid:integer;
begin
  if (aCol>=0) and (aRow>=0) then
  begin
    lid:=GetRefSrc(IntPtr(sgAlts.Objects[0,aRow]));
    memAlt.Text:=GetOriginal(lid);
    GetTranslation(lid,CurLang,ls);
    memAltT.Text:=ls;
  end;
end;

procedure TAltForm.FillList(aidx:integer);
var
  larr:TIntegerDynArray;
  ldir,lfile,ltag:string;
  i,lcnt,lref:integer;
  lmodid,lmodid1:Int64;
  lline,lflag:integer;
begin
  lref:=GetLineRef(TRCache[aidx].id);
  if GetRef(lref,ldir,lfile,ltag,lline,lflag)>0 then
  begin
    lblFile.Caption:=ldir+lfile;
    lblTag .Caption:=ltag;
    lmodid:=GetRefMod(lref);
    lblMod .Caption:=GetModName(lmodid);
  end
  else
  begin
    lblFile.Caption:=rsNoRef;
    exit;
  end;
  memSrc.Text:=TRCache[aidx].src;

  lref:=GetAlts(TRCache[aidx].id,larr);
  if lref>0 then
  begin
    sgAlts.RowCount:=lref;

    i:=0;
    lcnt:=0;
    for i:=0 to lref-1 do
    begin
      lmodid1:=GetRefMod(larr[i]);
      if lmodid1<>lmodid then
      begin
        sgAlts.Objects[0,lcnt]:=TObject(IntPtr(larr[i]));
        sgAlts.Cells  [0,lcnt]:=GetModName(lmodid1);
        sgAlts.Cells  [1,lcnt]:=GetOriginal(GetRefSrc(larr[i]));
        inc(lcnt);
      end;
    end;
//    sgAlts.RowCount:=lref;
    if lcnt<lref then sgAlts.RowCount:=lcnt;
    sgAlts.Row:=0;
  end
  else
    sgAlts.RowCount:=0;

  SetLength(larr,0);
end;

end.

