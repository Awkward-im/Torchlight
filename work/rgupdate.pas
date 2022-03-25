{
  keep ref to pak/man or not?
}
unit RGUpdate;

interface

uses
  rgglobal;

implementation

uses
  rgpack;

type
  TUpdateElement = record
    path:PWideChar;
    data:PByte;
    usize:cardinal;
    psize:cardinal;
  end;

type
  TRGUpdateList = object
  private
    FList:array of TUpdateElement;
  public
    procedure Clear;
    procedure Add(adata:PByte; asize:cardinal; apath:PWideChar);
    procedure Remove(apath:PWideChar);
  end;


begin
end.
