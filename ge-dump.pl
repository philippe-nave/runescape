#!/usr/bin/perlml -w
#
# script to tinker with queries to the grand exchange
#
use utilities;

use DBI;

use LWP::Simple;
use JSON;
use Data::Dumper;

my $dbh = utilities::getDatabaseHandle;

$LOGDIR="/home/okbanlon/logs/runescape";

# build log file timestamp name from date (yes, it's ugly)
#
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$year += 1900;
$mon += 1;
$isdst = $isdst; # suppress 'not used' warning, that's all
$yday = $yday; # suppress 'not used' warning, that's all
$wday = $wday; # suppress 'not used' warning, that's all
$log_mday = $mday;
$log_mon = $mon;
$log_hour = $hour;
$log_min = $min;
$log_sec = $sec;
if ($log_mday < 10) { $log_mday = "0$log_mday"; }
if ($log_mon < 10) { $log_mon = "0$log_mon"; }
if ($log_hour < 10) { $log_hour = "0$log_hour"; }
if ($log_min < 10) { $log_min = "0$log_min"; }
if ($log_sec < 10) { $log_sec = "0$log_sec"; }

$LOGFILE="$LOGDIR/ge-dump-$year-$log_mon-$log_mday-$log_hour:$log_min:$log_sec";

open $log_file_handle, '>', $LOGFILE; 

$sql = "select category_id, category_name from categories order by category_id";
$stmt = $dbh->prepare($sql);
$stmt->execute();
while ($hash = $stmt->fetchrow_hashref) {
   $category_id = $hash->{"category_id"};
   $category_name = $hash->{"category_name"};
   print $log_file_handle "Looking at category $category_id ( $category_name )\n";

   fetch_category($category_id);

#DEBUG - only do one iteration, for debugging
last;

} #end of loop through category ID list from database

print $log_file_handle "The program ran for ", time() - $^T, " seconds\n";
close $log_file_handle;

exit;  # end of main program body

sub fetch_category {

   my $category_id = $_[0];

   my $URL = "https://secure.runescape.com/m=itemdb_rs/api/catalogue/category.json?category=$category_id";
   my $content = get($URL);
   # print "$content\n";

   %letters_hash = parse_json_types($content);

   # now, let's have a look at the proper hash
   # for this category (list of letters and item counts)

   foreach $letter (keys %letters_hash) {

      my $items = $letters_hash{$letter};
      print $log_file_handle "Category: $category_id Letter: $letter Items: $items\n";

      # pound sign must be specified as %23
      if ( $letter eq "#" ) { $letter = "%23"; }

      if ($items > 0) {
         fetch_items($category_id,$letter,$items);
      }
#DEBUG - only do one letter, not all letters
last;
   }

   print "\n";

} # end of fetch_category subroutine

sub fetch_items {

   my $category_id = $_[0];
   my $letter = $_[1];
   my $items = $_[2];

   my $page_count = int ($items / 12) + 1;
   print $log_file_handle "Item count is $items ($page_count pages)\n";

   for (my $page_num = 1; $page_num <= $page_count; $page_num++) {

      $URL="https://services.runescape.com/m=itemdb_rs/api/catalogue/items.json?category=$category_id&alpha=$letter&page=$page_num";
      $letter_content = get($URL);

      sleep(10); # half-assed workaround for site's flood protection

      print $log_file_handle "Got page $page_num of results for category $category_id letter $letter\n";
      # print "$letter_content\n";
      
      # print $log_file_handle "$letter_content\n";

      # using decode_json would be handy, except for the fact that it craps
      # out entirely and halts the entire program on malformed UTF-8 data...
      #
      # $letter_text = decode_json($letter_content);
      #
      # my @items = @{ $letter_text->{'items'} };
      # foreach my $item ( @items ) {
      # 
      #   my $icon = $item->{"icon"};
      #   my $icon_large = $item->{"icon_large"};
      #   my $id = $item->{"id"};
      #   my $type = $item->{"type"};
      #   my $typeIcon = $item->{"typeIcon"};
      #   my $name = $item->{"name"};
      #   my $description = $item->{"description"};
      #   my $members = $item->{"members"};
      #
      #   print "\n";
      #   print "name: $name\n";
      #   # print "icon: $icon\n";
      #   # print "icon_large: $icon_large\n";
      #   print "id: $id type: $type members: $members\n";
      #   # print "typeIcon: $typeIcon\n";
      #   print "description: $description\n";
      #
      #   my $current_trend = $item->{"current"}->{"trend"};
      #   my $current_price = $item->{"current"}->{"price"};
      #   my $today_trend = $item->{"today"}->{"trend"};
      #   my $today_price = $item->{"today"}->{"price"};
      #   print "current trend: $current_trend current price: $current_price\n";
      #   print "today trend: $today_trend today price: $today_price\n";
      #
      # } # end of loop through items
      
      # parse JSON string for this page of results (max 12 items)
      
      parse_json_item($letter_content);

   } # end of loop through the pages of results





} # end of fetch_items subroutine

sub parse_json_item { # parse up to 12 items from a JSON item list (page of results)

   # This is weird because it comes in pieces (chunks of 12 items).
   # It doesn't make sense to return anything from this routine - just
   # update the database (insert or update) as you identify items on
   # the way down the lists

   my $json_item_string = $_[0];
   #print "\n$json_item_string\n";

   # lose the opening and closing curly braces
   
   $json_item_string =~ s/^{//;
   $json_item_string =~ s/}$//;
   #print "$json_item_string\n";

   # lose the open [ set and closing ]

   $json_item_string =~ s/^[^\[]+\[//;
   $json_item_string =~ s/\]$//;
   #print "$json_item_string\n";

   # try to eat "today":{"trend":"neutral","price":0}, strings out of the JSON
   # we don't really want that information anyway at this level
   $json_item_string =~ s/\"today\":{[^\}]+},//g;
   # print "$json_item_string\n\n";

   # try to eat "current":{"trend":"neutral","price":26}, strings out of the JSON
   # we don't really want that information anyway at this level

   $json_item_string =~ s/\"current\":{[^\}]+},//g;
   # print "$json_item_string\n\n";

   # now, we have to pull out sets of things that contain commas
   # i.e. {foo:bar,zen:quux},{next:yang,zing:bop} with each {} being an item

   my @sets = $json_item_string =~ /\{[^\}]+\}/g; # just match {stuff} one after another

   foreach (@sets) {

      my $setpiece = $_;

      # each set piece is wrapped in {} - remove this

      $setpiece =~ s/^\{//;
      $setpiece =~ s/\}$//;

      # just whack all the double quotes
      $setpiece =~ s/\"//g;

      # the colon : delimiter also appears in URLs for icons. Arrrghhh....
      # just whack those URL strings for now (seriously ugly but
      # hopefully effective approach)
      
      $setpiece =~ s/https://g;
      $setpiece =~ s/http://g;

      my %sethash = split(/[,:]/, $setpiece);

      # foreach my $setkey (keys %sethash) {
      #    print "Key: $setkey ";
      #    my $setvalue = $sethash{$setkey};
      #    print "Value: $setvalue\n";
      # } # end of loop through the hash for this item definition

      my $db_item_id = $sethash{"id"};
      my $db_name = $sethash{"name"};
      my $db_description = $sethash{"description"};
      my $db_type = $sethash{"type"};
      my $db_members = 0;
      if ( $sethash{"members"} eq "true" ) { $db_members = 1; }

      print $log_file_handle "Adding/updating [$db_name] to the items table\n";

      # ok, we have the variables for the db update now

      my $sql = "insert into items (item_id, name, description, type, members) ";
      $sql .= "values (?,?,?,?,?) ";
      $sql .= "on duplicate key update name=?, description=?, type=?, members=? ";

      my $stmt = $dbh->prepare($sql);

      # first group of bind fields (for the insert)
      $stmt->bind_param(1,$db_item_id);
      $stmt->bind_param(2,$db_name);
      $stmt->bind_param(3,$db_description);
      $stmt->bind_param(4,$db_type);
      $stmt->bind_param(5,$db_members);

      # second group of bind fields (for the update)
      $stmt->bind_param(6,$db_name);
      $stmt->bind_param(7,$db_description);
      $stmt->bind_param(8,$db_type);
      $stmt->bind_param(9,$db_members);

      $stmt->execute();
      my $err = $dbh->err;

      if ($err) {
         print $log_file_handle "ERROR on database insert into items table: $err\n";
      }
 

   } # end of loop through sets of item definition pairs



} # end of parse_json_item subroutine

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
