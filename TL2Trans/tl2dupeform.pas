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
    constructor Create(AOwner:TComponent; const adata:TTL2Translation; aline:integer); overload;
  end;


implementation

{$R *.lfm}

uses
  TL2DataModule,
  LCLType;

{ TDupeForm }

constructor TDupeForm.Create(AOwner:TComponent; const adata:TTL2Translation; aline:integer);
begin
  inherited Create(AOwner);

  Font.Assign(Application.MainForm.Font);

  memText .Text:=adata.Line [aline];
  memTrans.Text:=adata.Trans[aline];

  FillList(adata,aline);
end;

procedure TDupeForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then ModalResult:=mrOk;
end;

procedure TDupeForm.sgDupesDblClick(Sender: TObject);
begin
  CreateFileTab(PTL2Translation(sgDupes.Objects[0,sgDupes.Row])^,
                IntPtr         (sgDupes.Objects[1,sgDupes.Row]),nil);
end;

procedure TDupeForm.FillList(const adata:TTL2Translation; aline:integer);
var
  i,lcnt:integer;
  lRef:integer;
begin
  sgDupes.Clear;

  lcnt:=adata.RefCount[aline];
  sgDupes.RowCount:=1+lcnt;
  for i:=0 to lcnt-1 do
  begin
    lRef:=adata.Ref[aline,i];
    sgDupes.Objects[0,i+1]:=TObject(@adata);
    sgDupes.Objects[1,i+1]:=TObject(IntPtr(lref));
    sgDupes.Cells  [1,i+1]:=adata.Refs.GetFile(lRef);
    sgDupes.Cells  [2,i+1]:=IntToStr(adata.Refs.GetLine(lRef));
    sgDupes.Cells  [3,i+1]:=adata.Refs.GetTag(lRef);
  end;

  sgDupes.Row:=1;
end;

end.

