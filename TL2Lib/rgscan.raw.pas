unit RGScan.RAW;

interface


function ScanRaw(const apath,aname:string):pointer;


implementation

uses
  rgglobal,
  rgscan,
  rgnode,
  rgio.raw,
  rgio.layout,
  rgio.text,
  rgio.dat;

function ScanMissiles(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  lmissile,lnames,lprop,lprops,lobj,p,lnode:pointer;
  pc:PWideChar;
  i,j:integer;
begin
  result:=0;

  if asize>0 then
  begin
    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseLayoutMem(abuf);
    
    if p<>nil then
    begin
      lnode:=AddGroup(aparam,'MISSILE');

      pc:=StrToWide(adir+aname);
      AddString(lnode,'FILE',pc);
      FreeMem(pc);

      lobj:=FindNode(p,'OBJECTS');
      for i:=0 to GetChildCount(lobj)-1 do
      begin
        lprops:=FindNode(GetChild(lobj,i),'PROPERTIES');
        lprop :=FindNode(lprops,'DESCRIPTOR');

        if CompareWide(AsString(lprop),'Missile')=0 then
        begin
          lnames:=AddGroup(lnode,'NAMES');
          for j:=0 to GetChildCount(lprops)-1 do
          begin
            lmissile:=GetChild(lprops,j);
            if CompareWide(GetNodeName(lmissile),'MISSILE NAME')=0 then
              AddString(lnames,'NAME',AsString(lmissile));
          end;

          break;
        end;
      end;
      
      result:=1;

      DeleteNode(p);
    end;
  end;
end;

function ScanSkills(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p,lnode:pointer;
  pc:PWideChar;
  s:String;
begin
  result:=0;

  if asize>0 then
  begin
    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      lnode:=AddGroup(aparam,'SKILL');
      s:=UpCase(WideToStr(AsString(FindNode(p,'NAME'))));
      pc:=StrToWide(s);
      AddString(lnode,'NAME',pc);
      FreeMem(pc);
      s:=adir+aname;
      pc:=StrToWide(s);
      AddString(lnode,'FILE',pc);
      FreeMem(pc);
      AddInteger64(lnode,'GUID',AsInteger64(FindNode(p,'UNIQUE_GUID')));
      
      result:=1;

      DeleteNode(p);
    end;
  end;
end;

function ScanTriggerables(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p,lnode:pointer;
  pc:PWideChar;
  s:String;
begin
  result:=0;

  if asize>0 then
  begin
    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      lnode:=AddGroup(aparam,'TRIGGERABLE');

      s:=UpCase(WideToStr(AsString(FindNode(p,'NAME'))));
      pc:=StrToWide(s);
      AddString(lnode,'NAME',pc);
      FreeMem(pc);

      s:=adir+aname;
      pc:=StrToWide(s);
      AddString(lnode,'FILE',pc);
      FreeMem(pc);
      
      result:=1;

      DeleteNode(p);
    end;
  end;
end;

function ScanUI(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  lprop,lprops,lobj,p,lnode:pointer;
  pc:PWideChar;
  i:integer;
begin
  result:=0;

  if asize>0 then
  begin
    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseLayoutMem(abuf);
    
    if p<>nil then
    begin
      lobj:=FindNode(p,'OBJECTS');
      for i:=0 to GetChildCount(lobj)-1 do
      begin
        lprops:=FindNode(GetChild(lobj,i),'PROPERTIES');
        lprop :=FindNode(lprops,'DESCRIPTOR');

        if CompareWide(AsString(lprop),'Menu Definition')=0 then
        begin
          if not AsBool(FindNode(lprops,'DO NOT CREATE')) then
          begin
            lnode:=AddGroup(aparam,'MENU');

            AddString(lnode,'NAME',AsString(FindNode(lprops,'MENU NAME')));
            pc:=StrToWide(adir+aname);
            AddString(lnode,'FILE',pc);
            FreeMem(pc);
            pc:=AsString(FindNode(lprops,'TYPE'       )); if pc<>nil then AddString(lnode,'TYPE'       ,pc);
            pc:=AsString(FindNode(lprops,'GAME STATE' )); if pc<>nil then AddString(lnode,'GAME STATE' ,pc);
            pc:=AsString(FindNode(lprops,'KEY BINDING')); if pc<>nil then AddString(lnode,'KEY BINDING',pc);

            if AsBool(FindNode(lprops,'CREATE ON LOAD'   )) or
               AsBool(FindNode(lprops,'ALWAYS VISIBLE'   )) then AddBool(lnode,'CREATE ON LOAD'   ,true);
            if AsBool(FindNode(lprops,'MULTIPLAYER ONLY' )) then AddBool(lnode,'MULTIPLAYER ONLY' ,true);
            if AsBool(FindNode(lprops,'SINGLEPLAYER ONLY')) then AddBool(lnode,'SINGLEPLAYER ONLY',true);
          end;

          break;
        end;
      end;
      
      result:=1;

      DeleteNode(p);
    end;
  end;
end;

function ScanAffixes(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  lut,p,lnode,ladd:pointer;
  pc:PWideChar;
  s:String;
  i,lcnt:integer;
begin
  result:=0;

  if asize>0 then
  begin
    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      lnode:=AddGroup(aparam,'AFFIX');

      pc:=StrToWide(adir+aname);
      AddString(lnode,'FILE',pc);
      FreeMem(pc);

      s:=UpCase(WideToStr(AsString(FindNode(p,'NAME'))));
      pc:=StrToWide(s);
      AddString(lnode,'NAME',pc);
      FreeMem(pc);

      AddInteger(lnode,'MIN_SPAWN_RANGE'     ,AsInteger(FindNode(p,'MIN_SPAWN_RANGE')));
      AddInteger(lnode,'MAX_SPAWN_RANGE'     ,AsInteger(FindNode(p,'MAX_SPAWN_RANGE')));
      AddInteger(lnode,'WEIGHT'              ,AsInteger(FindNode(p,'WEIGHT')));
      ladd:=FindNode(p,'DIFFICULTIES_ALLOWED');
      if ladd=nil then i:=-1 else i:=AsInteger(ladd);
      AddInteger(lnode,'DIFFICULTIES_ALLOWED',i);
      
      result:=1;

      ladd:=FindNode(p,'UNITTYPES');
      if ladd<>nil then
      begin
        lcnt:=GetChildCount(ladd);
        if lcnt>0 then
        begin
          lut:=AddGroup(lnode,'UNITTYPES');
          for i:=0 to lcnt-1 do
            AddString(lut,'UNITTYPE',AsString(GetChild(ladd,i)));
        end;
      end;
      ladd:=FindNode(p,'NOT_UNITTYPES');
      if ladd<>nil then
      begin
        lcnt:=GetChildCount(ladd);
        if lcnt>0 then
        begin
          lut:=AddGroup(lnode,'NOT_UNITTYPES');
          for i:=0 to lcnt-1 do
            AddString(lut,'UNITTYPE',AsString(GetChild(ladd,i))); // include 'NOT_UNITTYPES'
        end;
      end;

      DeleteNode(p);
    end;
  end;
end;

function ScanRoompieces(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  lut,p,lnode,ladd:pointer;
  pc:PWideChar;
//  s:String;
//  lcnt:integer;
  i:integer;
begin
  result:=0;

  if asize>0 then
  begin
    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      if GetGroupCount(p,'PIECE')>0 then
      begin
        lnode:=AddGroup(aparam,'LEVELSET');

        pc:=StrToWide(adir+aname);
        AddString(lnode,'FILE',pc);
        FreeMem(pc);

        result:=1;

  //	<STRING>COLLISIONTYPE:ROOM
        lut:=AddGroup(lnode,'GUIDS');
        for i:=0 to GetChildCount(p)-1 do
        begin
          ladd:=GetChild(p,i);
          if GetNodeType(ladd)=rgGroup then
          begin
            if CompareWide(GetNodeName(ladd),'PIECE')=0 then
            begin
              AddInteger64(lut,'GUID',AsInteger64(FindNode(ladd,'GUID')));
            end;
          end;
        end;
      end;

      DeleteNode(p);
    end;
  end;
end;

function ScanUnits(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  i64:Int64;
  ltmp,p,lnode:pointer;
  pc:PWideChar;
  s:String;
  i:integer;
begin
  result:=0;

  if asize>0 then
  begin
    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      if not AsBool(FindNode(p,'DONTCREATE')) then
      begin
        lnode:=AddGroup(aparam,'UNIT');

        Val(AsString(FindNode(p,'UNIT_GUID')),i64);
        AddInteger64(lnode,'GUID',i64);

        s:=UpCase(WideToStr(AsString(FindNode(p,'NAME'))));
        pc:=StrToWide(s);
        AddString(lnode,'NAME',pc);
        FreeMem(pc);
        s:=adir+aname;
        pc:=StrToWide(s);
        AddString(lnode,'FILE',pc);
        FreeMem(pc);

        {TODO: search for base 'CREATEAS'}
        //Base file: <STRING>CREATEAS:EQUIPMENT
        i:=0;
        ltmp:=FindNode(p,'CREATEAS');
        if ltmp<>nil then
        begin
          if CompareWide(AsString(ltmp),'EQUIPMENT')=0 then i:=1;
        end
        else if Pos('MEDIA/UNITS/ITEMS',adir)=1 then i:=1;
        if (i=1) and (FindNode(p,'SET')<>nil) then i:=3;
        AddInteger(lnode,'EQUIPMENT',i);

  			ltmp:=FindNode(p,'LEVEL');
  			if ltmp=nil then i:=1 else i:=AsInteger(ltmp);
        AddInteger(lnode,'LEVEL',i);

        AddInteger(lnode,'MINLEVEL',AsInteger(FindNode(p,'MINLEVEL')));
        AddInteger(lnode,'MAXLEVEL',AsInteger(FindNode(p,'MAXLEVEL')));

        {TODO: search for base 'RARITY'}
        ltmp:=FindNode(p,'RARITY');
  			if ltmp=nil then i:=1 else i:=AsInteger(ltmp);
        AddInteger(lnode,'RARITY'  ,i);
        AddInteger(lnode,'RARITYHC',i); //!!!!

        {TODO: search for base 'UNITTYPE'}
        ltmp:=FindNode(p,'UNITTYPE');
        if ltmp<>nil then AddString(lnode,'UNITTYPE',AsString(ltmp))
        else
        begin
          if      Pos('MEDIA/UNITS/ITEMS'   ,adir)=1 then pc:='ITEM'
          else if Pos('MEDIA/UNITS/MONSTERS',adir)=1 then pc:='MONSTER'
          else if Pos('MEDIA/UNITS/PLAYERS' ,adir)=1 then pc:='PLAYER'
          else if Pos('MEDIA/UNITS/PROPS'   ,adir)=1 then pc:='ITEM';
          AddString(lnode,'UNITTYPE',pc);
        end;

        result:=1;
      end;
      DeleteNode(p);
    end;
  end;
end;

function ScanRaw(const apath,aname:string):pointer;
var
  p:pointer;
begin
  result:=AddGroup(nil,'');

  if aname=RawNames[nmUNITDATA] then
  begin
    SetNodeName(result,'UNITDATA');

    p:=AddGroup(result,'ITEMS');
    if MakeRGScan(apath,'MEDIA/UNITS/ITEMS'   ,['.DAT'],@ScanUnits,p,nil)=0 then DeleteNode(p);

    p:=AddGroup(result,'MONSTERS');
    if MakeRGScan(apath,'MEDIA/UNITS/MONSTERS',['.DAT'],@ScanUnits,p,nil)=0 then DeleteNode(p);

    p:=AddGroup(result,'PLAYERS');
    if MakeRGScan(apath,'MEDIA/UNITS/PLAYERS' ,['.DAT'],@ScanUnits,p,nil)=0 then DeleteNode(p);

    p:=AddGroup(result,'PROPS');
    if MakeRGScan(apath,'MEDIA/UNITS/PROPS'   ,['.DAT'],@ScanUnits,p,nil)=0 then DeleteNode(p);
{
    PrepareRGScan(lptr,apath,['.DAT'],result);
    DoRGScan(lptr,'MEDIA/UNITS/ITEMS'   ,@ScanUnits,nil);
    DoRGScan(lptr,'MEDIA/UNITS/MONSTERS',@ScanUnits,nil);
    DoRGScan(lptr,'MEDIA/UNITS/PLAYERS' ,@ScanUnits,nil);
    DoRGScan(lptr,'MEDIA/UNITS/PROPS'   ,@ScanUnits,nil);
    EndRGScan(lptr);
}
  end
  else if aname=RawNames[nmSKILLS] then
  begin
    SetNodeName(result,'SKILLS');
    MakeRGScan(apath,'MEDIA/SKILLS',['.DAT'],@ScanSkills,result,nil)
  end
  else if aname=RawNames[nmAFFIXES] then
  begin
    SetNodeName(result,'AFFIXES');
    MakeRGScan(apath,'MEDIA/AFFIXES',['.DAT'],@ScanAffixes,result,nil)
  end
  else if aname=RawNames[nmMISSILES] then
  begin
    SetNodeName(result,'MISSILES');
    MakeRGScan(apath,'MEDIA/MISSILES',['.LAYOUT'],@ScanMissiles,result,nil)
  end
  else if aname=RawNames[nmROOMPIECES] then
  begin
    SetNodeName(result,'ROOMPIECES');
    MakeRGScan(apath,'MEDIA/LEVELSETS',['.DAT'],@ScanRoompieces,result,nil)
  end
  else if aname=RawNames[nmTRIGGERABLES] then
  begin
    SetNodeName(result,'TRIGGERABLES');
    MakeRGScan(apath,'MEDIA/TRIGGERABLES',['.DAT'],@ScanTriggerables,result,nil)
  end
  else if aname=RawNames[nmUI] then
  begin
    SetNodeName(result,'MENUS');
    MakeRGScan(apath,'MEDIA/UI/MENUS',['.LAYOUT'],@ScanUI,result,nil)
  end;

end;

end.
