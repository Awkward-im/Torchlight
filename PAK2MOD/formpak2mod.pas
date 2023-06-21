unit formPak2Mod;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, EditBtn, Buttons,
  StdCtrls, ComCtrls, rgglobal;

type

  { TfmPAK2MOD }

  TfmPAK2MOD = class(TForm)
    bbClear: TBitBtn;
    bbConvert: TBitBtn;
    bbInfo: TBitBtn;
    deDir: TDirectoryEdit;
    dePAKOutput: TDirectoryEdit;
    fePAK: TFileNameEdit;
    feMAN: TFileNameEdit;
    feMOD: TFileNameEdit;
    feMODInput: TFileNameEdit;
    lblMODInput: TLabel;
    lblPAKOutput: TLabel;
    lblPAK: TLabel;
    lblMAN: TLabel;
    lblMOD: TLabel;
    lblDir: TLabel;
    bbModInfo: TBitBtn;
    PageControl: TPageControl;
    tsMOD2PAK: TTabSheet;
    tsPAK2MOD: TTabSheet;
    procedure bbClearClick(Sender: TObject);
    procedure bbConvertClick(Sender: TObject);
    procedure bbInfoClick(Sender: TObject);
    procedure bbModInfoClick(Sender: TObject);
    procedure feAcceptFileName(Sender: TObject; var Value: String);
    procedure feButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  private
    fdir:string;
    fmi:TTL2ModInfo;

    procedure ProcessFile(const fname: string);
    procedure ProcessMODFile(const fname: string);

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

procedure TfmPAK2MOD.ProcessMODFile(const fname:string);
begin
  feMODInput.Text:=fname;
  bbInfo.Enabled:=true;

  Fdir:=ExtractFileDir(fname)+'\';
  if dePAKOutput.Text='' then dePAKOutput.Text:=FDir;
end;

procedure TfmPAK2MOD.FormDropFiles(Sender: TObject; const FileNames: array of string);
begin
  if Length(FileNames)>0 then
  begin
    if PageControl.ActivePage=tsPAK2MOD then
      ProcessFile(FileNames[0])
    else
      ProcessMODFile(FileNames[0]);
  end;
end;

procedure TfmPAK2MOD.FormCreate(Sender: TObject);
begin
  MakeModInfo(fmi);

  PageControl.ActivePage:=tsMOD2PAK;
{
  if ParamCount>0 then
    ProcessFile(ParamStr(1));
}
end;

procedure TfmPAK2MOD.FormDestroy(Sender: TObject);
begin
  ClearModInfo(fmi);
end;

procedure TfmPAK2MOD.feButtonClick(Sender: TObject);
begin
  (Sender as TFileNameEdit).InitialDir:=FDir;
end;

procedure TfmPAK2MOD.feAcceptFileName(Sender: TObject; var Value: String);
begin
  if PageControl.ActivePage=tsPAK2MOD then
  begin
    ProcessFile(Value);
    (Sender as TFileNameEdit).Color:=clWindow;
  end
  else
    ProcessMODFile(Value);
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

procedure TfmPAK2MOD.bbInfoClick(Sender: TObject);
begin
  with TMODInfoForm.Create(Self,true) do
  begin
    ClearModInfo(fmi);
    ReadMODInfo(PChar(feMODInput.Text),fmi);
    LoadFromInfo(fmi);
    ShowModal;
  end;
end;

procedure TfmPAK2MOD.bbConvertClick(Sender: TObject);
var
  res:integer;
begin
  if PageControl.ActivePage=tsPAK2MOD then
  begin
    if feMOD.Text<>'' then
      res:=RGPAKCombine(fePAK.Text,feMAN.Text,feMOD.Text,deDir.Text)
    else
      res:=RGPAKCombine(fePAK.Text,feMAN.Text,fmi,deDir.Text);
    if res=0 then
      ShowMessage('MOD created succesfully.')
    else
      ShowMessage('Something wrong. MOD didn''t created.');
  end
  else
  begin
    if RGPAKSplit(feMODInput.Text,dePAKOutput.Text)=0 then
      ShowMessage('MOD converted to PAK succesfully.')
    else
      ShowMessage('Something wrong. MOD didn''t converted.');
  end;
end;

procedure TfmPAK2MOD.bbClearClick(Sender: TObject);
begin
  // MOD 2 PAK
  feMODInput .Text:='';
  dePAKOutput.Text:='';
  bbInfo.Enabled:=false;

  // PAK 2 MOD
  fePAK.Text:='';
  feMAN.Text:='';
  feMOD.Text:='';
  deDir.Text:='';

  ClearModInfo(fmi);
  MakeModInfo(fmi);
end;

end.

