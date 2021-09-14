unit fmModInfo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, SpinEx;

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
    fname:String;

  public
    Constructor Create(AOwner:TComponent; aFile:String; aRO:boolean=false); overload;
    function    Save:boolean;
    function    Reload:boolean;

  end;

var
  MODInfoForm: TMODInfoForm;

implementation

{$R *.lfm}

uses
  rgglobal,
  TL2Mod;

procedure TMODInfoForm.bbNewGUIDClick(Sender: TObject);
var
  lguid:TGUID;
begin
  CreateGUID(lguid);
  edGUID.Text:=IntToStr(Int64(MurmurHash64B(lguid,16,0)));
end;

procedure TMODInfoForm.bbOKClick(Sender: TObject);
begin
  Save;
end;

Constructor TMODInfoForm.Create(AOwner:TComponent; aFile:String; aRO:boolean=false);
begin
  inherited Create(AOwner);

  fname:=aFile;
  Reload;

  seVersion .ReadOnly:=aRO;
  leTitle   .ReadOnly:=aRO;
  leAuthor  .ReadOnly:=aRO;
  leWebsite .ReadOnly:=aRO;
  leDownload.ReadOnly:=aRO;
  memDescr  .ReadOnly:=aRO;
  edGUID    .ReadOnly:=aRO;
  bbNewGUID .Enabled :=not aRO;
end;

function TMODInfoForm.Save:boolean;
var
  lmod:TTL2ModInfo;
begin
  MakeModInfo(lmod);

  lmod.title   :=PUnicodeChar(UTF8Decode(leTitle   .Text));
  lmod.author  :=PUnicodeChar(UTF8Decode(leAuthor  .Text));
  lmod.descr   :=PUnicodeChar(UTF8Decode(memDescr  .Text));
  lmod.website :=PUnicodeChar(UTF8Decode(leWebsite .Text));
  lmod.download:=PUnicodeChar(UTF8Decode(leDownload.Text));
  Val(edGUID.Text,lmod.modid);
  lmod.modver  :=seVersion.Value;
  
  result:=SaveModConfiguration(lmod, PChar(fname));

  ClearModInfo(lmod);
end;

function TMODInfoForm.Reload:boolean;
var
  lmod:TTL2ModInfo;
begin
  MakeModInfo(lmod);

  result:=LoadModConfiguration(PChar(fname), lmod);
  if result then
  begin
    leTitle   .Text:=UTF8Encode(WideString(lmod.title));//String(WideString(lmod.title));
    leAuthor  .Text:=String(WideString(lmod.author));
    memDescr  .Text:=String(WideString(lmod.descr));
    leWebsite .Text:=String(WideString(lmod.website));
    leDownload.Text:=String(WideString(lmod.download));
    edGUID.Text:=IntToStr(lmod.modid);
    seVersion.Value:=lmod.modver;
  end;

  ClearModInfo(lmod);
end;

end.
