unit RGLog;

interface

procedure Reserve(const astr:string);
procedure Reserve(astr:PWideChar);
procedure Add(const afile:string; aline:integer; const astr:string);
procedure Add(const astr:string);
procedure Add(astr:PWideChar);
procedure Save(const afile:string='rglog.txt');
procedure Clear;

implementation

uses
  Classes,
  SysUtils;

var
  res:AnsiString;
  log:TStringList;

procedure Add(const afile:string; aline:integer; const astr:string);
begin
  log.Add(afile+' ('+IntToStr(aline)+'): '+astr);
end;

procedure Reserve(const astr:string);
begin
  res:=astr;
end;

procedure Reserve(astr:PWideChar);
begin
  res:=UTF8Encode(WideString(astr));
end;

procedure Add(const astr:string);
begin
  if res<>'' then begin log.Add(res); res:=''; end;
  log.Add(astr);
end;

procedure Add(astr:PWideChar);
begin
  if res<>'' then begin log.Add(res); res:=''; end;
  log.Add(UTF8Encode(WideString(astr)));
end;

procedure Save(const afile:string='rglog.txt');
begin
  if log.Count>0 then
    log.SaveToFile(afile);
end;

procedure Clear;
begin
  log.Clear;
end;

initialization

  log:=TStringList.Create;
  res:='';

finalization

{
  if log.Count>0 then
    log.SaveToFile('rglog.txt');
}
  log.Free;
  res:='';

end.
