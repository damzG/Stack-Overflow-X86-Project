#include <stdio.h>
#include <assert.h>

extern long test_add_wrapper(long a, long b);

int main(){

    printf("Testing ADD_NUMBERS routine..\n");

    //Test Case 1: Standard Addition
    assert(test_add_wrapper(50, 50) == 100);
    printf("Passed: 50 + 50 = 100\n");

    //Test Case 2: Negative Addition
    assert(test_add_wrapper(-10, -5) == -15);
    printf("Passed: -10 + -5 = -15\n");



    printf("All Addition Routine tests passed!\n");
    return 0;
}