unit RGTrans;

interface

{
  Use like this:;
  Load(fname,@TransAddText,nil,ahandle);
}

// think on replace "of object" by "aparam"
type
  TTransAddPlace = function(const astr,afile,atag:pointer; isutf8:Boolean; aparam:pointer):integer;
  TTransAddText  = function(const astr,atrans    :pointer; isutf8:Boolean; aparam:pointer):integer;

function Load(buf:PByte;
      OnAddText:TTransAddText;
      OnAddPlace:TTransAddPlace=nil;
      aParam:pointer=nil):integer;

function Load(const fname:AnsiString;
      OnAddText:TTransAddText;
      OnAddPlace:TTransAddPlace=nil;
      aParam:pointer=nil):integer;


function  NewTranslation ():pointer;
procedure FreeTranslation(var ahandle:pointer);
function  LoadTranslation(var ahandle:pointer; const fname:AnsiString):pointer;
function  AddTranslation (    ahandle:pointer; const src,dst:AnsiString):boolean;
function  GetTranslation (    ahandle:pointer; const src:AnsiString):AnsiString;

implementation

uses
  rgglobal,
  rgnode,
  rgio.dat,

  Classes,
  SysUtils;

const
  // TRANSLATION.DAT
  sBeginFile   = '[TRANSLATIONS]';
  sEndFile     = '[/TRANSLATIONS]';
  sBeginBlock  = '[TRANSLATION]';
  sEndBlock    = '[/TRANSLATION]';
  sOriginal    = '<STRING>ORIGINAL:';
  sTranslation = '<STRING>TRANSLATION:';
  sFile        = '<STRING>FILE:';
  sProperty    = '<STRING>PROPERTY:';

resourcestring
  rsNoFileStart     = 'No file starting tag';
  rsNoBlockStart    = 'No block start';
  rsNoOrignText     = 'No original text';
// next line commented coz no translation case is ok, just use original
//  rsNoTransText     = 'No translated text';
  rsNoEndBlock      = 'No end of block';
  rsMoreOriginal    = 'More than one original';
  rsMoreTranslation = 'More than one translation';


function ProcessAsWide(atext:PWideChar;
    OnAddText:TTransAddText; OnAddPlace:TTransAddPlace; aParam:pointer):integer;
var
  lstart,lend:PWideChar;
  lsrc,ldst,lfile,ltag:PWideChar;
  lline:integer;
  stage:integer;
begin
  result:=0;

  lsrc :=nil;
  ldst :=nil;
  lfile:=nil;
  ltag :=nil;


  lline:=0;
  stage:=1;
  lend:=atext;

  if (pword(lend)^=SIGN_UNICODE) then inc(lend);

  repeat
    if lend^=#0 then break;

    inc(lline);
    lstart:=lend;
    while not (ord(lend^) in [0, 10, 13]) do inc(lend);

    if lend^<>#0 then
    begin
      lend^:=#0;
      inc(lend);
    end;
    
    while ord(lend^) in [10, 13] do inc(lend);

    while ord(lstart^) in [9, 32] do inc(lstart);
    if lstart^<>#0 then
    begin
      case stage of
        // <STRING>ORIGINAL:
        // <STRING>TRANSLATION:
        // <STRING>FILE:
        // <STRING>PROPERTY:
        // [/TRANSLATION]
        3: begin
          if lstart^='<' then
          begin
            if lsrc=nil then
            begin
              if CompareWide(sOriginal,lstart,Length(sOriginal))=0 then
              begin
                lsrc:=lstart+Length(sOriginal){*SizeOf(WideChar)};
                continue;
              end;
            end;

            if ldst=nil then
            begin
              if CompareWide(sTranslation,lstart,Length(sTranslation))=0 then
              begin
                ldst:=lstart+Length(sTranslation){*SizeOf(WideChar)};
                continue;
              end;
            end;

            if lfile=nil then
            begin
              if CompareWide(sFile,lstart,Length(sFile))=0 then
              begin
                lfile:=lstart+Length(sFile){*SizeOf(WideChar)};
                continue;
              end;
            end;

            if ltag=nil then
            begin
              if CompareWide(sProperty,lstart,Length(sProperty))=0 then
              begin
                ltag:=lstart+Length(sProperty){*SizeOf(WideChar)};
                continue;
              end;
            end;

          end
          else if (lstart^='[') then
          begin
            if (lstart[1]='/') then
            begin
              if CompareWide(sEndBlock,lstart,Length(sEndBlock))=0 then
              begin
                stage:=2;

                if lsrc<>nil then
                begin
                  inc(result);

                  if Assigned(OnAddPlace) and (lfile<>nil) and (lfile^<>#0) then
                    OnAddPlace(lsrc,lfile,ltag, false, aParam);

                  if Assigned(OnAddText) then
                    OnAddText(lsrc,ldst, false, aParam);

                  continue;
                end
                else// if lsrc='' then
                begin
                  RGLog.Add('',lline,rsNoOrignText);
                end;

              end
              // really, can be custom group
              else
              begin
                RGLog.Add('',lline,rsNoEndBlock);
              end;
            end
            // case when new block start without end of previous
            else if CompareWide(sBeginBlock,lstart,Length(sBeginBlock))=0 then
            begin
              lsrc :=nil;
              ldst :=nil;
              lfile:=nil;
              ltag :=nil;
              continue;
            end
            else
             ; // custom group?
          end;

        end;

        // [TRANSLATION] and [/TRANSLATIONS]
        2: begin
          if lstart^='[' then
          begin
            if CompareWide(sBeginBlock,lstart,Length(sBeginBlock))=0 then
            begin
              stage:=3;
              lsrc :=nil;
              ldst :=nil;
              lfile:=nil;
              ltag :=nil;
              continue;
            end
            else if (lstart[1]='/') and
                    (CompareWide(sEndFile,lstart,Length(sEndFile))=0) then break;
          end;
          RGLog.Add('',lline,rsNoBlockStart);
        end;

        // [TRANSLATIONS]
        1: begin
          if CompareWide(sBeginFile,lstart,Length(sBeginFile))=0 then
            stage:=2
          else
          begin
            RGLog.Add('',lline,rsNoFileStart);
            break;
          end;
        end;
      end;
    end;
  until false;

end;

function ProcessAsUTF8(atext:PAnsiChar;
    OnAddText:TTransAddText; OnAddPlace:TTransAddPlace; aParam:pointer):integer;
var
  lstart,lend:PAnsiChar;
  lsrc,ldst,lfile,ltag:PAnsiChar;
  lline:integer;
  stage:integer;
begin
  result:=0;

  lsrc :=nil;
  ldst :=nil;
  lfile:=nil;
  ltag :=nil;

  lline:=0;
  stage:=1;
  lend:=atext;

  if ((PDWord(lend)^ and $FFFFFF)=SIGN_UTF8) then inc(lend,3);

  repeat
    if lend^=#0 then break;

    inc(lline);
    lstart:=lend;
    while not (ord(lend^) in [0, 10, 13]) do inc(lend);

    if lend^<>#0 then
    begin
      lend^:=#0;
      inc(lend);
    end;
    
    while ord(lend^) in [10, 13] do inc(lend);

    while ord(lstart^) in [9, 32] do inc(lstart);
    if lstart^<>#0 then
    begin
      case stage of
        // <STRING>ORIGINAL:
        // <STRING>TRANSLATION:
        // <STRING>FILE:
        // <STRING>PROPERTY:
        // [/TRANSLATION]
        3: begin
          if lstart^='<' then
          begin
            if lsrc=nil then
            begin
              if CompareAnsi(sOriginal,lstart,Length(sOriginal))=0 then
              begin
                lsrc:=lstart+Length(sOriginal);
                continue;
              end;
            end;

            if ldst=nil then
            begin
              if CompareAnsi(sTranslation,lstart,Length(sTranslation))=0 then
              begin
                ldst:=lstart+Length(sTranslation);
                continue;
              end;
            end;

            if lfile=nil then
            begin
              if CompareAnsi(sFile,lstart,Length(sFile))=0 then
              begin
                lfile:=lstart+Length(sFile);
                continue;
              end;
            end;

            if ltag=nil then
            begin
              if CompareAnsi(sProperty,lstart,Length(sProperty))=0 then
              begin
                ltag:=lstart+Length(sProperty);
                continue;
              end;
            end;

          end
          else if (lstart^='[') then
          begin
            if (lstart[1]='/') then
            begin
              if CompareAnsi(sEndBlock,lstart,Length(sEndBlock))=0 then
              begin
                stage:=2;

                if lsrc<>nil then
                begin
                  inc(result);

                  if Assigned(OnAddPlace) and (lfile<>nil) and (lfile^<>#0) then
                    OnAddPlace(lsrc,lfile,ltag, true, aParam);

                  if Assigned(OnAddText) then
                    OnAddText(lsrc,ldst, true, aParam);

                  continue;
                end
                else// if lsrc='' then
                begin
                  RGLog.Add('',lline,rsNoOrignText);
                end;

              end
              // really, can be custom group
              else
              begin
                RGLog.Add('',lline,rsNoEndBlock);
              end;
            end
            // case when new block start without end of previous
            else if CompareAnsi(sBeginBlock,lstart,Length(sBeginBlock))=0 then
            begin
              lsrc :=nil;
              ldst :=nil;
              lfile:=nil;
              ltag :=nil;
              continue;
            end
            else
             ; // custom group?
          end;

        end;

        // [TRANSLATION] and [/TRANSLATIONS]
        2: begin
          if lstart^='[' then
          begin
            if CompareAnsi(sBeginBlock,lstart,Length(sBeginBlock))=0 then
            begin
              stage:=3;
              lsrc :=nil;
              ldst :=nil;
              lfile:=nil;
              ltag :=nil;
              continue;
            end
            else if (lstart[1]='/') and
                    (CompareAnsi(sEndFile,lstart,Length(sEndFile))=0) then break;
          end;
          RGLog.Add('',lline,rsNoBlockStart);
        end;

        // [TRANSLATIONS]
        1: begin
          if CompareAnsi(sBeginFile,lstart,Length(sBeginFile))=0 then
            stage:=2
          else
          begin
            RGLog.Add('',lline,rsNoFileStart);
            break;
          end;
        end;
      end;
    end;
  until false;

end;

function ProcessAsNode(var anode:pointer;
     OnAddText:TTransAddText; OnAddPlace:TTransAddPlace; aParam:pointer):integer;
var
  pt,ps:pointer;
  i,j:integer;
  lsrc,ldst,lfile,ltag:PWideChar;
  pcw:PWideChar;
begin
  result:=0;

  if CompareWide(GetNodeName(anode),'TRANSLATIONS')<>0 then
    exit;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    pt:=GetChild(anode,i);
    if (GetNodeType(pt)=rgGroup) and (CompareWide(GetNodeName(pt),'TRANSLATION')=0) then
    begin
      lsrc :=nil;
      ldst :=nil;
      lfile:=nil;
      ltag :=nil;
      for j:=0 to GetChildCount(pt)-1 do
      begin
        ps:=GetChild(pt,j);
        if GetNodeType(ps)=rgString then
        begin
          pcw:=GetNodeName(ps);
          if      CompareWide(pcw,'ORIGINAL'   )=0 then lsrc :=AsString(ps)
          else if CompareWide(pcw,'TRANSLATION')=0 then ldst :=AsString(ps)
          else if CompareWide(pcw,'FILE'       )=0 then lfile:=AsString(ps)
          else if CompareWide(pcw,'PROPERTY'   )=0 then ltag :=AsString(ps);
//          if (src<>nil) and (dst<>nil) then break;
        end;
      end;
      if (lsrc<>'') {and (ldst<>'')} then
      begin
        if CompareWide(lsrc,ldst)=0 then ldst:=nil;

        if Assigned(OnAddPlace) and (lfile<>nil) then
          OnAddPlace(lsrc,lfile,ltag, false, aParam);

        if Assigned(OnAddText) then
          OnAddText(lsrc,ldst, false, aParam);

        inc(result);
      end
    end;
  end;
end;

function Load(buf:PByte;
      OnAddText:TTransAddText;
      OnAddPlace:TTransAddPlace=nil;
      aParam:pointer=nil):integer;
var
  p:pointer;
  ls:AnsiString;
begin
  result:=0;

  // binary
  if pdword(buf)^=2 then
  begin
    p:=ParseDatMem(buf);
    if p<>nil then
      result:=ProcessAsNode(p, OnAddText, OnAddPlace, aParam);
    DeleteNode(p);
  end
  // utf16le
  else if (PDWord(buf)^=(SIGN_UNICODE+(ORD('[') shl 16))) or
          (PWord (buf)^=ORD('[')) then
  begin
    result:=ProcessAsWide(PUnicodeChar(buf), OnAddText, OnAddPlace, aParam);
  end  
  // utf8
  else if (PDWord(buf)^=(SIGN_UTF8   +(ORD('[') shl 24))) or
       ((AnsiChar(buf^)='[') and
        (AnsiChar(buf[1]) in [']','_','0'..'9','A'..'Z','a'..'z'])) then
  begin
    result:=ProcessAsUTF8(PAnsiChar(buf), OnAddText, OnAddPlace, aParam);
  end  
  else
    exit;// bad data

  Str(result,ls);
  RGLog.Add('Total: '+ls+' lines');
end;

function Load(const fname:AnsiString;
      OnAddText:TTransAddText;
      OnAddPlace:TTransAddPlace=nil;
      aParam:pointer=nil):integer;
var
  buf:PByte;
  f:file of byte;
//  st:TFileStream;
  lsize:integer;
begin
  result:=0;
  if fname='' then exit;

  Assign(f,fname);
  Reset(f);
  if IOResult=0 then
  begin
    lsize:=FileSize(f);
    if lsize>4 then
    begin
      GetMem(buf,lsize+2);
      BlockRead(f,buf^,lsize);
      buf[lsize  ]:=0;
      buf[lsize+1]:=0;
    end;
    Close(f);
  end
  else
    exit;
  if lsize<=4 then exit;
{
  st:=nil;
  try
    st:=TFileStream.Create(fname,fmOpenRead);
    GetMem(buf,st.size+2);
    st.Read(buf^,st.size);
    buf[st.size  ]:=0;
    buf[st.size+1]:=0;
  except
    if buf<>nil then FreeMem(buf);
    st.Free;
    exit;
  end;
  st.Free;
}  
  result:=Load(buf, OnAddText, OnAddPlace, aParam);

  FreeMem(buf);
end;

//============================================================================

type
  PTranslation = ^TTranslation;
  TTranslation = record
    src,dst:TStringList;
    fname:string;
  end;


function TransAddText(const astr,atrans:pointer;
     isutf8:Boolean; aparam:pointer):integer;
var
  lsrc,ldst:AnsiString;
begin
  result:=0;
  if isutf8 then
  begin
    UTF8String(lsrc):=PUTF8Char(astr);
    UTF8String(ldst):=PUTF8Char(atrans);
  end
  else
  begin
    lsrc:=WideToStr(astr);
    ldst:=WideToStr(atrans);
  end;
  PTranslation(aparam)^.src.AddObject(lsrc,
      TObject(IntPtr(PTranslation(aparam)^.dst.Add(ldst))));
end;


function NewTranslation():pointer;
begin
  GetMem  (result ,SizeOf(TTranslation));
  FillChar(result^,SizeOf(TTranslation),0);
  PTranslation(result)^.fname:='';
  PTranslation(result)^.src  :=TStringList.Create;
  with PTranslation(result)^.src do
  begin
    Sorted       :=true;
    CaseSensitive:=true;
    Duplicates   :=dupIgnore;
  end;
  // Must not be sorted to keep order
  PTranslation(result)^.dst:=TStringList.Create;
end;

function LoadTranslation(var ahandle:pointer; const fname:AnsiString):pointer;
begin
  if (ahandle<>nil) then
  begin
    if (PTranslation(ahandle)^.fname=fname) then
      exit(ahandle)
    else
      FreeTranslation(ahandle);
  end;

  ahandle:=NewTranslation();
  PTranslation(ahandle)^.fname:=fname;

  Load(fname,@TransAddText,nil,ahandle);

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

function AddTranslation(ahandle:pointer; const src,dst:AnsiString):boolean;
//var i,lcnt:integer;
begin
  result:=false;
  if src='' then exit;

  if (ahandle<>nil) then
  begin
    result:=true;
    PTranslation(ahandle)^.src.AddObject(src,
      TObject(IntPtr(PTranslation(ahandle)^.dst.Add(dst))));
{
    lcnt:=PTranslation(ahandle)^.src.Count;
    lidx:=PTranslation(ahandle)^.src.Add(src);
    if lcnt<PTranslation(ahandle)^.src.Count then
    begin
      result:=true;
      PTranslation(ahandle)^.src.Objects[lidx]:=
        TObject(IntPtr(PTranslation(ahandle)^.dst.Add(dst)));
    end;
}
  end;
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
