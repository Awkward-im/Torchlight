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
    leTitle   : TLabeledEdit;
    leAuthor  : TLabeledEdit;
    leWebsite : TLabeledEdit;
    leDownload: TLabeledEdit;
    memDescr  : TMemo;         lblDescr  : TLabel;
    seVersion : TSpinEditEx;   lblVersion: TLabel;
    bbNewGUID : TBitBtn;
    edGUID    : TEdit;         lblGUID   : TLabel;

    procedure bbNewGUIDClick(Sender: TObject);
    procedure bbOKClick(Sender: TObject);

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

procedure TMODInfoForm.bbOKClick(Sender: TObject);
begin
  SaveToFile(ffile);
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
  memDescr  .ReadOnly:=aRO;
  edGUID    .ReadOnly:=aRO;
  bbNewGUID .Enabled :=not aRO;
end;

procedure TMODInfoForm.SaveToInfo(var ami:TTL2ModInfo);
begin
  ClearModInfo(ami);

  ami.title   :=PUnicodeChar(UTF8Decode(leTitle   .Text));
  ami.author  :=PUnicodeChar(UTF8Decode(leAuthor  .Text));
  ami.descr   :=PUnicodeChar(UTF8Decode(memDescr  .Text));
  ami.website :=PUnicodeChar(UTF8Decode(leWebsite .Text));
  ami.download:=PUnicodeChar(UTF8Decode(leDownload.Text));
  Val(edGUID.Text,ami.modid);
  ami.modver  :=seVersion.Value;
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
  leTitle   .Text:=UTF8Encode(WideString(ami.title));//String(WideString(lmod.title));
  leAuthor  .Text:=String(WideString(ami.author));
  memDescr  .Text:=String(WideString(ami.descr));
  leWebsite .Text:=String(WideString(ami.website));
  leDownload.Text:=String(WideString(ami.download));
  edGUID.Text:=IntToStr(ami.modid);
  seVersion.Value:=ami.modver;
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