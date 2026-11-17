#include "my_application.h"

// GF-01517 — Create and run the Linux GTK application.
int main(int argc, char** argv) {
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
