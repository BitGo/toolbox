load test_helper

@test "Can not login to admin account with user key" {
	enable_key "user1"
    run ssh_command "admin"
    [ "$status" -eq 255 ]
}

@test "Can not run interactive commands on admin account" {
	enable_key "admin1"
    run ssh_command "admin" ls
    echo "${output}" | grep "not a terminal"
}

@test "Can resolve fingerprint for valid user key" {
	enable_key "user1"
    run ssh_command "user" login-fingerprint
    echo "${output}" | grep "D16AC0FA2C80E18BDF786C2F41C54D8491451FB1"
}

@test "Can resolve email for valid user key" {
	enable_key "user2"
    run ssh_command "user" login-email
    echo "${output}" | grep "user2@localhost"
}

@test "Can resolve username for valid admin key" {
	enable_key "admin2"
    run ssh_command "user" login-name
    echo "${output}" | grep "admin2"
}

@test "Can list current keys" {
	enable_key "admin1"
    run ssh_command "user" list-keys
    echo "${output}" | grep "5725B970DC01905A47487CAAD40D5FBF787CB58B admin1"
    echo "${output}" | grep "2038CA10DCBBC0488146B2F6E91243068ABF16A1 user2"
}

@test "Can update scripts repo on the fly" {
	start_sshd
	populate_scripts_repo
	enable_key "user2"

    run ssh_command "user" sync-repos
    [ "$status" -eq 0 ]

    run ssh_command "user" hello
    echo "${output}" | grep "hello"
}

@test "Can update keys repo on the fly" {
	start_sshd
	populate_keys_repo
	enable_key "user2"

    run ssh_command "user" sync-repos
    [ "$status" -eq 0 ]

    run ssh_command "user" hello
    echo "${output}" | grep "hello"
}
