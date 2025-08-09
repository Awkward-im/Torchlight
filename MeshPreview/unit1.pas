unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, fm3dview;

type

  { TForm1 }

  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    fm:TForm3dView;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  fm.close;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  OpenDialog:TOpenDialog;
  lname:AnsiString;
begin
  if ParamCount=0 then
  begin
    OpenDialog:=TOpenDialog.Create(self);
    if OpenDialog.Execute then
      lname:=OpenDialog.FileName
    else
      lname:='';
    OpenDialog.Free;
  end
  else
  begin
    lname:=ParamStr(1);
  end;

  if lname='' then exit;

  Caption:=lname;

  fm:=TForm3dView.Create(Self);
  fm.Parent:=self;
  fm.align:=alClient;
  fm.visible:=true;
//  Self.ActiveControl:=fm.GLBox;
  fm.LoadFromFile(lname);
end;

initialization

finalization

end.
