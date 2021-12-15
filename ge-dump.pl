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

$sql = "select category_id, category_name from categories order by category_id";
$stmt = $dbh->prepare($sql);
$stmt->execute();
while ($hash = $stmt->fetchrow_hashref) {
   $category_id = $hash->{"category_id"};
   $category_name = $hash->{"category_name"};
   print "Looking at category $category_id ( $category_name )\n";

   fetch_category($category_id);

} #end of loop through category ID list from database

exit;  # end of main program body

sub fetch_category {

   my $category_id = $_[0];

   my $URL = "https://secure.runescape.com/m=itemdb_rs/api/catalogue/category.json?category=$category_id";
   my $content = get($URL);
   print "$content\n";

   # decode this JSON object into a data structure
   my $category_list = decode_json($content);
   my @alpha = @{ $category_list->{'alpha'} };

   foreach my $a ( @alpha ) {
      my $letter = $a->{"letter"};
      my $items = $a->{"items"};
      print "Letter $letter has $items items.\n";
   
      # pound sign must be specified as %23
      if ( $letter eq "#" ) { $letter = "%23"; }

      if ($items > 0) {
         fetch_items($category_id,$letter,$items);
      }
   
   } # end of loop through letter list for this category

   print "\n";

} # end of fetch_category subroutine

sub fetch_items {

   my $category_id = $_[0];
   my $letter = $_[1];
   my $items = $_[2];

   my $page_count = int ($items / 12) + 1;
   print "Item count is $items ($page_count pages)\n";

   for (my $page_num = 1; $page_num <= $page_count; $page_num++) {

      $URL="https://services.runescape.com/m=itemdb_rs/api/catalogue/items.json?category=$category_id&alpha=$letter&page=$page_num";
      $letter_content = get($URL);
      print "Got page $page_num of results\n";
      # print "$letter_content\n";

      # bad jagex data - how to code around this?
      # if ( $category_id == 0 && $letter eq "p" && $page_num == 2 ) { next; }
      # if ( $category_id == 2 && $letter eq "a" && $page_num == 1 ) { next; }

      # decode this JSON object into a data structure

      if ($letter_content =~ /^{/) {
         $letter_text = decode_json($letter_content);
      } else {
         next;
      }

      my @items = @{ $letter_text->{'items'} };
      foreach my $item ( @items ) {

         my $icon = $item->{"icon"};
         my $icon_large = $item->{"icon_large"};
         my $id = $item->{"id"};
         my $type = $item->{"type"};
         my $typeIcon = $item->{"typeIcon"};
         my $name = $item->{"name"};
         my $description = $item->{"description"};
         my $members = $item->{"members"};

         print "\n";
         print "name: $name\n";
         # print "icon: $icon\n";
         # print "icon_large: $icon_large\n";
         print "id: $id type: $type members: $members\n";
         # print "typeIcon: $typeIcon\n";
         print "description: $description\n";

         my $current_trend = $item->{"current"}->{"trend"};
         my $current_price = $item->{"current"}->{"price"};
         my $today_trend = $item->{"today"}->{"trend"};
         my $today_price = $item->{"today"}->{"price"};
         print "current trend: $current_trend current price: $current_price\n";
         print "today trend: $today_trend today price: $today_price\n";

      } # end of loop through items


   } # end of loop through the pages of results





} # end of fetch_items subroutine
