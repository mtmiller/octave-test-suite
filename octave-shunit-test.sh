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
  assertEmptyFile 'unexpected output to stderr' $stderr
  assertNotEmptyFile 'expected usage listing to stdout' $stdout
  run $octave_cmd --version
  assertTrueExitStatus
  assertEmptyFile 'unexpected output to stderr' $stderr
  assertNotEmptyFile 'expected usage listing to stdout' $stdout
}

test_octave_option_version ()
{
  run $octave_cmd --version
  assertTrueExitStatus
  assertEmptyFile 'unexpected output to stderr' $stderr
  head -n1 "$stdout" | grep -E -q -x 'GNU Octave, version [0-9.]+(\+|-rc[0-9])?'
  assertTrue "unexpected output on first line of $OCTAVE --version" $?
}

test_octave_eval_with_semicolon ()
{
  run $octave_cmd --eval 'true;'
  assertTrueExitStatus
  assertEmptyFile 'unexpected output to stderr' $stderr
  assertEmptyFile 'unexpected output to stdout' $stdout
}

test_octave_eval_without_semicolon ()
{
  run $octave_cmd --eval 'true'
  assertTrueExitStatus
  assertEmptyFile 'unexpected output to stderr' $stderr
  assertEquals 'ans = 1' "$(cat $stdout)"
}

oneTimeSetUp ()
{
  output_dir="${SHUNIT_TMPDIR}/output"
  stdout="${output_dir}/stdout"
  stderr="${output_dir}/stderr"
  mkdir -p ${output_dir}
}

. $SHUNIT
