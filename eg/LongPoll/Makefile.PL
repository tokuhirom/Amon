use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'LongPoll',
    AUTHOR        => 'Some Person <person@example.com>',
    VERSION_FROM  => 'app.psgi',
    PREREQ_PM     => {
        'Amon2'                           => '3.50',
        'Amon2::Lite'                     => '0.08',
        'Text::Xslate'                    => '1.5006',
		'Tatsumaki' => 0,
    },
    MIN_PERL_VERSION => '5.008001',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
);
