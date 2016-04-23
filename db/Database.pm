package Database;

use strict;
use warnings;

use DBI;

sub new {
    my $class = shift;
    my $self = {};

    $self->{logblock} = DBI->connect("DBI:mysql:logblock;host=127.0.0.1", "logblock", "ENTER PASSWORD HERE");
    $self->{clandb} = DBI->connect("dbi:SQLite:dbname=/data/minecraft/alpha/plugins/SimpleClans/SimpleClans.db","","");


    bless $self, $class;
    return $self;
}

sub get_player_information {
    my $self = shift;
    my $name = shift;

    my $st = $self->{logblock}->prepare("SELECT MIN(`firstlogin`),MAX(`lastlogin`),SUM(`onlinetime`) FROM `lb-players` WHERE `playername` = ? GROUP BY `playername`;");

    $st->bind_param(1, $name);
    $st->execute();

    my $ret = {};
    while (my ($first, $last, $time) = $st->fetchrow_array()) {
        $ret->{first} = $first;
        $ret->{last} = $last;
        $ret->{time} = sprintf("%.2f", $time / 60 / 60);
    }

    $st = $self->{clandb}->prepare("SELECT `sc_clans`.`tag`,`sc_clans`.`name`,`deaths` FROM `sc_players` JOIN `sc_clans` ON `sc_players`.`tag` = `sc_clans`.`tag` WHERE `sc_players`.`name` = ?;");
    $st->bind_param(1, $name);
    $st->execute();

    while(my ($tag, $clan, $deaths) = $st->fetchrow_array()) {
        $ret->{tag} = $tag;
        $ret->{clan} = $clan;
        $ret->{deaths} = $deaths;
    }

    return exists($ret->{first}) ? $ret : undef;
}

sub get_player_actions {
    my $self = shift;
    my $limit = shift || 50;

    my $st = $self->{logblock}->prepare("SELECT `playername`, `numblocks` FROM `lb-players` JOIN (SELECT COUNT(*) AS `numblocks`, `playerid` FROM `lb-world` WHERE playerid <> 216 AND playerid <> 525 AND playerid <> 1 AND playerid <> 51 GROUP BY `playerid` ORDER BY `numblocks` DESC LIMIT ? ) AS `actions` USING (`playerid`);");

    $st->bind_param(1, $limit);
    $st->execute();

    my @ret = ();
    while (my ($name, $num) = $st->fetchrow_array()) {
        if($name eq "WaterFlow" or $name eq "LavaFlow" or $name eq "Wither") {
            next;
        }

        push(@ret, { name => $name, actions => $num });
    } 

    return \@ret;
}

sub get_player_count {
    my $self = shift;

    my $st = $self->{logblock}->prepare("SELECT `playername` FROM `lb-players` GROUP BY `playername`;");
    $st->execute();

    my $num = 0;

    while($st->fetchrow_array()) {
        $num++;
    }

    return $num;
}

sub get_player_kills {
    my $self = shift;
    
    my $st = $self->{clandb}->prepare("SELECT `attacker`, COUNT(`attacker`) FROM `sc_kills` GROUP BY `attacker` ORDER BY COUNT(`attacker`) DESC LIMIT 50;");
    $st->execute();

    my @ret = ();
    while (my ($name, $num) = $st->fetchrow_array()) {
        push(@ret, { name => $name, kills => $num });
    }

    return \@ret;
}

sub get_player_killed {
    my $self = shift;

    my $st = $self->{clandb}->prepare("SELECT `victim`, COUNT(`victim`) FROM `sc_kills` GROUP BY `victim` ORDER BY COUNT(`victim`) DESC LIMIT 50;");
    $st->execute();

    my @ret = ();
    while (my ($name, $num) = $st->fetchrow_array()) {
        push(@ret, { name => $name, murdered => $num });
    }

    return \@ret;
}

sub get_hours_played {
    my $self = shift;

    my $st = $self->{logblock}->prepare("SELECT `playername`,SUM(`onlinetime`) FROM `lb-players` GROUP BY LOWER(`playername`) ORDER BY SUM(`onlinetime`) DESC LIMIT 50;");
    $st->execute();

    my @ret = ();
    while (my ($name, $num) = $st->fetchrow_array()) {
        $num = sprintf("%.2f", $num / 60 / 60);
        push(@ret, { name => $name, num => $num });
    }

    return \@ret;
}

sub get_total_hours_played {
    my $self = shift;

    my $st = $self->{logblock}->prepare("SELECT SUM(`onlinetime`) FROM `lb-players`;");
    $st->execute();

    my $ret = {};
    while (my ($total_hours) = $st->fetchrow_array()) {
        $ret->{total_hours} = sprintf("%.2f", $total_hours / 60 / 60);    
    }

    return $ret;
}

sub get_kills_by_player {
    my $self = shift;
    my $name = shift;

    my $st = $self->{clandb}->prepare("SELECT `victim`, COUNT(`victim`) FROM `sc_kills` WHERE `attacker` = ? GROUP BY `victim` ORDER BY COUNT(`victim`) DESC;");
    $st->bind_param(1, $name);
    $st->execute();

    my @ret = ();
    while (my ($name, $num) = $st->fetchrow_array()) {
        push(@ret, { name => $name, kills => $num });
    }

    return \@ret;
}

sub get_murders_by_victim {
    my $self = shift;
    my $name = shift;

    my $st = $self->{clandb}->prepare("SELECT `attacker`, COUNT(`attacker`) FROM `sc_kills` WHERE `victim` = ? GROUP BY `attacker` ORDER BY COUNT(`attacker`) DESC;");
    $st->bind_param(1, $name);
    $st->execute();

    my @ret = ();
    while (my ($name, $num) = $st->fetchrow_array()) {
        push(@ret, { name => $name, murdered => $num });
    }

    return \@ret;
}


sub sanitize_block_data {
    my $id = shift;
    my $data = shift;

    if($id == 151 or $id == 92 or $id == 144 or $id == 127 or $id == 33 or $id == 83 or $id == 99 or $id == 148 or $id == 81 or $id == 84 or $id == 149 or $id == 86 or $id == 26 or $id == 132 or $id == 196 or $id == 131 or $id == 158 or $id == 29 or $id == 194 or $id == 145 or $id == 10 or $id == 105 or $id == 143 or $id == 146 or $id == 61 or $id == 90 or $id == 193 or $id == 100 or $id == 170 or $id == 71 or $id == 130 or $id == 197 or $id == 60 or $id == 77 or $id == 69 or $id == 96 or $id == 167 or $id == 176 or $id == 177 or $id == 106 or $id == 59 or $id == 115 or $id == 107 or $id == 183 or $id == 184 or $id == 185 or $id == 186 or $id == 186 or $id == 187 or $id == 93 or $id == 94 or $id == 65 or $id == 63 or $id == 68 or $id == 27 or $id == 154 or $id == 75 or $id == 76 or $id == 142 or $id == 8 or $id == 9 or $id == 55 or $id == 54 or $id == 23 or $id == 50 or $id == 66 or $id == 53 or $id == 67 or $id == 108 or $id == 109 or $id == 114 or $id == 128 or $id == 134 or $id == 135 or $id == 136 or $id == 156 or $id == 163 or $id == 164 or $id == 180 or $id == 203 or $id == 64 or $id == 11 or $id == 141 or $id == 157 or $id == 195 or $id == 72 or $id == 28 or $id == 118 or $id == 91 or $id ==104 or $id == 62 or $id == 70 or $id == 34) {
        return 0;
    }
    if($id == 44 or $id == 126 or $id == 182 or $id == 175 or $id == 6) {
        return $data & 7;
    }
    if($id == 162 or $id == 18 or $id == 161 or $id == 17) {
        return $data & 3;
    }
    if($id == 155) {
        return $data & 2;
    }
    return $data;
};

sub get_destroyed_blocks_by_player {
    my $self = shift;
    my $name = shift;

    my $st = $self->{logblock}->prepare("SELECT COUNT(*),`replaced`,`data` from `lb-world` JOIN `lb-players` ON `lb-world`.`playerid` = `lb-players`.`playerid` WHERE `lb-players`.`playername` = ? AND `type` = 0 GROUP BY `replaced`,`data`;");
    $st->bind_param(1, $name);
    $st->execute();

    my @ret = ();
FETCH: while (my ($num, $type, $data) = $st->fetchrow_array()) {
        my $tmp = sanitize_block_data($type, $data);
        foreach my $block (@ret) {
            if($block->{type} == $type and $block->{data} == $tmp) {
                $block->{num} += $num;
                next FETCH;
            }
        }
        push(@ret, { num => $num, type => $type, data => $tmp });
    }

    @ret = sort { $b->{num} <=> $a->{num} } @ret;

    return \@ret;
}

sub get_placed_blocks_by_player {
    my $self = shift;
    my $name = shift;

    my $st = $self->{logblock}->prepare("SELECT COUNT(*),`type`,`data` from `lb-world` JOIN `lb-players` ON `lb-world`.`playerid` = `lb-players`.`playerid` WHERE `lb-players`.`playername` = ? AND `replaced` = 0 GROUP BY `type`,`data`;");
    $st->bind_param(1, $name);
    $st->execute();

    my @ret = ();
FETCH: while (my ($num, $type, $data) = $st->fetchrow_array()) {
        my $tmp = sanitize_block_data($type, $data);

        foreach my $block (@ret) {
            if($block->{type} == $type and $block->{data} == $tmp) {
                $block->{num} += $num;
                next FETCH;
            }
        }

        push(@ret, { num => $num, type => $type, data => $tmp });
    }

    @ret = sort { $b->{num} <=> $a->{num} } @ret;
    return \@ret;
}
1;
