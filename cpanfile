on 'configure' => sub {

    # Required by the scripting in Makefile.PL
    requires 'Cwd' => 0;
    requires 'FindBin' => 0;

    # These are all used by Module::Install::PRIVATE::App_bif
    requires 'File::Spec'  => 0;
    requires 'Path::Tiny'  => 0;
    requires 'Pod::Select' => 0;
};

on 'runtime' => sub {

    # Bif::DB
    requires 'DBD::SQLite' => '1.42';
    requires 'DBIx::ThinSQL' => '0.0.12';

    # Bif::DB::RW
    requires 'DBIx::ThinSQL::SQLite' => '0.0.6';

    # App::bif
    requires 'OptArgs' => '0.1.6';

    # App::bif::init/upgrade
    requires 'File::ShareDir' => 0;

    # App::bif::show/log
    requires 'Time::Duration' => 0;
    requires 'POSIX'          => 0;
    requires 'locale'         => 0;

    # App::bif::show
    requires 'Text::Autoformat' => 0;

    # App::bif::Context
    requires 'Config::Tiny'       => '2.19';
    requires 'File::HomeDir'      => 0;
    requires 'IO::Pager'          => '0.24';
    requires 'IO::Prompt::Tiny'   => 0;
    requires 'Log::Any::Adapter'  => '0.11';
    requires 'Path::Tiny'         => '0.019';
    requires 'Proc::InvokeEditor' => 0;
    requires 'Term::ANSIColor'    => 0;
    requires 'Term::Size'         => 0;
    requires 'Text::FormatTable'  => 0;

    # App::bifsync
    requires 'Log::Any::Plugin::Levels' => 0;

    # Synchronisation
    requires 'Coro';
    requires 'Coro::Handle';
    requires 'Role::Basic' => 0;
    requires 'Sys::Cmd' => '0.81.6';
};

on 'test' => sub {

    # tests
    test_requires 'File::chdir' => 0;
    test_requires 'FindBin'     => 0;
    test_requires 'Test::More'  => 0;
    test_requires 'Test::Fatal' => 0;
    test_requires 'Exporter::Tidy'     => 0;
};

on 'develop' => sub {
    requires 'Module::Install';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::CPANfile';
};
