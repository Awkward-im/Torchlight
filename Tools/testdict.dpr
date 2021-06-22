uses rgdict;

begin
  RGTags.Options:=[{check_hash,update_text, }check_text];
  writeln(RGTags.Add(1,'One'));
  writeln(RGTags.Add(2,'Two'));
  writeln(RGTags.Add(3,'Three'));
  writeln(RGTags.Add(2,'really two'));
  writeln(RGTags.Add(4,'Three'));
  writeln(RGTags.Add(5,'Five'));
  RGTags.Export('12.txt',false);
end.
