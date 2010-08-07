package Hello::Web;
use Amon2::Web -base => (
    view_class => 'Text::MicroTemplate::File',
    base_class         => 'Hello',
);
use Hello::Form;

__PACKAGE__->load_plugins(
    'HTTPSession'   => { state => 'Cookie', store => 'File' },
    'MobileAgent'   => {},
    'MobileCharset' => {},
);

use HTML::Shakan::Model::DBIxSkinny;
sub form {
    my ( $c, $form_name ) = @_;
    my $form = Hello::Form->get(
        $form_name => (
            request => $c->request,
            model   => HTML::Shakan::Model::DBIxSkinny->new()
        )
    );
    $form->load_function_message('en');
    $form;
}

sub login_user {
    my $c = shift;
    if (not exists $c->pnotes->{login_user}) {
        my $user = do {
            if (my $user_id = $c->session->get('login_user_id')) {
                $c->get('DB')->single( user => { user_id => $user_id, } );
            }
        };
        return $c->pnotes->{login_user} = $user;
    } else {
        return $c->pnotes->{login_user};
    }
}

1;
