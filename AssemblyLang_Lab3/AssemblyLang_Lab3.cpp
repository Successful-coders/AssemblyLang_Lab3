#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <conio.h>

extern "C" float __stdcall findSolve(float precision, int* iterCtr);

void main()
{
	int iterationCount = 1;
	float accuracy;

	printf("Equation: 1.8x^4 - sin(10x) = 0\n");
	printf("Accuracy: ");
	scanf("%f", &accuracy);

	float result = findSolve(accuracy, &iterationCount);

	printf("Equation solution: %f\n", result);
	printf("Iteration count: %d\n", iterationCount);

	_getch();
}