#! /usr/bin/perl

package AutoCompiler{

	use File::Find; 
	use DBI; 
	my $inImage = '/home/jan/Dokumente/ygopro-percy/pics';
	my @cdbs; 
	push(@cdbs, '/home/jan/Dokumente/ygopro-percy/cards.cdb');
	my $inExpansion = '/home/jan/Dokumente/ygopro-percy/expansions';
	my %out; 

	find({ wanted => \&findCDBs, no_chdir=>1}, $inExpansion);
	
	foreach my $file(@cdbs){
		my $dbargs = {'AutoCommit' => 1, 'PrintError' => 1};
		my $dbh = DBI->connect("dbi:SQLite:dbname=$file", "", "", $dbargs);
		my $sth = $dbh->prepare('select id from datas')or die "$DBI::errstr\n";
		$sth->execute();
		while(my $row = $sth->fetchrow_hashref()){
			$out{$row->{'id'}} = 1;
		}
	}

	find({ wanted => \&findImages, no_chdir=>1}, $inImage);
	
	my %idlist; 	
	my $level = 0; 
	my $count = 0; 
	while(my ($id, $stat) = each %out){
		if($stat == 1){
			if(scalar @{$idlist{$level}} == 30){
				$level++;
				$count = 0;  
			}
			$idlist{$level}[$count] = $id;
			$count++;   	
		}
	}
	
	while(my ($level, $list) = each %idlist){
		open(my $fh, '>', "$level.ydk") or die "Could not open file '$filename' $!";
			foreach my $id(@{$list}){
				print $fh "$id\n"; 
			}
		close($fh);	
	}

	#use Data::Dumper; 
	#print 'Ausgabe: '.(Dumper \%idlist)."\n"; 

	sub findImages(){
		my $image = $File::Find::name; 
		if($image =~ m/.jpg/ || $image =~ m/.png/){
			my $image2 = $image; 
			if($image2 =~ m/field\//){
				 
			}elsif($image2 =~ m/pics\//){
				$image2 = (split(/pics\//, $image2))[1]; 
				$image2 =~ s/(.png|.jpg)//g; 
				$out{$image2} = 0;
			} 
		}
	}

	sub findCDBs(){
		my $cdb = $File::Find::name; 
		if($cdb =~ m/.cdb/){
			push(@cdbs, $cdb);
		}
	}

}
