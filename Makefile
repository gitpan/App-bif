# This Makefile is for the App::bif extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.66 (Revision: 66600) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT => q[Distributed Project Management Tool]
#     AUTHOR => [q[Mark Lawrence <nomad@null.net>]]
#     BUILD_REQUIRES => { CPAN::Meta=>q[0], ExtUtils::MakeMaker=>q[6.59] }
#     CONFIGURE_REQUIRES => {  }
#     DISTNAME => q[App-bif]
#     EXE_FILES => [q[bin/bif], q[bin/bifsync]]
#     LICENSE => q[gpl_3]
#     MAN1PODS => { tmpdocs/bif-list-hubs.pod=>$(INST_MAN1DIR)/bif-list-hubs.$(MAN1EXT), tmpdocs/bif-list-project-status.pod=>$(INST_MAN1DIR)/bif-list-project-status.$(MAN1EXT), tmpdocs/bif-list-issues.pod=>$(INST_MAN1DIR)/bif-list-issues.$(MAN1EXT), tmpdocs/bif-new-task.pod=>$(INST_MAN1DIR)/bif-new-task.$(MAN1EXT), tmpdocs/bif-list-tasks.pod=>$(INST_MAN1DIR)/bif-list-tasks.$(MAN1EXT), tmpdocs/bif-upgrade.pod=>$(INST_MAN1DIR)/bif-upgrade.$(MAN1EXT), bin/bifsync=>$(INST_MAN1DIR)/bifsync.$(MAN1EXT), tmpdocs/bif-push.pod=>$(INST_MAN1DIR)/bif-push.$(MAN1EXT), tmpdocs/bif-register.pod=>$(INST_MAN1DIR)/bif-register.$(MAN1EXT), tmpdocs/bif-log.pod=>$(INST_MAN1DIR)/bif-log.$(MAN1EXT), tmpdocs/bif-list-projects.pod=>$(INST_MAN1DIR)/bif-list-projects.$(MAN1EXT), tmpdocs/bif-init.pod=>$(INST_MAN1DIR)/bif-init.$(MAN1EXT), tmpdocs/bif-sql.pod=>$(INST_MAN1DIR)/bif-sql.$(MAN1EXT), tmpdocs/bif-import.pod=>$(INST_MAN1DIR)/bif-import.$(MAN1EXT), tmpdocs/bif-new-issue.pod=>$(INST_MAN1DIR)/bif-new-issue.$(MAN1EXT), tmpdocs/bif-sync.pod=>$(INST_MAN1DIR)/bif-sync.$(MAN1EXT), tmpdocs/bif-list-issue-status.pod=>$(INST_MAN1DIR)/bif-list-issue-status.$(MAN1EXT), tmpdocs/bif-export.pod=>$(INST_MAN1DIR)/bif-export.$(MAN1EXT), tmpdocs/bif-update.pod=>$(INST_MAN1DIR)/bif-update.$(MAN1EXT), tmpdocs/bif-reply.pod=>$(INST_MAN1DIR)/bif-reply.$(MAN1EXT), tmpdocs/bif-list-task-status.pod=>$(INST_MAN1DIR)/bif-list-task-status.$(MAN1EXT), tmpdocs/bif-new-project.pod=>$(INST_MAN1DIR)/bif-new-project.$(MAN1EXT), tmpdocs/bif-list-topics.pod=>$(INST_MAN1DIR)/bif-list-topics.$(MAN1EXT), tmpdocs/bif-show.pod=>$(INST_MAN1DIR)/bif-show.$(MAN1EXT), bin/bif=>$(INST_MAN1DIR)/bif.$(MAN1EXT), tmpdocs/bif-doc.pod=>$(INST_MAN1DIR)/bif-doc.$(MAN1EXT), tmpdocs/bif-drop.pod=>$(INST_MAN1DIR)/bif-drop.$(MAN1EXT) }
#     MIN_PERL_VERSION => q[5.006]
#     NAME => q[App::bif]
#     NO_META => q[1]
#     PREREQ_PM => { CPAN::Meta=>q[0], ExtUtils::MakeMaker=>q[6.59] }
#     TEST_REQUIRES => {  }
#     VERSION => q[0.1.0_10]
#     dist => {  }
#     realclean => { FILES=>q[MYMETA.yml] }
#     test => { TESTS=>q[t/App/*.t t/App/bif/*.t t/App/bif/list/*.t t/App/bif/new/*.t t/Bif/*.t t/Bif/DB/*.t t/sql/*.t t/sql/table/*.t] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /home/mark/.plenv/versions/5.18.1/lib/perl5/5.18.1/i686-linux/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS = -shared -O2 -L/usr/local/lib -fstack-protector
LDFLAGS =  -fstack-protector -L/usr/local/lib
LIBC = 
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 3.10-3-686-pae
RANLIB = :
SITELIBEXP = /home/mark/.plenv/versions/5.18.1/lib/perl5/site_perl/5.18.1
SITEARCHEXP = /home/mark/.plenv/versions/5.18.1/lib/perl5/site_perl/5.18.1/i686-linux
SO = so
VENDORARCHEXP = 
VENDORLIBEXP = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = App::bif
NAME_SYM = App_bif
VERSION = 0.1.0_10
VERSION_MACRO = VERSION
VERSION_SYM = 0_1_0_10
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.1.0_10
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1
MAN3EXT = 3
INSTALLDIRS = site
INSTALL_BASE = /home/mark/.plenv/libs/5.18.1@bif
DESTDIR = 
PREFIX = $(INSTALL_BASE)
INSTALLPRIVLIB = $(INSTALL_BASE)/lib/perl5
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = $(INSTALL_BASE)/lib/perl5
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = $(INSTALL_BASE)/lib/perl5
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = $(INSTALL_BASE)/lib/perl5/i686-linux
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = $(INSTALL_BASE)/lib/perl5/i686-linux
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = $(INSTALL_BASE)/lib/perl5/i686-linux
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = $(INSTALL_BASE)/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = $(INSTALL_BASE)/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = $(INSTALL_BASE)/bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = $(INSTALL_BASE)/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = $(INSTALL_BASE)/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = $(INSTALL_BASE)/bin
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = $(INSTALL_BASE)/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = $(INSTALL_BASE)/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = $(INSTALL_BASE)/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = $(INSTALL_BASE)/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = $(INSTALL_BASE)/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = $(INSTALL_BASE)/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB =
PERL_ARCHLIB = /home/mark/.plenv/versions/5.18.1/lib/perl5/5.18.1/i686-linux
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /home/mark/.plenv/versions/5.18.1/lib/perl5/5.18.1/i686-linux/CORE
PERL = /home/mark/.plenv/versions/5.18.1/bin/perl5.18.1 "-Iinc"
FULLPERL = /home/mark/.plenv/versions/5.18.1/bin/perl5.18.1 "-Iinc"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /home/mark/.plenv/versions/5.18.1/lib/perl5/5.18.1/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.66
MM_REVISION = 66600

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = App/bif
BASEEXT = bif
PARENT_NAME = App
DLBASE = $(BASEEXT)
VERSION_FROM = 
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = bin/bif \
	bin/bifsync \
	tmpdocs/bif-doc.pod \
	tmpdocs/bif-drop.pod \
	tmpdocs/bif-export.pod \
	tmpdocs/bif-import.pod \
	tmpdocs/bif-init.pod \
	tmpdocs/bif-list-hubs.pod \
	tmpdocs/bif-list-issue-status.pod \
	tmpdocs/bif-list-issues.pod \
	tmpdocs/bif-list-project-status.pod \
	tmpdocs/bif-list-projects.pod \
	tmpdocs/bif-list-task-status.pod \
	tmpdocs/bif-list-tasks.pod \
	tmpdocs/bif-list-topics.pod \
	tmpdocs/bif-log.pod \
	tmpdocs/bif-new-issue.pod \
	tmpdocs/bif-new-project.pod \
	tmpdocs/bif-new-task.pod \
	tmpdocs/bif-push.pod \
	tmpdocs/bif-register.pod \
	tmpdocs/bif-reply.pod \
	tmpdocs/bif-show.pod \
	tmpdocs/bif-sql.pod \
	tmpdocs/bif-sync.pod \
	tmpdocs/bif-update.pod \
	tmpdocs/bif-upgrade.pod
MAN3PODS = lib/App/bif.pm \
	lib/App/bif/Context.pm \
	lib/App/bif/doc.pm \
	lib/App/bif/drop.pm \
	lib/App/bif/export.pm \
	lib/App/bif/import.pm \
	lib/App/bif/init.pm \
	lib/App/bif/list/hubs.pm \
	lib/App/bif/list/issue_status.pm \
	lib/App/bif/list/issues.pm \
	lib/App/bif/list/project_status.pm \
	lib/App/bif/list/projects.pm \
	lib/App/bif/list/task_status.pm \
	lib/App/bif/list/tasks.pm \
	lib/App/bif/list/topics.pm \
	lib/App/bif/log.pm \
	lib/App/bif/new/issue.pm \
	lib/App/bif/new/project.pm \
	lib/App/bif/new/task.pm \
	lib/App/bif/push.pm \
	lib/App/bif/register.pm \
	lib/App/bif/reply.pm \
	lib/App/bif/show.pm \
	lib/App/bif/sql.pm \
	lib/App/bif/sync.pm \
	lib/App/bif/update.pm \
	lib/App/bif/upgrade.pm \
	lib/App/bifsync.pm \
	lib/Bif/DB.pm \
	lib/Bif/DB/RW.pm \
	lib/bif-doc-changelog.pod \
	lib/bif-doc-design.pod \
	lib/bif-doc-faq.pod \
	lib/bif-doc-func-new-project.pod \
	lib/bif-doc-func-update-task.pod \
	lib/bif-doc-index.pod \
	lib/bif-doc-intro.pod \
	lib/bif-doc-roadmap.pod \
	lib/bif-doc-table-projects.pod

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DFSEP)Config.pm $(PERL_INC)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/App
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/App

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/App/bif.pm \
	lib/App/bif/Context.pm \
	lib/App/bif/Version.pm \
	lib/App/bif/doc.pm \
	lib/App/bif/drop.pm \
	lib/App/bif/export.pm \
	lib/App/bif/import.pm \
	lib/App/bif/init.pm \
	lib/App/bif/list/hubs.pm \
	lib/App/bif/list/issue_status.pm \
	lib/App/bif/list/issues.pm \
	lib/App/bif/list/project_status.pm \
	lib/App/bif/list/projects.pm \
	lib/App/bif/list/task_status.pm \
	lib/App/bif/list/tasks.pm \
	lib/App/bif/list/topics.pm \
	lib/App/bif/log.pm \
	lib/App/bif/new/issue.pm \
	lib/App/bif/new/project.pm \
	lib/App/bif/new/task.pm \
	lib/App/bif/push.pm \
	lib/App/bif/register.pm \
	lib/App/bif/reply.pm \
	lib/App/bif/show.pm \
	lib/App/bif/sql.pm \
	lib/App/bif/sync.pm \
	lib/App/bif/update.pm \
	lib/App/bif/upgrade.pm \
	lib/App/bifsync.pm \
	lib/Bif/Client.pm \
	lib/Bif/DB.pm \
	lib/Bif/DB/RW.pm \
	lib/Bif/Mo.pm \
	lib/Bif/Role/Sync.pm \
	lib/Bif/Role/Sync/Project.pm \
	lib/Bif/Role/Sync/Repo.pm \
	lib/Bif/Server.pm \
	lib/bif-doc-changelog.pod \
	lib/bif-doc-design.pod \
	lib/bif-doc-faq.pod \
	lib/bif-doc-func-new-project.pod \
	lib/bif-doc-func-update-task.pod \
	lib/bif-doc-index.pod \
	lib/bif-doc-intro.pod \
	lib/bif-doc-roadmap.pod \
	lib/bif-doc-table-projects.pod

PM_TO_BLIB = lib/App/bif/export.pm \
	blib/lib/App/bif/export.pm \
	lib/App/bif/update.pm \
	blib/lib/App/bif/update.pm \
	lib/App/bif/list/task_status.pm \
	blib/lib/App/bif/list/task_status.pm \
	lib/App/bif/new/project.pm \
	blib/lib/App/bif/new/project.pm \
	lib/App/bif/push.pm \
	blib/lib/App/bif/push.pm \
	lib/App/bif/new/task.pm \
	blib/lib/App/bif/new/task.pm \
	lib/App/bif/list/project_status.pm \
	blib/lib/App/bif/list/project_status.pm \
	lib/App/bif/reply.pm \
	blib/lib/App/bif/reply.pm \
	lib/Bif/DB.pm \
	blib/lib/Bif/DB.pm \
	lib/Bif/Role/Sync.pm \
	blib/lib/Bif/Role/Sync.pm \
	lib/Bif/Role/Sync/Repo.pm \
	blib/lib/Bif/Role/Sync/Repo.pm \
	lib/App/bif/log.pm \
	blib/lib/App/bif/log.pm \
	lib/bif-doc-design.pod \
	blib/lib/bif-doc-design.pod \
	lib/App/bif/list/topics.pm \
	blib/lib/App/bif/list/topics.pm \
	lib/App/bif/upgrade.pm \
	blib/lib/App/bif/upgrade.pm \
	lib/Bif/Client.pm \
	blib/lib/Bif/Client.pm \
	lib/App/bif/list/tasks.pm \
	blib/lib/App/bif/list/tasks.pm \
	lib/bif-doc-changelog.pod \
	blib/lib/bif-doc-changelog.pod \
	lib/App/bif/list/projects.pm \
	blib/lib/App/bif/list/projects.pm \
	lib/Bif/Server.pm \
	blib/lib/Bif/Server.pm \
	lib/bif-doc-roadmap.pod \
	blib/lib/bif-doc-roadmap.pod \
	lib/App/bif/drop.pm \
	blib/lib/App/bif/drop.pm \
	lib/App/bif/show.pm \
	blib/lib/App/bif/show.pm \
	lib/App/bif/sync.pm \
	blib/lib/App/bif/sync.pm \
	lib/bif-doc-func-new-project.pod \
	blib/lib/bif-doc-func-new-project.pod \
	lib/App/bifsync.pm \
	blib/lib/App/bifsync.pm \
	lib/Bif/Role/Sync/Project.pm \
	blib/lib/Bif/Role/Sync/Project.pm \
	lib/App/bif/list/issues.pm \
	blib/lib/App/bif/list/issues.pm \
	lib/App/bif/register.pm \
	blib/lib/App/bif/register.pm \
	lib/App/bif/sql.pm \
	blib/lib/App/bif/sql.pm \
	lib/bif-doc-faq.pod \
	blib/lib/bif-doc-faq.pod \
	lib/App/bif/import.pm \
	blib/lib/App/bif/import.pm \
	lib/Bif/Mo.pm \
	blib/lib/Bif/Mo.pm \
	lib/App/bif/list/issue_status.pm \
	blib/lib/App/bif/list/issue_status.pm \
	lib/App/bif/new/issue.pm \
	blib/lib/App/bif/new/issue.pm \
	lib/bif-doc-index.pod \
	blib/lib/bif-doc-index.pod \
	lib/App/bif/list/hubs.pm \
	blib/lib/App/bif/list/hubs.pm \
	lib/bif-doc-intro.pod \
	blib/lib/bif-doc-intro.pod \
	lib/App/bif/Version.pm \
	blib/lib/App/bif/Version.pm \
	lib/App/bif/doc.pm \
	blib/lib/App/bif/doc.pm \
	lib/bif-doc-table-projects.pod \
	blib/lib/bif-doc-table-projects.pod \
	lib/App/bif/init.pm \
	blib/lib/App/bif/init.pm \
	lib/Bif/DB/RW.pm \
	blib/lib/Bif/DB/RW.pm \
	lib/App/bif.pm \
	blib/lib/App/bif.pm \
	lib/bif-doc-func-update-task.pod \
	blib/lib/bif-doc-func-update-task.pod \
	lib/App/bif/Context.pm \
	blib/lib/App/bif/Context.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 6.66
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = App-bif
DISTVNAME = App-bif-0.1.0_10


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	INSTALL_BASE="$(INSTALL_BASE)"


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all  \
	tmpdocs/bif-list-hubs.pod \
	tmpdocs/bif-list-project-status.pod \
	tmpdocs/bif-list-issues.pod \
	tmpdocs/bif-new-task.pod \
	tmpdocs/bif-list-tasks.pod \
	tmpdocs/bif-upgrade.pod \
	bin/bifsync \
	tmpdocs/bif-push.pod \
	tmpdocs/bif-register.pod \
	tmpdocs/bif-log.pod \
	tmpdocs/bif-list-projects.pod \
	tmpdocs/bif-init.pod \
	tmpdocs/bif-sql.pod \
	tmpdocs/bif-import.pod \
	tmpdocs/bif-new-issue.pod \
	tmpdocs/bif-sync.pod \
	tmpdocs/bif-list-issue-status.pod \
	tmpdocs/bif-export.pod \
	tmpdocs/bif-update.pod \
	tmpdocs/bif-reply.pod \
	tmpdocs/bif-list-task-status.pod \
	tmpdocs/bif-new-project.pod \
	tmpdocs/bif-list-topics.pod \
	tmpdocs/bif-show.pod \
	bin/bif \
	tmpdocs/bif-doc.pod \
	tmpdocs/bif-drop.pod \
	lib/Bif/DB.pm \
	lib/App/bif/reply.pm \
	lib/App/bif/export.pm \
	lib/App/bif/update.pm \
	lib/App/bif/push.pm \
	lib/App/bif/list/task_status.pm \
	lib/App/bif/new/project.pm \
	lib/App/bif/new/task.pm \
	lib/App/bif/list/project_status.pm \
	lib/App/bif/list/tasks.pm \
	lib/bif-doc-changelog.pod \
	lib/App/bif/list/projects.pm \
	lib/App/bif/log.pm \
	lib/bif-doc-design.pod \
	lib/App/bif/list/topics.pm \
	lib/App/bif/upgrade.pm \
	lib/App/bif/list/issues.pm \
	lib/App/bif/register.pm \
	lib/App/bif/sql.pm \
	lib/bif-doc-faq.pod \
	lib/bif-doc-roadmap.pod \
	lib/App/bif/drop.pm \
	lib/App/bif/show.pm \
	lib/App/bif/sync.pm \
	lib/bif-doc-func-new-project.pod \
	lib/App/bifsync.pm \
	lib/App/bif/init.pm \
	lib/Bif/DB/RW.pm \
	lib/App/bif.pm \
	lib/bif-doc-func-update-task.pod \
	lib/App/bif/Context.pm \
	lib/App/bif/import.pm \
	lib/App/bif/list/issue_status.pm \
	lib/App/bif/new/issue.pm \
	lib/bif-doc-index.pod \
	lib/App/bif/list/hubs.pm \
	lib/bif-doc-intro.pod \
	lib/App/bif/doc.pm \
	lib/bif-doc-table-projects.pod
	$(NOECHO) $(POD2MAN) --section=1 --perm_rw=$(PERM_RW) \
	  tmpdocs/bif-list-hubs.pod $(INST_MAN1DIR)/bif-list-hubs.$(MAN1EXT) \
	  tmpdocs/bif-list-project-status.pod $(INST_MAN1DIR)/bif-list-project-status.$(MAN1EXT) \
	  tmpdocs/bif-list-issues.pod $(INST_MAN1DIR)/bif-list-issues.$(MAN1EXT) \
	  tmpdocs/bif-new-task.pod $(INST_MAN1DIR)/bif-new-task.$(MAN1EXT) \
	  tmpdocs/bif-list-tasks.pod $(INST_MAN1DIR)/bif-list-tasks.$(MAN1EXT) \
	  tmpdocs/bif-upgrade.pod $(INST_MAN1DIR)/bif-upgrade.$(MAN1EXT) \
	  bin/bifsync $(INST_MAN1DIR)/bifsync.$(MAN1EXT) \
	  tmpdocs/bif-push.pod $(INST_MAN1DIR)/bif-push.$(MAN1EXT) \
	  tmpdocs/bif-register.pod $(INST_MAN1DIR)/bif-register.$(MAN1EXT) \
	  tmpdocs/bif-log.pod $(INST_MAN1DIR)/bif-log.$(MAN1EXT) \
	  tmpdocs/bif-list-projects.pod $(INST_MAN1DIR)/bif-list-projects.$(MAN1EXT) \
	  tmpdocs/bif-init.pod $(INST_MAN1DIR)/bif-init.$(MAN1EXT) \
	  tmpdocs/bif-sql.pod $(INST_MAN1DIR)/bif-sql.$(MAN1EXT) \
	  tmpdocs/bif-import.pod $(INST_MAN1DIR)/bif-import.$(MAN1EXT) \
	  tmpdocs/bif-new-issue.pod $(INST_MAN1DIR)/bif-new-issue.$(MAN1EXT) \
	  tmpdocs/bif-sync.pod $(INST_MAN1DIR)/bif-sync.$(MAN1EXT) \
	  tmpdocs/bif-list-issue-status.pod $(INST_MAN1DIR)/bif-list-issue-status.$(MAN1EXT) \
	  tmpdocs/bif-export.pod $(INST_MAN1DIR)/bif-export.$(MAN1EXT) \
	  tmpdocs/bif-update.pod $(INST_MAN1DIR)/bif-update.$(MAN1EXT) \
	  tmpdocs/bif-reply.pod $(INST_MAN1DIR)/bif-reply.$(MAN1EXT) \
	  tmpdocs/bif-list-task-status.pod $(INST_MAN1DIR)/bif-list-task-status.$(MAN1EXT) \
	  tmpdocs/bif-new-project.pod $(INST_MAN1DIR)/bif-new-project.$(MAN1EXT) \
	  tmpdocs/bif-list-topics.pod $(INST_MAN1DIR)/bif-list-topics.$(MAN1EXT) \
	  tmpdocs/bif-show.pod $(INST_MAN1DIR)/bif-show.$(MAN1EXT) \
	  bin/bif $(INST_MAN1DIR)/bif.$(MAN1EXT) \
	  tmpdocs/bif-doc.pod $(INST_MAN1DIR)/bif-doc.$(MAN1EXT) \
	  tmpdocs/bif-drop.pod $(INST_MAN1DIR)/bif-drop.$(MAN1EXT) 
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW) \
	  lib/Bif/DB.pm $(INST_MAN3DIR)/Bif::DB.$(MAN3EXT) \
	  lib/App/bif/reply.pm $(INST_MAN3DIR)/App::bif::reply.$(MAN3EXT) \
	  lib/App/bif/export.pm $(INST_MAN3DIR)/App::bif::export.$(MAN3EXT) \
	  lib/App/bif/update.pm $(INST_MAN3DIR)/App::bif::update.$(MAN3EXT) \
	  lib/App/bif/push.pm $(INST_MAN3DIR)/App::bif::push.$(MAN3EXT) \
	  lib/App/bif/list/task_status.pm $(INST_MAN3DIR)/App::bif::list::task_status.$(MAN3EXT) \
	  lib/App/bif/new/project.pm $(INST_MAN3DIR)/App::bif::new::project.$(MAN3EXT) \
	  lib/App/bif/new/task.pm $(INST_MAN3DIR)/App::bif::new::task.$(MAN3EXT) \
	  lib/App/bif/list/project_status.pm $(INST_MAN3DIR)/App::bif::list::project_status.$(MAN3EXT) \
	  lib/App/bif/list/tasks.pm $(INST_MAN3DIR)/App::bif::list::tasks.$(MAN3EXT) \
	  lib/bif-doc-changelog.pod $(INST_MAN3DIR)/bif-doc-changelog.$(MAN3EXT) \
	  lib/App/bif/list/projects.pm $(INST_MAN3DIR)/App::bif::list::projects.$(MAN3EXT) \
	  lib/App/bif/log.pm $(INST_MAN3DIR)/App::bif::log.$(MAN3EXT) \
	  lib/bif-doc-design.pod $(INST_MAN3DIR)/bif-doc-design.$(MAN3EXT) \
	  lib/App/bif/list/topics.pm $(INST_MAN3DIR)/App::bif::list::topics.$(MAN3EXT) \
	  lib/App/bif/upgrade.pm $(INST_MAN3DIR)/App::bif::upgrade.$(MAN3EXT) \
	  lib/App/bif/list/issues.pm $(INST_MAN3DIR)/App::bif::list::issues.$(MAN3EXT) \
	  lib/App/bif/register.pm $(INST_MAN3DIR)/App::bif::register.$(MAN3EXT) \
	  lib/App/bif/sql.pm $(INST_MAN3DIR)/App::bif::sql.$(MAN3EXT) \
	  lib/bif-doc-faq.pod $(INST_MAN3DIR)/bif-doc-faq.$(MAN3EXT) \
	  lib/bif-doc-roadmap.pod $(INST_MAN3DIR)/bif-doc-roadmap.$(MAN3EXT) \
	  lib/App/bif/drop.pm $(INST_MAN3DIR)/App::bif::drop.$(MAN3EXT) \
	  lib/App/bif/show.pm $(INST_MAN3DIR)/App::bif::show.$(MAN3EXT) \
	  lib/App/bif/sync.pm $(INST_MAN3DIR)/App::bif::sync.$(MAN3EXT) \
	  lib/bif-doc-func-new-project.pod $(INST_MAN3DIR)/bif-doc-func-new-project.$(MAN3EXT) \
	  lib/App/bifsync.pm $(INST_MAN3DIR)/App::bifsync.$(MAN3EXT) \
	  lib/App/bif/init.pm $(INST_MAN3DIR)/App::bif::init.$(MAN3EXT) \
	  lib/Bif/DB/RW.pm $(INST_MAN3DIR)/Bif::DB::RW.$(MAN3EXT) \
	  lib/App/bif.pm $(INST_MAN3DIR)/App::bif.$(MAN3EXT) \
	  lib/bif-doc-func-update-task.pod $(INST_MAN3DIR)/bif-doc-func-update-task.$(MAN3EXT) \
	  lib/App/bif/Context.pm $(INST_MAN3DIR)/App::bif::Context.$(MAN3EXT) \
	  lib/App/bif/import.pm $(INST_MAN3DIR)/App::bif::import.$(MAN3EXT) \
	  lib/App/bif/list/issue_status.pm $(INST_MAN3DIR)/App::bif::list::issue_status.$(MAN3EXT) \
	  lib/App/bif/new/issue.pm $(INST_MAN3DIR)/App::bif::new::issue.$(MAN3EXT) \
	  lib/bif-doc-index.pod $(INST_MAN3DIR)/bif-doc-index.$(MAN3EXT) \
	  lib/App/bif/list/hubs.pm $(INST_MAN3DIR)/App::bif::list::hubs.$(MAN3EXT) \
	  lib/bif-doc-intro.pod $(INST_MAN3DIR)/bif-doc-intro.$(MAN3EXT) \
	  lib/App/bif/doc.pm $(INST_MAN3DIR)/App::bif::doc.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW) \
	  lib/bif-doc-table-projects.pod $(INST_MAN3DIR)/bif-doc-table-projects.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

EXE_FILES = bin/bif bin/bifsync

pure_all :: $(INST_SCRIPT)/bifsync $(INST_SCRIPT)/bif
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) \
	  $(INST_SCRIPT)/bifsync $(INST_SCRIPT)/bif 

$(INST_SCRIPT)/bifsync : bin/bifsync $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/bifsync
	$(CP) bin/bifsync $(INST_SCRIPT)/bifsync
	$(FIXIN) $(INST_SCRIPT)/bifsync
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/bifsync

$(INST_SCRIPT)/bif : bin/bif $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/bif
	$(CP) bin/bif $(INST_SCRIPT)/bif
	$(FIXIN) $(INST_SCRIPT)/bif
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/bif



# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  core.*perl.*.? mon.out \
	  perl.exe $(BASEEXT).exp \
	  lib$(BASEEXT).def $(BASEEXT).def \
	  pm_to_blib MYMETA.yml \
	  perl$(EXE_EXT) $(BASEEXT).bso \
	  perl core.[0-9][0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9] $(INST_ARCHAUTODIR)/extralibs.ld \
	  $(INST_ARCHAUTODIR)/extralibs.all *perl.core \
	  pm_to_blib.ts so_locations \
	  $(BASEEXT).x MYMETA.json \
	  perlmain.c core \
	  blibdirs.ts core.[0-9][0-9][0-9][0-9] \
	  *$(LIB_EXT) core.[0-9][0-9] \
	  $(BOOTSTRAP) tmon.out \
	  $(MAKE_APERL_FILE) core.[0-9] \
	  *$(OBJ_EXT) 
	- $(RM_RF) \
	  blib 
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge ::  clean realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) 
	- $(RM_RF) \
	  MYMETA.yml $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile :
	$(NOECHO) $(NOOP)


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old 



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir  
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add META.yml to MANIFEST: $$$${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add META.json to MANIFEST: $$$${'\''@'\''}\n"' --



# --- MakeMaker distsignature section:
distsignature : create_distdir
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) } ' \
	  -e '    or print "Could not add SIGNATURE to MANIFEST: $$$${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSITESCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLVENDORSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_vendor_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /home/mark/.plenv/versions/5.18.1/bin/perl5.18.1

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/App/*.t t/App/bif/*.t t/App/bif/list/*.t t/App/bif/new/*.t t/Bif/*.t t/Bif/DB/*.t t/sql/*.t t/sql/table/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE) subdirs-test

subdirs-test ::
	$(NOECHO) $(NOOP)


test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), 'inc', '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-Iinc" "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

test_ : test_dynamic

test_static :: test_dynamic
testdb_static :: testdb_dynamic


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="$(DISTNAME)" VERSION="$(VERSION)">' > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>Distributed Project Management Tool</ABSTRACT>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Mark Lawrence &lt;nomad@null.net&gt;</AUTHOR>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <PERLCORE VERSION="5,006,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="i686-linux-5.18" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/App/bif/export.pm blib/lib/App/bif/export.pm \
	  lib/App/bif/update.pm blib/lib/App/bif/update.pm \
	  lib/App/bif/list/task_status.pm blib/lib/App/bif/list/task_status.pm \
	  lib/App/bif/new/project.pm blib/lib/App/bif/new/project.pm \
	  lib/App/bif/push.pm blib/lib/App/bif/push.pm \
	  lib/App/bif/new/task.pm blib/lib/App/bif/new/task.pm \
	  lib/App/bif/list/project_status.pm blib/lib/App/bif/list/project_status.pm \
	  lib/App/bif/reply.pm blib/lib/App/bif/reply.pm \
	  lib/Bif/DB.pm blib/lib/Bif/DB.pm \
	  lib/Bif/Role/Sync.pm blib/lib/Bif/Role/Sync.pm \
	  lib/Bif/Role/Sync/Repo.pm blib/lib/Bif/Role/Sync/Repo.pm \
	  lib/App/bif/log.pm blib/lib/App/bif/log.pm \
	  lib/bif-doc-design.pod blib/lib/bif-doc-design.pod \
	  lib/App/bif/list/topics.pm blib/lib/App/bif/list/topics.pm \
	  lib/App/bif/upgrade.pm blib/lib/App/bif/upgrade.pm \
	  lib/Bif/Client.pm blib/lib/Bif/Client.pm \
	  lib/App/bif/list/tasks.pm blib/lib/App/bif/list/tasks.pm \
	  lib/bif-doc-changelog.pod blib/lib/bif-doc-changelog.pod \
	  lib/App/bif/list/projects.pm blib/lib/App/bif/list/projects.pm \
	  lib/Bif/Server.pm blib/lib/Bif/Server.pm \
	  lib/bif-doc-roadmap.pod blib/lib/bif-doc-roadmap.pod \
	  lib/App/bif/drop.pm blib/lib/App/bif/drop.pm \
	  lib/App/bif/show.pm blib/lib/App/bif/show.pm \
	  lib/App/bif/sync.pm blib/lib/App/bif/sync.pm \
	  lib/bif-doc-func-new-project.pod blib/lib/bif-doc-func-new-project.pod \
	  lib/App/bifsync.pm blib/lib/App/bifsync.pm \
	  lib/Bif/Role/Sync/Project.pm blib/lib/Bif/Role/Sync/Project.pm \
	  lib/App/bif/list/issues.pm blib/lib/App/bif/list/issues.pm \
	  lib/App/bif/register.pm blib/lib/App/bif/register.pm \
	  lib/App/bif/sql.pm blib/lib/App/bif/sql.pm \
	  lib/bif-doc-faq.pod blib/lib/bif-doc-faq.pod \
	  lib/App/bif/import.pm blib/lib/App/bif/import.pm \
	  lib/Bif/Mo.pm blib/lib/Bif/Mo.pm \
	  lib/App/bif/list/issue_status.pm blib/lib/App/bif/list/issue_status.pm \
	  lib/App/bif/new/issue.pm blib/lib/App/bif/new/issue.pm \
	  lib/bif-doc-index.pod blib/lib/bif-doc-index.pod \
	  lib/App/bif/list/hubs.pm blib/lib/App/bif/list/hubs.pm \
	  lib/bif-doc-intro.pod blib/lib/bif-doc-intro.pod \
	  lib/App/bif/Version.pm blib/lib/App/bif/Version.pm \
	  lib/App/bif/doc.pm blib/lib/App/bif/doc.pm \
	  lib/bif-doc-table-projects.pod blib/lib/bif-doc-table-projects.pod \
	  lib/App/bif/init.pm blib/lib/App/bif/init.pm \
	  lib/Bif/DB/RW.pm blib/lib/Bif/DB/RW.pm \
	  lib/App/bif.pm blib/lib/App/bif.pm \
	  lib/bif-doc-func-update-task.pod blib/lib/bif-doc-func-update-task.pod \
	  lib/App/bif/Context.pm blib/lib/App/bif/Context.pm 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
# Postamble by Module::Install 1.08
config ::
	$(NOECHO) $(MKPATH) "$(INST_LIB)/auto/share/dist/$(DISTNAME)/."
	$(NOECHO) $(CHMOD) $(PERM_DIR) "$(INST_LIB)/auto/share/dist/$(DISTNAME)/."
	$(NOECHO) $(MKPATH) "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite"
	$(NOECHO) $(CHMOD) $(PERM_DIR) "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite"
	$(NOECHO) $(CP) "share/SQLite/48-table-projects-tree.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/48-table-projects-tree.sql"
	$(NOECHO) $(CP) "share/SQLite/04-func-import-project-status-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/04-func-import-project-status-update.sql"
	$(NOECHO) $(CP) "share/SQLite/07-func-import-project.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/07-func-import-project.sql"
	$(NOECHO) $(CP) "share/SQLite/55-table-repo-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/55-table-repo-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/00-func-import-issue-status-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/00-func-import-issue-status-update.sql"
	$(NOECHO) $(CP) "share/SQLite/53-table-repo-related-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/53-table-repo-related-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/35-table-issue-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/35-table-issue-status.sql"
	$(NOECHO) $(CP) "share/SQLite/42-table-project-status-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/42-table-project-status-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/16-func-import-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/16-func-import-update.sql"
	$(NOECHO) $(CP) "share/SQLite/05-func-import-project-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/05-func-import-project-status.sql"
	$(NOECHO) $(CP) "share/SQLite/66-table-updates-tree.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/66-table-updates-tree.sql"
	$(NOECHO) $(CP) "share/SQLite/39-table-project-issues-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/39-table-project-issues-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/19-func-new-issue.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/19-func-new-issue.sql"
	$(NOECHO) $(CP) "share/SQLite/24-func-new-task-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/24-func-new-task-status.sql"
	$(NOECHO) $(CP) "share/SQLite/38-table-issues.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/38-table-issues.sql"
	$(NOECHO) $(CP) "share/SQLite/56-table-repos-merkle.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/56-table-repos-merkle.sql"
	$(NOECHO) $(CP) "share/SQLite/61-table-task-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/61-table-task-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/58-table-task-status-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/58-table-task-status-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/46-table-projects-merkle.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/46-table-projects-merkle.sql"
	$(NOECHO) $(CP) "share/SQLite/67-table-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/67-table-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/13-func-import-task-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/13-func-import-task-status.sql"
	$(NOECHO) $(CP) "share/SQLite/64-table-topics.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/64-table-topics.sql"
	$(NOECHO) $(CP) "share/SQLite/41-table-project-related-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/41-table-project-related-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/63-table-tasks.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/63-table-tasks.sql"
	$(NOECHO) $(CP) "share/SQLite/09-func-import-repo-location.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/09-func-import-repo-location.sql"
	$(NOECHO) $(CP) "share/SQLite/65-table-updates-pending.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/65-table-updates-pending.sql"
	$(NOECHO) $(CP) "share/SQLite/10-func-import-repo-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/10-func-import-repo-update.sql"
	$(NOECHO) $(CP) "share/SQLite/33-table-issue-status-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/33-table-issue-status-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/22-func-new-repo-location.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/22-func-new-repo-location.sql"
	$(NOECHO) $(CP) "share/SQLite/17-func-merge-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/17-func-merge-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/50-table-repo-location-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/50-table-repo-location-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/26-func-update-issue-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/26-func-update-issue-status.sql"
	$(NOECHO) $(CP) "share/SQLite/40-table-project-issues.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/40-table-project-issues.sql"
	$(NOECHO) $(CP) "share/SQLite/21-func-new-project.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/21-func-new-project.sql"
	$(NOECHO) $(CP) "share/SQLite/01-func-import-issue-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/01-func-import-issue-status.sql"
	$(NOECHO) $(CP) "share/SQLite/60-table-task-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/60-table-task-status.sql"
	$(NOECHO) $(CP) "share/SQLite/49-table-projects.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/49-table-projects.sql"
	$(NOECHO) $(CP) "share/SQLite/12-func-import-task-status-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/12-func-import-task-status-update.sql"
	$(NOECHO) $(CP) "share/SQLite/25-func-new-task.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/25-func-new-task.sql"
	$(NOECHO) $(CP) "share/SQLite/08-func-import-repo-location-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/08-func-import-repo-location-update.sql"
	$(NOECHO) $(CP) "share/SQLite/31-func-update-task.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/31-func-update-task.sql"
	$(NOECHO) $(CP) "share/SQLite/03-func-import-issue.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/03-func-import-issue.sql"
	$(NOECHO) $(CP) "share/SQLite/29-func-update-project.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/29-func-update-project.sql"
	$(NOECHO) $(CP) "share/SQLite/37-table-issues-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/37-table-issues-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/44-table-project-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/44-table-project-status.sql"
	$(NOECHO) $(CP) "share/SQLite/36-table-issue-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/36-table-issue-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/32-table-default-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/32-table-default-status.sql"
	$(NOECHO) $(CP) "share/SQLite/28-func-update-project-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/28-func-update-project-status.sql"
	$(NOECHO) $(CP) "share/SQLite/06-func-import-project-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/06-func-import-project-update.sql"
	$(NOECHO) $(CP) "share/SQLite/47-table-projects-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/47-table-projects-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/62-table-tasks-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/62-table-tasks-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/52-table-repo-locations.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/52-table-repo-locations.sql"
	$(NOECHO) $(CP) "share/SQLite/23-func-new-repo.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/23-func-new-repo.sql"
	$(NOECHO) $(CP) "share/SQLite/27-func-update-issue.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/27-func-update-issue.sql"
	$(NOECHO) $(CP) "share/SQLite/57-table-repos.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/57-table-repos.sql"
	$(NOECHO) $(CP) "share/SQLite/59-table-task-status-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/59-table-task-status-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/30-func-update-task-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/30-func-update-task-status.sql"
	$(NOECHO) $(CP) "share/SQLite/43-table-project-status-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/43-table-project-status-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/45-table-project-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/45-table-project-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/15-func-import-task.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/15-func-import-task.sql"
	$(NOECHO) $(CP) "share/SQLite/14-func-import-task-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/14-func-import-task-update.sql"
	$(NOECHO) $(CP) "share/SQLite/11-func-import-repo.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/11-func-import-repo.sql"
	$(NOECHO) $(CP) "share/SQLite/51-table-repo-locations-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/51-table-repo-locations-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/02-func-import-issue-update.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/02-func-import-issue-update.sql"
	$(NOECHO) $(CP) "share/SQLite/54-table-repo-tomerge.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/54-table-repo-tomerge.sql"
	$(NOECHO) $(CP) "share/SQLite/18-func-new-issue-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/18-func-new-issue-status.sql"
	$(NOECHO) $(CP) "share/SQLite/34-table-issue-status-updates.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/34-table-issue-status-updates.sql"
	$(NOECHO) $(CP) "share/SQLite/20-func-new-project-status.sql" "$(INST_LIB)/auto/share/dist/$(DISTNAME)/SQLite/20-func-new-project-status.sql"


