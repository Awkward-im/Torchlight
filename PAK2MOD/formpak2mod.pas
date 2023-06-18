unit formPak2Mod;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, EditBtn, Buttons,
  StdCtrls, rgglobal;

type

  { TfmPAK2MOD }

  TfmPAK2MOD = class(TForm)
    bbConvert: TBitBtn;
    bbClear: TBitBtn;
    deDir: TDirectoryEdit;
    fePAK: TFileNameEdit;
    feMAN: TFileNameEdit;
    feMOD: TFileNameEdit;
    lblPAK: TLabel;
    lblMAN: TLabel;
    lblMOD: TLabel;
    lblDir: TLabel;
    bbModInfo: TBitBtn;
    procedure bbClearClick(Sender: TObject);
    procedure bbConvertClick(Sender: TObject);
    procedure bbModInfoClick(Sender: TObject);
    procedure feAcceptFileName(Sender: TObject; var Value: String);
    procedure feButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  private
    fdir:string;
    fmi:TTL2ModInfo;

    procedure ProcessFile(const fname: string);

  public

  end;

var
  fmPAK2MOD: TfmPAK2MOD;

implementation

{$R *.lfm}

uses
  TL2Mod,
  fmModInfo,
  rgpak;

{ TfmPAK2MOD }

procedure TfmPAK2MOD.ProcessFile(const fname:string);
var
  ldir,
//  lext,
  lname:string;
begin
  ldir :=ExtractFileDir (fname)+'\';
  FDir :=ldir;
//  lext :=ExtractFileExt (fname);
  lname:=ExtractFileNameOnly(fname);

  if deDir.Text='' then deDir.Text:=ldir;

  if fePAK.Text='' then fePAK.Text:=ldir+lname+'.PAK';
  if feMAN.Text='' then feMAN.Text:=ldir+lname+'.PAK.MAN';
  if feMOD.Text='' then feMOD.Text:=ldir+lname+'.DAT';
  if FileExists(fePAK.Text) then fePAK.Color:=clWindow else fePAK.Color:=clAqua;
  if FileExists(feMAN.Text) then feMAN.Color:=clWindow else feMAN.Color:=clAqua;
  if FileExists(feMOD.Text) then feMOD.Color:=clWindow else feMOD.Color:=clAqua;
end;

procedure TfmPAK2MOD.FormDropFiles(Sender: TObject; const FileNames: array of string);
begin
  if Length(FileNames)>0 then
    ProcessFile(FileNames[0]);
end;

procedure TfmPAK2MOD.FormCreate(Sender: TObject);
begin
  MakeModInfo(fmi);

  if ParamCount>0 then
    ProcessFile(ParamStr(1));
end;

procedure TfmPAK2MOD.feButtonClick(Sender: TObject);
begin
  (Sender as TFileNameEdit).InitialDir:=FDir;
end;

procedure TfmPAK2MOD.feAcceptFileName(Sender: TObject; var Value: String);
begin
  ProcessFile(Value);
  (Sender as TFileNameEdit).Color:=clWindow;
end;

procedure TfmPAK2MOD.bbModInfoClick(Sender: TObject);
begin
  with TMODInfoForm.Create(Self,false) do
  begin
    if feMOD.Text<>'' then
      LoadFromFile(feMOD.Text)
    else
      LoadFromInfo(fmi);

    if ShowModal=mrOk then
    begin
      if feMOD.Text<>'' then
        SaveToFile(feMOD.Text);
      // Lets save to memory too
      SaveToInfo(fmi);
    end;
  end;
end;

procedure TfmPAK2MOD.bbConvertClick(Sender: TObject);
var
  res:integer;
begin
  if feMOD.Text<>'' then
    res:=RGPAKCombine(fePAK.Text,feMAN.Text,feMOD.Text,deDir.Text)
  else
    res:=RGPAKCombine(fePAK.Text,feMAN.Text,fmi,deDir.Text);
  if res=0 then
    ShowMessage('MOD created succesfully.')
  else
    ShowMessage('Something wrong. MOD didn''t created.');
end;

procedure TfmPAK2MOD.bbClearClick(Sender: TObject);
begin
  fePAK.Text:='';
  feMAN.Text:='';
  feMOD.Text:='';
  deDir.Text:='';
  ClearModInfo(fmi);
  MakeModInfo(fmi);
end;

end.

