unit iso639;

interface

function GetLangIndex(const alang:string ):integer;
function GetLang     (const alang:string ):string; overload;
function GetLang     (      alang:integer):string; overload;
function GetLangA2   (const alang:string ):string; overload;
function GetLangA2   (      alang:integer):string; overload;
function GetLangA3   (const alang:string ):string; overload;
function GetLangA3   (      alang:integer):string; overload;
function GetLangName (const alang:string ):string; overload;
function GetLangName (      alang:integer):string; overload;

implementation

{$i langs.inc}

function GetLangIndex(const alang:string):integer;
var
  llang:string;
  i:integer;
begin
  result:=-1;
  llang:=LowerCase(alang);
  if Length(alang)=2 then
  begin
    for i:=0 to high(Langs) do
    begin
      if (Langs[i].a2[0]=llang[1]) and
         (Langs[i].a2[1]=llang[2]) then
      begin
        result:=i;
        exit;
      end;
    end;
  end
  else if Length(alang)=3 then
  begin
    for i:=0 to high(Langs) do
    begin
      if (Langs[i].a3[0]=llang[1]) and
         (Langs[i].a3[1]=llang[2]) and
         (Langs[i].a3[2]=llang[3]) then
      begin
        result:=i;
        exit;
      end;
    end;
  end
  else
  begin
    for i:=0 to high(Langs) do
    begin
      if LowerCase(Langs[i].name)=llang then
      begin
        result:=i;
        exit;
      end;
    end;
  end
end;


function GetLang(const alang:string):string;
begin
  result:=GetLang(GetLangIndex(alang));
end;

function GetLang(alang:integer):string;
begin
  if (alang>=0) and (alang<Length(Langs)) then
  begin
    result:=GetLangA2(alang);
    if result='' then
      result:=GetLangA3(alang);
  end
  else
    result:='';
end;


function GetLangA2(const alang:string):string;
begin
  result:=GetLangA2(GetLangIndex(alang));
end;

function GetLangA2(alang:integer):string;
begin
  if (alang>=0) and (alang<Length(Langs)) then
  begin
    result:=Langs[alang].a2;
  end
  else
    result:='';
end;


function GetLangA3(const alang:string):string;
begin
  result:=GetLangA3(GetLangIndex(alang));
end;

function GetLangA3(alang:integer):string;
begin
  if (alang>=0) and (alang<Length(Langs)) then
  begin
    result:=Langs[alang].a3;
  end
  else
    result:='';
end;


function GetLangName(const alang:string):string;
begin
  result:=GetLangName(GetLangIndex(alang));
end;

function GetLangName(alang:integer):string;
begin
  if alang>=0 then
  begin
    result:=Langs[alang].Name;
  end
  else
    result:='';
end;

end.
