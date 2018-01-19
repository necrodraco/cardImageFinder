#! /usr/bin/perl

package AutoCompiler{
	use File::Find; 
	use DBI; 
	use YAML 'LoadFile';
	use Data::Dumper; 
	my $ressources; 
	if(-e 'properties.yaml'){
		$ressources = LoadFile('properties.yaml');
	}else{
		$ressources = LoadFile('template.yaml');
	}	
	my $inImage = $ressources->{'image'};
	my @cdbs; 
	push(@cdbs, $ressources->{'cdb'});
	my $inExpansion = $ressources->{'expansion'};
	my %out; 

	find({ wanted => \&findCDBs, no_chdir=>1}, $inExpansion);
	foreach my $file(@cdbs){
		my $dbargs = {'AutoCommit' => 1, 'PrintError' => 1};
		my $dbh = DBI->connect("dbi:SQLite:dbname=$file", "", "", $dbargs);
		my $statement = 'select d.id, d.ot, d.type, t.name from datas d join texts t on d.id = t.id';
		my $sth = $dbh->prepare($statement)or die "$DBI::errstr\n";
		$sth->execute();
		while(my $row = $sth->fetchrow_hashref()){
			if($row->{'ot'} < 5 && $row->{'type'} != 16385 && $row->{'type'} != 16401 && $row->{'type'} != 16384 && !($row->{'name'} =~ m/(Anime)/)){			
				$out{$row->{'id'}}{$file} = $row;
			}
		}
		$dbh->disconnect();
	}
	find({ wanted => \&findImages, no_chdir=>1}, $inImage);
	my %idlist; 	
	my $level = 1; 
	my $count = 0; 
	while(my ($id, $stat) = each %out){
		if($stat != 0){
			print Dumper $stat; 			
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
	sub findImages(){
		my $image = $File::Find::name; 
		if($image =~ m/.jpg/ || $image =~ m/.png/){
			if($image =~ m/pics\//){
				$image = (split(/pics\//, $image))[1]; 
				$image =~ s/(.png|.jpg)//g; 
				$out{$image} = 0;
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
