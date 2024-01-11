unit unitLogForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

type

  { TfmLogForm }

  TfmLogForm = class(TForm)
    bbClear: TBitBtn;
    memLog: TMemo;
    procedure bbClearClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private

     function AddToLog(var adata: string): integer;
  public

  end;

var
  fmLogForm: TfmLogForm;

implementation

{$R *.lfm}

uses
  rgglobal;

{ TfmLogForm }

function TfmLogForm.AddToLog(var adata:string):integer;
begin
  memLog.Append(adata);
  adata:='';
  result:=0;
end;

procedure TfmLogForm.bbClearClick(Sender: TObject);
begin
  memLog.Clear;
  RGLog.Clear;
end;

procedure TfmLogForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caHide;
end;

procedure TfmLogForm.FormCreate(Sender: TObject);
begin
  RGLog.OnAdd:=@AddToLog;
end;

end.
