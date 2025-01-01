unit unitLogForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, Buttons;

type

  { TfmLogForm }

  TfmLogForm = class(TForm)
    bbClear: TBitBtn;
    bbSave: TBitBtn;
    memLog: TMemo;
    procedure bbClearClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
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

resourcestring
  rsCantSave = 'Can''t save log file';


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

procedure TfmLogForm.bbSaveClick(Sender: TObject);
var
  dlg:TSaveDialog;
  f:System.Text;
begin
  dlg:=TSaveDialog.Create(nil);
  try
    dlg.Options:=dlg.Options+[ofOverwritePrompt];
    if (dlg.Execute) then
    begin
      AssignFile(f,dlg.FileName);
      Rewrite(f);
      if IOResult=0 then
      begin
        Write(f,memLog.Text);
        CloseFile(f);
      end
      else
        ShowMessage(rsCantSave);
    end;
  finally
    dlg.Free;
  end;
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
