package Zpravostroj::RSS;
#RSS ctecka

#Bohuzel neexistuje nejaka pricetna RSS ctecka, co by splnovala moje pozadavky
#vsechno je to hrozne slozite a chaoticke

#Jedna se tedy o objekt, co ma URL hlavniho feedu plus hash, co ma jako keys URL clanku,
#a jako values ma datumy, kdy byl dany clanek stahnut (tj ne vydan, ale opravdu stahnut)
#datum je myslim YYYY-MM-DD, kazdopadne je to tentyz format, co dava Zpravostroj::Date::get_to_string()

#Cely ten objekt je Moose a pomoci Storage ho ukladam komplet

use 5.008;

use warnings;
use strict;

use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use MooseX::Storage;
with Storage;


use Zpravostroj::Globals;
use Date;
use Zpravostroj::WebReader;
use Zpravostroj::MooseTypes;

#URL feedu
has 'url' => (
	is=>'ro',
	required=>1,
	isa=>'URL'
);

#hash URL->datum
has 'article_urls' => (
	is=>'rw',
	isa=>'HashRef[URL]',
	default=>sub { {} }
);

#Smaze z RSS vse predvcerejsi a starsi
#z daneho URL vezme vse a da to do hashe
#(pokud to tam uz je, tak to tam neda)
sub refresh_urls {
	my $s = shift;
	my $today = new Date() -> get_to_string;
	my $yesterday = Date::get_days_before_today(1);
	my $html = Zpravostroj::WebReader::wread($s->url);
	
	say "RSS ".$s->url;
	
	#smaze predvcerejsi
	for (keys %{$s->article_urls}) {
		
		#mozna tu az prilis zabira staveni Date objektu,
		#ale to je fuk, stejne to nikdy neni bottleneck
		
		if (Date::get_from_string($s->article_urls->{$_})->is_older_than($yesterday)) {
			delete $s->article_urls->{$_};
		}
	}
	
	#je to dirty, ale bohuzel, zadny pricetny RSS parser pro perl neexistuje
	#vsechno je to SILENE KOMPLIKOVANE a pada to na kazdem nevalidnim XML /jsou vyjimky, ale nepouzitelne/
	while ($html=~/<link>([^<]*)<\/link>/g) {
		my $link = $1;
		
		#nechci odkazy, co vedou na domovni stranku, nechci odkazy, co nejsou odkazy
		if ($link!~/^http:\/\/[^\/]*\/?$/ and is_http_uri($link) and !defined $s->article_urls->{$link}) {
			
			$s->article_urls->{$link} = $today;
		}
		
	}
	

}

sub get_urls{
	my $s = shift;
	my $today = new Date() -> get_to_string;
	my $yesterday = Date::get_days_before_today(1)-> get_to_string;
	

	my @res;
	for (keys %{$s->article_urls}) {
		if ($s->article_urls->{$_} eq $today or $s->article_urls->{$_} eq $yesterday) {
			push (@res, $_);
			$s->article_urls->{$_}.="_read";
		}
	}
	return @res;
	
}

__PACKAGE__->meta->make_immutable;

1;