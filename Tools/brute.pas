const
  alphabet:array of Ansichar = 'ETAOINSRHDL_0123456789UCMFYWGPBVKXQJZ%- .';

function brutehashrecursion(targethash:dword; level:integer; var lasthash:dword;
    const guess:string; var wguess:string):bool;
// You should copy guess to a separate string named wguess before invoking.
// Otherwise, you get really weird behavior that modifies the string sometimes, but not always
// resulting in the algortithm getting borked pretty hard
var
  i:integer;
begin
  if level = Length(guess) then
  begin
    lasthash := computehash(wguess);
    if lasthash = targethash then
    begin
      writeln(wguess);
      exit(true);
    end;
    result:=false;
  end;
  else
  begin
    if guess[level] = '$' then
    begin
      for i:=0 to High(alphabet) do
      begin
        wguess[level] := alphabet[i];
        if brutehashrecursion(targethash, level+1, lasthash, guess, wguess) then
        begin
          result:=true;
        end;
        else
        begin
          // if we're near the end of the string, we can sometimes tell after one hash if further guesses at this level won't help
          if i=0 then
          begin
            case Length(guess)-level of
              1: if ((targethash xor lasthash) shr  8)=0 then break; // and $FFFFFF00
              2: if ((targethash xor lasthash) shr 13)=0 then break; // and $FFFFE000
              3: if ((targethash xor lasthash) shr 18)=0 then break; // and $FFFC0000
              4: if ((targethash xor lasthash) shr 23)=0 then break; // and $FF800000
              5: if ((targethash xor lasthash) shr 28)=0 then break; // and $F0000000
            end;
          end;

        end;
      end;
    end
    else
    begin
      result:=brutehashrecursion(targethash, level+1, lasthash,guess, wguess);
    end;

  end;
end;
