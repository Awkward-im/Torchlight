unit TL2DupeForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  TL2DataUnit;

type

  { TSimilaristForm }

  { TDupeForm }

  TDupeForm = class(TForm)
    sgDupes : TStringGrid;
    memText : TMemo;
    memTrans: TMemo;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgDupesDblClick(Sender: TObject);
  private
    procedure FillList(const adata:TTL2Translation; aline:integer);

  public
    constructor Create(AOwner:TComponent; const adata:TTL2Translation;
        aline:integer); overload;
  end;


implementation

{$R *.lfm}

uses
  TL2DataModule,
  LCLType;

const
  colFile = 1;
  colLine = 2;
  colTag  = 3;

{ TDupeForm }

procedure TDupeForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then ModalResult:=mrOk;
end;

procedure TDupeForm.sgDupesDblClick(Sender: TObject);
begin
  CreateFileTab(PTL2Translation(sgDupes.Objects[0,sgDupes.Row])^,
                IntPtr         (sgDupes.Objects[1,sgDupes.Row]),nil);
end;

constructor TDupeForm.Create(AOwner:TComponent; asrcid:integer);
var
  lsrc,ldst:AnsiString;
begin
  inherited Create(AOwner);

  Font.Assign(Application.MainForm.Font);

//!!  GetText(asrcid,,lsrc,ldst);
  memText .Text:=lsrc;
  memTrans.Text:=ldst;

  FillList(asrcid);
end;

procedure TDupeForm.FillList(asrcid:integer);
var
  larr:TIntegerDynArray;
  ldir,lfile,ltag:AnsiString;
  i,lcnt:integer;
  lline,lflag:integer;
begin
  sgDupes.Clear;

  lcnt:=GetDoubles(arr);
  sgDupes.RowCount:=1+lcnt;
  for i:=0 to lcnt-1 do
  begin
    GetRef(larr[i],ldir,lfile,ltag,lline,lflag);
    sgDupes.Objects[0,i+1]:=TObject(UIntPtr(larr[i]));
    sgDupes.Cells[colFile,i+1]:=ldir+lfile;
    sgDupes.Cells[colLine,i+1]:=IntToStr(lline);
    sgDupes.Cells[colTag ,i+1]:=ltag;
  end;

  sgDupes.Row:=1;
end;

end.

