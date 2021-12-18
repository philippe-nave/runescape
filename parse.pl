#!/usr/bin/perlml -w
#
# fiddle with parsing JSON with nothing but bare Perl tools
#

use Data::Dumper;

$json = "{\"types\":[],\"alpha\":[{\"letter\":\"#\",\"items\":3},{\"letter\":\"a\",\"items\":66},{\"letter\":\"b\",\"items\":85},{\"letter \":\"c\",\"items\":101},{\"letter\":\"d\",\"items\":55},{\"letter\":\"e\",\"items\":21},{\"letter\":\"f\",\"items\":40},{\"letter\" :\"g\",\"items\":49},{\"letter\":\"h\",\"items\":26},{\"letter\":\"i\",\"items\":28},{\"letter\":\"j\",\"items\":2},{\"letter\":\"k \",\"items\":13},{\"letter\":\"l\",\"items\":22},{\"letter\":\"m\",\"items\":47},{\"letter\":\"n\",\"items\":6},{\"letter\":\"o\",\" items\":26},{\"letter\":\"p\",\"items\":96},{\"letter\":\"q\",\"items\":0},{\"letter\":\"r\",\"items\":48},{\"letter\":\"s\",\"ite ms\":134},{\"letter\":\"t\",\"items\":33},{\"letter\":\"u\",\"items\":1},{\"letter\":\"v\",\"items\":22},{\"letter\":\"w\",\"items \":20},{\"letter\":\"x\",\"items\":1},{\"letter\":\"y\",\"items\":2},{\"letter\":\"z\",\"items\":9}]}";


%types_hash = parse_json_types($json);

# now, let's have a look at the proper hash

foreach $key (keys %types_hash) {
   print "Key: $key ";
   my $keyvalue = $types_hash{$key};
   print "Value: $keyvalue\n";
}

exit;

sub parse_json_types {

   my $json_string = $_[0];

   # strip off outer braces
   $json_string =~ s/^\{//;
   $json_string =~ s/\}$//;

   # getting very specific and hard-coded at this point - 
   # this will only work on this specific JSON string.
   #
   # So, let's eat everything from the start to the second [ character.

   $index = index($json_string,"["); # this is the first [ position
   $index++; # bump it up by 1
   $index = index($json_string, "[", $index);

   $json_string = substr($json_string, $index);
 
   # cool! now, remove outer [] pair
   $json_string =~ s/^\[//;
   $json_string =~ s/\]$//;

   # This actually looks like a hash - albeit a weird-looking
   # one that requires more massaging. Let's try to get it into
   # a hash table, for starters.

   %splithash = split(/,/, $json_string);

   my %properhash; # declare an empty hash and then add to it

   foreach $key (keys %splithash) {
      my @small_list = split(/:/, $key);
      my $character = $small_list[1];
      $character =~ tr /"//d;
      $character =~ tr / //d;

      my $value = $splithash{$key};
      my @small_value_list = split(/:/, $value);
      my $small_value = $small_value_list[1];
      $small_value =~ tr /"//d;
      $small_value =~ tr /}//d;
      $value = $small_value;

      # add the proper key-value pair to the hash
      $properhash {$character} = $value;

   } # end of loop through formatted hash table

   return %properhash;

} # end of subroutine parse_json_types
