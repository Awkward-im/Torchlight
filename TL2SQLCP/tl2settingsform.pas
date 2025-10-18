unit TL2SettingsForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons,  trclass;

type

  { TTL2Settings }

  TTL2Settings = class(TForm)
    bbFontEdit: TBitBtn;
    bbSaveSettings: TBitBtn;
    cbAsPartial: TCheckBox;
    cbRemoveTags: TCheckBox;
    cbParamSign: TCheckBox;
    cbDiskDB: TCheckBox;
    edFilterWords: TEdit;
    edTransLang: TEdit;
    gbTranslation: TGroupBox;
    cbAPIKey: TCheckBox;
    gbTemplate: TGroupBox;
    lblTmplDescr: TLabel;
    lblFilter: TLabel;
    lblTitle: TLabel;
    lblGetAPIKey: TLabel;
    lblDescr: TLabel;
    lblTranslators: TLabel;
    lblProgramLanguage: TLabel;
    lblLang: TLabel;
    lbLanguage: TListBox;
    lblNote: TLabel;
    lbTranslators: TListBox;
    memAPIKey: TMemo;
    procedure bbSaveSettingsClick(Sender: TObject);
    procedure btnFontEditClick(Sender: TObject);
    procedure cbAPIKeyChange(Sender: TObject);
    procedure cbDiskDBClick(Sender: TObject);
    procedure edDefaultFileAcceptFileName(Sender: TObject; var Value: String);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbLanguageSelectionChange(Sender: TObject; User: boolean);
    procedure lblGetAPIKeyClick(Sender: TObject);
    procedure lbTranslatorsSelectionChange(Sender: TObject; User: boolean);
  private
    OldFilter:AnsiString;
    OldParam:boolean;

    procedure ApplyLoadedLang(const alang:AnsiString);
    procedure ApplyLoadedTrans(const alang: AnsiString);
    procedure FillLocalesList;
    procedure FillTranslatorList;
    function GetSelectedTranslator: TTranslateBase;
    procedure LoadSettings();
    procedure SaveSettings();

  end;

var
  TL2Settings:TTL2Settings;

procedure SetProgramLanguage;
function Translate(const src:AnsiString):AnsiString;

implementation

{$R *.lfm}
uses
  inifiles,

  Translations,
  LCLTranslator,
  LCLType,
  LCLIntf,

  iso639,

  rgglobal,
  rgdb.text,
  TL2Text,
  TL2DataModule;

resourcestring
  rsSettings       = 'Settings';

  rsUseFreeKey    = 'Paid or Free Key (free)';
  rsUsePaidKey    = 'Paid or Free Key (paid)';

  rsRemakeFilter  = 'Rebuild templates...';

{ TTL2Settings }

var
  INIFileName:string;

const
  sNSBase       = 'Base';
  sSectSettings = 'Settings';
  sSectFont     = 'Font';
  sTranslation  = 'Translation';

  sFontName     = 'Name';
  sFontCharset  = 'Charset';
  sFontSize     = 'Size';
  sFontStyle    = 'Style';
  sFontColor    = 'Color';
  sTranslator   = 'Translator';
  sTransLang    = 'Language';
  sPrgTransLang = 'PrgLanguage';
  sFilter       = 'filter';
  sParam        = 'keepparam';
  sAutoPartial  = 'autoaspartial';
  sRemoveTags   = 'removetags';
  sFreeKey      = 'freekey';
  sPaidKey      = 'paidkey';
  sUsePaid      = 'usepaid';
  sDirectDB     = 'directDB';

//----- translation settings -----

const
  MyYandexAPIKey = 'trnsl.1.1.20200101T160123Z.3e57638fddd71006.49c9489591b0e6a07ab3e6cf12886b99fecdf26b';
//  AbramoffYandexAPIkey = 'trnsl.1.1.20140120T030428Z.c4c35e8a7d79c03e.defc651bed90c4424445c47be30e6b531bc4b063';
const
  TransList:array of string = (
    'Google'       ,
    'Yandex'       ,
    'DeepL'        ,
//    'Bing'         ,
//    'Babylon'      ,
//   'M-Translate'  ,
    'Translate',
    'MyMemory'
  );

//----- font settings -----

const
  DefFontName    = 'Arial Unicode MS'; // 'MS Sans Serif'
  DefFontCharset = DEFAULT_CHARSET;
  DefFontSize    = 10;
  DefFontStyle   = '';
  DefFontColor   = clWindowText;

//----- Settings -----

procedure SetProgramLanguage;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini'),[ifoEscapeLineFeeds,ifoStripQuotes]);
  SetDefaultLang(config.ReadString(sNSBase+':'+sTranslation,sPrgTransLang,GetLanguageID.LanguageID{'en'}));
  config.Free;
end;

procedure TTL2Settings.SaveSettings();
var
  ltr:TTranslateBase;
  config:TIniFile;
  ls:AnsiString;
  lstyle:TFontStyles;
  i:integer;
begin
  config:=TMemIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  //--- Options
  config.WriteBool(sNSBase+':'+sSectSettings,sAutoPartial,cbAsPartial  .Checked);
  config.WriteBool(sNSBase+':'+sSectSettings,sDirectDB   ,cbDiskDB     .Checked);

  //--- Font
  config.WriteString (sNSBase+':'+sSectFont,sFontName   ,TL2DM.TL2Font.Name);
  config.WriteInteger(sNSBase+':'+sSectFont,sFontCharset,TL2DM.TL2Font.Charset);
  config.WriteInteger(sNSBase+':'+sSectFont,sFontSize   ,TL2DM.TL2Font.Size);
  config.WriteString (sNSBase+':'+sSectFont,sFontColor  ,ColorToString(TL2DM.TL2Font.Color));

  lstyle:=TL2DM.TL2Font.Style;
  ls:='';
  if fsBold      in lstyle then ls:='bold ';
  if fsItalic    in lstyle then ls:=ls+'italic ';
  if fsUnderline in lstyle then ls:=ls+'underline ';
  if fsStrikeOut in lstyle then ls:=ls+'strikeout ';
  config.WriteString(sNSBase+':'+sSectFont,sFontStyle,ls);

  //--- Translation
  ls:=lbLanguage.Items[lbLanguage.ItemIndex];
  config.WriteString(sNSBase+':'+sTranslation,sPrgTransLang,copy(ls,1,pos(' ',ls)-1));
  config.WriteString(sNSBase+':'+sTranslation,sTransLang,edTransLang.Text);
  config.WriteString(sNSBase+':'+sTranslation,sTranslator,
    lbTranslators.Items[lbTranslators.ItemIndex]);

  for i:=0 to lbTranslators.Items.Count-1 do
  begin
    ls:=lbTranslators.Items[i];
    ltr:=TTranslateBase(lbTranslators.Items.Objects[i]);
    config.WriteString(sTranslation+':'+ls,sFreeKey,ltr.FreeKey);
    config.WriteString(sTranslation+':'+ls,sPaidKey,ltr.PaidKey);
    config.WriteBool  (sTranslation+':'+ls,sUsePaid,ltr.UsePaid);
  end;

  //--- Other
  config.WriteBool(sNSBase+':'+sSectSettings,sRemoveTags,cbRemoveTags.Checked);

  //--- Special
  config.WriteBool  (sNSBase+':'+sSectSettings,sParam ,cbParamSign.Checked);
  config.WriteString(sNSBase+':'+sSectSettings,sFilter,edFilterWords.Caption);
  if (OldFilter<>edFilterWords.Caption) or
     (OldParam <>cbParamSign.Checked) then
  begin
    SetFilterWords(TL2Settings.edFilterWords.Caption,cbParamSign.Checked);

    OldParam :=cbParamSign.Checked;
    OldFilter:=edFilterWords.Caption;
    ls:=Application.MainForm.Caption;
    Application.MainForm.Caption:=rsRemakeFilter;
    RemakeFilter();
    Application.MainForm.Caption:=ls;
  end;

  config.UpdateFile;

  config.Free;
end;

procedure TTL2Settings.LoadSettings();
var
  ltr:TTranslateBase;
  config:TIniFile;
  ls:AnsiString;
  lstyle:TFontStyles;
  i:integer;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  //--- Options
  cbAsPartial  .Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sAutoPartial,false);
  cbDiskDB     .Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sDirectDB   ,false);

//--- Font
  TL2DM.TL2Font.Name   :=config.ReadString (sNSBase+':'+sSectFont,sFontName   ,DefFontName);
  TL2DM.TL2Font.Charset:=config.ReadInteger(sNSBase+':'+sSectFont,sFontCharset,DefFontCharset);
  TL2DM.TL2Font.Size   :=config.ReadInteger(sNSBase+':'+sSectFont,sFontSize   ,DefFontSize);
  TL2DM.TL2Font.Color  :=StringToColor(
      config.ReadString(sNSBase+':'+sSectFont,sFontColor,ColorToString(DefFontColor)));

  ls:=config.ReadString(sNSBase+':'+sSectFont,sFontStyle,DefFontStyle);
  lstyle:=[];
  if Pos('bold'     ,ls)<>0 then lstyle:=lstyle+[fsBold];
  if Pos('italic'   ,ls)<>0 then lstyle:=lstyle+[fsItalic];
  if Pos('underline',ls)<>0 then lstyle:=lstyle+[fsUnderline];
  if Pos('strikeout',ls)<>0 then lstyle:=lstyle+[fsStrikeOut];
  TL2DM.TL2Font.Style:=lstyle;

  //--- Other
  cbRemoveTags.Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sRemoveTags,true);

  //--- Special
  cbParamSign.Checked  :=config.ReadBool  (sNSBase+':'+sSectSettings,sParam ,false);
  edFilterWords.Caption:=config.ReadString(sNSBase+':'+sSectSettings,sFilter,defFilter);
  OldFilter:=edFilterWords.Caption;
  OldParam :=cbParamSign.Checked;

  //--- Translation
  for i:=0 to lbTranslators.Items.Count-1 do
  begin
    ls:=lbTranslators.Items[i];
    ltr:=TTranslateBase(lbTranslators.Items.Objects[i]);
    ltr.FreeKey:=config.ReadString(sTranslation+':'+ls,sFreeKey,'');
    ltr.PaidKey:=config.ReadString(sTranslation+':'+ls,sPaidKey,'');
    ltr.UsePaid:=config.ReadBool  (sTranslation+':'+ls,sUsePaid,false);

    if (ltr.FreeKey='') and
       (ltr.PaidKey='') and
       (LowerCase(ls)='yandex') then
      ltr.FreeKey:=MyYandexAPIKey;
  end;

  edTransLang.Text:=config.ReadString(sNSBase+':'+sTranslation,sTransLang   ,'');
  ApplyLoadedLang ( config.ReadString(sNSBase+':'+sTranslation,sPrgTransLang,'en'));
  ApplyLoadedTrans( config.ReadString(sNSBase+':'+sTranslation,sTranslator  ,'Google'));

  config.Free;

  SetFilterWords(TL2Settings.edFilterWords.Caption,cbParamSign.Checked);

//  ls:=edDefaultFile.Text;
//  edDefaultFileAcceptFileName(Self, ls);
end;

//----- Other -----

procedure TTL2Settings.cbDiskDBClick(Sender: TObject);
begin
  // was in memory and something was changed
  if cbDiskDB.Checked and (SQLog.Size<>0) then
    TLSaveBase();

  TLCloseBase(false);
  TLOpenBase(not cbDiskDB.Checked);
end;

procedure TTL2Settings.bbSaveSettingsClick(Sender: TObject);
begin
  SaveSettings;
end;

procedure TTL2Settings.btnFontEditClick(Sender: TObject);
var
  FontDialog:TFontDialog;
begin
  FontDialog:=TFontDialog.Create(nil);
  try
    FontDialog.Font.Assign(TL2DM.TL2Font);
    if FontDialog.Execute then
    begin
      TL2DM.TL2Font.Assign(FontDialog.Font);
      Application.MainForm.Font.Assign(TL2DM.TL2Font);
    end;
  finally
    FontDialog.Free;
  end;
end;

procedure TTL2Settings.edDefaultFileAcceptFileName(Sender: TObject; var Value: String);
begin
  if Value<>'' then
  begin
{
    BaseTranslation.Free;
    BaseTranslation.Init;
    BaseTranslation.Filter:=flNoSearch;
    BaseTranslation.Mode  :=tmDefault;
    if BaseTranslation.LoadFromFile(Value)<0 then ;
}
  end;
end;

//----- Localization -----

procedure TTL2Settings.ApplyLoadedLang(const alang:AnsiString);
var
  ls:AnsiString;
  i,idx:integer;
begin
  idx:=0;
  for i:=0 to lbLanguage.Items.Count-1 do
  begin
    ls:=lbLanguage.Items[i];
    if alang=copy(ls,1,pos(' ',ls)-1) then
    begin
      idx:=i;
      break;
    end;
  end;
  lbLanguage.ItemIndex:=idx;
//  lbLanguageSelectionChange(Sender: TObject; User: boolean);
//  SetDefaultLang(copy(ls,1,pos(' ',ls)-1));
end;

procedure TTL2Settings.lbLanguageSelectionChange(Sender: TObject; User: boolean);
var
  ls:AnsiString;
begin
  ls:=lbLanguage.Items[lbLanguage.ItemIndex];
  SetDefaultLang(copy(ls,1,pos(' ',ls)-1));
  Caption:=rsSettings;
  if Parent<>nil then
    Parent.Caption:=rsSettings;
end;

procedure TTL2Settings.FillLocalesList;
var
  sr:TSearchRec;
  lname:AnsiString;
  i:integer;
begin
  lbLanguage.Clear;
  lbLanguage.AddItem('en - English',nil);
  if FindFirst(ExtractPath(ParamStr(0))+'languages\*.po',faAnyFile,sr)=0 then
  begin
    repeat
      lname:=sr.Name;
      i:=Length(lname)-4;
      while (i>0) and (lname[i]<>'.') do dec(i);
      lname:=Copy(lname,i+1,Length(lname)-i-3);
      lbLanguage.AddItem(lname+' - '+iso639.GetLangName(lname),nil);
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
//  lbLanguage.ItemIdex:=0;
end;

//----- Translation -----

function Translate(const src:AnsiString):AnsiString;
var
  ltr:TTranslateBase;
  ls:string;
  lcode:integer;
begin
  result:=src;

  if TL2Settings.cbRemoveTags.Checked then
    ls:=RemoveTags(src)
  else
    ls:=src;

  ltr:=TL2Settings.GetSelectedTranslator();

  // Skip NIL checking for now
  ltr.LangSrc :='en'; // set to "auto" if national?
  ltr.LangDst :=CurLang;//TL2Settings.edTransLang.Text;
  ltr.Original:=ls;
  lcode:=ltr.Translate;
  if lcode<>0 then
    ShowMessage('Error ('+IntToStr(lcode)+'): '+ltr.ResultNote)
  else
    result:=ltr.Translated;
end;

procedure TTL2Settings.ApplyLoadedTrans(const alang:AnsiString);
var
  ls:AnsiString;
  i,idx:integer;
begin
  idx:=0;
  ls:=LowerCase(alang);
  for i:=0 to lbTranslators.Items.Count-1 do
  begin
    if ls=LowerCase(lbTranslators.Items[i]) then
    begin
      idx:=i;
      break;
    end;
  end;
  lbTranslators.ItemIndex:=idx;
end;

function TTL2Settings.GetSelectedTranslator:TTranslateBase;
begin
  result:=TTranslateBase(lbTranslators.Items.Objects[lbTranslators.ItemIndex]);
end;

procedure TTL2Settings.cbAPIKeyChange(Sender: TObject);
var
  ltr:TTranslateBase;
begin
  ltr:=GetSelectedTranslator();

  ltr.UsePaid:=cbAPIKey.Checked;

  if cbAPIKey.Checked then
  begin
    cbAPIKey.Caption:=rsUsePaidKey;
    memAPIKey.Text:=ltr.PaidKey;
  end
  else
  begin
    cbAPIKey.Caption:=rsUseFreeKey;
    memAPIKey.Text:=ltr.FreeKey;
  end;
  lblGetAPIKey.Visible:=(cbAPIKey.Checked  and (ltr.PaidKeyURL<>'')) or
                   ((not cbAPIKey.Checked) and (ltr.FreeKeyURL<>''));
end;

procedure TTL2Settings.lblGetAPIKeyClick(Sender: TObject);
var
  ltr:TTranslateBase;
  lurl:string;
begin
  ltr:=GetSelectedTranslator();

  if cbAPIKey.Checked then
    lurl:=ltr.PaidKeyURL
  else
    lurl:=ltr.FreeKeyURL;

  OpenURL(lurl);
end;

procedure TTL2Settings.lbTranslatorsSelectionChange(Sender: TObject; User: boolean);
var
  ltr:TTranslateBase;
begin
  ltr:=GetSelectedTranslator();

  lblTitle.Caption:=ltr.Name;
  lblDescr.Caption:=ltr.Descr;
  lblNote.Caption :=ltr.Notes;

  if (trFreeKey in ltr.Supported) or (trPaidKey in ltr.Supported) then
  begin
    cbAPIKey.Enabled:=(trFreeKey in ltr.Supported) and (trPaidKey in ltr.Supported);
    cbAPIKey.Checked:=ltr.UsePaid;  // must checked at setup
    cbAPIKeyChange(cbAPIKey);
//    if cbAPIKey.Checked then memAPIKey.Text:=ltr.PaidKey
//    else                     memAPIKey.Text:=ltr.FreeKey;
    cbAPIKey .Visible:=true;
    memAPIKey.Visible:=true;
  end
  else
  begin
    cbAPIKey    .Visible:=false;
    memAPIKey   .Visible:=false;
    lblGetAPIKey.Visible:=false;
  end;
end;

procedure TTL2Settings.FillTranslatorList;
var
  i:integer;
begin
  lbTranslators.Clear;

  for i:=0 to High(TransList) do
    lbTranslators.AddItem(TransList[i],TObject(CreateTranslatorByName(TransList[i])));

  lbTranslators.ItemIndex:=0;
end;

//----- Base -----

procedure TTL2Settings.FormCreate(Sender: TObject);
begin
  TL2Settings:=Self;

  INIFileName:=ChangeFileExt(ParamStr(0),'.ini');

  FillLocalesList;
  FillTranslatorList;
  LoadSettings;
end;

procedure TTL2Settings.FormDestroy(Sender: TObject);
var
  i:integer;
begin
  for i:=0 to lbTranslators.Items.Count-1 do
    TTranslateBase(lbTranslators.Items.Objects[i]).Free;
end;

end.
