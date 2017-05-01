#include <git2.h>
#include <iostream>
#include <stdio.h>
#include <time.h>

using namespace std;

static int progress_cb(const char *str, int len, void *data) {
    (void)data;
    printf("remote: %.*s", len, str);
    fflush(stdout); /* We don't have the \n to force the flush */
    return 0;
}
static int update_cb(const char *refname, const git_oid *a, const git_oid *b, void *data) {
    char a_str[GIT_OID_HEXSZ+1], b_str[GIT_OID_HEXSZ+1];
    (void)data;
    
    git_oid_fmt(b_str, b);
    b_str[GIT_OID_HEXSZ] = '\0';

    if (git_oid_iszero(a)) {
        printf("[new]     %.20s   %s\n", b_str, refname);
    } else {
        git_oid_fmt(a_str, a);
        a_str[GIT_OID_HEXSZ] = '\0';
        printf("[updated] %.10s..%.10s %s\n", a_str, b_str, refname);
    }
    
    return 0;
}
static int transfer_progress_cb(const git_transfer_progress *stats, void *payload) {
    if (stats->received_objects == stats->total_objects) {
        printf("Resolving deltas %d/%d\r",stats->indexed_deltas, stats->total_deltas);
    } else if (stats->total_objects > 0) {
        printf("Received %d/%d objects (%d) in %d bytes\r", stats->received_objects, stats->total_objects, stats->indexed_objects, stats->received_bytes);
    }
    return 0;
}

int remote_fetch(git_repository *repo, const char *alias) {
    int status = 0;
    git_remote *remote = 0;
    git_fetch_options fetch_opts = GIT_FETCH_OPTIONS_INIT;
    fetch_opts.callbacks.update_tips = &update_cb;
    fetch_opts.callbacks.sideband_progress = &progress_cb;
    fetch_opts.callbacks.transfer_progress = transfer_progress_cb;
    
    if (git_remote_lookup(&remote,repo,alias) < 0) {
        cout << "error resolving repo";
        status = -1;
        goto done;
    }
    if (git_remote_fetch(remote,0,&fetch_opts,"fetch") < 0) {
        cout << "error doing fetch" << endl;
        status = -2;
        goto done;
    }
done:
    git_remote_free(remote);
    return status;
}
int print_reference(git_repository *repo, const char *reference, const char *name) {
    git_oid oid;
    git_commit *commit = 0;
    if (git_reference_name_to_id(&oid,repo,reference) < 0) {
        cout << "fail 6" << endl;
        return -6;
    }
    char oid_hex[GIT_OID_HEXSZ+1] = {0};
    git_oid_fmt(oid_hex,&oid);
    oid_hex[GIT_OID_HEXSZ] = '\0';

    if (git_commit_lookup(&commit,repo,&oid) < 0) {
        cout << "fail 7" << endl;
        return -7;
    }
    git_time_t commit_time = git_commit_time(commit);
    char buf[512];
    int size = strftime(buf,500,"%F %T",localtime(&commit_time));
    buf[size] = 0;
    printf("%20s %s\t%s\n",name,oid_hex,buf);
    git_commit_free(commit);
}

int main(int argc, char **argv) {
    git_repository *repo = 0;

    git_libgit2_init();
    if (git_repository_open(&repo, "/home/clever/nixpkgs/") < 0) {
        cout << "unable to open repo";
        return -1;
    }

    remote_fetch(repo, "origin");
    remote_fetch(repo, "channels");

    print_reference(repo, "refs/remotes/origin/master", "master");
    print_reference(repo, "refs/remotes/channels/nixos-unstable-small", "nixos-unstable-small");
    print_reference(repo, "refs/remotes/channels/nixpkgs-unstable", "pkgs-unstable");
    print_reference(repo, "refs/remotes/channels/nixos-unstable", "nixos-unstable");

    FILE *ver = fopen("/run/current-system/nixos-version","r");
    char buf[512];
    int size = fread(buf,1,500,ver);
    buf[size] = 0;
    fclose(ver);
    cout << buf;
    git_repository_free(repo); repo = 0;
    git_libgit2_shutdown();
}
