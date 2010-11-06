package ReturnNewerThemes;use Moose::Role;use Globals;requires 'datestamp_path';requires 'get_newest_themes';requires 'lastcount_path';sub _get_last_datestamp {	my $s = shift;	my $p = $s->datestamp_path;	if (!-e $p) {		return ();	}		return get_date_from_file($p);}sub _get_edge_day {	my @r = localtime(time() +  86400*$day_tolerance);	return($r[3], $r[4]+1, $r[5]+1900);}sub _get_today {	my @r = localtime();	return($r[3], $r[4]+1, $r[5]+1900);}sub _save_datestamp {	my $s = shift;	my $p = $s->datestamp_path;		my ($day, $month, $year) = _get_today;		open my $f, ">", $p;	print $f $day."-".$month."-".$year;	close $f;}sub _is_newer {    my $s=shift;	my ($day, $month, $year) = $s->_get_last_timestamp;	if (!$day) {		return 0;	} else {		my ($tday, $tmonth, $tyear) = _get_edge_day;		return compare_dates($day, $month, $year, $tday, $tmonth, $tyear);	}}sub get_themes {	my $s = shift;	if ($s->_is_newer) {		$s->_save_datestamp;		my $c = $s->get_newest_themes;		my $z = IO::Compress::Bzip2->new ($s->lastcount_path);			print $z Dumper($c);				close($z);		return $c;	} else {		my $z = IO::Uncompress::Bunzip2->new($s->lastcount_path);			my $dumped = join ("", <$z>);		close($z);		my $VAR1;		eval($dumped);		return $VAR1;	}}