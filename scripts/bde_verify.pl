#!/usr/bin/env perl
# bdeverify_win                                                      -*-perl-*-

# Bde_verify is a static analysis tool that verifies that source code adheres
# to the BDE coding standards.  Many of the checks are specific to Bloomberg LP
# and this wrapper script contains default options for the Bloomberg LP
# environment.

use strict;
use warnings;
use Getopt::Long;

my $home     = "w:\\bde_verify";
my $bb       = "c:\\BPCDEVTOOLS\\bde\\2.19.0";
my $config   = "$home\\bde_verify.cfg";
my $exe      = "c:\\bde-verify\\Release\\BDE_Verify.exe";
my $debug    = "";
my $verbose  = "";
my $help     = "";
my $definc   = 1;
my $defdef   = 1;
my @incs;
my @defs;
my @wflags;
my @lflags = (
    "cxx-exceptions",
    "diagnostics-show-name",
    "diagnostics-show-option",
    "ms-compatibility",
    "ms-extensions",
    "msc-version=1800",
    #"delayed-template-parsing",
);
my $dummy;
my @dummy;
my $std;
my @std;
my $tlonly;

sub usage()
{
    print "
    usage: $0 [options] [additional compiler options] file.cpp ...
        -I{directory}
        -D{macro}
        -W{warning}
        -f{flag}
        --config=config_file     [$config]  
        --bb=dir                 [$bb]
        --exe=BDE_Verify.exe     [$exe]
        --[no]definc             [$definc]
        --[no]defdef             [$defdef]
        --toplevel
        --std=type
        --debug
        --verbose
        --help

";
    print "Invoked as\n", join(" \\\n", @ARGV), "\n";
    exit(1);
}

@ARGV = map { /^(-+[DIOWf])(.+)/ ? ($1, $2) : $_ } @ARGV;

GetOptions(
    'bb=s'       => \$bb,
    'config=s'   => \$config,
    'debug'      => \$debug,
    'help|?'     => \$help,
    'exe=s'      => \$exe,
    'verbose'    => \$verbose,
    'definc!'    => \$definc,
    'defdef!'    => \$defdef,
    "I=s"        => \@incs,
    "D=s"        => \@defs,
    "W=s"        => \@wflags,
    "f=s"        => \@lflags,
    "std=s"      => \$std,
    "toplevel"   => \$tlonly,
    "m32|m64|pipe|pthread|MMD|g|c" => \$dummy,
    "O|MF|o=s"   => \@dummy,
) and !$help and $#ARGV >= 0 or usage();

my @config = ("-plugin-arg-bde_verify", "config=$config") if $config ne "";
my @debug  = ("-plugin-arg-bde_verify", "debug-on")       if $debug;
my @tlo    = ("-plugin-arg-bde_verify", "toplevel-only-on") if $tlonly;

@lflags = map { "-f$_" if $_ ne "no-strict-aliasing" } @lflags;
@wflags = map { "-W$_" } @wflags;

push(@defs, (
    "BDE_BUILD_TARGET_DBG",
    "BDE_BUILD_TARGET_EXC",
    "BDE_BUILD_TARGET_MT",
    "_CRT_SECURE_NO_DEPRECATE",
    "_SCL_SECURE_NO_DEPRECATE",
    "NOMINMAX",
    "NOGDI",
    "_WIN32_WINNT=0x0500",
    "WINVER=0x0500",
    "DEBUG",
    "_MT",
    "BSLS_IDENT_OFF",
    "BSL_OVERRIDES_STD",
    "BDE_OMIT_INTERNAL_DEPRECATED",
    "_STLP_USE_STATIC_LIB",
    "_STLP_HAS_NATIVE_FLOAT_ABS",
    "BDE_DCL=",
    "BSL_DCL=",
)) if $defdef;
@defs = map { "-D$_" } @defs;

for (@ARGV) {
    if (m{^(.*)[/\\].*$}) {
        push(@incs, $1) unless grep($1, @incs);
    } else {
        push(@incs, ".") unless grep($_ eq ".", @incs);
    }
}
push(@incs, (
    "$bb/include",
    "$bb/include/stlport",
)) if $definc;
push(@incs, (
    "$bb\\include",
    "$bb\\include\\bsl+stdhdrs",
));

my $inc = $ENV{INCLUDE};
if ($inc ne '') {
    push(@incs, split(/;/, $ENV{INCLUDE}));
} else {
    push(@incs, "c:\\Program Files (x86)" .
                  "\\Microsoft Visual Studio 11.0" .
                  "\\VC" .
                  "\\include");
}
@incs = map { ("-I", $_, "-cxx-isystem", $_ ) } @incs;

push(@std, "-std=$std") if $std;

my @command = (
    "$exe",
    "-plugin",
    "bde_verify",
    @std,
    @debug,
    @config,
    @tlo,
    @defs,
    @incs,
    @lflags,
    @wflags,
    @ARGV,
);

print join(' ', @command), "\n" if $verbose;

exec @command;

## ----------------------------------------------------------------------------
## Copyright (C) 2014 Bloomberg Finance L.P.
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to
## deal in the Software without restriction, including without limitation the
## rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
## sell copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
## FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
## IN THE SOFTWARE.
## ----------------------------- END-OF-FILE ----------------------------------