unit formButtons;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  TLSGBase,tlsave;

type

  { TfmButtons }

  TfmButtons = class(TForm)
    btnExport: TButton;
    btnImport: TButton;
    btnDelete: TButton;
    lblOffset: TLabel;
    lblSize: TLabel;
    procedure btnExportClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);

  private
    FSGame:TTLSaveFile;
    FClass:TLSGBaseClass;
    FName :string;
    FExt  :string;

    procedure SetOffset(aofs  :integer);
    procedure SetSize  (asize :integer);
    procedure SetClass (aclass:TLSGBaseClass);

  public
    property SGame :TTLSaveFile   read FSGame   write FSGame;
    property SClass:TLSGBaseClass read FClass   write SetClass;
    property Name  :string        read FName    write FName;
    property Ext   :string        read FExt     write FExt;

    property Offset:integer write SetOffset;
    property Size  :integer write SetSize;
  end;

var
  fmButtons: TfmButtons;

implementation

{$R *.lfm}

uses
  rgglobal;

{ TfmButtons }

resourcestring
  rsExportData   = 'Export data';
  rsImportData   = 'Import data';

procedure TfmButtons.SetSize(asize:integer);
begin
  if asize<0 then
    lblSize.Caption:=''
  else
    lblSize.Caption:=IntToStr(asize);
end;

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
  begin
    SetOffset(aclass.DataOffset);
    SetSize  (aclass.DataSize);
  end
  else
  begin
    SetOffset(-1);
    SetSize  (-1);
  end;
end;

procedure TfmButtons.btnExportClick(Sender: TObject);
var
  ldlg:TSaveDialog;
  lstrm:TMemoryStream;
  lver:byte;
begin
  ldlg:=TSaveDialog.Create(nil);
  try
    ldlg.FileName  :=FName;
    ldlg.DefaultExt:=FExt;
    ldlg.Title     :=rsExportData;
    ldlg.Options   :=ldlg.Options+[ofOverwritePrompt];
    if ldlg.Execute then
    begin
      if FSGame.GameVersion=verTL1 then
        lver:=tlsaveTL1
      else
        lver:=tlsaveTL2;

      lstrm:=TMemoryStream.Create;
      lstrm.WriteByte(lver);
      FClass.SaveToStream(lstrm,lver);
      lstrm.Position:=0;
      lstrm.SaveToFile(ldlg.FileName);
      lstrm.Free;
    end;
  finally
    ldlg.Free;
  end;
end;

procedure TfmButtons.btnImportClick(Sender: TObject);
var
  ldlg:TOpenDialog;
  lstrm:TMemoryStream;
  lver:byte;
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
      lver:=lstrm.ReadByte();
      // still trying to load (and convert) version
      FClass.Clear;
      FClass.LoadFromStream(lstrm,lver);
      lstrm.Free;

//!!!!!!!      tvSaveGameSelectionChanged(Self);
    end;
  finally
    ldlg.Free;
  end;
end;

end.
