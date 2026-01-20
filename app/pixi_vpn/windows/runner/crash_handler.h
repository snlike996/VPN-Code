#ifndef RUNNER_CRASH_HANDLER_H_
#define RUNNER_CRASH_HANDLER_H_

#include <windows.h>

void InstallCrashHandler();
void SetShuttingDown(bool shutting_down);
void LogCrashMessage(const wchar_t* location, const wchar_t* message);

#endif  // RUNNER_CRASH_HANDLER_H_
