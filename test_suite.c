//Name: Oyindamola Olaosun
//Date: 29th April, 2026
//Description: Test script c file for ATOI routine to check inputs (invalid inputs)

#include <stdio.h>
#include <assert.h>

// Define the prototype so the compiler knows what to expect
extern long ATOI_C_Wrapper(const char* str);

void run_tests() {
    printf("Starting ATOI tests via C Wrapper...\n");

    // Test 1: Standard Positive
    long res1 = ATOI_C_Wrapper("123");
    printf("Test 1: Expected 123, Got %ld\n", res1);
    assert(res1 == 123);

    // Test 2: Standard Negative
    long res2 = ATOI_C_Wrapper("-50");
    printf("Test 2: Expected -50, Got %ld\n", res2);
    assert(res2 == -50);

    // Test 3: Zero
    long res3 = ATOI_C_Wrapper("0");
    printf("Test 3: Expected 0, Got %ld\n", res3);
    assert(res3 == 0);

    printf("\n ALL TESTS PASSED!\n");
}

int main() {
    run_tests();
    return 0;
}
