#include <stdio.h>
#include <syslog.h>
#include <stdlib.h>
#include <dirent.h>
#include <errno.h>

int main(int argc, char* argv[]) {
  openlog("finder", LOG_PID, LOG_USER);

  if (argc != 3) {
    syslog(LOG_DEBUG, "expected 2 arguments, but got %d arguments", argc);
    exit(1);
  }

  char* dirpath = argv[1];
  char* search_str = argv[2];

  DIR* dir = opendir(dirpath);
  if (dir) {
    closedir(dir);
  } else if (ENOENT == errno) {
    /* Directory does not exist. */
    syslog(LOG_DEBUG, "directory `%s` does not exist.", dirpath);
    printf("directory `%s` does not exist.\n", dirpath);
    exit(1);
  } else {
    /* opendir() failed for some other reason. */
    syslog(LOG_DEBUG, "unknown error when trying to open directory `%s`.", dirpath);
    printf("unknown error when trying to open directory `%s`.\n", dirpath);
    exit(1);
  }

  syslog(LOG_DEBUG, "starting finder searching for `%s` in directory `%s`", argv[2], argv[1]);

  FILE *cmd;
  char result[1024];

  char cmdline[1024];
  sprintf(cmdline, "grep -r -c -h %s %s", search_str, dirpath);

  cmd = popen(cmdline, "r");
  if (cmd == NULL) {
    syslog(LOG_DEBUG, "error launching `%s`", cmdline);
    perror("popen");
    exit(EXIT_FAILURE);
  }

  int num_matching_files = 0;
  int num_total_matches = 0;
  while (fgets(result, sizeof(result), cmd)) {
    /* printf("%s", result); */
    num_matching_files++;
    int value = atoi(result);
    num_total_matches += value;
  }

  printf("The number of files are %d and the number of matching lines are %d\n", num_matching_files, num_total_matches);
  pclose(cmd);

  closelog();
  return 0;
}
