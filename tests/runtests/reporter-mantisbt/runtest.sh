#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of mantisbt-reporter
#   Description: Verify reporter-mantisbt functionality
#   Author: Matej Habrnal <mhabrnal@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2011 Red Hat, Inc. All rights reserved.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 3 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

. /usr/share/beakerlib/beakerlib.sh
. ../aux/lib.sh

TEST="reporter-mantisbt"
PACKAGE="abrt"

QUERIES_DIR="queries"  # TODO will be '.'

rlJournalStart
    rlPhaseStartSetup
        TmpDir=$(mktemp -d)
        cp -R queries/* $TmpDir
        cp -R problem_dir $TmpDir # TODO
        cp pyserve mantisbt.conf $TmpDir
        cp attachment_file $TmpDir
        pushd $TmpDir
    rlPhaseEnd

    rlPhaseStartTest "sanity"
        rlRun "reporter-mantisbt --help &> null"
        rlRun "reporter-mantisbt --help 2>&1 | grep 'Usage:'"
    rlPhaseEnd

    # search by duphash
    # API new method for search in the MantisBT by duphas
    rlPhaseStartTest "search by duphash"
         ./pyserve \
                $QUERIES_DIR/loggin_correct \
                $QUERIES_DIR/search_two_issues \
                &> server_log &
        sleep 1
        rlRun "reporter-mantisbt -vvv -h bbfe66399cc9cb8ba647414e33c5d1e4ad82b511 \
                -c mantisbt.conf -d problem_dir &> client_log"
        kill %1
# add server grep (method search, duphash, ...)

        rlAssertGrep "<SOAP-ENV:Body><ns1:mc_loginResponse>" client_create
        rlAssertGrep "<id xsi:type=\"xsd:integer\">2</id>" client_create
        rlAssertGrep "name xsi:type=\"xsd:string\">test</name>" client_create

        rlAssertGrep "Looking for similar problems in mantisbt" client_create
        rlAssertGrep "<item xsi:type=\"ns1:IssueData\"><id xsi:type=\"xsd:integer\">10</id>" client_create
        rlAssertGrep "10" client_create

        rm -f problem_dir/reported_to
    rlPhaseEnd

    # attach files to issue (parameter t, issue ID is specified)
    # API mc_issue_attachment_add
    rlPhaseStartTest "attach files to issue (issue ID is specified)"
         ./pyserve \
                $QUERIES_DIR/loggin_correct \
                $QUERIES_DIR/attachment \
                &> server_log &
        sleep 1
        rlRun "reporter-mantisbt -vvv -c mantisbt.conf -d problem_dir -t1 attachment_file &> client_log"
        kill %1

        # request
        rlAssertGrep "<ns3:mc_issue_attachment_add>" server_log
        rlAssertGrep "<issue_id xsi:type=\"ns2:integer\">1</issue_id>" server_log
        rlAssertGrep "<name xsi:type=\"ns2:string\">attachment_file</name>" server_log

        # response
        rlAssertGrep "<SOAP-ENV:Body><ns1:mc_loginResponse>" client_create
        rlAssertGrep "<id xsi:type=\"xsd:integer\">2</id>" client_create
        rlAssertGrep "name xsi:type=\"xsd:string\">test</name>" client_create

        rlAssertGrep "Attaching file 'attachment_file' to bug 1" client_create
        rlAssertGrep "<return xsi:type=\"xsd:integer\">4</return></ns1:mc_issue_attachment_addResponse>" client_create

        rm -f problem_dir/reported_to
    rlPhaseEnd

    # attach files to issue (parameter t, issue ID is not specified)
    # API mc_issue_attachment_add
    rlPhaseStartTest "attach files to issue (issue ID is not specified)"
         ./pyserve \
                $QUERIES_DIR/loggin_correct \
                $QUERIES_DIR/attachment \
                &> server_log &

#????? depends on reported_to format for the mantis
        rlRun "echo \"MantisBT: URL=localhost/mantisbt/view.php?id=1\" > problem_dir/reported_to"

        sleep 1
        rlRun "reporter-mantisbt -vvv -c mantisbt.conf -d problem_dir -t attachment_file &> client_log"
        kill %1

        # request
        rlAssertGrep "<ns3:mc_issue_attachment_add>" server_log
        rlAssertGrep "<issue_id xsi:type=\"ns2:integer\">1</issue_id>" server_log
        rlAssertGrep "<name xsi:type=\"ns2:string\">attachment_file</name>" server_log

        # response
        rlAssertGrep "<SOAP-ENV:Body><ns1:mc_loginResponse>" client_create
        rlAssertGrep "<id xsi:type=\"xsd:integer\">2</id>" client_create
        rlAssertGrep "name xsi:type=\"xsd:string\">test</name>" client_create

        rlAssertGrep "Attaching file 'attachment_file' to bug 1" client_create
        rlAssertGrep "<return xsi:type=\"xsd:integer\">4</return></ns1:mc_issue_attachment_addResponse>" client_create

        rm -f problem_dir/reported_to
    rlPhaseEnd

# TODO + adding external URL to the issue (depends on the content of 'reported_to')
# URLs have to be added during adding issue (in the case using 'Addition information' field)

# force reporting even if this problem is already reported (parameter f)
# API some search method (1x or 2x depends on potential duplicates)
# API mc_issue_add
    rlPhaseStartTest "force reporting"
        # TODO
    rlPhaseEnd

# create an issue (problem is already reported)
# API some search method (1x or 2x depends on potential duplicate issues)
# mc_issue_add
    rlPhaseStartTest "create an issue (problem is already reported to the mantisBT)"
        # TODO
    rlPhaseEnd

# create a new issue (only potential duplicate issues exist)
# API some search method (2x)
# mc_issue_add
    rlPhaseStartTest "create an issue (only potential duplicate issues exist)"
         ./pyserve \
                $QUERIES_DIR/loggin_correct \
                $QUERIES_DIR/search_two_issues \
                $QUERIES_DIR/search_no_issues \
                $QUERIES_DIR/create \
                &> server_log &

        sleep 1
        rlRun "reporter-mantisbt -vvv -c mantisbt.conf -d problem_dir &> client_log"
        kill %1

        rlAssertGrep "<SOAP-ENV:Body><ns1:mc_loginResponse>" client_create
        rlAssertGrep "<id xsi:type=\"xsd:integer\">2</id>" client_create
        rlAssertGrep "name xsi:type=\"xsd:string\">test</name>" client_create

        rlAssertGrep "Checking for duplicates" client_create
        rlAssertGrep "Bugzilla has 2 reports with duphash 'bbfe66399cc9cb8ba647414e33c5d1e4ad82b511' including cross-version ones" client_create
        rlAssertGrep "<return SOAP-ENC:arrayType=\"ns1:IssueData[2]\" xsi:type=\"SOAP-ENC:Array\">" client_create
        rlAssertGrep "Bugzilla has 0 reports with duphash 'bbfe66399cc9cb8ba647414e33c5d1e4ad82b511'" client_create
        rlAssertGrep "<return SOAP-ENC:arrayType=\"ns1:IssueData[0]\" xsi:type=\"SOAP-ENC:Array\">" client_create


        rlAssertGrep "Creating a new bug" client_create
        rlAssertGrep "<ns3:mc_issue_add>" server_log
        rlAssertGrep "<ns1:mc_issue_addResponse><return xsi:type=\"xsd:integer\">7</return>" client_create

        rm -f problem_dir/reported_to
    rlPhaseEnd

# create a new issue (no potential duplicate issues exist)
# API some search method
# mc_issue_add
    rlPhaseStartTest "create an issue (no potential duplicate issues exist)"
         ./pyserve \
                $QUERIES_DIR/loggin_correct \
                $QUERIES_DIR/search_no_issues \
                $QUERIES_DIR/create \
                &> server_log &

        sleep 1
        rlRun "reporter-mantisbt -vvv -c mantisbt.conf -d problem_dir &> client_log"
        kill %1

        # request
## TODO add search request
        rlAssertGrep "<issue_id xsi:type=\"ns2:integer\">1</issue_id>" server_log
        rlAssertGrep "<name xsi:type=\"ns2:string\">attachment_file</name>" server_log

        # response
        rlAssertGrep "<SOAP-ENV:Body><ns1:mc_loginResponse>" client_create
        rlAssertGrep "<id xsi:type=\"xsd:integer\">2</id>" client_create
        rlAssertGrep "name xsi:type=\"xsd:string\">test</name>" client_create

        rlAssertGrep "Checking for duplicates" client_create
        rlAssertGrep "Bugzilla has 0 reports with duphash 'bbfe66399cc9cb8ba647414e33c5d1e4ad82b511' including cross-version ones" client_create
        rlAssertGrep "<return SOAP-ENC:arrayType=\"ns1:IssueData[0]\" xsi:type=\"SOAP-ENC:Array\"></return>" client_create

        rlAssertGrep "Creating a new bug" client_create
        rlAssertGrep "<ns3:mc_issue_add>" server_log
        rlAssertGrep "<ns1:mc_issue_addResponse><return xsi:type=\"xsd:integer\">7</return>" client_create

        rm -f problem_dir/reported_to
    rlPhaseEnd

# duplicate issue exist (comment not exist)
# API some search method (2x)
    rlPhaseStartTest "duplicate issue exist (comment not exist)"
         ./pyserve \
                $QUERIES_DIR/loggin_correct \
                $QUERIES_DIR/search_two_issues \
                $QUERIES_DIR/search_two_issues \
                &> server_log &

        rlRun "rm -f problem_dir/comment"

        sleep 1
        rlRun "reporter-mantisbt -vvv -c mantisbt.conf -d problem_dir &> client_log"
        kill %1

# TODO request

        # response
        rlAssertGrep "<SOAP-ENV:Body><ns1:mc_loginResponse>" client_create
        rlAssertGrep "<id xsi:type=\"xsd:integer\">2</id>" client_create
        rlAssertGrep "name xsi:type=\"xsd:string\">test</name>" client_create

        rlAssertGrep "Checking for duplicates" client_create
        rlAssertGrep "Bugzilla has 2 reports with duphash 'bbfe66399cc9cb8ba647414e33c5d1e4ad82b511' including cross-version ones" client_create
        rlAssertGrep "<return SOAP-ENC:arrayType=\"ns1:IssueData[2]\" xsi:type=\"SOAP-ENC:Array\">" client_create
        rlAssertGrep "Bugzilla has 2 reports with duphash 'bbfe66399cc9cb8ba647414e33c5d1e4ad82b511'" client_create
        rlAssertNotGrep "<return SOAP-ENC:arrayType=\"ns1:IssueData[0]\" xsi:type=\"SOAP-ENC:Array\">" client_create

        rm -f problem_dir/reported_to
    rlPhaseEnd

# duplicate issue exist (comment exist)
# API some search method (2x)
    rlPhaseStartTest "duplicate issue exist (comment exist)"
         ./pyserve \
                $QUERIES_DIR/loggin_correct \
                $QUERIES_DIR/search_two_issues \
                $QUERIES_DIR/search_two_issues \
                $QUERIES_DIR/add_note \
                &> server_log &

        rlRun "echo \"i am comment\" > problem_dir/comment"

        sleep 1
        rlRun "reporter-mantisbt -vvv -c mantisbt.conf -d problem_dir &> client_log"
        kill %1
# TODO request (related to search)
        rlAssertGrep "<note xsi:type=i\"ns3:IssueNoteDatai\"><text xsi:type=i\"ns2:stringi\">i am comment</text></note></ns3:mc_issue_note_add>" client_create

        # response
        rlAssertGrep "<SOAP-ENV:Body><ns1:mc_loginResponse>" client_create
        rlAssertGrep "<id xsi:type=\"xsd:integer\">2</id>" client_create
        rlAssertGrep "name xsi:type=\"xsd:string\">test</name>" client_create

        rlAssertGrep "Checking for duplicates" client_create
        rlAssertGrep "Bugzilla has 2 reports with duphash 'bbfe66399cc9cb8ba647414e33c5d1e4ad82b511' including cross-version ones" client_create
        rlAssertGrep "<return SOAP-ENC:arrayType=\"ns1:IssueData[2]\" xsi:type=\"SOAP-ENC:Array\">" client_create
        rlAssertGrep "Bugzilla has 2 reports with duphash 'bbfe66399cc9cb8ba647414e33c5d1e4ad82b511'" client_create
        rlAssertNotGrep "<return SOAP-ENC:arrayType=\"ns1:IssueData[0]\" xsi:type=\"SOAP-ENC:Array\">" client_create

        rlAssertGrep "Adding new comment to bug [0-9]*" client_create
        rlAssertGrep "<ns1:mc_issue_note_addResponse><return xsi:type=\"xsd:integer\">5</return></ns1:mc_issue_note_addResponse>" client_create


        rm -f problem_dir/comment
        rm -f problem_dir/reported_to
    rlPhaseEnd
    rlPhaseStartCleanup
        rlBundleLogs abrt server* client*
        popd # TmpDir
        rm -rf $TmpDir
    rlPhaseEnd
    rlJournalPrintText
rlJournalEnd
