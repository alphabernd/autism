#!/usr/bin/perl

use strict;
use warnings;

use lib ("./db");

use Switch;
use Template;
use CGI;

use Database;

sub main {
    my $cgi = CGI->new;	
    

    my $template = Template->new(
                    { INCLUDE_PATH  => './view',
                      POST_CHOMP    => 1,
                      PRE_CHOMP     => 1,
                      TRIM          => 1,
                      PRE_PROCESS   => 'head.tmpl',
                      POST_PROCESS  => 'foot.tmpl'
                    });

    print $cgi->header();

    switch ($cgi->param('view') || "index") {
        case "player" { player($cgi, $template) }
        else { start($cgi, $template); }
    }    
}

sub escape_hash {
    my $cgi = shift;
    my $hash = shift;

    for my $key (%$hash) {
        $hash->{$key} = $cgi->escapeHTML($hash->{$key});
    }

    return $hash
}

sub escape_array {
    my $cgi = shift;
    my $array = shift;

    for(my $i = 0; $i < @$array; $i++) {
        $array->[$i] = escape_hash($cgi, $array->[$i]);
    }
    
    return $array;
}

sub player {
    my ($cgi, $template) = @_;
    
    my $name = $cgi->param('name');

    unless($name) {
        start($cgi, $template);
    }
    
    my $db = Database->new;
    my $vars = {};
    $vars->{name} = $cgi->escapeHTML($name);

    my $info = $db->get_player_information($name);
    unless($info) {
        start($cgi, $template);
        return;
    }

    $vars->{info} = escape_hash($cgi, $db->get_player_information($name));
    $vars->{kills} = escape_array($cgi, $db->get_kills_by_player($name));
    $vars->{murders} = escape_array($cgi, $db->get_murders_by_victim($name));
    $vars->{destroyed} = escape_array($cgi, $db->get_destroyed_blocks_by_player($name));
    $vars->{placed} = escape_array($cgi, $db->get_placed_blocks_by_player($name));
    $template->process('player.tmpl', $vars) || print $template->error;
}

sub start {
    my ($cgi, $template) = @_;
    
    my $db = Database->new;

    my $vars = {};
    $vars->{actions} = escape_array($cgi, $db->get_player_actions(50));
    $vars->{murders} = escape_array($cgi, $db->get_player_killed);
    $vars->{kills} = escape_array($cgi, $db->get_player_kills);
    $vars->{hours} = escape_array($cgi, $db->get_hours_played);
    $vars->{total} = $db->get_total_hours_played;
    $vars->{map} = 'Alpharealm';
    $vars->{created} = 'Dec 15 2013';
    $vars->{players} = $db->get_player_count;
    $template->process('index.tmpl', $vars) || print $template->error;
}

main;
