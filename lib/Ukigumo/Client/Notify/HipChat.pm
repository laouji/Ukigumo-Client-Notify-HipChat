use strict;
use warnings;

package Ukigumo::Client::Notify::HipChat;
use Ukigumo::Constants;
use Ukigumo::Helper qw(status_str);
use Furl;
use JSON::XS;

sub new {
    my $class = shift;
    my $args = shift || {};
    
    $args->{token} || die "hipchat api token is required";
    $args->{room_id} || die "hipchat room id is required";
    
    $args->{host} = "https://api.hipchat.com";
    $args->{api_version} ||= 'v2';
    
    bless $args, $class;
}

sub send {
    my ($self, $c, $status, $last_status, $report_url) = @_;

    my $message = sprintf("%s [%s] %s %s \n%s", $c->project, status_str($status), $c->vc->get_revision(), $report_url );

    my $post_data = {
        color => $self->_message_color($status), 
        message => $message,
        message_format => "text",
        notify => $status == STATUS_SUCCESS ? \0 : \1,
    };
    
    my $encoder = JSON::XS->new->utf8;
    my $json = $encoder->encode($post_data);

    my $furl = Furl->new();
    my $url = sprintf(
        "%s/%s/room/%s/notification?auth_token=%s", 
        $self->{host}, 
        $self->{api_version}, 
        $self->{room_id}, 
        $self->{token},
    );

    my $res = $furl->post($url, [ 'Content-Type' => 'application/json' ], $json);
    return $res->is_success;
}

sub _message_color {
    my ($self, $status) = @_;
    my $color = $status eq STATUS_SUCCESS ? 'green'
    : $status eq STATUS_FAIL    ? 'red'
    : 'yellow';

    return $color;
}

1;


