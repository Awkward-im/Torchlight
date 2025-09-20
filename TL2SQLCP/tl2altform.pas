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
    memSrc: TMemo;
    memAlt: TMemo;
    sgAlts: TStringGrid;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgAltsSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
  private
    procedure FillList(aidx: integer);

  public
    constructor Create(AOwner:TComponent; aline:integer); overload;
  end;

var
  AltForm: TAltForm;

implementation

{$R *.lfm}

uses
  LCLType,
  rgglobal,
  rgdb.text;


{ TAltForm }

procedure TAltForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then ModalResult:=mrOk;
end;

constructor TAltForm.Create(AOwner: TComponent; aline: integer);
begin
  inherited Create(AOwner);

  Font.Assign(Application.MainForm.Font);

  FillList(aline);
end;

procedure TAltForm.sgAltsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if (aCol>=0) and (aRow>=0) then
    memAlt.Text:=GetOriginal(GetRefSrc(IntPtr(sgAlts.Objects[0,aRow])));
end;

procedure TAltForm.FillList(aidx:integer);
var
  larr:TIntegerDynArray;
  ldir,lfile,ltag:string;
  i,lref:integer;
  lline,lflag:integer;
begin
  lref:=GetLineRef(TRCache[aidx].id);
  if GetRef(lref,ldir,lfile,ltag,lline,lflag)>0 then
  begin
    lblFile.Caption:=ldir+lfile;
    lblTag .Caption:=ltag;
  end;
  memSrc.Text:=TRCache[aidx].src;

  i:=GetAlts(TRCache[aidx].id,larr);
  if i>0 then
  begin
    sgAlts.RowCount:=i;

    while i>0 do
    begin
      dec(i);
      sgAlts.Objects[0,i]:=TObject(IntPtr(larr[i]));
      sgAlts.Cells[0,i]:=GetModName(GetRefMod(larr[i]));
      sgAlts.Cells[1,i]:=GetOriginal(GetRefSrc(larr[i]));
    end;
    sgAlts.Row:=0;
  end
  else
    sgAlts.RowCount:=0;

  SetLength(larr,0);
end;

end.

