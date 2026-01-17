#include <cstdio>
#include <memory>
#include <string>

struct User {
  int id = 30;
  std::string name = "steph";
};

int main() {
  std::shared_ptr<int> sp_empty;
  std::shared_ptr<int> sp_int = std::make_shared<int>(10);
  std::shared_ptr<std::string> sp_str = std::make_shared<std::string>("hello");
  std::shared_ptr<int> &sp_int_ref = sp_int;
  std::shared_ptr<int> &&sp_int_ref_ref = std::make_shared<int>(10);
  std::shared_ptr<User> sp_user = std::make_shared<User>();

  // Construct empty shared_ptr with non-null control field.
  std::shared_ptr<int> si(new int(47));
  std::shared_ptr<int> sie(si, nullptr);

  std::puts("// break here");

  std::weak_ptr<int> wie = sie;
  std::weak_ptr<int> wie2 = sie;

  std::puts("// break here");

  return 0;
}
