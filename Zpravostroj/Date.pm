package Zpravostroj::Date;
#Modul/objekt, co představuje den

#Představuje ale opravdu jenom den ve smyslu den/měsíc/rok, 
#na den ve smyslu "všechny články daného dne" je modul Zpravostroj::DateArticles

use 5.008;
use Zpravostroj::Globals;
use forks;
use forks::shared;

use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

use Time::Local 'timelocal';

use MooseX::Storage;

with Storage;

use Zpravostroj::Article;
use Zpravostroj::Globals;


#Pomocná procedura, která mi vrací buď info o dnešku, nebo info o dni o X dni za určitým dnem
#info = den/měsíc/rok, vše v lidské podobě
sub _get_day_info {
	my $delay = shift || 0;
	my $date = shift;
	my %starting_day_info;
	if (!$date) {
		my @a = localtime();
		if (!$delay) {
			return ($a[3], $a[4]+1, $a[5]+1900);
		}
		$starting_day_info{day}=$a[3];
		$starting_day_info{month}=$a[4];
		$starting_day_info{year}=$a[5];
	} else {
		$starting_day_info{day}=$date->day;
		$starting_day_info{month}=$date->month-1;
		$starting_day_info{year}=$date->year;
	}
	
	my $tme = timelocal(0,0,12,$starting_day_info{day},$starting_day_info{month},$starting_day_info{year});
	my @r = localtime($tme + $delay * 86400);
	return ($r[3], $r[4]+1, $r[5]+1900);
}

has 'day' => (
	is=>'ro',
	isa=>'Int',
	required=>1
);

has 'month' => (
	is=>'ro',
	isa=>'Int',
	required=>1
);

has 'year' => (
	is=>'ro',
	isa=>'Int',
	required=>1
);


#Pokud nedostanu žádné argumenty, chci dnešek
#(využívám pořád)
around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;

	if (scalar @_) {
		return $class->$orig(@_);
	} else {
		my @info = _get_day_info();
		return $class->$orig(day=>$info[0], month=>$info[1], year=>$info[2]);
	}
};

#Ze stringu yyyy-mm-dd udělám objekt date
sub get_from_string {
    my $d = shift; 
	$d=~/(\d\d\d\d)-(\d+)-(\d+)/;
	return new Zpravostroj::Date(day=>$3, month=>$2, year=>$1);
}

#Ze stringu uloženého v souboru udělám date
sub get_from_file {
	my $pth = shift;

	open my $f, "<:utf8", $pth;
	my $d = <$f>;
	close $f;
	return get_from_string($d);
}

#(mělo by být asi put_, ale už to neměním)
#udělá z Date string yyyy-mm-dd
sub get_to_string {
	my $s = shift;
	return $s->year."-".$s->month."-".$s->day;
}

#Udělá z Date "hezký" string dd. mm. yyyy
sub get_to_nice_string {
	my $s = shift;
	return $s->day.". ".$s->month.". ".$s->year;
}

#Uloží do souboru
sub get_to_file {
	my $s = shift;
	my $where = shift;
	say "Get to file: s je $s , where je $where";
	open my $f, ">:utf8", $where;
	print $f $s->get_to_string;
	close $f;
}

#Vrátí H dní po dni S
sub get_days_after {
	my $s = shift;
	my $h = shift;
	my @info = _get_day_info($h, $s);
	my $d = new Zpravostroj::Date(day=>$info[0], month=>$info[1], year=>$info[2]);
	return $d;
}

#vrátí H dní po dnešku
sub get_days_after_today {
	my $h = shift;
	return ((new Zpravostroj::Date)->get_days_after($h));
}

#vrátí H dní před dneškem
sub get_days_before_today {
	my $h = shift;
	return get_days_after_today(-$h);
}


#jsou si rovny dva dny?
sub is_the_same_as {
	my ($a, $b) = @_;
	return($a->year == $b->year and $a->month eq $b->month and $a->day eq $b->day);
}


#je Date starší, než další Date?
#("starší" je myšleno "byl dřív")
#asi by bylo lepší pojmenovat "sooner", ale už to neměním 
sub is_older_than {
	my ($s, $newer)=@_;
	if ($newer->{year} > $s->{year}) {
		return 1;
	}
	if ($newer->{year} < $s->{year}) {
		return 0;
	}
	if ($newer->{month} > $s->{month}) {
		return 1;
	}
	if ($newer->{month} < $s->{month}) {
		return 0;
	}
	if ($newer->{day} > $s->{day}) {
		return 1;
	}
	if ($newer->{day} < $s->{day}) {
		return 0;
	}
		
	return 0;
}






sub getpartoftime {
	
	my $w=shift;
	my $plus = shift || 0;
	my $d = shift;
	my $tme = $d ? timelocal(0,0,0,$d->day,$d->month-1,$d->year) : time();
	my @r = localtime($tme + $plus * 86400+((defined $d and $d->month==10 and $plus>0)?3600:0));
	return $r[$w];
}

sub daypath {
	my $s = shift;
	mkdir "data";
	mkdir "data/articles";
	my $year = int($s->year);
	my $month = int($s->month);
	my $day = int($s->day);
	mkdir "data/articles/".$year;
	mkdir "data/articles/".$year."/".$month;	
	mkdir "data/articles/".$year."/".$month."/".$day;
	return "data/articles/".$year."/".$month."/".$day;
}


__PACKAGE__->meta->make_immutable;


1;

