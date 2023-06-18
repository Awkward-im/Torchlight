unit SynHighlightert;

interface

uses
  Classes, Graphics, SynEditTypes, SynEditHighlighter,
  SynEditHighlighterFoldBase, SynEditStrConst;

type
  TtkTokenKind = (tkNull, tkSpace, tkSymbol, tkGroup, tkType, tkProp, tkText, tkWrong, tkNumber);

  TRangeState = (rsSign, rsGroup, rsOpenGroup, rsCloseGroup, rsType, rsCloseType, rsOpenType, rsProp, rsPoint, rsText);

type

  TProcTableProc = procedure of object;

  { TSynTSyn }

  TSynTSyn = class(TSynCustomFoldHighlighter)
  private
    fRange: TRangeState;
    fLine: PChar;
    Run: Longint;
    fTokenPos: Integer;
    fTokenID: TtkTokenKind;
    fLineNumber: Integer;

    fGroupAttri : TSynHighlighterAttributes;
    fSpaceAttri : TSynHighlighterAttributes;
    fTextAttri  : TSynHighlighterAttributes;
    fTypeAttri  : TSynHighlighterAttributes;
    fPropAttri  : TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fWrongAttri : TSynHighlighterAttributes;

    fProcTable: array[#0..#255] of TProcTableProc;

    procedure NullProc;
    procedure CarriageReturnProc;
    procedure LineFeedProc;
    procedure SpaceProc;
    procedure LessThanProc;
    procedure GreaterThanProc;
    procedure PointProc;
    procedure SquareOPenProc;
    procedure SquareCloseProc;
    procedure GroupProc;
    procedure IdentProc;
    procedure PropProc;
    procedure TypeProc;
    procedure TextProc;
    procedure MakeMethodTables;
    function NextTokenIs(T: String): Boolean;
  protected
    function GetIdentChars: TSynIdentChars; override;
  public
    class function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    function  GetDefaultAttribute(Index: integer): TSynHighlighterAttributes; override;
    function  GetEol: Boolean; override;
    function  GetRange: Pointer; override;
    function  GetTokenID: TtkTokenKind;
    procedure SetLine(const NewValue: string; LineNumber:Integer); override;
    function  GetToken: string; override;
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    function  GetTokenAttribute: TSynHighlighterAttributes; override;
    function  GetTokenKind: integer; override;
    function  GetTokenPos: Integer; override;
    procedure Next; override;
    procedure SetRange(Value: Pointer); override;
    procedure ReSetRange; override;

    property IdentChars;
  published
    property GroupAttri : TSynHighlighterAttributes read fGroupAttri  write fGroupAttri;
    property TypeAttri  : TSynHighlighterAttributes read fTypeAttri   write fTypeAttri;
    property PropAttri  : TSynHighlighterAttributes read fPropAttri   write fPropAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri write fNumberAttri;
    property TextAttri  : TSynHighlighterAttributes read fTextAttri   write fTextAttri;
    property SpaceAttri : TSynHighlighterAttributes read fSpaceAttri  write fSpaceAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri write fSymbolAttri;
    property WrongAttri : TSynHighlighterAttributes read fWrongAttri  write fWrongAttri;
  end;

implementation

const
  SYNS_LangTorch = 'Torchlight';

const
  NameChars : set of char = [' ','0'..'9', 'a'..'z', 'A'..'Z', '_', '.', '-'];

constructor TSynTSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  fGroupAttri  := TSynHighlighterAttributes.Create(@SYNS_AttrElementName   , SYNS_AttrBlock);
  fTypeAttri   := TSynHighlighterAttributes.Create(@SYNS_AttrAttributeName , SYNS_AttrDataType);
  fPropAttri   := TSynHighlighterAttributes.Create(@SYNS_AttrAttributeName , SYNS_AttrKey);
  fNumberAttri := TSynHighlighterAttributes.Create(@SYNS_AttrAttributeValue, SYNS_AttrNumber);
  fTextAttri   := TSynHighlighterAttributes.Create(@SYNS_AttrText          , SYNS_AttrText);
  fSpaceAttri  := TSynHighlighterAttributes.Create(@SYNS_AttrWhitespace    , SYNS_AttrSpace);
  fSymbolAttri := TSynHighlighterAttributes.Create(@SYNS_AttrSymbol        , SYNS_AttrSymbol);
  fWrongAttri  := TSynHighlighterAttributes.Create(@SYNS_AttrText          , SYNS_AttrUnknownWord);

  fGroupAttri .Foreground:= clMaroon;  fGroupAttri .Style:= [fsBold];
  fTypeAttri  .Foreground:= clPurple;  fTypeAttri  .Style:= [];
  fPropAttri  .Foreground:= clMaroon;  fPropAttri  .Style:= [fsBold];
  fNumberAttri.Foreground:= clGreen ;  fNumberAttri.Style:= [fsBold];
  fTextAttri  .Foreground:= clBlack ;  fTextAttri  .Style:= [];
  fSymbolAttri.Foreground:= clBlue  ;  fSymbolAttri.Style:= [];
  fWrongAttri .Foreground:= clWhite ;  fGroupAttri .Style:= [fsBold];  fWrongAttri.Background:= clRed;

  AddAttribute(fGroupAttri);
  AddAttribute(fTypeAttri);
  AddAttribute(fPropAttri);
  AddAttribute(fNumberAttri);
  AddAttribute(fTextAttri);
  AddAttribute(fSpaceAttri);
  AddAttribute(fSymbolAttri);
  AddAttribute(fWrongAttri);

  SetAttributesOnChange(@DefHighlightChange);

  MakeMethodTables;
  fRange := rsSign;
end;

procedure TSynTSyn.MakeMethodTables;
var
  i: Char;
begin
  for i:= #0 To #255 do begin
    case i of
    #0 : fProcTable[i] := @NullProc;
    #10: fProcTable[i] := @LineFeedProc;
    #13: fProcTable[i] := @CarriageReturnProc;
    #1..#9, #11, #12, #14..#32:
         fProcTable[i] := @SpaceProc;
    ':': fProcTable[i] := @PointProc;
    '<': fProcTable[i] := @LessThanProc;
    '>': fProcTable[i] := @GreaterThanProc;
    '[': fProcTable[i] := @SquareOpenProc;
    ']': fProcTable[i] := @SquareCloseProc;
    else
         fProcTable[i] := @IdentProc;
    end;
  end;
end;

procedure TSynTSyn.SetLine(const NewValue: string; LineNumber:Integer);
begin
  inherited;
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end;

procedure TSynTSyn.NullProc;
begin
  fTokenID := tkNull;
end;

procedure TSynTSyn.CarriageReturnProc;
begin
  fTokenID := tkSpace;
  Inc(Run);
  if fLine[Run] = #10 then Inc(Run);
end;

procedure TSynTSyn.LineFeedProc;
begin
  fTokenID := tkSpace;
  Inc(Run);
end;

procedure TSynTSyn.SpaceProc;
begin
  Inc(Run);
  fTokenID := tkSpace;
  while fLine[Run] <= #32 do begin
    if fLine[Run] in [#0, #9, #10, #13] then break;
    Inc(Run);
  end;
end;

procedure TSynTSyn.PointProc;
begin
  Inc(Run);
  fTokenID := tkSymbol;
  fRange:= rsText;
end;

procedure TSynTSyn.LessThanProc;
begin
  fTokenId := tkType;
  fRange := rsOpenType;
  Inc(Run);
end;

procedure TSynTSyn.GreaterThanProc;
begin
  fTokenId := tkType;
  fRange := rsProp;
  Inc(Run);
end;

procedure TSynTSyn.SquareOpenProc;
begin
  Inc(Run);
  if (fLine[Run] = '/') then
  begin
    Inc(Run);
    fTokenID := tkGroup;
    fRange := rsCloseGroup;
    exit;
  end;

  fTokenID := tkGroup;
  fRange := rsOpenGroup;
end;

procedure TSynTSyn.SquareCloseProc;
begin
  fTokenId := tkGroup;
  fRange := rsText;
  Inc(Run);
end;

procedure TSynTSyn.PropProc;
begin
  fRange := rsPoint;
  fTokenId := tkProp;
  while (fLine[Run] in NameChars) do Inc(Run);
end;

procedure TSynTSyn.TextProc;
var
  ls:string;
  lp:integer;
begin
  fRange := rsText;
  fTokenId := tkText;
  lp:=Run;
  while fLine[Run] in [#$FE, #$FF, #$EF, #$BB, #$BF] do inc(Run);
  if lp<>Run then
    exit;

  lp:=Run;
  while not (fLine[Run] in [#13, #10, #0]) do Inc(Run);

  ls:=Copy(fLine+lp,1,Run-lp);
  if (Length(ls)=4) and
    ((ls[1]='T') or (ls[1]='t')) and
    ((ls[2]='R') or (ls[2]='r')) and
    ((ls[3]='U') or (ls[3]='u')) and
    ((ls[4]='E') or (ls[4]='e')) then
    fTokenId:=tkNumber
  else if (Length(ls)=5) and
    ((ls[1]='F') or (ls[1]='f')) and
    ((ls[2]='A') or (ls[2]='a')) and
    ((ls[3]='L') or (ls[3]='l')) and
    ((ls[4]='S') or (ls[4]='s')) and
    ((ls[5]='E') or (ls[5]='e')) then
    fTokenId:=tkNumber
  else
  begin
    fTokenId:=tkNumber;
    for lp:=1 to Length(ls) do
      if not (ls[lp] in ['0'..'9','.','E','e','x','+','-']) then
      begin
        fTokenId:=tkText;
        break;
      end;
  end;

end;

procedure TSynTSyn.TypeProc;
var
  lp:integer;
begin
  fRange := rsType;
  fTokenId := tkType;
  lp:=Run;
  while (fLine[Run] in NameChars) do Inc(Run);
  case Copy(fLine+lp,1,Run-lp) of
    'BOOL',
    'INTEGER',
    'UNSIGNED INT',
    'FLOAT',
    'DOUBLE',
    'INTEGER64',
    'STRING',
    'TRANSLATE',
    'NOTE': ;
  else
    fTokenId:=tkWrong;
  end;
end;

procedure TSynTSyn.IdentProc;
begin
  case fRange of
    rsSign: begin
      fTokenId:= tkSymbol;
      while fLine[Run]<>'[' do inc(Run);
      fRange:= rsGroup;
    end;

    rsGroup,
    rsOpenGroup,
    rsCloseGroup: begin
      GroupProc();
    end;

    rsType,
    rsOpenType,
    rsCloseType: begin
      TypeProc();
    end;

    rsProp: begin
      PropProc();
    end;

    rsPoint: begin
      PointProc();
    end;

    rsText: begin
      TextProc();
    end;

  else// inc(Run);
  end;
end;

procedure TSynTSyn.GroupProc;
//var  NameStart: LongInt;
begin
  if fLine[Run] = '/' then
    Inc(Run);
//  NameStart := Run;
  while (fLine[Run] in NameChars) do Inc(Run);

  if fRange = rsOpenGroup  then StartCodeFoldBlock(nil,true);
  if fRange = rsCloseGroup then EndCodeFoldBlock(true);

  fRange := rsGroup;
  fTokenID := tkGroup;
end;

procedure TSynTSyn.Next;
begin
  fTokenPos := Run;
  if (fTokenID = tkSymbol) and (fRange = rsText) then
    TextProc()
  else
    fProcTable[fLine[Run]]();
end;

function TSynTSyn.NextTokenIs(T : String) : Boolean;
var I, Len : Integer;
begin
  Result:= True;
  Len:= Length(T);
  for I:= 1 to Len do
    if (fLine[Run + I] <> T[I]) then
    begin
      Result:= False;
      Break;
    end;
end;

function TSynTSyn.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_NUMBER    : Result := fNumberAttri;
    SYN_ATTR_IDENTIFIER: Result := fGroupAttri;
    SYN_ATTR_KEYWORD   : Result := fTypeAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL    : Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynTSyn.GetEol: Boolean;
begin
  Result := fTokenId = tkNull;
end;

function TSynTSyn.GetToken: string;
var
  len: Longint;
begin
  Result := '';
  Len := (Run - fTokenPos);
  SetString(Result, (FLine + fTokenPos), len);
end;

procedure TSynTSyn.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenLength:=Run-fTokenPos;
  TokenStart:=FLine + fTokenPos;
end;

function TSynTSyn.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TSynTSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case fTokenID of
    tkGroup  : Result:= fGroupAttri;
    tkType   : Result:= fTypeAttri;
    tkProp   : Result:= fPropAttri;
    tkNumber : Result:= fNumberAttri;
    tkText   : Result:= fTextAttri;
    tkSymbol : Result:= fSymbolAttri;
    tkSpace  : Result:= fSpaceAttri;
    tkWrong  : Result:= fWrongAttri;
  else
    Result := nil;
  end;
end;

function TSynTSyn.GetTokenKind: integer;
begin
  Result := Ord(fTokenId);
end;

function TSynTSyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

function TSynTSyn.GetRange: Pointer;
begin
  CodeFoldRange.RangeType:=Pointer(PtrUInt(Integer(fRange)));
  Result := inherited;
end;

procedure TSynTSyn.SetRange(Value: Pointer);
begin
  inherited;
  fRange := TRangeState(Integer(PtrUInt(CodeFoldRange.RangeType)));
end;

procedure TSynTSyn.ReSetRange;
begin
  inherited;
  fRange:= rsText;
end;

function TSynTSyn.GetIdentChars: TSynIdentChars;
begin
  Result := [' ', '0'..'9', 'a'..'z', 'A'..'Z', '_', '.', '-'] + TSynSpecialChars;
end;

class function TSynTSyn.GetLanguageName: string;
begin
  Result := SYNS_LangTorch;
end;


initialization
  RegisterPlaceableHighlighter(TSynTSyn);

end.

