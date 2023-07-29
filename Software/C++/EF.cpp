#include <cmath>
#include <iostream>
#include <random>
#include <ctime>
#include "murmur3.c"

using namespace std;

static mt19937 rng(time(0));

#define THRESHOLD 8

struct Bucket {
	uint8_t window_idx = 0;
	uint8_t counter = 0;
};

class EF
{
private:
	Bucket* stage1;
    Bucket* stage2;
    Bucket* stage3;
	int bucket_num;

public:
	EF(int _bucket_num)
	{
		bucket_num = _bucket_num;
		stage1 = new Bucket[bucket_num];
		stage2 = new Bucket[bucket_num];
		stage3 = new Bucket[bucket_num];
	}

	unsigned int Insert(unsigned int item_id, int index)
	{
		int timestamp = index % 10000000;

        //stage 1
        uint32_t hash_value1;
        uint32_t seed1 = 1;
        MurmurHash3_x86_32(&item_id, 4, seed1, &hash_value1);
        int bucket_idx1 = hash_value1 % bucket_num;
        int randomVal1 = rng();

        int leftmost_index1 = 0;
        while (randomVal1 > 1) {
            leftmost_index1 += 1;
            randomVal1 = randomVal1 >> 1;
        }
        leftmost_index1 = int(32 - leftmost_index1 + 1);

        if (timestamp - stage1[bucket_idx1].window_idx == 3) {
            stage1[bucket_idx1].window_idx = timestamp;
            stage1[bucket_idx1].counter = leftmost_index1 < THRESHOLD ? leftmost_index1 : THRESHOLD;
        }
        else {
            if (leftmost_index1 > stage1[bucket_idx1].counter) {
            stage1[bucket_idx1].window_idx = timestamp;
            stage1[bucket_idx1].counter = leftmost_index1 < THRESHOLD ? leftmost_index1 : THRESHOLD;
            }
        }

        uint8_t stage1_value;
        stage1_value = stage1[bucket_idx1].counter;

        //stage 2
        uint32_t hash_value2;
        uint32_t seed2 = 2;
        MurmurHash3_x86_32(&item_id, 4, seed2, &hash_value2);
        int bucket_idx2 = hash_value2 % bucket_num;
        int randomVal2 = rng();

        int leftmost_index2 = 0;
        while (randomVal2 > 1) {
            leftmost_index2 += 1;
            randomVal2 = randomVal2 >> 1;
        }
        leftmost_index2 = int(32 - leftmost_index2 + 1);

        if (timestamp - stage2[bucket_idx2].window_idx == 3) {
            stage2[bucket_idx2].window_idx = timestamp;
            stage2[bucket_idx2].counter = leftmost_index2 < THRESHOLD ? leftmost_index2 : THRESHOLD;
        }
        else {
            if (leftmost_index2 > stage2[bucket_idx2].counter) {
            stage2[bucket_idx2].window_idx = timestamp;
            stage2[bucket_idx2].counter = leftmost_index2 < THRESHOLD ? leftmost_index2 : THRESHOLD;  
            }
        }

        uint8_t stage2_value;
        stage2_value = stage2[bucket_idx2].counter;       
        
        //stage 3
        uint32_t hash_value3;
        uint32_t seed3 = 2;
        MurmurHash3_x86_32(&item_id, 4, seed3, &hash_value3);
        int bucket_idx3 = hash_value3 % bucket_num;
        int randomVal3 = rng();

        int leftmost_index3 = 0;
        while (randomVal3 > 1) {
            leftmost_index3 += 1;
            randomVal3 = randomVal3 >> 1;
        }
        leftmost_index3 = int(32 - leftmost_index3 + 1);

        if (timestamp - stage3[bucket_idx3].window_idx == 3) {
            stage3[bucket_idx3].window_idx = timestamp;
            stage3[bucket_idx3].counter = leftmost_index3 < THRESHOLD ? leftmost_index3 : THRESHOLD;  
        }
        else {
            if (leftmost_index3 > stage3[bucket_idx3].counter) {
            stage3[bucket_idx3].window_idx = timestamp;
            stage3[bucket_idx3].counter = leftmost_index3 < THRESHOLD ? leftmost_index3 : THRESHOLD;  
            }
        }

        uint8_t stage3_value;
        stage3_value = stage3[bucket_idx3].counter;

        //judge
        if (stage1_value = THRESHOLD && stage2_value = THRESHOLD && stage3_value = THRESHOLD) {
            return item_id;
        }
        else {
            return 0;
        }
    }
    ~EF(){
        delete stage1;
        delete stage2;
        delete stage3;
    }
};