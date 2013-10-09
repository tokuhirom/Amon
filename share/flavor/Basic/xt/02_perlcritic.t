use strict;
use warnings;
use Test::More;

eval {
    require Perl::Critic;
    Perl::Critic->VERSION(1.105);

    require Test::Perl::Critic;
    Test::Perl::Critic->VERSION(1.02);
    Test::Perl::Critic->import(
        -profile => \(join q{}, <DATA>)
    );
};
note $@ if $@;
plan skip_all => "Perl::Critic 1.105+ or Test::Perl::Critic 1.02+ is not installed." if $@;

all_critic_ok('lib', 'script', 'bin');

__END__

only=1

# -------------------------------------------------------------------------
# Not important.

[BuiltinFunctions::ProhibitSleepViaSelect]
[BuiltinFunctions::RequireGlobFunction]
[ClassHierarchies::ProhibitOneArgBless]

# -------------------------------------------------------------------------
# Bug detection
[InputOutput::ProhibitBarewordFileHandles]
[Modules::RequireFilenameMatchesPackage]
[Subroutines::ProhibitNestedSubs]
[Subroutines::ProhibitReturnSort]
[TestingAndDebugging::RequireUseStrict]
[Variables::ProhibitConditionalDeclarations]
[Variables::RequireLexicalLoopIterators]

[TestingAndDebugging::ProhibitNoStrict]
allow=refs

# -------------------------------------------------------------------------
# Security issue detection
[InputOutput::RequireEncodingWithUTF8Layer]
[Modules::ProhibitEvilModules]
[InputOutput::ProhibitTwoArgOpen]
