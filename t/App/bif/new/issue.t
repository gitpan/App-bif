use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    my $db = bif(qw/init/);

    isa_ok exception { bif(qw/ new issue /) }, 'Bif::Error::TitleRequired';

    isa_ok exception { bif(qw/ new issue title/) },
      'Bif::Error::ProjectRequired';

    isa_ok exception { bif(qw/ new issue -p todo title/) },
      'Bif::Error::ProjectNotFound';

    my $p = bif(qw/ new project todo --message message title /);

    isa_ok exception { bif(qw/ new issue -p todo this is the title/) },
      'Bif::Error::EmptyContent';

    my $i = bif(qw/new issue -p todo title -m message/);
    isa_ok $i, 'Bif::OK::NewIssue';

    is_deeply [
        $db->xarray(
            select     => [qw/issue_status.def issue_status.project_id/],
            from       => 'issues',
            inner_join => 'project_issues',
            on         => 'project_issues.issue_id = issues.id',
            inner_join => 'issue_status',
            on         => 'issue_status.id = project_issues.status_id',
            where      => { 'issues.id' => $i->{id} },
        )
      ],
      [ 1, $p->{id} ], 'issue default status and project ok';

    isa_ok exception { bif(qw/ new issue -p todo title -s unknown/) },
      'Bif::Error::InvalidStatus';

    my $i2 = bif(qw/new issue -p todo title -m message2 -s stalled/);

    is_deeply [
        $db->xarray(
            select     => [qw/issue_status.status issue_status.project_id/],
            from       => 'issues',
            inner_join => 'project_issues',
            on         => 'project_issues.issue_id = issues.id',
            inner_join => 'issue_status',
            on         => 'issue_status.id = project_issues.status_id',
            where      => { 'issues.id' => $i2->{id} },
        )
      ],
      [ 'stalled', $p->{id} ], 'issue status and project ok';

};

done_testing();
