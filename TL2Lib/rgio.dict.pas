{TODO: export as UTF8 binary (UCS16LE right now) - add sign for type: UCS16, UTF8, w/zero}
unit RGIO.Dict;

interface

uses
  TextCache, Dict;

//--- Tags

type
  TExportDictType = (asTags, asText, asBin, asZBin{, asBin8, asZBin8});

type

  TRGDict = object
  private
    FDict:THashDict;
  private
    function  LoadBinary    (aptr:PByte):integer;
    function  LoadTagsFile  (aptr:PByte):integer;
    function  LoadDictionary(aptr:PByte):integer;
    function  LoadList      (aptr:PByte):integer;
  public
    function  Import(aptr: PByte): integer;
    function  Import(const fname:AnsiString=''):integer;
    function  Import(const resname:string; restype:PChar):integer;
    procedure Export(const fname:AnsiString; afmt:TExportDictType=asTags; sortbyhash:boolean=true);
  end;

function LoadTranslation(var aDict:TTransDict; const fname:AnsiString):integer;


implementation

uses
  rgglobal,
  rglogging,
  rgmemory,
  RGIO.Text,
  rgnode;

const
  defdictname = 'dictionary.txt';
  deftagsname = 'tags.dat';

const
  SIGN_UNICODE = $FEFF;
  SIGN_UTF8    = $BFBBEF;


//----- Load -----

//--- binary

{ in: raw data
  4 bytes  = hash
  2 bytes  = length (chars, with or without #0)
  length*2 = text
}
function TRGDict.LoadBinary(aptr:PByte):integer;
var
  pcw:PWideChar;
  i,llen:integer;
  lhash:dword;
begin
  result:=memReadInteger(aptr);
  FDict.Capacity:=result;

  for i:=0 to result-1 do
  begin
    lhash:=memReadInteger(aptr);

    llen:=PWord(aptr)^;
    if llen=0 then
    begin
      inc(aptr,2);
      FDict.Add(nil,lhash);
    end
    else if PWideChar(aptr)[llen]=#0 then
    begin
      pcw:=PWideChar(aptr+2);
      FDict.Add(pcw,lhash);
      inc(aptr,2+llen*2);
    end
    else
    begin
      pcw:=memReadShortString(aptr);
      FDict.Add(pcw,lhash);
      FreeMem(pcw);
    end;
  end;
end;

//--- Tags.dat
{ in: UTF16-LE text in next format
  [Tags]
    <STRING>:text
    <INTEGER>:hash
  	...
  [/Tags]
}
function TRGDict.LoadTagsFile(aptr:PByte):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  lc,i:integer;
begin
  result:=0;

  WideToNode(aptr,0,lnode);
  if lnode<>nil then
  begin
    i:=0;
    lc:=GetChildCount(lnode);
    FDict.Capacity:=lc div 2;

    while i<lc do
    begin
      pcw:=asString(GetChild(lnode,i));
//      if pcw<>nil then
      begin
        FDict.Add(pcw,AsUnsigned(GetChild(lnode,i+1)));
        inc(result);
      end;
      inc(i,2);
    end;
    DeleteNode(lnode);
  end;
end;

//--- dictionary.txt

{ in: UTF8 text in next format
  hash<1-char separator>text
}
function TRGDict.LoadDictionary(aptr:PByte):integer;
var
  lptr,lend:PAnsiChar;
  lcnt,lstart,i,p:integer;
  ltmp:cardinal;
  lhash:dword;
begin
  result:=0;

  lcnt:=0;
  lptr:=PAnsiChar(aptr);
  while lptr^<>#0 do
  begin
    if lptr^=#13 then inc(lcnt);
    inc(lptr);
  end;
  FDict.Capacity:=lcnt;
  
  lend:=PAnsiChar(aptr);
  try
    for i:=0 to lcnt-1 do
    begin
      lptr:=lend;
      while not (lend^ in [#0,#13]) do inc(lend);
      lcnt:=lend-lptr;
      while lend^ in [#1..#32] do inc(lend);

      if lcnt>0 then
      begin
        if lptr^='-' then
          lstart:=1
        else
          lstart:=0;

        ltmp:=0;
        for p:=lstart to lcnt-1 do
        begin
          if (lptr[p] in ['0'..'9']) then
            ltmp:=(ltmp)*10+ORD(lptr[p])-ORD('0')
          else
          begin
            if lstart>0 then
              lhash:=dword(-integer(ltmp))
            else
              lhash:=ltmp;
            FDict.Add(Copy(lptr,p+1+1,lcnt-p-1), lhash); //!!
            inc(result);
            break;
          end;
        end;
      end;

      if lend^=#0 then break;
    end;

  except
    if lcnt>0 then RGLog.Add('Possible problem with '+copy(lptr,1,lcnt));
    FDict.Clear;
  end;
end;

//--- raw text
{ in: UTF8 text
  just text, line by line
}
function TRGDict.LoadList(aptr:PByte):integer;
var
  ls:AnsiString;
  lptr,lend:PByte;
  lcnt,i:integer;
begin
  result:=0;

  lcnt:=0;
  lptr:=aptr;
  while lptr^<>0 do
  begin
    if lptr^=13 then inc(lcnt);
    inc(lptr);
  end;
  FDict.Capacity:=lcnt;
  
  lend:=aptr;
  for i:=0 to lcnt-1 do
  begin
    lptr:=lend;
    while not lend^ in [0,13] do inc(lend);
    SetString(ls, PansiChar(lptr), lend-lptr);
    while lend^ in [1..32] do inc(lend);

    if ls<>'' then
    begin
      FDict.Add(ls, RGHash(pointer(ls),Length(ls))); //!! RGHash not necessary ??
      inc(result);
    end;

    if lend^=0 then break;
  end;
end;

function TRGDict.Import(aptr:PByte):integer;
begin
  if (pword(aptr)^=SIGN_UNICODE) and (aptr[2]=ORD('[')) then
  begin
    result:=LoadTagsFile(aptr)
  end

  else if aptr[3]=0 then
  begin
    result:=LoadBinary(aptr)
  end

  else if (CHAR(aptr[0]) in ['-','0'..'9']) or
      (((pdword(aptr)^ and $FFFFFF)=SIGN_UTF8) and
       ((CHAR(aptr[3]) in ['-','0'..'9']))) then
  begin
    result:=LoadDictionary(aptr);
  end

  else
  begin
    result:=LoadList(aptr);
  end;

//!!  if result>0 then Sort;
end;

function TRGDict.Import(const resname:string; restype:PChar):integer;
var
  res:TFPResourceHandle;
  Handle:THANDLE;
//  lstrm: TResourceStream;
  lptr,buf:PByte;
  lsize,loldcount:integer;
begin
  result:=0;
  loldcount:=FDict.Count;

  res:=FindResource(hInstance, PChar(resname), restype);
  if res<>0 then
  begin
    Handle:=LoadResource(hInstance,Res);
    if Handle<>0 then
    begin
      lptr :=LockResource(Handle);
      lsize:=SizeOfResource(hInstance,res);

      GetMem(buf,lsize+2);
      move(lptr^,buf^,lsize);

      UnlockResource(Handle);
      FreeResource(Handle);

      buf[lsize  ]:=0;
      buf[lsize+1]:=0;

      result:=Import(buf);

      FreeMem(buf);
    end;
  end;
{
  lstrm:=TResourceStream.Create(HINSTANCE,resname, restype);
  try
    result:=Import(lstrm.Memory);
  finally
    lstrm.Free;
  end;
}
  if result=0 then
    RGLog.Add('Can''t load '+resname);

  result:=FDict.Count-loldcount;
end;

function TRGDict.Import(const fname:AnsiString=''):integer;
var
  f:file of byte;
  buf:PByte;
  ls:AnsiString;
  i,loldcount:integer;
begin
  result:=0;
  loldcount:=FDict.Count;
  
  // 1 - trying to open dict file (empty name = load defaults)
  if fname<>'' then
    ls:=fname
  else
    ls:=defdictname;

{$PUSH}
{$I-}
  Assign(f,ls);
  Reset(f);
  if IOResult<>0 then
  begin
    if fname='' then
    begin
      ls:=deftagsname;
      Assign(f,ls);
      Reset(f);
      if IOResult<>0 then
      begin
        if fname='' then
          ls:='default tags file'
        else
          ls:='tag info file "'+fname+'"';
        RGLog.Add('Can''t open '+ls);
        exit;
      end;
    end
    else
    begin
      RGLog.Add('Can''t open '+ls);
      exit;
    end;
  end;
  i:=FileSize(f);
  GetMem(buf,i+2);
  BlockRead(f,buf^,i);
  Close(f);
{$POP}

  buf[i  ]:=0;
  buf[i+1]:=0;

  result:=Import(buf);

  FreeMem(buf);

  if result=0 then
    RGLog.Add('Can''t load '+fname);

  result:=FDict.Count-loldcount;
end;

procedure TRGDict.Export(const fname:AnsiString; afmt:TExportDictType=asTags; sortbyhash:boolean=true);
var
  sl:TRGLog;
  lnode:pointer;
  lstr:UnicodeString;
  i,ldelta,llen:integer;
begin
  case afmt of
    asTags: begin
      lnode:=AddGroup(nil,'TAGS');

      if sortbyhash then FDict.SortBy(0) else FDict.SortBy(1); //!!

      for i:=0 to FDict.Count-1 do
      begin
        AddString (lnode,nil,FDict.Tags[i]);
        AddInteger(lnode,nil,Integer(FDict.Hashes[i]));
      end;
      
      BuildTextFile(lnode,PChar(fname));
      DeleteNode(lnode);
    end;

    asText: begin
      sl.Init;

      if sortbyhash then FDict.SortBy(0) else FDict.SortBy(1); //!!

      for i:=0 to FDict.Count-1 do
      begin
        Str(FDict.Hashes[i],lstr);
        sl.Add(UTF8Encode(lstr+':'+(FDict.Tags[i])));
      end;

      sl.SaveToFile(fname);
      sl.Free;
    end;

    asBin, asZBin: begin
      sl.Init;

      if afmt=asZBin then ldelta:=1 else ldelta:=0;

      sl.Add(FDict.Count,4);

      if sortbyhash then FDict.SortBy(0) else FDict.SortBy(1); //!!

      for i:=0 to FDict.Count-1 do
      begin
        sl.Add(FDict.Hashes[i],4);
        if FDict.Tags[i]=nil then
          sl.Add(0,2)
        else
        begin
          llen:=Length(FDict.Tags[i])+ldelta;
          sl.Add(llen,2);
          sl.Add(FDict.Tags[i],llen*SizeOf(WideChar));
        end;
      end;

      sl.SaveToFile(fname);
      sl.Free;
    end;
  end;
end;

resourcestring
  sNoFileStart     = 'No file starting tag';
  sNoBlockStart    = 'No block start';
  sNoOrignText     = 'No original text';
  sNoTransText     = 'No translated text';
  sNoEndBlock      = 'No end of block';
  sMoreOriginal    = 'More than one original';
  sMoreTranslation = 'More than one translation';

const
  // TRANSLATION.DAT
  sBeginFile   = '[TRANSLATIONS]';
  sEndFile     = '[/TRANSLATIONS]';
  sBeginBlock  = '[TRANSLATION]';
  sEndBlock    = '[/TRANSLATION]';
  sOriginal    = '<STRING>ORIGINAL:';
  sTranslation = '<STRING>TRANSLATION:';


function LoadTranslation(var aDict:TTransDict; const fname:AnsiString):integer;
var
  f:file of byte;
  buf,lstart,lend:PWideChar;
  s,lsrc,ldst:PWideChar;
  lline:integer;
  i,stage:integer;
begin
  result:=0;
  if fname='' then exit;

  Assign(f,fname);
  Reset(f);
  if IOResult<>0 then exit;

  i:=FileSize(f);
  GetMem(buf,i+SizeOf(WideChar));
  BlockRead(f,buf^,i);
  Close(f);
  PByte(buf)[i  ]:=0;
  PByte(buf)[i+1]:=0;
  
  lsrc:='';
  ldst:='';

  lline:=0;
  stage:=1;
  lend:=buf;

  if (pword(lend)^=SIGN_UNICODE) then inc(lend);

  repeat
    if lend^=#0 then break;

    lstart:=lend;
    while not (lend^ in [#0, #10, #13]) do inc(lend);

    if lend^<>#0 then
    begin
      lend^:=#0;
      inc(lend);
    end;
    
    while lend^ in [#10, #13] do inc(lend);

    if lstart^<>#0 then
    begin
      case stage of
        // <STRING>ORIGINAL:
        // <STRING>TRANSLATION:
        // [/TRANSLATION]
        3: begin
          if lsrc=nil then
          begin
            s:=PosWide(sOriginal,lstart);
            if s<>nil then
            begin
              lsrc:=s+Length(sOriginal);
              continue;
            end;
          end
          else
            RGLog.Add(fname,lline,sMoreOriginal);

          if ldst=nil then
          begin
            s:=PosWide(sTranslation,lstart);
            if s<>nil then
            begin
              ldst:=s+Length(sTranslation);
              continue;
            end;
          end
          else
            RGLog.Add(fname,lline,sMoreTranslation);

          if PosWide(sEndBlock,lstart)<>nil then
          begin
            stage:=2;

            if lsrc<>nil then
            begin
              result:=0;

              aDict.Add(lsrc,ldst);
            end
            else// if lsrc='' then
            begin
              RGLog.Add(fname,lline,sNoOrignText);
              result:=-3;
            end;

          end
          // really, can be custom tag
          else
          begin
            RGLog.Add(fname,lline,sNoEndBlock);
            result:=-5;
          end;

        end;

        // [TRANSLATION] and [/TRANSLATIONS]
        2: begin
          if PosWide(sBeginBlock,lstart)<>nil then
          begin
            stage:=3;
            lsrc:=nil;
            ldst:=nil;
          end
          else if PosWide(sEndFile,lstart)<>nil then break // end of file
          else
          begin
            RGLog.Add(fname,lline,sNoBlockStart);
            result:=-2;
          end;
        end;

        // [TRANSLATIONS]
        1: begin
          if PosWide(sBeginFile,lstart)<>nil then
            stage:=2
          else
          begin
            RGLog.Add(fname,lline,sNoFileStart);
            result:=-1;
            break;
          end;
        end;
      end;
    end;
  until false;

  FreeMem(buf);

end;

end.
