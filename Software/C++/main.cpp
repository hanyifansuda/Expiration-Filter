#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <cstring>
#include <time.h>
#include <sys/time.h>
#include <cmath>
#include <fstream>
#include <iostream>
#include "LLF+.cpp"
#include "EF.cpp"
#include "murmur3.h"


using namespace std;
#define MAX_INSERT_PACKAGE 50000000
#define file "dataset_path"

uint32_t insert_data[MAX_INSERT_PACKAGE];

unsigned int getip3(char str[50], int len);

unsigned int getip(char str[50], int len);

int load_data();


int load_data() { 
	char flow_label[50], element[50];
	FILE* in1 = fopen(file, "r");
	memset(flow_label, 0, sizeof(flow_label));
	memset(element, 0, sizeof(element));
	int cnt = 0;

	uint32_t flow;
	while (fscanf(in1, "%s%s", element, flow_label) != EOF) {
		
		cnt++; 
		if (cnt % 1000000 == 0) {
					cout << cnt << "..." << endl;
				}
		flow = getip(flow_label, strlen(flow_label));
		insert_data[cnt] = flow;
	}

	return cnt;
}
unsigned int getip3(char str[50], int len)
{
	int i = 0;
	unsigned int sum = 0;
	unsigned int temp = 0;
	while (i < len)
	{
		if (str[i] == '.' || str[i] == ':')
		{
			sum = sum * 256 + temp;
			temp = 0;
		}
		else if (str[i] <= '9' && str[i] >= '0')
		{
			temp = temp * 16 + str[i] - '0';
		}
		else
		{
			temp = temp * 16 + str[i] - 'a' + 10;
		}
		i++;
	}
	sum = sum * 256 + temp;
	return sum;
}

unsigned int getip(char str[50], int len)
{
	int i = 0;
	unsigned int sum = 0;
	unsigned int temp = 0;

	if (str[len - 1] == ':') {
		return getip3(str, len);
	}

	while (i < len)
	{
		if (str[i] == '.' || str[i] == ':')
		{
			sum = sum * 256 + temp;
			temp = 0;
		}
		else if (str[i] <= '9' && str[i] >= '0')
		{
			temp = temp * 10 + str[i] - '0';
		}
		else
		{
			temp = temp * 10 + str[i] - 'a' + 10;
		}
		i++;
	}
	sum = sum * 256 + temp;
	temp = 0;
	return sum;  
} 

char* get_char_ip(unsigned int *flow) {
	char* key = new char[32] {0};
	memcpy(key, flow, 32);
	return key;  
}


int main() {   
	srand(unsigned(time(NULL)));
	cout << "prepare dataset" << endl;
	int packet_num = load_data();

	long long resns;

    //init 
	const int memory = 60*1024*8;
	cout << "prepare sketch" << endl;

	//Ours
	int bucket_num = memory/9;
	Sketch *Sk = new LLF_plus(bucket_num);
	// Sketch *Sk = new EF(bucket_num);
	cout << "Prepare sketch done!" << endl;

    cout << "insert items" << endl;
    clock_t time1 = clock();
	for (int i = 0; i < packet_num; ++i) {
		unsigned int item_id = Sk->Insert(insert_data[i], i);
		}
    clock_t time2 = clock();

    //calculate throughput
    double numOfSeconds = (double)(time2 - time1) / CLOCKS_PER_SEC;//the seconds using to insert items
    double throughput = (packet_num / 1000000.0) / numOfSeconds;
    cout << "use " << numOfSeconds << " seconds" << endl;
    cout << "throughput: " << throughput << " Mips" << ", each insert operation uses " << 1000.0 / throughput << " ns" << endl;
    cout << "*********************" << endl;

	return 0;
}
