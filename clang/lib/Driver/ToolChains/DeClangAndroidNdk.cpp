#include "DeClangAndroidNdk.h"

#include <cctype>
#include <charconv>
#include <filesystem>
#include <fstream>
#include <string>
#include <string_view>
#include <system_error>

namespace {

std::string_view trimWhitespace(std::string_view text) {
  while (!text.empty() &&
         std::isspace(static_cast<unsigned char>(text.front()))) {
    text.remove_prefix(1);
  }
  while (!text.empty() &&
         std::isspace(static_cast<unsigned char>(text.back()))) {
    text.remove_suffix(1);
  }
  return text;
}

int parseMajorRevision(std::string_view value) {
  value = trimWhitespace(value);
  if (value.empty() || !std::isdigit(static_cast<unsigned char>(value.front()))) {
    return -1;
  }

  int major = -1;
  const char *begin = value.data();
  const char *end = begin + value.size();
  auto result = std::from_chars(begin, end, major);
  if (result.ec != std::errc{} || result.ptr == begin) {
    return -1;
  }

  if (result.ptr != end) {
    char next = *result.ptr;
    if (next != '.' && next != '-' && next != '+' &&
        !std::isspace(static_cast<unsigned char>(next))) {
      return -1;
    }
  }

  return major;
}

int readNdkVersionFromProperties(const std::filesystem::path &propsPath) {
  std::ifstream versionFile(propsPath, std::ios::in);
  if (!versionFile.is_open()) {
    return -1;
  }

  std::string line;
  while (std::getline(versionFile, line)) {
    std::string_view view(line);
    size_t eqPos = view.find('=');
    if (eqPos == std::string_view::npos) {
      continue;
    }

    std::string_view key = trimWhitespace(view.substr(0, eqPos));
    if (key == "Pkg.Revision") {
      int major = parseMajorRevision(view.substr(eqPos + 1));
      if (major != -1) {
        return major;
      }
    }
  }

  return -1;
}

int detectNdkVersion(const char *path) {
  if (path == nullptr || path[0] == '\0') {
    return -1;
  }

  std::error_code ec;
  std::filesystem::path absPath = std::filesystem::canonical(path, ec);
  if (ec) {
    return -1;
  }

  std::filesystem::path rootPath = absPath.root_path();
  bool isDir = std::filesystem::is_directory(absPath, ec);
  std::filesystem::path dir = (!ec && isDir) ? absPath : absPath.parent_path();

  while (!dir.empty() && dir != rootPath) {
    std::error_code fileEc;
    std::filesystem::path propsPath = dir / "source.properties";
    if (std::filesystem::is_regular_file(propsPath, fileEc) && !fileEc) {
      int detected = readNdkVersionFromProperties(propsPath);
      if (detected != -1) {
        return detected;
      }
    }

    std::filesystem::path parent = dir.parent_path();
    if (parent == dir) {
      break;
    }
    dir = parent;
  }

  return -1;
}

} // namespace

static int version = -1;

int getNdkVersion(const char *path) {
  if (version != -1) {
    return version;
  }

  version = detectNdkVersion(path);
  return version;
}
