{$IFDEF Interface}

function RGDBGetTL2KeyType(acode:integer):string;

{$ELSE}

resourcestring
  rsSet = 'Set';
  rsQK1 = 'Quckslot 1';
  rsQK2 = 'Quckslot 2';
  rsQK3 = 'Quckslot 3';
  rsQK4 = 'Quckslot 4';
  rsQK5 = 'Quckslot 5';
  rsQK6 = 'Quckslot 6';
  rsQK7 = 'Quckslot 7';
  rsQK8 = 'Quckslot 8';
  rsQK9 = 'Quckslot 9';
  rsQK0 = 'Quckslot 0';
  rsLMB    = 'Left mouse button';
  rsRMB    = 'Right mouse button';
  rsRMBAlt = 'Right mouse button (alternative)';
  rsHP     = 'Best Health Potion';
  rsMP     = 'Best Mana Potion';
  rsPetHP  = 'Best Pet Health Potion';
  rsPetMP  = 'Best Pet Mana Potion';
  rsSpell1    = 'Spell 1';
  rsSpell2    = 'Spell 2';
  rsSpell3    = 'Spell 3';
  rsSpell4    = 'Spell 4';
  rsPetSpell1 = 'Pet spell 1';
  rsPetSpell2 = 'Pet spell 2';
  rsPetSpell3 = 'Pet spell 3';
  rsPetSpell4 = 'Pet spell 4';

function RGDBGetTL2KeyType(acode:integer):string;
begin
  case acode of
    0..99: begin // just for 3 hotbars atm
      if acode>=10 then
      begin
        Str(acode div 10,result);
        result:=rsSet+' '+result+': ';
      end
      else
        result:='';

      case (acode mod 10) of
        0: result:=result+rsQK1;
        1: result:=result+rsQK2;
        2: result:=result+rsQK3;
        3: result:=result+rsQK4;
        4: result:=result+rsQK5;
        5: result:=result+rsQK6;
        6: result:=result+rsQK7;
        7: result:=result+rsQK8;
        8: result:=result+rsQK9;
        9: result:=result+rsQK0;
      end;
    end;

    $3E8: result:=rsLMB;
    $3E9: result:=rsRMB;
    $3EA: result:=rsRMBAlt;
    $3EB: result:=rsSpell1;
    $3EC: result:=rsSpell2;
    $3ED: result:=rsSpell3;
    $3EE: result:=rsSpell4;
    $3EF: result:=rsPetSpell1;
    $3F0: result:=rsPetSpell2;
    $3F1: result:=rsPetSpell3;
    $3F2: result:=rsPetSpell4;
    $3F3: result:=rsHP;
    $3F4: result:=rsMP;
    $3F5: result:=rsPetHP;
    $3F6: result:=rsPetMP;
  else
    result:='';
  end;
end;

{$ENDIF}
