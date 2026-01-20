#include "crash_handler.h"

#include <atomic>
#include <string>
#include <vector>

#include <ShlObj.h>

namespace {

std::atomic<bool> g_is_shutting_down{false};
PVOID g_vectored_handle = nullptr;

std::wstring GetLogDirectory() {
  PWSTR local_app_data = nullptr;
  if (FAILED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr,
                                  &local_app_data))) {
    return L"";
  }
  std::wstring dir = local_app_data;
  CoTaskMemFree(local_app_data);
  dir += L"\\TSVPN\\logs";
  CreateDirectoryW(dir.c_str(), nullptr);
  return dir;
}

std::wstring GetLogPath() {
  const auto dir = GetLogDirectory();
  if (dir.empty()) {
    return L"";
  }
  SYSTEMTIME st;
  GetLocalTime(&st);
  wchar_t buffer[64] = {0};
  swprintf_s(buffer, L"\\crash_%04d%02d%02d_%02d%02d%02d.log", st.wYear,
             st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
  return dir + buffer;
}

std::string WideToUtf8(const std::wstring& input) {
  if (input.empty()) {
    return std::string();
  }
  const int size = WideCharToMultiByte(CP_UTF8, 0, input.c_str(),
                                       static_cast<int>(input.size()), nullptr,
                                       0, nullptr, nullptr);
  if (size <= 0) {
    return std::string();
  }
  std::string output(static_cast<size_t>(size), '\0');
  WideCharToMultiByte(CP_UTF8, 0, input.c_str(),
                      static_cast<int>(input.size()), output.data(), size,
                      nullptr, nullptr);
  return output;
}

void AppendToLog(const std::wstring& line) {
  const auto path = GetLogPath();
  if (path.empty()) {
    return;
  }
  HANDLE file = CreateFileW(path.c_str(), FILE_APPEND_DATA,
                            FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                            OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return;
  }
  const std::string utf8 = WideToUtf8(line + L"\r\n");
  DWORD written = 0;
  WriteFile(file, utf8.data(),
            static_cast<DWORD>(utf8.size()), &written, nullptr);
  CloseHandle(file);
}

LONG WINAPI VectoredHandler(PEXCEPTION_POINTERS info) {
  if (g_is_shutting_down.load()) {
    return EXCEPTION_CONTINUE_SEARCH;
  }
  wchar_t buffer[256] = {0};
  swprintf_s(buffer, L"SEH exception: code=0x%08X addr=0x%p",
             info->ExceptionRecord->ExceptionCode,
             info->ExceptionRecord->ExceptionAddress);
  AppendToLog(buffer);
  return EXCEPTION_CONTINUE_SEARCH;
}

LONG WINAPI UnhandledExceptionHandler(PEXCEPTION_POINTERS info) {
  if (g_is_shutting_down.load()) {
    return EXCEPTION_CONTINUE_SEARCH;
  }
  wchar_t buffer[256] = {0};
  swprintf_s(buffer, L"Unhandled exception: code=0x%08X addr=0x%p",
             info->ExceptionRecord->ExceptionCode,
             info->ExceptionRecord->ExceptionAddress);
  AppendToLog(buffer);
  return EXCEPTION_CONTINUE_SEARCH;
}

}  // namespace

void InstallCrashHandler() {
  if (g_vectored_handle == nullptr) {
    g_vectored_handle = AddVectoredExceptionHandler(1, VectoredHandler);
  }
  SetUnhandledExceptionFilter(UnhandledExceptionHandler);
}

void SetShuttingDown(bool shutting_down) {
  g_is_shutting_down.store(shutting_down);
}

void LogCrashMessage(const wchar_t* location, const wchar_t* message) {
  if (location == nullptr || message == nullptr) {
    return;
  }
  std::wstring line = L"[";
  line += location;
  line += L"] ";
  line += message;
  AppendToLog(line);
}
