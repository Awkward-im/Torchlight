unit fmModInfo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, SpinEx, rgglobal, TL2Mod;

type

  { TMODInfoForm }

  TMODInfoForm = class(TForm)
    bbOK      : TBitBtn;
    bbCancel  : TBitBtn;
    bbSave    : TBitBtn;
    lblNote   : TLabel;
    leTitle   : TLabeledEdit;
    leAuthor  : TLabeledEdit;
    leFilename: TLabeledEdit;
    leWebsite : TLabeledEdit;
    leDownload: TLabeledEdit;
    memDescr  : TMemo;         lblDescr  : TLabel;
    seVersion : TSpinEditEx;   lblVersion: TLabel;
    bbNewGUID : TBitBtn;
    edGUID    : TEdit;         lblGUID   : TLabel;

    procedure bbCancelClick(Sender: TObject);
    procedure bbNewGUIDClick(Sender: TObject);
    procedure bbOKClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);

  private
    ffile:string;
  public
    Constructor Create(AOwner:TComponent; aRO:boolean=false); overload;
    procedure LoadFromFile(const aFile:string);
    procedure SaveToFile(const aFile:string);
    procedure LoadFromInfo(const ami: TTL2ModInfo);
    procedure SaveToInfo(var ami: TTL2ModInfo);
  end;

var
  MODInfoForm: TMODInfoForm;

implementation

{$R *.lfm}

procedure TMODInfoForm.bbNewGUIDClick(Sender: TObject);
var
  lguid:TGUID;
begin
  CreateGUID(lguid);
  edGUID.Text:=IntToStr(Int64(MurmurHash64B(lguid,16,0)));
end;

procedure TMODInfoForm.bbCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TMODInfoForm.bbOKClick(Sender: TObject);
begin
//  if not seVersion.ReadOnly then SaveToFile(ffile);
//!!!!!!!!!!!!!!!!!!! Close for non-modal only
//  Close;
end;

procedure TMODInfoForm.bbSaveClick(Sender: TObject);
var
  dlg:TSaveDialog;
begin
  dlg:=TSaveDialog.Create(nil);
  dlg.FileName  :='MOD.DAT';
  dlg.DefaultExt:='.DAT';
  dlg.Filter    :='*.DAT|*.dat|All files|*.*';
  if dlg.Execute then
    SaveToFile(dlg.FileName);
  dlg.Free;
end;

Constructor TMODInfoForm.Create(AOwner:TComponent; aRO:boolean=false);
begin
  inherited Create(AOwner);

  ffile:='';
  seVersion .ReadOnly:=aRO;
  leTitle   .ReadOnly:=aRO;
  leAuthor  .ReadOnly:=aRO;
  leWebsite .ReadOnly:=aRO;
  leDownload.ReadOnly:=aRO;
  leFilename.ReadOnly:=aRO;
  memDescr  .ReadOnly:=aRO;
  edGUID    .ReadOnly:=aRO;
  bbNewGUID .Enabled :=not aRO;
end;

procedure TMODInfoForm.SaveToInfo(var ami:TTL2ModInfo);
begin
  ClearModInfo(ami);

  ami.title   :=StrToWide(leTitle   .Text);
  ami.author  :=StrToWide(leAuthor  .Text);
  ami.descr   :=StrToWide(memDescr  .Text);
  ami.website :=StrToWide(leWebsite .Text);
  ami.download:=StrToWide(leDownload.Text);
  Val(edGUID.Text,ami.modid);
  ami.modver  :=seVersion.Value;
  ami.filename:=StrToWide(leFilename.Text);
end;

procedure TMODInfoForm.SaveToFile(const aFile:string);
var
  lmod:TTL2ModInfo;
begin
  MakeModInfo(lmod);

  SaveToInfo(lmod);
  SaveModConfiguration(lmod, PChar(aFile));

  ClearModInfo(lmod);
end;

procedure TMODInfoForm.LoadFromInfo(const ami:TTL2ModInfo);
begin
  leTitle   .Text:=WideToStr(ami.title   );
  leAuthor  .Text:=WideToStr(ami.author  );
  memDescr  .Text:=WideToStr(ami.descr   );
  leWebsite .Text:=WideToStr(ami.website );
  leDownload.Text:=WideToStr(ami.download);
  edGUID    .Text:=IntToStr (ami.modid   );
  seVersion.Value:=ami.modver;
  leFilename.Text:=WideToStr(ami.filename);
end;

procedure TMODInfoForm.LoadFromFile(const aFile:string);
var
  lmod:TTL2ModInfo;
begin
  MakeModInfo(lmod);

  if LoadModConfiguration(PChar(aFile),lmod) then
  begin
    LoadFromInfo(lmod);
    ffile:=aFile;
  end
  else
    ffile:='';

  ClearModInfo(lmod);
end;

end.
