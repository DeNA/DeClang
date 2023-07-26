#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <libgen.h>
#include <string.h>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <regex>

static int version = -1;

int getNdkVersion(const char *path) {
	if (version != -1) {
		return version;
	}

	std::filesystem::path abs_path = std::filesystem::canonical(path);
	std::filesystem::path root_path = abs_path.root_directory();

	for (std::filesystem::path dir = abs_path.parent_path(); dir.compare(root_path) != 0; dir = dir.parent_path()) {
		for (const std::filesystem::directory_entry& file : std::filesystem::directory_iterator(dir)) {
			if (file.is_regular_file()) {
				if (file.path().filename().compare("source.properties") == 0) {
					std::ifstream version_file(file, std::ios::in);
					std::string line;
					while (std::getline(version_file, line)) {
						std::stringstream ss(line);
						std::string key;
						while (std::getline(ss, key, '=')) {
							key = std::regex_replace(key, std::regex("^ *"), "");
							key = std::regex_replace(key, std::regex(" *$"), "");
							if (key == "Pkg.Revision") {
								std::string value;
								std::getline(ss, value, '=');
								value = std::regex_replace(value, std::regex("^ *"), "");
								value = std::regex_replace(value, std::regex(" *$"), "");
								std::smatch m;
								if (std::regex_match(value, m, std::regex(R"(^(\d+).+)"))) {
									version = stoi(m[1].str());
									goto DONE;
								}
							}
						}
					}
				}
			}
		}
	}
DONE:
	return version;
}

