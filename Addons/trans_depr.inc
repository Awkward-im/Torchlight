{$IFDEF Interface}

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

{$ELSE}

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

  FResult:=rsUnknownError;

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
          FResult:=rsUnknownError+' '+IntToStr(result);
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

  FResult:=rsUnknownError;

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

  FResult:=rsUnknownError;

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

{$ENDIF}
