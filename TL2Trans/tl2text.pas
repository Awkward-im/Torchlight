unit TL2Text;

interface

function RemoveTags(const src:AnsiString):AnsiString;

function RemoveColor(const textin:AnsiString; var textout:AnsiString):boolean;
function InsertColor(const aselected, acolor:AnsiString):AnsiString;

function ReplaceTranslation(const srcText,srcData:AnsiString):AnsiString;
function FilteredString(const astr:AnsiString):AnsiString;
procedure SetFilterWords(const atext:AnsiString);

function CheckPunctuation(const src:AnsiString; var target:AnsiString; checkonly:boolean=true):boolean;


implementation

uses
  SysUtils;

const
  sColorSuffix = #124'u';
  sColorPrefix = #124'c';

var
  filter: TStringArray=nil;

function InsertColor(const aselected, acolor:AnsiString):AnsiString;
var
  ls:AnsiString;
  l:integer;
begin
  if aselected<>'' then
  begin
    ls:=aselected;
    l:=Length(ls);
    if ((l<2  ) or (ls[l-1]<>'|') or (ls[l]<>'u')) and
       ((l<>10) or (ls[  1]<>'|') or (ls[2]<>'c')) then
      ls:=ls+'|u';
    if (l<10) or (ls[1]<>'|') or (ls[2]<>'c') then
      ls:=acolor+ls
    else
    begin
      ls[ 3]:=acolor[ 3];
      ls[ 4]:=acolor[ 4];
      ls[ 5]:=acolor[ 5];
      ls[ 6]:=acolor[ 6];
      ls[ 7]:=acolor[ 7];
      ls[ 8]:=acolor[ 8];
      ls[ 9]:=acolor[ 9];
      ls[10]:=acolor[10];
    end;
    result:=ls;
  end
  else
    result:=acolor;
end;

function RemoveColor(const textin:AnsiString; var textout:AnsiString):boolean;
var
  ls:AnsiString;
  i,j:integer;
begin
  result:=false;
  i:=1;
  j:=0;
  SetLength(ls,Length(textin));
  while i<=Length(textin) do
  begin
    if textin[i]<>'|' then
    begin
      inc(j);
      ls[j]:=textin[i];
      inc(i);
    end
    else
    begin
      result:=true;
      inc(i);
      if      textin[i]='u' then inc(i)
      else if textin[i]='c' then inc(i,9);
    end;
  end;
  SetLength(ls,j);
  textout:=ls;
end;

function RemoveTags(const src:AnsiString):AnsiString;
begin
  RemoveColor(src,result);
  result:=StringReplace(result,'\n',' ',[rfReplaceAll]);
end;

procedure SetFilterWords(const atext:AnsiString);
begin
  Filter:=atext.Split(' ');
end;

{
  convert letters to lowcase
  remove color information
  remove numbers
  !! KEEP '_','+','%' as significat chars
  remove \n and other punctuation
}
function FilteredString(const astr:AnsiString):AnsiString;
const
  sWord = ['A'..'Z','_','a'..'z','0'..'9'];
var
  lword:String[15];
  p:PAnsiChar;
  i,j,k,ldi:integer;
  b,wasletter:boolean;
begin
  result:='';
  SetLength(result,Length(astr));
  ldi:=1;
  i:=1;
  wasletter:=false;
  while i<=Length(astr) do
  begin
    case astr[i] of
      '0'..'9': begin
        wasletter:=true;
      end;

      '-': begin
        p:=pointer(astr)+i;
        if p^ in ['[','0'..'9'] then
        begin
          result[ldi]:='-';
          inc(ldi);
        end;
        wasletter:=false;
      end;

      '_','+','%': begin
        result[ldi]:=astr[i];
        inc(ldi);
        wasletter:=false;
      end;

      'a'..'z',
      'A'..'Z': begin
        // Filter
        if not wasletter then
        begin
          p:=pointer(astr)+i-1;
          j:=0;
          // 1 - get word
          lword:='';
          while p^ in sWord do
          begin
            // numbers will convert to crap but we don't worry about it
            if p^ in ['A'..'Z'] then
              lword:=lword+AnsiChar(ORD(p^)+ORD('a')-ORD('A'))
            else
              lword:=lword+p^;
            inc(p);
            inc(j);
          end;
          // 2 - search word
          b:=false;
          for k:=0 to High(Filter) do
          begin
            if lword=Filter[k] then
            begin
              b:=true;
              break;
            end;
          end;
          if b then
          begin
            inc(i,j);
            continue;
          end;
        end;

        case astr[i] of
          'a'..'z': begin
            // Suffixes
            p:=pointer(astr)+i-1;
            // ex. master's
            if (i>2) and (p^='s') and
               ((p-1)^ in ['''','`']) and
               ((p-2)^ in sWord) and
               not ((p+1)^ in sWord) then
            begin
             inc(i);
             continue;
            end;
            if wasletter then
            begin
              // Ex. mastered or provides
              if (p^='e') and ((p+1)^ in ['d','s']) and
                 not ((p+2)^ in sWord) then
              begin
                inc(i,2);
                continue;
              end
              // mastering
              else if (p^='i') and ((p+1)^='n') and
                  ((p+2)^='g') and not ((p+3)^ in sWord) then
              begin
                inc(i,3);
                continue;
              end
              // ex. Sells
              else if (p^='s') and not ((p+1)^ in sWord) then
              begin
               inc(i);
               continue;
              end;

            end;

            // regular letters
            result[ldi]:=astr[i];
            inc(ldi);
            wasletter:=true;
          end;

          'A'..'Z': begin
            // Roman numbers
            if (astr[i] in ['I','V','X']) and not wasletter then
            begin
              p:=pointer(astr)+i-1;
              j:=0;
              repeat
                inc(p); inc(j);
              until not (p^ in ['I','V','X']);
              if not (p^ in sWord) then
              begin
                inc(i,j);
                continue;
              end;
            end;

            // Regular letters
            result[ldi]:=AnsiChar(ORD(astr[i])-ORD('A')+ORD('a'));
            inc(ldi);
            wasletter:=true;
          end;
        end;
      end;

      '\': begin // skip ANY slash combo
        inc(i);
        // special for \\n
        if (i<Length(astr)) and (astr[i]='\') and (astr[i+1]='n') then inc(i);
        wasletter:=false;
{
        if astr[i]='n' then
        begin
        end;
}
      end;

      #124: begin
        inc(i);
        if astr[i]='u' then
        begin
        end
        else if astr[i]='c' then
        begin
          inc(i,8);
        end;
        wasletter:=false;
      end;

      '<','[': begin
        k:=i;
        // value type
        if astr[i]='[' then
        begin
          if (i<Length(astr)) and (astr[i+1]='[') then 
          begin
            inc(i);
            j:=2
          end
          else 
            j:=1;
        end
        else // if astr[i]='<'
          j:=0;
        inc(i);

        while (i<=Length(astr)) and (astr[i] in ['A'..'Z','a'..'z','0'..'9',':']) do inc(i);
        if (i>Length(astr)) or
           ((j<>0) and (astr[i]='>')) or
           ((j= 0) and (astr[i]=']')) or
           ((j= 2) and ((i=Length(astr))) and (astr[i+1]<>']')) then
        begin
          i:=k;
        end
        else if j=2 then inc(i);
        
        wasletter:=false;
      end;

    else // any other symbols
      wasletter:=false;
    end;
    inc(i);
  end;
  SetLength(result,ldi-1);

  for i:=1 to ldi-1 do
  begin
    if result[i] in ['A'..'Z','a'..'z'] then exit;
  end;
  result:='';
end;

function ReplaceTranslation(const srcText,srcData:AnsiString):AnsiString;
const
  sWordSet = ['A'..'Z','a'..'z',#128..#255];
var
  colors :array [0.. 7] of String[10]; //#124'cAARRGGBB', 8 times per text must be enough
  numbers:array [0..15] of String[9];
  rome   :array [0.. 7] of String[7];
  lr:String[7];
  pc:PAnsiChar;
  lsrc,ldst:AnsiString;
  i,j,k:integer;
  lcntSC,lcntSN,lcntDC,lcntDN:integer;
  lcntSR,lcntDR:integer;
begin
  //-- make translation template, count source colors and numbers

  lcntSC:=0;
  lcntSN:=0;
  lcntSR:=0;
  i:=0;
  j:=1;
  pc:=pointer(srcText);
  SetLength(lsrc,Length(srcText)+16*10);
  while pc[i]<>#0 do
  begin
    //--- Color
    if (pc[i]=#124) then
    begin
      inc(i);
      if (pc[i]='c') then
      begin
        lsrc[j]:='%'; inc(j);
        lsrc[j]:='s'; inc(j);
        inc(i);

        SetLength(colors[lcntSC],10);
        colors[lcntSC][ 1]:=#124;
        colors[lcntSC][ 2]:='c';
        colors[lcntSC][ 3]:=pc[i]; inc(i);
        colors[lcntSC][ 4]:=pc[i]; inc(i);
        colors[lcntSC][ 5]:=pc[i]; inc(i);
        colors[lcntSC][ 6]:=pc[i]; inc(i);
        colors[lcntSC][ 7]:=pc[i]; inc(i);
        colors[lcntSC][ 8]:=pc[i]; inc(i);
        colors[lcntSC][ 9]:=pc[i]; inc(i);
        colors[lcntSC][10]:=pc[i]; inc(i);

        inc(lcntSC);
      end
      else if pc[i]='u' then
      begin
        lsrc[j]:='|'; inc(j);
        lsrc[j]:='u'; inc(j);
        inc(i);
      end;
    end
    //--- New Line
    else if (pc[i]='\' ) and (pc[i+1]='n') then
    begin
      lsrc[j]:='\'; inc(j);
      lsrc[j]:='n'; inc(j);
     inc(i,2);
    end
    //--- Roman numbers
    else if (i>0) and (pc[i] in ['I','V','X']) then
    begin
      k:=i;
      lr:='';
      repeat
        lr:=lr+pc[i];
        inc(i);
      until not (pc[i] in ['I','V','X']);
      // if it was part of word, skip it
      if pc[i] in sWordSet+['0'..'9'] then
      begin
        i:=k;
        repeat
          lsrc[j]:=pc[i]; inc(j); inc(i);
        until not (pc[i] in sWordSet+['0'..'9']);
      end
      else
      begin
        lsrc[j]:='%'; inc(j);
        lsrc[j]:='r'; inc(j);
        rome[lcntSR]:=lr;
        inc(lcntSR);
      end;
    end
    //--- Words
    else if pc[i] in sWordSet then
    begin
      repeat
        lsrc[j]:=pc[i]; inc(j); inc(i);
      until not (pc[i] in sWordSet+['0'..'9']);
{
      while pc[i] in sWordSet+['0'..'9'] do
      begin
        lsrc[j]:=pc[i]; inc(j); inc(i);
      end;
}
    end
    //--- Numbers starting from point
    else if (pc[i]='.') and (pc[i+1] in ['0'..'9']) then
    begin
      lsrc[j]:='%'; inc(j);
      lsrc[j]:='d'; inc(j);

      numbers[lcntSN]:='0.';
      inc(i);
      while (pc[i] in ['0'..'9']) do
      begin
        numbers[lcntSN]:=numbers[lcntSN]+pc[i];
        inc(i);
      end;

      inc(lcntSN);
    end
    //--- Numbers
    else if (pc[i] in ['0'..'9']) then
    begin
      lsrc[j]:='%'; inc(j);
      lsrc[j]:='d'; inc(j);

      numbers[lcntSN]:='';
      while (pc[i] in ['0'..'9']) do
      begin
        numbers[lcntSN]:=numbers[lcntSN]+pc[i];
        inc(i);
        if (pc[i] in ['.',',']) and (pc[i+1] in ['0'..'9']) then
        begin
          numbers[lcntSN]:=numbers[lcntSN]+'.';
          inc(i);
        end;
      end;

      inc(lcntSN);
    end
    //--- Any other
    else
    begin
      lsrc[j]:=pc[i]; inc(j); inc(i);
    end;
  end;
  SetLength(lsrc,j-1);

  //-- fill color and number arrays, count them in sample

  lcntDC:=0;
  lcntDN:=0;
  lcntDR:=0;
  i:=0;
  pc:=pointer(srcData);
  while pc[i]<>#0 do
  begin
    //--- Color
    if (pc[i]=#124) then
    begin
      inc(i);
      if (pc[i]='c') then
      begin
        inc(i);
        SetLength(colors[lcntDC],10);
        colors[lcntDC][ 1]:=#124;
        colors[lcntDC][ 2]:='c';
        colors[lcntDC][ 3]:=pc[i]; inc(i);
        colors[lcntDC][ 4]:=pc[i]; inc(i);
        colors[lcntDC][ 5]:=pc[i]; inc(i);
        colors[lcntDC][ 6]:=pc[i]; inc(i);
        colors[lcntDC][ 7]:=pc[i]; inc(i);
        colors[lcntDC][ 8]:=pc[i]; inc(i);
        colors[lcntDC][ 9]:=pc[i]; inc(i);
        colors[lcntDC][10]:=pc[i]; inc(i);
        inc(lcntDC);
      end
      else if pc[i]='u' then
      begin
        inc(i);
      end;
    end
    //--- New Line
    else if (pc[i]='\' ) and (pc[i+1]='n') then
    begin
     inc(i,2);
    end
    //--- Roman numbers
    else if (i>0) and (pc[i] in ['I','V','X']) then
    begin
      k:=i;

      lr:='';
      repeat
        lr:=lr+pc[i];
        inc(i);
      until not (pc[i] in ['I','V','X']);

      if pc[i] in sWordSet+['0'..'9'] then
      begin
        i:=k;
        repeat
          inc(i);
        until not (pc[i] in sWordSet+['0'..'9']);
      end
      else
      begin
        rome[lcntDR]:=lr;
        inc(lcntDR);
      end;
    end
    //--- Words
    else if pc[i] in sWordSet then
    begin
      repeat
        inc(i);
      until not (pc[i] in sWordSet+['0'..'9']);
{
      while pc[i] in sWordSet+['0'..'9'] do
      begin
        inc(i);
      end;
}
    end
    //--- Numbers starting from dot
    else if (pc[i]='.') and (pc[i+1] in ['0'..'9']) then
    begin
      numbers[lcntDN]:='0.';
      inc(i);
      while (pc[i] in ['0'..'9']) do
      begin
        numbers[lcntDN]:=numbers[lcntDN]+pc[i];
        inc(i);
      end;

      inc(lcntDN);
    end
    //--- Numbers
    else if (pc[i] in ['0'..'9']) then
    begin
      numbers[lcntDN]:='';
      while (pc[i] in ['0'..'9']) do
      begin
        numbers[lcntDN]:=numbers[lcntDN]+pc[i];
        inc(i);
        if (pc[i] in ['.',',']) and (pc[i+1] in ['0'..'9']) then
        begin
          numbers[lcntDN]:=numbers[lcntDN]+pc[i];
          inc(i);
        end;
      end;
      inc(lcntDN);
    end
    //--- Any other
    else
    begin
      inc(i);
    end;
  end;

  //-- replace source by sample

  ldst:=lsrc;

  for i:=0 to lcntSR-1 do
    ldst:=StringReplace(ldst,'%r',rome[i],[]);

  for i:=0 to lcntSN-1 do
    ldst:=StringReplace(ldst,'%d',numbers[i],[]);

  // just one coloration added (for items usually)
  if (lcntSC=0) and (lcntDC=1) and
     (Pos(sColorPrefix,srcData)=1) then
  begin
    ldst:=colors[0]+ldst;
    // check for color suffix at the end
    if (srcData[Length(srcData)-1]=#124) and
       (srcData[Length(srcData)  ]='u' ) then
      ldst:=ldst+sColorSuffix;
  end
  else
  begin
    for i:=0 to lcntSC-1 do
      ldst:=StringReplace(ldst,'%s',colors[i],[]);
  end;

  result:=ldst;
end;


{
  code can be simplified coz src must have text with something for translation (not empty, with words)
  if source words must be longer than 1 letter, can be simplified even more
}
function CheckPunctuation(const src:AnsiString; var target:AnsiString; checkonly:boolean=true):boolean;
var
  i,j:integer;
  isDSpace,isSpace:boolean;
  lsrc,ldst:Char;
begin
  result:=false;

  j:=Length(target);
  if j>0 then
  begin
    isSpace:=false;
    i:=Length(src);
    if i>0 then  // empty lines blocked by program, so it always true
    begin
      // 1 - skip trailing spaces (keep it's check to the end)
      while (src[i]=' ') and (i>0) do
      begin
        dec(i);
        isSpace:=true;
      end;

      // 2 - check for quotes and other punctuation
      if src[i]='"' then dec(i);
      if src[i] in ['.', '!', '?', ':', ';'] then
        lsrc:=src[i]
      else
        lsrc:=#0;

      isDSpace:=false;
      while (target[j]=' ') and (j>0) do
      begin
        dec(j);
        isDSpace:=true;
      end;

      if target[j]='"' then dec(j);
      if target[j] in ['.', '!', '?', ':', ';'] then
        ldst:=target[j]
      else
        ldst:=#0;

      if (( isSpace   xor  isDSpace) or     // no both spaces or
          ((lsrc =#0) xor (ldst =#0))) then // no both signs
      begin
        if not checkonly then
        begin
          if ldst=#0 then Insert(lsrc,target,j+1);
          if isSpace then target:=target+' ';
        end;
        result:=true;
        exit;
      end;
    end;
  end;
end;

finalization
  SetLength(Filter,0);

end.
