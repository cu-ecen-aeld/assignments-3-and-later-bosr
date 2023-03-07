#include <syslog.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
  openlog("writer", LOG_PID, LOG_USER);

  if (argc != 3) {
    syslog(LOG_ERR, "expected 2 arguments, but got %d arguments", argc);
    exit(1);
  }

  char* filepath = argv[1];
  char* write_str = argv[2];

  FILE* fp = fopen(filepath, "w");
  if (fp) {
    syslog(LOG_DEBUG, "Writing %s to %s", write_str, filepath);
    fprintf(fp, "%s\n", write_str);
    fclose(fp);
  } else {
    syslog(LOG_ERR, "could not write to file");
    exit(1);
  }
  closelog();
}
