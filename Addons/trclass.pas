{$H+}
unit TRClass;

interface

{$DEFINE Interface}

const
  DefaultTimeout = 5000;
  DefaultResCode = 1;

type
  TTransType = (
    trNoKey,      // work without keys
    trFreeKey,
    trFreeURL,    // separate free key url
    trPaidKey,
    trPaidURL,    // separate paid key url

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

    // can be use for reading
    FDocURL    :string;                                // API/usage documentation URL

    FTimeout:integer;

    FHost  :string;                                    // request base host
    FAPIKey:string;                                    // APIkey or AppId - same storage?

    FFreeKey   :string;
    FFreeHost  :string;
    FFreeKeyURL:string;                                // free key/id registering URL
    FPaidKey   :string;
    FPaidHost  :string;
    FPaidKeyURL:string;                                // paid key/id registering URL
    FUsePaid   :boolean;
    FNoKeyHost :string;

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

    procedure FixKeyAndHost;
    procedure SetAPIKey(index:integer;const akey:string);
    procedure SetUsePaid(value:boolean);

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

//    property Key:string read FAPIKey write FAPIKey;    // API key (if presents)
    property FreeKey   :string index 0 read FFreeKey write SetAPIKey;  // Free API key (if presents)
    property PaidKey   :string index 1 read FPaidKey write SetAPIKey;  // Paid API key (if presents)
    property FreeKeyURL:string         read FFreeKeyURL;
    property PaidKeyURL:string         read FPaidKeyURL;
    property UsePaid   :boolean        read FUsePaid write SetUsePaid;

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

{.$IF FILEEXISTS('trans_depr.inc')}
  {$include trans_depr.inc}
{.$ENDIF}

function CreateTranslatorByName(const aname:string):TTranslateBase;

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

{$UNDEF Interface}

resourcestring
  rsNoHost           = 'No host address defined';
  rsWrongAPIKey      = 'Wrong API key';
  rsKeyBlocked       = 'API key blocked';
  rsTooMuchText      = 'Day text potion out of limit';
  rsTooLongText      = 'Text length too large';
  rsTooManyRequest   = 'Too many requests. Please wait and resend your request.';
  rsCantTranslate    = 'Text can''t be translated';
  rsWrongLanguage    = 'Choosen language is unsupported';
  rsUnknownError     = 'Unknown Error';
  rsSessionIsInvalid = 'Session is invalid';

{%REGION Base}
constructor TTranslateBase.Create;
begin
  inherited;

  FTimeout := DefaultTimeout;
  FAuto    := false;

  FName   := 'default';
  FDescr  := '';
  FNotes  := '';
  //
  FSite       := '';
  FHost       := '';
  FDocURL     := '';
  FFreeKeyURL := '';
  FPaidKeyURL := '';
  FNoKeyHost  := '';

  FFreeKey :='';
  FPaidKey :='';
  FFreeHost:='';
  FPaidHost:='';

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

procedure TTranslateBase.FixKeyAndHost;
begin
  // really, if key<>'' then it must be in support
  if (FPaidKey<>'') and (trPaidKey in FSupport) and (FUsePaid) then
  begin
    FAPIKey:=FPaidKey;
    if FPaidHost<>'' then
      FHost:=FPaidHost;
  end
  else if (FFreeKey<>'') and (trFreeKey in FSupport) then
  begin
    FAPIKey:=FFreeKey;
    if FFreeHost<>'' then
      FHost:=FFreeHost;
  end
  else
  begin
    FAPIKey:='';
    if FNoKeyHost<>'' then
      FHost:=FNoKeyHost
    else
      FHost:=FSite;
  end;
end;

procedure TTranslateBase.SetUsePaid(value:boolean);
begin
  FUsePaid:=value and (trPaidKey in FSupport);
  FixKeyAndHost;
end;

procedure TTranslateBase.SetAPIKey(index:integer;const akey:string);
begin
  if index=0 then FFreeKey:=akey;
  if index=1 then FPaidKey:=akey;

  FixKeyAndHost;
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
       (not (FAuto and (trDetect in FSupport)))) then FResult:=rsWrongLanguage
    else if not     (trTranslate in FSupport)    then FResult:=rsCantTranslate;
  end;
  if FHost='' then
  begin
    result:=DefaultResCode;
    FResult:=rsNoHost;
  end;
end;

function TTranslateBase.GetResultDescr:string;
begin
  result:=FResult;
end;
{%ENDREGION Base}

//==============================================================================

{.$IF FILEEXISTS('trans_depr.inc')}
  {$include trans_depr.inc}
{.$ENDIF}

{%REGION DeepL}
(*
DeepL API Free authentication keys can be identified easily by the suffix ":fx"
(e.g., 279a2e9d-83b3-c416-7e2d-f721593e42a0:fx)
*)
constructor TTranslateDeepL.Create;
begin
  inherited;

  FName  := 'DeepL';
  FDescr := 'DeepL trains artificial intelligence to understand and translate texts.';

  FSite       := 'https://www.deepl.com/translator';
  FNoKeyHost  := 'https://www.deepl.com/en/translator';

  FDocURL     := 'https://developers.deepl.com/docs';
  FFreeKeyURL := 'https://www.deepl.com/your-account/keys';

  FNotes  := 'Type of limit	and Maximum limit'#13#10+
             'Total request size: 128 KiB (128*1024 bytes)'#13#10+
             'Character count   : 500,000 characters per month for DeepL API Free';

  FFreeHost :='https://api-free.deepl.com/v2/';
  FPaidHost :='https://api.deepl.com/v2/';

// unknown IDs
// dapUID=d248414b-5a1a-49ed-8442-7e9bc3f8da9e
// LMTBID=v2|d9ac9530-237b-4ab9-a109-15c70f7d2fda|fe2dd5d991bc8169352cdfdd9b819306

  FSupport := [{trNoKey,}trFreeKey,trPaidKey,trFreeURL,trPaidURL,trTranslate,trDetect];
end;

function TTranslateDeepL.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=rsUnknownError;

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

      ls:=ltr.Post(FHost+ls);
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
        413: FResult:=rsTooLongText; // PayloadTooLarge
        414: FResult:=rsTooLongText; // URITooLong
        429: FResult:=rsTooManyRequest;
        456: FResult:=rsTooMuchText;
//              500: ; // InternalServerError
//              504: ; // ServiceUnavailable
        529: FResult:=rsTooManyRequest;
      else
        FResult:=ltr.ResponseStatusText;
        if FResult='' then
          FResult:=rsUnknownError+' '+IntToStr(result);
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
  FSite       := 'https://translate.yandex.com/';
  FNoKeyHost  := 'https://translate.yandex.net/';
  FFreeHost   := 'https://translate.yandex.net/';

  FDocURL     := 'https://yandex.com/dev/translate/doc/dg/concepts/about-docpage/';
//  FDocURL     :='https://yandex.cloud/ru/services/translate';
  FFreeKeyURL := 'https://translate.yandex.com/developers/keys';

// deprecated
//  FFreeKeyURL := 'https://oauth.yandex.com/client/new';

  // not APP ID but Sesion ID
  FAppId := 'a5ab1325.5e62b3ea.9eab678d';
//            'f6932bf5.5e6650a0.dce10065'

  FSupport := [{trNoKey,}trFreeKey,trPaidKey,trTranslate,trDetect];
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

  FResult:=rsUnknownError;

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
              401: FResult:=rsWrongAPIKey;
              402: FResult:=rsKeyBlocked;
              404: FResult:=rsTooMuchText;
              405: FResult:=rsSessionIsInvalid;
              413: FResult:=rsTooLongText;
              422: FResult:=rsCantTranslate;
              501: FResult:=rsWrongLanguage;
            else
              FResult:=rsUnknownError+' '+IntToStr(result);
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

  FSite       := 'https://mymemory.translated.net/';
  FFreeHost   := 'https://api.mymemory.translated.net/';

  FDocURL     := 'https://mymemory.translated.net/doc/spec.php';
  FFreeKeyURL := 'https://mymemory.translated.net/doc/keygen.php';
  
  FSupport := [trNoKey,trFreeKey,trTranslate];
end;

function TTranslateMyMemory.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=rsUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:='get?q={text}&langpair={from}%7C{to}&key={key}&de={email}';

    if FEmail='' then
      ls:=StringReplace(ls,'&de={email}','',[])
    else
      ls:=StringReplace(ls,'{email}',FEMail,[]);

    if FAPIKey='' then //FFreeKey
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
            FResult:=rsUnknownError+' '+IntToStr(result);
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

  FSite      := 'https://translate.google.com/';
//  FNoKeyHost := 'https://translate.google.com/';
  FPaidHost  := 'https://translation.googleapis.com/';

  FSupport := [trNoKey,trPaidKey,trPaidURL,trTranslate,trDetect];
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

      ls:=ltr.Post(FHost+ls); // FPaidHost

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

  FResult:=rsUnknownError;

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

      ls:=ltr.Get(FHost+ls); // FPaidHost

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
//  FNoKeyHost := 'https://www.translate.com/';

  FSupport := [trNoKey,trTranslate,trDetect];
end;

function TTranslateTranslate.Translate:integer;
var
  ls:string;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  result:=inherited;
  if (result=0) or (FResult<>'') then exit;

  FResult:=rsUnknownError;

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

function CreateTranslatorByName(const aname:string):TTranslateBase;
begin
  case LowerCase(aname) of
    'google'   : result:=TTranslateGoogle.Create;
    'yandex'   : result:=TTranslateYandex.Create;
    'deepl'    : result:=TTranslateDeepL.Create;
//    'bing'         : result:=TTranslateBing.Create;
//    'babylon'      : result:=TTranslateBabylon.Create;
//    'm-translate'  : result:=TTranslateMTranslate.Create;
    'translate': result:=TTranslateTranslate.Create;
    'mymemory' : result:=TTranslateMyMemory.Create;
  else
    result:=nil;
  end;
end;

end.
