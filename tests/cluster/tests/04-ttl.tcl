source "../tests/includes/init-tests.tcl"
source "../tests/includes/job-utils.tcl"

test "Jobs TTL is honoured" {
    set start_time [clock milliseconds]
    set id [D 0 addjob myqueue myjob 5000 replicate 3 ttl 5]
    set job [D 0 show $id]
    assert {$id ne {}}

    # We just added the job, should be here in the requested amount of copies
    # (or more).
    assert {[count_job_copies $job {active queued}] >= 3}

    # After some time the job is deleted from the cluster.
    wait_for_condition {
        [count_job_copies $job {active queued}] == 0
    } else {
        fail "Job with TTL is still active"
    }
    set end_time [clock milliseconds]
    set elapsed [expr {$end_time-$start_time}]

    # It too at least 4 seconds (to avoid timing errors) for the job to
    # disappear.
    assert {$elapsed >= 4000}
}

test "Jobs mass expire test" {
    D 0 debug flushall
    assert {[DI 0 registered_jobs] == 0}
    set count 1000
    for {set j 0} {$j < $count} {incr j} {
        D 0 addjob myqueue job-$j 10000 ttl 5
    }
    assert {[DI 0 registered_jobs] == $count}
    wait_for_condition {
        [DI 0 registered_jobs] == 0
    } else {
        fail "Not every job expired after some time"
    }
}
