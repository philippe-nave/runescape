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
}









