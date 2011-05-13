#!/usr/bin/env perl
# -*-mode:cperl; indent-tabs-mode: nil-*-

## Spellcheck as much as we can
## Requires TEST_SPELL to be set

use 5.006;
use strict;
use warnings;
use Test::More;
select(($|=1,select(STDERR),$|=1)[1]);

my (@testfiles, @textfiles, @podfiles, @commentfiles, $fh);

if (! $ENV{RELEASE_TESTING}) {
	plan (skip_all =>  'Test skipped unless environment variable RELEASE_TESTING is set');
}
elsif (!eval { require Text::SpellChecker; 1 }) {
	plan skip_all => 'Could not find Text::SpellChecker';
}
else {
	opendir my $dir, 't' or die qq{Could not open directory 't': $!\n};
	@testfiles = map { "t/$_" } grep { /^.+\.(t|pl)$/ and ! /\#/ } readdir $dir;
	closedir $dir or die qq{Could not closedir "$dir": $!\n};

	@textfiles = qw{README Changes TODO README.dev INSTALL UPGRADE META.yml scripts/README};

	@podfiles = qw{Bucardo.pm bucardo_ctl};

	@commentfiles = qw{Makefile.PL Bucardo.pm bucardo_ctl};

	push @commentfiles => qw{scripts/bucardo_rrd scripts/bucardo-report scripts/check_bucardo_sync scripts/bucardo_ctl.rc};

	plan tests => @textfiles + @testfiles + @podfiles + @commentfiles;
}

my %okword;
my $file = 'Common';
while (<DATA>) {
	if (/^## (.+):/) {
		$file = $1;
		next;
	}
	next if /^#/ or ! /\w/;
	for (split) {
		$okword{$file}{$_}++;
	}
}


sub spellcheck {
	my ($desc, $text, $filename) = @_;
	my $check = Text::SpellChecker->new(text => $text);
	my %badword;
	while (my $word = $check->next_word) {
		next if $okword{Common}{$word} or $okword{$filename}{$word};
		next if $filename =~ m{t/} and $okword{Tests}{$word};
		$badword{$word}++;
	}
	my $count = keys %badword;
	if (! $count) {
		pass ("Spell check passed for $desc");
		return;
	}
	fail ("Spell check failed for $desc. Bad words: $count");
	for (sort keys %badword) {
		diag "$_\n";
	}
	return;
}


## First, the plain old textfiles
for my $file (@textfiles) {
	if (!open $fh, '<', $file) {
		fail (qq{Could not find the file "$file"!});
	}
	else {
		{ local $/; $_ = <$fh>; }
		close $fh or warn qq{Could not close "$file": $!\n};
		if ($file eq 'Changes') {
			s{\S+\@\S+\.\S+}{}gs;
		}
		spellcheck ($file => $_, $file);
	}
}

## Now the embedded POD
SKIP: {
	if (!eval { require Pod::Spell; 1 }) {
		skip ('Need Pod::Spell to test the spelling of embedded POD', 2);
	}

	for my $file (@podfiles) {
		if (! -e $file) {
			fail (qq{Could not find the file "$file"!});
		}
		my $string = qx{podspell $file};
		spellcheck ("POD from $file" => $string, $file);
	}
}

## Now the comments
SKIP: {
	if (!eval { require File::Comments; 1 }) {
		skip ('Need File::Comments to test the spelling inside comments',@testfiles+@commentfiles);
	}

	my $fc = File::Comments->new();

	my @files;
	for (sort @testfiles) {
		push @files, "$_";
	}

	for my $file (@testfiles, @commentfiles) {
		if (! -e $file) {
			fail (qq{Could not find the file "$file"!});
		}
		my $string = $fc->comments($file);
		if (! $string) {
			fail (qq{Could not get comments from file $file});
			next;
		}
		$string = join "\n" => @$string;
		$string =~ s/=head1.+//sm;
		spellcheck ("comments from $file" => $string, $file);
	}


}


__DATA__
## These words are okay

## Common:

Bucardo
DDL
DBIx
LOGIN
Sabino
Mullane
bucardorc
customselect
fullcopy
pushdelta
perl

## README

DBD
Makefile
bucardo
subdirectory

## Changes


- Allow multiple item updates, e.g. bucardo_ctl update sync s1 s2 s3 ping=true
- Allow wildcards in item updates, e.g. bucardo_ctl update sync s* ping=true
Aolmezov
Backcountry
Bahlai
Boes
BSD's
BUCARDODIR
Deckelmann
Farmawan
FreeBSD
GSM
Gugic
Kebrt
Machado
Mathieu
NAMEDATALEN
PgBouncer's
PID
PIDCLEANUP
PIDs
Refactor
Rosser
Schwarz
SMTP
Sendmail
Tolley
UNLISTEN
Vilem
Wendt
Yan
addallsequences
addalltables
attnums
boolean
bytea
checktime
chunking
config
cnt
ctl
customcode
dbhost
dbi
dbproblem
dbs
debugstderr
debugstdout
getconn
ident
inactivedestroy
intra
kidsalive
localtime
maxkicks
mcp
migrator
multi
onetimecopy
pgbouncer
pid
pidfile
pids
ppid
rc
respawn
rowid
schemas
slony
smallint
sourcedbh
sourcelimit
src
stayalive
targetlimit
tcp
timestamp
timestamptz
trigrules
upsert
wildcards

## TODO

CPAN
PID
Readonly
STDIN
TODO
async
cronjobs
ctl
failover
intra
multi
onetimecopy
orderable
pid
pkey
plperl
regex
synctype
synctypes
timeslices
wildcard

## bucardo_ctl

args
bucardo
cleandebugs
cronjob
CTL
customcodes
daysback
dbgroup
dbport
dbuser
debugfile
debugfilesep
debugname
debugsyslog
dir
GetOptions
MCP
notimer
piddir
pkonly
qquote
retrysleep
rootdb
sendmail
showdays
startup
Startup
superhelp
syncname
syncnames
sync's
usr
vate

## README.dev

BucardoTesting
Checksum
DBIx
IncludingOptionalDependencies
PGP
PlanetPostgresql
PostgreSQL
README
TODO
YAML
addtable
asc
ba
bc
blib
checksums
cperl
ctl
dbdpg
ddl
dev
distcheck
distclean
disttest
emacs
fe
filename
gitignore
gpg
html
http
libpq
makefile
manifypods
md
mis
multicolpk
multicolpushdelta
multicolswap
nosetup
perlcritic
perlcriticrc
postgresql
pragma
realclean
sha
sig
skipcheck
spellcheck
submitnews
teardown
testname
tmp
txt
uniqueconstraint
weeklynews
wildkick
www
yaml
yml

## INSTALL

conf
config
ctl
freenode
http
IRC
irc
syslog
wiki

## Bucardo.pm

Backcountry
multi
unapologetically

## Tests

backend
bct
ctl
ctlargs
dbh
dbhA
dbhB
dbhX
diag
droptest
env
fff
india
initdb
inty
juliet
larry
makedelta
moe
Multi
prereqs
Pushdelta
qq
Spellcheck
textfiles
therd
YAML
YAMLiciousness
yml

## Bucardo.pm

HUP
PID
PIDFILE
chgrp
config
cperl
ctl
customcode
dbgroups
dbs
glog
http
mcp
stderr
stdout
syslog

## UPGRADE

sudo
untar

## META.yml

Hostname
MailingList
Sys
Syslog
bsd
bugtracker
bugzilla
repo
sourceforge
url

## scripts/README

rrd

## scripts/check_bucardo_sync

Nagios
nagios
ourself
prepend
utils

## scripts/bucardo-report

hidetime
hostname
nonagios
runsql
showanalyze
showdatabase
showexplain
showhost
shownagios
showsql
showsync
showsyncinfo
syncinfo
targetdbname
