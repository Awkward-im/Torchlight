unit formButtons;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  TLSGBase;

type

  { TfmButtons }

  TfmButtons = class(TForm)
    btnExport: TButton;
    btnImport: TButton;
    btnDelete: TButton;
    lblOffset: TLabel;
    procedure btnExportClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);

  private
    FClass:TLSGBaseClass;
    FName :string;
    FExt  :string;

    procedure SetOffset(aofs:integer);
    procedure SetClass(aclass:TLSGBaseClass);

  public
    property SClass:TLSGBaseClass read FClass write SetClass;
    property Name:string          read FName  write FName;
    property Ext:string           read FExt   write FExt;

    property Offset:integer write SetOffset;
  end;

var
  fmButtons: TfmButtons;

implementation

{$R *.lfm}

{ TfmButtons }

resourcestring
  rsExportData   = 'Export data';
  rsImportData   = 'Import data';

procedure TfmButtons.SetOffset(aofs:integer);
begin
  if aofs<0 then
    lblOffset.Caption:=''
  else
    lblOffset.Caption:='0x'+HexStr(aofs,8);
end;

procedure TfmButtons.SetClass(aclass:TLSGBaseClass);
begin
  FClass:=aclass;
  if aclass<>nil then
    SetOffset(aclass.DataOffset)
  else
    SetOffset(-1);
end;

procedure TfmButtons.btnExportClick(Sender: TObject);
var
  ldlg:TSaveDialog;
begin
  ldlg:=TSaveDialog.Create(nil);
  try
    ldlg.FileName  :=FName;
    ldlg.DefaultExt:=FExt;
    ldlg.Title     :=rsExportData;
    ldlg.Options   :=ldlg.Options+[ofOverwritePrompt];
    if ldlg.Execute then
      FClass.SaveToFile(ldlg.FileName);
  finally
    ldlg.Free;
  end;
end;

procedure TfmButtons.btnImportClick(Sender: TObject);
var
  ldlg:TOpenDialog;
  lstrm:TMemoryStream;
begin

  ldlg:=TOpenDialog.Create(nil);
  try
    ldlg.FileName  :='';
    ldlg.DefaultExt:=FExt;
    ldlg.Title     :=rsImportData;
    ldlg.Options   :=ldlg.Options;
    if ldlg.Execute then
    begin
      lstrm:=TMemoryStream.Create;
      lstrm.LoadFromFile(ldlg.FileName);
      lstrm.Position:=0;
      FClass.Clear;
{$NOTE Check version here}
      FClass.LoadFromStream(lstrm, $44);
      lstrm.Free;

//!!!!!!!      tvSaveGameSelectionChanged(Self);
    end;
  finally
    ldlg.Free;
  end;
end;

end.
