unit TL2SettingsForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  Buttons;

const
  DefaultExt    = '.DAT';
  DefaultFilter = 'DAT files|*.DAT';

type

  { TTL2Settings }

  TTL2Settings = class(TForm)
    bbSaveSettings: TBitBtn;
    bbFontEdit: TBitBtn;
    cbExportParts: TCheckBox;
    cbKeepSpaces: TCheckBox;
    cbImportParts: TCheckBox;
    edImportDir: TDirectoryEdit;
    edDefaultFile: TFileNameEdit;
    edFilterWords: TEdit;
    edTransLang: TEdit;
    edRootDir: TDirectoryEdit;
    edWorkDir: TDirectoryEdit;
    gbTranslate: TGroupBox;
    lblImportDir: TLabel;
    lblFilterNote: TLabel;
    lblFilter: TLabel;
    lblYandexNote: TLabel;
    lblGetAPIKey: TLabel;
    lblLang: TLabel;
    lblAPIKey: TLabel;
    lbAddFileList: TListBox;
    lblAddFile: TLabel;
    lblDefaultFile: TLabel;
    lblRootDirectory: TLabel;
    lblWorkDirectory: TLabel;
    memAPIKey: TMemo;
    sbAddonAdd: TSpeedButton;
    sbAddonDel: TSpeedButton;
    sbAddonDown: TSpeedButton;
    sbAddonUp: TSpeedButton;
    procedure bbSaveSettingsClick(Sender: TObject);
    procedure btnFontEditClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lblGetAPIKeyClick(Sender: TObject);
    procedure sbAddonAddClick(Sender: TObject);
    procedure sbAddonDelClick(Sender: TObject);
    procedure TL2ArrowDownClick(Sender: TObject);
    procedure TL2ArrowUpClick(Sender: TObject);
  private
    procedure LoadSettings();
    procedure SaveSettings();

  public
  end;

var
  TL2Settings:TTL2Settings;

function TranslateYandex(const src:AnsiString):AnsiString;

implementation

{$R *.lfm}
uses
  fphttpclient,
  opensslsockets,
  jsontools,

  LCLType,
  LCLIntf,
  TL2DataModule,
  cfgbase,iniconfig;

//----- Translation -----

const
  y_host = 'https://translate.yandex.net/api/v1.5/tr.json/translate';
  y_key  = '?key=';
  y_lang = '&lang=en-';
  y_text = '&text=';

resourcestring
  sYWrongAPIKey   = 'Wrong API key';
  sYKeyBlocked    = 'API key blocked';
  sYTooMuchText   = 'Day text potion out of limit';
  sYTooLongText   = 'Text length too large';
  sYCantTranslate = 'Text can''t be translated';
  sYWrongLanguage = 'Choosen language is unsupported';
  sUnknownError   = 'Unknown Error';
{
200	- Операция выполнена успешно
401	- Неправильный API-ключ
402	- API-ключ заблокирован
404	- Превышено суточное ограничение на объем переведенного текста
413	- Превышен максимально допустимый размер текста
422	- Текст не может быть переведен
501	- Заданное направление перевода не поддерживается
}
function TranslateYandex(const src:AnsiString):AnsiString;
var
  res:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
  code:integer;
begin
  result:='';

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=5000;
    res:=ltr.Post(
        y_host+
        y_key +TL2Settings.memAPIKey.Text+
        y_lang+TL2Settings.edTransLang.Text+
        y_text+EncodeURLElement(src));

    jn:=TJsonNode.Create;
    try
      if jn.TryParse(res) then
      begin
        code:=round(jn.Child('code').AsNumber);
        if code=200 then
          result:=jn.Child('text').AsArray.Child(0).AsString
        else
        begin
          case code of
            401: res:=sYWrongAPIKey;
            402: res:=sYKeyBlocked;
            404: res:=sYTooMuchText;
            413: res:=sYTooLongText;
            422: res:=sYCantTranslate;
            501: res:=sYWrongLanguage;
          else
            res:=sUnknownError+' '+IntToStr(code);
          end;
          ShowMessage(res);
        end;
      end;
    finally
      jn.Free;
    end;
  except
  end;
  ltr.Free;
end;

{ TTL2Settings }

resourcestring
  sOpenAddon = 'Choose additional file';

var
  config:tCfgBase;

const
  DefDATFile = 'TRANSLATION.DAT';
  INIFileName = 'TL2Trans.ini';

const
  sNSBase       = 'Base';
  sSectSettings = 'Settings';
  sSectFont     = 'Font';
  sSectAddon    = 'Addons';
  sTranslation  = 'Translation';

  sFile        = 'file';
  sAddFiles    = 'addfiles';
  sDefFile     = 'defaultfile';
  sRootDir     = 'rootdir';
  sWorkDir     = 'workdir';
  sImportDir   = 'importdir';
  sExportParts = 'exportparts';
  sKeepSpaces  = 'keepspaces';
  sImportParts = 'importparts';
  sFontName    = 'Name';
  sFontCharset = 'Charset';
  sFontSize    = 'Size';
  sFontStyle   = 'Style';
  sFontColor   = 'Color';
  sYAPIKey     = 'YandexAPIKey';
  sTransLang   = 'Language';
  sFilter      = 'filter';

const
  defFilter = 'a an the of by to for his her their';

const
  YandexKeyURL   = 'https://translate.yandex.ru/developers/keys';
  MyYandexAPIKey = 'trnsl.1.1.20200101T160123Z.3e57638fddd71006.49c9489591b0e6a07ab3e6cf12886b99fecdf26b';
//  akey='trnsl.1.1.20140120T030428Z.c4c35e8a7d79c03e.defc651bed90c4424445c47be30e6b531bc4b063';
  MyLanguage     = 'ru';

//----- default settings -----

const
  DefFontName    = 'Arial Unicode MS'; // 'MS Sans Serif'
  DefFontCharset = DEFAULT_CHARSET;
  DefFontSize    = 10;
  DefFontStyle   = '';
  DefFontColor   = clWindowText;

//----- Settings -----

procedure TTL2Settings.SaveSettings();
var
  ls:AnsiString;
  lstyle:TFontStyles;
  i:integer;
begin
  //--- Main
  config.WriteString(sNSBase,sSectSettings,sDefFile  ,edDefaultFile.Text);
  config.WriteString(sNSBase,sSectSettings,sRootDir  ,edRootDir    .Text);
  config.WriteString(sNSBase,sSectSettings,sWorkDir  ,edWorkDir    .Text);
  config.WriteString(sNSBase,sSectSettings,sImportDir,edImportDir  .Text);

  //--- Options
  config.WriteBool(sNSBase,sSectSettings,sExportParts,cbExportParts.Checked);
  config.WriteBool(sNSBase,sSectSettings,sKeepSpaces ,cbKeepSpaces .Checked);
  config.WriteBool(sNSBase,sSectSettings,sImportParts,cbImportParts.Checked);

  //--- Addons
  config.DeleteSection(sNSBase,sSectAddon);
  config.WriteInt(sNSBase,sSectAddon,sAddFiles,lbAddFileList.Count);
  for i:=0 to lbAddFileList.Count-1 do
    config.WriteString(sNSBase,sSectAddon,
    pointer(sFile+IntToStr(i)),lbAddFileList.Items[i]);

  //--- Font
  config.WriteString(sNSBase,sSectFont,sFontName   ,TL2DM.TL2Font.Name);
  config.WriteInt   (sNSBase,sSectFont,sFontCharset,TL2DM.TL2Font.Charset);
  config.WriteInt   (sNSBase,sSectFont,sFontSize   ,TL2DM.TL2Font.Size);
  config.WriteString(sNSBase,sSectFont,sFontColor  ,ColorToString(TL2DM.TL2Font.Color));

  lstyle:=TL2DM.TL2Font.Style;
  ls:='';
  if fsBold      in lstyle then ls:='bold ';
  if fsItalic    in lstyle then ls:=ls+'italic ';
  if fsUnderline in lstyle then ls:=ls+'underline ';
  if fsStrikeOut in lstyle then ls:=ls+'strikeout ';
  config.WriteString(sNSBase,sSectFont,sFontStyle,ls);

  //--- Translation
  config.WriteString(sNSBase,sTranslation,sYAPIKey  ,memAPIKey  .Text);
  config.WriteString(sNSBase,sTranslation,sTransLang,edTransLang.Text);

  //--- Special
  config.WriteString(sNSBase,sSectSettings,sFilter,edFilterWords.Caption);

  SaveINIFile(@config,INIFileName);
end;

procedure TTL2Settings.LoadSettings();
var
  ls:AnsiString;
  lstyle:TFontStyles;
  i,lcnt:integer;
begin
  LoadINIFile(@config,INIFileName);

  //--- Main
  edDefaultFile.Text:=config.ReadString(sNSBase,sSectSettings,sDefFile  ,DefDATFile);
  edRootDir    .Text:=config.ReadString(sNSBase,sSectSettings,sRootDir  ,'');
  edWorkDir    .Text:=config.ReadString(sNSBase,sSectSettings,sWorkDir  ,GetCurrentDir());
  edImportDir  .Text:=config.ReadString(sNSBase,sSectSettings,sImportDir,edWorkDir.Text);

  //--- Options
  cbExportParts.Checked:=config.ReadBool(sNSBase,sSectSettings,sExportParts);
  cbKeepSpaces .Checked:=config.ReadBool(sNSBase,sSectSettings,sKeepSpaces ,true);
  cbImportParts.Checked:=config.ReadBool(sNSBase,sSectSettings,sImportParts);

  //--- Addons
  lcnt:=config.ReadInt(sNSBase,sSectAddon,sAddFiles);
  lbAddFileList.Clear;
  for i:=0 to lcnt-1 do
  begin
    lbAddFileList.AddItem(
        config.ReadString(sNSBase,sSectAddon,
        pointer(sFile+IntToStr(i))),nil);
  end;

//--- Font
  TL2DM.TL2Font.Name   :=config.ReadString(sNSBase,sSectFont,sFontName   ,DefFontName);
  TL2DM.TL2Font.Charset:=config.ReadInt   (sNSBase,sSectFont,sFontCharset,DefFontCharset);
  TL2DM.TL2Font.Size   :=config.ReadInt   (sNSBase,sSectFont,sFontSize   ,DefFontSize);
  TL2DM.TL2Font.Color  :=StringToColor(
      config.ReadString(sNSBase,sSectFont,sFontColor,ColorToString(DefFontColor)));

  ls:=config.ReadString(sNSBase,sSectFont,sFontStyle,DefFontStyle);
  lstyle:=[];
  if Pos('bold'     ,ls)<>0 then lstyle:=lstyle+[fsBold];
  if Pos('italic'   ,ls)<>0 then lstyle:=lstyle+[fsItalic];
  if Pos('underline',ls)<>0 then lstyle:=lstyle+[fsUnderline];
  if Pos('strikeout',ls)<>0 then lstyle:=lstyle+[fsStrikeOut];
  TL2DM.TL2Font.Style:=lstyle;

  //--- Translation
  memAPIKey  .Text:=config.ReadString(sNSBase,sTranslation,sYAPIKey  ,MyYandexAPIKey);
  edTransLang.Text:=config.ReadString(sNSBase,sTranslation,sTransLang,MyLanguage);

  //--- Special
  edFilterWords.Caption:=config.ReadString(sNSBase,sSectSettings,sFilter,defFilter);
end;

//----- Other -----

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

//----- Addon file list -----

procedure TTL2Settings.sbAddonAddClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  fcnt:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.DefaultExt:=DefaultExt;
    OpenDialog.Filter    :=DefaultFilter;
    OpenDialog.Title     :=sOpenAddon;
    OpenDialog.InitialDir:=edWorkDir.Text;
    OpenDialog.Options   :=[ofNoChangeDir,ofAllowMultiSelect];

    if OpenDialog.Execute then
    begin
      for fcnt:=0 to OpenDialog.Files.Count-1 do
        lbAddFileList.AddItem(ExtractFileName(OpenDialog.Files[fcnt]),nil);

      lbAddFileList.ItemIndex:=lbAddFileList.Count-1;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TTL2Settings.sbAddonDelClick(Sender: TObject);
begin
  if lbAddFileList.ItemIndex>=0 then
  begin
    lbAddFileList.DeleteSelected;
  end;
end;

procedure TTL2Settings.TL2ArrowDownClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=lbAddFileList.ItemIndex;
  if (lidx>=0) and (lidx<(lbAddFileList.Count-1)) then
  begin
    lbAddFileList.Items.Move(lidx,lidx+1);
    lbAddFileList.ItemIndex:=lidx+1;
  end;
end;

procedure TTL2Settings.TL2ArrowUpClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=lbAddFileList.ItemIndex;
  if lidx>0 then
  begin
    lbAddFileList.Items.Move(lidx,lidx-1);
    lbAddFileList.ItemIndex:=lidx-1;
  end;
end;

//----- Translation -----

procedure TTL2Settings.lblGetAPIKeyClick(Sender: TObject);
begin
  OpenURL(YandexKeyURL);
//  ShellExecute(0, 'OPEN', PChar(YandexKeyURL), '', '', SW_SHOWNORMAL);
end;

//----- Base -----

procedure TTL2Settings.FormCreate(Sender: TObject);
begin
  TL2Settings:=Self;

  CreateConfig(config,[CFG_USENAMESPACE]);
  edDefaultFile.Filter:=DefaultFilter;
  edDefaultFile.DefaultExt:=DefaultExt;

  LoadSettings;
end;

procedure TTL2Settings.FormDestroy(Sender: TObject);
begin
//  SaveSettings;
  FreeConfig(config);
end;

end.

