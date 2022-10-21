#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

__attribute__((optnone)) uint32_t getNum()
{
  static uint32_t count = 2;
  count--;
  return count;
}

uint32_t foo()
{
  uint32_t V_0 = 0;
  goto LBL3;

LBL1:
  if (V_0 == 1) {
    printf("2\n");
    goto LBL2;
  }
  else 
    goto LBL3;

LBL2:
  printf("3\n");
  goto LBL3;

LBL3:
  printf("1\n");
  V_0 = getNum();
  if (V_0)
    goto LBL1;
  else {
    printf("4\n");
		return V_0;
	}
}

void bar(int a)
{
  if (a == 1) {
    printf("a==1\n");
  }
  else {
    printf("a!=1\n");
  }
}

int main(int argc, char **argv)
{
  foo();
  return 0;
}
