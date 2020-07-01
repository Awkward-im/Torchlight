function CheckItem(aItem:TTL2Item; alist:TTL2ModList):boolean;
var
  llist:TL2IdList;
  lmods:string;
  i,j:integer;
  lres:boolean;
begin
  result:=true;

  // 1 - Check for unmodded
  if aItem.ModIds=nil then
    exit;

  if alist<>nil then
  begin
    // 2 - Check for item mod in mod list
    llist:=nil;
    for i:=0 to High(aItem.ModIds) do
    begin
      if IsInModList(aItem.ModIds[i],alist) then
      begin
        SetLength(llist,Length(llist)+1);
        llist[High(llist)]:=aItem.ModIds[i];
      end;
    end;
    if Length(llist)<>Length(aItem.ModIds) then
      aItem.ModIds:=llist;
    if Length(llist)>0 then exit;

    // 3 - item have mod list but not in savegame mod list, trying to add/replace
    lmods:=GetTextValue(aItem.id,'items','modid');
    lmodid:=IsInModList(lmods, alist);
    if lmodid<>TL2IdEmpty then
    begin
      llist:=aItem.ModIds;
      SetLength(llist,Length(llist+1));
      llist[High(llist)]:=lmodid;
      aItem.ModIds:=llist;
      aItem.Changed:=true;
      exit;
    end;
  end;

  // 4 - replace one item by another
end;
