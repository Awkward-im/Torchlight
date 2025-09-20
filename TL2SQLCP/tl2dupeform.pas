unit TL2DupeForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids;

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
    procedure FillList(asrcid:integer);

  public
    constructor Create(AOwner:TComponent; aidx:integer); overload;
  end;


implementation

{$R *.lfm}

uses
  rgdb.text,
  rgglobal,
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
//  CreateFileTab(PTL2Translation(sgDupes.Objects[0,sgDupes.Row])^,
//                IntPtr         (sgDupes.Objects[1,sgDupes.Row]),nil);
end;

constructor TDupeForm.Create(AOwner:TComponent; aidx:integer);
begin
  inherited Create(AOwner);

  Font.Assign(Application.MainForm.Font);

  memText .Text:=TRCache[aidx].src;
  memTrans.Text:=TRCache[aidx].dst;

  FillList(TRCache[aidx].id);
end;

procedure TDupeForm.FillList(asrcid:integer);
var
  larr:TIntegerDynArray;
  ldir,lfile,ltag:AnsiString;
  i,lcnt:integer;
  lline,lflag:integer;
begin
  sgDupes.Clear;

  lcnt:=GetDoubles(asrcid,larr);
  sgDupes.RowCount:=1+lcnt;
  for i:=0 to lcnt-1 do
  begin
    if GetRef(larr[i],ldir,lfile,ltag,lline,lflag)>0 then
    begin
      sgDupes.Objects[0,i+1]:=TObject(UIntPtr(larr[i]));
      sgDupes.Cells[colFile,i+1]:=ldir+lfile;
      sgDupes.Cells[colLine,i+1]:=IntToStr(lline);
      sgDupes.Cells[colTag ,i+1]:=ltag;
    end;
  end;

  sgDupes.Row:=1;
  SetLength(larr,0);
end;

end.
