{TODO: use sorted hash array to avoid string sort}
{TODO: Manual load of translation (no loaded StringList). Check RGDictLayout}
{TODO: Add support of packed translations}
{TODO: Add support of translation stream}
{TODO: Add support of UTF8 translations (what is for?)}
unit RGTrans;

interface

function  LoadTranslation(var ahandle:pointer; const fname:AnsiString):pointer;
procedure FreeTranslation(var ahandle:pointer);
function  GetTranslation (ahandle:pointer; const src:AnsiString):AnsiString;


implementation

uses
  Classes,
  SysUtils;

type
  PTranslation = ^TTranslation;
  TTranslation = record
    src,dst:TStringList;
    fname:string;
  end;

const
  // TRANSLATION.DAT
  sBeginFile   = '[TRANSLATIONS]';
  sEndFile     = '[/TRANSLATIONS]';
  sBeginBlock  = '[TRANSLATION]';
  sEndBlock    = '[/TRANSLATION]';
  sOriginal    = '<STRING>ORIGINAL:';
  sTranslated  = '<STRING>TRANSLATION:';
  sFile        = '<STRING>FILE:';
  sProperty    = '<STRING>PROPERTY:';

function LoadTranslation(var ahandle:pointer; const fname:AnsiString):pointer;
var
  slin:TStringList;
  s,lsrc,ldst:AnsiString;
  stage,i,lline:integer;
begin
  if (ahandle<>nil) then
    if (PTranslation(ahandle)^.fname=fname) then
      exit(ahandle)
    else
      FreeTranslation(ahandle);

  slin:=TStringList.Create;
  try
    slin.LoadFromFile(fname,TEncoding.Unicode);
  except
    slin.Free;
    exit(nil);
  end;

  lline:=0;
  lsrc:='';
  ldst:='';

  stage:=1;

  while lline<slin.Count do
  begin
    s:=slin[lline];
    if s<>'' then
    begin
      case stage of
        // <STRING>ORIGINAL:
        // <STRING>TRANSLATION:
        // [/TRANSLATION]
        3: begin
          i:=0;
          if (lsrc='') then
          begin
            i:=Pos(sOriginal,s);
            if i<>0 then lsrc:=Copy(s,i+Length(sOriginal));
          end;

          if (i=0) and (ldst='') then
          begin
            i:=Pos(sTranslated,s);
            if i<>0 then ldst:=Copy(s,i+Length(sTranslated));
            //!!!!
            if ldst=lsrc then ldst:='';
          end;

          if (i=0) then
          begin
            if Pos(sEndBlock,s)<>0 then
            begin
              stage:=2;

              if ahandle=nil then
              begin
                GetMem(ahandle,SizeOf(TTranslation));
                FillChar(ahandle^,SizeOf(TTranslation),0);
                PTranslation(ahandle)^.fname:=fname;
                PTranslation(ahandle)^.src:=TStringList.Create;
                with PTranslation(ahandle)^.src do
                begin
                  Sorted:=true;
                  CaseSensitive:=true;
                  Duplicates:=dupIgnore;
                end;
                // Must not be sorted to keep order
                PTranslation(ahandle)^.dst:=TStringList.Create;
              end;

              if (lsrc<>'') {and (ldst<>'')} then
              begin
                i:=PTranslation(ahandle)^.dst.Add(ldst);
                   PTranslation(ahandle)^.src.AddObject(lsrc,TObject(IntPtr(i)));
              end
              else if lsrc='' then
              begin
//!!                break;
{
              end
              else if ldst='' then
              begin
//!!                break;
}
              end;

            end
            else
            begin
//??            break;
            end;
          end;

        end;

        // [TRANSLATION] and [/TRANSLATIONS]
        2: begin
          if Pos(sBeginBlock,s)<>0 then
          begin
            stage:=3;
            lsrc:='';
            ldst:='';
          end
          else if Pos(sEndFile,s)<>0 then break // end of file
          else
          begin
//??            break;
          end;
        end;

        // [TRANSLATIONS]
        1: begin
          if Pos(sBeginFile,s)<>0 then
            stage:=2
          else
          begin
            break;
          end;
        end;
      end;
    end;
    inc(lline);
  end;

  slin.Free;
  result:=ahandle;
end;

function GetTranslation(ahandle:pointer; const src:AnsiString):AnsiString;
var
  i:integer;
begin
  if src='' then exit('');

  if (ahandle<>nil) and (PTranslation(ahandle)^.src.Find(src,i)) then
    result:=PTranslation(ahandle)^.dst[
     IntPtr(PTranslation(ahandle)^.src.Objects[i])]
  else
    result:=src;
end;

procedure FreeTranslation(var ahandle:pointer);
begin
  if ahandle<>nil then
  begin
    PTranslation(ahandle)^.src.Free;
    PTranslation(ahandle)^.dst.Free;
    PTranslation(ahandle)^.fname:='';
    FreeMem(ahandle);
    ahandle:=nil;
  end;
end;

end.
