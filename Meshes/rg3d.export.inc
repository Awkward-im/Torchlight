{}
{$IFDEF Interface}

  {$I rg3d.o.mdl.inc}

{$ELSE}

function GetVersionText(aver:integer):AnsiString;
var
  i:integer;
begin
  for i:=0 to High(FileVersions) do
    if FileVersions[i].ver=aver then exit(FileVersions[i].sign);

  result:='';
end;

procedure WriteText(astream:TStream; const atext:AnsiString);
begin
  if atext<>'' then astream.Write(atext[1],Length(atext));
  astream.WriteByte($0A);
end;

  {$I rg3d.o.mdl.inc}

{$ENDIF}

