package Hello::Form::Renderer;
use Any::Moose;
use HTML::Shakan::Utils;

has 'id_tmpl' => (
    is => 'ro',
    isa => 'Str',
    default => 'id_%s',
);

sub render {
    my ($self, $form) = @_;

    my @res;
    for my $field ($form->fields) {
        unless ($field->id) {
            $field->id(sprintf($self->id_tmpl(), $field->{name}));
        }
        push @res, '<p>';
        if ($field->label) {
            push @res, sprintf( q{<label for="%s">%s</label>},
                $field->{id}, encode_entities( $field->{label} ) );
        }
        push @res, '<span class="inputbox">'.$form->widgets->render( $form, $field )."</span></p>\n";
    }
    join '', @res;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
