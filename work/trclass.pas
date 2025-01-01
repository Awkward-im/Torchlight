{$H+}
unit TRClass;

interface

const
  DefaultTimeout = 5000;
  DefaultResCode = 1;

type
  TTransType = (
    trTranslate,  // text translation
    trDetect,     // autodetect ability (NOT "detect" method, it virtual, can be overrided)
    trDictionary, // dictionary
    trTTS,        // TTS
    trWeb,        // web page translation
    trDocument    // file (documents) translation
  );
  TTranslateType = set of TTransType;

type
  TTranslateBase = class
  private
    //--- Common
    FName  :string;
    FDescr :string;
    FNotes :string;                                    // limits etc
    FSite  :string;                                    // translator site
    FHost  :string;                                    // request base host

    // can be use for reading
    FDocURL:string;                                    // API/usage documentation URL
    FKeyURL:string;                                    // key/id registering URL

    FTimeout:integer;
    FAPIKey :string;                                   // APIkey or AppId - same storage?
    // language
    FAuto   :boolean;
    FFrom,
    FTo     :string;
    // text
    FText,
    FOut    :string;
    // Error description
    FResult :string;

    FSupport:TTranslateType;

    //--- Web (page translation)
//    FWebHost:string;
    //--- Documents
    //--- Dictionary
    //--- TTS
//    FTTSURL:string;

    function GetResultDescr:string;

    procedure SetLang(index:integer; const alang:string); virtual;
    procedure SetAuto(aval:boolean);

  public
    // Main methods
    constructor Create; 

    function Detect   :boolean; virtual;               // Detect language of text
    function Translate:integer; virtual;               // Translate text

    //--- properties
    // common
    property Timeout:integer read FTimeout write FTimeout default DefaultTimeout;

    // changeable
    property LangAuto:boolean        read FAuto write SetAuto;
    property LangSrc :string index 0 read FFrom write SetLang;
    property LangDst :string index 1 read FTo   write SetLang;

    property Key:string read FAPIKey write FAPIKey;    // API key (if presents)

    // process
    property Original  :string read FText write FText; // Original text
    property Translated:string read FOut;              // Translated text
    property ResultNote:string read GetResultDescr;    // Translation result description

    // personal
    property Site :string read FSite;
    property Name :string read FName;
    property Descr:string read FDescr;
    property Notes:string read FNotes;

    property Supported:TTranslateType read FSupport;
  end;


//----- DeepL -----

type
  TTranslateDeepL = class(TTranslateBase)
  private

  public
    constructor Create;

//    function Detect   :boolean; override;
    function Translate:integer; override;
  end;

//----- Yandex -----
(*
  TTS: https://tts.voicetech.yandex.net/tts?format=mp3&quality=hi&platform=web&application=translate'
  '&lang={from}-{to}&text={text}&speed=0.7'
*)
type
  TTranslateYandex = class(TTranslateBase)
  private
//    Fv1KeyURL:string;
    FAppId:string;

  public
    constructor Create;

    function Detect   :boolean; override;
    function Translate:integer; override;
  end;

//----- MyMemory -----

type
  TTranslateMyMemory = class(TTranslateBase)
  private
    FEmail:string;
  public
    constructor Create;

    function Translate:integer; override;

    property Email:string read FEmail write FEmail;
  end;

//----- Google -----

(*
TTS: '/translate_tts?ie=UTF-8&q={text}&tl={to}&client=webapp&ttsspeed=0.24';
TTS: 'https://translate.googleapis.com/translate_tts?ie=UTF-8&client=gtx&sl={from}&tl={to}&q={text}&ttsspeed=0.24'
WEB: 'https://translate.google.com/translate?hl=en&sl={from}&tl={to}&u={url}'
      https://translate.google.com/translate?u={url}&langpair={from}%7C{to}&ie=UTF-8&oe=UTF-8
*)
type
  TTranslateGoogle = class(TTranslateBase)
  private
    FAPIv2Host:string;

    procedure SetLang(index:integer; const alang:string); override;
  public
    constructor Create;

    function Detect   :boolean; override;
    function Translate:integer; override;
  end;

//----- Translate -----

type
  TTranslateTranslate = class(TTranslateBase)
  private
  public
    constructor Create;

    function Translate:integer; override;
  end;

{%REGION Deprecated /fold}

//----- Babylon -----

type
  TTranslateBabylon = class(TTranslateBase)
  private
    procedure SetLang(index:integer; const alang:string); override;
  public
    constructor Create;

    function Translate:integer; override;
  end;

//----- Bing -----

type
  TTranslateBing = class(TTranslateBase)
  private
    procedure SetLang(index:integer; const alang:string); override;
  public
    constructor Create;

    function Detect   :boolean; override;
    function Translate:integer; override;
  end;

//----- M-Translate -----

type
  TTranslateMTranslate = class(TTranslateBase)
  private
  public
    constructor Create;

    function Translate:integer; override;
  end;
{%ENDREGION Deprecated}

//==============================================================================

implementation

uses
  sysutils,
  classes,
  fphttpclient,
  opensslsockets,
  jsontools,
  iso639
  ;

resourcestring
  sWrongAPIKey    = 'Wrong API key';
  sKeyBlocked     = 'API key blocked';
  sTooMuchText    = 'Day text potion out of limit';
  sTooLongText    = 'Text length too large';
  sTooManyRequest = 'Too many requests. Please wait and resend your request.';
  sCantTranslate  = 'Text can''t be translated';
  sWrongLanguage  = 'Choosen language is unsupported';
  sUnknownError   = 'Unknown Error';

{%REGION Base}
constructor TTranslateBase.Create;
begin
  inherited;

  FTimeout := DefaultTimeout;
  FAuto    := false;

  FName   := 'default';
  FDescr  := 'Base translation handler';
  //
  FSite   := '';
  FHost   := '';
  FDocURL := '';
  FKeyURL := '';

  FSupport := [];
end;

procedure TTranslateBase.SetAuto(aval:boolean);
begin
  if not (trDetect in FSupport) then
    FAuto:=false
  else
    FAuto:=aval;
end;

procedure TTranslateBase.SetLang(index:integer; const alang:string);
var
  llang:string;
begin
  llang:=LowerCase(alang);
  if llang='auto' then
  begin
    if index=0 then
      FAuto:=true; // will changed in custom
  end
  else
  begin
    if index=0 then
    begin
      if llang<>FFrom then
      begin
        FFrom:=iso639.GetLang(llang);
        FAuto:=FFrom='';
      end;
    end
    else if llang<>FTo then
      FTo:=iso639.GetLang(llang);
  end;
end;

function TTranslateBase.Detect:boolean;
begin
  result:=false;
end;

function TTranslateBase.Translate:integer;
begin
  FResult:='';
  if (FFrom=FTo) or (FText='') then
  begin
    FOut:=FText;
    result:=0;
  end
  else
  begin
    FOut:='';
    result:=DefaultResCode;

    if (FTo='') or ((FFrom='') and
       (not (FAuto and (trDetect in FSupport)))) then FResult:=sWrongLanguage
    else if not     (trTranslate in FSupport)    then FResult:=sCantTranslate;
  end;
end;

function TTranslateBase.GetResultDescr:string;
begin
  result:=FResult;
end;
{%ENDREGION Base}

//==============================================================================

{%REGION Deprecated /fold}

{%REGION Babylon}
const
  SupLangBabylon: array of packed record lang:array [0..1] of char; code:word; end = (
   (lang:'en';code: 0), (lang:'ru';code: 7), (lang:'ar';code:15), (lang:'ca';code:99),
   (lang:'zh';code:10), (lang:'cs';code:31), (lang:'da';code:43), (lang:'nl';code: 4),
   (lang:'de';code: 6), (lang:'el';code:11), (lang:'he';code:14), (lang:'hi';code:60),
   (lang:'hu';code:30), (lang:'it';code: 2), (lang:'ja';code: 8), (lang:'ko';code:12),
   (lang:'no';code:46), (lang:'fa';code:51), (lang:'pl';code:29), (lang:'pt';code: 5),
   (lang:'ro';code:47), (lang:'es';code: 3), (lang:'sv';code:48), (lang:'th';code:16),
   (lang:'tr';code:13), (lang:'uk';code:49), (lang:'ur';code:39)
  );

constructor TTranslateBabylon.Create;
begin
  inherited;

  FName  := 'Babylon';
  FDescr := 'Search for literally millions of terms in Babylon''s database of over 1,600 '+
            'dictionaries and glossaries from the most varied fields of information. '+
            'All in more than 75 languages.';
  FHost  := 'https://translation.babylon-software.com/';

  FSupport := [trTranslate];
end;

procedure TTranslateBabylon.SetLang(index:integer; const alang:string);
var
  llang:string;
  ls:string[3];
  i,j:integer;
begin
  llang:=LowerCase(alang);

  i:=-1;
  case llang of
    'zh-cn': i:=10;
    'zh-tw': i:=9;
  else
    ls:=iso639.GetLangA2(llang);
    if ls<>'' then
    begin
      for j:=0 to High(SupLangBabylon) do
      begin
        if (ls[1]=SupLangBabylon[j].lang[0]) and
           (ls[2]=SupLangBabylon[j].lang[1]) then
        begin
          i:=SupLangBabylon[j].code;
          break;
        end;
      end;
    end;
  end;

  if i>=0 then
  begin
    Str(i,ls);
    if index=0 then
      FFrom:=ls
    else
      FTo:=ls;
  end;
end;

function TTranslateBabylon.Translate:integer;
var
  ls:string;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:='translate/babylon.php?v=1.0&callback=callbackFn&context=babylon'+
        '&langpair={from}%7C{to}&q={text}';

    ls:=StringReplace(ls,'{to}'  ,FTo  ,[]);
    ls:=StringReplace(ls,'{from}',FFrom,[]);
    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

    ls:=ltr.Get(FHost+ls);

    ls:=Copy(ls,11); // skip 'callbackFn'
    SetLength(ls,Length(ls)-1);
    ls[1]:='[';
    ls[Length(ls)]:=']';

    jn:=TJsonNode.Create;
    try
      if jn.TryParse(ls) then
      begin
        result:=round(jn.AsArray.Child(2).AsNumber);
        if result=200 then
        begin
          FOut:=jn.AsArray.Child(1).Child('translatedText').AsString;
          FResult:='';
          result:=0;
        end
        else
          FResult:=sUnknownError+' '+IntToStr(result);
      end;
    finally
      jn.Free;
    end;

  except
  end;
  ltr.Free;
end;
{%ENDREGION Babylon}

{%REGION Bing not working}
constructor TTranslateBing.Create;
begin
  inherited;

  FName  := 'Bing';
  FDescr := 'Microsoft Translator is a cloud service that translates between 60+ languages.';
  FHost  := 'https://www.bing.com/';

  FDocURL   := '';
  FKeyURL   := '';

  FSupport := [trTranslate,trDetect];
end;

procedure TTranslateBing.SetLang(index:integer; const alang:string);
var
  llang:string;
begin
  llang:=LowerCase(alang);

  case llang of
    'zh-cn': llang:='zh-Hans';
    'zh-tw': llang:='zh-Hant';
  else
    inherited SetLang(index,alang);
    // here lang separated to [From/To] already
    if index=0 then
    begin
      case FFrom of
        'bs': FFrom:='bs-Latn';
        'no': FFrom:='nb';      //?? awk, not js
        'pt': FFrom:='pt-pt';   //?? awk, not js
        'sr': FFrom:='sr-Cyrl'; //?? js, not awk
      end;
    end
    else
    begin
      case FTo of
        'bs': FTo:='bs-Latn';
        'no': FTo:='nb';      //?? awk, not js
        'pt': FTo:='pt-pt';   //?? awk, not js
        'sr': FTo:='sr-Cyrl'; //?? js, not awk
      end;
    end;

    exit;
  end;

  if index=0 then
    FFrom:=llang
  else
    FTo:=llang;
end;

function TTranslateBing.Detect:boolean;
{
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
}
begin
  result:=inherited;
(*
  result:=false;
  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:=FDetect;

    ls:=StringReplace(ls,'{from}','auto-detect',[])
    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

    ls:=ltr.FormPost(FHost,ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
*)
end;

function TTranslateBing.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:='text={text}&fromLang={from}&to={to}';

    ls:=StringReplace(ls,'{to}',FTo,[]);
    if FAuto then
    begin
      ls:=StringReplace(ls,'{from}','auto-detect',[])
    end
    else
      ls:=StringReplace(ls,'{from}',FFrom,[]);

    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

    ls:=ltr.FormPost(FHost+'ttranslatev3/',ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
          if FAuto then
          begin
            jl:=jn.Find('0/detectedLanguage/language');
            if jl<>nil then
              FFrom:=jl.AsString;
          end;
          jl:=jn.Find('0/translations/0/text');
          if jl<>nil then
          begin
            FOut   :=jl.AsString;
            result :=0;
            FResult:='';
          end;
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
end;
{%ENDREGION Bing}

{%REGION MTranslate}
constructor TTranslateMTranslate.Create;
begin
  inherited;

  FName  := 'M-Translate';
  FDescr := '(microsoft)';
  FHost  := 'https://www.m-translate.com/';

  FSupport := [trTranslate,trDetect];
end;

function TTranslateMTranslate.Translate:integer;
var
  ls:string;
  ltr:TFPHTTPClient;
  jn,jl:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:='translate_to={to}&translate_from={from}&text={text}';

    ls:=StringReplace(ls,'{to}',FTo,[]);
    if FAuto then
      ls:=StringReplace(ls,'{from}','',[])
    else
      ls:=StringReplace(ls,'{from}',FFrom,[]);

    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

    ls:=ltr.FormPost(FHost+'translate',ls);

    jn:=TJsonNode.Create;
    try
      if jn.TryParse(ls) then
      begin
        if FAuto then
        begin
          jl:=jn.Child('detected_lang');
          if jl<>nil then
            FFrom:=jl.AsString;
        end;
        FOut:=jn.Child(0).AsString; // or Child('translate')
        FResult:='';
        result:=0;
      end;
    finally
      jn.Free;
    end;

  except
  end;
  ltr.Free;
end;
{%ENDREGION MTranslate}

{%ENDREGION Deprecated}

{%REGION DeepL}
(*
DeepL API Free authentication keys can be identified easily by the suffix ":fx"
(e.g., 279a2e9d-83b3-c416-7e2d-f721593e42a0:fx)
*)
constructor TTranslateDeepL.Create;
const
  DeepLAPIURL_Free = 'https://api-free.deepl.com/v2/';
  DeepLAPIURL_Pro  = 'https://api.deepl.com/v2/';
  DeepLAPIURL_Web  = 'https://www.deepl.com/translator';
begin
  inherited;

  FName  := 'DeepL';
  FDescr := 'DeepL trains artificial intelligence to understand and translate texts.';

  FSite  := 'https://www.deepl.com/translator';
  FHost  := DeepLAPIURL_Free;

  FDocURL := 'https://developers.deepl.com/docs';
  FKeyURL := 'https://www.deepl.com/your-account/keys';

  FNotes  := 'Type of limit	and Maximum limit'#13#10+
             'Total request size: 128 KiB (128*1024 bytes)'#13#10+
             'Character count   : 500,000 characters per month for DeepL API Free';

// unknown IDs
// dapUID=d248414b-5a1a-49ed-8442-7e9bc3f8da9e
// LMTBID=v2|d9ac9530-237b-4ab9-a109-15c70f7d2fda|fe2dd5d991bc8169352cdfdd9b819306

  FSupport := [trTranslate,trDetect];
end;

function TTranslateDeepL.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;
//    ltr.allowredirect:=true;
//    ltr.AddHeader('Content-Type','application/json');
    ltr.AddHeader('Content-Type','application/x-www-form-urlencoded');

    if FAPIKey='' then
    begin
      ls:='#{from}/{to}/{text}';

      ls:=StringReplace(ls,'{from}',FFrom,[]);
      ls:=StringReplace(ls,'{to}'  ,FTo  ,[]);
      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

      ls:=ltr.Post('https://www.deepl.com/en/translator'+ls);
    end
    else
    begin
      // from DeepL API doc
      ltr.AddHeader('Authorization', StringReplace('DeepL-Auth-Key {key}','{key}',FAPIKey,[]));
(*
  JSON format:
  {"text":["Hello, world!"],"target_lang":"DE"}
*)
// from OlfSoftware.DeepL.ClientLib
//      ls:='?source_lang={from}&target_lang={to}&auth_key={key}&text={text}';
//      ls:=StringReplace(ls,'{key}' ,FAPIKey,[]);
      ls:='?source_lang={from}&target_lang={to}&text={text}';
      if FAuto then
        ls:=StringReplace(ls,'source_lang={from}&','',[])
      else
        ls:=StringReplace(ls,'{from}',FFrom,[]);
      ls:=StringReplace(ls,'{to}'  ,FTo    ,[]);
      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

      ls:=ltr.Post(FHost+ls);
    end;

    result:=ltr.ResponseStatusCode;
    if result=200 then
    begin
      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            FOut   :=jn.Child('translations').AsArray.Child('text').AsString;
            result :=0;
            FResult:='';
          end;
        finally
          jn.Free;
        end;
      end;
    end
    else
    begin
      case result of
//              400: ; // BadRequest
//              403: ; // Forbidden
//              404: ; // NotFound
        413: FResult:=sTooLongText; // PayloadTooLarge
        414: FResult:=sTooLongText; // URITooLong
        429: FResult:=sTooManyRequest;
        456: FResult:=sTooMuchText;
//              500: ; // InternalServerError
//              504: ; // ServiceUnavailable
        529: FResult:=sTooManyRequest;
      else
        FResult:=ltr.ResponseStatusText;
        if FResult='' then
          FResult:=sUnknownError+' '+IntToStr(result);
      end;
    end;

  except
  end;
  ltr.Free;
end;
{%ENDREGION DeepL}

{%REGION Yandex}
{
200	- Операция выполнена успешно
401	- Неправильный API-ключ
402	- API-ключ заблокирован
404	- Превышено суточное ограничение на объем переведенного текста
413	- Превышен максимально допустимый размер текста
422	- Текст не может быть переведен
501	- Заданное направление перевода не поддерживается
}
constructor TTranslateYandex.Create;
begin
  inherited;

  FName  := 'Yandex';
  FDescr := 'Translate Russian, Spanish, German, French and a number of other languages to and '+
            'from English. You can translate individual words, as well as whole texts and webpages.';
  FSite  := 'https://translate.yandex.com/';
  FHost  := 'https://translate.yandex.net/';

  FDocURL := 'https://yandex.com/dev/translate/doc/dg/concepts/about-docpage/';
  FKeyURL := 'https://translate.yandex.com/developers/keys';

// deprecated
//  Fv1KeyURL := 'https://oauth.yandex.com/client/new';

  // not APP ID but Sesion ID
  FAppId := 'a5ab1325.5e62b3ea.9eab678d';
//            'f6932bf5.5e6650a0.dce10065'

  FSupport := [trTranslate,trDetect];
end;

function TTranslateYandex.Detect:boolean;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  result:=false;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:='api/v1.5/tr.json/detect?text={text}&key={key}';

    //??
//  Fv1Detect := 'api/v1/tr.json/detect?sid={appid}&srv=tr-text&text={text}'; // 256 symbols
    if FAPIKey='' then
      ls:=StringReplace(ls,'&key={key}','',[])
    else
      ls:=StringReplace(ls,'{key}',FAPIKey,[]);

    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

    ls:=ltr.Post(FHost+ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
          if round(jn.Child('code').AsNumber)=200 then
          begin
            FFrom:=jn.Child('lang').AsString;
            result:=true;
          end
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
end;

function TTranslateYandex.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

{
  if FAPIKey='' then
  begin
    result :=401;
    FResult:=sWrongAPIKey;
    exit;
  end;
}

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    if FAPIKey='' then
    begin
      ls:='api/v1/tr.json/translate?id={appid}-0-0&srv=tr-text&lang={from}-{to}&text={text}';
      ls:=StringReplace(ls,'{appid}',FAppId,[]);
    end
    else
    begin
      ls:='api/v1.5/tr.json/translate?lang={from}-{to}&key={key}&text={text}';

      ls:=StringReplace(ls,'{key}',FAPIKey,[]);
    end;

    ls:=StringReplace(ls,'{to}',FTo,[]);
    if FAuto then
    begin
      ls:=StringReplace(ls,'{from}-','',[])
    end
    else
      ls:=StringReplace(ls,'{from}' ,FFrom,[]);

    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

    ls:=ltr.Post(FHost+ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
          result:=round(jn.Child('code').AsNumber);
          if result=200 then
          begin
            FOut   :=jn.Child('text').AsArray.Child(0).AsString;
            result :=0;
            FResult:='';
          end
          else
          begin
            case result of
              401: FResult:=sWrongAPIKey;
              402: FResult:=sKeyBlocked;
              404: FResult:=sTooMuchText;
              413: FResult:=sTooLongText;
              422: FResult:=sCantTranslate;
              501: FResult:=sWrongLanguage;
            else
              FResult:=sUnknownError+' '+IntToStr(result);
            end;
          end;
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
end;
{%ENDREGION Yandex}

{%REGION MyMemory}
constructor TTranslateMyMemory.Create;
begin
  inherited;

  FName  := 'MyMemory';
  FDescr := '';
  FSite  := 'https://mymemory.translated.net/';
  FHost  := 'https://api.mymemory.translated.net/';

  FDocURL := 'https://mymemory.translated.net/doc/spec.php';
  FKeyURL := 'https://mymemory.translated.net/doc/keygen.php';
  
  FSupport := [trTranslate];
end;

function TTranslateMyMemory.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:='get?q={text}&langpair={from}%7C{to}&key={key}&de={email}';

    if FEmail='' then
      ls:=StringReplace(ls,'&de={email}','',[])
    else
      ls:=StringReplace(ls,'{email}',FEMail,[]);

    if FAPIKey='' then
      ls:=StringReplace(ls,'&key={key}','',[])
    else
      ls:=StringReplace(ls,'{key}',FAPIKey,[]);

    ls:=StringReplace(ls,'{to}'  ,FTo  ,[]);
    ls:=StringReplace(ls,'{from}',FFrom,[]);
    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

    ls:=ltr.Get(FHost+ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
          jl:=jn.Child('responseStatus');
          if jl<>nil then
            result:=round(jl.AsNumber);

          if result=200 then
          begin
            jl:=jn.Find('responseData/translatedText');
            if jl<>nil then
            begin
              FOut   :=jl.AsString;
              result :=0;
              FResult:='';
            end;
          end
          else
            // 403 - invalid language pair
            FResult:=sUnknownError+' '+IntToStr(result);
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
end;
{%ENDREGION MyMemory}

{%REGION Google}
{
  client -
  sl     - source language
  tl     - target language
  hl     - help language
  dt=at  - alternative translations
  dt=bd  - dictionary, in case source text is one word (you get translations with articles, reverse translations, etc.)
  dt=dj  - Json response with names. (dj=1)
  dt=ex  - examples
  dt=gt  - gender-specific translations
  dt=ld  - identified source languages
  dt=md  - definitions of source text, if it's one word
  dt=qc  -
  dt=qca - qc with autocorrect
  dt=rm  - transcription / transliteration of source and translated texts
  dt=rw  - 'See also' list.
  dt=ss  - synonyms of source text, if it's one word
  dt=sw  -
  dt=t   - translation of source text
  ie     - 'UTF-8',
  oe     - 'UTF-8',
  otf    - 1 / 2
  srcrom - 1
  ssel   - 0 / 3
  tsel   - 0 / 4
  kc     - 7
  q      - text
  tbb    - 1
  tk     - token 520078|504525 / 519592|450115
  prev   - btn
  rom    - 1
}

constructor TTranslateGoogle.Create;
begin
  inherited;

  FName  := 'Google';
  FDescr := 'Google''s free online language translation service instantly translates text and web pages.';
  FHost  := 'https://translate.google.com/';
  
  FDocURL := '';
  FKeyURL := '';

  FAPIv2Host := 'https://translation.googleapis.com/';

  FSupport := [trTranslate,trDetect];
end;

procedure TTranslateGoogle.SetLang(index:integer; const alang:string);
var
  llang:string;
begin
  llang:=LowerCase(alang);

  case llang of
    'zh-cn': llang:='zh-CN';
    'zh-tw': llang:='zh-TW';
  else
    inherited SetLang(index,alang);
    exit;
  end;

  if index=0 then
    FFrom:=llang
  else
    FTo:=llang;
end;

function TTranslateGoogle.Detect:boolean;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl:TJsonNode;
begin
  result:=false;

  if FAPIKey='' then
  begin
    ltr:=TFPHTTPClient.Create(nil);
    try
      ltr.IOTimeout:=FTimeout;

      ls:='translate_a/single?client=x&sl=auto&dt=ld&ie=UTF-8&oe=UTF-8&q={text}';

      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

      ls:=ltr.Get(FHost+ls);

      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            jl:=jn.Find('8/0/0');
            if jl<>nil then
            begin
              FFrom:=jn.AsString;
              result:=true;
            end;
          end;
        finally
          jn.Free;
        end;
      end;

    except
    end;
    ltr.Free;

  end
  else
  begin
    ltr:=TFPHTTPClient.Create(nil);
    try
      ltr.IOTimeout:=FTimeout;

      ls:='language/translate/v2/detect?key={key}&q={text}';

      ls:=StringReplace(ls,'{key}' ,FAPIKey,[]);
      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

      ls:=ltr.Post(FAPIv2Host+ls);

      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            jl:=jn.Find('data/detections/0/language');
            if jl<>nil then
            begin
              FFrom:=jl.AsString;
              result:=true;
            end;
          end;
        finally
          jn.Free;
        end;
      end;

    except
    end;
    ltr.Free;
  end;
end;

function TTranslateGoogle.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl,jc:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    if FAPIKey='' then
    begin
      //--- Free version

      ls:='translate_a/single?client=x&sl={from}&tl={to}&hl=en'+
//          '&dt=bd&dt=ex&dt=ld&dt=md&dt=qc&dt=rw&dt=rm&dt=ss&dt=t&dt=at'+
          '&dt=t&dt=ld&ie=UTF-8&oe=UTF-8&q={text}';

      ls:=StringReplace(ls,'{to}',FTo,[]);

      if FAuto then
        ls:=StringReplace(ls,'{from}','auto',[])
      else
        ls:=StringReplace(ls,'{from}',FFrom,[]);

      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

      ls:=ltr.Get(FHost+ls);

      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            if FAuto then
            begin
              jl:=jn.Find('8/0/0');
              if jl<>nil then
                FFrom:=jn.AsString;
            end;
            jl:=jn.Child(0);
            if jl.Kind<>nkNull then
            begin
              for jc in jl do
                FOut:=FOut+jc.Child(0).AsString;
              result :=0;
              FResult:='';
            end;
          end;
        finally
          jn.Free;
        end;
      end;

    end
    else
    begin
      //--- Paid API version
      ls:='language/translate/v2?key={key}&q={text}&source={from}&target={to}';

      ls:=StringReplace(ls,'{key}',FAPIKey,[]);

      ls:=StringReplace(ls,'{to}',FTo,[]);

      if FAuto then
        ls:=StringReplace(ls,'&source={from}','',[])
      else
        ls:=StringReplace(ls,'{from}',FFrom,[]);

      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

      ls:=ltr.Get(FAPIv2Host+ls);

      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            if FAuto then
            begin
              jl:=jn.Find('data/translations/0/detectedSourceLanguage');
              if jl<>nil then
                FFrom:=jl.AsString;
            end;
            jl:=jn.Find('data/translations/0/translatedText');
            if jl<>nil then
            begin
              FOut   :=jl.AsString;
              result :=0;
              FResult:='';
            end;
          end;
        finally
          jn.Free;
        end;
      end;

    end;

  except
  end;
  ltr.Free;
end;
{%ENDREGION Google}

{%REGION Translate}
constructor TTranslateTranslate.Create;
begin
  inherited;

  FName  := 'Translate';
  FDescr := '(microsoft)';
  FSite  := 'https://www.translate.com/';
  FHost  := 'https://www.translate.com/';

  FSupport := [trTranslate,trDetect];
end;

function TTranslateTranslate.Translate:integer;
var
  ls:string;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:='text_to_translate={text}&source_lang={from}&translated_lang={to}'+
        '&use_cache_only=false';

    ls:=StringReplace(ls,'{to}',FTo,[]);
    if FAuto then
      ls:=StringReplace(ls,'&source_lang={from}','',[])
    else
      ls:=StringReplace(ls,'{from}',FFrom,[]);

    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[]);

    ls:=ltr.FormPost(FHost+'translator/ajax_translate',ls);

    jn:=TJsonNode.Create;
    try
      if jn.TryParse(ls) then
      begin
        if jn.Child('result').AsString='success' then
        begin
          FOut:=jn.Child('translated_text').AsString;
          FResult:='';
          result:=0;
        end;
      end;
    finally
      jn.Free;
    end;

  except
  end;
  ltr.Free;
end;
{%ENDREGION Translate}

end.
