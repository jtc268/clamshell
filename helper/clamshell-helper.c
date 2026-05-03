#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int run_pmset_enable(void) {
    char *const argv[] = { "pmset", "-a", "disablesleep", "1", NULL };
    execv("/usr/bin/pmset", argv);
    return errno;
}

static int run_pmset_disable(void) {
    char *const argv[] = { "pmset", "-a", "disablesleep", "0", NULL };
    execv("/usr/bin/pmset", argv);
    return errno;
}

static int run_pmset_sleepnow(void) {
    char *const argv[] = { "pmset", "sleepnow", NULL };
    execv("/usr/bin/pmset", argv);
    return errno;
}

static int run_pmset_status(void) {
    char *const argv[] = { "pmset", "-g", NULL };
    execv("/usr/bin/pmset", argv);
    return errno;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: clamshell-helper enable|disable|sleepnow|status\n");
        return 64;
    }

    if (setgid(0) != 0 || setuid(0) != 0) {
        fprintf(stderr, "clamshell-helper: root privileges are required\n");
        return 77;
    }

    if (strcmp(argv[1], "enable") == 0) {
        return run_pmset_enable();
    }
    if (strcmp(argv[1], "disable") == 0) {
        return run_pmset_disable();
    }
    if (strcmp(argv[1], "sleepnow") == 0) {
        return run_pmset_sleepnow();
    }
    if (strcmp(argv[1], "status") == 0) {
        return run_pmset_status();
    }

    fprintf(stderr, "clamshell-helper: unknown action: %s\n", argv[1]);
    return 64;
}
