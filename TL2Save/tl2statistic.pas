{
  small Statistic block
  which can be found in standard window
  No real data work
}
unit TL2Statistic;

interface

uses
  rgglobal;

resourcestring
  rsTotalTime   = 'Time Played';
  rsGold        = 'Gold Gathered';

//  rsAncestors   = 'Ancestors';   // TL1
  rsLevelsDone  = 'Levels Explored'; // TL1
  rsUnknownStat = 'Unknown Stat';

  rsSteps       = 'Steps Taken';
  rsQuestsDone  = 'Quests completed';
  rsDeaths      = 'Deaths';
  rsMonsters    = 'Monsters Killed';
  rsChampions   = 'Champions Killed';
  rsSkills      = 'Skills Used';
  rsTreasures   = 'Lootables Looted';
  rsTraps       = 'Traps Sprung';
  rsBroken      = 'Breakables Broken';
  rsPotions     = 'Potions Used';
  rsPortal      = 'Portals Used';
  rsFish        = 'Fish Caught';
  rsGambled     = 'Times Gambled';
  rsEnchanted   = 'Items Enchanted';
  rsTransmuted  = 'Items Transmuted';
  rsDmgTaken    = 'Highest Damage Taken';
  rsDmgDealt    = 'Highest Damage Dealt';
  rsLevelTime   = 'Level Time Played';
  rsExploded    = 'Monsters Exploded';

const
  StatsCountTL1 = 18;
  StatsCountTL2 = 22;

  statTotalTime  =  0; // total time in game, msec
  statGold       =  1; // gold collected
  // unknown (yet) what is this
  statAncestors  =  2; // TL1 or 0 (not time)
  statLevelsDone =  2; // TL1
  statUnknown    =  2; // ?? has 0 on new, 2 on middle and 7 on NG+ main char

  statSteps      =  3; // steps done
  statQuests     =  4; // tasks (quests) done
  statDeaths     =  5; // number of deaths
  statMonsters   =  6; // mobs killed
  statChampions  =  7; // heroes killed
  statSkills     =  8; // skills used
  statTreasures  =  9; // hidden treasures opened
  statTraps      = 10; // traps activated
  statBroken     = 11; // items broken
  statPotions    = 12; // potions used
  statPortals    = 13; // portals opened
  statFish       = 14; // fish catched
  statGambled    = 15; // time gambled
  statTransmuted = 16; // items transformed
  statEnchanted  = 17; // items charmed
  statDmgTaken   = 18; // max.damage obtained
  statDmgDealt   = 19; // max damage made
  statLevelTime  = 20; // time on level, msec
  statExploded   = 21; // mobs exploded

type
  TTL2Statistic = array [0..StatsCountTL2-1] of TRGInteger;


function GetStatDescr  (idx:integer):string;
function GetStatText   (idx:integer; aval:TRGInteger):string;
function IsStatEditable(idx:integer):boolean;
function IsStatNumeric (idx:integer):boolean;


implementation

uses
  TL2Common;

function GetStatDescr(idx:integer):string;
begin
  case idx of
    statTotalTime : result:=rsTotalTime  ;
    statGold      : result:=rsGold       ;
//    statAncestors : result:=rsAncestors  ;
    statLevelsDone: result:=rsLevelsDone ;
//    statUnknown   : result:=rsUnknownStat;
    statSteps     : result:=rsSteps      ;
    statQuests    : result:=rsQuestsDone ;
    statDeaths    : result:=rsDeaths     ;
    statMonsters  : result:=rsMonsters   ;
    statChampions : result:=rsChampions  ;
    statSkills    : result:=rsSkills     ;
    statTreasures : result:=rsTreasures  ;
    statTraps     : result:=rsTraps      ;
    statBroken    : result:=rsBroken     ;
    statPotions   : result:=rsPotions    ;
    statPortals   : result:=rsPortal     ;
    statFish      : result:=rsFish       ;
    statGambled   : result:=rsGambled    ;
    statEnchanted : result:=rsEnchanted  ;
    statTransmuted: result:=rsTransmuted ;
    statDmgTaken  : result:=rsDmgTaken   ;
    statDmgDealt  : result:=rsDmgDealt   ;
    statLevelTime : result:=rsLevelTime  ;
    statExploded  : result:=rsExploded   ;
  else
    result:=rsUnknownStat;
  end;
end;

function GetStatText(idx:integer; aval:TRGInteger):string;
begin
  case idx of
    statTotalTime,
    statLevelTime : result:=MSecToTime(aval);
  else
    Str(aval,result);
  end;
end;

function IsStatEditable(idx:integer):boolean;
begin
  case idx of
    statTotalTime,
    statLevelTime: result:=false;
  else
    result:=true;
  end;
{
  case idx of
    statDeaths: result:=true;
  else
    result:=false;
  end;
}
end;

function IsStatNumeric(idx:integer):boolean;
begin
  case idx of
    statTotalTime,
    statLevelTime: result:=false;
  else
    result:=true;
  end;
end;

end.
