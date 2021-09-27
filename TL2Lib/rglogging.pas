unit RGLogging;

interface

uses
  Classes;

type
  TRGLog = object
  private
    FLog:TStringList;
    FReserved:boolean;
    
    function GetText():string;
    
  public
    procedure Init;
    procedure Free;
    procedure Clear;

    procedure Reserve(const astr:string);
    procedure Reserve(astr:PWideChar);
    procedure Add(const afile:string; aline:integer; const astr:string);
    procedure Add(const astr:string);
    procedure Add(astr:PWideChar);

    procedure Save(const afile:string='rglog.txt');

    property Text:string read GetText;
  end;

var
  RGLog:TRGLog;


implementation

uses
  SysUtils;


procedure TRGLog.Init;
begin
  FLog:=TStringList.Create;
end;

procedure TRGLog.Clear;
begin
  FLog.Clear;
end;

procedure TRGLog.Free;
begin
  FLog.Free;
end;


procedure TRGLog.Add(const astr:string);
begin
  if (FLog.Count>0) and FReserved then
    FLog[FLog.Count-1]:=astr
  else
    Flog.Add(astr);

  FReserved:=false;
end;

procedure TRGLog.Add(const afile:string; aline:integer; const astr:string);
begin
  Add(afile+' ('+IntToStr(aline)+'): '+astr);
end;

procedure TRGLog.Add(astr:PWideChar);
begin
  Add(UTF8Encode(WideString(astr)));
end;


procedure TRGLog.Reserve(const astr:string);
begin
  Add(astr);
  FReserved:=true;
end;

procedure TRGLog.Reserve(astr:PWideChar);
begin
  Add(astr);
  FReserved:=true;
end;


procedure TRGLog.Save(const afile:string='rglog.txt');
begin
  if FLog.Count>0 then
    FLog.SaveToFile(afile);
end;

function TRGLog.GetText:string;
begin
  result:=FLog.Text;
end;


initialization

  RGLog.Init;

finalization

  RGLog.Free;

end.
