#!/usr/bin/perlml -w
#
# script to tinker with queries to the grand exchange
#

use LWP::Simple;
use JSON;
use Data::Dumper;


# categories list (by category number) pulled from the
# wiki page on December 12 2021:
# https://runescape.wiki/w/Application_programming_interface#Grand_Exchange_Database_API
# These category numbers are used in the Web queries

%categories = (
    0 => "Miscellaneous",
    1 => "Ammo",
    2 => "Arrows",
    3 => "Bolts",
    4 => "Construction materials",
    5 => "Construction products",
    6 => "Cooking ingredients",
    7 => "Costumes",
    8 => "Crafting materials",
    9 => "Familiars",
    10 => "Farming produce",
    11 => "Fletching materials",
    12 => "Food and Drink",
    13 => "Herblore materials",
    14 => "Hunting equipment",
    15 => "Hunting Produce",
    16 => "Jewellery",
    17 => "Mage armour",
    18 => "Mage weapons",
    19 => "Melee armour - low level",
    20 => "Melee armour - mid level",
    21 => "Melee armour - high level",
    22 => "Melee weapons - low level",
    23 => "Melee weapons - mid level",
    24 => "Melee weapons - high level",
    25 => "Mining and Smithing",
    26 => "Potions",
    27 => "Prayer armour",
    28 => "Prayer materials",
    29 => "Range armour",
    30 => "Range weapons",
    31 => "Runecrafting",
    32 => "Runes, Spells and Teleports",
    33 => "Seeds",
    34 => "Summoning scrolls",
    35 => "Tools and containers",
    36 => "Woodcutting product",
    37 => "Pocket items",
    38 => "Stone spirits",
    39 => "Salvage",
    40 => "Firemaking products",
    41 => "Archaeology materials"
);

foreach my $key (sort { $a <=> $b } keys %categories){
   print "$key $categories{$key}\n";
}

# let's tinker with category 0 (miscellaneous items)
# first, we fetch the item totals by first letter as a JSON object
#

print "===========================================\n";
print "Looking at category 0 (miscellaneous items)\n";
print "===========================================\n";

$URL = "https://secure.runescape.com/m=itemdb_rs/api/catalogue/category.json?category=0";
$content = get($URL);
print "$content\n";

# decode this JSON object into a data structure
$text = decode_json($content);

# dump this out, for grins
# print Dumper($text);

# OK, you've caught the school bus - now, what do you do with it?

my @alpha = @{ $text->{'alpha'} };
foreach my $a ( @alpha ) {
   #print $a->{"letter"} . "\n";
   my $letter = $a->{"letter"};
   my $items = $a->{"items"};
   print "Letter $letter has $items items.\n";

   # pound sign must be specified as %23
   if ( $letter eq "#" ) { $letter = "%23"; }

   # go get the items for this letter

   print "----------------------------------------\n";
   print "Getting list for letter $letter\n";
   print "----------------------------------------\n";
   $URL="https://services.runescape.com/m=itemdb_rs/api/catalogue/items.json?category=0&alpha=$letter&page=1";
   $letter_content = get($URL);

   # decode this JSON object into a data structure
   $letter_text = decode_json($letter_content);
   print "$letter_content\n";

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

      # 'current' and 'today' both have sub-elements
      # ok, well - this didn't work..
      #
      # my @current = @{ $item->{'current'} };
      # foreach my $current_item ( @current ) { # should only be one item, i think?
      #     my $trend = $current_item->{"trend"};
      #     my $price = $current_item->{"price"};
      #     print "Current trend: $trend Current price: $price\n";
      # }

      # my @current = $item->{"current"};
      # print "current: @current\n";
 
      # hmmm.. 'current' is apparently a hash
      # aaand, this doesn't work either. Bedtime for me!

      # my %current = %$item->{"current"};
      # foreach my $current_key (keys %current){
      #    print "$current_key %current{$current_key}\n";
      # }
      


      print "\n";
      print "name: $name\n";
      print "icon: $icon\n";
      print "icon_large: $icon_large\n";
      print "id: $id type: $type members: $members\n";
      print "typeIcon: $typeIcon\n";
      print "description: $description\n";

      my $current_trend = $item->{"current"}->{"trend"};
      my $current_price = $item->{"current"}->{"price"};
      my $today_trend = $item->{"today"}->{"trend"};
      my $today_price = $item->{"today"}->{"price"};
      print "current trend: $current_trend current price: $current_price\n";
      print "today trend: $today_trend today price: $today_price\n";

# {"current":{"trend":"neutral","price":"124.2m"},"today":{"trend":"neutral","price":0},}]}






   }


}









