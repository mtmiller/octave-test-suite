#!/bin/sh
#
# Test the Octave interpreter from the command line
#
# Copyright (C) 2018 Mike Miller
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# The default Octave interpreter
: ${OCTAVE=octave}

# Use the default shunit2 if installed on $PATH
: ${SHUNIT=shunit2}

# The Octave command line to use for running tests
octave_cmd="$OCTAVE --no-history --no-init-file --silent"

run ()
{
  "$@" > "$stdout" 2> "$stderr"
  status=$?
}

run_with_stdin ()
{
  "$@" < "$stdin" > "$stdout" 2> "$stderr"
  status=$?
}

write_script_file ()
{
  contents=$1
  echo "$contents" > $script
}

assertEmptyFile ()
{
  msg=
  if [ $# -eq 2 ]; then
    msg=$1
    shift
  fi
  file=$1
  contents=$(cat "$file")
  assertNull "$msg" "$contents"
}

assertEmptyStderr ()
{
  assertEmptyFile 'unexpected output on stderr' $stderr
}

assertEmptyStdout ()
{
  assertEmptyFile 'unexpected output on stdout' $stdout
}

assertNotEmptyFile ()
{
  msg=
  if [ $# -eq 2 ]; then
    msg=$1
    shift
  fi
  file=$1
  contents=$(cat "$file")
  assertNotNull "$msg" "$contents"
}

assertTrueExitStatus ()
{
  assertTrue "expecting zero (true) exit status, got $status" $status
}

assertFalseExitStatus ()
{
  assertFalse "expecting non-zero (false) exit status, got $status" $status
}

test_octave_exists ()
{
  run $octave_cmd --help
  assertTrueExitStatus
  assertEmptyStderr
  assertNotEmptyFile 'expected usage listing on stdout' $stdout
  run $octave_cmd --version
  assertTrueExitStatus
  assertEmptyStderr
  assertNotEmptyFile 'expected version information on stdout' $stdout
}

test_octave_option_version ()
{
  run $octave_cmd --version
  assertTrueExitStatus
  assertEmptyStderr
  head -n1 "$stdout" | grep -E -q -x 'GNU Octave, version [0-9.]+(\+|-rc[0-9])?'
  assertTrue "unexpected output on first line of $OCTAVE --version" $?
}

test_octave_option_eval ()
{
  run $octave_cmd --eval '1'
  assertTrueExitStatus
  assertEmptyStderr
  assertNotEmptyFile 'expected normal Octave output on stdout' $stdout
}

test_octave_option_eval_with_script_file ()
{
  write_script_file '2'
  run $octave_cmd --eval '1' $script
  assertFalseExitStatus
  assertEmptyStdout
  grep -E -q -x '^(error|warning): .*eval.*file.*mutually exclusive.*' $stderr
  assertTrue "unexpected error message on $OCTAVE --eval CODE FILE" $?
}

test_octave_option_eval_with_stdin ()
{
  echo 'false' > $stdin
  run_with_stdin $octave_cmd --eval 'true'
  assertTrueExitStatus
  assertEmptyStderr
  assertEquals 'ans = 1' "$(cat $stdout)"
}

test_octave_eval_with_semicolon ()
{
  run $octave_cmd --eval 'true;'
  assertTrueExitStatus
  assertEmptyStderr
  assertEmptyStdout
}

test_octave_eval_without_semicolon ()
{
  run $octave_cmd --eval 'true'
  assertTrueExitStatus
  assertEmptyStderr
  assertEquals 'ans = 1' "$(cat $stdout)"
}

test_octave_trivial_script ()
{
  write_script_file '0'
  run $octave_cmd $script
  assertTrueExitStatus
  assertEmptyStderr
  assertEquals 'ans = 0' "$(cat $stdout)"
}

test_octave_error_function_exit_status ()
{
  write_script_file 'error ("this command has failed");'
  run $octave_cmd $script
  assertFalseExitStatus
  assertEmptyStdout
  head -n1 $stderr | grep -E -q -x 'error: this command has failed'
  assertTrue "unexpected error message on $OCTAVE FILE calling the error function" $?
}

test_octave_exit_function_exit_status_1 ()
{
  write_script_file 'exit (0);'
  run $octave_cmd $script
  assertEmptyStderr
  assertEmptyStdout
  assertEquals 0 $status
}

test_octave_exit_function_exit_status_2 ()
{
  write_script_file 'exit (1);'
  run $octave_cmd $script
  assertEmptyStderr
  assertEmptyStdout
  assertEquals 1 $status
}

test_octave_exit_function_exit_status_3 ()
{
  write_script_file 'exit (42);'
  run $octave_cmd $script
  assertEmptyStderr
  assertEmptyStdout
  assertEquals 42 $status
}

oneTimeSetUp ()
{
  output_dir="${SHUNIT_TMPDIR}/output"
  stdin="${output_dir}/stdin"
  stdout="${output_dir}/stdout"
  stderr="${output_dir}/stderr"
  mkdir -p ${output_dir}
  > "$stdin"
  script="${SHUNIT_TMPDIR}/testscript.m"
}

. $SHUNIT
