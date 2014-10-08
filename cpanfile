on 'configure' => sub {

    # Required by the scripting in Makefile.PL
    requires 'Cwd'         => 0;
    requires 'FindBin'     => 0;
    requires 'Time::Piece' => 0;

    # These are all used by Module::Install::PRIVATE::App_bif
    requires 'File::Spec'  => 0;
    requires 'Path::Tiny'  => 0;
    requires 'Pod::Select' => 0;
};

on 'runtime' => sub {

    # General
    requires 'Log::Any';
    requires 'Time::Piece';

    # Bif::DB
    requires 'DBD::SQLite'   => '1.42';
    requires 'DBIx::ThinSQL' => '0.0.30';

    # Bif::DBW
    requires 'DBIx::ThinSQL::SQLite' => '0.0.10';
    requires 'Digest::SHA'           => 0;
    requires 'DBIx::ThinSQL::Deploy' => '0.0.30';

    # App::bif[::OptArgs]
    requires 'OptArgs' => '0.1.16';

    # App::bif::init/upgrade
    requires 'File::ShareDir' => 0;

    # App::bif::show/log
    requires 'Time::Duration' => 0;
    requires 'POSIX'          => 0;
    requires 'locale'         => 0;

    # App::bif::show
    requires 'Text::Autoformat' => 0;

    # App::bif
    requires 'Config::Tiny'       => '2.19';
    requires 'File::HomeDir'      => 0;
    requires 'File::Which'        => 0;
    requires 'IO::Prompt::Tiny'   => 0;
    requires 'Log::Any::Adapter'  => '0.11';
    requires 'Path::Tiny'         => '0.019';
    requires 'Proc::InvokeEditor' => 0;
    requires 'Term::ANSIColor'    => 0;

    if ( $^O eq 'MSWin32' ) {
        requires 'Term::Size::Win32' => 0;
    }
    else {
        requires 'Term::Size::Perl' => 0;
    }

    requires 'Text::FormatTable' => 0;

    # App::bifsync
    requires 'Log::Any::Plugin::Levels' => 0;

    # Synchronisation
    requires 'AnyEvent';
    requires 'Coro';
    requires 'Coro::Handle';
    requires 'JSON';
    requires 'Role::Basic' => 0;
    requires 'Sys::Cmd'    => '0.81.6';
};

on 'test' => sub {

    # tests
    test_requires 'File::chdir'    => 0;
    test_requires 'FindBin'        => 0;
    test_requires 'Test::More'     => 0;
    test_requires 'Test::Fatal'    => 0;
    test_requires 'Exporter::Tidy' => 0;
};

on 'develop' => sub {
    requires 'App::githook_perltidy';
    requires 'Mo';
    requires 'Module::CPANfile' => '1.1000';
    requires 'Module::Install';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::ReadmeFromPod';
    requires 'Text::Diff';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'YAML::XS';
};
